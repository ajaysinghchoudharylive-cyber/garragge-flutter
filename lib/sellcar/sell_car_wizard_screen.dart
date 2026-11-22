import 'package:carsbuzz/login/login_screen.dart';
import 'package:carsbuzz/login/login_session.dart';
import 'package:carsbuzz/models/car_brand_model.dart';
import 'package:carsbuzz/sellcar/screens/sell_model_screen.dart';
import 'package:carsbuzz/sellcar/screens/sell_upload_photos_screen.dart';
import 'package:carsbuzz/sellcar/sell_car_flow.dart';
import 'package:carsbuzz/sellcar/widgets/sell_ui.dart';
import 'package:carsbuzz/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Sell tab entry, a port of the Android SelectYourCarBrandFragment
/// (fragment_select_your_car_brand.xml + SelectYourCarBrandMainAdapter): header, "Upload your
/// car's RC" card, promo badges, Brands grid, Why sell, FAQ, footer. Tapping a brand opens the
/// model screen; the RC card jumps straight to photo upload.
///
/// The class keeps its old name so existing callers (`const SellCarWizardScreen()`) still work.
class SellCarWizardScreen extends StatefulWidget {
  /// Back arrow when the screen is shown as a bottom-nav tab (goes to Dashboard).
  final VoidCallback? onBack;

  const SellCarWizardScreen({super.key, this.onBack});

  @override
  State<SellCarWizardScreen> createState() => _SellCarWizardScreenState();
}

class _SellCarWizardScreenState extends State<SellCarWizardScreen> {
  SellCarFlow _flow = SellCarFlow();
  final ImagePicker _picker = ImagePicker();
  List<CarBrandModel> _brands = [];
  bool _loading = true;
  bool _error = false;
  int? _openFaq;

  static const _faqs = [
    (
      'Why should I sell car on Garragge.com?',
      'Sell car online on Garragge.com to over 3.5 million used car buyers who visit our site every month looking for a used car. Sell your car at the best price possible on Garragge.com. Sell your car in just a few steps. Simple, Fast and Free.'
    ),
    (
      'How do I get the best price for my car?',
      'To get the best price, ensure your car is clean, all documentation is ready, and provide accurate details about its condition during the listing process.'
    ),
    (
      'Is RC transfer free?',
      'Yes, we handle all the paperwork, from loan clearance to RC transfer, completely free of charge.'
    ),
  ];

  @override
  void initState() {
    super.initState();
    _loadBrands();
  }

  Future<void> _loadBrands() async {
    setState(() {
      _loading = true;
      _error = false;
    });
    try {
      final brands = await _flow.repo.getCarBrands();
      if (!mounted) return;
      setState(() {
        _brands = brands;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = true;
      });
    }
  }

