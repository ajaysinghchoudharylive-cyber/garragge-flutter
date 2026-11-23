import 'dart:async';

import 'package:carsbuzz/carlisting/car_ad.dart';
import 'package:carsbuzz/carlisting/car_api.dart';
import 'package:carsbuzz/carlisting/car_listing_screen.dart' show CarPhoto;
import 'package:carsbuzz/login/login_screen.dart';
import 'package:carsbuzz/login/login_session.dart';
import 'package:carsbuzz/theme/app_colors.dart';
import 'package:carsbuzz/widgets/app_network_image.dart';
import 'package:carsbuzz/widgets/notification_permission_prompt.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

/// Car details, a port of the Android FragmentCarDetails (fragment_buy_used_car_details_new.xml
/// + fragment_buy_used_car_details_overview_tab.xml). Data: GET cars/ad-details/{id}?userId=.
class CarDetailsScreen extends StatefulWidget {
  final int carId;

  /// Opened from My Ads (Android isFromMeFragment): the seller's own ad, no "Contact Seller".
  final bool isFromMyAds;

  const CarDetailsScreen({super.key, required this.carId, this.isFromMyAds = false});

  @override
  State<CarDetailsScreen> createState() => _CarDetailsScreenState();
}

class _CarDetailsScreenState extends State<CarDetailsScreen> {
  static const _primary = Color(0xFF111111);
  static const _secondary = Color(0xFF757575);
  static const _border = Color(0xFFEAEAEA);
  static const _bg = Color(0xFFF7F7F7);
  static const _navy = Color(0xFF1E293B);

