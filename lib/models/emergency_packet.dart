class EmergencyPreparePacketResponse {
  const EmergencyPreparePacketResponse({
    required this.packetId,
    required this.generatedAt,
    required this.summary,
    required this.currentMedicationState,
    required this.recentIntakeRecords,
  });

  final String packetId;
  final DateTime generatedAt;
  final String summary;
  final List<String> currentMedicationState;
  final List<EmergencyIntakeRecord> recentIntakeRecords;

  factory EmergencyPreparePacketResponse.fromJson(Map<String, dynamic> json) {
    return EmergencyPreparePacketResponse(
      packetId: json['packet_id'] as String? ?? 'packet-local',
      generatedAt: DateTime.tryParse(json['generated_at'] as String? ?? '') ??
          DateTime.now(),
      summary: json['summary'] as String? ?? '已生成急救数据包。',
      currentMedicationState:
          (json['current_medication_state'] as List<dynamic>? ?? <dynamic>[])
              .map((dynamic item) => item.toString())
              .toList(),
      recentIntakeRecords:
          (json['recent_intake_records'] as List<dynamic>? ?? <dynamic>[])
              .whereType<Map<String, dynamic>>()
              .map(EmergencyIntakeRecord.fromJson)
              .toList(),
    );
  }
}

class EmergencyPacketCard {
  const EmergencyPacketCard({
    required this.packetId,
    required this.generatedAt,
    required this.summary,
    required this.avatarUrl,
    required this.patientName,
    required this.age,
    required this.bloodType,
    required this.allergies,
    required this.chronicConditions,
    required this.currentMedicationState,
    required this.riskNotice,
    required this.recentIntakeRecords,
  });

  final String packetId;
  final DateTime generatedAt;
  final String summary;
  final String avatarUrl;
  final String patientName;
  final int age;
  final String bloodType;
  final List<String> allergies;
  final List<String> chronicConditions;
  final List<String> currentMedicationState;
  final String riskNotice;
  final List<EmergencyIntakeRecord> recentIntakeRecords;

  bool get hasHighRiskNotice => riskNotice.contains('抗凝药');

  factory EmergencyPacketCard.fromJson(Map<String, dynamic> json) {
    return EmergencyPacketCard(
      packetId: json['packet_id'] as String? ?? 'packet-card',
      generatedAt: DateTime.tryParse(json['generated_at'] as String? ?? '') ??
          DateTime.now(),
      summary: json['summary'] as String? ?? '数字化急救名片已生成。',
      avatarUrl: json['avatar_url'] as String? ?? '',
      patientName: json['patient_name'] as String? ?? '未知患者',
      age: json['age'] as int? ?? 0,
      bloodType: json['blood_type'] as String? ?? '未知',
      allergies: (json['allergies'] as List<dynamic>? ?? <dynamic>[])
          .map((dynamic item) => item.toString())
          .toList(),
      chronicConditions:
          (json['chronic_conditions'] as List<dynamic>? ?? <dynamic>[])
              .map((dynamic item) => item.toString())
              .toList(),
      currentMedicationState:
          (json['current_medication_state'] as List<dynamic>? ?? <dynamic>[])
              .map((dynamic item) => item.toString())
              .toList(),
      riskNotice: json['risk_notice'] as String? ?? '请继续核对病史。',
      recentIntakeRecords:
          (json['recent_intake_records'] as List<dynamic>? ?? <dynamic>[])
              .whereType<Map<String, dynamic>>()
              .map(EmergencyIntakeRecord.fromJson)
              .toList(),
    );
  }
}

class EmergencyIntakeRecord {
  const EmergencyIntakeRecord({
    required this.medicationName,
    required this.dosage,
    required this.confirmedAt,
  });

  final String medicationName;
  final String dosage;
  final DateTime confirmedAt;

  factory EmergencyIntakeRecord.fromJson(Map<String, dynamic> json) {
    return EmergencyIntakeRecord(
      medicationName: json['medication_name'] as String? ?? '未知药物',
      dosage: json['dosage'] as String? ?? '未记录',
      confirmedAt: DateTime.tryParse(json['confirmed_at'] as String? ?? '') ??
          DateTime.now(),
    );
  }
}
