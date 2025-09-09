import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../constants/colors.dart';
import '../../providers/language_provider.dart';

class MaintenanceScreen extends StatelessWidget {
  const MaintenanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context);
    final isHindi = languageProvider.isHindi;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isHindi ? 'सिस्टम स्थिति' : 'System Status',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          
          // Component Status Cards
          _buildComponentCard(
            title: isHindi ? 'सोलर पैनल' : 'Solar Panels',
            icon: FontAwesomeIcons.solarPanel,
            status: isHindi ? 'सामान्य' : 'Normal',
            statusColor: AppColors.successGreen,
            details: isHindi ? 'उत्पादन: 85W' : 'Output: 85W',
          ),
          _buildComponentCard(
            title: isHindi ? 'बैटरी' : 'Battery',
            icon: Icons.battery_full,
            status: isHindi ? 'अच्छी' : 'Good',
            statusColor: AppColors.successGreen,
            details: isHindi ? 'चार्ज: 78%' : 'Charge: 78%',
          ),
          _buildComponentCard(
            title: isHindi ? 'पानी पंप' : 'Water Pump',
            icon: FontAwesomeIcons.fan,
            status: isHindi ? 'सामान्य' : 'Normal',
            statusColor: AppColors.successGreen,
            details: isHindi ? 'दबाव: 2.3 bar' : 'Pressure: 2.3 bar',
          ),
          _buildComponentCard(
            title: isHindi ? 'मिट्टी सेंसर' : 'Soil Sensors',
            icon: FontAwesomeIcons.seedling,
            status: isHindi ? 'सामान्य' : 'Normal',
            statusColor: AppColors.successGreen,
            details: isHindi ? 'सभी 4 सेंसर कार्यरत' : 'All 4 sensors active',
          ),
          _buildComponentCard(
            title: isHindi ? 'सोलेनॉइड वाल्व' : 'Solenoid Valves',
            icon: FontAwesomeIcons.gear,  // Changed from valve
            status: isHindi ? 'चेतावनी' : 'Warning',
            statusColor: AppColors.solarOrange,
            details: isHindi ? 'वाल्व 2 में समस्या' : 'Issue with Valve 2',
          ),
          _buildComponentCard(
            title: isHindi ? 'टरबाइन जेनरेटर' : 'Turbine Generator',
            icon: FontAwesomeIcons.wind,
            status: isHindi ? 'सामान्य' : 'Normal',
            statusColor: AppColors.successGreen,
            details: isHindi ? 'उत्पादन: 12W' : 'Output: 12W',
          ),
          
          const SizedBox(height: 20),
          
          // Maintenance Schedule
          Text(
            isHindi ? 'रखरखाव अनुसूची' : 'Maintenance Schedule',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          
          _buildMaintenanceItem(
            title: isHindi ? 'फिल्टर सफाई' : 'Filter Cleaning',
            dueDate: isHindi ? '2 दिन बाकी' : '2 days remaining',
            priority: isHindi ? 'उच्च' : 'High',
            priorityColor: AppColors.errorRed,
          ),
          _buildMaintenanceItem(
            title: isHindi ? 'सोलर पैनल सफाई' : 'Solar Panel Cleaning',
            dueDate: isHindi ? '1 सप्ताह बाकी' : '1 week remaining',
            priority: isHindi ? 'मध्यम' : 'Medium',
            priorityColor: AppColors.solarOrange,
          ),
          _buildMaintenanceItem(
            title: isHindi ? 'सेंसर कैलिब्रेशन' : 'Sensor Calibration',
            dueDate: isHindi ? '3 सप्ताह बाकी' : '3 weeks remaining',
            priority: isHindi ? 'कम' : 'Low',
            priorityColor: AppColors.successGreen,
          ),
        ],
      ),
    );
  }

  Widget _buildComponentCard({
    required String title,
    required IconData icon,
    required String status,
    required Color statusColor,
    required String details,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(icon, size: 30, color: statusColor),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  details,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              status,
              style: TextStyle(
                color: statusColor,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMaintenanceItem({
    required String title,
    required String dueDate,
    required String priority,
    required Color priorityColor,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border(  // Fixed here
          left: BorderSide(
            color: priorityColor,
            width: 4,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  dueDate,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: priorityColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              priority,
              style: TextStyle(
                color: priorityColor,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
