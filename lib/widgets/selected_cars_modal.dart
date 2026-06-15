import 'package:flutter/material.dart';
import 'package:carsbuzz/models/selected_car.dart';
import 'package:carsbuzz/repository/selected_cars_repo.dart';
import 'package:carsbuzz/screens/car_selection_screen.dart';

class SelectedCarsModal extends StatefulWidget {
  final List<SelectedCar> selectedCars;
  final int userId;
  final Function(SelectedCar) onPrimaryChanged;

  const SelectedCarsModal({
    super.key,
    required this.selectedCars,
    required this.userId,
    required this.onPrimaryChanged,
  });

  @override
  State<SelectedCarsModal> createState() => _SelectedCarsModalState();
}

class _SelectedCarsModalState extends State<SelectedCarsModal> {
  final SelectedCarsRepo _repo = SelectedCarsRepo();
  List<SelectedCar> _cars = [];
  bool _isUpdating = false;

  @override
  void initState() {
    super.initState();
    _cars = List.from(widget.selectedCars);
  }

  Future<void> _setPrimaryCar(SelectedCar targetCar) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Set primary car?'),
        content: Text(
            'Do you want to set ${targetCar.carName} as your primary car?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('NO')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('YES')),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isUpdating = true);

    final updatedCars = _cars.map((car) {
      return SelectedCar(
        carName: car.carName,
        carImage: car.carImage,
        primary: car.carName == targetCar.carName,
      );
    }).toList();

    final success = await _repo.updateSelectedCars(widget.userId, updatedCars);

    if (success) {
      setState(() => _cars = updatedCars);
      widget.onPrimaryChanged(targetCar);
    }

    setState(() => _isUpdating = false);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints:
          BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85),
      decoration: const BoxDecoration(
        color: Color(0xFFF5F6F8), // 🔥 light grey background like design
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 16, 10),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Select Your Car',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Container(
                  width: 29,
                  height: 29,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade400),
                    shape: BoxShape.circle,
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: () => Navigator.pop(context),
                    child: const Center(
                      child: Icon(
                        Icons.close,
                        size: 16, // adjust for better fit
                      ),
                    ),
                  ),
                )
              ],
            ),
          ),

          const Divider(height: 1),

          // List
          _cars.isEmpty
              ? const Padding(
                  padding: EdgeInsets.all(20),
                  child: Text("No cars"),
                )
              : ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _cars.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final car = _cars[index];
                    return _buildCarItem(car);
                  },
                ),

          // Button
          Padding(
            padding: const EdgeInsets.all(20),
            child: SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: () async {
                  Navigator.pop(context);
                  await showModalBottomSheet(
                    context: context,
                    isScrollControlled: true, // 🔥 important
                    backgroundColor: Colors.transparent,
                    builder: (context) {
                      return const CarSelectionScreen();
                    },
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black, // 🔥 dark navy
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                child: const Text(
                  'Add Another Car',
                  style: TextStyle(fontSize: 16, color: Colors.white),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCarItem(SelectedCar car) {
    return Container(
      color: car.primary
          ? const Color(0xFFE8EEF7) // 🔥 selected bluish background
          : Colors.transparent,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          Image.network(
            car.carImage,
            width: 70,
            height: 40,
            fit: BoxFit.contain,
          ),
          const SizedBox(width: 16),

          Expanded(
            child: Text(
              car.carName,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),

          // Custom Switch (like your design)
          GestureDetector(
            onTap: _isUpdating ? null : () => _setPrimaryCar(car),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 36,
              height: 18,
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                color: car.primary ? Colors.teal : Colors.grey.shade300,
              ),
              child: Align(
                alignment:
                    car.primary ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  width: 20,
                  height: 20,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
