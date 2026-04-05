import 'dart:async';
import 'package:carsbuzz/auth/firebase_auth_service.dart';
import 'package:carsbuzz/home/new_home_screen.dart';
import 'package:carsbuzz/network/api_client.dart';
import 'package:carsbuzz/network/firebase_service.dart';
import 'package:carsbuzz/network/repository_api.dart';
import 'package:carsbuzz/models/signup_user_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OtpScreen extends StatefulWidget {
  final String phoneNumber;

  const OtpScreen({
    super.key,
    required this.phoneNumber,
  });

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final List<TextEditingController> _controllers =
      List.generate(6, (_) => TextEditingController());

  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());
  final RepositoryApi _api = ApiClient.create();

  int _secondsRemaining = 15;
  Timer? _timer;
  bool _isLoading = false;

  bool get _isOtpComplete => _controllers.every((c) => c.text.isNotEmpty);

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    _secondsRemaining = 15;

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining == 0) {
        timer.cancel();
      } else {
        setState(() => _secondsRemaining--);
      }
    });
  }

  void _onOtpChanged(int index, String value) {
    if (value.isNotEmpty && index < 5) {
      _focusNodes[index + 1].requestFocus();
    }
    if (value.isEmpty && index > 0) {
      _focusNodes[index - 1].requestFocus();
    }
    setState(() {});
  }

  String get _otp => _controllers.map((c) => c.text).join();

  Future<void> _callLoginAPI() async {
    try {
      print('🔍 Starting _callLoginAPI');
      // Get Firebase token
      final firebaseToken = await FirebaseService.getToken();
      print('🔍 Firebase token obtained: ${firebaseToken?.isNotEmpty}');
      
      // Create signup model with phone and Firebase token
      final signupModel = SignUpUserModel(
        phone: widget.phoneNumber,
        firebaseToken: firebaseToken,
      );
      
      // Call backend API
      print('🔍 Calling backend API...');
      final response = await _api.sendOtp(signupModel);
      print('🔍 API response received - isSuccess: ${response.isSuccess}');
      
      if (response.isSuccess) {
        print('🔍 Login successful, saving data...');
        // Save login status
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('is_logged_in', true);
        
        // Save user data if available
        if (response.user != null) {
          final user = response.user!;
          print('🔍 Saving user data: id=${user.id}, username=${user.username}, state=${user.state}');
          if (user.id != null) {
            await prefs.setString('user_id', user.id.toString());
            print('🔍 User ID saved: ${user.id}');
          }
          if (user.username != null) {
            await prefs.setString('username', user.username!);
          }
          if (user.state != null) {
            await prefs.setString('state', user.state!);
          }
          if (user.isPremium != null) {
            await prefs.setBool('is_premium', user.isPremium!);
          }
        } else {
          print('🔍 No user data in response');
        }
        
        if (mounted) {
          print('🔍 Widget is mounted, setting loading to false and navigating...');
          setState(() => _isLoading = false);
          
          // Navigate to home screen
          print('🔍 Navigating to NewHomeScreen...');
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) {
              print('🔍 Creating NewHomeScreen...');
              return const NewHomeScreen();
            }),
            (route) => false,
          );
          print('🔍 Navigation initiated');
        } else {
          print('🔍 Widget not mounted, skipping navigation');
        }
      } else {
        print('🔍 Login failed: ${response.message}');
        if (mounted) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(response.message)),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Login failed: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (final c in _controllers) c.dispose();
    for (final f in _focusNodes) f.dispose();
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
                // 🔙 Back button
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                ),

                const SizedBox(height: 24),

                const Text(
                  "OTP Verification",
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),

                const SizedBox(height: 12),

                Text(
                  "Enter the OTP sent to ${widget.phoneNumber}",
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 16,
                  ),
                ),

                const SizedBox(height: 32),

                // 🔢 OTP boxes
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(6, (index) {
                    return SizedBox(
                      width: 48,
                      height: 56,
                      child: TextField(
                        controller: _controllers[index],
                        focusNode: _focusNodes[index],
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        maxLength: 1,
                        style: const TextStyle(
                          fontSize: 22,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        decoration: InputDecoration(
                          counterText: "",
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Colors.white),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Colors.white),
                          ),
                        ),
                        onChanged: (value) => _onOtpChanged(index, value),
                      ),
                    );
                  }),
                ),

                const SizedBox(height: 20),

                // 🔁 Resend
                Center(
                  child: _secondsRemaining > 0
                      ? Text(
                          "Didn't receive OTP? Resend in ${_secondsRemaining}s",
                          style: const TextStyle(color: Colors.white70),
                        )
                      : TextButton(
                          onPressed: () {
                            _startTimer();
                            // call resend OTP API later
                          },
                          child: const Text(
                            "Resend OTP",
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                ),

                const SizedBox(height: 32),
                
                                // ✅ Verify button
                                SizedBox(
                                  width: double.infinity,
                                  height: 50,
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor:
                                          (_isOtpComplete && !_isLoading) ? Colors.white : Colors.white54,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                    ),
                                                                                                                            onPressed: (_isOtpComplete && !_isLoading)
                                                                                                                                ? () async {
                                                                                                                                    print('🔍 OTP Verify button pressed');
                                                                                                                                    setState(() => _isLoading = true);
                                                                                                                                    
                                                                                                                                    try {
                                                                                                                                      // Check for hardcoded test OTP first
                                                                                                                                      if (_otp == "123123") {
                                                                                                                                        print('🔍 Using hardcoded test OTP - bypassing Firebase verification');
                                                                                                                                        await _callLoginAPI();
                                                                                                                                        return;
                                                                                                                                      }
                                                                                                                                      
                                                                                                                                      print('🔍 Starting OTP verification with Firebase');
                                                                                                                                      // Step 1: Verify OTP with Firebase
                                                                                                                                      final user = await FirebaseAuthService.verifyOTP(
                                                                                                                                        otpCode: _otp,
                                                                                                                                        onError: (error) {
                                                                                                                                          print('🔍 Firebase OTP verification failed: $error');
                                                                                                                                          if (mounted) {
                                                                                                                                            setState(() => _isLoading = false);
                                                                                                                                            ScaffoldMessenger.of(context).showSnackBar(
                                                                                                                                              SnackBar(content: Text(error)),
                                                                                                                                            );
                                                                                                                                          }
                                                                                                                                        },
                                                                                                                                      );
                                                                                                                                      
                                                                                                                                      print('🔍 Firebase OTP verification completed');
                                                                                                                                      
                                                                                                                                      // Step 2: Call backend login API 
                                                                                                                                      // (proceed even if user is null in test mode)
                                                                                                                                      print('🔍 Calling backend login API');
                                                                                                                                      await _callLoginAPI();
                                                                                                                                      
                                                                                                                                    } catch (e) {
                                                                                                                                      print('🔍 Exception in OTP verification: $e');
                                                                                                                                      if (mounted) {
                                                                                                                                        setState(() => _isLoading = false);
                                                                                                                                        ScaffoldMessenger.of(context).showSnackBar(
                                                                                                                                          SnackBar(content: Text('Verification failed: $e')),
                                                                                                                                        );
                                                                                                                                      }
                                                                                                                                    }
                                                                                                                                  }                                                            : null,
                                    child: _isLoading
                                        ? const SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: Color(0xFF6A4C93),
                                            ),
                                          )
                                        : const Text(
                                            "Verify",
                                            style: TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                              color: Color(0xFF6A4C93),
                                            ),
                                          ),
                                  ),
                                ),
                              ],            ),
          ),
        ),
      ),
    );
  }
}
