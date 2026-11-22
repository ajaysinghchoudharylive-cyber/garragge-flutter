import 'package:flutter/material.dart';
import 'package:carsbuzz/sellcar/models/sell_car_models.dart';

/// Step 4: Color selection - mirrors native FragmentColors.
///
/// When the chosen model/variant lists its available colours (e.g. "Everest White, Black"),
/// exactly those are offered; otherwise a generic palette is shown. "Other" lets the seller type
/// a colour that isn't listed (the ad then needs an RC photo, like the Android app).
class StepColorSelection extends StatelessWidget {
  final String? selectedColor;

  /// Colour names offered for the model/variant. Empty -> generic palette.
  final List<String> availableColors;
  final ValueChanged<String> onColorSelected;
  final VoidCallback onSkip;

  const StepColorSelection({
    super.key,
    this.selectedColor,
    this.availableColors = const [],
    required this.onColorSelected,
    required this.onSkip,
  });

  static const List<String> _genericColors = [
    'White',
    'Black',
    'Silver',
    'Grey',
    'Red',
    'Blue',
    'Brown',
    'Beige',
    'Green',
    'Orange',
    'Gold',
    'Yellow',
    'Purple',
    'Maroon',
    'Navy Blue',
  ];

  /// Best-effort swatch for a colour name (works for names like "Everest Green").
  static Color swatchFor(String name) {
    final n = name.toLowerCase();
    const table = <String, int>{
      'white': 0xFFFFFFFF,
      'pearl': 0xFFF5F5F5,
      'black': 0xFF212121,
      'silver': 0xFFC0C0C0,
      'grey': 0xFF808080,
      'gray': 0xFF808080,
      'magma': 0xFF616161,
      'red': 0xFFD32F2F,
      'crimson': 0xFFB71C1C,
      'maroon': 0xFF800000,
      'blue': 0xFF1976D2,
      'navy': 0xFF000080,
      'midnight': 0xFF191970,
      'brown': 0xFF5D4037,
      'bronze': 0xFFCD7F32,
      'beige': 0xFFF5F5DC,
      'champagne': 0xFFF7E7CE,
      'green': 0xFF388E3C,
      'lime': 0xFF9ACD32,
      'orange': 0xFFF57C00,
      'gold': 0xFFFFD700,
      'yellow': 0xFFFFEB3B,
      'purple': 0xFF7B1FA2,
      'lavender': 0xFFB39DDB,
      'magenta': 0xFFC2185B,
      'turquoise': 0xFF26C6DA,
      'terquise': 0xFF26C6DA,
    };
    for (final entry in table.entries) {
      if (n.contains(entry.key)) return Color(entry.value);
    }
    return const Color(0xFFE0E0E0);
  }

  List<String> get _options {
    final base = availableColors.isNotEmpty ? availableColors : _genericColors;
    final deduped = <String>[];
    for (final c in base) {
      if (c.toLowerCase() != kOtherOptionLabel.toLowerCase() &&
          !deduped.any((d) => d.toLowerCase() == c.toLowerCase())) {
        deduped.add(c);
      }
    }
    return [...deduped, kOtherOptionLabel];
  }

  @override
  Widget build(BuildContext context) {
    final options = _options;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Select the color of your car',
                style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
              ),
              const Spacer(),
              TextButton(onPressed: onSkip, child: const Text('Skip')),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                childAspectRatio: 0.8,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: options.length,
              itemBuilder: (context, index) {
                final name = options[index];
                final isSelected = selectedColor == name;
                final swatch = swatchFor(name);
                final checkColor =
                    swatch.computeLuminance() > 0.5 ? Colors.black : Colors.white;

                return GestureDetector(
                  onTap: () => onColorSelected(name),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? const Color(0xFF1A73E8)
                            : Colors.grey.shade300,
                        width: isSelected ? 2.5 : 1,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: swatch,
                            shape: BoxShape.circle,
                            border: Border.all(
                                color: Colors.grey.shade300, width: 1),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: isSelected
                              ? Icon(Icons.check, color: checkColor, size: 18)
                              : null,
                        ),
                        const SizedBox(height: 6),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 2),
                          child: Text(
                            name,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight:
                                  isSelected ? FontWeight.bold : FontWeight.w500,
                              color: isSelected
                                  ? const Color(0xFF1A73E8)
                                  : Colors.black87,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
