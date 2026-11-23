import 'package:carsbuzz/auth/firebase_auth_service.dart';
import 'package:carsbuzz/carlisting/car_api.dart';
import 'package:carsbuzz/login/login_screen.dart';
import 'package:carsbuzz/login/login_session.dart';
import 'package:carsbuzz/login/otp_screen.dart';
import 'package:carsbuzz/myads/my_ads_screen.dart';
import 'package:carsbuzz/notifications/notifications_screen.dart';
import 'package:carsbuzz/storage/app_shared_preferences.dart';
import 'package:carsbuzz/theme/app_colors.dart';
import 'package:carsbuzz/widgets/app_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:package_info_plus/package_info_plus.dart';
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
  String _phone = '';
  String _version = '';
  int _unread = 0;
  final GlobalKey _updateBannerKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final info = await PackageInfo.fromPlatform();
    if (!mounted) return;
    final loggedIn = prefs.getBool('is_logged_in') ?? false;
    setState(() {
      _loggedIn = loggedIn;
      _name = prefs.getString('username') ?? '';
      _phone = prefs.getString('phone_number') ?? '';
      _version = info.version;
    });
    if (loggedIn) _loadUnread();
  }

  /// Android MeViewModel.unreadNotificationCount -> tvNotificationCount badge.
  Future<void> _loadUnread() async {
    final count = await CarApi.unreadCount();
    if (mounted) setState(() => _unread = count);
  }

  Future<void> _openNotifications() async {
    await Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => const NotificationsScreen()));
    _loadUnread();
  }

  /// Android MeViewEvents.DoEditUsername: scroll down to the "update your name" banner.
  void _onEditProfile() {
    final ctx = _updateBannerKey.currentContext;
    if (ctx == null) return;
    Scrollable.ensureVisible(ctx,
        alignment: 1, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
  }

  /// Android OnStartNameUpdateFlow -> VerifyIdentityFragment (send OTP to the saved number)
  /// -> FragmentVerifyNameOtp -> update name.
  Future<void> _startNameUpdate() async {
    final digits = _phone.replaceAll(RegExp(r'\D'), '');
    final phone10 = digits.length > 10 ? digits.substring(digits.length - 10) : digits;
    if (phone10.length != 10) {
      showAppSnackBar(context, 'Phone number is missing. Please try again.');
      return;
    }
    final send = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _VerifyIdentitySheet(phone10: phone10),
    );
    if (send != true || !mounted) return;
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) =>
          OtpScreen(phoneNumber: phone10, origin: LoginOrigin.more, forNameUpdate: true),
    ));
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
  //
  // The iOS app has no Leads / New Stocks screens, so this is the Android layout for
  // "onlyMyAdsInDashboard" (both cards disabled): one "My Ads & Settings" heading, with My Ads
  // shown as a row above Privacy and Legal.

  static const _black = Colors.black;
  static const _subtitle = AppColors.accountSubtitle; // account_text_subtitle
  static const _badgeBlue = AppColors.brandBlue; // account_verified_badge #4169E1

  Widget _buildAccount() {
    final name = _name.trim();
    final initial = name.isEmpty ? '?' : name[0].toUpperCase();
    return Container(
      color: AppColors.accountBg,
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 28, 16, 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _header(),
              const SizedBox(height: 24),
              _profileCard(initial, name),
              const SizedBox(height: 32),
              const Text('My Ads & Settings',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: _black)),
              const SizedBox(height: 16),
              _settingsList(),
              const SizedBox(height: 20),
              _logoutCard(),
              const SizedBox(height: 16),
              _updateNameBanner(),
              const SizedBox(height: 16),
              const SizedBox(
                width: double.infinity,
                child: Text('Carsbuzz Technologies(OPC) Private Limited',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 11, color: _subtitle)),
              ),
              const SizedBox(height: 4),
              SizedBox(
                width: double.infinity,
                child: Text(_version.isEmpty ? '' : 'Version $_version',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 11, color: _subtitle)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// tv_header_title, tv_header_subtitle, iv_notifications + tvNotificationCount.
  Widget _header() {
    return Row(
      children: [
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('My Account',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: _black)),
              SizedBox(height: 4),
              Text('Manage your profile and activity',
                  style: TextStyle(fontSize: 14, color: _subtitle)),
            ],
          ),
        ),
        GestureDetector(
          onTap: _openNotifications,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Material(
                color: Colors.white,
                shape: const CircleBorder(),
                elevation: 2,
                child: SizedBox(
                  width: 48,
                  height: 48,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Image.asset('assets/images/notificationbell.png'),
                  ),
                ),
              ),
              if (_unread > 0)
                Positioned(
                  top: -2,
                  right: -2,
                  child: Container(
                    width: 16,
                    height: 16,
                    alignment: Alignment.center,
                    decoration:
                        const BoxDecoration(color: AppColors.badgeRed, shape: BoxShape.circle),
                    child: Text(
                      _unread > 99 ? '9+' : '$_unread',
                      style: const TextStyle(
                          fontSize: 9, fontWeight: FontWeight.w700, color: Colors.white),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  /// layout_profile_card (bg_account_profile_card: #EBF5FF -> #F0F7FF, radius 24).
  Widget _profileCard(String initial, String name) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFFEBF5FF), Color(0xFFF0F7FF)]),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            alignment: Alignment.center,
            decoration: const BoxDecoration(color: Color(0xFF4169E1), shape: BoxShape.circle),
            child: Text(initial,
                style: const TextStyle(
                    fontSize: 32, fontWeight: FontWeight.w700, color: Colors.white)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              name.isEmpty ? 'Click the icon to edit your name.' : name,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _black),
            ),
          ),
          GestureDetector(
            onTap: _onEditProfile,
            behavior: HitTestBehavior.opaque,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Material(
                  color: Colors.white,
                  shape: const CircleBorder(),
                  elevation: 2,
                  child: SizedBox(
                    width: 30,
                    height: 30,
                    child: Padding(
                      padding: const EdgeInsets.all(10),
                      child: _svg('edit_pencel', _badgeBlue),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                const Text('Edit Profile',
                    style: TextStyle(
                        fontSize: 10, fontWeight: FontWeight.w700, color: _badgeBlue)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// layout_settings_list (bg_account_dashboard_card: white, radius 20, padding 8).
  Widget _settingsList() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration:
          BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
      child: Column(
        children: [
          _row('ic_car', const Color(0xFFEBF5FF), _badgeBlue, 'My Ads',
              'Manage your car advertisements', () {
            Navigator.of(context).push(MaterialPageRoute(builder: (_) => const MyAdsScreen()));
          }),
          _divider(),
          _row('ic_privacy_policy', const Color(0xFFF5F3FF), const Color(0xFF8B5CF6), 'Privacy',
              'Manage your privacy settings', () => _open(AppUrls.privacy)),
          _divider(),
          _row('ic_terms_conditions', const Color(0xFFFFFBEB), const Color(0xFFF59E0B), 'Legal',
              'Terms & conditions and policies', () => _open(AppUrls.terms)),
        ],
      ),
    );
  }

  /// layout_logout (bg_account_logout_card: #FEF2F2, radius 20, 72dp).
  Widget _logoutCard() {
    return Material(
      color: AppColors.logoutBg,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: _logout,
        borderRadius: BorderRadius.circular(20),
        child: SizedBox(
          height: 72,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _iconBox('ic_log_out', const Color(0xFFFEE2E2), AppColors.logoutText),
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
                          style: TextStyle(fontSize: 12, color: _subtitle)),
                    ],
                  ),
                ),
                SizedBox(
                    width: 20,
                    height: 20,
                    child: _svg('ic_chevron_right_24', AppColors.logoutText)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// layout_update_banner (bg_update_name_banner: black, radius 16).
  Widget _updateNameBanner() {
    return GestureDetector(
      key: _updateBannerKey,
      onTap: _startNameUpdate,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration:
            BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(16)),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              padding: const EdgeInsets.all(10),
              decoration: const BoxDecoration(color: Color(0xFF262626), shape: BoxShape.circle),
              child: _svg('baseline_security_24', Colors.white),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Want to update your name?',
                      style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
                  const SizedBox(height: 4),
                  const Text(
                      "For your security, we'll verify your identity before making any changes.",
                      style: TextStyle(fontSize: 12, color: Color(0xFFA3A3A3))),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 40,
                    child: ElevatedButton(
                      onPressed: _startNameUpdate,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF262626),
                        foregroundColor: _badgeBlue,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        shape:
                            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        textStyle: const TextStyle(
                            fontFamily: 'Outfit', fontSize: 13, fontWeight: FontWeight.w700),
                      ),
                      child: const Text('Verify with OTP →'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _svg(String name, Color tint) => SvgPicture.asset(
        'assets/icons/$name.svg',
        fit: BoxFit.contain,
        colorFilter: ColorFilter.mode(tint, BlendMode.srcIn),
      );

  /// 40dp bg_account_icon_wrapper (radius 12) with a 10dp-padded tinted icon.
  Widget _iconBox(String icon, Color bg, Color tint) {
    return Container(
      width: 40,
      height: 40,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
      child: _svg(icon, tint),
    );
  }

  Widget _row(String icon, Color bg, Color tint, String title, String subtitle,
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
                          fontSize: 15, fontWeight: FontWeight.w700, color: _black)),
                  Text(subtitle, style: const TextStyle(fontSize: 12, color: _subtitle)),
                ],
              ),
            ),
            SizedBox(width: 20, height: 20, child: _svg('ic_chevron_right_24', _subtitle)),
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

