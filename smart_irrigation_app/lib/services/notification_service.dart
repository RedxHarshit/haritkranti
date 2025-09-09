import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:translator/translator.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();
  static final translator = GoogleTranslator();

  static Future<void> initialize() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: DarwinInitializationSettings(
        requestSoundPermission: true,
        requestBadgePermission: true,
        requestAlertPermission: true,
      ),
    );

    await _notificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        debugPrint('Notification tapped: ${response.payload}');
      },
    );

    // Create notification channel for Android
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'smart_irrigation_channel',
      'Smart Irrigation Notifications',
      description: 'Notifications for smart irrigation system',
      importance: Importance.max,
      playSound: true,
    );

    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    // Request permissions
    await _requestPermissions();
  }

  static Future<void> _requestPermissions() async {
    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
  }

  static Future<void> showLocalizedNotification({
    required int id,
    required String title,
    required String body,
    required bool isHindi,
    String? payload,
  }) async {
    try {
      String localizedTitle = title;
      String localizedBody = body;

      if (isHindi) {
        try {
          final translatedTitle = await translator.translate(title, to: 'hi');
          final translatedBody = await translator.translate(body, to: 'hi');
          localizedTitle = translatedTitle.text;
          localizedBody = translatedBody.text;
        } catch (e) {
          debugPrint('Translation failed: $e');
        }
      }

      const NotificationDetails platformChannelSpecifics = NotificationDetails(
        android: AndroidNotificationDetails(
          'smart_irrigation_channel',
          'Smart Irrigation Notifications',
          channelDescription: 'Notifications for smart irrigation system',
          importance: Importance.max,
          priority: Priority.high,
          showWhen: true,
          playSound: true,
          icon: '@mipmap/ic_launcher',
          color: Color(0xFF2E7D32),
          largeIcon: DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      );

      await _notificationsPlugin.show(
        id,
        localizedTitle,
        localizedBody,
        platformChannelSpecifics,
        payload: payload,
      );
    } catch (e) {
      debugPrint('Failed to show notification: $e');
    }
  }

  // Irrigation-specific notifications
  static Future<void> showIrrigationStarted(bool isHindi) async {
    await showLocalizedNotification(
      id: 1,
      title: isHindi ? 'सिंचाई शुरू' : 'Irrigation Started',
      body: isHindi ? 'आपके फसल क्षेत्रों में सिंचाई शुरू हो गई है' : 'Irrigation has started in your crop zones',
      isHindi: false, // Already translated above
    );
  }

  static Future<void> showIrrigationCompleted(bool isHindi) async {
    await showLocalizedNotification(
      id: 2,
      title: isHindi ? 'सिंचाई पूर्ण' : 'Irrigation Completed',
      body: isHindi ? 'सभी क्षेत्रों में सिंचाई सफलतापूर्वक पूर्ण हुई' : 'Irrigation completed successfully in all zones',
      isHindi: false,
    );
  }

  static Future<void> showLowBatteryWarning(bool isHindi) async {
    await showLocalizedNotification(
      id: 3,
      title: isHindi ? 'कम बैटरी चेतावनी' : 'Low Battery Warning',
      body: isHindi ? 'सिस्टम बैटरी 20% से कम है। कृपया चार्ज करें।' : 'System battery is below 20%. Please charge.',
      isHindi: false,
    );
  }

  static Future<void> showHighSoilMoisture(String zoneName, bool isHindi) async {
    final translatedZone = isHindi ? await _translateZoneName(zoneName) : zoneName;
    await showLocalizedNotification(
      id: 4,
      title: isHindi ? 'अधिक नमी चेतावनी' : 'High Moisture Warning',
      body: isHindi 
        ? '$translatedZone में मिट्टी की नमी बहुत अधिक है'
        : 'Soil moisture is too high in $zoneName',
      isHindi: false,
    );
  }

  static Future<void> showLowSoilMoisture(String zoneName, bool isHindi) async {
    final translatedZone = isHindi ? await _translateZoneName(zoneName) : zoneName;
    await showLocalizedNotification(
      id: 5,
      title: isHindi ? 'पानी की आवश्यकता' : 'Water Needed',
      body: isHindi 
        ? '$translatedZone में पानी की आवश्यकता है'
        : '$zoneName needs water',
      isHindi: false,
    );
  }

  static Future<void> showWeatherAlert(String message, bool isHindi) async {
    await showLocalizedNotification(
      id: 6,
      title: isHindi ? 'मौसम चेतावनी' : 'Weather Alert',
      body: message,
      isHindi: isHindi,
    );
  }

  static Future<void> showTestNotification(bool isHindi) async {
    await showLocalizedNotification(
      id: 999,
      title: isHindi ? 'टेस्ट नोटिफिकेशन' : 'Test Notification',
      body: isHindi ? 'यह एक टेस्ट नोटिफिकेशन है' : 'This is a test notification',
      isHindi: false,
    );
  }

  static Future<String> _translateZoneName(String zoneName) async {
    try {
      if (zoneName.contains('Tomatoes')) return 'टमाटर क्षेत्र';
      if (zoneName.contains('Peppers')) return 'मिर्च क्षेत्र';
      if (zoneName.contains('Spinach')) return 'पालक क्षेत्र';
      
      final translation = await translator.translate(zoneName, to: 'hi');
      return translation.text;
    } catch (e) {
      return zoneName;
    }
  }
}
