class WeatherData {
  final String location;
  final double temperature;
  final double feelsLike;
  final String description;
  final String icon;
  final double humidity;
  final double windSpeed;
  final int pressure;
  final double visibility;
  final double uvIndex;
  final AirQuality airQuality;
  final DateTime lastUpdated;

  const WeatherData({
    required this.location,
    required this.temperature,
    required this.feelsLike,
    required this.description,
    required this.icon,
    required this.humidity,
    required this.windSpeed,
    required this.pressure,
    required this.visibility,
    required this.uvIndex,
    required this.airQuality,
    required this.lastUpdated,
  });

  factory WeatherData.fromJson(Map<String, dynamic> json) {
    return WeatherData(
      location: json['location'] ?? 'Delhi',
      temperature: (json['temperature'] ?? 0.0).toDouble(),
      feelsLike: (json['feelsLike'] ?? 0.0).toDouble(),
      description: json['description'] ?? 'Clear',
      icon: json['icon'] ?? '01d',
      humidity: (json['humidity'] ?? 0.0).toDouble(),
      windSpeed: (json['windSpeed'] ?? 0.0).toDouble(),
      pressure: json['pressure'] ?? 1013,
      visibility: (json['visibility'] ?? 0.0).toDouble(),
      uvIndex: (json['uvIndex'] ?? 0.0).toDouble(),
      airQuality: AirQuality.fromJson(json['airQuality'] ?? {}),
      lastUpdated: DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'location': location,
      'temperature': temperature,
      'feelsLike': feelsLike,
      'description': description,
      'icon': icon,
      'humidity': humidity,
      'windSpeed': windSpeed,
      'pressure': pressure,
      'visibility': visibility,
      'uvIndex': uvIndex,
      'airQuality': airQuality.toJson(),
      'lastUpdated': lastUpdated.toIso8601String(),
    };
  }
}

class AirQuality {
  final int aqi;
  final String level;
  final String description;
  final String color;

  const AirQuality({
    required this.aqi,
    required this.level,
    required this.description,
    required this.color,
  });

  factory AirQuality.fromJson(Map<String, dynamic> json) {
    final aqi = json['aqi'] ?? 0;
    String level;
    String description;
    String color;

    if (aqi <= 50) {
      level = 'Good';
      description = 'Air quality is satisfactory';
      color = '#4CAF50';
    } else if (aqi <= 100) {
      level = 'Moderate';
      description = 'Air quality is acceptable';
      color = '#FFC107';
    } else if (aqi <= 150) {
      level = 'Unhealthy for Sensitive Groups';
      description = 'Members of sensitive groups may experience health effects';
      color = '#FF9800';
    } else if (aqi <= 200) {
      level = 'Unhealthy';
      description = 'Everyone may begin to experience health effects';
      color = '#F44336';
    } else if (aqi <= 300) {
      level = 'Very Unhealthy';
      description = 'Health warnings of emergency conditions';
      color = '#9C27B0';
    } else {
      level = 'Hazardous';
      description = 'Health alert: everyone may experience more serious health effects';
      color = '#795548';
    }

    return AirQuality(
      aqi: aqi,
      level: level,
      description: description,
      color: color,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'aqi': aqi,
      'level': level,
      'description': description,
      'color': color,
    };
  }
}

class WeatherForecast {
  final DateTime date;
  final double maxTemp;
  final double minTemp;
  final String description;
  final String icon;
  final double humidity;
  final double windSpeed;
  final double precipitation;

  const WeatherForecast({
    required this.date,
    required this.maxTemp,
    required this.minTemp,
    required this.description,
    required this.icon,
    required this.humidity,
    required this.windSpeed,
    required this.precipitation,
  });

  factory WeatherForecast.fromJson(Map<String, dynamic> json) {
    return WeatherForecast(
      date: DateTime.parse(json['date'] ?? DateTime.now().toIso8601String()),
      maxTemp: (json['maxTemp'] ?? 0.0).toDouble(),
      minTemp: (json['minTemp'] ?? 0.0).toDouble(),
      description: json['description'] ?? 'Clear',
      icon: json['icon'] ?? '01d',
      humidity: (json['humidity'] ?? 0.0).toDouble(),
      windSpeed: (json['windSpeed'] ?? 0.0).toDouble(),
      precipitation: (json['precipitation'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'date': date.toIso8601String(),
      'maxTemp': maxTemp,
      'minTemp': minTemp,
      'description': description,
      'icon': icon,
      'humidity': humidity,
      'windSpeed': windSpeed,
      'precipitation': precipitation,
    };
  }
}
