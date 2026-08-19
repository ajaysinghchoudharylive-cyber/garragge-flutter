import 'package:flutter/material.dart';
import 'package:carsbuzz/models/car_brand_model.dart';
import 'package:carsbuzz/network/api_client.dart';
import 'package:carsbuzz/network/repository_api.dart';

/// Step 1: Brand selection - mirrors native SelectYourCarBrandFragment
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
  final RepositoryApi _api = ApiClient.create();
  final TextEditingController _searchController = TextEditingController();

  List<CarBrandModel> _brands = [];
  List<CarBrandModel> _filteredBrands = [];
  bool _isLoading = true;

  // Popular brands shown at top
  static const List<String> _popularBrands = [
    'Maruti Suzuki',
    'Hyundai',
    'Tata',
    'Mahindra',
    'Honda',
    'Toyota',
    'Kia',
    'MG',
  ];

  @override
  void initState() {
    super.initState();
    _loadBrands();
  }

  Future<void> _loadBrands() async {
    try {
      final brands = await _api.getCarBrands();
      if (mounted) {
        setState(() {
          _brands = brands;
          _filteredBrands = brands;
          _isLoading = false;
        });
      }
    } catch (e) {
      // Fallback to popular brands if API fails
      if (mounted) {
        setState(() {
          _brands = _popularBrands
              .map((b) => CarBrandModel(brandName: b))
              .toList();
          _filteredBrands = _brands;
          _isLoading = false;
        });
      }
    }
  }

  void _onSearchChanged(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredBrands = _brands;
      } else {
        _filteredBrands = _brands
            .where((b) =>
                b.brandName.toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });
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

    return Column(
      children: [
        // Search bar
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

        // Popular brands section
        if (_searchController.text.isEmpty) ...[
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
              itemCount: _popularBrands.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final brandName = _popularBrands[index];
                final isSelected = widget.selectedBrand == brandName;
                return GestureDetector(
                  onTap: () => widget.onBrandSelected(brandName),
                  child: Container(
                    width: 75,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFFE3F2FD)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? const Color(0xFF1A73E8)
                            : Colors.grey.shade300,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.directions_car,
                          color: isSelected
                              ? const Color(0xFF1A73E8)
                              : Colors.grey,
                          size: 28,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          brandName,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            color: isSelected
                                ? const Color(0xFF1A73E8)
                                : Colors.black87,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                );
              },
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

        // All brands grid
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              childAspectRatio: 1.1,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: _filteredBrands.length,
            itemBuilder: (context, index) {
              final brand = _filteredBrands[index];
              final isSelected = widget.selectedBrand == brand.brandName;
              return GestureDetector(
                onTap: () => widget.onBrandSelected(brand.brandName),
                child: Container(
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFFE3F2FD)
                        : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected
                          ? const Color(0xFF1A73E8)
                          : Colors.grey.shade300,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (brand.brandLogo != null)
                        Image.network(
                          brand.brandLogo!,
                          width: 36,
                          height: 36,
                          errorBuilder: (_, __, ___) => Icon(
                            Icons.directions_car,
                            color: isSelected
                                ? const Color(0xFF1A73E8)
                                : Colors.grey,
                            size: 32,
                          ),
                        )
                      else
                        Icon(
                          Icons.directions_car,
                          color: isSelected
                              ? const Color(0xFF1A73E8)
                              : Colors.grey,
                          size: 32,
                        ),
                      const SizedBox(height: 8),
                      Text(
                        brand.brandName,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: isSelected
                              ? const Color(0xFF1A73E8)
                              : Colors.black87,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
