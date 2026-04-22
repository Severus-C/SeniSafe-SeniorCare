enum MedicationIntakeState { pending, confirmed, missed }

enum ConflictLevel { none, caution, highRisk }

class MedicationConflict {
  const MedicationConflict({
    required this.level,
    required this.summary,
    required this.detail,
  });

  final ConflictLevel level;
  final String summary;
  final String detail;
}

class Medication {
  const Medication({
    required this.id,
    required this.name,
    required this.dosage,
    required this.scheduleLabel,
    required this.instructions,
    required this.requiresFaceScan,
    required this.intakeState,
    this.conflict,
  });

  final String id;
  final String name;
  final String dosage;
  final String scheduleLabel;
  final String instructions;
  final bool requiresFaceScan;
  final MedicationIntakeState intakeState;
  final MedicationConflict? conflict;

  Medication copyWith({
    MedicationIntakeState? intakeState,
    MedicationConflict? conflict,
  }) {
    return Medication(
      id: id,
      name: name,
      dosage: dosage,
      scheduleLabel: scheduleLabel,
      instructions: instructions,
      requiresFaceScan: requiresFaceScan,
      intakeState: intakeState ?? this.intakeState,
      conflict: conflict ?? this.conflict,
    );
  }
}
