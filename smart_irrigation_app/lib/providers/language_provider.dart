import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageProvider extends ChangeNotifier {
  bool _isHindi = false;
  
  bool get isHindi => _isHindi;

  LanguageProvider() {
    _loadLanguage();
  }

  void toggleLanguage() {
    _isHindi = !_isHindi;
    _saveLanguage();
    notifyListeners(); // This will automatically rebuild all listening widgets
  }

  Future<void> _loadLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    _isHindi = prefs.getBool('isHindi') ?? false;
    notifyListeners();
  }

  Future<void> _saveLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isHindi', _isHindi);
  }
}
