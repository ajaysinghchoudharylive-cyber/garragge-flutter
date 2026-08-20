import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:carsbuzz/sellcar/models/sell_car_form_data.dart';
import 'package:carsbuzz/sellcar/repository/sell_car_repository.dart';
import 'package:carsbuzz/sellcar/steps/step_brand_selection.dart';
import 'package:carsbuzz/sellcar/steps/step_model_selection.dart';
import 'package:carsbuzz/sellcar/steps/step_variant_selection.dart';
import 'package:carsbuzz/sellcar/steps/step_color_selection.dart';
import 'package:carsbuzz/sellcar/steps/step_year_selection.dart';
import 'package:carsbuzz/sellcar/steps/step_price.dart';
import 'package:carsbuzz/sellcar/steps/step_km_driven.dart';
import 'package:carsbuzz/sellcar/steps/step_fuel_type.dart';
import 'package:carsbuzz/sellcar/steps/step_transmission.dart';
import 'package:carsbuzz/sellcar/steps/step_ownership.dart';
import 'package:carsbuzz/sellcar/steps/step_upload_images.dart';
import 'package:carsbuzz/sellcar/steps/step_additional_info.dart';

/// Complete Sell Car Wizard - mirrors native navigation flow:
/// SelectYourCarBrand → CarModel → CarVariant → Colors →
/// SellCarWizard(Price/Year/KM/Owner/Fuel/Transmission) →
/// UploadImages → AdditionalInfo → Submit
///
/// Uses SellCarFormData as the single source of truth (like native SelectDetailsPojoJava)
/// and SellCarRepository for all API interactions.
class SellCarWizardScreen extends StatefulWidget {
  const SellCarWizardScreen({super.key});

  @override
  State<SellCarWizardScreen> createState() => _SellCarWizardScreenState();
}

class _SellCarWizardScreenState extends State<SellCarWizardScreen> {
  final PageController _pageController = PageController();
  final SellCarRepository _repo = SellCarRepository();
  final SellCarFormData _formData = SellCarFormData();

  int _currentStep = 0;
  bool _isSubmitting = false;
  int? _remoteDraftId;

  // Steps in order matching native navigation graph
  static const List<_StepInfo> _steps = [
    _StepInfo('Select Brand', 'Brand', '1/10'),
    _StepInfo('Select Model', 'Model', '2/10'),
    _StepInfo('Select Variant', 'Variant', '3/10'),
    _StepInfo('Select Color', 'Color', '3/10'),
    _StepInfo('Expected Price', 'Price', '4/10'),
    _StepInfo('Manufacturing Year', 'Year', '5/10'),
    _StepInfo('Kilometers Driven', 'KM', '6/10'),
    _StepInfo('Ownership History', 'Owner', '7/10'),
    _StepInfo('Fuel Type', 'Fuel', '8/10'),
    _StepInfo('Transmission', 'Transmission', '9/10'),
    _StepInfo('Upload Photos', 'Photos', '10/10'),
    _StepInfo('Additional Info', 'Info', ''),
  ];

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  Future<void> _loadUserInfo() async {
    final prefs = await SharedPreferences.getInstance();
    _formData.userId = int.tryParse(prefs.getString('user_id') ?? '');
    _formData.phoneNumber = prefs.getString('phone_number');
    _formData.city = prefs.getString('city');
    _formData.state = prefs.getString('state');
    _formData.ownerName = prefs.getString('username');
  }

