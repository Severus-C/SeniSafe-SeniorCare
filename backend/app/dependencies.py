from .services.emergency_service import EmergencyService
from .services.medication_engine import MedicationEngine
from .services.store import JsonMedicationStore

store = JsonMedicationStore()
medication_engine = MedicationEngine(store=store)
emergency_service = EmergencyService(store=store)
