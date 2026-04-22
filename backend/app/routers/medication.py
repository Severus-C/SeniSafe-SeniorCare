import json

from fastapi import APIRouter, File, Form, UploadFile

from ..dependencies import medication_engine
from ..models.medication import (
    CurrentMedicationItem,
    MedicationConfirmRequest,
    MedicationConfirmResponse,
    MedicationRecognizeResponse,
)

router = APIRouter(prefix="/medication", tags=["MedicationEngine"])


@router.post("/recognize", response_model=MedicationRecognizeResponse)
async def recognize_medication(
    user_id: str = Form(...),
    current_medications: str = Form("[]"),
    mock_hint_text: str | None = Form(default=None),
    image: UploadFile = File(...),
) -> MedicationRecognizeResponse:
    image_bytes = await image.read()
    parsed_current_medications = [
        CurrentMedicationItem.model_validate(item)
        for item in json.loads(current_medications)
    ]
    return medication_engine.recognize(
        user_id=user_id,
        image_bytes=image_bytes,
        original_filename=image.filename or "captured-medication.jpg",
        mock_hint_text=mock_hint_text,
        current_medications=parsed_current_medications,
    )


@router.post("/confirm", response_model=MedicationConfirmResponse)
async def confirm_medication(
    payload: MedicationConfirmRequest,
) -> MedicationConfirmResponse:
    return medication_engine.confirm_medication(payload=payload)
