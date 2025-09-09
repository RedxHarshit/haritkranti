import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/language_provider.dart';


class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});


  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final languageProvider = Provider.of<LanguageProvider>(context);
    final isHindi = languageProvider.isHindi;


    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          // Profile Header
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.primaryGreen,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                const CircleAvatar(
                  radius: 50,
                  backgroundColor: Colors.white,
                  child: Icon(
                    Icons.person,
                    size: 50,
                    color: AppColors.primaryGreen,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  authProvider.user?.phoneNumber ?? '+91XXXXXXXXXX',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  isHindi ? 'किसान' : 'Farmer',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Menu Items
          _buildMenuItem(
            icon: Icons.book,
            title: isHindi ? 'उपयोगकर्ता मैनुअल' : 'User Manual',
            onTap: () => _showUserManual(context, isHindi),
          ),
          _buildMenuItem(
            icon: Icons.language,
            title: isHindi ? 'भाषा बदलें' : 'Change Language',
            onTap: languageProvider.toggleLanguage,
          ),
          _buildMenuItem(
            icon: Icons.help,
            title: isHindi ? 'सहायता' : 'Help & Support',
            onTap: () => _showHelpDialog(context, isHindi),
          ),
          _buildMenuItem(
            icon: Icons.info,
            title: isHindi ? 'ऐप के बारे में' : 'About App',
            onTap: () => _showAboutDialog(context, isHindi),
          ),
          _buildMenuItem(
            icon: Icons.logout,
            title: isHindi ? 'लॉग आउट' : 'Logout',
            textColor: AppColors.errorRed,
            onTap: () => _showLogoutDialog(context, authProvider, isHindi),
          ),
        ],
      ),
    );
  }


  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? textColor,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(icon, color: textColor ?? AppColors.primaryGreen),
        title: Text(
          title,
          style: TextStyle(
            color: textColor ?? AppColors.textPrimary,
            fontWeight: FontWeight.w500,
          ),
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        tileColor: Colors.white,
      ),
    );
  }


  void _showUserManual(BuildContext context, bool isHindi) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isHindi ? 'उपयोगकर्ता मैनुअल' : 'User Manual'),
        content: SingleChildScrollView(
          child: Text(
            isHindi
                ? '''1. होम स्क्रीन पर सभी सेंसर की जानकारी देखें
2. सिंचाई टैब से पानी देना शुरू/बंद करें  
3. मेंटेनेंस टैब से सिस्टम की स्थिति देखें
4. चैटबॉट से तुरंत सहायता पाएं
5. नोटिफिकेशन से अलर्ट देखें'''
                : '''1. View all sensor data on Home screen
2. Control irrigation from Irrigation tab
3. Check system status in Maintenance tab  
4. Get instant help from chatbot
5. View alerts in notifications''',
            style: const TextStyle(fontSize: 16),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(isHindi ? 'समझ गया' : 'Got it'),
          ),
        ],
      ),
    );
  }


  void _showHelpDialog(BuildContext context, bool isHindi) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isHindi ? 'सहायता' : 'Help & Support'),
        content: Text(
          isHindi
              ? 'सहायता के लिए संपर्क करें:\nफोन: +91 98765 43210\nईमेल: support@smartirrigation.com'
              : 'Contact us for support:\nPhone: +91 98765 43210\nEmail: support@smartirrigation.com',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(isHindi ? 'ठीक है' : 'OK'),
          ),
        ],
      ),
    );
  }


  void _showAboutDialog(BuildContext context, bool isHindi) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isHindi ? 'ऐप के बारे में' : 'About App'),
        content: Text(
          isHindi
              ? 'स्मार्ट सिंचाई प्रणाली v1.0\n\nसोलर पावर और रेनवाटर हार्वेस्टिंग के साथ स्वचालित सिंचाई।\n\nबनाया गया: SIH 2025 प्रोजेक्ट के लिए'
              : 'Smart Irrigation System v1.0\n\nAutomated irrigation with solar power and rainwater harvesting.\n\nMade for: SIH 2025 Project',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(isHindi ? 'ठीक है' : 'OK'),
          ),
        ],
      ),
    );
  }


  void _showLogoutDialog(BuildContext context, AuthProvider authProvider, bool isHindi) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isHindi ? 'लॉग आउट' : 'Logout'),
        content: Text(isHindi ? 'क्या आप वाकई लॉग आउट करना चाहते हैं?' : 'Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(isHindi ? 'रद्द करें' : 'Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await authProvider.signOut();
              if (context.mounted) {
                Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
              }
            },
            child: Text(
              isHindi ? 'लॉग आउट' : 'Logout',
              style: const TextStyle(color: AppColors.errorRed),
            ),
          ),
        ],
      ),
    );
  }
}
