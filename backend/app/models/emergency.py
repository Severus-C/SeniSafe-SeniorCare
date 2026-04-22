from datetime import datetime

from pydantic import BaseModel, Field


class EmergencyPreparePacketRequest(BaseModel):
    user_id: str
    medication_name: str
    dosage: str
    confirmed_at: datetime


class RecentIntakeRecordPayload(BaseModel):
    medication_name: str
    dosage: str
    confirmed_at: datetime


class EmergencyPreparePacketResponse(BaseModel):
    packet_id: str
    generated_at: datetime
    summary: str
    current_medication_state: list[str] = Field(default_factory=list)
    recent_intake_records: list[RecentIntakeRecordPayload] = Field(
        default_factory=list
    )


class EmergencyPacketResponse(BaseModel):
    packet_id: str
    generated_at: datetime
    summary: str
    avatar_url: str
    patient_name: str
    age: int
    blood_type: str
    allergies: list[str] = Field(default_factory=list)
    chronic_conditions: list[str] = Field(default_factory=list)
    current_medication_state: list[str] = Field(default_factory=list)
    risk_notice: str
    recent_intake_records: list[RecentIntakeRecordPayload] = Field(
        default_factory=list
    )
