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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('NO', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('YES', style: TextStyle(color: Colors.blue)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isUpdating = true);

    try {
      final updatedCars = _cars.map((car) {
        return SelectedCar(
          carName: car.carName,
          carImage: car.carImage,
          primary: car.carName == targetCar.carName,
        );
      }).toList();

      final success =
          await _repo.updateSelectedCars(widget.userId, updatedCars);

      if (success) {
        setState(() => _cars = updatedCars);
        widget.onPrimaryChanged(targetCar);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.white),
                  const SizedBox(width: 8),
                  Expanded(
                      child: Text('${targetCar.carName} set as primary car')),
                ],
              ),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating primary car: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isUpdating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.9,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min, // ✅ wrap content
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Select Your Car',
                    style:
                        TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.close, color: Colors.grey),
                  ),
                ),
              ],
            ),
          ),

          // Car list
          _cars.isEmpty
              ? Padding(
                  padding: const EdgeInsets.symmetric(vertical: 40),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(Icons.directions_car,
                          size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        'No cars selected',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Add your first car to get started',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  itemCount: _cars.length,
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
              height: 50,
              child: ElevatedButton(
                onPressed: () async {
                  Navigator.pop(context);
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const CarSelectionScreen(),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
                child: const Text(
                  'Add Another Car',
                  style:
                      TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
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
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: car.primary ? Colors.blue.shade50 : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: car.primary ? Colors.blue : Colors.grey.shade300,
          width: car.primary ? 2 : 1,
        ),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              car.carImage,
              width: 60,
              height: 40,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                width: 60,
                height: 40,
                color: Colors.grey.shade200,
                child: const Icon(Icons.directions_car, color: Colors.grey),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              car.carName,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: car.primary ? Colors.blue : Colors.black87,
              ),
            ),
          ),
          GestureDetector(
            onTap: _isUpdating ? null : () => _setPrimaryCar(car),
            child: Icon(
              car.primary ? Icons.check_circle : Icons.radio_button_unchecked,
              color: car.primary ? Colors.green : Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
}