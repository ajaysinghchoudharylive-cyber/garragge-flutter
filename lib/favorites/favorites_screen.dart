import 'package:carsbuzz/cardetails/car_details_screen.dart';
import 'package:carsbuzz/carlisting/car_ad.dart';
import 'package:carsbuzz/carlisting/car_api.dart';
import 'package:carsbuzz/carlisting/car_listing_screen.dart' show CarPhoto;
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// "Wishlist", opened from the heart in the Buy header (Android FragmentFavorites,
/// fragment_layout_favorites.xml). Favourites are stored on the device by [FavoritesStore].
class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  static const _purple = Color(0xFF4A148C);
  static const _grey = Color(0xFF757575);

  List<CarAd> _cars = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final ids = await FavoritesStore.all();
    final results = await Future.wait(ids.map((id) async {
      try {
        return (await CarApi.details(id)).car;
      } catch (_) {
        return null; // sold / removed ads are skipped
      }
    }));
    if (!mounted) return;
    setState(() {
      _cars = results.whereType<CarAd>().toList();
      _loading = false;
    });
  }

  Future<void> _remove(CarAd car) async {
    await FavoritesStore.toggle(car.id);
    if (mounted) setState(() => _cars.removeWhere((c) => c.id == car.id));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              color: Colors.white,
              height: 56,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      width: 40,
                      height: 40,
                      padding: const EdgeInsets.all(10),
                      decoration: const BoxDecoration(
                          color: Color(0xFFF3F4F6), shape: BoxShape.circle),
                      child: SvgPicture.asset('assets/icons/back_orange.svg',
                          colorFilter: const ColorFilter.mode(Colors.black, BlendMode.srcIn)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Wishlist',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                        if (!_loading)
                          Text('${_cars.length} cars saved',
                              style: const TextStyle(fontSize: 12, color: _grey)),
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
    if (_cars.isEmpty) {
      return const Center(
        child: Text('No cars in your wishlist', style: TextStyle(fontSize: 16, color: _grey)),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: _cars.length,
      itemBuilder: (_, i) => _card(_cars[i]),
    );
  }

  Widget _card(CarAd car) {
    const titleStyle = TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: _purple);
    final specs = ['${car.kmDriven} Km', car.fuelType, car.transmission]
        .where((s) => s.trim().isNotEmpty)
        .join(' • ');
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      elevation: 2,
      color: Colors.white,
      surfaceTintColor: Colors.white,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () async {
          await Navigator.of(context)
              .push(MaterialPageRoute(builder: (_) => CarDetailsScreen(carId: car.id)));
          // The heart may have been toggled on the details screen.
          final ids = await FavoritesStore.all();
          if (mounted) setState(() => _cars.removeWhere((c) => !ids.contains(c.id)));
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 200,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CarPhoto(url: car.firstImage),
                  Positioned(
                    top: 12,
                    right: 12,
                    child: GestureDetector(
                      onTap: () => _remove(car),
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration:
                            const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                        child: const Icon(Icons.favorite, size: 22, color: Colors.red),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                          child: Text('${car.year} ${car.make} ${car.model}', style: titleStyle)),
                      Text('₹${car.price}', style: titleStyle),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(specs, style: const TextStyle(fontSize: 13, color: _grey)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
