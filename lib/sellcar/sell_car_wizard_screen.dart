import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:carsbuzz/services/location_service.dart';
import 'package:carsbuzz/sellcar/models/sell_car_form_data.dart';
import 'package:carsbuzz/sellcar/models/sell_car_models.dart';
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

/// Complete Sell Car Wizard - mirrors the native flow:
/// Brand → Model → Variant → Colour → Price → Year → KM → Owner → Fuel → Transmission →
/// Photos → Additional info → Post.
///
/// [SellCarFormData] is the single source of truth (like native SelectDetailsPojoJava) and
/// [SellCarRepository] talks to the same live API as the Android app (JWT on every call).
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
  int _uploadProgress = 0;
  int? _remoteDraftId;
  bool _creatingDraft = false;

  static const int _stepVariant = 2;
  static const int _stepColor = 3;

  static const List<_StepInfo> _steps = [
    _StepInfo('Select Brand', '1/10'),
    _StepInfo('Select Model', '2/10'),
    _StepInfo('Select Variant', '3/10'),
    _StepInfo('Select Color', '3/10'),
    _StepInfo('Expected Price', '4/10'),
    _StepInfo('Manufacturing Year', '5/10'),
    _StepInfo('Kilometers Driven', '6/10'),
    _StepInfo('Ownership History', '7/10'),
    _StepInfo('Fuel Type', '8/10'),
    _StepInfo('Transmission', '9/10'),
    _StepInfo('Upload Photos', '10/10'),
    _StepInfo('Additional Info', ''),
  ];

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final prefs = await SharedPreferences.getInstance();
    _formData.userId = int.tryParse(prefs.getString('user_id') ?? '');
    _formData.phoneNumber = prefs.getString('phone_number');
    _formData.city = prefs.getString('city');
    _formData.state = prefs.getString('state');
    _formData.ownerName = prefs.getString('username');

    // Free-upload limit: if the user is already out of free ads, say so before they spend time
    // filling in the whole form (the server enforces it again when posting).
    final userId = _formData.userId;
    if (userId != null && userId > 0) {
      final status = await _repo.checkUploadStatus(userId);
      if (!status.canUpload && mounted) {
        await _showLimitReachedDialog(null);
        if (mounted) Navigator.pop(context);
      }
    }
  }

  // ── navigation ───────────────────────────────────────────────────────────────

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
    if (_isSubmitting) return;
    if (_currentStep > 0) {
      _goToStep(_currentStep - 1);
    } else {
      Navigator.pop(context);
    }
  }

  /// Best-effort draft sync (mirrors native syncRemoteDraft). Never blocks the wizard.
  Future<void> _syncDraft() async {
    final userId = _formData.userId;
    if (userId == null || userId == 0 || _formData.brandName == null) return;

    if (_remoteDraftId == null) {
      if (_creatingDraft) return;
      _creatingDraft = true;
      final id = await _repo.createDraft(userId, _formData);
      _creatingDraft = false;
      if (id != null) _remoteDraftId = id;
    } else {
      await _repo.updateDraft(_remoteDraftId!, userId, _formData);
    }
  }

  // ── step handlers ────────────────────────────────────────────────────────────

  void _onBrandSelected(String brand) {
    setState(() {
      if (_formData.brandName != brand) {
        // A different brand invalidates everything chosen after it.
        _formData.modelName = null;
        _formData.modelId = null;
        _formData.variantName = null;
        _formData.variantId = null;
        _formData.availableColors = [];
        _formData.color = null;
        _formData.bodyType = null;
        _formData.otherModel = false;
        _formData.otherVariant = false;
        _formData.otherColor = false;
        _formData.rcImagePath = null;
      }
      _formData.brandName = brand;
    });
    _nextStep();
  }

  Future<void> _onModelSelected(CarModelItem model) async {
    if (model.isOther) {
      final typed = await _askText(
        title: 'Your car model',
        hint: 'e.g. Swift ZXi',
        message:
            'Enter the model name. You will need to add a photo of your RC later so we can verify it.',
      );
      if (typed == null) return;
      setState(() {
        _formData.modelName = typed;
        _formData.modelId = null;
        _formData.otherModel = true;
        _formData.variantName = null;
        _formData.variantId = null;
        _formData.otherVariant = false;
        _formData.availableColors = [];
        _formData.color = null;
        _formData.otherColor = false;
      });
      _goToStep(_stepColor); // no variants exist for an unlisted model
      return;
    }

    setState(() {
      _formData.modelName = model.name;
      _formData.modelId = model.id;
      _formData.otherModel = false;
      _formData.variantName = null;
      _formData.variantId = null;
      _formData.otherVariant = false;
      _formData.availableColors = model.colorList;
      _formData.color = null;
      _formData.otherColor = false;
      // The model's own body type sets the ad's body type automatically.
      _formData.bodyType = bodyCodeForLabel(model.carBody) ?? _formData.bodyType;
    });
    _goToStep(_stepVariant);
  }

  Future<void> _onVariantSelected(CarVariantItem variant) async {
    if (variant.isOther) {
      final typed = await _askText(
        title: 'Your car variant',
        hint: 'e.g. VXi AMT',
        message:
            'Enter the variant name. You will need to add a photo of your RC later so we can verify it.',
      );
      if (typed == null) return;
      setState(() {
        _formData.variantName = typed;
        _formData.variantId = null;
        _formData.otherVariant = true;
      });
      _goToStep(_stepColor);
      return;
    }

    setState(() {
      _formData.variantName = variant.name;
      _formData.variantId = variant.id;
      _formData.otherVariant = false;

      final transmission = _normalizeTransmission(variant.resolvedTransmission);
      if (transmission != null) _formData.transmission = transmission;
      final fuel = _normalizeFuel(variant.resolvedFuelType);
      if (fuel != null) _formData.fuelType = fuel;
      final seats = variant.seatingCapacity;
      if (seats != null && seats.trim().isNotEmpty) {
        _formData.seatingCapacity = seats.trim();
      }
      final colors = (variant.availableColors ?? '')
          .split(',')
          .map((c) => c.trim())
          .where((c) => c.isNotEmpty)
          .toList();
      if (colors.isNotEmpty) _formData.availableColors = colors;
    });
    _goToStep(_stepColor);
  }

  Future<void> _onColorSelected(String color) async {
    if (color == kOtherOptionLabel) {
      final typed = await _askText(
        title: 'Your car colour',
        hint: 'e.g. Pearl Metallic Grey',
        message:
            'Enter the colour name. You will need to add a photo of your RC later so we can verify it.',
      );
      if (typed == null) return;
      setState(() {
        _formData.color = typed;
        _formData.otherColor = true;
      });
    } else {
      setState(() {
        _formData.color = color;
        _formData.otherColor = false;
      });
    }
    _nextStep();
  }

  /// Variant values like "6-Speed AMT" / "Petrol" mapped to the options the wizard offers.
  String? _normalizeTransmission(String? raw) {
    final v = (raw ?? '').trim().toLowerCase();
    if (v.isEmpty) return null;
    if (v.contains('semi') || v.contains('amt') || v.contains('imt')) {
      return 'Semi - Automatic';
    }
    if (v.contains('manual') || v == 'mt' || v.contains(' mt')) return 'Manual';
    if (v.contains('auto') ||
        v.contains('cvt') ||
        v.contains('dct') ||
        v.contains('dsg') ||
        v.contains('torque') ||
        v == 'at' ||
        v.contains(' at')) {
      return 'Automatic';
    }
    return null;
  }

  String? _normalizeFuel(String? raw) {
    final v = (raw ?? '').trim().toLowerCase();
    if (v.isEmpty) return null;
    if (v.contains('hybrid')) return 'Hybrid';
    if (v.contains('electric') || v == 'ev') return 'Electric';
    if (v.contains('diesel')) return 'Diesel';
    if (v.contains('cng')) return 'CNG';
    if (v.contains('lpg')) return 'LPG';
    if (v.contains('petrol') || v.contains('gasoline')) return 'Petrol';
    return null;
  }

  Future<String?> _askText({
    required String title,
    required String hint,
    String? message,
  }) async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (message != null) ...[
              Text(message, style: const TextStyle(fontSize: 13)),
              const SizedBox(height: 12),
            ],
            TextField(
              controller: controller,
              autofocus: true,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(hintText: hint),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final text = controller.text.trim();
              if (text.isNotEmpty) Navigator.pop(ctx, text);
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
    controller.dispose();
    return result;
  }

  // ── submit ───────────────────────────────────────────────────────────────────

  void _toast(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  /// The ad needs the coordinates: the server turns them into the city/state shown on the ad.
  Future<void> _ensureLocation() async {
    if (_formData.latitude != null && _formData.longitude != null) return;
    final position = await LocationService.getCurrentPosition();
    if (position != null) {
      _formData.latitude = position.latitude;
      _formData.longitude = position.longitude;
      _formData.fullAddress = await LocationService.getAddressFromCoordinates(
              position.latitude, position.longitude) ??
          '';
      return;
    }
    final saved = await LocationService.getSavedCurrentLocation();
    if (saved != null) {
      _formData.latitude = (saved['latitude'] as num?)?.toDouble();
      _formData.longitude = (saved['longitude'] as num?)?.toDouble();
      _formData.fullAddress = saved['address']?.toString() ?? '';
    }
  }

  Future<bool> _ensureOwnerName() async {
    if ((_formData.ownerName ?? '').trim().isNotEmpty) return true;
    final name = await _askText(
      title: 'Your name',
      hint: 'Full name',
      message: 'Buyers will see this name on your ad.',
    );
    if (name == null) return false;
    _formData.ownerName = name;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('username', name);
    return true;
  }

  Future<void> _submitAd() async {
    if (_isSubmitting) return;

    final userId = _formData.userId ?? 0;
    if (userId <= 0 || (_formData.phoneNumber ?? '').isEmpty) {
      _toast('Please log in again to post your ad.');
      return;
    }
    if (!_formData.isReadyToPost) {
      _toast('Some car details are missing. Please complete all steps.');
      return;
    }
    if (!_formData.hasMinimumImages) {
      _toast('Please add at least 6 photos.');
      return;
    }
    if (_formData.requiresRc && (_formData.rcImagePath ?? '').isEmpty) {
      _toast('Please add a photo of your RC.');
      return;
    }
    if (!await _ensureOwnerName()) return;

    setState(() {
      _isSubmitting = true;
      _uploadProgress = 0;
    });

    try {
      await _ensureLocation();

      final result = await _repo.postAd(
        _formData,
        draftId: _remoteDraftId,
        onProgress: (p) {
          if (mounted) setState(() => _uploadProgress = p);
        },
      );

      if (!mounted) return;
      setState(() => _isSubmitting = false);

      if (result.success) {
        _showSuccessDialog();
      } else if (result.isUploadLimitReached) {
        await _showLimitReachedDialog(result.message);
      } else {
        _toast(result.message);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      _toast('Failed to post ad: $e');
    }
  }

  Future<void> _showLimitReachedDialog(String? message) {
    return showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Upload limit reached'),
        content: Text(
          message ??
              "You've used your free car ads for this month. Upgrade to post more.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK'),
          ),
        ],
      ),
    );
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
              'Ad submitted!',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Your ${_formData.brandName ?? ''} ${_formData.modelName ?? ''} is now under review. '
              'Ads are reviewed within an hour, though some take longer.',
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
                child: const Text('Got it',
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

  // ── UI ───────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_isSubmitting,
      child: Scaffold(
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
        body: Stack(
          children: [
            Column(
              children: [
                if (_formData.summaryChips.isNotEmpty) _buildSummaryChips(),
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      // 0: Brand
                      StepBrandSelection(
                        selectedBrand: _formData.brandName,
                        onBrandSelected: _onBrandSelected,
                      ),
                      // 1: Model
                      StepModelSelection(
                        brandName: _formData.brandName ?? '',
                        selectedModel: _formData.modelName,
                        onModelSelected: _onModelSelected,
                      ),
                      // 2: Variant
                      StepVariantSelection(
                        brandName: _formData.brandName ?? '',
                        modelName: _formData.modelName ?? '',
                        modelId: _formData.modelId,
                        selectedVariant: _formData.variantName,
                        onVariantSelected: _onVariantSelected,
                        onSkip: () => _goToStep(_stepColor),
                      ),
                      // 3: Colour
                      StepColorSelection(
                        selectedColor: _formData.color,
                        availableColors: _formData.availableColors,
                        onColorSelected: _onColorSelected,
                        onSkip: _nextStep,
                      ),
                      // 4: Price
                      StepPrice(
                        initialPrice: _formData.carPrice,
                        onPriceSubmitted: (price, _) {
                          setState(() => _formData.carPrice = price);
                          _nextStep();
                        },
                      ),
                      // 5: Year
                      StepYearSelection(
                        selectedYear: _formData.registrationYear,
                        onYearSelected: (year) {
                          setState(() => _formData.registrationYear = year);
                          _nextStep();
                        },
                      ),
                      // 6: KM
                      StepKmDriven(
                        initialValue: _formData.kmDriven,
                        onKmSubmitted: (km) {
                          setState(() => _formData.kmDriven = km);
                          _nextStep();
                        },
                      ),
                      // 7: Ownership
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
                      // 8: Fuel
                      StepFuelType(
                        selectedFuel: _formData.fuelType,
                        onFuelSelected: (fuel) {
                          setState(() => _formData.fuelType = fuel);
                          _nextStep();
                        },
                      ),
                      // 9: Transmission
                      StepTransmission(
                        selectedTransmission: _formData.transmission,
                        onTransmissionSelected: (transmission) {
                          setState(() => _formData.transmission = transmission);
                          _nextStep();
                        },
                      ),
                      // 10: Photos (+ RC photo when an "Other" option was chosen)
                      StepUploadImages(
                        imageUrls: _formData.imagePaths,
                        isSubmitting: false,
                        requiresRc: _formData.requiresRc,
                        rcImagePath: _formData.rcImagePath,
                        onRcChanged: (path) =>
                            setState(() => _formData.rcImagePath = path),
                        onImagesChanged: (paths) {
                          setState(() => _formData.imagePaths = paths);
                        },
                        onSubmit: _nextStep,
                      ),
                      // 11: Additional info & final submit
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
            if (_isSubmitting) _buildUploadOverlay(),
          ],
        ),
      ),
    );
  }

  Widget _buildUploadOverlay() {
    return Positioned.fill(
      child: Container(
        color: Colors.black54,
        alignment: Alignment.center,
        child: Container(
          width: 260,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Uploading your ad',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              LinearProgressIndicator(
                value: _uploadProgress >= 100 || _uploadProgress == 0
                    ? null
                    : _uploadProgress / 100,
                minHeight: 6,
              ),
              const SizedBox(height: 12),
              Text(
                _uploadProgress >= 100
                    ? 'Finishing up...'
                    : 'Sending photos... $_uploadProgress%',
                style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
              ),
              const SizedBox(height: 4),
              Text(
                'Please keep the app open.',
                style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
              ),
            ],
          ),
        ),
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
  final String progress;

  const _StepInfo(this.title, this.progress);
}
