import 'package:flutter/material.dart';
import 'package:carsbuzz/sellcar/models/sell_car_models.dart';
import 'package:carsbuzz/sellcar/repository/sell_car_repository.dart';

/// Step 2: Model selection - mirrors native SelectCarsModelsBottomSheetFragment.
/// Models come from GET cars/{brandName}/models (each has an id, needed to load variants).
/// The backend appends an "Other" entry (id -1) for models that aren't listed.
class StepModelSelection extends StatefulWidget {
  final String brandName;
  final String? selectedModel;
  final ValueChanged<CarModelItem> onModelSelected;

  const StepModelSelection({
    super.key,
    required this.brandName,
    this.selectedModel,
    required this.onModelSelected,
  });

  @override
  State<StepModelSelection> createState() => _StepModelSelectionState();
}

class _StepModelSelectionState extends State<StepModelSelection> {
  final SellCarRepository _repo = SellCarRepository();
  final TextEditingController _searchController = TextEditingController();

  List<CarModelItem> _models = [];
  List<CarModelItem> _filteredModels = [];
  bool _isLoading = true;
  bool _hasError = false;
  String _loadedFor = '';

  @override
  void initState() {
    super.initState();
    _loadModels();
  }

  @override
  void didUpdateWidget(StepModelSelection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.brandName.isNotEmpty && widget.brandName != _loadedFor) {
      _searchController.clear();
      _loadModels();
    }
  }

  Future<void> _loadModels() async {
    if (widget.brandName.isEmpty) return;
    final brand = widget.brandName;
    setState(() {
      _isLoading = true;
      _hasError = false;
      _loadedFor = brand;
    });
    try {
      final models = await _repo.getModels(brand);
      if (!mounted || brand != widget.brandName) return;
      setState(() {
        _models = models;
        _filteredModels = _applyFilter(models, _searchController.text);
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted || brand != widget.brandName) return;
      setState(() {
        _models = [];
        _filteredModels = [];
        _hasError = true;
        _isLoading = false;
      });
    }
  }

  List<CarModelItem> _applyFilter(List<CarModelItem> source, String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return source;
    // Keep "Other" visible while searching so an unlisted model can always be entered.
    return source
        .where((m) => m.isOther || m.name.toLowerCase().contains(q))
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

    if (_hasError || _models.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.info_outline, size: 48, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            Text(
              _hasError
                  ? "Couldn't load models for ${widget.brandName}"
                  : 'No models found for ${widget.brandName}',
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            TextButton(onPressed: _loadModels, child: const Text('Retry')),
          ],
        ),
      );
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            controller: _searchController,
            onChanged: (q) =>
                setState(() => _filteredModels = _applyFilter(_models, q)),
            decoration: InputDecoration(
              hintText: 'Search model...',
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
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _filteredModels.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final model = _filteredModels[index];
              final isSelected = widget.selectedModel == model.name;
              final image = model.imageUrl;
              return ListTile(
                leading: (image != null && image.isNotEmpty)
                    ? Image.network(
                        image,
                        width: 56,
                        height: 40,
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => const Icon(
                            Icons.directions_car,
                            color: Colors.grey),
                      )
                    : const Icon(Icons.directions_car, color: Colors.grey),
                title: Text(
                  model.name,
                  style: TextStyle(
                    fontWeight:
                        isSelected ? FontWeight.bold : FontWeight.normal,
                    color: isSelected ? const Color(0xFF1A73E8) : Colors.black87,
                  ),
                ),
                trailing: isSelected
                    ? const Icon(Icons.check_circle, color: Color(0xFF1A73E8))
                    : const Icon(Icons.chevron_right, color: Colors.grey),
                onTap: () => widget.onModelSelected(model),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                selectedTileColor: const Color(0xFFE3F2FD),
                selected: isSelected,
              );
            },
          ),
        ),
      ],
    );
  }
}
