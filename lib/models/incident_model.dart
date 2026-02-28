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

  Incident copyWith({
    int? id,
    int? gasLevel,
    String? status,
    DateTime? timestamp,
    String? location,
  }) {
    return Incident(
      id: id ?? this.id,
      gasLevel: gasLevel ?? this.gasLevel,
      status: status ?? this.status,
      timestamp: timestamp ?? this.timestamp,
      location: location ?? this.location,
    );
  }

  factory Incident.fromJson(Map<String, dynamic> json) {
    try {
      return Incident(
        id: json['id'] is int
            ? json['id']
            : int.tryParse(json['id']?.toString() ?? ''),
        gasLevel: json['gas_level'] is int
            ? json['gas_level']
            : (int.tryParse(json['gas_level']?.toString() ?? '0') ?? 0),
        status: json['status']?.toString().toUpperCase() ?? 'NORMAL',
        timestamp: json['timestamp'] != null
            ? DateTime.parse(json['timestamp'].toString())
            : DateTime.now(),
        location: json['location']?.toString() ?? 'Main Sensor',
      );
    } catch (e) {
      return Incident(
        gasLevel: 0,
        status: 'ERROR',
        timestamp: DateTime.now(),
        location: 'Parse Error',
      );
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'gas_level': gasLevel,
      'status': status,
      'location': location,
      'timestamp': timestamp.toIso8601String(),
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
