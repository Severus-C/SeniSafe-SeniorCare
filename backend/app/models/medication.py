from datetime import datetime

from pydantic import BaseModel, Field


class CurrentMedicationItem(BaseModel):
    name: str = Field(..., description="当前正在服用的药品名")
    dosage: str = Field(..., description="当前药品剂量")


class RecognizedMedicationPayload(BaseModel):
    name: str
    dosage: str
    usage: str
    contraindications: str
    source_text: str


class ConflictWarningPayload(BaseModel):
    interacting_medication: str
    risk_level: str
    summary: str
    detail: str
    voice_prompt: str


class MedicationRecognizeResponse(BaseModel):
    status: str
    message: str
    image_id: str | None = None
    image_path: str | None = None
    medication: RecognizedMedicationPayload | None = None
    conflict_warning: ConflictWarningPayload | None = None
    current_medication_state: list[str] = Field(default_factory=list)


class MedicationConfirmRequest(BaseModel):
    user_id: str
    name: str
    dosage: str
    usage: str
    contraindications: str | None = None
    confirmed_at: datetime | None = None


class MedicationConfirmResponse(BaseModel):
    status: str
    message: str
    medication_list: list[dict[str, str]] = Field(default_factory=list)
