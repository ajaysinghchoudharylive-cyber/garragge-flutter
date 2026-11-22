import 'package:carsbuzz/sellcar/models/sell_car_form_data.dart';
import 'package:carsbuzz/sellcar/models/sell_car_models.dart';
import 'package:carsbuzz/sellcar/repository/sell_car_repository.dart';
import 'package:carsbuzz/services/location_service.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Route names of the sell screens, so a "Your Car Details" chip can pop back to the screen that
/// edits that value (Android: popBackStack(navigation_car_model) etc.).
class SellRoutes {
  SellRoutes._();
  static const String model = 'sell/model';
  static const String variant = 'sell/variant';
  static const String wizard = 'sell/wizard';
  static const String upload = 'sell/upload';
  static const String checklist = 'sell/checklist';
}

/// What a summary chip shows (Android SellCarWizardFragment.updateSummary types).
enum SummaryType { brand, model, variant, city, year, km, color, price, fuel, transmission, owner }

/// State shared by all sell screens for one ad (Android: the SelectDetailsPojoJava singleton +
/// SelectYourCarBrandViewModel). Created by the brand screen and passed down.
class SellCarFlow {
  final SellCarRepository repo = SellCarRepository();
  final SellCarFormData form = SellCarFormData();
  int? remoteDraftId;
  bool _creatingDraft = false;

  /// Set once the ad is posted; the brand screen then starts a fresh flow.
  bool posted = false;

  /// Loads the logged-in seller's identity from the saved session.
  Future<void> loadUser() async {
    final prefs = await SharedPreferences.getInstance();
    form.userId = int.tryParse(prefs.getString('user_id') ?? '');
    form.phoneNumber = prefs.getString('phone_number');
    form.city = prefs.getString('city');
    form.state = prefs.getString('state');
    form.ownerName = prefs.getString('username');
  }

  /// Starts a fresh ad for [brand]. Picking a different brand clears everything after it.
  void selectBrand(String brand) {
    if (form.brandName != brand || form.rcShortcut) _resetAd();
    form.brandName = brand;
  }

  /// Clears the ad but keeps who is selling it.
  void _resetAd() {
    final userId = form.userId;
    final phone = form.phoneNumber;
    final city = form.city;
    final state = form.state;
    final name = form.ownerName;
    form.clear();
    form.userId = userId;
    form.phoneNumber = phone;
    form.city = city;
    form.state = state;
    form.ownerName = name;
    remoteDraftId = null;
  }

  /// "Upload RC & Continue": no car details, only photos + RC.
  void startRcShortcut(String rcPath) {
    _resetAd();
    form.rcShortcut = true;
    form.rcImagePath = rcPath;
  }

  void selectModel(CarModelItem model) {
    form.modelName = model.name;
    form.modelId = model.id;
    form.otherModel = false;
    form.variantName = null;
    form.variantId = null;
    form.otherVariant = false;
    form.availableColors = model.colors;
    if (!model.colors.any((c) => c.name.toLowerCase() == (form.color ?? '').toLowerCase())) {
      form.color = null;
    }
    form.otherColor = false;
    form.bodyType = bodyCodeForLabel(model.carBody) ?? form.bodyType;
  }

  void selectOtherModel(String typedName) {
    form.modelName = typedName;
    form.modelId = null;
    form.otherModel = true;
    form.variantName = null;
    form.variantId = null;
    form.otherVariant = false;
    form.availableColors = [];
  }

  void selectVariant(CarVariantItem variant) {
    form.variantName = variant.name;
    form.variantId = variant.id;
    form.otherVariant = false;
    final transmission = normalizeTransmission(variant.resolvedTransmission);
    if (transmission != null) form.transmission = transmission;
    final fuel = normalizeFuel(variant.resolvedFuelType);
    if (fuel != null) form.fuelType = fuel;
    final seats = variant.seatingCapacity;
    if (seats != null && seats.trim().isNotEmpty) form.seatingCapacity = seats.trim();
  }

  void selectOtherVariant(String typedName) {
    form.variantName = typedName;
    form.variantId = null;
    form.otherVariant = true;
  }

  /// Best-effort draft sync (Android syncRemoteDraft). Never blocks the flow.
  Future<void> syncDraft() async {
    final userId = form.userId;
    if (userId == null || userId == 0 || form.brandName == null) return;
    if (remoteDraftId == null) {
      if (_creatingDraft) return;
      _creatingDraft = true;
      final id = await repo.createDraft(userId, form);
      _creatingDraft = false;
      if (id != null) remoteDraftId = id;
    } else {
      await repo.updateDraft(remoteDraftId!, userId, form);
    }
  }

  /// The server turns the coordinates into the city/state shown on the ad.
  Future<void> ensureLocation() async {
    if (form.latitude != null && form.longitude != null) return;
    final position = await LocationService.getCurrentPosition();
    if (position != null) {
      form.latitude = position.latitude;
      form.longitude = position.longitude;
      form.fullAddress = await LocationService.getAddressFromCoordinates(
              position.latitude, position.longitude) ??
          '';
      return;
    }
    final saved = await LocationService.getSavedCurrentLocation();
    if (saved != null) {
      form.latitude = (saved['latitude'] as num?)?.toDouble();
      form.longitude = (saved['longitude'] as num?)?.toDouble();
      form.fullAddress = saved['address']?.toString() ?? '';
    }
  }

  /// Ordered chips for "Your Car Details" (same order as Android).
  List<(String, SummaryType)> summary() {
    final f = form;
    final items = <(String?, SummaryType)>[
      (f.brandName, SummaryType.brand),
      (f.modelName, SummaryType.model),
      (f.variantName, SummaryType.variant),
      (f.city, SummaryType.city),
      ((f.registrationYear ?? 0) > 0 ? f.registrationYear.toString() : null, SummaryType.year),
      (f.kmDriven, SummaryType.km),
      (f.color, SummaryType.color),
      (f.carPrice, SummaryType.price),
      (f.fuelType, SummaryType.fuel),
      (f.transmission, SummaryType.transmission),
      (f.owner, SummaryType.owner),
    ];
    return [
      for (final (text, type) in items)
        if (text != null && text.trim().isNotEmpty && text != '0') (text, type),
    ];
  }

  /// Pops back to the screen named [route] (or to the first route = the Sell brand screen).
  static void popTo(BuildContext context, String? route) {
    Navigator.of(context).popUntil((r) => r.isFirst || (route != null && r.settings.name == route));
  }

  /// Variant values like "6-Speed AMT" mapped to the values the backend expects.
  static String? normalizeTransmission(String? raw) {
    final v = (raw ?? '').trim().toLowerCase();
    if (v.isEmpty) return null;
    if (v.contains('semi') || v.contains('amt') || v.contains('imt')) return 'Semi - Automatic';
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

  static String? normalizeFuel(String? raw) {
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
}
