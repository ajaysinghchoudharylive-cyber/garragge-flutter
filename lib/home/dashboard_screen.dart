import 'dart:async';

import 'package:carsbuzz/carlisting/car_api.dart';
import 'package:carsbuzz/carlisting/car_listing_screen.dart';
import 'package:carsbuzz/home/city_selection_sheet.dart';
import 'package:carsbuzz/home/dashboard_repository.dart';
import 'package:carsbuzz/notifications/notifications_screen.dart';
import 'package:carsbuzz/home/widgets/find_cars_card.dart';
import 'package:carsbuzz/models/car_brand_model.dart';
import 'package:carsbuzz/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

/// Home "Dashboard" tab, a port of the Android HomeSellCarFragment + HomeSellCarAdapter.
/// Sections, in the same order as Android: top banner carousel, Brands, Find The Cars Of Your
/// Choice, Popular Cars, Latest Car News, bottom banner.
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  static const _searchHints = [
    'Search "Nexon"',
    'Search "Creta"',
    'Search "Swift"',
    'Search "Scorpio"',
  ];

  String _area = '';
  bool _loggedIn = false;
  int _unread = 0;
  int _hintIndex = 0;
  Timer? _hintTimer;

  List<DashboardBanner> _topBanners = [];
  List<DashboardBanner> _bottomBanners = [];
  List<CarBrandModel> _brands = [];
  List<BrandModelPair> _suggestions = [];
  List<PopularModel> _popular = [];
  List<NewsItem> _news = [];
  bool _showAllBrands = false;
  int _newsCategory = 0;

  @override
  void initState() {
    super.initState();
    _hintTimer = Timer.periodic(const Duration(milliseconds: 2500), (_) {
      if (mounted) setState(() => _hintIndex = (_hintIndex + 1) % _searchHints.length);
    });
    _loadArea();
    _loadUnread();
    _load();
  }

  @override
  void dispose() {
    _hintTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadArea() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      // The city sheet saves the picked city in 'city' (Android getCity()).
      _area = prefs.getString('city') ?? '';
    });
  }

  Future<void> _load() async {
    final results = await Future.wait([
      DashboardRepository.getBanners(placeBottom: false),
      DashboardRepository.getBanners(placeBottom: true),
      DashboardRepository.getBrands(),
      DashboardRepository.getSearchSuggestions(),
      DashboardRepository.getPopularModels(),
      DashboardRepository.getNews(),
    ]);
    if (!mounted) return;
    setState(() {
      _topBanners = results[0] as List<DashboardBanner>;
      _bottomBanners = results[1] as List<DashboardBanner>;
      _brands = results[2] as List<CarBrandModel>;
      _suggestions = results[3] as List<BrandModelPair>;
      _popular = results[4] as List<PopularModel>;
      _news = results[5] as List<NewsItem>;
      _newsCategory = 0;
    });
  }

  // ── Navigation ──────────────────────────────────────────────────────────────────────────────

  void _openListing({
    String? brand,
    String? model,
    String? fuel,
    String? transmission,
    String? minPrice,
    String? maxPrice,
    String? bodyType,
    bool isFromSearch = false,
  }) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => CarListingScreen(
        initialBrand: brand,
        initialModel: model,
        initialFuelType: fuel,
        initialTransmission: transmission,
        initialMinPrice: minPrice,
        initialMaxPrice: maxPrice,
        initialBodyType: bodyType,
        isFromSearch: isFromSearch,
      ),
    ));
  }

  /// Android HomeSellCarFragment.onAddLocationClick -> CitySelectionBottomSheet.
  Future<void> _onLocationTap() async {
    await CitySelectionSheet.show(context);
    _loadArea();
  }

  Future<void> _loadUnread() async {
    final prefs = await SharedPreferences.getInstance();
    final loggedIn = prefs.getBool('is_logged_in') ?? false;
    final count = loggedIn ? await CarApi.unreadCount() : 0;
    if (mounted) {
      setState(() {
        _loggedIn = loggedIn;
        _unread = count;
      });
    }
  }

  Future<void> _openNotifications() async {
    await Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => const NotificationsScreen()));
    _loadUnread();
  }

  Future<void> _onSearchTap() async {
    final picked = await Navigator.of(context).push<BrandModelPair>(
      MaterialPageRoute(builder: (_) => _SearchScreen(suggestions: _suggestions)),
    );
    if (picked != null && mounted) {
      _openListing(brand: picked.brand, model: picked.model, isFromSearch: true);
    }
  }

  Future<void> _openUrl(String url) =>
      launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);

  // ── UI ──────────────────────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFFBFCFF),
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: Container(
                color: AppColors.aliceBlue,
                child: RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    padding: const EdgeInsets.only(top: 12, bottom: 24),
                    children: [
                      if (_topBanners.isNotEmpty) _BannerCarousel(banners: _topBanners),
                      if (_brands.isNotEmpty) _buildBrands(),
                      FindCarsCard(
                        onExplore: (s) => _openListing(
                          fuel: s.fuelType,
                          transmission: s.transmission,
                          bodyType: s.bodyType,
                          minPrice: s.minPrice,
                          maxPrice: s.maxPrice,
                        ),
                      ),
                      if (_popular.isNotEmpty) _buildPopular(),
                      if (_news.isNotEmpty) _buildNews(),
                      if (_bottomBanners.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: Image.network(
                            _bottomBanners.first.imageUrl,
                            width: double.infinity,
                            fit: BoxFit.fitWidth,
                            errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// adapter_car_care_header.xml: location row, then the rounded search box with rotating hint.
  Widget _buildHeader() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(8, 12, 8, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: _onLocationTap,
            behavior: HitTestBehavior.opaque,
            child: Row(
              children: [
                const Icon(Icons.location_on_outlined, size: 18, color: Colors.black),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _area.isNotEmpty ? _area : 'Set your address',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Colors.black,
                    ),
                  ),
                ),
                // Bell + unread badge, only for logged-in users (Android ivBell).
                if (_loggedIn)
                  GestureDetector(
                    onTap: _openNotifications,
                    child: Padding(
                      padding: const EdgeInsets.only(left: 12, right: 16),
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          const Icon(Icons.notifications_none, size: 24, color: Colors.black),
                          if (_unread > 0)
                            Positioned(
                              top: -4,
                              right: -4,
                              child: Container(
                                width: 16,
                                height: 16,
                                alignment: Alignment.center,
                                decoration: const BoxDecoration(
                                    color: AppColors.badgeRed, shape: BoxShape.circle),
                                child: Text(
                                  _unread > 99 ? '9+' : '$_unread',
                                  style: const TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: _onSearchTap,
            child: Container(
              height: 40,
              margin: const EdgeInsets.only(right: 4),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFE0E0E0)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.search, size: 20, color: Color(0xFF8C8C8C)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 350),
                      transitionBuilder: (child, anim) => SlideTransition(
                        position: Tween(begin: const Offset(0, 0.6), end: Offset.zero)
                            .animate(anim),
                        child: FadeTransition(opacity: anim, child: child),
                      ),
                      child: Align(
                        key: ValueKey(_hintIndex),
                        alignment: Alignment.centerLeft,
                        child: Text(
                          _searchHints[_hintIndex],
                          style: const TextStyle(fontSize: 14, color: Color(0xFF8C8C8C)),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBrands() {
    final visible = _showAllBrands ? _brands : _brands.take(4).toList();
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Column(
        children: [
          Row(
            children: [
              const Expanded(
                child: Text('Brands',
                    style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.slate900)),
              ),
              if (_brands.length > 4)
                InkWell(
                  onTap: () => setState(() => _showAllBrands = !_showAllBrands),
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Text(
                      _showAllBrands ? 'Show less' : 'View All',
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.accent),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: EdgeInsets.zero,
            itemCount: visible.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              childAspectRatio: 0.95,
            ),
            itemBuilder: (context, i) {
              final brand = visible[i];
              return GestureDetector(
                onTap: () => _openListing(brand: brand.brandName),
                child: Card(
                  margin: const EdgeInsets.all(4),
                  color: Colors.white,
                  elevation: 3,
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
                              : Image.network(
                                  brand.brandLogo!,
                                  fit: BoxFit.contain,
                                  errorBuilder: (_, __, ___) =>
                                      const Icon(Icons.directions_car, color: Colors.black38),
                                ),
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

  Widget _buildPopular() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Popular Cars',
              style: TextStyle(fontSize: 16, color: Color(0xFF231F20))),
          Container(
            width: 100,
            height: 2,
            margin: const EdgeInsets.only(left: 24, top: 8),
            color: AppColors.brandBlue,
          ),
          const SizedBox(height: 8),
          // Two rows scrolling sideways, like the Android horizontal 2-span grid.
          SizedBox(
            height: 2 * 186,
            child: GridView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _popular.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisExtent: 176,
              ),
              itemBuilder: (context, i) {
                final m = _popular[i];
                return GestureDetector(
                  onTap: () =>
                      _openListing(brand: m.brand, model: m.modelName, isFromSearch: true),
                  child: Card(
                    margin: const EdgeInsets.all(8),
                    elevation: 2,
                    color: Colors.white,
                    clipBehavior: Clip.antiAlias,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.all(4),
                            child: Center(
                              child: m.imageUrl == null
                                  ? const Icon(Icons.directions_car,
                                      size: 48, color: Colors.black26)
                                  : Image.network(
                                      m.imageUrl!,
                                      fit: BoxFit.contain,
                                      errorBuilder: (_, __, ___) => const Icon(
                                          Icons.directions_car,
                                          size: 48,
                                          color: Colors.black26),
                                    ),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                          child: Text(m.modelName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF111111))),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(12, 2, 12, 12),
                          child: Text(m.brand,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 12, color: Color(0xFF757575))),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNews() {
    final categories =
        _newsCategories.where((c) => _news.any((n) => c.matches(n))).toList();
    final selected = _newsCategory < categories.length ? categories[_newsCategory] : null;
    final filtered = selected == null ? _news : _news.where(selected.matches).toList();
    final preview = filtered.take(4).toList();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('Latest Car News',
                  style: TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.slate900)),
              Container(
                margin: const EdgeInsets.only(left: 8),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFE6F4EA),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text('UPDATED DAILY',
                    style: TextStyle(
                        fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF0D9488))),
              ),
              const Spacer(),
              InkWell(
                onTap: () => _openUrl('${AppUrls.newsWebBase}/news'),
                child: const Padding(
                  padding: EdgeInsets.all(4),
                  child: Text('View All',
                      style: TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.accent)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: List.generate(categories.length, (i) {
                final c = categories[i];
                final isSelected = i == _newsCategory;
                return GestureDetector(
                  onTap: () => setState(() => _newsCategory = i),
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                    decoration: BoxDecoration(
                      color: isSelected ? c.color : const Color(0xFFF3F4F6),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      c.title,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: isSelected ? Colors.white : const Color(0xFF334155),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 12),
          if (preview.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Text('No news articles found in this category.',
                  style: TextStyle(fontSize: 14, color: AppColors.slate500)),
            )
          else
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: EdgeInsets.zero,
              itemCount: preview.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisExtent: 205,
              ),
              itemBuilder: (context, i) => _newsCard(preview[i]),
            ),
        ],
      ),
    );
  }

  Widget _newsCard(NewsItem n) {
    return GestureDetector(
      onTap: () => _openUrl(n.articleUrl),
      child: Card(
        margin: const EdgeInsets.all(6),
        color: Colors.white,
        elevation: 3,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 115,
              width: double.infinity,
              color: AppColors.slate200,
              child: n.imageUrl == null
                  ? null
                  : Image.network(n.imageUrl!,
                      fit: BoxFit.cover, errorBuilder: (_, __, ___) => const SizedBox()),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
              child: Text(
                n.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 13,
                  height: 1.25,
                  fontWeight: FontWeight.w700,
                  color: AppColors.slate900,
                ),
              ),
            ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 2, 12, 10),
              child: Row(
                children: [
                  const Icon(Icons.article_outlined, size: 16, color: AppColors.slate500),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(n.dateLabel,
                        style: const TextStyle(fontSize: 11, color: AppColors.slate500)),
                  ),
                  const Icon(Icons.chevron_right, size: 14, color: AppColors.slate900),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// News category chips (Android NewsFilterAdapter.DEFAULT_CATEGORIES).
class _NewsCategory {
  final String id;
  final String title;
  final Color color;
  final List<String> aliases;

  const _NewsCategory(this.id, this.title, this.color, [this.aliases = const []]);

  bool matches(NewsItem item) {
    if (id == 'ALL') return true;
    final cat = item.categoryId?.trim().toLowerCase();
    if (cat == null || cat.isEmpty) return false;
    if (cat == id.toLowerCase()) return true;
    return aliases.any((a) => cat.contains(a.toLowerCase()));
  }
}

const _newsCategories = [
  _NewsCategory('ALL', 'All News', Color(0xFF2563EB)),
  _NewsCategory('cat_car_tips', 'Car Tips', Color(0xFF059669), ['tips', 'car_tips']),
  _NewsCategory('cat_ev_news', 'EV News', Color(0xFF0284C7), ['ev', 'ev_news']),
  _NewsCategory(
      'cat_expert_reviews', 'Expert Reviews', Color(0xFF6D28D9), ['expert_reviews', 'reviews']),
  _NewsCategory('cat_industry', 'Industry News', Color(0xFF1E293B), ['industry']),
  _NewsCategory(
      'cat_new_launches', 'New Launches', Color(0xFFEA580C), ['launches', 'new_launches']),
  _NewsCategory('cat_user_reviews', 'User Reviews', Color(0xFFE11D48), ['user_reviews']),
];

/// Top banner carousel (dashboard_banner.xml): 175dp card, radius 12, dots below, auto-advance
/// every 5 s.
class _BannerCarousel extends StatefulWidget {
  final List<DashboardBanner> banners;

  const _BannerCarousel({required this.banners});

  @override
  State<_BannerCarousel> createState() => _BannerCarouselState();
}

class _BannerCarouselState extends State<_BannerCarousel> {
  final PageController _controller = PageController();
  Timer? _timer;
  int _page = 0;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 5), (_) {
      final count = widget.banners.length;
      if (count < 2 || !_controller.hasClients) return;
      _controller.animateToPage(
        (_page + 1) % count,
        duration: const Duration(milliseconds: 1200),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              height: 175,
              child: PageView.builder(
                controller: _controller,
                itemCount: widget.banners.length,
                onPageChanged: (i) => setState(() => _page = i),
                itemBuilder: (context, i) {
                  final url = widget.banners[i].imageUrl;
                  return Stack(
                    fit: StackFit.expand,
                    children: [
                      // Blurred-looking backdrop: the same image, cropped and dimmed.
                      Container(
                        color: Colors.black,
                        child: Opacity(
                          opacity: 0.4,
                          child: Image.network(url,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => const SizedBox()),
                        ),
                      ),
                      Image.network(url,
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) => const SizedBox()),
                    ],
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(widget.banners.length, (i) {
              final selected = i == _page;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: selected ? 8 : 6,
                height: selected ? 8 : 6,
                decoration: BoxDecoration(
                  color: selected ? Colors.black : const Color(0xFF808080),
                  shape: BoxShape.circle,
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

/// Search page backed by GET cars/suggestionsAll (brand + model). Returns the picked pair.
class _SearchScreen extends StatefulWidget {
  final List<BrandModelPair> suggestions;

  const _SearchScreen({required this.suggestions});

  @override
  State<_SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<_SearchScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final q = _query.trim().toLowerCase();
    final results = q.isEmpty
        ? const <BrandModelPair>[]
        : widget.suggestions
            .where((p) =>
                p.model.toLowerCase().contains(q) || p.brand.toLowerCase().contains(q))
            .take(50)
            .toList();
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        titleSpacing: 0,
        title: TextField(
          autofocus: true,
          onChanged: (v) => setState(() => _query = v),
          style: const TextStyle(fontSize: 15),
          decoration: const InputDecoration(
            hintText: 'Search by brand or model',
            border: InputBorder.none,
          ),
        ),
      ),
      body: ListView.separated(
        itemCount: results.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, i) {
          final p = results[i];
          return ListTile(
            leading: const Icon(Icons.search, color: Color(0xFF8C8C8C)),
            title: Text(p.model),
            subtitle: Text(p.brand),
            onTap: () => Navigator.of(context).pop(p),
          );
        },
      ),
    );
  }
}
