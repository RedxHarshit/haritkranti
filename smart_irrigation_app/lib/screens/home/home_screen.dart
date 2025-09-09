import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../constants/colors.dart';
import '../../providers/irrigation_provider.dart';
import '../../providers/language_provider.dart';
import '../../providers/weather_provider.dart';
import '../../widgets/common/status_card.dart';
import '../../widgets/common/chatbot_widget.dart';
import '../../services/notification_service.dart';
import '../irrigation/irrigation_control_screen.dart';
import '../profile/profile_screen.dart';
import '../maintenance/maintenance_screen.dart';
import '../notifications/notifications_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = const [
    HomeDashboard(),
    IrrigationControlScreen(),
    MaintenanceScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Consumer<LanguageProvider>(
      builder: (context, languageProvider, child) {
        return Scaffold(
          appBar: AppBar(
            title: Text(languageProvider.isHindi ? 'स्मार्ट सिंचाई प्रणाली' : 'Smart Irrigation System'),
            actions: [
              IconButton(
                icon: const Icon(Icons.notifications),
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationsScreen()));
                },
              ),
              IconButton(
                icon: Icon(languageProvider.isHindi ? Icons.language : Icons.translate),
                onPressed: () async {
                  // Toggle language
                  languageProvider.toggleLanguage();
                  // Automatically refresh weather data with new language
                  await context.read<WeatherProvider>().fetchWeatherData(isHindi: languageProvider.isHindi);
                },
              ),
            ],
          ),
          body: Stack(
            children: [
              _screens[_selectedIndex],
              const ChatbotWidget(),
            ],
          ),
          bottomNavigationBar: BottomNavigationBar(
            type: BottomNavigationBarType.fixed,
            currentIndex: _selectedIndex,
            onTap: (index) => setState(() => _selectedIndex = index),
            selectedItemColor: AppColors.primaryGreen,
            unselectedItemColor: AppColors.textSecondary,
            items: [
              BottomNavigationBarItem(icon: const Icon(Icons.home), label: languageProvider.isHindi ? 'होम' : 'Home'),
              BottomNavigationBarItem(icon: const FaIcon(FontAwesomeIcons.droplet), label: languageProvider.isHindi ? 'सिंचाई' : 'Irrigation'),
              BottomNavigationBarItem(icon: const Icon(Icons.build), label: languageProvider.isHindi ? 'रखरखाव' : 'Maintenance'),
              BottomNavigationBarItem(icon: const Icon(Icons.person), label: languageProvider.isHindi ? 'प्रोफाइल' : 'Profile'),
            ],
          ),
        );
      },
    );
  }
}

