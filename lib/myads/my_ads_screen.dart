import 'package:carsbuzz/cardetails/car_details_screen.dart';
import 'package:carsbuzz/carlisting/car_ad.dart';
import 'package:carsbuzz/carlisting/car_api.dart';
import 'package:carsbuzz/carlisting/car_listing_screen.dart' show CarPhoto;
import 'package:carsbuzz/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// "My Ads", a port of the Android MyCarAdsFragment + MyCarsAdapter (item_my_car_ad_v2.xml).
/// Data: GET cars/getCarAdsByUser?userId=.
class MyAdsScreen extends StatefulWidget {
  const MyAdsScreen({super.key});

  @override
  State<MyAdsScreen> createState() => _MyAdsScreenState();
}

class _MyAdsScreenState extends State<MyAdsScreen> {
  static const _green = Color(0xFF059669);
  static const _grey = Color(0xFF757575);

  List<CarAd> _ads = [];
  bool _loading = true;
  bool _error = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = false;
    });
    try {
      final ads = await CarApi.myAds();
      if (!mounted) return;
      setState(() {
        _ads = ads;
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

  void _toast(String text) => ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(text)));

  Future<void> _editPrice(CarAd ad) async {
    final newPrice = await showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _EditPriceSheet(ad: ad),
    );
    if (newPrice == null) return;
    try {
      await CarApi.updatePrice(ad.id, newPrice);
      _toast('Price updated');
      _load();
    } catch (_) {
      _toast('Could not update the price. Please try again.');
    }
  }

  Future<void> _delete(CarAd ad) async {
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _DeleteSheet(ad: ad),
    );
    if (confirmed != true) return;
    try {
      final message = await CarApi.deleteAd(ad.id);
      if (!mounted) return;
      setState(() => _ads.removeWhere((a) => a.id == ad.id));
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          content: Text(message),
          actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK'))],
        ),
      );
    } catch (_) {
      _toast('Could not delete the ad. Please try again.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(4, 8, 16, 12),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.black),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('My Ads',
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.w700, color: Colors.black)),
                        Text('All your car ads and their performance',
                            style: TextStyle(fontSize: 13, color: _grey)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(child: _body()),
          ],
        ),
      ),
    );
  }

  Widget _body() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Could not load your ads', style: TextStyle(color: _grey)),
            TextButton(onPressed: _load, child: const Text('Retry')),
          ],
        ),
      );
    }
    if (_ads.isEmpty) {
      return RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          children: const [
            SizedBox(height: 120),
            Icon(Icons.directions_car_outlined, size: 64, color: Colors.black26),
            SizedBox(height: 12),
            Center(
              child: Text('No ads yet',
                  style: TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w500, color: Colors.black)),
            ),
            SizedBox(height: 4),
            Center(
              child: Text('Cars you post will appear here.',
                  style: TextStyle(fontSize: 13, color: _grey)),
            ),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.builder(
        padding: const EdgeInsets.only(bottom: 16),
        itemCount: _ads.length,
        itemBuilder: (_, i) => _card(_ads[i]),
      ),
    );
  }

  (String, Color, Color) _status(int v) => switch (v) {
        0 => ('Pending', const Color(0xFF4169E1), const Color(0xFFEBF5FF)),
        2 => ('Needs improvement', const Color(0xFFB45309), const Color(0xFFFEF3C7)),
        3 => ('Rejected', const Color(0xFFDC2626), const Color(0xFFFEE2E2)),
        _ => ('Active', _green, const Color(0xFFD1FAE5)),
      };

  Widget _card(CarAd ad) {
    final (label, color, bg) = _status(ad.isVerified);
    final showReview = (ad.isVerified == 2 || ad.isVerified == 3) && ad.statusMessage.trim().isNotEmpty;
    final rejected = ad.isVerified == 3;
    final performance = ad.leadCount > 100 ? 'Top' : (ad.leadCount > 50 ? 'Good' : 'Average');

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      color: Colors.white,
      surfaceTintColor: Colors.white,
      elevation: 2,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: InkWell(
        onTap: () => Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => CarDetailsScreen(carId: ad.id, isFromMyAds: true),
        )),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 180,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CarPhoto(url: ad.firstImage),
                  Positioned(
                    top: 10,
                    left: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
                      child: Row(
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                          ),
                          const SizedBox(width: 6),
                          Text(label,
                              style: TextStyle(
                                  fontSize: 10, fontWeight: FontWeight.w700, color: color)),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    top: 10,
                    right: 10,
                    child: PopupMenuButton<String>(
                      onSelected: (v) => v == 'edit' ? _editPrice(ad) : _delete(ad),
                      itemBuilder: (_) => const [
                        PopupMenuItem(value: 'edit', child: Text('Edit Price')),
                        PopupMenuItem(value: 'delete', child: Text('Delete ad')),
                      ],
                      child: Container(
                        width: 30,
                        height: 30,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 2)],
                        ),
                        child: const Icon(Icons.more_vert, size: 18, color: Colors.black),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('${ad.make} ${ad.model}'.trim(),
                                style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.black)),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                const Icon(Icons.location_on, size: 10, color: _green),
                                const SizedBox(width: 4),
                                Text(ad.city, style: const TextStyle(fontSize: 11, color: _grey)),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text('₹${ad.price}',
                              style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF10B981))),
                          const Text('onwards', style: TextStyle(fontSize: 10, color: _grey)),
                        ],
                      ),
                    ],
                  ),
                  if (showReview)
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(top: 10),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: rejected ? const Color(0xFFFEE2E2) : const Color(0xFFFEF3C7),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(rejected ? 'Why it was rejected' : 'What needs to be improved',
                              style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: rejected
                                      ? const Color(0xFFDC2626)
                                      : const Color(0xFFB45309))),
                          const SizedBox(height: 2),
                          Text(ad.statusMessage,
                              style: const TextStyle(fontSize: 12, color: Colors.black)),
                        ],
                      ),
                    ),
                  Container(
                      height: 1,
                      margin: const EdgeInsets.only(top: 10),
                      color: const Color(0xFFF3F4F6)),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      _metric(Icons.visibility_outlined, groupThousands(ad.viewCount), 'Views',
                          Colors.black),
                      const SizedBox(width: 4),
                      _metric(Icons.person_outline, '${ad.leadCount}', 'Leads', _green),
                      const SizedBox(width: 4),
                      _metric(Icons.bar_chart, performance, 'Performance', _green),
                    ],
                  ),
                ],
              ),
            ),
            Container(
              color: const Color(0xFFF9FAFB),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: const Row(
                children: [
                  Icon(Icons.storefront_outlined, size: 16, color: _green),
                  SizedBox(width: 6),
                  Expanded(
                    child: Text('Dealer • Garragge.com',
                        style:
                            TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: _green)),
                  ),
                  Icon(Icons.arrow_forward, size: 12, color: _green),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _metric(IconData icon, String value, String label, Color tint) {
    return Expanded(
      child: Container(
        color: const Color(0xFFF8FAFC),
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          children: [
            Icon(icon, size: 16, color: tint),
            const SizedBox(height: 2),
            Text(value,
                style: const TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w700, color: Colors.black)),
            Text(label, style: const TextStyle(fontSize: 9, color: _grey)),
          ],
        ),
      ),
    );
  }
}

