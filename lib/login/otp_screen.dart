import 'dart:async';

import 'package:carsbuzz/auth/firebase_auth_service.dart';
import 'package:carsbuzz/login/login_session.dart';
import 'package:carsbuzz/login/profile_details_screen.dart';
import 'package:carsbuzz/theme/app_colors.dart';
import 'package:carsbuzz/widgets/app_ui.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// "Verify Mobile Number" screen, a port of the Android OtpVerification fragment
/// (fragment_otp_verification_layout.xml + otp_boxes_layout.xml):
/// - the OTP is sent as soon as the screen opens ("OTP is sending..." -> "OTP sent"),
/// - six masked boxes, disabled until the code is sent, auto-submit on the 6th digit,
/// - 2-minute resend timer, then "Didn't receive OTP? Resend" (one resend, like Android),
/// - 3 wrong attempts, then back to the number screen,
/// - back/close is blocked while the timer runs.
class OtpScreen extends StatefulWidget {
  /// Raw 10-digit number typed on the login screen.
  final String phoneNumber;
  final LoginOrigin origin;

  const OtpScreen({
    super.key,
    required this.phoneNumber,
    this.origin = LoginOrigin.home,
  });

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  static const int _maxWrongAttempts = 3;
  static const int _timerSeconds = 120;

  final TextEditingController _otpController = TextEditingController();
  final FocusNode _otpFocus = FocusNode();

  Timer? _timer;
  int _secondsLeft = 0;
  bool _isTimerRunning = false;
  bool _canSendOtp = false; // true once the timer has finished
  bool _codeSent = false;
  bool _loading = true; // sending the code / verifying
  bool _isSubmitting = false;
  bool _verified = false;
  bool _attemptsExhausted = false;
  int _wrongAttempts = 0;
  int _sendCount = 1; // same counter as Android: a resend is refused once it reaches 3

  String get _displayNumber => FirebaseAuthService.e164(widget.phoneNumber);

  @override
  void initState() {
    super.initState();
    _otpController.addListener(_onOtpChanged);
    _otpFocus.addListener(() {
      if (mounted) setState(() {});
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _sendOtp(isResend: false));
  }

  @override
  void dispose() {
    _timer?.cancel();
    _otpController.dispose();
    _otpFocus.dispose();
    super.dispose();
  }

  // ── Sending ────────────────────────────────────────────────────────────────────────────────

  void _sendOtp({required bool isResend}) {
    setState(() => _loading = true);
    showAppSnackBar(context, 'OTP is sending...', duration: const Duration(seconds: 30));
    FirebaseAuthService.sendOtp(
      phoneNumber: widget.phoneNumber,
      isResend: isResend,
      onCodeSent: _onCodeSent,
      onFailed: _onSendFailed,
      onAutoFill: (code) {
        if (!mounted) return;
        _otpController.text = _extractOtp(code);
      },
    );
  }

  void _onCodeSent() {
    if (!mounted) return;
    _sendCount++;
    setState(() {
      _codeSent = true;
      _loading = false;
      _canSendOtp = false;
      _wrongAttempts = 0;
      _attemptsExhausted = false;
    });
    showAppSnackBar(context, 'OTP sent');
    _startTimer();
    _otpFocus.requestFocus();
  }

  void _onSendFailed(FirebaseAuthException e) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    setState(() {
      _loading = false;
      // Nothing is counting down, so let the user try again.
      _canSendOtp = true;
    });
    if (e.code == 'too-many-requests') {
      showAppSnackBar(context,
          'You have exceed maximum number of request. Please come back later.');
    } else if (e.code == 'invalid-phone-number') {
      showMessageDialog(context,
          'The mobile number you entered seems to be incorrect. Please check and try again.',
          onOk: () => Navigator.of(context).pop());
    } else {
      showMessageDialog(
          context, e.message ?? 'Something went wrong. Please try again later.');
    }
  }

  void _startTimer() {
    _timer?.cancel();
    setState(() {
      _secondsLeft = _timerSeconds;
      _isTimerRunning = true;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return timer.cancel();
      if (_secondsLeft <= 1) {
        timer.cancel();
        setState(() {
          _secondsLeft = 0;
          _isTimerRunning = false;
          _canSendOtp = true;
        });
      } else {
        setState(() => _secondsLeft--);
      }
    });
  }

