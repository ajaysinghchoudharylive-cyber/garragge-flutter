import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Step 7: Price & owners - mirrors native FragmentSellCarRecommendedPrice + FragmentNoOfOwnersSellCar
class StepPrice extends StatefulWidget {
  final String? initialPrice;
  final void Function(String price, String owners) onPriceSubmitted;

  const StepPrice({
    super.key,
    this.initialPrice,
    required this.onPriceSubmitted,
  });

  @override
  State<StepPrice> createState() => _StepPriceState();
}

class _StepPriceState extends State<StepPrice> {
  late TextEditingController _priceController;
  String _selectedOwner = '1st Owner';

  static const List<String> _ownerOptions = [
    '1st Owner',
    '2nd Owner',
    '3rd Owner',
    '4th Owner',
    '4+ Owner',
  ];

  @override
  void initState() {
    super.initState();
    _priceController = TextEditingController(text: widget.initialPrice ?? '');
  }

  @override
  void dispose() {
    _priceController.dispose();
    super.dispose();
  }

  String _formatPrice(String value) {
    final price = double.tryParse(value);
    if (price == null) return '';
    if (price >= 100000) {
      return '${(price / 100000).toStringAsFixed(2)} Lakh';
    }
    return value;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Set your asking price',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 20),

            // Price input
            TextField(
              controller: _priceController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'Enter price',
                prefixText: '\u20B9 ',
                prefixStyle: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                      color: Color(0xFF1A73E8), width: 2),
                ),
              ),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),

            if (_priceController.text.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                '\u20B9 ${_formatPrice(_priceController.text)}',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade600,
                ),
              ),
            ],

            const SizedBox(height: 32),

            // Number of owners
            Text(
              'Number of owners',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 12),

            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: _ownerOptions.map((owner) {
                final isSelected = _selectedOwner == owner;
                return GestureDetector(
                  onTap: () => setState(() => _selectedOwner = owner),
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
                      owner,
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

            const SizedBox(height: 40),

            // Continue button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _priceController.text.isNotEmpty
                    ? () => widget.onPriceSubmitted(
                          _priceController.text,
                          _selectedOwner,
                        )
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
      ),
    );
  }
}
