import 'package:carsbuzz/login/login_session.dart';
import 'package:carsbuzz/network/api_client.dart';
import 'package:carsbuzz/theme/app_colors.dart';
import 'package:carsbuzz/widgets/app_ui.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// "Profile Details" screen shown to a brand-new user right after OTP, a port of the Android
/// FragmentUpdateName (upload_name_layout.xml). Saves the name with PUT cars/updatePhoneNumber.
class ProfileDetailsScreen extends StatefulWidget {
  final String phoneNumber;
  final LoginOrigin origin;

  const ProfileDetailsScreen({
    super.key,
    required this.phoneNumber,
    this.origin = LoginOrigin.home,
  });

  @override
  State<ProfileDetailsScreen> createState() => _ProfileDetailsScreenState();
}

class _ProfileDetailsScreenState extends State<ProfileDetailsScreen> {
  final _firstController = TextEditingController();
  final _lastController = TextEditingController();
  String? _firstError;
  String? _lastError;
  bool _loading = false;

  bool get _isValid =>
      _firstController.text.trim().isNotEmpty && _lastController.text.trim().isNotEmpty;

  @override
  void initState() {
    super.initState();
    _firstController.addListener(_revalidate);
    _lastController.addListener(_revalidate);
  }

  @override
  void dispose() {
    _firstController.dispose();
    _lastController.dispose();
    super.dispose();
  }

  void _revalidate() {
    setState(() {
      if (_firstController.text.trim().isNotEmpty) _firstError = null;
      if (_lastController.text.trim().isNotEmpty) _lastError = null;
    });
  }

  Future<void> _onContinue() async {
    final first = _firstController.text.trim();
    final last = _lastController.text.trim();
    setState(() {
      _firstError = first.isEmpty ? 'First name required' : null;
      _lastError = last.isEmpty ? 'Last name required' : null;
    });
    if (first.isEmpty || last.isEmpty) return;

    final fullName = [first, last].where((s) => s.isNotEmpty).join(' ');
    setState(() => _loading = true);
    try {
      final response = await ApiClient.dio.put<dynamic>(
        'cars/updatePhoneNumber',
        data: {'phone': widget.phoneNumber, 'username': fullName},
      );
      final body = response.data;
      final savedName = body is Map && body['userName'] != null
          ? body['userName'].toString()
          : fullName;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('username', savedName);
      await prefs.setString('first_name', first);
      await prefs.setString('last_name', last);
      if (!mounted) return;
      LoginSession.finish(context, widget.origin);
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
      showMessageDialog(context, 'Failed to update profile. Please try again.');
    }
  }

  InputDecoration _decoration(String label, String? error) {
    OutlineInputBorder border(Color color) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: color),
        );
    return InputDecoration(
      labelText: label,
      errorText: error,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      labelStyle: const TextStyle(fontFamily: 'Outfit', color: AppColors.textSecondary),
      floatingLabelStyle: const TextStyle(fontFamily: 'Outfit', color: AppColors.accent),
      enabledBorder: border(const Color(0xFF9CA3AF)),
      focusedBorder: border(AppColors.accent),
      errorBorder: border(Colors.red),
      focusedErrorBorder: border(Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    const fieldStyle =
        TextStyle(fontFamily: 'Outfit', fontSize: 16, color: AppColors.textPrimary);
    return PopScope(
      // The account already exists at this point; the name is required before continuing.
      canPop: false,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Profile Details',
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontWeight: FontWeight.w700,
                    fontSize: 28,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Update your personal information',
                  style: TextStyle(
                      fontFamily: 'Outfit', fontSize: 15, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 32),
                TextField(
                  controller: _firstController,
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.givenName],
                  style: fieldStyle,
                  decoration: _decoration('First Name', _firstError),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _lastController,
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.done,
                  autofillHints: const [AutofillHints.familyName],
                  onSubmitted: (_) => _onContinue(),
                  style: fieldStyle,
                  decoration: _decoration('Last Name', _lastError),
                ),
                const Spacer(),
                Opacity(
                  opacity: _isValid || _loading ? 1 : 0.5,
                  child: AppButton(
                    text: 'Continue',
                    loading: _loading,
                    onPressed: _onContinue,
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
