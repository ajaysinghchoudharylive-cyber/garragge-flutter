import 'package:flutter/material.dart';
import 'package:carsbuzz/models/car_listing_model.dart';
import 'package:carsbuzz/models/car_listing_response.dart';
import 'package:carsbuzz/network/api_client.dart';
import 'package:carsbuzz/network/repository_api.dart';
import 'package:carsbuzz/carlisting/car_listing_card.dart';
import 'package:carsbuzz/carlisting/car_listing_filters.dart';
import 'package:carsbuzz/widgets/notification_permission_prompt.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Car Listing screen - mirrors native FragmentCarListing
/// Shows paginated car grid with filters, sort, location selector, and search
class CarListingScreen extends StatefulWidget {
  final String? initialBrand;
  final String? initialModel;
  final bool isFromPopular;

  const CarListingScreen({
    super.key,
    this.initialBrand,
    this.initialModel,
    this.isFromPopular = false,
  });

  @override
  State<CarListingScreen> createState() => _CarListingScreenState();
}

class _CarListingScreenState extends State<CarListingScreen> {
  final RepositoryApi _api = ApiClient.create();
  final ScrollController _scrollController = ScrollController();

  List<CarListingModel> _cars = [];
  Set<int> _favorites = {};
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  int _currentPage = 0;
  int _totalCount = 0;

  // Filters
  String? _city;
  String? _selectedBrand;
  String? _selectedFuelType;
  String? _selectedTransmission;
  String? _sortBy;
  String? _sortDirection;
  String? _minPrice;
  String? _maxPrice;

  // Active filter chips
  List<String> _activeFilters = [];