  void _goToStep(int step) {
    if (step < 0 || step >= _steps.length) return;
    setState(() => _currentStep = step);
    _pageController.animateToPage(
      step,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
    _syncDraft();
  }

  void _nextStep() => _goToStep(_currentStep + 1);

  void _previousStep() {
    if (_currentStep > 0) {
      _goToStep(_currentStep - 1);
    } else {
      Navigator.pop(context);
    }
  }

  /// Sync draft to server (mirrors native syncRemoteDraft)
  Future<void> _syncDraft() async {
    if (_formData.userId == null || _formData.userId == 0) return;

    if (_remoteDraftId == null) {
      final id = await _repo.createDraft(_formData.userId!, _formData);
      if (id != null) _remoteDraftId = id;
    } else {
      await _repo.updateDraft(_remoteDraftId!, _formData.userId!, _formData);
    }
  }

  /// Submit ad (mirrors native onSubmitCarDetails → AdUploadWorker)
  Future<void> _submitAd() async {
    setState(() => _isSubmitting = true);

    try {
      // Mark draft complete
      if (_remoteDraftId != null && _formData.userId != null) {
        await _repo.markDraftComplete(_remoteDraftId!, _formData.userId!);
      }

      // Post the ad with images
      final result = await _repo.postCarAd(_formData, _formData.imagePaths);

      if (mounted) {
        setState(() => _isSubmitting = false);
        if (result.success) {
          _showSuccessDialog();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(result.message)),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to post ad: $e')),
        );
      }
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 72),
            const SizedBox(height: 16),
            const Text(
              'Ad Posted Successfully!',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Your ${_formData.brandName ?? ''} ${_formData.modelName ?? ''} is now live.\nBuyers will start contacting you soon.',
              style: const TextStyle(color: Colors.grey, fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1A73E8),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Done',
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
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
          _steps[_currentStep].title,
          style: const TextStyle(
            color: Colors.black87,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          if (_steps[_currentStep].progress.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: Text(
                  _steps[_currentStep].progress,
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: LinearProgressIndicator(
            value: (_currentStep + 1) / _steps.length,
            backgroundColor: Colors.grey.shade200,
            valueColor:
                const AlwaysStoppedAnimation<Color>(Color(0xFF1A73E8)),
          ),
        ),
      ),
      body: Column(
        children: [
          // Summary chips (mirrors native chipGroupSummary in SellCarWizardFragment)
          if (_formData.summaryChips.isNotEmpty) _buildSummaryChips(),
          // Step content
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                // Step 0: Brand
                StepBrandSelection(
                  selectedBrand: _formData.brandName,
                  onBrandSelected: (brand) {
                    setState(() {
                      _formData.brandName = brand;
                      _formData.modelName = null;
                      _formData.variantName = null;
                      _formData.variantId = null;
                    });
                    _nextStep();
                  },
                ),
                // Step 1: Model
                StepModelSelection(
                  brandName: _formData.brandName ?? '',
                  selectedModel: _formData.modelName,
                  onModelSelected: (model) {
                    setState(() => _formData.modelName = model);
                    _nextStep();
                  },
                ),
                // Step 2: Variant
                StepVariantSelection(
                  brandName: _formData.brandName ?? '',
                  modelName: _formData.modelName ?? '',
                  selectedVariant: _formData.variantName,
                  onVariantSelected: (name, id, transmission, seating) {
                    setState(() {
                      _formData.variantName = name;
                      _formData.variantId = id;
                      if (transmission != null) {
                        _formData.transmission = transmission;
                      }
                      if (seating != null) {
                        _formData.seatingCapacity = seating;
                      }
                    });
                    _nextStep();
                  },
                  onSkip: _nextStep,
                ),
                // Step 3: Color
                StepColorSelection(
                  selectedColor: _formData.color,
                  onColorSelected: (color) {
                    setState(() => _formData.color = color);
                    _nextStep();
                  },
                  onSkip: _nextStep,
                ),
                // Step 4: Price
                StepPrice(
                  initialPrice: _formData.carPrice,
                  onPriceSubmitted: (price, owners) {
                    setState(() {
                      _formData.carPrice = price;
                      // owners type from price step is not used here
                    });
                    _nextStep();
                  },
                ),
                // Step 5: Year
                StepYearSelection(
                  selectedYear: _formData.registrationYear,
                  onYearSelected: (year) {
                    setState(() => _formData.registrationYear = year);
                    _nextStep();
                  },
                ),
                // Step 6: KM
                StepKmDriven(
                  initialValue: _formData.kmDriven,
                  onKmSubmitted: (km) {
                    setState(() => _formData.kmDriven = km);
                    _nextStep();
                  },
                ),
                // Step 7: Ownership
                StepOwnership(
                  selectedOwner: _formData.owner,
                  selectedType: _formData.ownersType,
                  onOwnerSelected: (owner, type) {
                    setState(() {
                      _formData.owner = owner;
                      _formData.ownersType = type;
                    });
                    _nextStep();
                  },
                ),
                // Step 8: Fuel
                StepFuelType(
                  selectedFuel: _formData.fuelType,
                  onFuelSelected: (fuel) {
                    setState(() => _formData.fuelType = fuel);
                    _nextStep();
                  },
                ),
                // Step 9: Transmission
                StepTransmission(
                  selectedTransmission: _formData.transmission,
                  onTransmissionSelected: (transmission) {
                    setState(() => _formData.transmission = transmission);
                    _nextStep();
                  },
                ),
                // Step 10: Upload Images
                StepUploadImages(
                  imageUrls: _formData.imagePaths,
                  isSubmitting: false,
                  onImagesChanged: (paths) {
                    setState(() => _formData.imagePaths = paths);
                  },
                  onSubmit: _nextStep,
                ),
                // Step 11: Additional Info & Final Submit
                StepAdditionalInfo(
                  formData: _formData,
                  isSubmitting: _isSubmitting,
                  onFieldChanged: () => setState(() {}),
                  onSubmit: _submitAd,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryChips() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: _formData.summaryChips.map((chip) {
            return Padding(
              padding: const EdgeInsets.only(right: 6),
              child: Chip(
                label: Text(chip, style: const TextStyle(fontSize: 11)),
                backgroundColor: const Color(0xFFE3F2FD),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(horizontal: 4),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _StepInfo {
  final String title;
  final String shortName;
  final String progress;

  const _StepInfo(this.title, this.shortName, this.progress);
}
