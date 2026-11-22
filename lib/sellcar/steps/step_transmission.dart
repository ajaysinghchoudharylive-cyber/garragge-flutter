import 'package:flutter/material.dart';

/// Step 6: Transmission selection - mirrors native FragmentTransmissionSellCar
class StepTransmission extends StatelessWidget {
  final String? selectedTransmission;
  final ValueChanged<String> onTransmissionSelected;

  const StepTransmission({
    super.key,
    this.selectedTransmission,
    required this.onTransmissionSelected,
  });

  static const List<Map<String, dynamic>> _transmissionTypes = [
    {
      'name': 'Manual',
      'icon': Icons.settings,
      'description': 'Manual gearbox',
    },
    {
      'name': 'Automatic',
      'icon': Icons.auto_mode,
      'description': 'Automatic transmission',
    },
    {
      'name': 'Semi - Automatic',
      'icon': Icons.tune,
      'description': 'Clutch-less manual (AMT / iMT)',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Select transmission type',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 24),
          ..._transmissionTypes.map((item) {
            final name = item['name'] as String;
            final icon = item['icon'] as IconData;
            final description = item['description'] as String;
            final isSelected = selectedTransmission == name;

            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: GestureDetector(
                onTap: () => onTransmissionSelected(name),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFFE3F2FD)
                        : Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isSelected
                          ? const Color(0xFF1A73E8)
                          : Colors.grey.shade300,
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xFF1A73E8).withOpacity(0.1)
                              : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          icon,
                          color: isSelected
                              ? const Color(0xFF1A73E8)
                              : Colors.grey.shade600,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: isSelected
                                    ? const Color(0xFF1A73E8)
                                    : Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              description,
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (isSelected)
                        const Icon(
                          Icons.check_circle,
                          color: Color(0xFF1A73E8),
                          size: 24,
                        ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
