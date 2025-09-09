import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'dart:math';
import '../services/notification_service.dart';

class IrrigationProvider extends ChangeNotifier {
  bool _irrigationEnabled = false;
  SensorData _currentData = SensorData();
  Timer? _dataUpdateTimer;
  Timer? _monitoringTimer;
  List<AppNotification> _notifications = []; // Add notifications list

  bool get irrigationEnabled => _irrigationEnabled;
  SensorData get currentData => _currentData;
  List<AppNotification> get notifications => _notifications; // Add getter

  IrrigationProvider() {
    _loadIrrigationState();
    _startDataSimulation();
    _startMonitoring();
    _initializeNotifications();
  }

  void _initializeNotifications() {
    // Add some sample notifications
    _notifications = [
      AppNotification(
        id: '1',
        title: 'System Started',
        message: 'Smart irrigation system is now active',
        timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
        type: NotificationType.info,
      ),
      AppNotification(
        id: '2',
        title: 'Battery Status',
        message: 'System battery level is at 78%',
        timestamp: DateTime.now().subtract(const Duration(minutes: 10)),
        type: NotificationType.info,
      ),
    ];
  }

  void _startDataSimulation() {
    _dataUpdateTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      _updateSensorData();
    });
  }

  void _startMonitoring() {
    _monitoringTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      _performSystemChecks();
    });
  }

  void _updateSensorData() {
    final random = Random();
    
    // Simulate battery discharge
    _currentData.batteryLevel = (_currentData.batteryLevel - random.nextDouble() * 0.5).clamp(0, 100);
    
    // Simulate tank levels
    _currentData.upperTankLevel = (_currentData.upperTankLevel + random.nextDouble() * 2 - 1).clamp(0, 100);
    _currentData.lowerTankLevel = (_currentData.lowerTankLevel + random.nextDouble() * 2 - 1).clamp(0, 100);
    
    // Update zones
    for (int i = 0; i < _currentData.zones.length; i++) {
      final zone = _currentData.zones[i];
      if (_irrigationEnabled && zone.isActive) {
        zone.soilMoisture = (zone.soilMoisture + random.nextDouble() * 3).clamp(0, 100);
      } else {
        zone.soilMoisture = (zone.soilMoisture - random.nextDouble() * 1).clamp(0, 100);
      }
    }
    
    notifyListeners();
  }

  void _performSystemChecks() {
    // Check battery level
    if (_currentData.batteryLevel < 20) {
      _addNotification(
        'Low Battery Warning',
        'System battery is below 20%. Please charge.',
        NotificationType.warning,
      );
    }
    
    // Check soil moisture levels
    for (final zone in _currentData.zones) {
      if (zone.soilMoisture > 80) {
        _addNotification(
          'High Moisture Alert',
          '${zone.name} soil moisture is too high',
          NotificationType.warning,
        );
      } else if (zone.soilMoisture < 20) {
        _addNotification(
          'Water Needed',
          '${zone.name} needs water',
          NotificationType.alert,
        );
      }
    }
  }

  void _addNotification(String title, String message, NotificationType type) {
    final notification = AppNotification(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      message: message,
      timestamp: DateTime.now(),
      type: type,
    );
    _notifications.insert(0, notification); // Add to beginning of list
    notifyListeners();
  }

  void toggleIrrigation() {
    _irrigationEnabled = !_irrigationEnabled;
    
    _addNotification(
      _irrigationEnabled ? 'Irrigation Started' : 'Irrigation Stopped',
      _irrigationEnabled 
        ? 'Irrigation has started in your crop zones'
        : 'Irrigation has been stopped',
      NotificationType.info,
    );
    
    notifyListeners();
    _saveIrrigationState();
  }

  // Add method to update irrigation with language context
  void toggleIrrigationWithLanguage(bool isHindi) {
    _irrigationEnabled = !_irrigationEnabled;
    
    if (_irrigationEnabled) {
      NotificationService.showIrrigationStarted(isHindi);
      _addNotification(
        'Irrigation Started',
        'Irrigation has started in your crop zones',
        NotificationType.info,
      );
    } else {
      NotificationService.showIrrigationCompleted(isHindi);
      _addNotification(
        'Irrigation Stopped',
        'Irrigation has been stopped',
        NotificationType.info,
      );
    }
    
    notifyListeners();
    _saveIrrigationState();
  }

  void toggleZone(String zoneId) {
    final zoneIndex = _currentData.zones.indexWhere((zone) => zone.id == zoneId);
    if (zoneIndex != -1) {
      _currentData.zones[zoneIndex].isActive = !_currentData.zones[zoneIndex].isActive;
      final zone = _currentData.zones[zoneIndex];
      
      _addNotification(
        'Zone ${zone.isActive ? 'Activated' : 'Deactivated'}',
        '${zone.name} has been ${zone.isActive ? 'activated' : 'deactivated'}',
        NotificationType.info,
      );
      
      notifyListeners();
    }
  }

  void updateZoneMoisture(String zoneId, double newMoisture) {
    final zoneIndex = _currentData.zones.indexWhere((zone) => zone.id == zoneId);
    if (zoneIndex != -1) {
      _currentData.zones[zoneIndex].soilMoisture = newMoisture;
      notifyListeners();
    }
  }

  // Add clear notifications method
  void clearNotifications() {
    _notifications.clear();
    notifyListeners();
  }

  // Add method to remove single notification
  void removeNotification(String id) {
    _notifications.removeWhere((notification) => notification.id == id);
    notifyListeners();
  }

  // Add battery monitoring method
  void checkBatteryLevel(bool isHindi) {
    if (_currentData.batteryLevel < 20) {
      NotificationService.showLowBatteryWarning(isHindi);
    }
  }

  // Add soil moisture monitoring
  void checkSoilMoisture(bool isHindi) {
    for (final zone in _currentData.zones) {
      if (zone.soilMoisture > 80) {
        NotificationService.showHighSoilMoisture(zone.name, isHindi);
      } else if (zone.soilMoisture < 20) {
        NotificationService.showLowSoilMoisture(zone.name, isHindi);
      }
    }
  }

  // Add manual check methods that can be called from UI
  void performBatteryCheck(bool isHindi) {
    checkBatteryLevel(isHindi);
  }

  void performSoilMoistureCheck(bool isHindi) {
    checkSoilMoisture(isHindi);
  }

  Future<void> _loadIrrigationState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _irrigationEnabled = prefs.getBool('irrigation_enabled') ?? false;
    } catch (e) {
      debugPrint('Error loading irrigation state: $e');
    }
  }

  Future<void> _saveIrrigationState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('irrigation_enabled', _irrigationEnabled);
    } catch (e) {
      debugPrint('Error saving irrigation state: $e');
    }
  }

  @override
  void dispose() {
    _dataUpdateTimer?.cancel();
    _monitoringTimer?.cancel();
    super.dispose();
  }
}

