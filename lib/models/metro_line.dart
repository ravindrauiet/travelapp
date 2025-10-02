class MetroLine {
  final String id;
  final String name;
  final String color;
  final List<MetroStation> stations;

  const MetroLine({
    required this.id,
    required this.name,
    required this.color,
    required this.stations,
  });

  factory MetroLine.fromJson(Map<String, dynamic> json) {
    return MetroLine(
      id: json['id'] as String,
      name: json['name'] as String,
      color: json['color'] as String,
      stations: (json['stations'] as List)
          .map((stationJson) => MetroStation.fromJson(stationJson))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'color': color,
      'stations': stations.map((station) => station.toJson()).toList(),
    };
  }
}

class MetroStation {
  final String id;
  final String name;
  final double latitude;
  final double longitude;
  final bool isInterchange;

  const MetroStation({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.isInterchange,
  });

  factory MetroStation.fromJson(Map<String, dynamic> json) {
    return MetroStation(
      id: json['id'] as String,
      name: json['name'] as String,
      latitude: (json['lat'] as num).toDouble(),
      longitude: (json['lng'] as num).toDouble(),
      isInterchange: json['interchange'] as bool,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'lat': latitude,
      'lng': longitude,
      'interchange': isInterchange,
    };
  }
}


