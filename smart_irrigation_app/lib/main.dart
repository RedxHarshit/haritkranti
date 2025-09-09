import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:geolocator/geolocator.dart';
import 'constants/colors.dart';
import 'providers/auth_provider.dart';
import 'providers/irrigation_provider.dart';
import 'providers/language_provider.dart';
import 'providers/weather_provider.dart';
import 'screens/auth/phone_auth_screen.dart';
import 'screens/home/home_screen.dart';
import 'services/notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Load the .env file
  await dotenv.load(fileName: ".env");

  // Global error handler
  FlutterError.onError = (FlutterErrorDetails details) {
    debugPrint('Flutter error: ${details.exceptionAsString()}');
  };
  
  await Firebase.initializeApp();
  
  // Initialize notifications
  await NotificationService.initialize();
  
  // Request location permission at startup
  await _requestLocationPermission();
  
  runApp(const MyApp());
}

Future<void> _requestLocationPermission() async {
  try {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
  } catch (e) {
    debugPrint('Location permission error: $e');
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => IrrigationProvider()),
        ChangeNotifierProvider(create: (_) => LanguageProvider()),
        ChangeNotifierProvider(create: (_) => WeatherProvider()..fetchWeatherData()),
      ],
      child: Consumer<LanguageProvider>(
        builder: (context, languageProvider, child) {
          return MaterialApp(
            title: 'Smart Irrigation',
            debugShowCheckedModeBanner: false,
            locale: languageProvider.isHindi ? const Locale('hi', 'IN') : const Locale('en', 'US'),
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [
              Locale('en', 'US'),
              Locale('hi', 'IN'),
            ],
            theme: ThemeData(
              primarySwatch: MaterialColor(0xFF2E7D32, {
                50: AppColors.primaryGreen.withOpacity(0.1),
                100: AppColors.primaryGreen.withOpacity(0.2),
                200: AppColors.primaryGreen.withOpacity(0.3),
                300: AppColors.primaryGreen.withOpacity(0.4),
                400: AppColors.primaryGreen.withOpacity(0.5),
                500: AppColors.primaryGreen.withOpacity(0.6),
                600: AppColors.primaryGreen.withOpacity(0.7),
                700: AppColors.primaryGreen.withOpacity(0.8),
                800: AppColors.primaryGreen.withOpacity(0.9),
                900: AppColors.primaryGreen,
              }),
              primaryColor: AppColors.primaryGreen,
              scaffoldBackgroundColor: Colors.grey[50],
              appBarTheme: const AppBarTheme(
                backgroundColor: AppColors.primaryGreen,
                foregroundColor: Colors.white,
                elevation: 2,
              ),
              elevatedButtonTheme: ElevatedButtonThemeData(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryGreen,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              textTheme: const TextTheme(
                bodyLarge: TextStyle(color: AppColors.textPrimary),
                bodyMedium: TextStyle(color: AppColors.textSecondary),
              ),
            ),
            initialRoute: '/',
            routes: {
              '/': (context) => Consumer<AuthProvider>(
                builder: (context, authProvider, child) {
                  if (authProvider.isAuthenticated) {
                    return const HomeScreen();
                  } else {
                    return const PhoneAuthScreen();
                  }
                },
              ),
              '/phone-auth': (context) => const PhoneAuthScreen(),
              '/home': (context) => const HomeScreen(),
            },
          );
        },
      ),
    );
  }
}
