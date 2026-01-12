import 'dart:io';
import 'package:carsbuzz/login/otp_screen.dart';
import 'package:carsbuzz/network/repository_api.dart';
import 'package:carsbuzz/repository/auth_repo.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_number/mobile_number.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _phoneController = TextEditingController();

  bool _isLoading = false;
  bool _isValidPhone = false;
  late final RepositoryApi _api;

  List<String> _mobileNumbers = [];
  late final AuthRepo _authRepo;

  @override
  void initState() {
    super.initState();
    _authRepo = AuthRepo();
    _autoDetectPhoneNumber();
  }

  // 🔹 Auto-detect phone number (Android only)
  Future<void> _autoDetectPhoneNumber() async {
    if (!Platform.isAndroid) return;

    try {
      final numbers = await MobileNumber.getSimCards;
      if (numbers == null || numbers.isEmpty) return;

      final extracted = numbers
          .map((e) => e.number)
          .whereType<String>()
          .map(_sanitizeNumber)
          .where(_isPhoneValid)
          .toList();

      if (!mounted || extracted.isEmpty) return;

      setState(() {
        _mobileNumbers = extracted;
        _phoneController.text = extracted.first;
        _isValidPhone = true;
      });
    } catch (_) {}
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

    _authRepo.sendOtp(
      phone: _phoneController.text,
      onSuccess: (data) {
        if (!mounted) return;

        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => OtpScreen(phoneNumber: _phoneController.text),
        )
        );

        setState(() => _isLoading = false);
      },
      onError: (message) {
        if (!mounted) return;

        setState(() => _isLoading = false);

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(message)));
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

                // Detected numbers (dual SIM)
                if (_mobileNumbers.length > 1)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Wrap(
                      spacing: 8,
                      children: _mobileNumbers.map((number) {
                        return ActionChip(
                          label: Text(number),
                          onPressed: () {
                            _phoneController.text = number;
                            _isValidPhone = true;
                            setState(() {});
                          },
                        );
                      }).toList(),
                    ),
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
