import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'dart:io';

class FirebaseAuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static String? _verificationId;
  static bool _testMode = false;
  
  /// Check if running on iOS (for test mode)
  static bool get _isIOS => Platform.isIOS;
  
  /// Send OTP to phone number (Test mode for iOS, Real for Android)
  static Future<void> sendOTP({
    required String phoneNumber,
    required VoidCallback onCodeSent,
    required Function(String error) onError,
    int? resendToken,
  }) async {
    try {
      // Use test mode for iOS development (no Apple Developer account needed)
      if (_isIOS) {
        debugPrint('🔥 iOS Development Mode - Using test OTP: 123123');
        _testMode = true;
        _simulateOTPSent(onCodeSent);
        return;
      }
      
      // Real Firebase OTP for Android (and iOS when Apple account is ready)
      String formattedPhone = phoneNumber;
      if (!formattedPhone.startsWith('+')) {
        formattedPhone = '+91$phoneNumber';
      }
      
      debugPrint('🔥 Sending real OTP to: $formattedPhone');
      
      await _auth.verifyPhoneNumber(
        phoneNumber: formattedPhone,
        verificationCompleted: (PhoneAuthCredential credential) async {
          debugPrint('🔥 Auto verification completed');
        },
        verificationFailed: (FirebaseAuthException e) {
          debugPrint('🔥 Verification failed: ${e.code} - ${e.message}');
          String errorMessage = _getReadableError(e.code);
          onError(errorMessage);
        },
        codeSent: (String verificationId, int? resendToken) {
          debugPrint('🔥 Real OTP code sent to $formattedPhone');
          _verificationId = verificationId;
          onCodeSent();
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          _verificationId = verificationId;
        },
        timeout: const Duration(seconds: 60),
        forceResendingToken: resendToken,
      );
    } catch (e) {
      debugPrint('🔥 Send OTP Error: $e');
      onError('Failed to send OTP. Please try again.');
    }
  }
  
  /// Simulate OTP sent for iOS test mode
  static void _simulateOTPSent(VoidCallback onCodeSent) {
    Future.delayed(const Duration(seconds: 1), () {
      debugPrint('🔥 TEST OTP SENT - Use: 123123');
      _verificationId = 'test_verification_id';
      onCodeSent();
    });
  }
  
  /// Verify real OTP code from SMS
  static Future<User?> verifyOTP({
    required String otpCode,
    required Function(String error) onError,
  }) async {
    try {
      if (_verificationId == null) {
        onError('Verification session expired. Please resend OTP.');
        return null;
      }
      
      debugPrint('🔥 Verifying real OTP: $otpCode');
      
      // iOS Test Mode - Accept test OTP 123123
      if (_testMode && _isIOS) {
        debugPrint("🔥 iOS Test Mode - Verifying OTP: $otpCode");
        if (otpCode.length != 6) {
          onError("Please enter a valid 6-digit OTP code");
          return null;
        }
        if (!RegExp(r"^\d{6}$").hasMatch(otpCode)) {
          onError("OTP should contain only numbers");
          return null;
        }
        if (otpCode == "123123") {
          debugPrint("🔥 iOS Test OTP (123123) Verified Successfully");
          return null;
        } else {
          onError("Invalid test OTP. Use: 123123 for iOS development");
          return null;
        }
      }
      
      // Real Firebase OTP verification for Android
      
      if (otpCode.length != 6) {
        onError('Please enter a valid 6-digit OTP code');
        return null;
      }
      
      if (!RegExp(r'^\d{6}$').hasMatch(otpCode)) {
        onError('OTP should contain only numbers');
        return null;
      }
      
      PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: otpCode,
      );
      
      UserCredential userCredential = await _auth.signInWithCredential(credential);
      debugPrint('🔥 Real OTP Verified Successfully');
      return userCredential.user;
      
    } on FirebaseAuthException catch (e) {
      debugPrint('🔥 OTP Verification Error: ${e.code} - ${e.message}');
      String errorMessage = _getReadableError(e.code);
      onError(errorMessage);
      return null;
    } catch (e) {
      debugPrint('🔥 OTP Verification Error: $e');
      onError('Failed to verify OTP. Please try again.');
      return null;
    }
  }
  
  static User? getCurrentUser() => _auth.currentUser;
  static Future<void> signOut() async => await _auth.signOut();
  
  static String _getReadableError(String code) {
    switch (code) {
      case 'invalid-phone-number':
        return 'Invalid phone number format';
      case 'too-many-requests':
        return 'Too many requests. Please try again later';
      case 'invalid-verification-code':
        return 'Invalid OTP code. Please check and try again';
      case 'invalid-verification-id':
        return 'Verification session expired. Please resend OTP';
      default:
        return 'Authentication failed. Please try again';
    }
  }
}
