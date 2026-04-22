from __future__ import annotations

import json
from dataclasses import dataclass
from datetime import datetime, timedelta, timezone
from pathlib import Path
from typing import Any


@dataclass
class IntakeRecord:
    medication_name: str
    dosage: str
    confirmed_at: datetime


@dataclass
class UserProfile:
    user_id: str
    name: str
    age: int
    blood_type: str
    allergies: list[str]
    chronic_conditions: list[str]
    avatar_url: str
    medication_list: list[dict[str, str]]
    current_medication_state: list[str]
    intake_records: list[IntakeRecord]


class JsonMedicationStore:
    """使用 JSON 文件做轻量持久化，便于本地开发联调。"""

    def __init__(self, storage_path: str | Path | None = None) -> None:
        default_path = Path(__file__).resolve().parents[2] / "data" / "users.json"
        self._storage_path = Path(storage_path or default_path)
        self._storage_path.parent.mkdir(parents=True, exist_ok=True)
        if not self._storage_path.exists():
            self._write_seed_data()

    def _write_seed_data(self) -> None:
        now = datetime.now(timezone.utc)
        seed_payload = {
            "users": {
                "user-001": {
                    "user_id": "user-001",
                    "name": "李秀兰",
                    "age": 72,
                    "blood_type": "A+",
                    "allergies": ["青霉素"],
                    "chronic_conditions": ["高血压", "2 型糖尿病"],
                    "avatar_url": "https://example.com/assets/avatar-li-xiulan.png",
                    "medication_list": [
                        {
                            "name": "缬沙坦胶囊",
                            "dosage": "80mg / 次",
                            "usage": "早餐后服用，每日 1 次。",
                        },
                        {
                            "name": "华法林",
                            "dosage": "2.5mg / 次",
                            "usage": "晚饭后服用，请定期监测 INR。",
                        },
                    ],
                    "current_medication_state": ["缬沙坦胶囊", "华法林"],
                    "intake_records": [
                        {
                            "medication_name": "缬沙坦胶囊",
                            "dosage": "80mg / 次",
                            "confirmed_at": (
                                now - timedelta(hours=8)
                            ).isoformat(),
                        },
                        {
                            "medication_name": "华法林",
                            "dosage": "2.5mg / 次",
                            "confirmed_at": (
                                now - timedelta(hours=20)
                            ).isoformat(),
                        },
                        {
                            "medication_name": "阿司匹林",
                            "dosage": "100mg / 次",
                            "confirmed_at": (
                                now - timedelta(hours=4)
                            ).isoformat(),
                        },
                    ],
                }
            }
        }
        self._save_raw(seed_payload)

    def _load_raw(self) -> dict[str, Any]:
        with self._storage_path.open("r", encoding="utf-8") as file:
            return json.load(file)

    def _save_raw(self, payload: dict[str, Any]) -> None:
        with self._storage_path.open("w", encoding="utf-8") as file:
            json.dump(payload, file, ensure_ascii=False, indent=2)

    def _ensure_user_payload(self, user_id: str) -> dict[str, Any]:
        payload = self._load_raw()
        users = payload.setdefault("users", {})
        if user_id not in users:
            users[user_id] = {
                "user_id": user_id,
                "name": "未命名用户",
                "age": 0,
                "blood_type": "未知",
                "allergies": [],
                "chronic_conditions": [],
                "avatar_url": "",
                "medication_list": [],
                "current_medication_state": [],
                "intake_records": [],
            }
            self._save_raw(payload)
        return payload

    def get_user_profile(self, user_id: str) -> UserProfile:
        payload = self._ensure_user_payload(user_id)
        user_data = payload["users"][user_id]
        return UserProfile(
            user_id=user_data["user_id"],
            name=user_data["name"],
            age=user_data["age"],
            blood_type=user_data["blood_type"],
            allergies=list(user_data.get("allergies", [])),
            chronic_conditions=list(user_data.get("chronic_conditions", [])),
            avatar_url=user_data.get("avatar_url", ""),
            medication_list=list(user_data.get("medication_list", [])),
            current_medication_state=list(
                user_data.get("current_medication_state", [])
            ),
            intake_records=[
                IntakeRecord(
                    medication_name=item["medication_name"],
                    dosage=item["dosage"],
                    confirmed_at=datetime.fromisoformat(item["confirmed_at"]),
                )
                for item in user_data.get("intake_records", [])
            ],
        )

    def add_medication_to_list(
        self,
        user_id: str,
        medication_name: str,
        dosage: str,
        usage: str,
    ) -> list[dict[str, str]]:
        payload = self._ensure_user_payload(user_id)
        user_data = payload["users"][user_id]

        existing = next(
            (
                item
                for item in user_data["medication_list"]
                if item["name"] == medication_name
            ),
            None,
        )
        if existing is None:
            user_data["medication_list"].append(
                {
                    "name": medication_name,
                    "dosage": dosage,
                    "usage": usage,
                }
            )
        else:
            existing["dosage"] = dosage
            existing["usage"] = usage

        if medication_name not in user_data["current_medication_state"]:
            user_data["current_medication_state"].append(medication_name)

        self._save_raw(payload)
        return list(user_data["medication_list"])

    def update_current_medication_state(
        self,
        user_id: str,
        medication_name: str,
        dosage: str,
        confirmed_at: datetime,
    ) -> UserProfile:
        payload = self._ensure_user_payload(user_id)
        user_data = payload["users"][user_id]

        if medication_name not in user_data["current_medication_state"]:
            user_data["current_medication_state"].append(medication_name)

        user_data["intake_records"].append(
            {
                "medication_name": medication_name,
                "dosage": dosage,
                "confirmed_at": confirmed_at.astimezone(timezone.utc).isoformat(),
            }
        )

        self._save_raw(payload)
        return self.get_user_profile(user_id)

    def recent_intake_records(
        self,
        user_id: str,
        hours: int = 24,
    ) -> list[IntakeRecord]:
        profile = self.get_user_profile(user_id)
        cutoff = datetime.now(timezone.utc) - timedelta(hours=hours)
        return [
            item for item in profile.intake_records if item.confirmed_at >= cutoff
        ]
