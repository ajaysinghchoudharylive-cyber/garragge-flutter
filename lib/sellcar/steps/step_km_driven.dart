import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Step 4: KM Driven input - mirrors native FragmentSellCarKilometerDriven
class StepKmDriven extends StatefulWidget {
  final String? initialValue;
  final ValueChanged<String> onKmSubmitted;

  const StepKmDriven({
    super.key,
    this.initialValue,
    required this.onKmSubmitted,
  });

  @override
  State<StepKmDriven> createState() => _StepKmDrivenState();
}

class _StepKmDrivenState extends State<StepKmDriven> {
  late TextEditingController _controller;
  int? _selectedQuickValue;

  static const List<int> _quickOptions = [
    5000,
    10000,
    20000,
    30000,
    50000,
    75000,
    100000,
  ];

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue ?? '');
    if (widget.initialValue != null) {
      final val = int.tryParse(widget.initialValue!);
      if (_quickOptions.contains(val)) {
        _selectedQuickValue = val;
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _formatKm(int km) {
    if (km >= 100000) return '${km ~/ 100000} Lakh km';
    if (km >= 1000) return '${km ~/ 1000}k km';
    return '$km km';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'How many kilometers has your car driven?',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 20),

          // Text input
          TextField(
            controller: _controller,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: InputDecoration(
              hintText: 'Enter KM driven',
              suffixText: 'km',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFF1A73E8), width: 2),
              ),
            ),
            onChanged: (_) {
              setState(() => _selectedQuickValue = null);
            },
          ),

          const SizedBox(height: 24),

          Text(
            'Or select a range',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 12),

          // Quick options
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: _quickOptions.map((km) {
              final isSelected = _selectedQuickValue == km;
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedQuickValue = km;
                    _controller.text = km.toString();
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFF1A73E8)
                        : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected
                          ? const Color(0xFF1A73E8)
                          : Colors.grey.shade300,
                    ),
                  ),
                  child: Text(
                    _formatKm(km),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: isSelected ? Colors.white : Colors.black87,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),

          const Spacer(),

          // Continue button
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _controller.text.isNotEmpty
                  ? () => widget.onKmSubmitted(_controller.text)
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1A73E8),
                disabledBackgroundColor: Colors.grey.shade300,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Continue',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
