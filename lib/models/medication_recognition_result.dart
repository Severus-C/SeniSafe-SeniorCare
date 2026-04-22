class MedicationRecognitionResult {
  const MedicationRecognitionResult({
    required this.status,
    required this.message,
    this.imageId,
    this.imagePath,
    this.medication,
    this.conflictWarning,
    this.currentMedicationState = const <String>[],
  });

  final String status;
  final String message;
  final String? imageId;
  final String? imagePath;
  final RecognizedMedicationDetail? medication;
  final MedicationConflictWarning? conflictWarning;
  final List<String> currentMedicationState;

  bool get hasConflict => conflictWarning != null;
  bool get isRecognized => medication != null && status == 'recognized';

  factory MedicationRecognitionResult.fromJson(Map<String, dynamic> json) {
    return MedicationRecognitionResult(
      status: json['status'] as String? ?? 'failed',
      message: json['message'] as String? ?? '识别未完成，请稍后再试。',
      imageId: json['image_id'] as String?,
      imagePath: json['image_path'] as String?,
      medication: json['medication'] is Map<String, dynamic>
          ? RecognizedMedicationDetail.fromJson(
              json['medication'] as Map<String, dynamic>,
            )
          : null,
      conflictWarning: json['conflict_warning'] is Map<String, dynamic>
          ? MedicationConflictWarning.fromJson(
              json['conflict_warning'] as Map<String, dynamic>,
            )
          : null,
      currentMedicationState:
          (json['current_medication_state'] as List<dynamic>? ?? <dynamic>[])
              .map((dynamic item) => item.toString())
              .toList(),
    );
  }
}

class MedicationConfirmResult {
  const MedicationConfirmResult({
    required this.status,
    required this.message,
    required this.medicationList,
  });

  final String status;
  final String message;
  final List<ConfirmedMedicationItem> medicationList;

  bool get isSaved => status == 'saved';
  bool get isBlockedByConflict => status == 'conflict_blocked';

  factory MedicationConfirmResult.fromJson(Map<String, dynamic> json) {
    return MedicationConfirmResult(
      status: json['status'] as String? ?? 'failed',
      message: json['message'] as String? ?? '药物录入暂未成功。',
      medicationList: (json['medication_list'] as List<dynamic>? ?? <dynamic>[])
          .whereType<Map<String, dynamic>>()
          .map(ConfirmedMedicationItem.fromJson)
          .toList(),
    );
  }
}

class ConfirmedMedicationItem {
  const ConfirmedMedicationItem({
    required this.name,
    required this.dosage,
    required this.usage,
  });

  final String name;
  final String dosage;
  final String usage;

  factory ConfirmedMedicationItem.fromJson(Map<String, dynamic> json) {
    return ConfirmedMedicationItem(
      name: json['name'] as String? ?? '未知药物',
      dosage: json['dosage'] as String? ?? '未记录',
      usage: json['usage'] as String? ?? '请遵医嘱',
    );
  }
}

class RecognizedMedicationDetail {
  const RecognizedMedicationDetail({
    required this.name,
    required this.dosage,
    required this.usage,
    required this.contraindications,
    required this.sourceText,
  });

  final String name;
  final String dosage;
  final String usage;
  final String contraindications;
  final String sourceText;

  factory RecognizedMedicationDetail.fromJson(Map<String, dynamic> json) {
    return RecognizedMedicationDetail(
      name: json['name'] as String? ?? '未知药物',
      dosage: json['dosage'] as String? ?? '请咨询医生',
      usage: json['usage'] as String? ?? '请遵医嘱使用',
      contraindications: json['contraindications'] as String? ?? '暂无',
      sourceText: json['source_text'] as String? ?? '',
    );
  }
}

class MedicationConflictWarning {
  const MedicationConflictWarning({
    required this.interactingMedication,
    required this.riskLevel,
    required this.summary,
    required this.detail,
    required this.voicePrompt,
  });

  final String interactingMedication;
  final String riskLevel;
  final String summary;
  final String detail;
  final String voicePrompt;

  factory MedicationConflictWarning.fromJson(Map<String, dynamic> json) {
    return MedicationConflictWarning(
      interactingMedication:
          json['interacting_medication'] as String? ?? '未知药物',
      riskLevel: json['risk_level'] as String? ?? 'caution',
      summary: json['summary'] as String? ?? '存在药物冲突风险',
      detail: json['detail'] as String? ?? '请先咨询医生后再继续服药。',
      voicePrompt: json['voice_prompt'] as String? ??
          '注意，这个药和您正在服用的药物可能有冲突，请先咨询医生。',
    );
  }
}
