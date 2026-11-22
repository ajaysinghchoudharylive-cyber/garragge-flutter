import 'package:flutter/material.dart';
import 'package:carsbuzz/sellcar/repository/sell_car_repository.dart';

/// Step: Registration year - mirrors native SelectRegistrationYearFragment.
/// Years come from GET cars/carsRegistrationsYears (falls back to the last 25 years).
class StepYearSelection extends StatefulWidget {
  final int? selectedYear;
  final ValueChanged<int> onYearSelected;

  const StepYearSelection({
    super.key,
    this.selectedYear,
    required this.onYearSelected,
  });

  @override
  State<StepYearSelection> createState() => _StepYearSelectionState();
}

class _StepYearSelectionState extends State<StepYearSelection> {
  final SellCarRepository _repo = SellCarRepository();
  List<int> _years = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final years = await _repo.getRegistrationYears();
    if (!mounted) return;
    setState(() {
      _years = years;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Select the year of registration',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
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
                final isSelected = widget.selectedYear == year;
                return GestureDetector(
                  onTap: () => widget.onYearSelected(year),
                  child: Container(
                    decoration: BoxDecoration(
                      color:
                          isSelected ? const Color(0xFF1A73E8) : Colors.white,
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