// Add notification classes
class AppNotification {
  final String id;
  final String title;
  final String message;
  final DateTime timestamp;
  final NotificationType type;

  AppNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.timestamp,
    required this.type,
  });
}

enum NotificationType {
  info,
  warning,
  alert,
  success,
}

class SensorData {
  double batteryLevel;
  double upperTankLevel;
  double lowerTankLevel;
  List<CropZone> zones;

  SensorData({
    this.batteryLevel = 78.0,
    this.upperTankLevel = 65.0,
    this.lowerTankLevel = 88.0,
    List<CropZone>? zones,
  }) : zones = zones ?? [
          CropZone(
            id: 'zone_1',
            name: 'Zone 1 - Tomatoes',
            cropType: 'Tomatoes',
            soilMoisture: 45.0,
            optimalMoistureMin: 40.0,
            optimalMoistureMax: 70.0,
            isActive: true,
          ),
          CropZone(
            id: 'zone_2',
            name: 'Zone 2 - Peppers',
            cropType: 'Peppers',
            soilMoisture: 25.0,
            optimalMoistureMin: 35.0,
            optimalMoistureMax: 65.0,
            isActive: false,
          ),
          CropZone(
            id: 'zone_3',
            name: 'Zone 3 - Spinach',
            cropType: 'Spinach',
            soilMoisture: 60.0,
            optimalMoistureMin: 45.0,
            optimalMoistureMax: 75.0,
            isActive: true,
          ),
        ];

  double get averageSoilMoisture {
    if (zones.isEmpty) return 0.0;
    return zones.map((zone) => zone.soilMoisture).reduce((a, b) => a + b) / zones.length;
  }
}

class CropZone {
  final String id;
  final String name;
  final String cropType;
  double soilMoisture;
  final double optimalMoistureMin;
  final double optimalMoistureMax;
  bool isActive;

  CropZone({
    required this.id,
    required this.name,
    required this.cropType,
    required this.soilMoisture,
    required this.optimalMoistureMin,
    required this.optimalMoistureMax,
    required this.isActive,
  });

  Color get statusColor {
    if (soilMoisture >= optimalMoistureMin && soilMoisture <= optimalMoistureMax) {
      return Colors.green;
    } else if (soilMoisture < optimalMoistureMin) {
      return Colors.red;
    } else {
      return Colors.orange;
    }
  }

  String get moistureStatus {
    if (soilMoisture >= optimalMoistureMin && soilMoisture <= optimalMoistureMax) {
      return 'Optimal';
    } else if (soilMoisture < optimalMoistureMin) {
      return 'Needs water';
    } else {
      return 'Over-watered';
    }
  }
}
