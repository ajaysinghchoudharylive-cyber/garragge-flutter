import 'package:flutter/material.dart';
import 'package:carsbuzz/sellcar/models/sell_car_form_data.dart';

/// Final step: Additional vehicle info checklist + submit
/// Mirrors native FragmentAdditionalInformation
/// Collects: insurance, registration, battery, tyre, brakes, service, loan, puc, challan
class StepAdditionalInfo extends StatelessWidget {
  final SellCarFormData formData;
  final bool isSubmitting;
  final VoidCallback onFieldChanged;
  final VoidCallback onSubmit;

  const StepAdditionalInfo({
    super.key,
    required this.formData,
    required this.isSubmitting,
    required this.onFieldChanged,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Vehicle Condition Checklist',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            'This helps buyers make informed decisions (optional)',
            style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 20),

          // Insurance
          _ChecklistDropdown(
            label: 'Insurance',
            icon: Icons.security,
            value: formData.insurance,
            options: const ['Comprehensive', 'Third Party', 'Zero Dep', 'Expired', 'Not Available'],
            onChanged: (val) {
              formData.insurance = val;
              onFieldChanged();
            },
          ),

          // Battery
          _ChecklistDropdown(
            label: 'Battery Condition',
            icon: Icons.battery_full,
            value: formData.battery,
            options: const ['Good', 'Average', 'Poor', 'Replaced Recently'],
            onChanged: (val) {
              formData.battery = val;
              onFieldChanged();
            },
          ),

          // Tyre
          _ChecklistDropdown(
            label: 'Tyre Condition',
            icon: Icons.trip_origin,
            value: formData.tyre,
            options: const ['Good', 'Average', 'Needs Replacement'],
            onChanged: (val) {
              formData.tyre = val;
              onFieldChanged();
            },
          ),

          // Brakes
          _ChecklistDropdown(
            label: 'Brakes',
            icon: Icons.disc_full,
            value: formData.brakes,
            options: const ['Good', 'Average', 'Needs Service'],
            onChanged: (val) {
              formData.brakes = val;
              onFieldChanged();
            },
          ),

          // Service History
          _ChecklistDropdown(
            label: 'Service History',
            icon: Icons.build,
            value: formData.service,
            options: const ['Regular Service', 'Irregular Service', 'No Service Records'],
            onChanged: (val) {
              formData.service = val;
              onFieldChanged();
            },
          ),

          // Loan
          _ChecklistDropdown(
            label: 'Loan on Car',
            icon: Icons.account_balance,
            value: formData.loan,
            options: const ['Yes', 'No'],
            onChanged: (val) {
              formData.loan = val;
              onFieldChanged();
            },
          ),

          // PUC
          _ChecklistDropdown(
            label: 'PUC Certificate',
            icon: Icons.description,
            value: formData.puc,
            options: const ['Valid', 'Expired', 'Not Available'],
            onChanged: (val) {
              formData.puc = val;
              onFieldChanged();
            },
          ),

          // Challan
          _ChecklistDropdown(
            label: 'Pending Challans',
            icon: Icons.gavel,
            value: formData.challan,
            options: const ['No Challans', 'Yes, pending'],
            onChanged: (val) {
              formData.challan = val;
              onFieldChanged();
            },
          ),

          const SizedBox(height: 24),

          // Summary card
          _buildSummaryCard(),

          const SizedBox(height: 20),

          // Submit button
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: isSubmitting ? null : onSubmit,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade600,
                disabledBackgroundColor: Colors.grey.shade300,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
              ),
              child: isSubmitting
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.publish, color: Colors.white),
                        SizedBox(width: 8),
                        Text(
                          'Post Your Ad',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
            ),
          ),

          const SizedBox(height: 16),

          // Disclaimer
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.grey.shade600, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'By posting, you agree to our Terms & Conditions. Incorrect information may lead to ad removal.',
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildSummaryCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F9FF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFBBDEFB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.directions_car, color: Color(0xFF1A73E8), size: 20),
              SizedBox(width: 8),
              Text(
                'Ad Summary',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A73E8),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _summaryRow('Car', '${formData.brandName ?? ''} ${formData.modelName ?? ''}'.trim()),
          if (formData.variantName != null)
            _summaryRow('Variant', formData.variantName!),
          if (formData.registrationYear != null)
            _summaryRow('Year', formData.registrationYear.toString()),
          if (formData.carPrice != null)
            _summaryRow('Price', '\u20B9${formData.carPrice}'),
          if (formData.kmDriven != null)
            _summaryRow('KM Driven', formData.kmDriven!),
          if (formData.fuelType != null)
            _summaryRow('Fuel', formData.fuelType!),
          if (formData.transmission != null)
            _summaryRow('Transmission', formData.transmission!),
          if (formData.owner != null)
            _summaryRow('Owner', formData.owner!),
          if (formData.color != null)
            _summaryRow('Color', formData.color!),
          _summaryRow('Photos', '${formData.imagePaths.length} uploaded'),
        ],
      ),
    );
  }

  Widget _summaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChecklistDropdown extends StatelessWidget {
  final String label;
  final IconData icon;
  final String? value;
  final List<String> options;
  final ValueChanged<String?> onChanged;

  const _ChecklistDropdown({
    required this.label,
    required this.icon,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: value != null ? const Color(0xFF1A73E8) : Colors.grey.shade300,
          ),
          color: value != null ? const Color(0xFFF5F9FF) : Colors.white,
        ),
        child: Row(
          children: [
            Icon(icon,
                size: 20,
                color: value != null
                    ? const Color(0xFF1A73E8)
                    : Colors.grey.shade500),
            const SizedBox(width: 10),
            Expanded(
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: value,
                  hint: Text(label,
                      style: TextStyle(
                          fontSize: 14, color: Colors.grey.shade600)),
                  isExpanded: true,
                  icon: Icon(Icons.keyboard_arrow_down,
                      color: Colors.grey.shade500),
                  items: options
                      .map((opt) => DropdownMenuItem(
                            value: opt,
                            child: Text(opt, style: const TextStyle(fontSize: 14)),
                          ))
                      .toList(),
                  onChanged: onChanged,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