  void _onResendTap() {
    if (_sendCount == 3) {
      showMessageDialog(context,
          'You have exceed maximum number of request. Please come back later.');
      return;
    }
    if (!_canSendOtp) {
      showAppSnackBar(context, 'Please wait for the timer to finish.');
      return;
    }
    // A new code invalidates whatever was typed.
    _otpController.clear();
    _wrongAttempts = 0;
    setState(() => _canSendOtp = false);
    _sendOtp(isResend: true);
  }

  // ── Entering / verifying ────────────────────────────────────────────────────────────────────

  /// Same rule as Android's extractOtp: first standalone 6-digit group, else the first 6 digits.
  String _extractOtp(String text) {
    final group = RegExp(r'\d{6}').firstMatch(text);
    if (group != null) return group.group(0)!;
    final digits = text.replaceAll(RegExp(r'\D'), '');
    return digits.length > 6 ? digits.substring(0, 6) : digits;
  }

  void _onOtpChanged() {
    setState(() {});
    if (_otpController.text.length == 6) _submitOtp();
  }

  void _onVerifyTap() {
    if (_loading) return;
    final code = _otpController.text;
    if (code.isEmpty) {
      showAppSnackBar(context, 'Please enter OTP');
    } else if (code.length < 6) {
      showAppSnackBar(context, 'Please enter complete OTP');
    } else {
      _submitOtp();
    }
  }

  Future<void> _submitOtp() async {
    if (_attemptsExhausted || _isSubmitting || _verified || !_codeSent) return;
    final code = _otpController.text;
    if (code.length != 6) return;

    _isSubmitting = true;
    setState(() => _loading = true);
    try {
      await FirebaseAuthService.verifyOtp(code);
    } catch (_) {
      _isSubmitting = false;
      if (mounted) _onWrongOtp();
      return;
    }

    _verified = true;
    _isSubmitting = false;
    _timer?.cancel();
    _isTimerRunning = false;
    await _loginWithBackend();
  }

  void _onWrongOtp() {
    _wrongAttempts++;
    _otpController.clear();
    setState(() => _loading = false);

    if (_wrongAttempts >= _maxWrongAttempts) {
      setState(() => _attemptsExhausted = true);
      showMessageDialog(
        context,
        'You have reached the maximum number of attempts. Please verify your number again.',
        onOk: () {
          if (mounted) Navigator.of(context).pop();
        },
      );
      return;
    }
    final remaining = _maxWrongAttempts - _wrongAttempts;
    showMessageDialog(context, 'Please enter the correct OTP. $remaining attempt(s) left.');
  }