/// VerifyIdentityFragment (fragment_verify_identity.xml): confirms the masked number before
/// the OTP is sent. Pops true on "Send OTP".
class _VerifyIdentitySheet extends StatelessWidget {
  final String phone10;

  const _VerifyIdentitySheet({required this.phone10});

  @override
  Widget build(BuildContext context) {
    final masked = '+91 ${phone10.substring(0, 2)}•••• ${phone10.substring(6)}';
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Align(
              alignment: Alignment.topRight,
              child: IconButton(
                icon: const Icon(Icons.close, color: Color(0xFF9CA3AF)),
                onPressed: () => Navigator.of(context).pop(false),
              ),
            ),
            const SizedBox(height: 8),
            const Text('Verify your identity',
                style: TextStyle(
                    fontSize: 24, fontWeight: FontWeight.w700, color: AppColors.brandBlue)),
            const SizedBox(height: 8),
            const Text("Before updating your name, we need to verify it's you.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: AppColors.accountSubtitle)),
            const SizedBox(height: 24),
            Text(masked,
                style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
            const SizedBox(height: 24),
            AppButton(
              text: 'Send OTP',
              color: AppColors.brandBlue,
              onPressed: () => Navigator.of(context).pop(true),
            ),
          ],
        ),
      ),
    );
  }
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
