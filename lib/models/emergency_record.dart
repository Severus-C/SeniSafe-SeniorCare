enum EmergencyStatus { preparing, dispatched, completed }

class EmergencyRecord {
  const EmergencyRecord({
    required this.id,
    required this.triggeredAt,
    required this.reason,
    required this.status,
    required this.packetSummary,
    this.latitude,
    this.longitude,
  });

  final String id;
  final DateTime triggeredAt;
  final String reason;
  final EmergencyStatus status;
  final String packetSummary;
  final double? latitude;
  final double? longitude;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'triggeredAt': triggeredAt.toIso8601String(),
      'reason': reason,
      'status': status.name,
      'packetSummary': packetSummary,
      'latitude': latitude,
      'longitude': longitude,
    };
  }
}
