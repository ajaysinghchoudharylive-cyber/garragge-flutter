import 'package:carsbuzz/cardetails/car_details_screen.dart';
import 'package:carsbuzz/carlisting/car_ad.dart';
import 'package:carsbuzz/carlisting/car_api.dart';
import 'package:carsbuzz/carlisting/car_listing_filters.dart';
import 'package:carsbuzz/favorites/favorites_screen.dart';
import 'package:carsbuzz/home/city_selection_sheet.dart';
import 'package:carsbuzz/sellcar/models/sell_car_models.dart';
import 'package:carsbuzz/theme/app_colors.dart';
import 'package:carsbuzz/widgets/app_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Buy listing, a port of the Android FragmentCarListing + CarListPagingAdapter
/// (item_car_listing_v2.xml). Loads GET cars/filter page by page with the same conditions as
/// Android (see [CarApi.search]).
class CarListingScreen extends StatefulWidget {
  final String? initialBrand;
  final String? initialModel;
  final bool isFromPopular;
  final String? initialFuelType;
  final String? initialTransmission;
  final String? initialMinPrice; // rupees, e.g. "500000"
  final String? initialMaxPrice;
  final String? initialBodyType; // label, e.g. "SUV"
  /// Opened from a home brand/model search: location is not applied (Android isFromSearch).
  final bool isFromSearch;

  /// Back arrow action when this is the root of the Buy tab (nothing to pop). Android's iv_back
  /// pops back to the previous destination, which is the dashboard.
  final VoidCallback? onBack;

  const CarListingScreen({
    super.key,
    this.initialBrand,
    this.initialModel,
    this.isFromPopular = false,
    this.initialFuelType,
    this.initialTransmission,
    this.initialMinPrice,
    this.initialMaxPrice,
    this.initialBodyType,
    this.isFromSearch = false,
    this.onBack,
  });

  @override
  State<CarListingScreen> createState() => _CarListingScreenState();
}

class _CarListingScreenState extends State<CarListingScreen> {
  static const _purple = Color(0xFF4A148C);
  static const _grey = Color(0xFF757575);

  final ScrollController _scroll = ScrollController();
  late CarSearch _search;
  final List<CarAd> _cars = [];
  Set<int> _favorites = {};
  int _page = 0;
  int _total = 0;
  bool _loading = true;
  bool _loadingMore = false;
  bool _isLast = false;
  bool _error = false;
  int _requestId = 0;
  String _city = '';
  double? _lat;
  double? _lng;
  int _sort = 0; // 0 relevance, 1 price low-high, 2 price high-low, 3 km low-high

  @override
  void initState() {
    super.initState();
    _search = CarSearch(
      make: widget.initialBrand,
      model: widget.initialModel,
      fuelType: widget.initialFuelType,
      transmission: widget.initialTransmission,
      minPrice: widget.initialMinPrice,
      maxPrice: widget.initialMaxPrice,
      bodyType: bodyCodeForLabel(widget.initialBodyType),
      isFromSearch: widget.isFromSearch,
    );
    _scroll.addListener(() {
      if (_scroll.position.pixels > _scroll.position.maxScrollExtent - 400) _loadMore();
    });
    _reload();
    FavoritesStore.all().then((f) {
      if (mounted) setState(() => _favorites = f);
    });
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _reload() async {
    final prefs = await SharedPreferences.getInstance();
    _city = prefs.getString('city') ?? '';
    _lat = prefs.getDouble('latitude');
    _lng = prefs.getDouble('longitude');
    final id = ++_requestId;
    setState(() {
      _loading = true;
      _error = false;
      _cars.clear();
      _page = 0;
      _isLast = false;
    });
    try {
      final page = await CarApi.search(_search, 0);
      if (!mounted || id != _requestId) return;
      setState(() {
        _cars.addAll(page.cars);
        _total = page.total;
        _isLast = page.isLast;
        _loading = false;
      });
    } catch (e) {
      if (!mounted || id != _requestId) return;
      setState(() {
        _loading = false;
        _error = true;
      });
    }
  }

  Future<void> _loadMore() async {
    if (_loading || _loadingMore || _isLast || _error) return;
    final id = _requestId;
    setState(() => _loadingMore = true);
    try {
      final page = await CarApi.search(_search, _page + 1);
      if (!mounted || id != _requestId) return;
      setState(() {
        _page++;
        _cars.addAll(page.cars);
        _isLast = page.isLast;
        _loadingMore = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loadingMore = false);
    }
  }

  // ── Actions ─────────────────────────────────────────────────────────────────────────────────

  Future<void> _pickCity() async {
    final before = _city;
    await CitySelectionSheet.show(context);
    final prefs = await SharedPreferences.getInstance();
    // "Detect my location" keeps the sheet open, so reload whenever the city or coords changed.
    if (prefs.getString('city') != before ||
        prefs.getDouble('latitude') != _lat ||
        prefs.getDouble('longitude') != _lng) {
      _reload();
    }
  }

  void _openFilters() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => CarListingFilters(
        selectedBrand: _search.make,
        selectedFuelType: _search.fuelType,
        selectedTransmission: _search.transmission,
        minPrice: _search.minPrice,
        maxPrice: _search.maxPrice,
        onApply: (brand, fuel, transmission, min, max) {
          Navigator.pop(ctx);
          _search = CarSearch(
            make: brand,
            model: brand == _search.make ? _search.model : null,
            fuelType: fuel,
            transmission: transmission,
            minPrice: min,
            maxPrice: max,
            bodyType: _search.bodyType,
            sortBy: _search.sortBy,
            sortDirection: _search.sortDirection,
            isFromSearch: _search.isFromSearch,
          );
          _reload();
        },
      ),
    );
  }

