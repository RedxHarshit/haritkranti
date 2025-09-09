import 'package:flutter/material.dart';
import '../services/weather_service.dart';
import 'package:translator/translator.dart';

class WeatherProvider extends ChangeNotifier {
  final WeatherService _weatherService = WeatherService();
  final translator = GoogleTranslator();
  
  WeatherData? _currentWeather;
  List<WeatherForecast> _forecast = [];
  bool _isLoading = false;
  String? _error;

  WeatherData? get currentWeather => _currentWeather;
  List<WeatherForecast> get forecast => _forecast;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchWeatherData({bool isHindi = false}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _currentWeather = await _weatherService.getCurrentWeather(isHindi: isHindi);
      _forecast = await _weatherService.getWeatherForecast();
      
      // Translate weather description if Hindi
      if (isHindi && _currentWeather != null) {
        try {
          final translatedDescription = await translator.translate(_currentWeather!.description, to: 'hi');
          _currentWeather = WeatherData(
            temperature: _currentWeather!.temperature,
            description: translatedDescription.text,
            icon: _currentWeather!.icon,
            humidity: _currentWeather!.humidity,
            windSpeed: _currentWeather!.windSpeed,
            location: _currentWeather!.location, // Already localized by Nominatim
          );
        } catch (e) {
          debugPrint('Description translation failed: $e');
        }
      }
      
      _error = null;
    } on LocationPermissionException catch (e) {
      _error = e.message;
      _currentWeather = null;
      _forecast = [];
    } catch (e) {
      String errorMsg = 'Failed to fetch weather data';
      if (e.toString().contains('No internet connection')) {
        errorMsg = 'No internet connection';
      } else if (e.toString().contains('Invalid API key')) {
        errorMsg = 'Weather API key invalid';
      } else if (e.toString().contains('timed out')) {
        errorMsg = 'Request timed out';
      }
      _error = errorMsg;
      _currentWeather = null;
      _forecast = [];
    }

    _isLoading = false;
    notifyListeners();
  }

  String getIrrigationRecommendation(double soilMoisture, {bool isHindi = false}) {
    if (_currentWeather == null) {
      return isHindi ? 'मौसम की जानकारी उपलब्ध नहीं' : 'Weather data unavailable';
    }
    return _weatherService.getIrrigationRecommendation(_currentWeather!, soilMoisture, isHindi: isHindi);
  }
}
