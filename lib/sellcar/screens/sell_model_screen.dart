import 'package:carsbuzz/sellcar/models/sell_car_models.dart';
import 'package:carsbuzz/sellcar/screens/sell_upload_photos_screen.dart';
import 'package:carsbuzz/sellcar/screens/sell_variant_screen.dart';
import 'package:carsbuzz/sellcar/sell_car_flow.dart';
import 'package:carsbuzz/sellcar/widgets/sell_ui.dart';
import 'package:flutter/material.dart';

/// Model picker, a port of the Android SelectCarsModelsBottomSheetFragment
/// (fragment_select_your_brand.xml + SelectYourModelMainAdapter): "Your Car Details" chips,
/// title "Select the model of your car" 2/9, search, POPULAR MODELS (first 4, 2 per row, with
/// image) and OTHER MODELS (the rest, 3 per row, text only).
class SellModelScreen extends StatefulWidget {
  final SellCarFlow flow;

  const SellModelScreen({super.key, required this.flow});

  @override
  State<SellModelScreen> createState() => _SellModelScreenState();
}

class _SellModelScreenState extends State<SellModelScreen> {
  List<CarModelItem> _models = [];
  bool _loading = true;
  bool _error = false;
  String _query = '';

  SellCarFlow get _flow => widget.flow;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = false;
    });
    try {
      final models = await _flow.repo.getModels(_flow.form.brandName ?? '');
      if (!mounted) return;
      setState(() {
        _models = models;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = true;
      });
    }
  }

  /// Selected model first so it always shows under POPULAR MODELS (Android orderedModels()).
  List<CarModelItem> get _visible {
    final q = _query.trim().toLowerCase();
    if (q.isNotEmpty) {
      return _models.where((m) => m.name.toLowerCase().contains(q)).toList();
    }
    final selected = _flow.form.modelName;
    final index = _models.indexWhere(
        (m) => selected != null && m.name.toLowerCase() == selected.toLowerCase());
    if (index < 4) return _models;
    return [_models[index], ..._models.where((m) => m != _models[index])];
  }

  Future<void> _onModelTap(CarModelItem model) async {
    if (model.isOther || model.name.toLowerCase() == kOtherOptionLabel.toLowerCase()) {
      final typed = await askSellText(
        context,
        title: 'Your car model',
        hint: 'e.g. Swift ZXi',
        message:
            'Enter the model name. You will need to add a photo of your RC so we can verify it.',
      );
      if (typed == null || !mounted) return;
      _flow.selectOtherModel(typed);
      _flow.syncDraft();
      // Android: an unlisted model skips variant and details and goes straight to photos + RC.
      await Navigator.of(context).push(MaterialPageRoute(
        settings: const RouteSettings(name: SellRoutes.upload),
        builder: (_) => SellUploadPhotosScreen(flow: _flow),
      ));
    } else {
      _flow.selectModel(model);
      _flow.syncDraft();
      await Navigator.of(context).push(MaterialPageRoute(
        settings: const RouteSettings(name: SellRoutes.variant),
        builder: (_) => SellVariantScreen(flow: _flow),
      ));
    }
    if (mounted) setState(() {});
  }

  void _onSummaryTap(SummaryType type) {
    if (type == SummaryType.brand) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final visible = _visible;
    final popular = visible.take(4).toList();
    final other = visible.length > 4 ? visible.sublist(4) : <CarModelItem>[];
    final selected = _flow.form.modelName?.toLowerCase();

    return Scaffold(
      backgroundColor: SellColors.pageBg,
      body: SafeArea(
        child: Column(
          children: [
            const SellToolbar(),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _load,
                child: ListView(
                  padding: const EdgeInsets.only(bottom: 24),
                  children: [
                    CarDetailsSummary(flow: _flow, onTap: _onSummaryTap),
                    const Padding(
                      padding: EdgeInsets.fromLTRB(16, 20, 16, 0),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text('Select the model of your car',
                                style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.black)),
                          ),
                          Text('2/9',
                              style: TextStyle(fontSize: 14, color: SellColors.apGray)),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                      child: SellSearchBox(
                        hint: 'Search your car model',
                        onChanged: (v) => setState(() => _query = v),
                      ),
                    ),
                    if (_loading)
                      const Padding(
                        padding: EdgeInsets.all(40),
                        child: Center(child: CircularProgressIndicator()),
                      )
                    else if (_error)
                      Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          children: [
                            const Text('Could not load models',
                                style: TextStyle(color: SellColors.slate500)),
                            TextButton(onPressed: _load, child: const Text('Retry')),
                          ],
                        ),
                      )
                    else if (visible.isEmpty && _query.isNotEmpty)
                      const Padding(
                        padding: EdgeInsets.all(32),
                        child: Text('No models found. Try a different search.',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 14, color: SellColors.apGray)),
                      )
                    else ...[
                      if (popular.isNotEmpty) ...[
                        _label('POPULAR MODELS'),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            padding: EdgeInsets.zero,
                            itemCount: popular.length,
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              childAspectRatio: 1.05,
                            ),
                            itemBuilder: (_, i) => _popularCell(
                                popular[i], popular[i].name.toLowerCase() == selected),
                          ),
                        ),
                      ],
                      if (other.isNotEmpty) ...[
                        _label('OTHER MODELS'),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            padding: EdgeInsets.zero,
                            itemCount: other.length,
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 3,
                              mainAxisExtent: 56,
                            ),
                            itemBuilder: (_, i) =>
                                _otherCell(other[i], other[i].name.toLowerCase() == selected),
                          ),
                        ),
                      ],
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
        child: Text(text, style: const TextStyle(fontSize: 14, color: SellColors.apGray)),
      );

  Widget _popularCell(CarModelItem m, bool selected) {
    return GestureDetector(
      onTap: () => _onModelTap(m),
      child: Container(
        margin: const EdgeInsets.all(8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected ? SellColors.green : SellColors.stroke,
            width: selected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Expanded(
              child: m.imageUrl == null || m.imageUrl!.isEmpty
                  ? const Icon(Icons.directions_car, size: 48, color: Colors.black26)
                  : Image.network(m.imageUrl!,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) =>
                          const Icon(Icons.directions_car, size: 48, color: Colors.black26)),
            ),
            const SizedBox(height: 12),
            Text(m.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 14, color: Colors.black)),
          ],
        ),
      ),
    );
  }

  Widget _otherCell(CarModelItem m, bool selected) {
    return GestureDetector(
      onTap: () => _onModelTap(m),
      child: Container(
        margin: const EdgeInsets.all(4),
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFF0FDF4) : SellColors.pageBg,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: selected ? SellColors.green : SellColors.stroke,
            width: selected ? 2 : 1,
          ),
        ),
        child: Text(m.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13, color: Colors.black)),
      ),
    );
  }
}
