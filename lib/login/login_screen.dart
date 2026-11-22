import 'package:carsbuzz/login/login_session.dart';
import 'package:carsbuzz/login/otp_screen.dart';
import 'package:carsbuzz/theme/app_colors.dart';
import 'package:carsbuzz/widgets/app_logo.dart';
import 'package:carsbuzz/widgets/app_ui.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

/// "Login or Signup" screen, a port of the Android FragmentLoginScreen (fragment_login_layout.xml).
/// The OTP is sent on the next screen, exactly like Android.
class LoginScreen extends StatefulWidget {
  final LoginOrigin origin;

  const LoginScreen({super.key, this.origin = LoginOrigin.home});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _phoneController = TextEditingController();
  late final TapGestureRecognizer _termsTap = TapGestureRecognizer()
    ..onTap = () => _open(AppUrls.terms);
  late final TapGestureRecognizer _privacyTap = TapGestureRecognizer()
    ..onTap = () => _open(AppUrls.privacy);

  @override
  void dispose() {
    _phoneController.dispose();
    _termsTap.dispose();
    _privacyTap.dispose();
    super.dispose();
  }

  Future<void> _open(String url) async {
    await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  }

  void _onContinue() {
    FocusScope.of(context).unfocus();
    final number = _phoneController.text.replaceAll(RegExp(r'\s'), '');
    if (number.length != 10 || !RegExp(r'^\d{10}$').hasMatch(number)) {
      showMessageDialog(
        context,
        'Please enter a correct 10-digit phone number',
        onOk: () => _phoneController.clear(),
      );
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => OtpScreen(phoneNumber: number, origin: widget.origin),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final canClose = Navigator.of(context).canPop();
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Wavy background texture, tinted #F0F7FF.
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 240,
            child: Image.asset(
              'assets/images/bg_screens_texture.png',
              fit: BoxFit.cover,
              color: const Color(0xFFF0F7FF),
              colorBlendMode: BlendMode.srcIn,
            ),
          ),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) => SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  // Top block + bottom block pushed apart; the min height makes the Column
                  // fill the screen so the notice and footer sit at the bottom.
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        children: [
                        Align(
                          alignment: Alignment.topRight,
                          child: Padding(
                            padding: const EdgeInsets.only(top: 24, right: 16),
                            child: SizedBox(
                              width: 40,
                              height: 40,
                              child: canClose
                                  ? IconButton(
                                      padding: EdgeInsets.zero,
                                      icon: const Icon(Icons.close,
                                          color: Color(0xFF9CA3AF)),
                                      onPressed: () => Navigator.of(context).pop(),
                                    )
                                  : null,
                            ),
                          ),
                        ),
                        const SizedBox(height: 86), // logo sits 150dp from the top
                        const AppLogo(size: 100),
                        const SizedBox(height: 32),
                        const Text(
                          'Login or Signup',
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontWeight: FontWeight.w700,
                            fontSize: 26,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 40),
                        _buildPhoneInput(),
                        const SizedBox(height: 24),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: AppButton(text: 'Continue', onPressed: _onContinue),
                        ),
                        ],
                      ),
                      Column(
                        children: [
                          const SizedBox(height: 24),
                          _buildEmailNotice(),
                          const SizedBox(height: 32),
                          _buildFooter(),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhoneInput() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFD1D5DB)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Enter Mobile Number',
            style: TextStyle(
                fontFamily: 'Outfit', fontSize: 12, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Text(
                '+91',
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontWeight: FontWeight.w600,
                  fontSize: 18,
                  color: Color(0xFF6B7280),
                ),
              ),
              Container(
                width: 1,
                height: 24,
                margin: const EdgeInsets.symmetric(horizontal: 12),
                color: const Color(0xFFD1D5DB),
              ),
              Expanded(
                child: TextField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  autofillHints: const [AutofillHints.telephoneNumberNational],
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(10),
                  ],
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _onContinue(),
                  style: const TextStyle(
                    fontFamily: 'Outfit',
                    fontWeight: FontWeight.w600,
                    fontSize: 18,
                    color: AppColors.textPrimary,
                  ),
                  decoration: const InputDecoration(
                    isDense: true,
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                    hintText: '00000 00000',
                    hintStyle: TextStyle(
                      fontFamily: 'Outfit',
                      fontWeight: FontWeight.w600,
                      fontSize: 18,
                      color: Color(0xFF9CA3AF),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmailNotice() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F7FF),
        border: Border.all(color: const Color(0xFFD1E9FF)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Row(
        children: [
          Icon(Icons.mail_outline, size: 20, color: Color(0xFF3B82F6)),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Email based login is no longer available. Please click here to restore your mobile number.',
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 13,
                height: 1.35,
                color: Color(0xFF1E40AF),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    const base = TextStyle(
      fontFamily: 'Outfit',
      fontSize: 12,
      height: 1.5,
      color: AppColors.textSecondary,
    );
    const link = TextStyle(
      fontFamily: 'Outfit',
      fontSize: 12,
      height: 1.5,
      fontWeight: FontWeight.w700,
      color: AppColors.accent,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Text.rich(
        TextSpan(
          style: base,
          children: [
            const TextSpan(text: 'By Signing In, I agree to '),
            TextSpan(text: 'Terms & Conditions', style: link, recognizer: _termsTap),
            const TextSpan(text: ' and '),
            TextSpan(text: 'Privacy Policy', style: link, recognizer: _privacyTap),
            const TextSpan(text: '.'),
          ],
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}
