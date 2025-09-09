import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../constants/colors.dart';
import '../../widgets/common/custom_button.dart';
import '../home/home_screen.dart';

class OTPVerificationScreen extends StatefulWidget {
  final String verificationId;
  final String phoneNumber;

  const OTPVerificationScreen({
    super.key,
    required this.verificationId,
    required this.phoneNumber,
  });

  @override
  State<OTPVerificationScreen> createState() => _OTPVerificationScreenState();
}

class _OTPVerificationScreenState extends State<OTPVerificationScreen> {
  final List<TextEditingController> _otpControllers = List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    // DEBUG: show which verificationId and phone this screen is using
    debugPrint('OTP screen VID: ${widget.verificationId.substring(0, 12)}');
    debugPrint('OTP for: ${widget.phoneNumber}');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Verify OTP / OTP सत्यापित करें'),
        backgroundColor: AppColors.primaryGreen,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.sms, size: 80, color: AppColors.primaryGreen),
              const SizedBox(height: 24),
              Text(
                'OTP भेजा गया है',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: AppColors.primaryGreen,
                      fontWeight: FontWeight.bold,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                widget.phoneNumber,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(6, (index) => _buildOTPField(index)),
              ),
              const SizedBox(height: 32),
              CustomButton(
                text: 'Verify / सत्यापित करें',
                isLoading: _isLoading,
                onPressed: () {
                  if (_isLoading) return;
                  _verifyOTP();
                },
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: _isLoading
                    ? null
                    : () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('कृपया पिछले पेज से OTP दोबारा भेजें'),
                            backgroundColor: AppColors.solarOrange,
                          ),
                        );
                      },
                child: const Text(
                  'Resend OTP / OTP दोबारा भेजें',
                  style: TextStyle(color: AppColors.primaryGreen),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOTPField(int index) {
    return SizedBox(
      width: 45,
      height: 55,
      child: TextFormField(
        controller: _otpControllers[index],
        focusNode: _focusNodes[index],
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        maxLength: 1,
        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        decoration: InputDecoration(
          counterText: '',
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.primaryGreen),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.primaryGreen, width: 2),
          ),
        ),
        onChanged: (value) {
          if (value.isNotEmpty && index < 5) _focusNodes[index + 1].requestFocus();
          if (value.isEmpty && index > 0) _focusNodes[index - 1].requestFocus();
        },
      ),
    );
  }

  Future<void> _verifyOTP() async {
    final otp = _otpControllers.map((c) => c.text.trim()).join();

    // DEBUG: log entered OTP and the verificationId prefix used
    debugPrint('Entered OTP: $otp');
    debugPrint('Using VID: ${widget.verificationId.substring(0, 12)}');

    if (otp.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('कृपया 6 अंकों का OTP दर्ज करें'),
          backgroundColor: AppColors.errorRed,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // IMPORTANT: Always use the verificationId passed to this screen
      final credential = PhoneAuthProvider.credential(
        verificationId: widget.verificationId,
        smsCode: otp,
      );

      final userCredential = await FirebaseAuth.instance.signInWithCredential(credential);

      if (!mounted) return;
      setState(() => _isLoading = false);

      if (userCredential.user != null) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const HomeScreen()),
          (route) => false,
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('गलत OTP। कृपया दोबारा कोशिश करें।'),
            backgroundColor: AppColors.errorRed,
          ),
        );
      }
    } catch (e) {
      // DEBUG: print the raw error to console for diagnosis
      debugPrint('OTP verify error: $e');

      if (!mounted) return;
      setState(() => _isLoading = false);

      String errorMessage = 'गलत OTP। कृपया दोबारा कोशिश करें।';
      final s = e.toString();
      if (s.contains('session-expired')) {
        errorMessage = 'OTP की समय सीमा समाप्त हो गई। नया OTP मांगें।';
      } else if (s.contains('invalid-verification-id')) {
        errorMessage = 'सत्र मेल नहीं खा रहा। कृपया OTP दोबारा भेजें।';
      } else if (s.contains('invalid-verification-code')) {
        errorMessage = 'गलत OTP। कृपया सही OTP दर्ज करें।';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage), backgroundColor: AppColors.errorRed),
      );
    }
  }

  @override
  void dispose() {
    for (final c in _otpControllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }
}
