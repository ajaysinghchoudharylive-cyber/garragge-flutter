import 'package:flutter/material.dart';

/// Step 8: Ownership selection - mirrors native FragmentNoOfOwnersSellCar
/// Includes number of owners AND owner type (Individual/Dealer)
class StepOwnership extends StatefulWidget {
  final String? selectedOwner;
  final String? selectedType;
  final void Function(String owner, String type) onOwnerSelected;

  const StepOwnership({
    super.key,
    this.selectedOwner,
    this.selectedType,
    required this.onOwnerSelected,
  });

  @override
  State<StepOwnership> createState() => _StepOwnershipState();
}

class _StepOwnershipState extends State<StepOwnership> {
  String? _selectedOwner;
  String _selectedType = 'Individual';

  static const List<String> _ownerOptions = [
    '1st owner',
    '2nd owner',
    '3rd owner',
    '4th owner',
    'Beyond 4th owner',
  ];

  @override
  void initState() {
    super.initState();
    _selectedOwner = widget.selectedOwner;
    _selectedType = widget.selectedType ?? 'Individual';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Select the ownership history of your car',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 20),

          // Owner count options
          Expanded(
            child: ListView.separated(
              itemCount: _ownerOptions.length + 1, // +1 for dealer option
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                if (index < _ownerOptions.length) {
                  final owner = _ownerOptions[index];
                  final isSelected = _selectedOwner == owner;
                  return _OwnerOptionTile(
                    label: owner,
                    isSelected: isSelected,
                    onTap: () {
                      setState(() {
                        _selectedOwner = owner;
                        _selectedType = 'Individual';
                      });
                      widget.onOwnerSelected(owner, 'Individual');
                    },
                  );
                } else {
                  // Dealer option
                  final isSelected = _selectedType == 'Dealer';
                  return _OwnerOptionTile(
                    label: 'I am a car dealer',
                    isSelected: isSelected,
                    icon: Icons.store,
                    onTap: () {
                      setState(() {
                        _selectedOwner = '1st owner';
                        _selectedType = 'Dealer';
                      });
                      widget.onOwnerSelected('1st owner', 'Dealer');
                    },
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _OwnerOptionTile extends StatelessWidget {
  final String label;
  final bool isSelected;
  final IconData? icon;
  final VoidCallback onTap;

  const _OwnerOptionTile({
    required this.label,
    required this.isSelected,
    this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFE3F2FD) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF1A73E8)
                : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            if (icon != null) ...[
              Icon(icon,
                  color: isSelected
                      ? const Color(0xFF1A73E8)
                      : Colors.grey.shade600,
                  size: 22),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isSelected
                      ? const Color(0xFF1A73E8)
                      : Colors.black87,
                ),
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle,
                  color: Color(0xFF1A73E8), size: 22),
          ],
        ),
      ),
    );
  }
}
