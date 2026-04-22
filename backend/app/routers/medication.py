from fastapi import APIRouter

from ..dependencies import medication_engine
from ..models.medication import (
    MedicationConfirmRequest,
    MedicationConfirmResponse,
    MedicationRecognizeRequest,
    MedicationRecognizeResponse,
)

router = APIRouter(prefix="/medication", tags=["MedicationEngine"])


@router.post("/recognize", response_model=MedicationRecognizeResponse)
async def recognize_medication(
    payload: MedicationRecognizeRequest,
) -> MedicationRecognizeResponse:
    return medication_engine.recognize(
        user_id=payload.user_id,
        image_base64=payload.image_base64,
        mock_hint_text=payload.mock_hint_text,
        current_medications=payload.current_medications,
    )


@router.post("/confirm", response_model=MedicationConfirmResponse)
async def confirm_medication(
    payload: MedicationConfirmRequest,
) -> MedicationConfirmResponse:
    return medication_engine.confirm_medication(payload=payload)
