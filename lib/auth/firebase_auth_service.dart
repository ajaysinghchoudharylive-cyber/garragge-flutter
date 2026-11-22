import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// Firebase phone-number verification, mirroring the Android app's firebasemobileauth/PhoneAuth.kt.
///
/// - The number is always sent in E.164 form (+91XXXXXXXXXX).
/// - The ForceResendingToken from every `codeSent` is cached, and passed back on resend so Firebase
///   issues a NEW code instead of re-delivering the old one.
/// - Auto-retrieval timeout is 0 (same as Android); the user types the code, or iOS offers it from
///   the SMS through the keyboard's one-time-code suggestion.
/// - The same real flow runs on Android and iOS (the old iOS "test OTP 123123" shortcut is gone).
class FirebaseAuthService {
  FirebaseAuthService._();

  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static String? _verificationId;
  static int? _resendToken;

  /// Canonical E.164 number for a 10-digit Indian mobile number (or any input containing one).
  static String e164(String raw) {
    final digits = raw.replaceAll(RegExp(r'\D'), '');
    final last10 = digits.length >= 10 ? digits.substring(digits.length - 10) : digits;
    return '+91$last10';
  }

  /// Sends (or, with [isResend], re-sends) the OTP.
  static Future<void> sendOtp({
    required String phoneNumber,
    bool isResend = false,
    required VoidCallback onCodeSent,
    required void Function(FirebaseAuthException e) onFailed,
    void Function(String smsCode)? onAutoFill,
  }) async {
    try {
      await _auth.verifyPhoneNumber(
        phoneNumber: e164(phoneNumber),
        timeout: Duration.zero,
        forceResendingToken: isResend ? _resendToken : null,
        verificationCompleted: (PhoneAuthCredential credential) {
          // Android instant verification: fill the boxes with the code; the screen submits it.
          final code = credential.smsCode;
          if (code != null && code.isNotEmpty) onAutoFill?.call(code);
        },
        verificationFailed: (FirebaseAuthException e) {
          debugPrint('Phone verification failed: ${e.code} ${e.message}');
          onFailed(e);
        },
        codeSent: (String verificationId, int? resendToken) {
          _verificationId = verificationId;
          _resendToken = resendToken;
          onCodeSent();
        },
        // Not an error: with auto-retrieval disabled this fires right after the code is sent.
        codeAutoRetrievalTimeout: (String verificationId) {
          _verificationId ??= verificationId;
        },
      );
    } on FirebaseAuthException catch (e) {
      onFailed(e);
    } catch (e) {
      onFailed(FirebaseAuthException(code: 'unknown', message: e.toString()));
    }
  }

  /// Signs in with the typed code. Throws [FirebaseAuthException] if the code is wrong or the
  /// verification session is gone.
  static Future<void> verifyOtp(String code) async {
    final verificationId = _verificationId;
    if (verificationId == null) {
      throw FirebaseAuthException(
        code: 'session-expired',
        message: 'Verification session expired. Please resend the OTP.',
      );
    }
    final credential = PhoneAuthProvider.credential(
      verificationId: verificationId,
      smsCode: code,
    );
    await _auth.signInWithCredential(credential);
  }

  static User? getCurrentUser() => _auth.currentUser;

  static Future<void> signOut() async {
    _verificationId = null;
    _resendToken = null;
    await _auth.signOut();
  }
}