  Future<void> _loginWithBackend() async {
    try {
      final response = await LoginSession.signUp(widget.phoneNumber);
      if (!mounted) return;
      setState(() => _loading = false);
      final username = response.user?.username ?? '';
      if (username.trim().isEmpty) {
        // New user: ask for the name first (Android: FragmentUpdateName).
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => ProfileDetailsScreen(
              phoneNumber: widget.phoneNumber,
              origin: widget.origin,
            ),
          ),
        );
      } else {
        LoginSession.finish(context, widget.origin);
      }
    } on LoginFailedException catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      _verified = false;
      showMessageDialog(context, e.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
      _verified = false;
      showMessageDialog(context, 'Something went wrong!');
    }
  }

  // ── Navigation ──────────────────────────────────────────────────────────────────────────────

  void _onCloseTap() {
    if (_isTimerRunning) {
      showAppSnackBar(context, 'Please wait for the timer to finish.');
    } else {
      Navigator.of(context).pop();
    }
  }

  Future<void> _onEditTap() async {
    final yes = await showConfirmDialog(context, 'Do you want to edit your phone number?');
    if (yes && mounted) {
      _timer?.cancel();
      Navigator.of(context).pop();
    }
  }

  // ── UI ──────────────────────────────────────────────────────────────────────────────────────

  String get _timerText {
    final minutes = _secondsLeft ~/ 60;
    final seconds = _secondsLeft % 60;
    return '$minutes min, $seconds sec Enter the OTP.';
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_isTimerRunning,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) showAppSnackBar(context, 'Please wait for the timer to finish.');
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Align(
                  alignment: Alignment.topRight,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 24),
                    child: SizedBox(
                      width: 40,
                      height: 40,
                      child: IconButton(
                        padding: EdgeInsets.zero,
                        icon: const Icon(Icons.close, color: Color(0xFF9CA3AF)),
                        onPressed: _onCloseTap,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Verify Mobile Number',
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontWeight: FontWeight.w600,
                    fontSize: 28,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 32),
                const Text(
                  'OTP sent to your mobile number.',
                  style: TextStyle(
                      fontFamily: 'Outfit', fontSize: 14, color: Color(0xFF374151)),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      _displayNumber,
                      style: const TextStyle(
                        fontFamily: 'Outfit',
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(width: 12),
                    InkWell(
                      onTap: _onEditTap,
                      child: const Padding(
                        padding: EdgeInsets.all(4),
                        child: Text(
                          'Edit',
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            color: AppColors.accent,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                _buildOtpBoxes(),
                const SizedBox(height: 16),
                _buildTimerOrResend(),
                const SizedBox(height: 32),
                AppButton(text: 'Verify', loading: _loading, onPressed: _onVerifyTap),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Six boxes drawn over one hidden text field. A single field handles typing, backspace,
  /// paste, and iOS's "From Messages" one-time-code suggestion.
  Widget _buildOtpBoxes() {
    final enabled = _codeSent && !_attemptsExhausted && !_verified;
    final text = _otpController.text;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: enabled ? () => _otpFocus.requestFocus() : null,
      child: Stack(
        children: [
          Row(
            children: List.generate(6, (i) {
              final filled = i < text.length;
              final focused = enabled && _otpFocus.hasFocus && i == text.length;
              return Expanded(
                child: Container(
                  height: 64,
                  margin: EdgeInsets.only(right: i < 5 ? 8 : 0),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(8),
                    border: focused ? Border.all(color: AppColors.accent, width: 1.5) : null,
                  ),
                  child: Text(
                    filled ? '*' : '',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: enabled ? Colors.black : Colors.black38,
                    ),
                  ),
                ),
              );
            }),
          ),
          // Invisible input that owns the keyboard.
          Positioned.fill(
            child: Opacity(
              opacity: 0,
              child: TextField(
                controller: _otpController,
                focusNode: _otpFocus,
                enabled: enabled,
                keyboardType: TextInputType.number,
                autofillHints: const [AutofillHints.oneTimeCode],
                showCursor: false,
                enableInteractiveSelection: false,
                inputFormatters: [_OtpPasteFormatter(_extractOtp)],
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  counterText: '',
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimerOrResend() {
    if (_isTimerRunning) {
      return Text(
        _timerText,
        style: const TextStyle(
            fontFamily: 'Outfit', fontSize: 14, color: Color(0xFF4B5563)),
      );
    }
    if (!_canSendOtp) return const SizedBox(height: 18);
    return GestureDetector(
      onTap: _onResendTap,
      child: const Text(
        "Didn't receive OTP? Resend",
        style: TextStyle(
          fontFamily: 'Outfit',
          fontWeight: FontWeight.w700,
          fontSize: 14,
          color: AppColors.accent,
          decoration: TextDecoration.underline,
          decorationColor: AppColors.accent,
        ),
      ),
    );
  }
}

/// Keeps only digits (max 6). A paste of a whole SMS ("Your code is 123456") becomes "123456".
class _OtpPasteFormatter extends TextInputFormatter {
  final String Function(String) extract;

  _OtpPasteFormatter(this.extract);

  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final added = newValue.text.length - oldValue.text.length;
    final String next;
    if (added > 1) {
      next = extract(newValue.text);
    } else {
      final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
      next = digits.length > 6 ? digits.substring(0, 6) : digits;
    }
    return TextEditingValue(
      text: next,
      selection: TextSelection.collapsed(offset: next.length),
    );
  }
}