class HomeDashboard extends StatelessWidget {
  const HomeDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<LanguageProvider>(
      builder: (context, languageProvider, child) {
        final irrigationProvider = context.watch<IrrigationProvider>();
        final sensorData = irrigationProvider.currentData;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildWeatherCard(context, languageProvider.isHindi),
              const SizedBox(height: 16),
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.1,
                children: [
                  StatusCard(
                    title: languageProvider.isHindi ? 'औसत मिट्टी की नमी' : 'Avg Soil Moisture',
                    value: '${sensorData.averageSoilMoisture.toInt()}%',
                    icon: Icons.water_drop,
                    color: _getColorForValue(sensorData.averageSoilMoisture),
                  ),
                  StatusCard(
                    title: languageProvider.isHindi ? 'बैटरी' : 'Battery',
                    value: '${sensorData.batteryLevel.toInt()}%',
                    icon: Icons.battery_full,
                    color: _getColorForValue(sensorData.batteryLevel),
                  ),
                  StatusCard(
                    title: languageProvider.isHindi ? 'ऊपरी टैंक' : 'Upper Tank',
                    value: '${sensorData.upperTankLevel.toInt()}%',
                    icon: Icons.water,
                    color: _getColorForValue(sensorData.upperTankLevel),
                  ),
                  StatusCard(
                    title: languageProvider.isHindi ? 'निचला टैंक' : 'Lower Tank',
                    value: '${sensorData.lowerTankLevel.toInt()}%',
                    icon: Icons.water,
                    color: _getColorForValue(sensorData.lowerTankLevel),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _buildZonesList(context, languageProvider.isHindi),
              const SizedBox(height: 20),
              _buildQuickActions(context, languageProvider.isHindi),
            ],
          ),
        );
      },
    );
  }

  Widget _buildWeatherCard(BuildContext context, bool isHindi) {
    return Consumer<WeatherProvider>(
      builder: (context, weatherProvider, child) {
        if (weatherProvider.isLoading) {
          return Container(
            width: double.infinity,
            height: 120,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.waterBlue, AppColors.primaryGreen],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Center(child: CircularProgressIndicator(color: Colors.white)),
          );
        }

        final weather = weatherProvider.currentWeather;
        if (weather == null) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.waterBlue, AppColors.primaryGreen],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                const Icon(Icons.error, color: Colors.white, size: 50),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    isHindi ? 'मौसम की जानकारी उपलब्ध नहीं' : 'Weather data unavailable',
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ),
                TextButton(
                  onPressed: () => context.read<WeatherProvider>().fetchWeatherData(isHindi: isHindi),
                  child: Text(isHindi ? 'पुनः प्रयास' : 'Retry', style: const TextStyle(color: Colors.white)),
                ),
              ],
            ),
          );
        }

        final recommendation = weatherProvider.getIrrigationRecommendation(
          context.read<IrrigationProvider>().currentData.averageSoilMoisture,
          isHindi: isHindi,
        );

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.waterBlue, AppColors.primaryGreen],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Image.network(
                'https://openweathermap.org/img/wn/${weather.icon}@2x.png',
                width: 50,
                height: 50,
                errorBuilder: (_, __, ___) => const Icon(Icons.wb_sunny, color: Colors.white, size: 50),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${weather.location} - ${weather.temperature.toInt()}°C',
                      style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      weather.description,
                      style: const TextStyle(color: Colors.white70, fontSize: 14)
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${isHindi ? 'सिफारिश' : 'Recommendation'}: $recommendation',
                      style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => context.read<WeatherProvider>().fetchWeatherData(isHindi: isHindi),
                icon: const Icon(Icons.refresh, color: Colors.white),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildZonesList(BuildContext context, bool isHindi) {
  final irrigationProvider = context.watch<IrrigationProvider>();
  final zones = irrigationProvider.currentData.zones;

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        isHindi ? 'फसल क्षेत्र' : 'Crop Zones',
        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
      ),
      const SizedBox(height: 12),
      ...zones.map((zone) => Card(
        margin: const EdgeInsets.only(bottom: 8),
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: zone.statusColor,
            child: Text(
              zone.id.replaceAll(RegExp(r'[^0-9]'), ''), // FIXED: Only show numbers
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
          title: Text(isHindi ? _getHindiZoneName(zone.name) : zone.name),
          subtitle: Text('${zone.soilMoisture.toInt()}% - ${isHindi ? _getHindiMoistureStatus(zone.moistureStatus) : zone.moistureStatus}'),
          trailing: Switch(
            value: zone.isActive,
            onChanged: (value) => irrigationProvider.toggleZone(zone.id),
            activeColor: AppColors.primaryGreen,
          ),
        ),
      )),
    ],
  );
}


  String _getHindiZoneName(String zoneName) {
    if (zoneName.contains('Tomatoes')) return 'क्षेत्र 1 - टमाटर';
    if (zoneName.contains('Peppers')) return 'क्षेत्र 2 - मिर्च';
    if (zoneName.contains('Spinach')) return 'क्षेत्र 3 - पालक';
    return zoneName;
  }

  String _getHindiMoistureStatus(String status) {
    switch (status) {
      case 'Optimal': return 'आदर्श';
      case 'Needs water': return 'पानी चाहिए';
      case 'Over-watered': return 'अधिक पानी';
      default: return status;
    }
  }

  Widget _buildQuickActions(BuildContext context, bool isHindi) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          isHindi ? 'त्वरित कार्य' : 'Quick Actions',
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () {
                  final provider = context.read<IrrigationProvider>();
                  
                  // Use the new method that includes language context
                  provider.toggleIrrigationWithLanguage(isHindi);

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(provider.irrigationEnabled 
                        ? (isHindi ? 'सिंचाई शुरू की गई' : 'Irrigation Started')
                        : (isHindi ? 'सिंचाई बंद की गई' : 'Irrigation Stopped')),
                      backgroundColor: AppColors.primaryGreen,
                      duration: const Duration(seconds: 2),
                    ),
                  );

                  final parent = context.findAncestorStateOfType<_HomeScreenState>();
                  if (parent != null) {
                    parent.setState(() => parent._selectedIndex = 1);
                  }
                },
                icon: const Icon(Icons.play_arrow),
                label: Text(isHindi ? 'सिंचाई शुरू करें' : 'Start Irrigation'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryGreen,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _showScheduleDialog(context, isHindi),
                icon: const Icon(Icons.schedule),
                label: Text(isHindi ? 'शेड्यूल सेट करें' : 'Set Schedule'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.solarOrange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Test Notification Button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () async {
              // Test various notifications
              await NotificationService.showTestNotification(isHindi);
              
              // Test after 3 seconds
              await Future.delayed(const Duration(seconds: 3));
              await NotificationService.showLowSoilMoisture('Zone 1 - Tomatoes', isHindi);
              
              // Test after another 3 seconds
              await Future.delayed(const Duration(seconds: 3));
              await NotificationService.showWeatherAlert(
                isHindi ? 'आज बारिश की संभावना है' : 'Rain expected today',
                isHindi,
              );

              // Test battery warning after 6 seconds
              await Future.delayed(const Duration(seconds: 3));
              await NotificationService.showLowBatteryWarning(isHindi);
            },
            icon: const Icon(Icons.notifications),
            label: Text(isHindi ? 'नोटिफिकेशन टेस्ट' : 'Test Notifications'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),
      ],
    );
  }

  void _showScheduleDialog(BuildContext context, bool isHindi) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(isHindi ? 'सिंचाई शेड्यूल' : 'Irrigation Schedule'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.access_time),
              title: Text(isHindi ? 'सुबह 6:00 बजे' : 'Morning 6:00 AM'),
              trailing: Switch(value: true, onChanged: (v) {}, activeColor: AppColors.primaryGreen),
            ),
            ListTile(
              leading: const Icon(Icons.access_time),
              title: Text(isHindi ? 'शाम 6:00 बजे' : 'Evening 6:00 PM'),
              trailing: Switch(value: false, onChanged: (v) {}, activeColor: AppColors.primaryGreen),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(isHindi ? 'रद्द करें' : 'Cancel')),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(isHindi ? 'शेड्यूल सेव किया गया' : 'Schedule Saved'), backgroundColor: AppColors.primaryGreen),
              );
            },
            child: Text(isHindi ? 'सेव करें' : 'Save'),
          ),
        ],
      ),
    );
  }

  Color _getColorForValue(double value) {
    if (value > 60) return AppColors.successGreen;
    if (value > 30) return AppColors.solarOrange;
    return AppColors.errorRed;
  }
}
