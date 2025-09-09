import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/colors.dart';
import '../../providers/irrigation_provider.dart';
import '../../providers/language_provider.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final languageProvider = context.watch<LanguageProvider>();
    final isHindi = languageProvider.isHindi;

    return Scaffold(
      appBar: AppBar(
        title: Text(isHindi ? 'सूचनाएं' : 'Notifications'),
        actions: [
          IconButton(
            icon: const Icon(Icons.clear_all),
            onPressed: () {
              final irrigationProvider = context.read<IrrigationProvider>();
              irrigationProvider.clearNotifications();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(isHindi ? 'सभी सूचनाएं साफ़ की गईं' : 'All notifications cleared'),
                  backgroundColor: AppColors.primaryGreen,
                ),
              );
            },
          ),
        ],
      ),
      body: Consumer<IrrigationProvider>(
        builder: (context, irrigationProvider, child) {
          if (irrigationProvider.notifications.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.notifications_off,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    isHindi ? 'कोई सूचना नहीं' : 'No notifications',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: irrigationProvider.notifications.length,
            itemBuilder: (context, index) {
              final notification = irrigationProvider.notifications[index];
              return _buildNotificationCard(context, notification, isHindi);
            },
          );
        },
      ),
    );
  }

  Widget _buildNotificationCard(BuildContext context, AppNotification notification, bool isHindi) {
    IconData icon;
    Color iconColor;

    switch (notification.type) {
      case NotificationType.info:
        icon = Icons.info;
        iconColor = Colors.blue;
        break;
      case NotificationType.warning:
        icon = Icons.warning;
        iconColor = Colors.orange;
        break;
      case NotificationType.alert:
        icon = Icons.error;
        iconColor = Colors.red;
        break;
      case NotificationType.success:
        icon = Icons.check_circle;
        iconColor = Colors.green;
        break;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: iconColor.withOpacity(0.1),
          child: Icon(icon, color: iconColor),
        ),
        title: Text(
          isHindi ? _translateTitle(notification.title) : notification.title,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(isHindi ? _translateMessage(notification.message) : notification.message),
            const SizedBox(height: 4),
            Text(
              _formatTimestamp(notification.timestamp, isHindi),
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.close, size: 18),
          onPressed: () {
            context.read<IrrigationProvider>().removeNotification(notification.id);
          },
        ),
        isThreeLine: true,
      ),
    );
  }

  String _translateTitle(String title) {
    // Simple translations for common titles
    final translations = {
      'System Started': 'सिस्टम शुरू',
      'Battery Status': 'बैटरी स्थिति',
      'Irrigation Started': 'सिंचाई शुरू',
      'Irrigation Stopped': 'सिंचाई बंद',
      'Low Battery Warning': 'कम बैटरी चेतावनी',
      'High Moisture Alert': 'अधिक नमी चेतावनी',
      'Water Needed': 'पानी की आवश्यकता',
      'Zone Activated': 'क्षेत्र सक्रिय',
      'Zone Deactivated': 'क्षेत्र निष्क्रिय',
    };
    return translations[title] ?? title;
  }

  String _translateMessage(String message) {
    // Simple translations for common messages
    if (message.contains('Smart irrigation system is now active')) {
      return 'स्मार्ट सिंचाई प्रणाली अब सक्रिय है';
    }
    if (message.contains('battery level is at')) {
      return message.replaceAll('System battery level is at', 'सिस्टम बैटरी स्तर है');
    }
    if (message.contains('Irrigation has started')) {
      return 'आपके फसल क्षेत्रों में सिंचाई शुरू हो गई है';
    }
    if (message.contains('Irrigation has been stopped')) {
      return 'सिंचाई बंद की गई है';
    }
    if (message.contains('System battery is below 20%')) {
      return 'सिस्टम बैटरी 20% से कम है। कृपया चार्ज करें।';
    }
    return message;
  }

  String _formatTimestamp(DateTime timestamp, bool isHindi) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return isHindi ? 'अभी' : 'Just now';
    } else if (difference.inMinutes < 60) {
      return isHindi ? '${difference.inMinutes} मिनट पहले' : '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return isHindi ? '${difference.inHours} घंटे पहले' : '${difference.inHours}h ago';
    } else {
      return isHindi ? '${difference.inDays} दिन पहले' : '${difference.inDays}d ago';
    }
  }
}
