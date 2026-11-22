import 'package:carsbuzz/auth/firebase_auth_service.dart';
import 'package:carsbuzz/login/login_screen.dart';
import 'package:carsbuzz/login/login_session.dart';
import 'package:carsbuzz/storage/app_shared_preferences.dart';
import 'package:carsbuzz/theme/app_colors.dart';
import 'package:carsbuzz/widgets/app_ui.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

/// "More" tab, a port of the Android MeFragment: fragment_profile.xml when logged in,
/// me_non_login_layout.xml for guests.
class MoreScreen extends StatefulWidget {
  final VoidCallback onLoggedOut;

  const MoreScreen({super.key, required this.onLoggedOut});

  @override
  State<MoreScreen> createState() => _MoreScreenState();
}

class _MoreScreenState extends State<MoreScreen> {
  bool? _loggedIn;
  String _name = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _loggedIn = prefs.getBool('is_logged_in') ?? false;
      _name = prefs.getString('username') ?? '';
    });
  }

  Future<void> _open(String url) =>
      launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);

  void _login() {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => const LoginScreen(origin: LoginOrigin.more),
    ));
  }

  Future<void> _logout() async {
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => const _LogoutSheet(),
    );
    if (confirmed != true) return;
    final prefs = await SharedPreferences.getInstance();
    await AppSharedPreferences(prefs).logout();
    await prefs.remove('first_name');
    await prefs.remove('last_name');
    await FirebaseAuthService.signOut();
    widget.onLoggedOut();
  }

  @override
  Widget build(BuildContext context) {
    final loggedIn = _loggedIn;
    if (loggedIn == null) return const ColoredBox(color: AppColors.accountBg);
    return loggedIn ? _buildAccount() : _buildGuest();
  }

  // ── Guest (me_non_login_layout.xml) ─────────────────────────────────────────────────────────

  Widget _buildGuest() {
    return Container(
      color: Colors.white,
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 60, 24, 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Welcome!',
                  style: TextStyle(
                      fontSize: 48, fontWeight: FontWeight.w700, color: AppColors.slate900)),
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(top: 12),
                decoration: BoxDecoration(
                  color: AppColors.accent,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'You have not yet logged in.\nPlease login to continue.',
                style: TextStyle(fontSize: 20, color: AppColors.slate600),
              ),
              Container(
                height: 1,
                margin: const EdgeInsets.only(top: 32),
                color: const Color(0xFFF1F5F9),
              ),
              const SizedBox(height: 32),
              _feature(Icons.security, const Color(0xFFEFF6FF), AppColors.accent,
                  'Secure & Private', 'Your data is safe with us'),
              const SizedBox(height: 32),
              _feature(Icons.bolt, const Color(0xFFFFF7ED), AppColors.brandBlue,
                  'Quick & Easy', 'Login in just a few seconds'),
              const SizedBox(height: 32),
              _feature(Icons.person_outline, const Color(0xFFF5F3FF), const Color(0xFF6D28D9),
                  'Personalized for you', 'Experience made just for you'),
              const SizedBox(height: 48),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _login,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Login to continue',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                      SizedBox(width: 8),
                      Icon(Icons.trending_flat),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _feature(IconData icon, Color bg, Color tint, String title, String desc) {
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
          child: Icon(icon, color: tint, size: 24),
        ),
        const SizedBox(width: 20),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF1E293B))),
              const SizedBox(height: 2),
              Text(desc, style: const TextStyle(fontSize: 14, color: AppColors.slate500)),
            ],
          ),
        ),
      ],
    );
  }

  // ── Logged in (fragment_profile.xml) ───────────────────────────────────────────────────────

  Widget _buildAccount() {
    final initial = _name.trim().isEmpty ? '' : _name.trim()[0].toUpperCase();
    return Container(
      color: AppColors.accountBg,
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 28, 16, 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('My Account',
                  style: TextStyle(
                      fontSize: 24, fontWeight: FontWeight.w700, color: Colors.black)),
              const SizedBox(height: 4),
              const Text('Manage your profile and activity',
                  style: TextStyle(fontSize: 14, color: AppColors.accountSubtitle)),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFEBF5FF), Color(0xFFF0F7FF)],
                  ),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      alignment: Alignment.center,
                      decoration: const BoxDecoration(
                          color: AppColors.brandBlue, shape: BoxShape.circle),
                      child: Text(initial,
                          style: const TextStyle(
                              fontSize: 32, fontWeight: FontWeight.w700, color: Colors.white)),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        _name,
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w700, color: Colors.black),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              const Text('My Ads & Settings',
                  style: TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w700, color: Colors.black)),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: [
                    _row(Icons.directions_car_outlined, const Color(0xFFEBF5FF),
                        AppColors.brandBlue, 'My Ads', 'Manage your car advertisements', () {
                      showAppSnackBar(context, 'My Ads is not available in this app yet.');
                    }),
                    _divider(),
                    _row(Icons.privacy_tip_outlined, const Color(0xFFF5F3FF),
                        const Color(0xFF8B5CF6), 'Privacy', 'Manage your privacy settings',
                        () => _open(AppUrls.privacy)),
                    _divider(),
                    _row(Icons.gavel_outlined, const Color(0xFFFFFBEB), const Color(0xFFF59E0B),
                        'Legal', 'Terms & conditions and policies', () => _open(AppUrls.terms)),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              InkWell(
                onTap: _logout,
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  height: 72,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: AppColors.logoutBg,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      _iconBox(Icons.logout, const Color(0xFFFEE2E2), AppColors.logoutText),
                      const SizedBox(width: 16),
                      const Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Log out',
                                style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.logoutText)),
                            Text('Sign out from your account',
                                style: TextStyle(fontSize: 12, color: AppColors.accountSubtitle)),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right, color: AppColors.logoutText),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _iconBox(IconData icon, Color bg, Color tint) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
      child: Icon(icon, size: 20, color: tint),
    );
  }

  Widget _row(IconData icon, Color bg, Color tint, String title, String subtitle,
      VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: SizedBox(
        height: 64,
        child: Row(
          children: [
            const SizedBox(width: 8),
            _iconBox(icon, bg, tint),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w700, color: Colors.black)),
                  Text(subtitle,
                      style: const TextStyle(fontSize: 12, color: AppColors.accountSubtitle)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, size: 20, color: AppColors.accountSubtitle),
            const SizedBox(width: 8),
          ],
        ),
      ),
    );
  }

  Widget _divider() => Container(
        height: 1,
        margin: const EdgeInsets.symmetric(horizontal: 16),
        color: const Color(0xFFF3F4F6),
      );
}

/// LogoutConfirmationBottomSheet (fragment_logout_confirmation.xml). Pops true on Logout.
class _LogoutSheet extends StatelessWidget {
  const _LogoutSheet();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: const Color(0xFFE5E7EB),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const Text(
              'Do you really want to logout?',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.accent),
            ),
            const SizedBox(height: 24),
            AppButton(
              text: 'Logout',
              height: 54,
              onPressed: () => Navigator.of(context).pop(true),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: OutlinedButton(
                onPressed: () => Navigator.of(context).pop(false),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.accent,
                  side: const BorderSide(color: AppColors.accent),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Cancel',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
