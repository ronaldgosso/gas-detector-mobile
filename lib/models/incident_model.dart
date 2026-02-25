class Incident {
  final int? id;
  final int gasLevel;
  final String status;
  final DateTime timestamp;
  final String location;

  Incident({
    this.id,
    required this.gasLevel,
    required this.status,
    required this.timestamp,
    this.location = 'Main Sensor',
  });

  factory Incident.fromJson(Map<String, dynamic> json) {
    return Incident(
      id: json['id'],
      gasLevel: json['gas_level'] ?? 0,
      status: json['status'] ?? 'NORMAL',
      timestamp: DateTime.parse(json['timestamp']),
      location: json['location'] ?? 'Main Sensor',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'gas_level': gasLevel,
      'status': status,
      'location': location,
    };
  }

  bool get isAlert => status == 'ALERT';
  bool get isNormal => status == 'NORMAL';

  String get formattedTime {
    return '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
  }

  String get formattedDate {
    return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
  }

  String get statusColor {
    if (isAlert) return '#EF4444';
    return '#22C55E';
  }
}