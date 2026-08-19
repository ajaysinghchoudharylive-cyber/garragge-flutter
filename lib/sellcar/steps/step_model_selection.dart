import 'package:flutter/material.dart';
import 'package:carsbuzz/network/api_client.dart';
import 'package:carsbuzz/network/repository_api.dart';

/// Step 2: Model selection - mirrors native SelectCarsModelsBottomSheetFragment
class StepModelSelection extends StatefulWidget {
  final String brandName;
  final String? selectedModel;
  final ValueChanged<String> onModelSelected;

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
  final RepositoryApi _api = ApiClient.create();
  final TextEditingController _searchController = TextEditingController();

  List<String> _models = [];
  List<String> _filteredModels = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadModels();
  }

  @override
  void didUpdateWidget(StepModelSelection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.brandName != widget.brandName && widget.brandName.isNotEmpty) {
      _loadModels();
    }
  }

  Future<void> _loadModels() async {
    if (widget.brandName.isEmpty) return;

    setState(() => _isLoading = true);
    try {
      final models = await _api.getCarModels(widget.brandName.toLowerCase());
      if (mounted) {
        setState(() {
          _models = models;
          _filteredModels = models;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _models = [];
          _filteredModels = [];
          _isLoading = false;
        });
      }
    }
  }

  void _onSearchChanged(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredModels = _models;
      } else {
        _filteredModels = _models
            .where((m) => m.toLowerCase().contains(query.toLowerCase()))
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

    if (_models.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.info_outline, size: 48, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            Text(
              'No models found for ${widget.brandName}',
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: _loadModels,
              child: const Text('Retry'),
            ),
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
            onChanged: _onSearchChanged,
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
              final isSelected = widget.selectedModel == model;
              return ListTile(
                title: Text(
                  model,
                  style: TextStyle(
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
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
