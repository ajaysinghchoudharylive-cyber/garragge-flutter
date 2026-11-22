import 'dart:math' as math;

import 'package:carsbuzz/theme/app_colors.dart';
import 'package:flutter/material.dart';

/// Filters picked on the card, handed to the Buy listing.
class FindCarsSelection {
  final String? minPrice; // rupees
  final String? maxPrice; // rupees, null = no upper limit
  final String? bodyType;
  final String? fuelType;
  final String? transmission;

  const FindCarsSelection({
    this.minPrice,
    this.maxPrice,
    this.bodyType,
    this.fuelType,
    this.transmission,
  });
}

/// "Find The Cars Of Your Choice" card, a port of the Android dashboard_find_used_car_layout.xml
/// (tabs Budget / Body Type / Fuel Type / Transmission).
class FindCarsCard extends StatefulWidget {
  final ValueChanged<FindCarsSelection> onExplore;

  const FindCarsCard({super.key, required this.onExplore});

  @override
  State<FindCarsCard> createState() => _FindCarsCardState();
}

class _ChoiceItem {
  final String label;
  final IconData icon;
  const _ChoiceItem(this.label, this.icon);
}

class _Chip {
  final String label;
  final double min;
  final double max;
  const _Chip(this.label, this.min, this.max);
}

class _FindCarsCardState extends State<FindCarsCard> {
  static const double _maxLakh = 30;

  static const _tabs = ['Budget', 'Body Type', 'Fuel Type', 'Transmission'];

  static const _chips = [
    _Chip('Any', 0, 30),
    _Chip('< ₹5 Lakh', 0, 5),
    _Chip('₹5 Lakh - ₹10 Lakh', 5, 10),
    _Chip('₹10 Lakh - ₹15 Lakh', 10, 15),
    _Chip('₹15 Lakh - ₹20 Lakh', 15, 20),
    _Chip('₹20 Lakh+', 20, 30),
  ];

  static const _bodyItems = [
    _ChoiceItem('Hatchback', Icons.directions_car),
    _ChoiceItem('Sedan', Icons.directions_car_filled),
    _ChoiceItem('SUV', Icons.airport_shuttle),
    _ChoiceItem('Compact SUV', Icons.airport_shuttle),
    _ChoiceItem('Luxury', Icons.directions_car_filled),
    _ChoiceItem('Convertible', Icons.directions_car),
    _ChoiceItem('Sports', Icons.directions_car_filled),
    _ChoiceItem('Limo', Icons.directions_car_filled),
    _ChoiceItem('MUV', Icons.airport_shuttle),
    _ChoiceItem('Minivan', Icons.airport_shuttle),
  ];

  static const _fuelItems = [
    _ChoiceItem('Petrol', Icons.local_gas_station),
    _ChoiceItem('Diesel', Icons.oil_barrel),
    _ChoiceItem('CNG', Icons.propane_tank),
    _ChoiceItem('Electric', Icons.ev_station),
    _ChoiceItem('LPG', Icons.propane),
    _ChoiceItem('Hybrid', Icons.eco),
  ];

  static const _transmissionItems = [
    _ChoiceItem('Automatic', Icons.settings),
    _ChoiceItem('Manual', Icons.tune),
  ];

  int _tab = 0;
  RangeValues _range = const RangeValues(5, 18);
  int? _selectedChip = 2; // "₹5 Lakh - ₹10 Lakh" looks selected on first show, as on Android
  bool _showTip = false;
  bool _includeHigher = true;
  String? _body;
  String? _fuel;
  String? _transmission;

  /// Utilities.calculateEMI: 80% loan, 9.5% a year, 5 years.
  String _emiText(double maxLakh) {
    final price = maxLakh.round() * 100000;
    if (price <= 0) return '₹0 /mo*';
    final p = price * 0.8;
    const r = 9.5 / 12 / 100;
    const n = 60;
    final pow = math.pow(1 + r, n).toDouble();
    final emi = pow <= 1 ? p / n : p * r * pow / (pow - 1);
    return '₹${_groupThousands(emi.round())} /mo*';
  }

