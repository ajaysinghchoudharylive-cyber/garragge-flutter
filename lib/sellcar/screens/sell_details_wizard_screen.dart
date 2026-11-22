import 'package:carsbuzz/sellcar/models/sell_car_models.dart';
import 'package:carsbuzz/sellcar/screens/sell_upload_photos_screen.dart';
import 'package:carsbuzz/sellcar/sell_car_flow.dart';
import 'package:carsbuzz/sellcar/widgets/sell_ui.dart';
import 'package:carsbuzz/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

enum _Step { year, km, color, owner, price }

/// Car details wizard, a port of the Android SellCarWizardFragment + SellCarStepFragment:
/// tabs Year, Kilometer, Color, Ownership, Price. Tapping a value only selects it; the "Next"
/// button moves exactly one tab. Next on Price opens photo upload.
class SellDetailsWizardScreen extends StatefulWidget {
  final SellCarFlow flow;

  const SellDetailsWizardScreen({super.key, required this.flow});

  @override
  State<SellDetailsWizardScreen> createState() => _SellDetailsWizardScreenState();
}

class _SellDetailsWizardScreenState extends State<SellDetailsWizardScreen>
    with SingleTickerProviderStateMixin {
  static const _tabTitles = ['Year', 'Kilometer', 'Color', 'Ownership', 'Price'];
  static const int _minPrice = 10000;

  static const _kmRanges = [
    '0 Km - 10,000 Km',
    '10,000 Km - 20,000 Km',
    '20,000 Km - 30,000 Km',
    '30,000 Km - 40,000 Km',
    '40,000 Km - 50,000 Km',
    '50,000 Km - 60,000 Km',
    '60,000 Km - 70,000 Km',
    '70,000 Km - 80,000 Km',
    '80,000 Km - 90,000 Km',
  ];

  static const _owners = [
    '1st owner',
    '2nd owner',
    '3rd owner',
    '4th owner',
    'Beyond 4th owner',
    'I am a car dealer',
  ];

  late final TabController _tabs;
  int _reached = 0;
  DateTime _lastNav = DateTime.fromMillisecondsSinceEpoch(0);

  final TextEditingController _priceController = TextEditingController();
  String? _priceError;
  String _colorQuery = '';

  SellCarFlow get _flow => widget.flow;

  @override
  void initState() {
    super.initState();
    final start = _allFilled ? _furthestFilled : 0;
    _reached = start;
    _tabs = TabController(length: _tabTitles.length, vsync: this, initialIndex: start);
    _tabs.addListener(() {
      if (mounted) setState(() {});
    });
    final price = _flow.form.carPrice;
    if (price != null) _priceController.text = price;
  }

  @override
  void dispose() {
    _tabs.dispose();
    _priceController.dispose();
    super.dispose();
  }

  // ── step state ─────────────────────────────────────────────────────────────────────────────

  bool _filled(_Step s) {
    final f = _flow.form;
    switch (s) {
      case _Step.year:
        return (f.registrationYear ?? 0) > 0;
      case _Step.km:
        return (f.kmDriven ?? '').isNotEmpty;
      case _Step.color:
        return (f.color ?? '').isNotEmpty || f.availableColors.isEmpty;
      case _Step.owner:
        return (f.owner ?? '').isNotEmpty;
      case _Step.price:
        return (f.carPrice ?? '').isNotEmpty;
    }
  }

  bool get _allFilled => _Step.values.every(_filled);

  int get _furthestFilled {
    var furthest = 0;
    for (var i = 0; i < _Step.values.length; i++) {
      if (_filled(_Step.values[i])) furthest = i;
    }
    return furthest;
  }

  /// A tab can be opened up to the furthest reached/filled step, never past the first gap.
  int get _maxTab {
    final firstGap = _Step.values.indexWhere((s) => !_filled(s));
    final reach = _reached > _furthestFilled ? _reached : _furthestFilled;
    if (firstGap < 0) return reach;
    return reach < firstGap ? reach : firstGap;
  }

  bool _debounced() {
    final now = DateTime.now();
    if (now.difference(_lastNav).inMilliseconds < 600) return true;
    _lastNav = now;
    return false;
  }

  void _next() {
    if (_debounced()) return;
    _flow.syncDraft();
    final i = _tabs.index + 1;
    if (i < _tabTitles.length) {
      _tabs.index = i;
      if (i > _reached) _reached = i;
      setState(() {});
    } else {
      Navigator.of(context).push(MaterialPageRoute(
        settings: const RouteSettings(name: SellRoutes.upload),
        builder: (_) => SellUploadPhotosScreen(flow: _flow),
      ));
    }
  }

  void _back() {
    if (_tabs.index > 0) {
      if (_debounced()) return;
      _tabs.index = _tabs.index - 1;
      setState(() {});
    } else {
      Navigator.of(context).pop();
    }
  }

  void _onSummaryTap(SummaryType type) {
    switch (type) {
      case SummaryType.brand:
        SellCarFlow.popTo(context, null);
        break;
      case SummaryType.model:
        SellCarFlow.popTo(context, SellRoutes.model);
        break;
      case SummaryType.variant:
      case SummaryType.fuel:
      case SummaryType.transmission:
        SellCarFlow.popTo(context, SellRoutes.variant);
        break;
      case SummaryType.year:
        _goTab(0);
        break;
      case SummaryType.km:
        _goTab(1);
        break;
      case SummaryType.color:
        _goTab(2);
        break;
      case SummaryType.owner:
        _goTab(3);
        break;
      case SummaryType.price:
        _goTab(4);
        break;
      case SummaryType.city:
        break;
    }
  }

  void _goTab(int i) {
    _tabs.index = i;
    setState(() {});
  }

  // ── UI ─────────────────────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _tabs.index == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _back();
      },
      child: Scaffold(
        backgroundColor: SellColors.pageBg,
        body: SafeArea(
          child: Column(
            children: [
              SellToolbar(titleSize: 16, onBack: _back),
              CarDetailsSummary(flow: _flow, onTap: _onSummaryTap),
              _tabBar(),
              Expanded(
                child: Container(
                  margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: _page(_Step.values[_tabs.index]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _tabBar() {
    final maxTab = _maxTab;
    return SizedBox(
      height: 48,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        itemCount: _tabTitles.length,
        itemBuilder: (_, i) {
          final selected = i == _tabs.index;
          final enabled = i <= maxTab;
          return InkWell(
            onTap: enabled ? () => _goTab(i) : null,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    _tabTitles[i],
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                      color: selected ? AppColors.accent : SellColors.brandsGray,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    height: 3,
                    width: 32,
                    decoration: BoxDecoration(
                      color: selected ? AppColors.accent : Colors.transparent,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _page(_Step step) {
    switch (step) {
      case _Step.year:
        final years = [for (var y = 2026; y >= 2010; y--) y.toString()];
        return _listPage(
          title: 'Select the car manufacturing year',
          counter: '4/9',
          items: years,
          selected: (_flow.form.registrationYear ?? 0) > 0
              ? _flow.form.registrationYear.toString()
              : null,
          onSelect: (v) => setState(() => _flow.form.registrationYear = int.parse(v)),
        );
      case _Step.km:
        return _listPage(
          title: 'Select kilometers driven',
          counter: '5/9',
          items: _kmRanges,
          selected: _flow.form.kmDriven,
          onSelect: (v) => setState(() => _flow.form.kmDriven = v),
        );
      case _Step.color:
        return _colorPage();
      case _Step.owner:
        return _listPage(
          title: 'Select the ownership history of your car',
          counter: '7/9',
          items: _owners,
          selected: _flow.form.owner,
          onSelect: (v) => setState(() {
            _flow.form.owner = v;
            _flow.form.ownersType = v == 'I am a car dealer' ? 'Dealer' : 'Individual';
          }),
        );
      case _Step.price:
        return _pricePage();
    }
  }

  Widget _header(String title, String counter) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(title,
                style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.w700, color: Colors.black)),
          ),
          const SizedBox(width: 16),
          Text(counter, style: const TextStyle(fontSize: 14, color: SellColors.apGray)),
          if (_allFilled) ...[
            const SizedBox(width: 8),
            // Fast-forward to photos once every step has a value (Android iv_fast_forward).
            InkWell(
              onTap: () => Navigator.of(context).push(MaterialPageRoute(
                settings: const RouteSettings(name: SellRoutes.upload),
                builder: (_) => SellUploadPhotosScreen(flow: _flow),
              )),
              child: const Padding(
                padding: EdgeInsets.all(4),
                child: Icon(Icons.arrow_forward, size: 24, color: AppColors.accent),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _withNext(
      {required Widget child, required bool showNext, Color? bg, VoidCallback? onNext}) {
    return Container(
      color: bg ?? Colors.white,
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
      child: Stack(
        children: [
          Positioned.fill(child: child),
          if (showNext)
            Positioned(right: 4, bottom: 16, child: SellNextFab(onPressed: onNext ?? _next)),
        ],
      ),
    );
  }

  Widget _listPage({
    required String title,
    required String counter,
    required List<String> items,
    required String? selected,
    required ValueChanged<String> onSelect,
  }) {
    return _withNext(
      showNext: selected != null && selected.isNotEmpty,
      child: Column(
        children: [
          _header(title, counter),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.only(top: 8, bottom: 96),
              itemCount: items.length,
              itemBuilder: (_, i) {
                final item = items[i];
                final isSelected = item == selected;
                return GestureDetector(
                  onTap: () => onSelect(item),
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0xFFF0FDF4) : SellColors.pageBg,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isSelected ? SellColors.green : SellColors.stroke,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Text(item,
                        style: const TextStyle(fontSize: 16, color: Colors.black)),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _colorPage() {
    final all = _flow.form.availableColors;
    if (all.isEmpty) {
      // No colour data for this model: nothing to pick, let the seller continue.
      return _withNext(
        showNext: true,
        child: Column(
          children: [_header('No colors available for this model', '6/9')],
        ),
      );
    }
    final q = _colorQuery.trim().toLowerCase();
    final colors = q.isEmpty
        ? all
        : all.where((c) => _fuzzy(c.name.toLowerCase(), q)).toList();
    final selected = _flow.form.color?.toLowerCase();

    return _withNext(
      bg: const Color(0xFFF5F5F7),
      showNext: (_flow.form.color ?? '').isNotEmpty,
      child: Column(
        children: [
          _header('Select car color', '6/9'),
          const SizedBox(height: 12),
          SellSearchBox(
            hint: 'Search color',
            onChanged: (v) => setState(() => _colorQuery = v),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: colors.isEmpty
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 24),
                      child: Text(
                        "This color isn't available for this model. Try a different color from the list.",
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
                      ),
                    ),
                  )
                : GridView.builder(
                    padding: const EdgeInsets.only(bottom: 96),
                    itemCount: colors.length,
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 4,
                      childAspectRatio: 0.85,
                    ),
                    itemBuilder: (_, i) =>
                        _colorCell(colors[i], colors[i].name.toLowerCase() == selected),
                  ),
          ),
        ],
      ),
    );
  }

  /// Subsequence match, so "mtlc gry" finds "Metallic Grey".
  bool _fuzzy(String text, String query) {
    if (text.contains(query)) return true;
    var i = 0;
    for (final ch in query.replaceAll(' ', '').split('')) {
      i = text.indexOf(ch, i);
      if (i < 0) return false;
      i++;
    }
    return true;
  }

  Widget _colorCell(ModelColor c, bool selected) {
    return GestureDetector(
      onTap: () => setState(() {
        _flow.form.color = c.name;
        _flow.form.otherColor = false;
      }),
      child: Container(
        margin: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? AppColors.accent : const Color(0xFFEAEAEA),
            width: selected ? 2 : 1,
          ),
          boxShadow: selected
              ? const [BoxShadow(color: Color(0x22000000), blurRadius: 4, offset: Offset(0, 1))]
              : null,
        ),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _Swatch(color: c),
                  const SizedBox(height: 8),
                  Text(c.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          fontSize: 10, fontWeight: FontWeight.w500, color: Colors.black)),
                ],
              ),
            ),
            if (selected)
              const Positioned(
                top: 4,
                right: 4,
                child: Icon(Icons.check_circle, size: 14, color: AppColors.accent),
              ),
          ],
        ),
      ),
    );
  }

  Widget _pricePage() {
    return _withNext(
      showNext: (_flow.form.carPrice ?? '').isNotEmpty,
      onNext: _submitPrice,
      child: SingleChildScrollView(
        child: Column(
          children: [
            _header('Expected Resale Value', '8/9'),
            const SizedBox(height: 40),
            TextField(
              controller: _priceController,
              keyboardType: TextInputType.number,
              inputFormatters: [_IndianNumberFormatter()],
              style: const TextStyle(fontSize: 16),
              decoration: InputDecoration(
                hintText: 'Price',
                prefixText: '₹ ',
                errorText: _priceError,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppColors.accent),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Colors.red),
                ),
                focusedErrorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Colors.red),
                ),
              ),
              onSubmitted: (_) => _submitPrice(),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _submitPrice,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Set Price',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _submitPrice() {
    final raw = _priceController.text.replaceAll(',', '').trim();
    final value = int.tryParse(raw);
    String? error;
    if (raw.isEmpty) {
      error = 'Please enter a price';
    } else if (value == null) {
      error = 'Please enter a valid price';
    } else if (value < _minPrice) {
      error = 'Price must be at least ₹10,000';
    }
    setState(() => _priceError = error);
    if (error != null) return;
    FocusScope.of(context).unfocus();
    _flow.form.carPrice = formatIndian(value!);
    _next();
  }
}

/// 36dp round swatch; dual-tone colours are split diagonally (Android adapter_colors_layout).
class _Swatch extends StatelessWidget {
  final ModelColor color;

  const _Swatch({required this.color});

  static Color? _parse(String? hex) {
    var h = (hex ?? '').trim().replaceAll('#', '');
    if (h.length == 6) h = 'FF$h';
    final v = int.tryParse(h, radix: 16);
    return (h.length == 8 && v != null) ? Color(v) : null;
  }

  @override
  Widget build(BuildContext context) {
    final c1 = _parse(color.code) ?? const Color(0xFFE5E7EB);
    final c2 = color.isDualTone ? _parse(color.code2) : null;
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFFD1D1D1), width: 0.5),
        color: c2 == null ? c1 : null,
        gradient: c2 == null
            ? null
            : LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [c1, c1, c2, c2],
                stops: const [0, 0.5, 0.5, 1],
              ),
      ),
    );
  }
}

/// "500000" -> "5,00,000" (Indian grouping, as the Android price field shows).
String formatIndian(int value) {
  final s = value.toString();
  if (s.length <= 3) return s;
  final last3 = s.substring(s.length - 3);
  var rest = s.substring(0, s.length - 3);
  final parts = <String>[];
  while (rest.length > 2) {
    parts.insert(0, rest.substring(rest.length - 2));
    rest = rest.substring(0, rest.length - 2);
  }
  if (rest.isNotEmpty) parts.insert(0, rest);
  return '${parts.join(',')},$last3';
}

/// Digits only, max 10, shown with Indian grouping.
class _IndianNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    var digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    if (digits.length > 10) digits = digits.substring(0, 10);
    if (digits.isEmpty) return const TextEditingValue(text: '');
    final text = formatIndian(int.parse(digits));
    return TextEditingValue(text: text, selection: TextSelection.collapsed(offset: text.length));
  }
}
