import 'package:flutter/material.dart';
import 'package:carsbuzz/sellcar/models/car_variant_response.dart';
import 'package:carsbuzz/sellcar/repository/sell_car_repository.dart';

/// Step 3: Variant selection - mirrors native CarVariant fragment
/// Shows variants with specs (engine, HP, mileage, transmission)
/// User can skip if variant not available
class StepVariantSelection extends StatefulWidget {
  final String brandName;
  final String modelName;
  final String? selectedVariant;
  final void Function(String name, int? id, String? transmission, String? seating) onVariantSelected;
  final VoidCallback onSkip;

  const StepVariantSelection({
    super.key,
    required this.brandName,
    required this.modelName,
    this.selectedVariant,
    required this.onVariantSelected,
    required this.onSkip,
  });

  @override
  State<StepVariantSelection> createState() => _StepVariantSelectionState();
}

class _StepVariantSelectionState extends State<StepVariantSelection> {
  final SellCarRepository _repo = SellCarRepository();
  final TextEditingController _searchController = TextEditingController();

  List<CarVariantResponse> _variants = [];
  List<CarVariantResponse> _filteredVariants = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadVariants();
  }

  @override
  void didUpdateWidget(StepVariantSelection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.brandName != widget.brandName ||
        oldWidget.modelName != widget.modelName) {
      _loadVariants();
    }
  }

  Future<void> _loadVariants() async {
    if (widget.brandName.isEmpty || widget.modelName.isEmpty) return;
    setState(() => _isLoading = true);

    // modelId is typically derived from model name; use 0 as placeholder
    // The API handles brand + model lookup
    final variants = await _repo.getVariants(widget.brandName.toLowerCase(), 0);

    if (mounted) {
      setState(() {
        _variants = variants;
        _filteredVariants = variants;
        _isLoading = false;
      });
    }
  }

  void _onSearchChanged(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredVariants = _variants;
      } else {
        _filteredVariants = _variants
            .where((v) =>
                (v.variantName ?? '').toLowerCase().contains(query.toLowerCase()))
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
              hintText: 'Search variant...',
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

        // Skip button
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Text(
                '${_filteredVariants.length} variants found',
                style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
              ),
              const Spacer(),
              TextButton(
                onPressed: widget.onSkip,
                child: const Text("I don't know my variant"),
              ),
            ],
          ),
        ),

        // Variant list
        Expanded(
          child: _filteredVariants.isEmpty
              ? _buildEmptyState()
              : ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _filteredVariants.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final variant = _filteredVariants[index];
                    final isSelected =
                        widget.selectedVariant == variant.variantName;

                    return _VariantTile(
                      variant: variant,
                      isSelected: isSelected,
                      onTap: () => widget.onVariantSelected(
                        variant.variantName ?? '',
                        variant.id,
                        variant.transmission,
                        variant.seatingCapacity,
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.info_outline, size: 48, color: Colors.grey.shade400),
          const SizedBox(height: 12),
          Text(
            'No variants found for ${widget.modelName}',
            style: const TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: widget.onSkip,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1A73E8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('Skip this step',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

class _VariantTile extends StatelessWidget {
  final CarVariantResponse variant;
  final bool isSelected;
  final VoidCallback onTap;

  const _VariantTile({
    required this.variant,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFE3F2FD) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    variant.variantName ?? 'Unknown',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.w500,
                      color: isSelected
                          ? const Color(0xFF1A73E8)
                          : Colors.black87,
                    ),
                  ),
                  if (variant.displaySpecs.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      variant.displaySpecs,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle, color: Color(0xFF1A73E8), size: 22)
            else
              Icon(Icons.chevron_right, color: Colors.grey.shade400, size: 22),
          ],
        ),
      ),
    );
  }
}