  String _groupThousands(int v) {
    final s = v.toString();
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
      buf.write(s[i]);
    }
    return buf.toString();
  }

  void _explore() {
    switch (_tab) {
      case 0:
        final min = _range.start.round();
        final max = _range.end.round();
        widget.onExplore(FindCarsSelection(
          minPrice: (min * 100000).toString(),
          // Top of the slider = "30L+" = no upper limit.
          maxPrice: max >= _maxLakh ? null : (max * 100000).toString(),
        ));
        break;
      case 1:
        widget.onExplore(FindCarsSelection(bodyType: _body));
        break;
      case 2:
        widget.onExplore(FindCarsSelection(fuelType: _fuel));
        break;
      default:
        widget.onExplore(FindCarsSelection(transmission: _transmission));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Text(
              'Find The Cars Of Your Choice',
              style: TextStyle(fontSize: 16, color: AppColors.slate900),
            ),
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: List.generate(_tabs.length, (i) {
                final selected = i == _tab;
                return Padding(
                  padding: EdgeInsets.only(right: i < _tabs.length - 1 ? 20 : 0),
                  child: InkWell(
                    onTap: () => setState(() => _tab = i),
                    child: IntrinsicWidth(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Text(
                              _tabs[i],
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 14,
                                color: selected ? AppColors.tabBlue : AppColors.slate500,
                              ),
                            ),
                          ),
                          Container(
                            height: 3,
                            color: selected ? AppColors.tabBlue : Colors.transparent,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
          Container(
            margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            decoration: BoxDecoration(
              color: AppColors.slate50,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.dividerGrey),
            ),
            child: AnimatedSize(
              duration: const Duration(milliseconds: 200),
              child: switch (_tab) {
                0 => _buildBudget(),
                1 => _buildGrid(_bodyItems, 4, _body, (v) => setState(() => _body = v)),
                2 => _buildGrid(_fuelItems, 4, _fuel, (v) => setState(() => _fuel = v)),
                _ => _buildGrid(_transmissionItems, 2, _transmission,
                    (v) => setState(() => _transmission = v)),
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBudget() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text("What's your budget?",
                  style: TextStyle(fontSize: 18, color: AppColors.slate900)),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => setState(() => _showTip = !_showTip),
                child: const Icon(Icons.info_outline, size: 20, color: AppColors.slate500),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text('Select the range that suits you',
              style: TextStyle(fontSize: 13, color: AppColors.slate500)),
          if (_showTip) ...[
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFECFDF5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'Tip: A used car priced 15-20% below original usually offers the best value. Aim for a 20% down payment to keep EMI low.',
                style: TextStyle(fontSize: 12, color: Color(0xFF065F46)),
              ),
            ),
          ],
          const SizedBox(height: 16),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: List.generate(_chips.length, (i) {
                final selected = _selectedChip == i;
                return Padding(
                  padding: EdgeInsets.only(right: i < _chips.length - 1 ? 8 : 0),
                  child: GestureDetector(
                    onTap: () => setState(() {
                      _selectedChip = i;
                      _range = RangeValues(_chips[i].min, _chips[i].max);
                    }),
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: i == 0 ? 20 : 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: selected ? AppColors.chipBlue : AppColors.slate50,
                        borderRadius: BorderRadius.circular(20),
                        border: selected ? null : Border.all(color: AppColors.slate200),
                      ),
                      child: Text(
                        _chips[i].label,
                        style: TextStyle(
                          fontSize: 13,
                          color: selected ? Colors.white : AppColors.slate600,
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 24),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 6,
              activeTrackColor: AppColors.chipBlue,
              inactiveTrackColor: AppColors.slate200,
              thumbColor: Colors.white,
              overlayColor: Colors.transparent,
              rangeThumbShape: const _OutlinedThumb(),
              showValueIndicator: ShowValueIndicator.never,
            ),
            child: RangeSlider(
              min: 0,
              max: _maxLakh,
              values: _range,
              onChanged: (v) => setState(() {
                _range = v;
                _selectedChip = null; // moving by hand clears the chip selection
              }),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: LayoutBuilder(builder: (context, c) {
              const labels = ['₹0', '₹5L', '₹10L', '₹15L', '₹20L', '₹30L+'];
              const stops = [0.0, 0.166, 0.333, 0.5, 0.666, 1.0];
              return SizedBox(
                height: 18,
                child: Stack(
                  children: List.generate(labels.length, (i) {
                    final x = c.maxWidth * stops[i];
                    return Positioned(
                      left: i == 0 ? 0 : null,
                      right: i == labels.length - 1 ? 0 : null,
                      child: i == 0 || i == labels.length - 1
                          ? Text(labels[i], style: _scaleStyle)
                          : Transform.translate(
                              offset: Offset(x - 14, 0),
                              child: Text(labels[i], style: _scaleStyle),
                            ),
                    );
                  }),
                ),
              );
            }),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(child: _budgetBox('Minimum Budget', _range.start.round())),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 10),
                child: Text('—', style: TextStyle(fontSize: 18, color: AppColors.slate500)),
              ),
              Expanded(child: _budgetBox('Maximum Budget', _range.end.round())),
            ],
          ),
          const SizedBox(height: 14),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: _infoCard(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.calculate_outlined,
                            size: 22, color: AppColors.chipBlue),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('EMI starts at',
                                  style: TextStyle(fontSize: 11, color: AppColors.slate600)),
                              Text(_emiText(_range.end),
                                  style: const TextStyle(
                                      fontSize: 15, color: AppColors.chipBlue)),
                              const Text('For selected range',
                                  style: TextStyle(fontSize: 10, color: AppColors.slate500)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _infoCard(
                    child: Row(
                      children: [
                        SizedBox(
                          width: 22,
                          height: 22,
                          child: Checkbox(
                            value: _includeHigher,
                            activeColor: AppColors.chipBlue,
                            onChanged: (v) => setState(() => _includeHigher = v ?? false),
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Expanded(
                          child: Text('Include higher price',
                              style: TextStyle(fontSize: 12, color: AppColors.slate900)),
                        ),
                        GestureDetector(
                          onTap: _showWhyHigherPrice,
                          child: const Icon(Icons.info_outline,
                              size: 18, color: AppColors.slate500),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _exploreButton(),
        ],
      ),
    );
  }

  static const _scaleStyle = TextStyle(fontSize: 12, color: AppColors.slate600);

  void _showWhyHigherPrice() {
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => const Padding(
        padding: EdgeInsets.fromLTRB(24, 24, 24, 32),
        child: Text(
          'Include higher price also shows cars priced a little above your maximum budget, '
          'so you do not miss good deals that are open to negotiation.',
          style: TextStyle(fontSize: 14, color: AppColors.slate600),
        ),
      ),
    );
  }

  Widget _budgetBox(String label, int lakh) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.slate200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 11, color: AppColors.slate500)),
          const SizedBox(height: 2),
          Row(
            children: [
              Expanded(
                child: Text('₹$lakh Lakh',
                    style: const TextStyle(fontSize: 16, color: AppColors.slate900)),
              ),
              const Icon(Icons.arrow_drop_down, size: 20, color: AppColors.slate500),
            ],
          ),
        ],
      ),
    );
  }

  Widget _infoCard({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFDBEAFE)),
      ),
      child: child,
    );
  }

  Widget _buildGrid(List<_ChoiceItem> items, int columns, String? selected,
      ValueChanged<String?> onSelect) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: items.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: columns,
              childAspectRatio: columns == 2 ? 1.6 : 0.95,
            ),
            itemBuilder: (context, i) {
              final item = items[i];
              final isSelected = item.label == selected;
              return GestureDetector(
                onTap: () => onSelect(isSelected ? null : item.label),
                child: Container(
                  margin: const EdgeInsets.all(3),
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFFEFF6FF) : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? AppColors.tabBlue : AppColors.dividerGrey,
                    ),
                  ),
                  child: Stack(
                    children: [
                      Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 38,
                              height: 38,
                              decoration: const BoxDecoration(
                                color: Color(0xFFEFF6FF),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(item.icon, size: 20, color: AppColors.tabBlue),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              item.label,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 11, color: Colors.black),
                            ),
                          ],
                        ),
                      ),
                      if (isSelected)
                        const Positioned(
                          top: 0,
                          right: 0,
                          child: Icon(Icons.check_circle, size: 16, color: AppColors.tabBlue),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          _exploreButton(),
        ],
      ),
    );
  }

  Widget _exploreButton() {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton.icon(
        onPressed: _explore,
        icon: const Icon(Icons.search, color: Colors.white),
        label: const Text('Explore Cars',
            style: TextStyle(fontSize: 16, color: Colors.white)),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.chipBlue,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
        ),
      ),
    );
  }
}

/// White thumb, radius 10, 3dp #0066FF outline (Android RangeSlider style).
class _OutlinedThumb extends RangeSliderThumbShape {
  const _OutlinedThumb();

  @override
  Size getPreferredSize(bool isEnabled, bool isDiscrete) => const Size(20, 20);

  @override
  void paint(
    PaintingContext context,
    Offset center, {
    required Animation<double> activationAnimation,
    required Animation<double> enableAnimation,
    bool isDiscrete = false,
    bool isEnabled = false,
    bool? isOnTop,
    required SliderThemeData sliderTheme,
    TextDirection? textDirection,
    Thumb? thumb,
    bool? isPressed,
  }) {
    final canvas = context.canvas;
    canvas.drawCircle(center + const Offset(0, 1), 10,
        Paint()..color = Colors.black.withValues(alpha: 0.12));
    canvas.drawCircle(center, 10, Paint()..color = Colors.white);
    canvas.drawCircle(
      center,
      8.5,
      Paint()
        ..color = AppColors.chipBlue
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );
  }
}
