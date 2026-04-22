from __future__ import annotations

from dataclasses import dataclass
from datetime import datetime, timezone
from difflib import SequenceMatcher
from pathlib import Path
from uuid import uuid4

from ..models.medication import (
    ConflictWarningPayload,
    CurrentMedicationItem,
    MedicationConfirmRequest,
    MedicationConfirmResponse,
    MedicationRecognizeResponse,
    RecognizedMedicationPayload,
)
from .store import JsonMedicationStore

try:
    from paddleocr import PaddleOCR
except ImportError:  # pragma: no cover - 运行环境未安装 OCR 时走兜底
    PaddleOCR = None


@dataclass(frozen=True)
class DrugCandidate:
    canonical_name: str
    aliases: tuple[str, ...]
    dosage: str
    usage: str
    contraindications: str
    source_text: str


class MedicationEngine:
    """MedicationEngine: 负责 OCR 识别、药名映射、图片保存与基础 DDI 冲突检查。"""

    _drug_catalog = (
        DrugCandidate(
            canonical_name="阿司匹林",
            aliases=("阿司匹林", "aspirin", "乙酰水杨酸"),
            dosage="100mg / 次",
            usage="建议早餐后温水送服，每日 1 次，请勿自行加量。",
            contraindications="活动性出血、消化道溃疡、阿司匹林过敏者慎用。",
            source_text="aspirin",
        ),
        DrugCandidate(
            canonical_name="二甲双胍缓释片",
            aliases=("二甲双胍", "二甲双胍缓释片", "metformin"),
            dosage="500mg / 次",
            usage="建议随餐或餐后服用，每日 1 至 2 次。",
            contraindications="严重肾功能不全者慎用。",
            source_text="metformin",
        ),
    )

    _ddi_rules = {
        frozenset({"阿司匹林", "华法林"}): ConflictWarningPayload(
            interacting_medication="华法林",
            risk_level="high",
            summary="注意！检测到高风险药物冲突",
            detail="注意！这个药和您正在吃的华法林有冲突，可能会导致出血风险，请先咨询医生！",
            voice_prompt="注意！这个药和您正在吃的华法林有冲突，可能会导致出血风险，请先咨询医生！",
        ),
    }

    def __init__(self, store: JsonMedicationStore) -> None:
        self._store = store
        self._image_dir = Path(__file__).resolve().parents[2] / "data" / "uploads"
        self._image_dir.mkdir(parents=True, exist_ok=True)
        self._ocr_engine = None

    def recognize(
        self,
        user_id: str,
        image_bytes: bytes,
        original_filename: str,
        mock_hint_text: str | None,
        current_medications: list[CurrentMedicationItem],
    ) -> MedicationRecognizeResponse:
        image_id, stored_path = self._persist_uploaded_image(
            user_id=user_id,
            image_bytes=image_bytes,
            original_filename=original_filename,
        )
        ocr_texts = self._extract_texts_via_ocr(
            image_path=stored_path,
            mock_hint_text=mock_hint_text,
        )
        recognized = self._map_to_drug(ocr_texts=ocr_texts)
        current_state_names = self._current_state_names(
            user_id=user_id,
            current_medications=current_medications,
        )

        if recognized is None:
            return MedicationRecognizeResponse(
                status="not_found",
                message="暂时没有看清药盒文字，请再拍一张更清楚的照片。",
                image_id=image_id,
                image_path=stored_path,
                medication=None,
                conflict_warning=None,
                current_medication_state=current_state_names,
            )

        conflict_warning = self._detect_conflict(
            recognized_name=recognized.name,
            active_medications=current_state_names,
        )

        return MedicationRecognizeResponse(
            status="recognized",
            message="识别完成，已为您检查用法用量与药物冲突。",
            image_id=image_id,
            image_path=stored_path,
            medication=recognized,
            conflict_warning=conflict_warning,
            current_medication_state=current_state_names,
        )

    def confirm_medication(
        self,
        payload: MedicationConfirmRequest,
    ) -> MedicationConfirmResponse:
        active_medications = self._store.get_user_profile(
            payload.user_id
        ).current_medication_state
        conflict_warning = self._detect_conflict(
            recognized_name=payload.name,
            active_medications=active_medications,
        )
        if conflict_warning is not None:
            return MedicationConfirmResponse(
                status="conflict_blocked",
                message=conflict_warning.detail,
                medication_list=self._store.get_user_profile(
                    payload.user_id
                ).medication_list,
            )

        medication_list = self._store.add_medication_to_list(
            user_id=payload.user_id,
            medication_name=payload.name,
            dosage=payload.dosage,
            usage=payload.usage,
        )
        self._store.update_current_medication_state(
            user_id=payload.user_id,
            medication_name=payload.name,
            dosage=payload.dosage,
            confirmed_at=payload.confirmed_at or datetime.now(timezone.utc),
        )
        return MedicationConfirmResponse(
            status="saved",
            message="药物已录入用户药物清单。",
            medication_list=medication_list,
        )

    def _extract_texts_via_ocr(
        self,
        image_path: str,
        mock_hint_text: str | None,
    ) -> list[str]:
        engine = self._get_ocr_engine()
        extracted_texts: list[str] = []

        if engine is not None:
            try:
                prediction = engine.predict(image_path)
                for item in prediction:
                    result = item.get("res", {})
                    texts = result.get("rec_texts", [])
                    extracted_texts.extend(
                        text.strip() for text in texts if isinstance(text, str)
                    )
            except Exception:
                extracted_texts = []

        # 兜底：开发环境还未装好 PaddleOCR 时，仍允许通过提示词联调主流程。
        if not extracted_texts and mock_hint_text:
            extracted_texts.append(mock_hint_text)

        return extracted_texts

    def _get_ocr_engine(self):
        if self._ocr_engine is not None:
            return self._ocr_engine
        if PaddleOCR is None:
            return None

        self._ocr_engine = PaddleOCR(
            use_doc_orientation_classify=False,
            use_doc_unwarping=False,
            use_textline_orientation=False,
        )
        return self._ocr_engine

    def _map_to_drug(
        self,
        ocr_texts: list[str],
    ) -> RecognizedMedicationPayload | None:
        normalized_blob = " ".join(ocr_texts).lower()

        # 先做直接命中，优先保证常见药盒识别稳定。
        for candidate in self._drug_catalog:
            for alias in candidate.aliases:
                if alias.lower() in normalized_blob:
                    return self._to_payload(candidate)

        # 再做模糊匹配，处理 OCR 文本存在轻微错漏的情况。
        best_candidate: DrugCandidate | None = None
        best_score = 0.0
        for candidate in self._drug_catalog:
            for alias in candidate.aliases:
                score = SequenceMatcher(
                    None,
                    normalized_blob,
                    alias.lower(),
                ).ratio()
                if score > best_score:
                    best_score = score
                    best_candidate = candidate

        if best_candidate is not None and best_score >= 0.35:
            return self._to_payload(best_candidate)

        return None

    @staticmethod
    def _to_payload(candidate: DrugCandidate) -> RecognizedMedicationPayload:
        return RecognizedMedicationPayload(
            name=candidate.canonical_name,
            dosage=candidate.dosage,
            usage=candidate.usage,
            contraindications=candidate.contraindications,
            source_text=candidate.source_text,
        )

    def _detect_conflict(
        self,
        recognized_name: str,
        active_medications: list[str],
    ) -> ConflictWarningPayload | None:
        for existing_name in active_medications:
            rule = self._ddi_rules.get(
                frozenset({recognized_name, existing_name})
            )
            if rule is not None:
                return rule
        return None

    def _current_state_names(
        self,
        user_id: str,
        current_medications: list[CurrentMedicationItem],
    ) -> list[str]:
        stored_names = self._store.get_user_profile(user_id).current_medication_state
        merged_names = list(stored_names)
        for item in current_medications:
            if item.name not in merged_names:
                merged_names.append(item.name)
        return merged_names

    def _persist_uploaded_image(
        self,
        user_id: str,
        image_bytes: bytes,
        original_filename: str,
    ) -> tuple[str, str]:
        suffix = Path(original_filename).suffix or ".jpg"
        image_id = f"{user_id}-{uuid4().hex[:12]}"
        output_path = self._image_dir / f"{image_id}{suffix}"
        output_path.write_bytes(image_bytes)
        return image_id, str(output_path)