/// "Edit Price Ad" sheet. Pops with the new price in rupees.
class _EditPriceSheet extends StatefulWidget {
  final CarAd ad;
  const _EditPriceSheet({required this.ad});

  @override
  State<_EditPriceSheet> createState() => _EditPriceSheetState();
}

class _EditPriceSheetState extends State<_EditPriceSheet> {
  late final TextEditingController _controller =
      TextEditingController(text: _indian(widget.ad.priceValue.round()));
  String? _error;

  static String _indian(int v) {
    final s = v.toString();
    if (s.length <= 3) return s;
    final last3 = s.substring(s.length - 3);
    var rest = s.substring(0, s.length - 3);
    final parts = <String>[];
    while (rest.length > 2) {
      parts.insert(0, rest.substring(rest.length - 2));
      rest = rest.substring(0, rest.length - 2);
    }
    if (rest.isNotEmpty) parts.insert(0, rest);
    return '${parts.join(',')},$last3';
  }

  void _save() {
    final value = int.tryParse(_controller.text.replaceAll(',', ''));
    String? error;
    if (value == null || value <= 0) {
      error = 'Please enter a valid price';
    } else if (value < 10000) {
      error = 'Price must be at least ₹10,000';
    } else if (value > 100000000) {
      error = "Price can't exceed ₹10,00,00,000";
    }
    setState(() => _error = error);
    if (error == null) Navigator.of(context).pop(value);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(24, 20, 24, 24 + MediaQuery.of(context).viewInsets.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text('Edit Price Ad',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
              ),
              IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
            ],
          ),
          const Text('Update the price for your ad',
              style: TextStyle(fontSize: 13, color: Color(0xFF757575))),
          const SizedBox(height: 16),
          Text('₹ ${widget.ad.price} onwards',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          TextField(
            controller: _controller,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(10),
              TextInputFormatter.withFunction((oldV, newV) {
                if (newV.text.isEmpty) return newV;
                final t = _indian(int.parse(newV.text));
                return TextEditingValue(text: t, selection: TextSelection.collapsed(offset: t.length));
              }),
            ],
            decoration: InputDecoration(
              prefixText: '₹ ',
              errorText: _error,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Update Price'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// "Delete Ad" sheet with a confirm checkbox. Pops true to delete.
class _DeleteSheet extends StatefulWidget {
  final CarAd ad;
  const _DeleteSheet({required this.ad});

  @override
  State<_DeleteSheet> createState() => _DeleteSheetState();
}

class _DeleteSheetState extends State<_DeleteSheet> {
  bool _confirm = false;

  @override
  Widget build(BuildContext context) {
    final ad = widget.ad;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text('Delete Ad',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                ),
                IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
              ],
            ),
            const Text('This action cannot be undone',
                style: TextStyle(fontSize: 13, color: Color(0xFF757575))),
            const SizedBox(height: 16),
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: SizedBox(width: 80, height: 60, child: CarPhoto(url: ad.firstImage)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${ad.make} ${ad.model}',
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                      Text('₹ ${ad.price}', style: const TextStyle(fontSize: 13)),
                      Text(ad.city,
                          style: const TextStyle(fontSize: 12, color: Color(0xFF757575))),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              value: _confirm,
              onChanged: (v) => setState(() => _confirm = v ?? false),
              title: const Text('I understand this ad will be permanently deleted',
                  style: TextStyle(fontSize: 13)),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _confirm ? () => Navigator.pop(context, true) : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFDC2626),
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Delete'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
