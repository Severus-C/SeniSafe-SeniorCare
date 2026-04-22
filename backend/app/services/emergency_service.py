from __future__ import annotations

from datetime import datetime, timezone
from uuid import uuid4

from ..models.emergency import (
    EmergencyPreparePacketResponse,
    EmergencyPacketResponse,
    RecentIntakeRecordPayload,
)
from .store import JsonMedicationStore


class EmergencyService:
    """EmergencyHub: 聚合近 24 小时服药记录，生成急救数据包。"""

    def __init__(self, store: JsonMedicationStore) -> None:
        self._store = store

    def prepare_packet(
        self,
        user_id: str,
        medication_name: str,
        dosage: str,
        confirmed_at: datetime,
    ) -> EmergencyPreparePacketResponse:
        user_state = self._store.update_current_medication_state(
            user_id=user_id,
            medication_name=medication_name,
            dosage=dosage,
            confirmed_at=confirmed_at,
        )
        recent_records = self._store.recent_intake_records(user_id=user_id, hours=24)

        return EmergencyPreparePacketResponse(
            packet_id=f"packet-{uuid4().hex[:8]}",
            generated_at=datetime.now(timezone.utc),
            summary="已整理最近 24 小时服药记录，可供 SOS 时优先共享。",
            current_medication_state=user_state.current_medication_state,
            recent_intake_records=[
                RecentIntakeRecordPayload(
                    medication_name=item.medication_name,
                    dosage=item.dosage,
                    confirmed_at=item.confirmed_at,
                )
                for item in recent_records
            ],
        )

    def get_packet(self, user_id: str) -> EmergencyPacketResponse:
        profile = self._store.get_user_profile(user_id)
        recent_records = self._store.recent_intake_records(user_id=user_id, hours=24)
        risk_notice = self._build_risk_notice(
            current_state=profile.current_medication_state,
            recent_records=recent_records,
        )

        return EmergencyPacketResponse(
            packet_id=f"packet-{uuid4().hex[:8]}",
            generated_at=datetime.now(timezone.utc),
            summary="数字化急救名片已准备完成，可立即展示给急救人员。",
            avatar_url=profile.avatar_url,
            patient_name=profile.name,
            age=profile.age,
            blood_type=profile.blood_type,
            allergies=profile.allergies,
            chronic_conditions=profile.chronic_conditions,
            current_medication_state=profile.current_medication_state,
            risk_notice=risk_notice,
            recent_intake_records=[
                RecentIntakeRecordPayload(
                    medication_name=item.medication_name,
                    dosage=item.dosage,
                    confirmed_at=item.confirmed_at,
                )
                for item in recent_records
            ],
        )

    @staticmethod
    def _build_risk_notice(
        current_state: list[str],
        recent_records: list,
    ) -> str:
        medication_names = {
            *current_state,
            *[item.medication_name for item in recent_records],
        }
        if {"阿司匹林", "华法林"} & medication_names:
            return "患者正在服用抗凝药，急救请注意！"
        return "当前未发现高风险抗凝药提示，请继续核对病史。"
