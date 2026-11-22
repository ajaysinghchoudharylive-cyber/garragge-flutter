import 'package:carsbuzz/sellcar/models/sell_car_models.dart';
import 'package:carsbuzz/sellcar/screens/sell_details_wizard_screen.dart';
import 'package:carsbuzz/sellcar/screens/sell_upload_photos_screen.dart';
import 'package:carsbuzz/sellcar/sell_car_flow.dart';
import 'package:carsbuzz/sellcar/widgets/sell_ui.dart';
import 'package:flutter/material.dart';

/// Variant picker, a port of the Android SelectCarsVariantsBottomSheetFragment
/// (fragment_select_your_variant.xml + adapter_variant_selection_layout.xml).
class SellVariantScreen extends StatefulWidget {
  final SellCarFlow flow;

  const SellVariantScreen({super.key, required this.flow});

  @override
  State<SellVariantScreen> createState() => _SellVariantScreenState();
}

class _SellVariantScreenState extends State<SellVariantScreen> {
  static const _categories = ['Automatic', 'Manual', 'Petrol', 'Diesel', 'CNG'];
  static const _darkGreen = Color(0xFF2E7D32);

  List<CarVariantItem> _variants = [];
  final Map<int, Set<String>> _tags = {};
  final Set<String> _filters = {};
  bool _loading = true;
  bool _error = false;

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
      final list = await _flow.repo
          .getVariants(_flow.form.brandName ?? '', _flow.form.modelId ?? 0);
      if (!mounted) return;
      _tags
        ..clear()
        ..addEntries(list.map((v) => MapEntry(v.id, _tagsOf(v))));
      setState(() {
        _variants = list;
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

  /// Same keyword rules as Android matchesCategory().
  Set<String> _tagsOf(CarVariantItem v) {
    final t = (v.resolvedTransmission ?? '').toLowerCase();
    final f = (v.resolvedFuelType ?? '').toLowerCase();
    return <String>{
      if (['automatic', 'amt', 'cvt', 'dct', 'at', 'dsg'].any(t.contains)) 'Automatic',
      if (t.contains('manual') || t.contains('mt')) 'Manual',
      if (f.contains('petrol') || f.contains('gasoline')) 'Petrol',
      if (f.contains('diesel')) 'Diesel',
      if (f.contains('cng')) 'CNG',
    };
  }

  List<String> get _availableFilters {
    final all = _tags.values.expand((s) => s).toSet();
    return _categories.where(all.contains).toList()..sort();
  }

  /// Transmission filters OR'd, fuel filters OR'd, the two groups AND'd (Android applyFilters).
  List<CarVariantItem> get _filtered {
    if (_filters.isEmpty) return _variants;
    final trans = _filters.where((f) => f == 'Automatic' || f == 'Manual').toList();
    final fuel = _filters.where((f) => f == 'Petrol' || f == 'Diesel' || f == 'CNG').toList();
    return _variants.where((v) {
      if (v.isOther) return true;
      final tags = _tags[v.id] ?? const <String>{};
      final okT = trans.isEmpty || trans.any(tags.contains);
      final okF = fuel.isEmpty || fuel.any(tags.contains);
      return okT && okF;
    }).toList();
  }

  Future<void> _onVariantTap(CarVariantItem v) async {
    if (v.isOther || v.name.toLowerCase() == kOtherOptionLabel.toLowerCase()) {
      final typed = await askSellText(
        context,
        title: 'Your car variant',
        hint: 'e.g. VXi AMT',
        message:
            'Enter the variant name. You will need to add a photo of your RC so we can verify it.',
      );
      if (typed == null || !mounted) return;
      _flow.selectOtherVariant(typed);
      _flow.syncDraft();
      await Navigator.of(context).push(MaterialPageRoute(
        settings: const RouteSettings(name: SellRoutes.upload),
        builder: (_) => SellUploadPhotosScreen(flow: _flow),
      ));
    } else {
      _flow.selectVariant(v);
      _flow.syncDraft();
      await Navigator.of(context).push(MaterialPageRoute(
        settings: const RouteSettings(name: SellRoutes.wizard),
        builder: (_) => SellDetailsWizardScreen(flow: _flow),
      ));
    }
    if (mounted) setState(() {});
  }

  void _onSummaryTap(SummaryType type) {
    switch (type) {
      case SummaryType.brand:
        SellCarFlow.popTo(context, null);
        break;
      case SummaryType.model:
        Navigator.of(context).pop();
        break;
      default:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final filters = _availableFilters;
    final items = _filtered;
    return Scaffold(
      backgroundColor: SellColors.pageBg,
      body: SafeArea(
        child: Column(
          children: [
            const SellToolbar(),
            CarDetailsSummary(flow: _flow, onTap: _onSummaryTap, background: Colors.white),
            Container(
              color: Colors.white,
              height: 12,
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 20, 16, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Text('Choose the variant that suits you',
                        style: TextStyle(fontSize: 14, color: SellColors.brandsGray)),
                  ),
                  Text('3/8', style: TextStyle(fontSize: 14, color: SellColors.apGray)),
                ],
              ),
            ),
            if (filters.isNotEmpty)
              SizedBox(
                height: 48,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  children: [
                    for (final f in filters)
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: _filterChip(f),
                      ),
                  ],
                ),
              ),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _error
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text('Could not load variants',
                                  style: TextStyle(color: SellColors.slate500)),
                              TextButton(onPressed: _load, child: const Text('Retry')),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _load,
                          child: ListView.builder(
                            padding: const EdgeInsets.fromLTRB(8, 8, 8, 16),
                            itemCount: items.length,
                            itemBuilder: (_, i) => _variantCard(items[i]),
                          ),
                        ),
            ),
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, size: 20, color: SellColors.brandsGray),
                  SizedBox(width: 12),
                  Text('2WD: Two Wheel Drive',
                      style: TextStyle(fontSize: 12, color: SellColors.brandsGray)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _filterChip(String label) {
    final selected = _filters.contains(label);
    return GestureDetector(
      onTap: () => setState(() {
        if (selected) {
          _filters.remove(label);
        } else {
          _filters.add(label);
        }
      }),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? SellColors.green : Colors.transparent,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: SellColors.green),
        ),
        child: Text(label,
            style: TextStyle(
                fontSize: 13, color: selected ? Colors.white : SellColors.green)),
      ),
    );
  }

  Widget _variantCard(CarVariantItem v) {
    final isOther = v.isOther;
    final selected = _flow.form.variantId == v.id && !isOther;
    final transmission = SellCarFlow.normalizeTransmission(v.resolvedTransmission) ??
        v.resolvedTransmission;
    final fuel = SellCarFlow.normalizeFuel(v.resolvedFuelType) ?? v.resolvedFuelType;

    Widget spec(IconData icon, String? value, String label) {
      return Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration:
                const BoxDecoration(color: Color(0xFFF1F8E9), shape: BoxShape.circle),
            child: Icon(icon, size: 18, color: _darkGreen),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text((value == null || value.isEmpty || value == 'null') ? '-' : value,
                  style: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w500, color: Colors.black)),
              Text(label, style: const TextStyle(fontSize: 10, color: SellColors.brandsGray)),
            ],
          ),
        ],
      );
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      color: Colors.white,
      surfaceTintColor: Colors.white,
      elevation: 4,
      shadowColor: Colors.black26,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: selected ? const BorderSide(color: SellColors.green, width: 2) : BorderSide.none,
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _onVariantTap(v),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.check_circle, size: 24, color: _darkGreen),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(v.name,
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w700, color: Colors.black)),
                  ),
                  const Icon(Icons.chevron_right, size: 20, color: SellColors.brandsGray),
                ],
              ),
              if (!isOther) ...[
                const SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.only(left: 24),
                  child: Row(
                    children: [
                      Expanded(child: spec(Icons.settings_outlined, transmission, 'Transmission')),
                      Expanded(child: spec(Icons.local_gas_station_outlined, fuel, 'Fuel')),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