  final PageController _pager = PageController();
  Timer? _autoScroll;
  CarDetails? _details;
  bool _loading = true;
  bool _error = false;
  bool _isFavorite = false;
  bool _isOwner = false;
  int _page = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _autoScroll?.cancel();
    _pager.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = false;
    });
    try {
      final d = await CarApi.details(widget.carId);
      final prefs = await SharedPreferences.getInstance();
      final favs = await FavoritesStore.all();
      String last10(String s) {
        final digits = s.replaceAll(RegExp(r'\D'), '');
        return digits.length > 10 ? digits.substring(digits.length - 10) : digits;
      }

      final myPhone = last10(prefs.getString('phone_number') ?? '');
      if (!mounted) return;
      setState(() {
        _details = d;
        _isFavorite = favs.contains(widget.carId);
        _isOwner = myPhone.isNotEmpty && myPhone == last10(d.car.phoneNumber);
        _loading = false;
      });
      CarApi.incrementViews(widget.carId);
      _startAutoScroll(d.car.images.length);
      Future.delayed(const Duration(milliseconds: 1500), () {
        if (mounted) NotificationPermissionPrompt.maybeAsk(context);
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = true;
      });
    }
  }

  /// Gallery advances every 4 seconds and wraps to the first photo (Android scrollOrExit).
  void _startAutoScroll(int count) {
    _autoScroll?.cancel();
    if (count < 2) return;
    _autoScroll = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!_pager.hasClients) return;
      final next = (_page + 1) % count;
      _pager.animateToPage(next,
          duration: const Duration(milliseconds: 400), curve: Curves.easeInOut);
    });
  }

  Future<void> _toggleFavorite() async {
    final added = await FavoritesStore.toggle(widget.carId);
    if (mounted) setState(() => _isFavorite = added);
  }

  void _share(CarAd car) {
    Share.share(
      '🚗 **Check out this amazing ${car.make} ${car.model} (${car.year})!** 🚗\n'
      '💰 **Price:** ${car.price}\n'
      '🔗 View details: ${car.shareUrl}',
      subject: 'Share Car Ad via',
    );
  }

  String _whatsAppMessage(CarAd car) =>
      "Hi, I'm interested in your car ad details for ${car.make} ${car.model} ${car.transmission} ${car.year}. \n"
      'If you are still looking for a genuine buyer then we can take our conversation ahead.\n'
      'Check out the details here: ${car.shareUrl}';

  Future<void> _openWhatsApp(CarAd car) async {
    var phone = car.phoneNumber.replaceAll('+', '').replaceAll(' ', '');
    if (phone.length == 10) phone = '91$phone';
    final uri = Uri.parse(
        'https://wa.me/$phone?text=${Uri.encodeComponent(_whatsAppMessage(car))}');
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> _contactSeller(CarAd car) async {
    if (!await CarApi.isLoggedIn()) {
      if (!mounted) return;
      Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => const LoginScreen(origin: LoginOrigin.buy),
      ));
      return;
    }
    CarApi.recordLead(car.id, 'interested');
    if (!mounted) return;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => _SellerSheet(
        name: car.ownerName,
        number: car.phoneNumber,
        onWhatsApp: () {
          Navigator.pop(ctx);
          CarApi.recordLead(car.id, 'contacted');
          _openWhatsApp(car);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading || _error || _details == null) {
      return Scaffold(
        backgroundColor: _bg,
        appBar: AppBar(backgroundColor: Colors.white, surfaceTintColor: Colors.white),
        body: Center(
          child: _loading
              ? const CircularProgressIndicator()
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Could not load this car', style: TextStyle(color: _secondary)),
                    TextButton(onPressed: _load, child: const Text('Retry')),
                  ],
                ),
        ),
      );
    }
    final d = _details!;
    final car = d.car;
    final owner = widget.isFromMyAds || _isOwner;

    return Scaffold(
      backgroundColor: _bg,
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _gallery(car),
                      if (car.images.length > 1) _thumbnails(car),
                      _title(car, d.variantName),
                      _price(car),
                    ],
                  ),
                ),
                _highlights(car),
                _emiCard(car),
                _health(car),
                if (d.alreadyContacted && !owner) _sellerCard(car),
                const SizedBox(height: 24),
              ],
            ),
          ),
          if (!owner) _bottomBar(car, d.alreadyContacted),
        ],
      ),
    );
  }

  Widget _gallery(CarAd car) {
    final top = MediaQuery.of(context).padding.top;
    return SizedBox(
      height: 260 + top,
      child: Stack(
        children: [
          Positioned.fill(
            top: top,
            child: car.images.isEmpty
                ? const CarPhoto(url: null)
                : PageView.builder(
                    controller: _pager,
                    itemCount: car.images.length,
                    onPageChanged: (i) => setState(() => _page = i),
                    itemBuilder: (_, i) => CarPhoto(url: car.images[i]),
                  ),
          ),
          Positioned(
            top: top + 8,
            left: 8,
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: () => Navigator.of(context).pop(),
              child: Container(
                width: 40,
                height: 40,
                decoration:
                    const BoxDecoration(color: Color(0xFFF3F4F6), shape: BoxShape.circle),
                child: const Icon(Icons.arrow_back, size: 20, color: Colors.black),
              ),
            ),
          ),
          Positioned(
            left: 16,
            bottom: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.55),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.photo_camera, size: 14, color: Colors.white),
                  const SizedBox(width: 4),
                  Text('${car.images.length}',
                      style: const TextStyle(fontSize: 12, color: Colors.white)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _thumbnails(CarAd car) {
    return SizedBox(
      height: 80,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
        itemCount: car.images.length,
        itemBuilder: (_, i) => GestureDetector(
          onTap: () => _pager.jumpToPage(i),
          child: Container(
            width: 96,
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                  color: i == _page ? AppColors.accent : Colors.transparent, width: 2),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              // CarThumbnailAdapter: car_placeholder while loading.
              child: AppNetworkImage(car.images[i], fit: BoxFit.cover),
            ),
          ),
        ),
      ),
    );
  }

  Widget _circleButton(IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      customBorder: const CircleBorder(),
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: const BoxDecoration(color: Color(0xFFF8F9FA), shape: BoxShape.circle),
        child: Icon(icon, size: 20, color: color),
      ),
    );
  }

  Widget _title(CarAd car, String? variant) {
    Widget spec(IconData icon, String text) => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: _secondary),
            const SizedBox(width: 4),
            Text(text, style: const TextStyle(fontSize: 14, color: _secondary)),
          ],
        );
    Widget sep() => Container(
        width: 1, height: 12, margin: const EdgeInsets.symmetric(horizontal: 8), color: _border);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${car.make} ${car.model} ${variant ?? ''}'.trim(),
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w700, color: _primary)),
                Text('${car.transmission} ${car.fuelType} ${car.year}',
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w700, color: _primary)),
                const SizedBox(height: 12),
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    spec(Icons.local_gas_station_outlined, car.fuelType),
                    sep(),
                    spec(Icons.settings_outlined, car.transmission),
                    sep(),
                    spec(Icons.calendar_today_outlined, '${car.year}'),
                  ],
                ),
              ],
            ),
          ),
          _circleButton(_isFavorite ? Icons.favorite : Icons.favorite_border,
              _isFavorite ? Colors.red : _primary, _toggleFavorite),
          const SizedBox(width: 8),
          _circleButton(Icons.share_outlined, _primary, () => _share(car)),
        ],
      ),
    );
  }

  Widget _price(CarAd car) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('₹ ${car.price}',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: _primary)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFECFDF5),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.bar_chart, size: 14, color: Color(0xFF10B981)),
                SizedBox(width: 4),
                Text('Great price • ₹3,25,000 below average',
                    style: TextStyle(fontSize: 11, color: Color(0xFF10B981))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _card({required String title, required Widget child}) {
    return Card(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      color: Colors.white,
      surfaceTintColor: Colors.white,
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (title.isNotEmpty) ...[
              Text(title,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w700, color: _primary)),
              const SizedBox(height: 20),
            ],
            child,
          ],
        ),
      ),
    );
  }

  Widget _highlights(CarAd car) {
    Widget item(IconData icon, String label, String value) => Expanded(
          child: Column(
            children: [
              Icon(icon, size: 24, color: _primary),
              const SizedBox(height: 8),
              Text(label, style: const TextStyle(fontSize: 11, color: _secondary)),
              const SizedBox(height: 2),
              Text(value.isEmpty ? '-' : value,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w600, color: _primary)),
            ],
          ),
        );
    return _card(
      title: 'Key Highlights',
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          item(Icons.settings_outlined, 'Transmission', car.transmission),
          item(Icons.speed, 'Driven', car.kmDriven),
          item(Icons.event_seat_outlined, 'Seating',
              car.seatingCapacity.isEmpty ? '' : '${car.seatingCapacity} Seats'),
          item(Icons.person_outline, 'Ownership', car.ownerType),
        ],
      ),
    );
  }

  Widget _emiCard(CarAd car) {
    return _card(
      title: '',
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration:
                    const BoxDecoration(color: Color(0xFFF8F9FA), shape: BoxShape.circle),
                child: const Icon(Icons.calculate_outlined, color: AppColors.accent),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('EMI starting from',
                        style: TextStyle(fontSize: 12, color: _secondary)),
                    const SizedBox(height: 2),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(emiFor(car.priceValue),
                            style: const TextStyle(
                                fontSize: 18, fontWeight: FontWeight.w700, color: _primary)),
                        const SizedBox(width: 4),
                        const Text('/month', style: TextStyle(fontSize: 12, color: _secondary)),
                      ],
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () => _showEmiCalculator(car),
                child: const Text('Calculate >',
                    style: TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.accent)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.check_circle, size: 14, color: Color(0xFF10B981)),
              SizedBox(width: 6),
              Text('100% Secure • No Impact on CIBIL',
                  style: TextStyle(fontSize: 11, color: _secondary)),
            ],
          ),
        ],
      ),
    );
  }

  /// Simple EMI calculator (down payment, rate, tenure), same formula as Android calculateEMI.
  void _showEmiCalculator(CarAd car) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _EmiSheet(price: car.priceValue, carName: '${car.make} ${car.model}'),
    );
  }

  Widget _health(CarAd car) {
    String v(String? s) => (s == null || s.trim().isEmpty) ? 'NO' : s;
    Widget item(IconData icon, String label, String value, Color tint, Color bg) => Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
              child: Icon(icon, size: 18, color: tint),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: const TextStyle(fontSize: 11, color: _secondary)),
                  Text(value,
                      style: const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w600, color: _primary)),
                ],
              ),
            ),
          ],
        );
    final items = [
      item(Icons.description_outlined, 'Insurance', v(car.insurance), const Color(0xFF2563EB),
          const Color(0xFFEFF6FF)),
      item(Icons.app_registration, 'Registration', v(car.registration), const Color(0xFF059669),
          const Color(0xFFECFDF5)),
      item(Icons.assured_workload, 'PUC Certificate', v(car.puc), const Color(0xFF7C3AED),
          const Color(0xFFF5F3FF)),
      item(Icons.battery_unknown, 'Battery', v(car.battery), const Color(0xFF16A34A),
          const Color(0xFFF0FDF4)),
      item(Icons.tire_repair, 'Tyre condition', v(car.tyre), const Color(0xFF7C3AED),
          const Color(0xFFF5F3FF)),
      item(Icons.security, 'Brakes', v(car.brakes), const Color(0xFFD97706),
          const Color(0xFFFFFBEB)),
      item(Icons.build_circle_outlined, 'Service history', v(car.service),
          const Color(0xFF2563EB), const Color(0xFFEFF6FF)),
      item(Icons.attach_money, 'Loan Clearance', v(car.loan), const Color(0xFFDB2777),
          const Color(0xFFFDF2F8)),
    ];
    return _card(
      title: 'Health & Certifications',
      child: Column(
        children: [
          for (int i = 0; i < items.length; i += 2)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Row(children: [Expanded(child: items[i]), Expanded(child: items[i + 1])]),
            ),
          item(Icons.policy_outlined, 'No Challan Pending', v(car.challan),
              const Color(0xFF0891B2), const Color(0xFFECFEFF)),
        ],
      ),
    );
  }

  Widget _sellerCard(CarAd car) {
    return _card(
      title: 'Seller Contact Details',
      child: Row(
        children: [
          _Avatar(name: car.ownerName),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(car.ownerName,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w700, color: _primary)),
                const SizedBox(height: 4),
                Text(car.phoneNumber, style: const TextStyle(fontSize: 14, color: _secondary)),
              ],
            ),
          ),
          InkWell(
            customBorder: const CircleBorder(),
            onTap: () => _openWhatsApp(car),
            child: Container(
              width: 44,
              height: 44,
              decoration: const BoxDecoration(color: Color(0xFFDCFCE7), shape: BoxShape.circle),
              child: const Icon(Icons.chat, color: Color(0xFF16A34A)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _bottomBar(CarAd car, bool alreadyContacted) {
    return Container(
      color: Colors.white,
      padding: EdgeInsets.fromLTRB(12, 12, 12, 12 + MediaQuery.of(context).padding.bottom),
      child: SizedBox(
        width: double.infinity,
        height: 56,
        child: ElevatedButton(
          onPressed: alreadyContacted ? null : () => _contactSeller(car),
          style: ElevatedButton.styleFrom(
            backgroundColor: _navy,
            disabledBackgroundColor: const Color(0xFF9E9E9E),
            foregroundColor: Colors.white,
            disabledForegroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: Text(alreadyContacted ? 'Already contacted' : 'Contact Seller',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        ),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  final String name;
  final double size;

  const _Avatar({required this.name, this.size = 52});

  @override
  Widget build(BuildContext context) {
    final initials = name
        .split(' ')
        .where((p) => p.isNotEmpty)
        .take(2)
        .map((p) => p[0].toUpperCase())
        .join();
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: const BoxDecoration(color: Color(0xFFF0F9FF), shape: BoxShape.circle),
      child: Text(initials.isEmpty ? 'S' : initials,
          style: const TextStyle(
              fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF0284C7))),
    );
  }
}

/// Seller contact sheet shown after "Contact Seller" (Android bottom_sheet_seller_contact).
class _SellerSheet extends StatelessWidget {
  final String name;
  final String number;
  final VoidCallback onWhatsApp;

  const _SellerSheet({required this.name, required this.number, required this.onWhatsApp});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text('Seller Details',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                ),
                IconButton(
                    onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _Avatar(name: name),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name.isEmpty ? 'N/A' : name,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 4),
                      Text(number.isEmpty ? 'N/A' : number,
                          style: const TextStyle(fontSize: 14, color: Color(0xFF757575))),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Copy',
                  icon: const Icon(Icons.copy, color: AppColors.accent),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: number));
                    ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Number copied to clipboard')));
                  },
                ),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: onWhatsApp,
                icon: const Icon(Icons.chat),
                label: const Text('Chat on WhatsApp',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF16A34A),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmiSheet extends StatefulWidget {
  final double price;
  final String carName;

  const _EmiSheet({required this.price, required this.carName});

  @override
  State<_EmiSheet> createState() => _EmiSheetState();
}

class _EmiSheetState extends State<_EmiSheet> {
  double _downPct = 20;
  double _rate = 9.5;
  int _years = 5;

  @override
  Widget build(BuildContext context) {
    final principal = widget.price * (1 - _downPct / 100);
    final r = _rate / 12 / 100;
    final n = _years * 12;
    double pow = 1;
    for (int i = 0; i < n; i++) {
      pow *= 1 + r;
    }
    final emi = principal <= 0 ? 0 : (pow <= 1 ? principal / n : principal * r * pow / (pow - 1));
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('EMI for ${widget.carName}',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),
            Text('₹${groupThousands(emi.round())} /month',
                style: const TextStyle(
                    fontSize: 24, fontWeight: FontWeight.w700, color: AppColors.accent)),
            const SizedBox(height: 16),
            Text('Down payment: ${_downPct.round()}%'),
            Slider(
                value: _downPct,
                min: 0,
                max: 90,
                divisions: 18,
                onChanged: (v) => setState(() => _downPct = v)),
            Text('Interest rate: ${_rate.toStringAsFixed(1)}%'),
            Slider(
                value: _rate,
                min: 7,
                max: 18,
                divisions: 22,
                onChanged: (v) => setState(() => _rate = v)),
            Text('Tenure: $_years years'),
            Slider(
                value: _years.toDouble(),
                min: 1,
                max: 7,
                divisions: 6,
                onChanged: (v) => setState(() => _years = v.round())),
          ],
        ),
      ),
    );
  }
}