  /// Selling needs an account and a free upload slot. Returns false if the user can't continue.
  Future<bool> _ensureCanSell() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return false;
    if (!(prefs.getBool('is_logged_in') ?? false)) {
      Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => const LoginScreen(origin: LoginOrigin.sell),
      ));
      return false;
    }
    await _flow.loadUser();
    final userId = _flow.form.userId;
    if (userId != null && userId > 0) {
      final status = await _flow.repo.checkUploadStatus(userId);
      if (!status.canUpload) {
        if (mounted) await showUploadLimitDialog(context, null);
        return false;
      }
    }
    return mounted;
  }

  Future<void> _onBrandTap(CarBrandModel brand) async {
    if (!await _ensureCanSell()) return;
    _flow.selectBrand(brand.brandName);
    if (!mounted) return;
    await Navigator.of(context).push(MaterialPageRoute(
      settings: const RouteSettings(name: SellRoutes.model),
      builder: (_) => SellModelScreen(flow: _flow),
    ));
    _afterFlow();
  }

  /// After a posted ad, the next one starts from scratch.
  void _afterFlow() {
    if (!mounted) return;
    setState(() {
      if (_flow.posted) _flow = SellCarFlow();
    });
  }

  Future<void> _onUploadRc() async {
    if (!await _ensureCanSell()) return;
    if (!mounted) return;
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_camera_outlined, color: AppColors.accent),
                title: const Text('Take a photo'),
                onTap: () => Navigator.pop(ctx, ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined, color: AppColors.accent),
                title: const Text('Choose from gallery'),
                onTap: () => Navigator.pop(ctx, ImageSource.gallery),
              ),
            ],
          ),
        ),
      ),
    );
    if (source == null) return;
    final image = await _picker.pickImage(
        source: source, imageQuality: 80, maxWidth: 1920, maxHeight: 1920);
    if (image == null || !mounted) return;
    _flow.startRcShortcut(image.path);
    await Navigator.of(context).push(MaterialPageRoute(
      settings: const RouteSettings(name: SellRoutes.upload),
      builder: (_) => SellUploadPhotosScreen(flow: _flow),
    ));
    _afterFlow();
  }

  void _onBack() {
    if (widget.onBack != null) {
      widget.onBack!();
    } else {
      Navigator.of(context).maybePop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            SellToolbar(
              height: 72,
              counter: '1/10',
              onBack: _onBack,
              trailing: _freePill(),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.only(bottom: 24),
                children: [
                  _header(),
                  _rcCard(),
                  _promoBadges(),
                  _orDivider(),
                  _brandsSection(),
                  _whySell(),
                  _faq(),
                  _footer(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _freePill() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: SellColors.emiResultBg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.attach_money, size: 14, color: SellColors.designPurple),
          SizedBox(width: 6),
          Text('100% Free',
              style: TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w700, color: SellColors.designPurple)),
        ],
      ),
    );
  }

  Widget _circleIcon(IconData icon, Color bg, Color tint, {double size = 32}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
      child: Icon(icon, size: size / 2, color: tint),
    );
  }

  Widget _miniFeature(IconData icon, Color bg, Color tint, String title, String sub) {
    return Row(
      children: [
        _circleIcon(icon, bg, tint),
        const SizedBox(width: 8),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w700, color: Colors.black)),
              Text(sub, style: const TextStyle(fontSize: 10, color: SellColors.greySubtitle)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _header() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Sell Your Car',
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.w700, color: Colors.black)),
                    SizedBox(height: 8),
                    Text('Get the best resale value\nin just 2 minutes.',
                        style: TextStyle(
                            fontSize: 16, height: 1.35, color: SellColors.brandsGray)),
                  ],
                ),
              ),
              Opacity(
                opacity: 0.8,
                child: Image.asset('assets/images/sell_map.png',
                    width: 100, height: 100, fit: BoxFit.contain),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Android weights 1 : 1 : 1.2
          Row(
            children: [
              Expanded(
                flex: 10,
                child: _miniFeature(Icons.local_offer_outlined, SellColors.softPurple,
                    SellColors.designPurple, 'Best Price', 'Assured'),
              ),
              Expanded(
                flex: 10,
                child: _miniFeature(Icons.local_fire_department_outlined, SellColors.softGreen,
                    SellColors.green10, 'Quick & Easy', 'Takes 2 Min'),
              ),
              Expanded(
                flex: 12,
                child: _miniFeature(Icons.location_on_outlined, SellColors.softRed,
                    const Color(0xFFEF4444), 'Trusted by', '60,000+ Sellers'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _rcCard() {
    return Card(
      margin: const EdgeInsets.all(12),
      color: Colors.white,
      surfaceTintColor: Colors.white,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Upload your car's RC",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.black)),
            const SizedBox(height: 4),
            const Text(
              "Don't want to pick your car details manually? Just upload a photo of your car's Registration Certificate and continue.",
              style: TextStyle(fontSize: 13, color: SellColors.slate500),
            ),
            const SizedBox(height: 20),
            InkWell(
              onTap: _onUploadRc,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                height: 50,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                      colors: [Color(0xFF6366F1), Color(0xFF5832E0)]),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Stack(
                  alignment: Alignment.center,
                  children: [
                    Text('Upload RC & Continue',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Icon(Icons.arrow_forward, color: Colors.white, size: 24),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _promoBadges() {
    Widget badge(IconData icon, Color bg, Color tint, String title, String sub) {
      return Expanded(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: SellColors.commentBg,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              _circleIcon(icon, bg, tint),
              const SizedBox(height: 8),
              Text(title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w700, color: Colors.black)),
              Text(sub,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 10, color: SellColors.greySubtitle)),
            ],
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          badge(Icons.local_offer_outlined, SellColors.softPurple, SellColors.designPurple,
              '100% Free', 'No hidden charges'),
          badge(Icons.security, SellColors.softGreen, SellColors.green10, 'Secure & Safe',
              'Data is protected'),
          badge(Icons.support_agent, SellColors.softRed, const Color(0xFFEF4444),
              'Instant Support', "We're here to help"),
        ],
      ),
    );
  }

  Widget _orDivider() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(child: Container(height: 2, color: AppColors.aliceBlue)),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8),
            child: Text('Or',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.black)),
          ),
          Expanded(child: Container(height: 2, color: AppColors.aliceBlue)),
        ],
      ),
    );
  }

  Widget _brandsSection() {
    final selected = _flow.form.brandName;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Brands',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.slate900)),
          const SizedBox(height: 12),
          if (_loading)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_error)
            Center(
              child: Column(
                children: [
                  const Text('Could not load brands',
                      style: TextStyle(color: SellColors.slate500)),
                  TextButton(onPressed: _loadBrands, child: const Text('Retry')),
                ],
              ),
            )
          else
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: EdgeInsets.zero,
              itemCount: _brands.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                childAspectRatio: 0.95,
              ),
              itemBuilder: (context, i) {
                final brand = _brands[i];
                final isSelected = brand.brandName == selected;
                return GestureDetector(
                  onTap: () => _onBrandTap(brand),
                  child: Card(
                    margin: const EdgeInsets.all(4),
                    color: isSelected ? SellColors.primaryLight : Colors.white,
                    surfaceTintColor: Colors.white,
                    elevation: isSelected ? 8 : 4,
                    shadowColor: Colors.black26,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 34,
                            height: 34,
                            child: brand.brandLogo == null
                                ? const Icon(Icons.directions_car, color: Colors.black38)
                                : Image.network(brand.brandLogo!,
                                    fit: BoxFit.contain,
                                    errorBuilder: (_, __, ___) =>
                                        const Icon(Icons.directions_car, color: Colors.black38)),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            brand.brandName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 10, color: Colors.black),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _whySell() {
    Widget item(IconData icon, String title, String sub) {
      return Expanded(
        child: Column(
          children: [
            Icon(icon, size: 40, color: AppColors.brandBlue),
            const SizedBox(height: 8),
            Text(title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w700, color: Colors.black)),
            const SizedBox(height: 2),
            Text(sub,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 10, color: SellColors.greySubtitle)),
          ],
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 24, 12, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: SellColors.commentBg,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Why Sell on Carsbuzz?',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Colors.black)),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              item(Icons.sell_outlined, 'Sell Faster', 'Reach thousands\nof active buyers'),
              item(Icons.local_offer_outlined, 'Best Price', 'Get the highest\nmarket value'),
              item(Icons.attach_money, 'Safe & Secure', '100% safe deals &\nsecured payments'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _faq() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('FAQs',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.black)),
          const SizedBox(height: 8),
          for (int i = 0; i < _faqs.length; i++)
            Container(
              margin: const EdgeInsets.only(top: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: SellColors.stroke),
              ),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => setState(() => _openFaq = _openFaq == i ? null : i),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(_faqs[i].$1,
                                style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black)),
                          ),
                          Icon(_openFaq == i ? Icons.expand_less : Icons.expand_more,
                              color: SellColors.brandsGray),
                        ],
                      ),
                      if (_openFaq == i) ...[
                        const SizedBox(height: 8),
                        Text(_faqs[i].$2,
                            style:
                                const TextStyle(fontSize: 13, color: SellColors.slate500)),
                      ],
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _footer() {
    return const Padding(
      padding: EdgeInsets.fromLTRB(16, 24, 16, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.attach_money, size: 16, color: SellColors.greySubtitle),
          SizedBox(width: 4),
          Flexible(
            child: Text(
              'No hidden charges  |  Free to list  |  Trusted by 60,000+ sellers',
              style: TextStyle(fontSize: 10, color: SellColors.greySubtitle),
            ),
          ),
        ],
      ),
    );
  }
}

/// "Upload limit reached" dialog (Android shows the same title).
Future<void> showUploadLimitDialog(BuildContext context, String? message) {
  return showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text('Upload limit reached',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
      content: Text(message ??
          "You've used your free car ads for this month. Upgrade to post more."),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK')),
      ],
    ),
  );
}
