import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Filter bottom sheet for car listing - mirrors native filter fragments
class CarListingFilters extends StatefulWidget {
  final String? selectedBrand;
  final String? selectedFuelType;
  final String? selectedTransmission;
  final String? minPrice;
  final String? maxPrice;
  final void Function(
    String? brand,
    String? fuelType,
    String? transmission,
    String? minPrice,
    String? maxPrice,
  ) onApply;

  const CarListingFilters({
    super.key,
    this.selectedBrand,
    this.selectedFuelType,
    this.selectedTransmission,
    this.minPrice,
    this.maxPrice,
    required this.onApply,
  });

  @override
  State<CarListingFilters> createState() => _CarListingFiltersState();
}

class _CarListingFiltersState extends State<CarListingFilters> {
  late String? _brand;
  late String? _fuelType;
  late String? _transmission;
  late TextEditingController _minPriceController;
  late TextEditingController _maxPriceController;

  static const _fuelTypes = ['Petrol', 'Diesel', 'CNG', 'Electric', 'Hybrid'];
  static const _transmissions = ['Manual', 'Automatic'];
  static const _popularBrands = [
    'Maruti Suzuki',
    'Hyundai',
    'Tata',
    'Mahindra',
    'Honda',
    'Toyota',
    'Kia',
    'MG',
    'Volkswagen',
    'Skoda',
  ];

  @override
  void initState() {
    super.initState();
    _brand = widget.selectedBrand;
    _fuelType = widget.selectedFuelType;
    _transmission = widget.selectedTransmission;
    _minPriceController = TextEditingController(text: widget.minPrice ?? '');
    _maxPriceController = TextEditingController(text: widget.maxPrice ?? '');
  }

  @override
  void dispose() {
    _minPriceController.dispose();
    _maxPriceController.dispose();
    super.dispose();
  }

  void _clearAll() {
    setState(() {
      _brand = null;
      _fuelType = null;
      _transmission = null;
      _minPriceController.clear();
      _maxPriceController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      maxChildSize: 0.9,
      minChildSize: 0.5,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Filters',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  TextButton(
                    onPressed: _clearAll,
                    child: const Text('Clear All'),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Brand section
                      _buildSectionTitle('Brand'),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _popularBrands.map((brand) {
                          final isSelected = _brand == brand;
                          return GestureDetector(
                            onTap: () => setState(() {
                              _brand = isSelected ? null : brand;
                            }),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 8),
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
                                brand,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: isSelected
                                      ? Colors.white
                                      : Colors.black87,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),

                      const SizedBox(height: 24),

                      // Fuel Type section
                      _buildSectionTitle('Fuel Type'),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _fuelTypes.map((fuel) {
                          final isSelected = _fuelType == fuel;
                          return GestureDetector(
                            onTap: () => setState(() {
                              _fuelType = isSelected ? null : fuel;
                            }),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 8),
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
                                  fontSize: 13,
                                  color: isSelected
                                      ? Colors.white
                                      : Colors.black87,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),

                      const SizedBox(height: 24),

                      // Transmission section
                      _buildSectionTitle('Transmission'),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _transmissions.map((trans) {
                          final isSelected = _transmission == trans;
                          return GestureDetector(
                            onTap: () => setState(() {
                              _transmission = isSelected ? null : trans;
                            }),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 8),
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
                                trans,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: isSelected
                                      ? Colors.white
                                      : Colors.black87,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),

                      const SizedBox(height: 24),

                      // Price Range section
                      _buildSectionTitle('Price Range'),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _minPriceController,
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly
                              ],
                              decoration: InputDecoration(
                                hintText: 'Min',
                                prefixText: '\u20B9 ',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 10),
                              ),
                            ),
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 8),
                            child: Text('-'),
                          ),
                          Expanded(
                            child: TextField(
                              controller: _maxPriceController,
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly
                              ],
                              decoration: InputDecoration(
                                hintText: 'Max',
                                prefixText: '\u20B9 ',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 10),
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),
                      // Quick price ranges
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _PriceRangeChip(
                            label: 'Under 3L',
                            onTap: () {
                              _minPriceController.text = '0';
                              _maxPriceController.text = '300000';
                            },
                          ),
                          _PriceRangeChip(
                            label: '3L - 5L',
                            onTap: () {
                              _minPriceController.text = '300000';
                              _maxPriceController.text = '500000';
                            },
                          ),
                          _PriceRangeChip(
                            label: '5L - 10L',
                            onTap: () {
                              _minPriceController.text = '500000';
                              _maxPriceController.text = '1000000';
                            },
                          ),
                          _PriceRangeChip(
                            label: '10L - 20L',
                            onTap: () {
                              _minPriceController.text = '1000000';
                              _maxPriceController.text = '2000000';
                            },
                          ),
                          _PriceRangeChip(
                            label: '20L+',
                            onTap: () {
                              _minPriceController.text = '2000000';
                              _maxPriceController.text = '';
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Apply button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    widget.onApply(
                      _brand,
                      _fuelType,
                      _transmission,
                      _minPriceController.text.isNotEmpty
                          ? _minPriceController.text
                          : null,
                      _maxPriceController.text.isNotEmpty
                          ? _maxPriceController.text
                          : null,
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1A73E8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Apply Filters',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: Colors.grey.shade800,
      ),
    );
  }
}

class _PriceRangeChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _PriceRangeChip({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
        ),
      ),
    );
  }
}
