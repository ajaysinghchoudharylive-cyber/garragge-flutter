import 'package:flutter/material.dart';

/// Step 5: Fuel type selection - mirrors native FragmentFuelTypeSellCar
class StepFuelType extends StatelessWidget {
  final String? selectedFuel;
  final ValueChanged<String> onFuelSelected;

  const StepFuelType({
    super.key,
    this.selectedFuel,
    required this.onFuelSelected,
  });

  static const List<Map<String, dynamic>> _fuelTypes = [
    {'name': 'Petrol', 'icon': Icons.local_gas_station},
    {'name': 'Diesel', 'icon': Icons.local_gas_station},
    {'name': 'CNG', 'icon': Icons.propane_tank},
    {'name': 'Electric', 'icon': Icons.electric_car},
    {'name': 'Hybrid', 'icon': Icons.eco},
    {'name': 'LPG', 'icon': Icons.propane},
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Select fuel type of your car',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 2.2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: _fuelTypes.length,
              itemBuilder: (context, index) {
                final fuel = _fuelTypes[index];
                final name = fuel['name'] as String;
                final icon = fuel['icon'] as IconData;
                final isSelected = selectedFuel == name;

                return GestureDetector(
                  onTap: () => onFuelSelected(name),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFFE3F2FD)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? const Color(0xFF1A73E8)
                            : Colors.grey.shade300,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          icon,
                          color: isSelected
                              ? const Color(0xFF1A73E8)
                              : Colors.grey.shade600,
                          size: 24,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          name,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: isSelected
                                ? const Color(0xFF1A73E8)
                                : Colors.black87,
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
