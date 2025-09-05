import 'dart:math';
import '../models/weather_data.dart';

class WeatherService {
  Future<WeatherData> getCurrentWeather() async {
    // Simulate API delay
    await Future.delayed(const Duration(seconds: 2));
    
    // Generate sample weather data for Delhi
    final random = Random();
    final temperature = 20 + random.nextInt(20); // 20-40°C
    final aqi = 50 + random.nextInt(200); // 50-250 AQI
    
    return WeatherData(
      location: 'Delhi',
      temperature: temperature.toDouble(),
      feelsLike: (temperature + random.nextInt(5) - 2).toDouble(),
      description: _getWeatherDescription(temperature),
      icon: _getWeatherIcon(temperature),
      humidity: (40 + random.nextInt(40)).toDouble(),
      windSpeed: (5 + random.nextInt(15)).toDouble(),
      pressure: 1000 + random.nextInt(50),
      visibility: (5 + random.nextInt(10)).toDouble(),
      uvIndex: (1 + random.nextInt(10)).toDouble(),
      airQuality: AirQuality(
        aqi: aqi,
        level: _getAQIDescription(aqi),
        description: _getAQIDescription(aqi),
        color: _getAQIColor(aqi),
      ),
      lastUpdated: DateTime.now(),
    );
  }

  Future<List<WeatherForecast>> getWeatherForecast() async {
    // Simulate API delay
    await Future.delayed(const Duration(seconds: 1));
    
    final random = Random();
    final forecasts = <WeatherForecast>[];
    
    for (int i = 1; i <= 7; i++) {
      final date = DateTime.now().add(Duration(days: i));
      final maxTemp = 25 + random.nextInt(15);
      final minTemp = maxTemp - 8 - random.nextInt(5);
      
      forecasts.add(WeatherForecast(
        date: date,
        maxTemp: maxTemp.toDouble(),
        minTemp: minTemp.toDouble(),
        description: _getWeatherDescription(maxTemp),
        icon: _getWeatherIcon(maxTemp),
        precipitation: random.nextInt(30).toDouble(),
        humidity: (30 + random.nextInt(50)).toDouble(),
        windSpeed: (3 + random.nextInt(12)).toDouble(),
      ));
    }
    
    return forecasts;
  }

  String _getWeatherDescription(int temperature) {
    if (temperature < 15) return 'Cold';
    if (temperature < 25) return 'Cool';
    if (temperature < 35) return 'Pleasant';
    if (temperature < 40) return 'Hot';
    return 'Very Hot';
  }

  String _getWeatherIcon(int temperature) {
    if (temperature < 15) return '13d'; // snow
    if (temperature < 25) return '02d'; // few clouds
    if (temperature < 35) return '01d'; // clear sky
    if (temperature < 40) return '03d'; // scattered clouds
    return '04d'; // broken clouds
  }

  String _getAQIDescription(int aqi) {
    if (aqi <= 50) return 'Good';
    if (aqi <= 100) return 'Moderate';
    if (aqi <= 150) return 'Unhealthy for Sensitive Groups';
    if (aqi <= 200) return 'Unhealthy';
    if (aqi <= 300) return 'Very Unhealthy';
    return 'Hazardous';
  }

  String _getAQIColor(int aqi) {
    if (aqi <= 50) return '#00E400'; // Green
    if (aqi <= 100) return '#FFFF00'; // Yellow
    if (aqi <= 150) return '#FF7E00'; // Orange
    if (aqi <= 200) return '#FF0000'; // Red
    if (aqi <= 300) return '#8F3F97'; // Purple
    return '#7E0023'; // Maroon
  }
}
