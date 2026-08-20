import 'package:flutter/material.dart';

/// Step 4: Color selection - mirrors native FragmentColors
/// Shows a grid of car colors with visual swatches
class StepColorSelection extends StatelessWidget {
  final String? selectedColor;
  final ValueChanged<String> onColorSelected;
  final VoidCallback onSkip;

  const StepColorSelection({
    super.key,
    this.selectedColor,
    required this.onColorSelected,
    required this.onSkip,
  });

  static const List<_CarColor> _colors = [
    _CarColor('White', Color(0xFFFFFFFF), Colors.black),
    _CarColor('Black', Color(0xFF212121), Colors.white),
    _CarColor('Silver', Color(0xFFC0C0C0), Colors.black),
    _CarColor('Grey', Color(0xFF808080), Colors.white),
    _CarColor('Red', Color(0xFFD32F2F), Colors.white),
    _CarColor('Blue', Color(0xFF1976D2), Colors.white),
    _CarColor('Brown', Color(0xFF5D4037), Colors.white),
    _CarColor('Beige', Color(0xFFF5F5DC), Colors.black),
    _CarColor('Green', Color(0xFF388E3C), Colors.white),
    _CarColor('Orange', Color(0xFFF57C00), Colors.white),
    _CarColor('Gold', Color(0xFFFFD700), Colors.black),
    _CarColor('Yellow', Color(0xFFFFEB3B), Colors.black),
    _CarColor('Purple', Color(0xFF7B1FA2), Colors.white),
    _CarColor('Maroon', Color(0xFF800000), Colors.white),
    _CarColor('Navy Blue', Color(0xFF000080), Colors.white),
    _CarColor('Other', Color(0xFFE0E0E0), Colors.black),
  ];

  @override
  Widget build(BuildContext context) {
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
              TextButton(
                onPressed: onSkip,
                child: const Text('Skip'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                childAspectRatio: 0.85,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: _colors.length,
              itemBuilder: (context, index) {
                final color = _colors[index];
                final isSelected = selectedColor == color.name;

                return GestureDetector(
                  onTap: () => onColorSelected(color.name),
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
                            color: color.value,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.grey.shade300,
                              width: 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: isSelected
                              ? Icon(Icons.check,
                                  color: color.textColor, size: 18)
                              : null,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          color.name,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.w500,
                            color: isSelected
                                ? const Color(0xFF1A73E8)
                                : Colors.black87,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
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

class _CarColor {
  final String name;
  final Color value;
  final Color textColor;

  const _CarColor(this.name, this.value, this.textColor);
}
