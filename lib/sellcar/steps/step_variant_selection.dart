import 'package:flutter/material.dart';
import 'package:carsbuzz/sellcar/models/sell_car_models.dart';
import 'package:carsbuzz/sellcar/repository/sell_car_repository.dart';

/// Step 3: Variant selection - mirrors native SelectCarsVariantsBottomSheetFragment.
/// Variants come from GET cars/{brandName}/models/{modelId}/variants. The user can skip when
/// they don't know their variant.
class StepVariantSelection extends StatefulWidget {
  final String brandName;
  final String modelName;

  /// Id of the chosen model. Variants can't be loaded without it.
  final int? modelId;
  final String? selectedVariant;
  final ValueChanged<CarVariantItem> onVariantSelected;
  final VoidCallback onSkip;

  const StepVariantSelection({
    super.key,
    required this.brandName,
    required this.modelName,
    required this.modelId,
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

  List<CarVariantItem> _variants = [];
  List<CarVariantItem> _filteredVariants = [];
  bool _isLoading = false;
  bool _hasError = false;
  String _loadedKey = '';

  String get _key => '${widget.brandName}|${widget.modelId}';

  @override
  void initState() {
    super.initState();
    _loadVariants();
  }

  @override
  void didUpdateWidget(StepVariantSelection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_key != _loadedKey) {
      _searchController.clear();
      _loadVariants();
    }
  }

  Future<void> _loadVariants() async {
    final id = widget.modelId;
    if (widget.brandName.isEmpty || id == null || id <= 0) {
      // Nothing to load yet (before a model is chosen) or an "Other" model with no variants.
      setState(() {
        _variants = [];
        _filteredVariants = [];
        _isLoading = false;
        _hasError = false;
        _loadedKey = _key;
      });
      return;
    }
    final key = _key;
    setState(() {
      _isLoading = true;
      _hasError = false;
      _loadedKey = key;
    });
    try {
      final variants = await _repo.getVariants(widget.brandName, id);
      if (!mounted || key != _key) return;
      setState(() {
        _variants = variants;
        _filteredVariants = _applyFilter(variants, _searchController.text);
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted || key != _key) return;
      setState(() {
        _variants = [];
        _filteredVariants = [];
        _hasError = true;
        _isLoading = false;
      });
    }
  }

  List<CarVariantItem> _applyFilter(List<CarVariantItem> source, String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return source;
    return source
        .where((v) => v.isOther || v.name.toLowerCase().contains(q))
        .toList();
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
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            controller: _searchController,
            onChanged: (q) =>
                setState(() => _filteredVariants = _applyFilter(_variants, q)),
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
        Expanded(
          child: _filteredVariants.isEmpty
              ? _buildEmptyState()
              : ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _filteredVariants.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final variant = _filteredVariants[index];
                    return _VariantTile(
                      variant: variant,
                      isSelected: widget.selectedVariant == variant.name,
                      onTap: () => widget.onVariantSelected(variant),
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
            _hasError
                ? "Couldn't load variants"
                : 'No variants found for ${widget.modelName}',
            style: const TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 16),
          if (_hasError)
            TextButton(onPressed: _loadVariants, child: const Text('Retry')),
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
  final CarVariantItem variant;
  final bool isSelected;
  final VoidCallback onTap;

  const _VariantTile({
    required this.variant,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final specs = variant.displaySpecs;
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
                    variant.name,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                      color:
                          isSelected ? const Color(0xFF1A73E8) : Colors.black87,
                    ),
                  ),
                  if (specs.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      specs,
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
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
