import 'package:flutter/material.dart';
import '../models/weather_data.dart';
import '../services/weather_service.dart';

class WeatherProvider extends ChangeNotifier {
  final WeatherService _weatherService = WeatherService();
  
  WeatherData? _currentWeather;
  List<WeatherForecast> _forecast = [];
  bool _isLoading = false;
  String? _error;

  WeatherData? get currentWeather => _currentWeather;
  List<WeatherForecast> get forecast => _forecast;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadWeather() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _currentWeather = await _weatherService.getCurrentWeather();
      _forecast = await _weatherService.getWeatherForecast();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Error loading weather data: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}