  @override
  void initState() {
    super.initState();
    _selectedBrand = widget.initialBrand;
    _scrollController.addListener(_onScroll);
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _city = prefs.getString('city');
    });
    _fetchCars();
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = int.tryParse(prefs.getString('user_id') ?? '');
      if (userId != null) {
        final favs = await _api.getFavorites(userId);
        if (mounted) {
          setState(() => _favorites = favs.toSet());
        }
      }
    } catch (_) {}
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !_isLoadingMore &&
        _hasMore) {
      _fetchMoreCars();
    }
  }

  Future<void> _fetchCars() async {
    setState(() {
      _isLoading = true;
      _currentPage = 0;
      _cars = [];
    });

    try {
      final response = await _api.getCarListing(_buildQueryParams(0));
      if (mounted) {
        setState(() {
          _cars = response.content;
          _totalCount = response.totalElements;
          _hasMore = !response.isLast;
          _currentPage = 0;
          _isLoading = false;
        });
        _askForNotificationsOnce();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  bool _notificationPromptChecked = false;

  /// Once per visit, after the list has loaded: if notifications are off, ask the user to turn
  /// them back on (throttled to every few days inside the prompt).
  void _askForNotificationsOnce() {
    if (_notificationPromptChecked) return;
    _notificationPromptChecked = true;
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) NotificationPermissionPrompt.maybeAsk(context);
    });
  }

  Future<void> _fetchMoreCars() async {
    setState(() => _isLoadingMore = true);
    final nextPage = _currentPage + 1;

    try {
      final response = await _api.getCarListing(_buildQueryParams(nextPage));
      if (mounted) {
        setState(() {
          _cars.addAll(response.content);
          _hasMore = !response.isLast;
          _currentPage = nextPage;
          _isLoadingMore = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingMore = false);
      }
    }
  }

  Map<String, dynamic> _buildQueryParams(int page) {
    final params = <String, dynamic>{
      'page': page,
      'size': 20,
    };

    if (_city != null && _city!.isNotEmpty) params['city'] = _city;
    if (_selectedBrand != null) params['make'] = _selectedBrand;
    if (widget.initialModel != null) params['model'] = widget.initialModel;
    if (_selectedFuelType != null) params['fuelType'] = _selectedFuelType;
    if (_selectedTransmission != null) {
      params['transmission'] = _selectedTransmission;
    }
    if (_sortBy != null) params['sortBy'] = _sortBy;
    if (_sortDirection != null) params['sortDirection'] = _sortDirection;
    if (_minPrice != null) params['minPrice'] = _minPrice;
    if (_maxPrice != null) params['maxPrice'] = _maxPrice;
    if (widget.isFromPopular) params['isPopular'] = 1;

    return params;
  }

  void _updateActiveFilters() {
    _activeFilters = [];
    if (_selectedBrand != null) _activeFilters.add(_selectedBrand!);
    if (_selectedFuelType != null) _activeFilters.add(_selectedFuelType!);
    if (_selectedTransmission != null) _activeFilters.add(_selectedTransmission!);
    if (_minPrice != null && _maxPrice != null) {
      _activeFilters.add('\u20B9$_minPrice - \u20B9$_maxPrice');
    }
  }

  void _clearAllFilters() {
    setState(() {
      _selectedBrand = null;
      _selectedFuelType = null;
      _selectedTransmission = null;
      _sortBy = null;
      _sortDirection = null;
      _minPrice = null;
      _maxPrice = null;
      _activeFilters = [];
    });
    _fetchCars();
  }

  void _removeFilter(String filter) {
    setState(() {
      if (filter == _selectedBrand) _selectedBrand = null;
      if (filter == _selectedFuelType) _selectedFuelType = null;
      if (filter == _selectedTransmission) _selectedTransmission = null;
      if (filter.startsWith('\u20B9')) {
        _minPrice = null;
        _maxPrice = null;
      }
    });
    _updateActiveFilters();
    _fetchCars();
  }

  void _showSortBottomSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => _SortBottomSheet(
        currentSort: _sortBy,
        onSortSelected: (sortBy, direction) {
          Navigator.pop(context);
          setState(() {
            _sortBy = sortBy;
            _sortDirection = direction;
          });
          _fetchCars();
        },
      ),
    );
  }

  void _showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => CarListingFilters(
        selectedBrand: _selectedBrand,
        selectedFuelType: _selectedFuelType,
        selectedTransmission: _selectedTransmission,
        minPrice: _minPrice,
        maxPrice: _maxPrice,
        onApply: (brand, fuelType, transmission, minPrice, maxPrice) {
          Navigator.pop(context);
          setState(() {
            _selectedBrand = brand;
            _selectedFuelType = fuelType;
            _selectedTransmission = transmission;
            _minPrice = minPrice;
            _maxPrice = maxPrice;
          });
          _updateActiveFilters();
          _fetchCars();
        },
      ),
    );
  }

  void _toggleFavorite(int carId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = int.tryParse(prefs.getString('user_id') ?? '');
      if (userId == null) return;

      await _api.toggleFavorite({'userId': userId, 'carId': carId});
      setState(() {
        if (_favorites.contains(carId)) {
          _favorites.remove(carId);
        } else {
          _favorites.add(carId);
        }
      });
    } catch (_) {}
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildFilterBar(),
            if (_activeFilters.isNotEmpty) _buildActiveFilters(),
            _buildResultCount(),
            Expanded(child: _buildCarGrid()),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          // Location
          GestureDetector(
            onTap: () {
              // Show location picker
            },
            child: Row(
              children: [
                const Icon(Icons.location_on,
                    color: Color(0xFF1A73E8), size: 20),
                const SizedBox(width: 4),
                Text(
                  _city ?? 'All Cities',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Icon(Icons.keyboard_arrow_down, size: 18),
              ],
            ),
          ),
          const Spacer(),
          // Search icon
          IconButton(
            icon: const Icon(Icons.search, color: Colors.black87),
            onPressed: () {},
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          const SizedBox(width: 16),
          // Favorites icon
          IconButton(
            icon: const Icon(Icons.favorite_border, color: Colors.black87),
            onPressed: () {},
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar() {
    final filterCount = _activeFilters.length;
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _FilterChip(
              label: 'Filter${filterCount > 0 ? ' ($filterCount)' : ''}',
              icon: Icons.tune,
              onTap: _showFilterBottomSheet,
            ),
            const SizedBox(width: 8),
            _FilterChip(
              label: 'Sort',
              icon: Icons.swap_vert,
              onTap: _showSortBottomSheet,
              isActive: _sortBy != null,
            ),
            const SizedBox(width: 8),
            _FilterChip(
              label: 'Price Range',
              onTap: _showFilterBottomSheet,
              isActive: _minPrice != null || _maxPrice != null,
            ),
            const SizedBox(width: 8),
            _FilterChip(
              label: 'Fuel Type',
              onTap: () {
                _showFuelTypeSheet();
              },
              isActive: _selectedFuelType != null,
            ),
          ],
        ),
      ),
    );
  }

  void _showFuelTypeSheet() {
    final fuelTypes = ['Petrol', 'Diesel', 'CNG', 'Electric', 'Hybrid'];
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Fuel Type',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: fuelTypes.map((fuel) {
                final isSelected = _selectedFuelType == fuel;
                return GestureDetector(
                  onTap: () {
                    Navigator.pop(context);
                    setState(() {
                      _selectedFuelType = isSelected ? null : fuel;
                    });
                    _updateActiveFilters();
                    _fetchCars();
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFF1A73E8)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected
                            ? const Color(0xFF1A73E8)
                            : Colors.grey.shade300,
                      ),
                    ),
                    child: Text(
                      fuel,
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.black87,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveFilters() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Row(
        children: [
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _activeFilters.map((filter) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Chip(
                      label: Text(filter, style: const TextStyle(fontSize: 12)),
                      deleteIcon: const Icon(Icons.close, size: 16),
                      onDeleted: () => _removeFilter(filter),
                      backgroundColor: const Color(0xFFE3F2FD),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      visualDensity: VisualDensity.compact,
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          if (_activeFilters.isNotEmpty)
            TextButton(
              onPressed: _clearAllFilters,
              child: const Text('Clear', style: TextStyle(fontSize: 12)),
            ),
        ],
      ),
    );
  }

  Widget _buildResultCount() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      alignment: Alignment.centerLeft,
      child: Text(
        _isLoading
            ? 'Searching for cars...'
            : '$_totalCount cars${_city != null ? ' in $_city' : ''}',
        style: TextStyle(
          fontSize: 13,
          color: Colors.grey.shade600,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildCarGrid() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_cars.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.directions_car_outlined,
                size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            const Text(
              'No cars found',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              'Try changing your filters or location',
              style: TextStyle(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 20),
            TextButton(
              onPressed: _clearAllFilters,
              child: const Text('Clear all filters'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchCars,
      child: GridView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.all(12),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.68,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
        ),
        itemCount: _cars.length + (_isLoadingMore ? 2 : 0),
        itemBuilder: (context, index) {
          if (index >= _cars.length) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            );
          }

          final car = _cars[index];
          final isFav = _favorites.contains(car.id);
          return CarListingCard(
            car: car,
            isFavorite: isFav,
            onTap: () {
              // Navigate to car details
            },
            onFavoriteToggle: () {
              if (car.id != null) _toggleFavorite(car.id!);
            },
          );
        },
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback onTap;
  final bool isActive;

  const _FilterChip({
    required this.label,
    this.icon,
    required this.onTap,
    this.isActive = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFFE3F2FD) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive ? const Color(0xFF1A73E8) : Colors.grey.shade300,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 16, color: isActive ? const Color(0xFF1A73E8) : Colors.grey.shade700),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: isActive ? const Color(0xFF1A73E8) : Colors.black87,
              ),
            ),
            const SizedBox(width: 2),
            Icon(
              Icons.keyboard_arrow_down,
              size: 16,
              color: isActive ? const Color(0xFF1A73E8) : Colors.grey,
            ),
          ],
        ),
      ),
    );
  }
}

class _SortBottomSheet extends StatelessWidget {
  final String? currentSort;
  final void Function(String? sortBy, String? direction) onSortSelected;

  const _SortBottomSheet({
    this.currentSort,
    required this.onSortSelected,
  });

  @override
  Widget build(BuildContext context) {
    final options = [
      {'label': 'Relevance', 'sortBy': null, 'direction': null},
      {'label': 'Price: Low to High', 'sortBy': 'price', 'direction': 'asc'},
      {'label': 'Price: High to Low', 'sortBy': 'price', 'direction': 'desc'},
      {'label': 'KM: Low to High', 'sortBy': 'km', 'direction': 'asc'},
      {'label': 'Newest First', 'sortBy': 'date', 'direction': 'desc'},
    ];

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Sort By',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          ...options.map((option) {
            final isSelected = currentSort == option['sortBy'];
            return ListTile(
              title: Text(
                option['label'] as String,
                style: TextStyle(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? const Color(0xFF1A73E8) : Colors.black87,
                ),
              ),
              trailing: isSelected
                  ? const Icon(Icons.check, color: Color(0xFF1A73E8))
                  : null,
              onTap: () => onSortSelected(
                option['sortBy'],
                option['direction'],
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            );
          }),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
