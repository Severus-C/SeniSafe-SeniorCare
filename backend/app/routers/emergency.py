from fastapi import APIRouter

from ..dependencies import emergency_service
from ..models.emergency import (
    EmergencyPacketResponse,
    EmergencyPreparePacketRequest,
    EmergencyPreparePacketResponse,
)

router = APIRouter(prefix="/emergency", tags=["EmergencyHub"])


@router.post("/prepare_packet", response_model=EmergencyPreparePacketResponse)
async def prepare_emergency_packet(
    payload: EmergencyPreparePacketRequest,
) -> EmergencyPreparePacketResponse:
    return emergency_service.prepare_packet(
        user_id=payload.user_id,
        medication_name=payload.medication_name,
        dosage=payload.dosage,
        confirmed_at=payload.confirmed_at,
    )


@router.get("/packet/{user_id}", response_model=EmergencyPacketResponse)
async def get_emergency_packet(user_id: str) -> EmergencyPacketResponse:
    return emergency_service.get_packet(user_id=user_id)
