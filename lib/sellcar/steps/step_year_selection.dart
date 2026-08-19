import 'package:flutter/material.dart';

/// Step 3: Registration year selection - mirrors native SelectRegistrationYearFragment
class StepYearSelection extends StatelessWidget {
  final int? selectedYear;
  final ValueChanged<int> onYearSelected;

  const StepYearSelection({
    super.key,
    this.selectedYear,
    required this.onYearSelected,
  });

  List<int> get _years {
    final currentYear = DateTime.now().year;
    return List.generate(25, (i) => currentYear - i);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Select the year of registration',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                childAspectRatio: 2.0,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              itemCount: _years.length,
              itemBuilder: (context, index) {
                final year = _years[index];
                final isSelected = selectedYear == year;
                return GestureDetector(
                  onTap: () => onYearSelected(year),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFF1A73E8)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isSelected
                            ? const Color(0xFF1A73E8)
                            : Colors.grey.shade300,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      year.toString(),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isSelected ? Colors.white : Colors.black87,
                      ),
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
