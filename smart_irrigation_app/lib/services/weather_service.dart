import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'location_service.dart';

class LocationPermissionException implements Exception {
  final String message;
  LocationPermissionException(this.message);
  
  @override
  String toString() => 'LocationPermissionException: $message';
}

class WeatherService {
  static final String _apiKey = dotenv.env['OPENWEATHER_API_KEY'] ?? 'default_fallback_key';
  static const String _baseUrl = 'https://api.openweathermap.org/data/2.5';
  
  final LocationService _locationService = LocationService();

  Future<Position> _getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw LocationPermissionException('Location services are disabled');
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw LocationPermissionException('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw LocationPermissionException('Location permissions are permanently denied');
    }

    return await Geolocator.getCurrentPosition().timeout(const Duration(seconds: 10));
  }

  Future<WeatherData> getCurrentWeather({bool isHindi = false}) async {
    try {
      final position = await _getCurrentLocation();
      final url = Uri.parse(
        '$_baseUrl/weather?lat=${position.latitude}&lon=${position.longitude}&appid=$_apiKey&units=metric'
      );

      final response = await http.get(url).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        // Get localized location name using free Nominatim service
        final localizedLocation = await _locationService.getLocalizedLocationName(
          lat: position.latitude,
          lng: position.longitude,
          isHindi: isHindi,
        );
        
        return WeatherData.fromJson(data, localizedLocation);
      } else if (response.statusCode == 401) {
        throw Exception('Invalid OpenWeather API key');
      } else {
        throw Exception('Weather API error: ${response.statusCode}');
      }
    } on SocketException catch (_) {
      throw Exception('No internet connection');
    } on TimeoutException catch (_) {
      throw Exception('Request timed out');
    } on LocationPermissionException {
      rethrow;
    } catch (e) {
      throw Exception('Error fetching weather: $e');
    }
  }

  Future<List<WeatherForecast>> getWeatherForecast() async {
    try {
      final position = await _getCurrentLocation();
      final url = Uri.parse(
        '$_baseUrl/forecast?lat=${position.latitude}&lon=${position.longitude}&appid=$_apiKey&units=metric'
      );

      final response = await http.get(url).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return (data['list'] as List)
            .map((item) => WeatherForecast.fromJson(item))
            .toList();
      } else {
        throw Exception('Forecast API error: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching forecast: $e');
    }
  }

  String getIrrigationRecommendation(WeatherData weather, double soilMoisture, {bool isHindi = false}) {
    if (weather.description.toLowerCase().contains('rain') || 
        weather.description.toLowerCase().contains('drizzle')) {
      return isHindi ? 'बारिश की संभावना - सिंचाई न करें' : 'Rain expected - Skip irrigation';
    }

    if (weather.humidity > 80) {
      return soilMoisture < 30 
        ? (isHindi ? 'हल्की सिंचाई की सिफारिश' : 'Light irrigation recommended')
        : (isHindi ? 'सिंचाई की जरूरत नहीं' : 'No irrigation needed');
    }

    if (weather.temperature > 30 && weather.humidity < 50) {
      return soilMoisture < 40 
        ? (isHindi ? 'तुरंत सिंचाई की जरूरत' : 'Immediate irrigation needed')
        : (isHindi ? 'मिट्टी की नमी पर ध्यान दें' : 'Monitor soil moisture closely');
    }

    return soilMoisture < 35 
      ? (isHindi ? 'सिंचाई की सिफारिश' : 'Irrigation recommended')
      : (isHindi ? 'मिट्टी की नमी पर्याप्त है' : 'Soil moisture adequate');
  }
}

class WeatherData {
  final double temperature;
  final String description;
  final String icon;
  final int humidity;
  final double windSpeed;
  final String location;

  WeatherData({
    required this.temperature,
    required this.description,
    required this.icon,
    required this.humidity,
    required this.windSpeed,
    required this.location,
  });

  factory WeatherData.fromJson(Map<String, dynamic> json, String localizedLocation) {
    return WeatherData(
      temperature: (json['main']['temp'] as num).toDouble(),
      description: json['weather'][0]['description'],
      icon: json['weather'][0]['icon'],
      humidity: json['main']['humidity'],
      windSpeed: (json['wind']?['speed'] as num?)?.toDouble() ?? 0.0,
      location: localizedLocation, // Use the localized location name
    );
  }
}

class WeatherForecast {
  final DateTime dateTime;
  final double temperature;
  final String description;
  final String icon;
  final double rainProbability;

  WeatherForecast({
    required this.dateTime,
    required this.temperature,
    required this.description,
    required this.icon,
    required this.rainProbability,
  });

  factory WeatherForecast.fromJson(Map<String, dynamic> json) {
    return WeatherForecast(
      dateTime: DateTime.fromMillisecondsSinceEpoch(json['dt'] * 1000),
      temperature: (json['main']['temp'] as num).toDouble(),
      description: json['weather'][0]['description'],
      icon: json['weather'][0]['icon'],
      rainProbability: ((json['pop'] ?? 0.0) as num).toDouble() * 100,
    );
  }
}
