class MetroStation {
  final String id;
  final String name;
  final String line;
  final String lineColor;
  final double latitude;
  final double longitude;
  final List<String> facilities;
  final bool isInterchange;
  final List<String> interchangeLines;

  MetroStation({
    required this.id,
    required this.name,
    required this.line,
    required this.lineColor,
    required this.latitude,
    required this.longitude,
    this.facilities = const [],
    this.isInterchange = false,
    this.interchangeLines = const [],
  });

  factory MetroStation.fromJson(Map<String, dynamic> json) {
    return MetroStation(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      line: json['line'] ?? '',
      lineColor: json['lineColor'] ?? '#1976D2',
      latitude: (json['latitude'] ?? 0.0).toDouble(),
      longitude: (json['longitude'] ?? 0.0).toDouble(),
      facilities: List<String>.from(json['facilities'] ?? []),
      isInterchange: json['isInterchange'] ?? false,
      interchangeLines: List<String>.from(json['interchangeLines'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'line': line,
      'lineColor': lineColor,
      'latitude': latitude,
      'longitude': longitude,
      'facilities': facilities,
      'isInterchange': isInterchange,
      'interchangeLines': interchangeLines,
    };
  }
}

class MetroUpdate {
  final String id;
  final String stationId;
  final String stationName;
  final String message;
  final String type; // 'delay', 'closure', 'maintenance'
  final DateTime timestamp;
  final String severity; // 'low', 'medium', 'high'

  MetroUpdate({
    required this.id,
    required this.stationId,
    required this.stationName,
    required this.message,
    required this.type,
    required this.timestamp,
    required this.severity,
  });

  factory MetroUpdate.fromJson(Map<String, dynamic> json) {
    return MetroUpdate(
      id: json['id'] ?? '',
      stationId: json['stationId'] ?? '',
      stationName: json['stationName'] ?? '',
      message: json['message'] ?? '',
      type: json['type'] ?? 'delay',
      timestamp: DateTime.parse(json['timestamp'] ?? DateTime.now().toIso8601String()),
      severity: json['severity'] ?? 'low',
    );
  }
}

