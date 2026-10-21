import 'dart:math';
import '../models/weather_data.dart';

class WeatherService {
  Future<WeatherData> getCurrentWeather() async {
    // Realistic simulation of Delhi NCR weather
    await Future.delayed(const Duration(milliseconds: 400));
    
    final random = Random();
    // Delhi pleasant/mild temperature
    final temperature = 24 + random.nextInt(8); // 24–31°C
    // Delhi typical AQI (Moderate to Poor)
    final aqi = 110 + random.nextInt(75); // 110–184 AQI
    
    return WeatherData(
      location: 'Delhi NCR',
      temperature: temperature.toDouble(),
      feelsLike: (temperature + 1).toDouble(),
      description: _getWeatherDescription(temperature),
      icon: _getWeatherIcon(temperature),
      humidity: (45 + random.nextInt(20)).toDouble(),
      windSpeed: (8 + random.nextInt(8)).toDouble(),
      pressure: 1011 + random.nextInt(5), // Realistic 1011–1015 hPa for Delhi
      visibility: 4.5,
      uvIndex: 4.0,
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
    await Future.delayed(const Duration(milliseconds: 300));
    
    final random = Random();
    final forecasts = <WeatherForecast>[];
    final now = DateTime.now();
    
    // Day 0 = Today, Day 1 = Tomorrow, Day 2..6 = Subsequent days
    for (int i = 0; i < 7; i++) {
      final date = DateTime(now.year, now.month, now.day).add(Duration(days: i));
      final maxTemp = 28 + random.nextInt(6);
      final minTemp = maxTemp - 9 - random.nextInt(3);
      
      forecasts.add(WeatherForecast(
        date: date,
        maxTemp: maxTemp.toDouble(),
        minTemp: minTemp.toDouble(),
        description: i == 0 ? 'Hazy Sunshine' : (i == 1 ? 'Partly Cloudy' : _getWeatherDescription(maxTemp)),
        icon: _getWeatherIcon(maxTemp),
        precipitation: random.nextInt(15).toDouble(),
        humidity: (40 + random.nextInt(25)).toDouble(),
        windSpeed: (6 + random.nextInt(8)).toDouble(),
      ));
    }
    
    return forecasts;
  }

  String _getWeatherDescription(int temperature) {
    if (temperature < 15) return 'Cold & Foggy';
    if (temperature < 25) return 'Pleasant';
    if (temperature < 35) return 'Warm & Sunny';
    if (temperature < 40) return 'Hot';
    return 'Heatwave';
  }

  String _getWeatherIcon(int temperature) {
    if (temperature < 15) return '13d';
    if (temperature < 25) return '02d';
    if (temperature < 35) return '01d';
    return '01d';
  }

  /// Official Central Pollution Control Board (CPCB) India AQI Classification:
  /// 0–50: Good
  /// 51–100: Satisfactory
  /// 101–200: Moderate
  /// 201–300: Poor
  /// 301–400: Very Poor
  /// 401–500: Severe
  static String _getAQIDescription(int aqi) {
    if (aqi <= 50) return 'Good';
    if (aqi <= 100) return 'Satisfactory';
    if (aqi <= 200) return 'Moderate';
    if (aqi <= 300) return 'Poor';
    if (aqi <= 400) return 'Very Poor';
    return 'Severe';
  }

  static String _getAQIColor(int aqi) {
    if (aqi <= 50) return '#10B981'; // Green
    if (aqi <= 100) return '#84CC16'; // Light Green
    if (aqi <= 200) return '#F59E0B'; // Amber / Yellow
    if (aqi <= 300) return '#F97316'; // Orange
    if (aqi <= 400) return '#EF4444'; // Red
    return '#881337'; // Maroon
  }
}
