from __future__ import annotations

import base64
from datetime import datetime, timezone
from pathlib import Path

from ..models.medication import (
    ConflictWarningPayload,
    CurrentMedicationItem,
    MedicationConfirmRequest,
    MedicationConfirmResponse,
    MedicationRecognizeResponse,
    RecognizedMedicationPayload,
)
from .store import JsonMedicationStore


class MedicationEngine:
    """MedicationEngine: 负责模拟 OCR 识别与基础 DDI 冲突检查。"""

    _recognition_map = {
        "aspirin": RecognizedMedicationPayload(
            name="阿司匹林",
            dosage="100mg / 次",
            usage="建议早餐后温水送服，每日 1 次，请勿自行加量。",
            contraindications="活动性出血、消化道溃疡、阿司匹林过敏者慎用。",
            source_text="aspirin",
        ),
        "metformin": RecognizedMedicationPayload(
            name="二甲双胍缓释片",
            dosage="500mg / 次",
            usage="建议随餐或餐后服用，每日 1 至 2 次。",
            contraindications="严重肾功能不全者慎用。",
            source_text="metformin",
        ),
    }

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

    def recognize(
        self,
        user_id: str,
        image_base64: str,
        mock_hint_text: str | None,
        current_medications: list[CurrentMedicationItem],
    ) -> MedicationRecognizeResponse:
        self._persist_mock_image(user_id=user_id, image_base64=image_base64)
        decoded_text = self._decode_base64_text(image_base64)
        search_text = f"{decoded_text} {mock_hint_text or ''}".lower()

        recognized = self._resolve_recognition(search_text)
        if recognized is None:
            return MedicationRecognizeResponse(
                status="not_found",
                message="暂时没有认出药盒文字，请换个角度再试一次。",
                medication=None,
                conflict_warning=None,
                current_medication_state=self._current_state_names(
                    user_id=user_id,
                    current_medications=current_medications,
                ),
            )

        conflict_warning = self._detect_conflict(
            recognized_name=recognized.name,
            active_medications=self._current_state_names(
                user_id=user_id,
                current_medications=current_medications,
            ),
        )

        return MedicationRecognizeResponse(
            status="recognized",
            message="识别完成，已为您检查用法用量与药物冲突。",
            medication=recognized,
            conflict_warning=conflict_warning,
            current_medication_state=self._current_state_names(
                user_id=user_id,
                current_medications=current_medications,
            ),
        )

    def _resolve_recognition(
        self,
        search_text: str,
    ) -> RecognizedMedicationPayload | None:
        for keyword, payload in self._recognition_map.items():
            if keyword in search_text:
                return payload
        return None

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

    def confirm_medication(
        self,
        payload: MedicationConfirmRequest,
    ) -> MedicationConfirmResponse:
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

    @staticmethod
    def _decode_base64_text(image_base64: str) -> str:
        try:
            raw_bytes = base64.b64decode(image_base64.encode("utf-8"), validate=False)
            return raw_bytes.decode("utf-8", errors="ignore")
        except Exception:
            return ""

    def _persist_mock_image(self, user_id: str, image_base64: str) -> None:
        try:
            raw_bytes = base64.b64decode(image_base64.encode("utf-8"), validate=False)
        except Exception:
            raw_bytes = image_base64.encode("utf-8")
        output_path = (
            self._image_dir
            / f"{user_id}-{datetime.now(timezone.utc).strftime('%Y%m%d%H%M%S')}.jpg"
        )
        output_path.write_bytes(raw_bytes)
