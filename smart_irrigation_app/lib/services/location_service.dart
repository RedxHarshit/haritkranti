import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:translator/translator.dart';
import 'package:flutter/material.dart';

class LocationService {
  final translator = GoogleTranslator();
  static const String _nominatimBaseUrl = 'https://nominatim.openstreetmap.org';

  Future<String> getLocalizedLocationName({
    required double lat,
    required double lng,
    required bool isHindi,
  }) async {
    if (!isHindi) {
      return await _getLocationNameFromCoords(lat, lng);
    }

    try {
      // Use OpenStreetMap Nominatim with Hindi language preference
      final uri = Uri.parse(
        '$_nominatimBaseUrl/reverse?lat=$lat&lon=$lng&format=json&accept-language=hi,en&addressdetails=1'
      );
      
      final response = await http.get(
        uri,
        headers: {
          'User-Agent': 'SmartIrrigationApp/1.0 (contact@yourapp.com)', // Required by Nominatim
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        // Extract locality/city from address components
        final address = data['address'] as Map<String, dynamic>?;
        if (address != null) {
          // Priority order: village -> suburb -> town -> city -> state
          final locationName = address['village'] ?? 
                             address['suburb'] ?? 
                             address['town'] ?? 
                             address['city'] ?? 
                             address['state'] ??
                             'Unknown';
          
          // If we got a localized name that looks different from English, use it
          if (locationName != null && locationName.toString().isNotEmpty) {
            return locationName.toString();
          }
        }
      }
    } catch (e) {
      debugPrint('Nominatim geocoding failed: $e');
    }

    // Fallback: Get English name and translate it
    final englishName = await _getLocationNameFromCoords(lat, lng);
    return await _translateWithFallback(englishName, isHindi);
  }

  Future<String> _getLocationNameFromCoords(double lat, double lng) async {
    try {
      final uri = Uri.parse(
        '$_nominatimBaseUrl/reverse?lat=$lat&lon=$lng&format=json&addressdetails=1'
      );
      
      final response = await http.get(
        uri,
        headers: {
          'User-Agent': 'SmartIrrigationApp/1.0 (contact@yourapp.com)',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final address = data['address'] as Map<String, dynamic>?;
        
        if (address != null) {
          return address['village'] ?? 
                 address['suburb'] ?? 
                 address['town'] ?? 
                 address['city'] ?? 
                 address['state'] ??
                 'Unknown Location';
        }
      }
    } catch (e) {
      debugPrint('Nominatim geocoding failed: $e');
    }
    
    return 'Unknown Location';
  }

  Future<String> _translateWithFallback(String text, bool isHindi) async {
    if (!isHindi || text == 'Unknown Location') return text;
    
    try {
      final translation = await translator.translate(text, to: 'hi');
      return translation.text;
    } catch (e) {
      return text; // Return original if translation fails
    }
  }
}
