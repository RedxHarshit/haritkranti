import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../../constants/colors.dart';
import '../../widgets/common/custom_button.dart';
import '../../providers/language_provider.dart';
import 'otp_verification_screen.dart';

class PhoneAuthScreen extends StatefulWidget {
  const PhoneAuthScreen({super.key});

  @override
  State<PhoneAuthScreen> createState() => _PhoneAuthScreenState();
}

class _PhoneAuthScreenState extends State<PhoneAuthScreen> {
  final _phoneController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  Widget build(BuildContext context) {
    final isHindi = context.watch<LanguageProvider>().isHindi;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.agriculture, size: 100, color: AppColors.primaryGreen),
                const SizedBox(height: 24),
                Text(
                  isHindi ? 'स्मार्ट सिंचाई प्रणाली' : 'Smart Irrigation System',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: AppColors.primaryGreen,
                        fontWeight: FontWeight.bold,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 48),
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  style: const TextStyle(fontSize: 18),
                  decoration: InputDecoration(
                    labelText: isHindi ? 'मोबाइल नंबर' : 'Mobile Number',
                    labelStyle: const TextStyle(fontSize: 16),
                    prefixText: '+91 ',
                    prefixStyle: const TextStyle(fontSize: 18, color: AppColors.textPrimary),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.primaryGreen, width: 2),
                    ),
                    prefixIcon: const Icon(Icons.phone, color: AppColors.primaryGreen),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return isHindi ? 'कृपया मोबाइल नंबर दर्ज करें' : 'Please enter mobile number';
                    }
                    if (value.length != 10) {
                      return isHindi ? 'मोबाइल नंबर 10 अंकों का होना चाहिए' : 'Mobile number should be 10 digits';
                    }
                    if (!RegExp(r'^[0-9]+$').hasMatch(value)) {
                      return isHindi ? 'केवल अंक दर्ज करें' : 'Enter only numbers';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                CustomButton(
                  text: isHindi ? 'OTP भेजें' : 'Send OTP',
                  isLoading: _isLoading,
                  onPressed: () {
                    if (_isLoading) return;
                    _sendOTP();
                  },
                ),
                const SizedBox(height: 20),
                TextButton.icon(
                  onPressed: context.read<LanguageProvider>().toggleLanguage,
                  icon: Icon(isHindi ? Icons.language : Icons.translate, color: AppColors.primaryGreen),
                  label: Text(
                    isHindi ? 'Switch to English' : 'हिंदी में बदलें',
                    style: const TextStyle(color: AppColors.primaryGreen),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  isHindi
                      ? 'OTP भेजने पर आप हमारे नियम और शर्तों से सहमत हैं'
                      : 'By sending OTP, you agree to our Terms & Conditions',
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _sendOTP() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final isHindi = context.read<LanguageProvider>().isHindi;
    final phoneNumber = '+91${_phoneController.text.trim()}';

    try {
      await _auth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        verificationCompleted: (PhoneAuthCredential credential) async {
          debugPrint('verificationCompleted: auto credential path');
          try {
            await _auth.signInWithCredential(credential);
            if (!mounted) return;
            setState(() => _isLoading = false);
            Navigator.pushReplacementNamed(context, '/home');
          } catch (_) {
            if (!mounted) return;
            setState(() => _isLoading = false);
          }
        },
        verificationFailed: (FirebaseAuthException e) {
          debugPrint('verificationFailed: ${e.code} - ${e.message}');
          if (!mounted) return;
          setState(() => _isLoading = false);

          String errorMessage;
          switch (e.code) {
            case 'invalid-phone-number':
              errorMessage = isHindi ? 'अवैध फोन नंबर' : 'Invalid phone number';
              break;
            case 'too-many-requests':
              errorMessage = isHindi ? 'बहुत सारे अनुरोध। कुछ देर बाद कोशिश करें।' : 'Too many requests. Try again later.';
              break;
            case 'operation-not-allowed':
              errorMessage = isHindi ? 'फोन प्रामाणीकरण सक्षम नहीं है' : 'Phone authentication is not enabled';
              break;
            default:
              errorMessage = isHindi ? 'कुछ गलत हुआ है। कृपया दोबारा कोशिश करें।' : 'Something went wrong. Please try again.';
          }

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(errorMessage), backgroundColor: AppColors.errorRed),
          );
        },
        codeSent: (String verificationId, int? resendToken) {
          debugPrint('codeSent VID: ${verificationId.substring(0, 12)}');
          debugPrint('sent to: $phoneNumber');
          if (!mounted) return;
          setState(() => _isLoading = false);

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => OTPVerificationScreen(
                verificationId: verificationId,
                phoneNumber: phoneNumber,
              ),
            ),
          );
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          // Optional: inform user that timeout happened
        },
        timeout: const Duration(seconds: 60),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isHindi ? 'कुछ गलत हुआ है। कृपया दोबारा कोशिश करें।' : 'Something went wrong. Please try again.'),
          backgroundColor: AppColors.errorRed,
        ),
      );
    }
  }

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }
}