  void _openSort() {
    const options = ['Relevance', 'Price: Low to High', 'Price: High to Low', 'Kilometers: Low to High'];
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('Sort by',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            ),
            for (int i = 0; i < options.length; i++)
              RadioListTile<int>(
                value: i,
                groupValue: _sort,
                activeColor: AppColors.accent,
                title: Text(options[i]),
                onChanged: (v) {
                  Navigator.pop(ctx);
                  _sort = v ?? 0;
                  // Android: 1 price/asc, 2 price/desc, 3 km/asc, else default (desc).
                  final (by, dir) = switch (_sort) {
                    1 => ('price', 'asc'),
                    2 => ('price', 'desc'),
                    3 => ('km', 'asc'),
                    _ => (null, 'desc'),
                  };
                  _search = by == null
                      ? _search.copyWith(clearSort: true)
                      : _search.copyWith(sortBy: by, sortDirection: dir);
                  _reload();
                },
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _toggleFavorite(int id) async {
    final added = await FavoritesStore.toggle(id);
    if (!mounted) return;
    setState(() => added ? _favorites.add(id) : _favorites.remove(id));
  }

  void _openDetails(CarAd car) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => CarDetailsScreen(carId: car.id)));
  }

  // ── UI ─────────────────────────────────────────────────────────────────────────────────────

  List<(String, VoidCallback)> get _chips {
    final s = _search;
    return [
      if ((s.make ?? '').isNotEmpty)
        (s.make!, () => _search = s.copyWith(clearMake: true, clearModel: true)),
      if ((s.model ?? '').isNotEmpty) (s.model!, () => _search = s.copyWith(clearModel: true)),
      if ((s.fuelType ?? '').isNotEmpty) (s.fuelType!, () => _search = s.copyWith(clearFuel: true)),
      if ((s.transmission ?? '').isNotEmpty)
        (s.transmission!, () => _search = s.copyWith(clearTransmission: true)),
      if (s.bodyType != null && s.bodyType! < kBodyTypeLabels.length)
        (kBodyTypeLabels[s.bodyType!], () => _search = s.copyWith(clearBody: true)),
      if ((s.minPrice ?? '').isNotEmpty && (s.maxPrice ?? '').isNotEmpty)
        (
          '₹${groupThousands(int.tryParse(s.minPrice!) ?? 0)} - ₹${groupThousands(int.tryParse(s.maxPrice!) ?? 0)}',
          () => _search = s.copyWith(clearPrice: true)
        ),
    ];
  }

  void _onBackTap() {
    final nav = Navigator.of(context);
    if (nav.canPop()) {
      nav.pop();
    } else {
      widget.onBack?.call();
    }
  }

  Future<void> _openWishlist() async {
    await Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => const FavoritesScreen()));
    final favs = await FavoritesStore.all();
    if (mounted) setState(() => _favorites = favs);
  }

  @override
  Widget build(BuildContext context) {
    final chips = _chips;
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SafeArea(
        child: Column(
          children: [
            _header(),
            _filterCategories(chips.length),
            if (chips.isNotEmpty)
              Container(
                color: Colors.white,
                height: 44,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  children: [
                    for (final (label, clear) in chips)
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: InputChip(
                          label: Text(label, style: const TextStyle(fontSize: 12)),
                          onDeleted: () {
                            clear();
                            _reload();
                          },
                          backgroundColor: const Color(0xFFEFF6FF),
                          side: BorderSide.none,
                        ),
                      ),
                  ],
                ),
              ),
            if (!_loading && !_error)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    _city.isNotEmpty && !_search.isFromSearch
                        ? '$_total cars in $_city and nearby'
                        : '$_total cars found',
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            Expanded(child: _body()),
          ],
        ),
      ),
    );
  }

  static Widget _svg(String name, {Color? tint, double? size}) => SvgPicture.asset(
        'assets/icons/$name.svg',
        width: size,
        height: size,
        fit: BoxFit.contain,
        colorFilter: tint == null ? null : ColorFilter.mode(tint, BlendMode.srcIn),
      );

  /// 40dp touch target with a 10dp-padded black icon (iv_search / iv_wishlist_top).
  Widget _headerIcon(String icon, VoidCallback onTap) {
    return InkResponse(
      onTap: onTap,
      radius: 22,
      child: SizedBox(
        width: 40,
        height: 40,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: _svg(icon, tint: Colors.black),
        ),
      ),
    );
  }

  /// fragment_car_listing.xml layout_header (?attr/actionBarSize = 56dp):
  /// round back button, "Buy Car", location chip, search, wishlist.
  Widget _header() {
    final place = _city.isNotEmpty ? _city : 'Select City';
    return Container(
      color: Colors.white,
      height: 56,
      child: Row(
        children: [
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _onBackTap,
            child: Container(
              width: 40,
              height: 40,
              padding: const EdgeInsets.all(10),
              decoration:
                  const BoxDecoration(color: Color(0xFFF3F4F6), shape: BoxShape.circle),
              child: _svg('back_orange', tint: Colors.black),
            ),
          ),
          const SizedBox(width: 8),
          const Text('Buy Car', style: TextStyle(fontSize: 16, color: Colors.black)),
          const Spacer(),
          // bg_location_chip: white, radius 20, 1dp #F44336 stroke.
          GestureDetector(
            onTap: _pickCity,
            child: Container(
              constraints: const BoxConstraints(maxWidth: 140),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFF44336)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Text(place,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w500, color: _purple)),
                  ),
                  const SizedBox(width: 4),
                  _svg('ic_drop_down', tint: _purple, size: 12),
                ],
              ),
            ),
          ),
          const SizedBox(width: 16),
          // Android: the search icon opens the filter/refine screen.
          _headerIcon('ic_search', _openFilters),
          const SizedBox(width: 4),
          _headerIcon('heart_gray', _openWishlist),
          const SizedBox(width: 8),
        ],
      ),
    );
  }

  /// rv_filter_categories (BuyCarFilterCategoryAdapter): Filter (count badge), Sort,
  /// Price Range, Fuel Type. Price and fuel are edited in the same filter sheet.
  Widget _filterCategories(int activeCount) {
    return Container(
      color: Colors.white,
      height: 46,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: [
          _categoryChip('Filter', icon: 'ic_filter', count: activeCount, onTap: _openFilters),
          // Android passes R.drawable.ic_drop_down as Sort's icon too (untinted, before the text).
          _categoryChip('Sort', icon: 'ic_drop_down', onTap: _openSort),
          _categoryChip('Price Range', onTap: _openFilters),
          _categoryChip('Fuel Type', onTap: _openFilters),
        ],
      ),
    );
  }

  /// item_buy_car_filter_category.xml: radius 20, 1dp #E0E0E0 stroke, 12sp medium text,
  /// 10dp drop-down arrow.
  Widget _categoryChip(String name,
      {String? icon, int count = 0, required VoidCallback onTap}) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Material(
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Color(0xFFE0E0E0)),
        ),
        child: InkWell(
          onTap: onTap,
          customBorder:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (count > 0) ...[
                  Container(
                    width: 16,
                    height: 16,
                    alignment: Alignment.center,
                    // bg_circle_red.xml (the colour really is #BCA4FF).
                    decoration: const BoxDecoration(
                        color: Color(0xFFBCA4FF), shape: BoxShape.circle),
                    child: Text('$count',
                        style: const TextStyle(fontSize: 8, color: Colors.white)),
                  ),
                  const SizedBox(width: 4),
                ],
                if (icon != null) ...[
                  _svg(icon, size: 14),
                  const SizedBox(width: 4),
                ],
                Text(name,
                    style: const TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w500, color: Colors.black)),
                const SizedBox(width: 4),
                _svg('ic_drop_down', tint: Colors.black, size: 10),
              ],
            ),
          ),
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
            const Text('Could not load cars', style: TextStyle(color: _grey)),
            TextButton(onPressed: _reload, child: const Text('Retry')),
          ],
        ),
      );
    }
    if (_cars.isEmpty) {
      return RefreshIndicator(
        onRefresh: _reload,
        child: ListView(
          children: const [
            SizedBox(height: 120),
            Icon(Icons.directions_car_outlined, size: 64, color: Colors.black26),
            SizedBox(height: 12),
            Center(child: Text('No cars found', style: TextStyle(fontSize: 16, color: _grey))),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _reload,
      child: ListView.builder(
        controller: _scroll,
        padding: const EdgeInsets.only(bottom: 16),
        itemCount: _cars.length + (_loadingMore ? 1 : 0),
        itemBuilder: (_, i) {
          if (i >= _cars.length) {
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          return _card(_cars[i]);
        },
      ),
    );
  }

  Widget _card(CarAd car) {
    final fav = _favorites.contains(car.id);
    final dist = distanceKm(_lat, _lng, car.latitude, car.longitude);
    final stateCode = car.state.isEmpty
        ? 'KA04'
        : car.state.substring(0, car.state.length < 4 ? car.state.length : 4).toUpperCase();
    final specs = ['${car.kmDriven} Km', car.fuelType, car.transmission, stateCode]
        .where((s) => s.trim().isNotEmpty)
        .join(' • ');
    const titleStyle = TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: _purple);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      elevation: 2,
      color: Colors.white,
      surfaceTintColor: Colors.white,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () => _openDetails(car),
        child: Padding(
          padding: const EdgeInsets.only(bottom: 12),
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
                        onTap: () => _toggleFavorite(car.id),
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: const BoxDecoration(
                              color: Colors.white, shape: BoxShape.circle),
                          child: Icon(fav ? Icons.favorite : Icons.favorite_border,
                              size: 22, color: fav ? Colors.red : Colors.grey),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${car.year} ${car.make} ${car.model}', style: titleStyle),
                          Text(car.bodyLabel,
                              style: const TextStyle(fontSize: 12, color: _grey)),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('₹${car.price}', style: titleStyle),
                        Container(
                          color: const Color(0xFFE8F5E9),
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          child: Text(saveFor(car.priceValue),
                              style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFF4CAF50))),
                        ),
                        const SizedBox(height: 4),
                        Text('EMI ${emiFor(car.priceValue)}',
                            style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF00ACC1))),
                      ],
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: Text(specs, style: const TextStyle(fontSize: 13, color: _grey)),
              ),
              Container(
                height: 1,
                margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                color: const Color(0xFFF5F5F5),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: Row(
                  children: [
                    const Icon(Icons.location_on_outlined, size: 14, color: _grey),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        [car.city, car.state].where((s) => s.isNotEmpty).join(', '),
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 11, color: _grey),
                      ),
                    ),
                    if (dist != null) ...[
                      const SizedBox(width: 6),
                      Text('• ${dist.round()} km away from you',
                          style: const TextStyle(
                              fontSize: 11, fontWeight: FontWeight.w500, color: _purple)),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Car photo over a dimmed, cropped copy of itself (Android iv_car_image_bg + iv_car_image).
class CarPhoto extends StatelessWidget {
  final String? url;
  final BoxFit fit;

  const CarPhoto({super.key, required this.url, this.fit = BoxFit.contain});

  @override
  Widget build(BuildContext context) {
    final u = url;
    // Android: Glide .placeholder(R.drawable.car_placeholder) while loading / without a URL.
    if (u == null || u.isEmpty) return const CarPlaceholder();
    return Stack(
      fit: StackFit.expand,
      children: [
        Container(
          color: Colors.black,
          child: Opacity(
            opacity: 0.4,
            child: Image.network(u, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const SizedBox()),
          ),
        ),
        // Covers the black backdrop with the white placeholder until the photo arrives.
        AppNetworkImage(u, fit: fit),
      ],
    );
  }
}
