import 'package:carsbuzz/auth/firebase_auth_service.dart';
import 'package:carsbuzz/login/otp_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _phoneController = TextEditingController();

  bool _isLoading = false;
  bool _isValidPhone = false;

  @override
  void initState() {
    super.initState();
  }

  // 🔹 Sanitize input
  String _sanitizeNumber(String number) {
    return number
        .replaceAll(RegExp(r'[^0-9]'), '')
        .replaceFirst(RegExp(r'^91'), '');
  }

  // 🔹 Validate Indian phone number
  bool _isPhoneValid(String number) {
    return RegExp(r'^[6-9]\d{9}$').hasMatch(number);
  }

  void _onPhoneChanged(String value) {
    final sanitized = _sanitizeNumber(value);

    setState(() {
      _phoneController.value = TextEditingValue(
        text: sanitized,
        selection: TextSelection.collapsed(offset: sanitized.length),
      );
      _isValidPhone = _isPhoneValid(sanitized);
    });
  }

  void _getOtp() {
    if (!_isValidPhone) return;

    setState(() => _isLoading = true);

    FirebaseAuthService.sendOTP(
      phoneNumber: _phoneController.text,
      onCodeSent: () {
        if (!mounted) return;
        
        setState(() => _isLoading = false);
        
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => OtpScreen(phoneNumber: _phoneController.text),
          ),
        );
      },
      onError: (message) {
        if (!mounted) return;
        
        setState(() => _isLoading = false);
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
      },
    );
  }

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/registration_page_background.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 40),

                const Text(
                  "Welcome Car Lover!",
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),

                const SizedBox(height: 12),

                const Text(
                  "Enter your phone number\nWe will send you a 6 digit verification code",
                  style: TextStyle(color: Colors.white70),
                ),

                const SizedBox(height: 30),

                // 📱 Phone Field + Stable Error
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      maxLength: 10,
                      style: const TextStyle(color: Colors.white),
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      onChanged: _onPhoneChanged,
                      decoration: InputDecoration(
                        counterText: "",
                        hintText: "Mobile Number",
                        hintStyle: const TextStyle(color: Colors.white70),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: Colors.white),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: Colors.white),
                        ),
                        disabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: Colors.white54),
                        ),
                      ),
                    ),

                    // ✅ Fixed-height error message (no UI jump)
                    SizedBox(
                      height: 20,
                      child:
                          (!_isValidPhone && _phoneController.text.isNotEmpty)
                          ? const Text(
                              "Enter valid 10-digit mobile number",
                              style: TextStyle(
                                color: Colors.redAccent,
                                fontSize: 12,
                              ),
                            )
                          : null,
                    ),
                  ],
                ),

                const SizedBox(height: 30),

                // 🔘 Get OTP Button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isValidPhone
                          ? Colors.white
                          : Colors.white54,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    onPressed: (_isValidPhone && !_isLoading) ? _getOtp : null,
                    child: _isLoading
                        ? const SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text(
                            "Get OTP",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF6A4C93),
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
