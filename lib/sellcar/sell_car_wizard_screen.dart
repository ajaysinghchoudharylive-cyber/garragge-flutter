import 'package:flutter/material.dart';
import 'package:carsbuzz/models/sell_car_request.dart';
import 'package:carsbuzz/network/api_client.dart';
import 'package:carsbuzz/network/repository_api.dart';
import 'package:carsbuzz/sellcar/steps/step_brand_selection.dart';
import 'package:carsbuzz/sellcar/steps/step_model_selection.dart';
import 'package:carsbuzz/sellcar/steps/step_year_selection.dart';
import 'package:carsbuzz/sellcar/steps/step_km_driven.dart';
import 'package:carsbuzz/sellcar/steps/step_fuel_type.dart';
import 'package:carsbuzz/sellcar/steps/step_transmission.dart';
import 'package:carsbuzz/sellcar/steps/step_price.dart';
import 'package:carsbuzz/sellcar/steps/step_upload_images.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Multi-step sell car wizard - mirrors native SellCarWizardFragment
/// Steps: Brand -> Model -> Year -> KM Driven -> Fuel -> Transmission -> Price -> Upload Images
class SellCarWizardScreen extends StatefulWidget {
  const SellCarWizardScreen({super.key});

  @override
  State<SellCarWizardScreen> createState() => _SellCarWizardScreenState();
}

class _SellCarWizardScreenState extends State<SellCarWizardScreen> {
  final PageController _pageController = PageController();
  final RepositoryApi _api = ApiClient.create();

  int _currentStep = 0;
  bool _isSubmitting = false;

  // Collected data from each step
  String? _selectedBrand;
  String? _selectedModel;
  String? _selectedVariant;
  int? _selectedYear;
  String? _kmDriven;
  String? _fuelType;
  String? _transmission;
  String? _price;
  String? _numberOfOwners;
  String? _color;
  String? _city;
  List<String> _imageUrls = [];

  static const List<String> _stepTitles = [
    'Select Brand',
    'Select Model',
    'Registration Year',
    'KM Driven',
    'Fuel Type',
    'Transmission',
    'Set Price',
    'Upload Photos',
  ];

  void _goToStep(int step) {
    setState(() => _currentStep = step);
    _pageController.animateToPage(
      step,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _nextStep() {
    if (_currentStep < _stepTitles.length - 1) {
      _goToStep(_currentStep + 1);
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      _goToStep(_currentStep - 1);
    } else {
      Navigator.pop(context);
    }
  }

  Future<void> _submitAd() async {
    setState(() => _isSubmitting = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = int.tryParse(prefs.getString('user_id') ?? '') ?? 0;
      final phone = prefs.getString('phone_number') ?? '';
      final city = _city ?? prefs.getString('city') ?? '';
      final state = prefs.getString('state') ?? '';

      final request = SellCarRequest(
        carMake: _selectedBrand ?? '',
        carModel: _selectedModel ?? '',
        variant: _selectedVariant,
        registrationYear: _selectedYear ?? DateTime.now().year,
        kmDriven: _kmDriven ?? '',
        price: _price ?? '',
        fuelType: _fuelType ?? '',
        transmission: _transmission ?? '',
        numberOfOwners: _numberOfOwners ?? '1st Owner',
        city: city,
        state: state,
        color: _color,
        userId: userId,
        phoneNumber: phone,
        images: _imageUrls.isNotEmpty ? _imageUrls : null,
      );

      await _api.postSellCar(request);

      if (mounted) {
        _showSuccessDialog();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to post ad: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 64),
            const SizedBox(height: 16),
            const Text(
              'Ad Posted Successfully!',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Your ${_selectedBrand ?? ''} ${_selectedModel ?? ''} ad is now live.',
              style: const TextStyle(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context); // close dialog
                  Navigator.pop(context); // go back to home
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1A73E8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text(
                  'Done',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryChips() {
    final details = <String>[
      if (_selectedBrand != null) _selectedBrand!,
      if (_selectedModel != null) _selectedModel!,
      if (_selectedVariant != null) _selectedVariant!,
      if (_selectedYear != null) _selectedYear.toString(),
      if (_kmDriven != null) '$_kmDriven km',
      if (_fuelType != null) _fuelType!,
      if (_transmission != null) _transmission!,
      if (_price != null) '\u20B9$_price',
    ];

    if (details.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Wrap(
        spacing: 6,
        runSpacing: 6,
        children: details.map((detail) {
          return Chip(
            label: Text(detail, style: const TextStyle(fontSize: 12)),
            backgroundColor: const Color(0xFFE3F2FD),
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            visualDensity: VisualDensity.compact,
          );
        }).toList(),
      ),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: _previousStep,
        ),
        title: Text(
          _stepTitles[_currentStep],
          style: const TextStyle(
            color: Colors.black87,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: LinearProgressIndicator(
            value: (_currentStep + 1) / _stepTitles.length,
            backgroundColor: Colors.grey.shade200,
            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF1A73E8)),
          ),
        ),
      ),
      body: Column(
        children: [
          _buildSummaryChips(),
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                StepBrandSelection(
                  selectedBrand: _selectedBrand,
                  onBrandSelected: (brand) {
                    setState(() {
                      _selectedBrand = brand;
                      _selectedModel = null;
                      _selectedVariant = null;
                    });
                    _nextStep();
                  },
                ),
                StepModelSelection(
                  brandName: _selectedBrand ?? '',
                  selectedModel: _selectedModel,
                  onModelSelected: (model) {
                    setState(() => _selectedModel = model);
                    _nextStep();
                  },
                ),
                StepYearSelection(
                  selectedYear: _selectedYear,
                  onYearSelected: (year) {
                    setState(() => _selectedYear = year);
                    _nextStep();
                  },
                ),
                StepKmDriven(
                  initialValue: _kmDriven,
                  onKmSubmitted: (km) {
                    setState(() => _kmDriven = km);
                    _nextStep();
                  },
                ),
                StepFuelType(
                  selectedFuel: _fuelType,
                  onFuelSelected: (fuel) {
                    setState(() => _fuelType = fuel);
                    _nextStep();
                  },
                ),
                StepTransmission(
                  selectedTransmission: _transmission,
                  onTransmissionSelected: (transmission) {
                    setState(() => _transmission = transmission);
                    _nextStep();
                  },
                ),
                StepPrice(
                  initialPrice: _price,
                  onPriceSubmitted: (price, owners) {
                    setState(() {
                      _price = price;
                      _numberOfOwners = owners;
                    });
                    _nextStep();
                  },
                ),
                StepUploadImages(
                  imageUrls: _imageUrls,
                  isSubmitting: _isSubmitting,
                  onImagesChanged: (urls) {
                    setState(() => _imageUrls = urls);
                  },
                  onSubmit: _submitAd,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
