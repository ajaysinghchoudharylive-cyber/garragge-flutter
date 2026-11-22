import 'package:flutter/material.dart';
import 'package:carsbuzz/models/car_brand_model.dart';
import 'package:carsbuzz/sellcar/repository/sell_car_repository.dart';

/// Step 1: Brand selection - mirrors native SelectYourCarBrandFragment.
/// Brands (with logos) come from GET cars/carLogoAndNames.
class StepBrandSelection extends StatefulWidget {
  final String? selectedBrand;
  final ValueChanged<String> onBrandSelected;

  const StepBrandSelection({
    super.key,
    this.selectedBrand,
    required this.onBrandSelected,
  });

  @override
  State<StepBrandSelection> createState() => _StepBrandSelectionState();
}

class _StepBrandSelectionState extends State<StepBrandSelection> {
  final SellCarRepository _repo = SellCarRepository();
  final TextEditingController _searchController = TextEditingController();

  List<CarBrandModel> _brands = [];
  List<CarBrandModel> _filteredBrands = [];
  bool _isLoading = true;
  bool _hasError = false;

  // Names promoted to the "Popular Brands" row. Only brands that the server actually returns are
  // shown, so a popular chip can never lead to a brand that has no models.
  static const List<String> _popularBrandNames = [
    'Maruti Suzuki',
    'Hyundai',
    'Tata',
    'Mahindra',
    'Honda',
    'Toyota',
    'Kia',
    'MG',
  ];

  List<CarBrandModel> get _popularBrands {
    final byName = {for (final b in _brands) b.brandName.toLowerCase(): b};
    return _popularBrandNames
        .map((n) => byName[n.toLowerCase()])
        .whereType<CarBrandModel>()
        .toList();
  }

  @override
  void initState() {
    super.initState();
    _loadBrands();
  }

  Future<void> _loadBrands() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });
    try {
      final brands = await _repo.getCarBrands();
      if (!mounted) return;
      setState(() {
        _brands = brands;
        _filteredBrands = _applyFilter(brands, _searchController.text);
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _hasError = true;
        _isLoading = false;
      });
    }
  }

  List<CarBrandModel> _applyFilter(List<CarBrandModel> source, String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return source;
    return source.where((b) => b.brandName.toLowerCase().contains(q)).toList();
  }

  void _onSearchChanged(String query) {
    setState(() => _filteredBrands = _applyFilter(_brands, query));
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_hasError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.wifi_off, size: 48, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            const Text("Couldn't load brands",
                style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 12),
            TextButton(onPressed: _loadBrands, child: const Text('Retry')),
          ],
        ),
      );
    }

    final popular = _popularBrands;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            controller: _searchController,
            onChanged: _onSearchChanged,
            decoration: InputDecoration(
              hintText: 'Search brand...',
              prefixIcon: const Icon(Icons.search, color: Colors.grey),
              filled: true,
              fillColor: Colors.grey.shade100,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),

        if (_searchController.text.isEmpty && popular.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Popular Brands',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade700,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 90,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: popular.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, index) => SizedBox(
                width: 75,
                child: _BrandTile(
                  brand: popular[index],
                  isSelected: widget.selectedBrand == popular[index].brandName,
                  compact: true,
                  onTap: () => widget.onBrandSelected(popular[index].brandName),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Divider(),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'All Brands',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade700,
                ),
              ),
            ),
          ),
        ],

        Expanded(
          child: _filteredBrands.isEmpty
              ? const Center(
                  child: Text('No brands found',
                      style: TextStyle(color: Colors.grey)),
                )
              : GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    childAspectRatio: 1.1,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: _filteredBrands.length,
                  itemBuilder: (context, index) {
                    final brand = _filteredBrands[index];
                    return _BrandTile(
                      brand: brand,
                      isSelected: widget.selectedBrand == brand.brandName,
                      onTap: () => widget.onBrandSelected(brand.brandName),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _BrandTile extends StatelessWidget {
  final CarBrandModel brand;
  final bool isSelected;
  final bool compact;
  final VoidCallback onTap;

  const _BrandTile({
    required this.brand,
    required this.isSelected,
    required this.onTap,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final accent = isSelected ? const Color(0xFF1A73E8) : Colors.grey;
    final logo = brand.brandLogo;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFE3F2FD) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? const Color(0xFF1A73E8) : Colors.grey.shade300,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (logo != null && logo.isNotEmpty)
              Image.network(
                logo,
                width: compact ? 30 : 36,
                height: compact ? 30 : 36,
                errorBuilder: (_, __, ___) =>
                    Icon(Icons.directions_car, color: accent, size: 28),
              )
            else
              Icon(Icons.directions_car, color: accent, size: 28),
            SizedBox(height: compact ? 6 : 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                brand.brandName,
                style: TextStyle(
                  fontSize: compact ? 10 : 12,
                  fontWeight: FontWeight.w500,
                  color: isSelected ? const Color(0xFF1A73E8) : Colors.black87,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
