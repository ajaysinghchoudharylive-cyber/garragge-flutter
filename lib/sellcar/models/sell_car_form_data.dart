import 'package:carsbuzz/sellcar/models/sell_car_models.dart';

/// Equivalent to native SelectDetailsPojoJava.java
/// Collects all sell car form data across the wizard steps.
/// This is the single source of truth for the entire sell car flow.
class SellCarFormData {
  // Brand & Model
  String? brandName;
  String? modelName;
  int? modelId;
  String? variantName;
  int? variantId;

  /// Colours offered for the chosen model/variant (drives the colour step).
  List<String> availableColors = [];

  // "Other" picks: the exact option wasn't listed. The typed value goes in the normal field
  // (modelName / variantName / color) and the matching flag below marks it for admin review.
  bool otherModel = false;
  bool otherVariant = false;
  bool otherColor = false;

  /// RC (registration certificate) photo, required when any "Other" option was picked.
  String? rcImagePath;

  // Car Details
  int? registrationYear;
  String? owner; // "First owner", "Second owner", ...
  String? carPrice;
  String? kmDriven;
  String? transmission; // "Manual", "Automatic", "Semi - Automatic"
  String? fuelType; // "Petrol", "Diesel", "CNG", "Electric", "Hybrid", "LPG"
  String? ownersType; // "Individual" or "Dealer"
  String? carModified; // "yes" or "no"
  int? bodyType;
  String? color;
  String? seatingCapacity;

  // Contact & Location
  String? city;
  String? state;
  String? phoneNumber;
  String? ownerName;

  /// Coordinates of the car. The backend derives city/state from these.
  double? latitude;
  double? longitude;
  String? fullAddress;

  // Vehicle Condition Checklist (Additional Info)
  String? insurance;
  String? registration;
  String? battery;
  String? tyre;
  String? brakes;
  String? service;
  String? loan;
  String? puc;
  String? challan;

  // Images & Videos
  List<String> imagePaths = [];
  String? exteriorVideoPath;
  String? interiorVideoPath;

  // Metadata
  int? userId;
  bool isConfirmed = false;

  SellCarFormData();

  /// True when the ad needs an RC photo (seller picked "Other" for model, variant or colour).
  bool get requiresRc => otherModel || otherVariant || otherColor;

  bool get hasBrandAndModel =>
      brandName != null &&
      brandName!.isNotEmpty &&
      modelName != null &&
      modelName!.isNotEmpty;

  bool get isReadyToPost =>
      hasBrandAndModel &&
      registrationYear != null &&
      carPrice != null &&
      carPrice!.isNotEmpty &&
      kmDriven != null &&
      kmDriven!.isNotEmpty &&
      fuelType != null &&
      transmission != null &&
      owner != null;

  /// Native requires at least 6 photos.
  bool get hasMinimumImages => imagePaths.length >= 6;

  List<String> get summaryChips {
    final chips = <String>[];
    if (brandName != null) chips.add(brandName!);
    if (modelName != null) chips.add(modelName!);
    if (variantName != null) chips.add(variantName!);
    if (registrationYear != null) chips.add(registrationYear.toString());
    if (kmDriven != null) chips.add(kmDriven!);
    if (fuelType != null) chips.add(fuelType!);
    if (transmission != null) chips.add(transmission!);
    if (carPrice != null) chips.add('\u20B9$carPrice');
    if (owner != null) chips.add(owner!);
    if (color != null) chips.add(color!);
    return chips;
  }

  /// The `carDetails` JSON part of POST cars/postad. Keys match the Android CarsListingModels.
  /// City/state are intentionally blank: the server derives both from latitude/longitude.
  Map<String, dynamic> toPostAdJson() {
    return {
      'make': brandName ?? '',
      'cars_model': modelName ?? '',
      'cars_km_driven': kmDriven ?? '',
      'cars_transmission': transmission ?? '',
      'car_price': carPrice ?? '',
      'cars_owners': owner ?? '',
      'cars_fuel_type': fuelType ?? '',
      'cars_city': '',
      'cars_owner_type': ownersType ?? 'Individual',
      'user_id': userId ?? 0,
      'cars_registration_year': registrationYear ?? 0,
      'car_modified': carModified ?? 'no',
      'body': bodyType ?? 0,
      'phone_number': phoneNumber ?? '',
      'owner_name': ownerName ?? '',
      'is_verified': 0,
      'cars_state': '',
      'isCarPopular': 0,
      'variantId': (variantId == null || variantId == 0 || variantId == kOtherOptionId)
          ? null
          : variantId,
      'seating_capacity': seatingCapacity ?? '5',
      'color': color ?? '',
      'insurance': insurance ?? '',
      'registration': registration ?? '',
      'battery': battery ?? '',
      'tyre': tyre ?? '',
      'brakes': brakes ?? '',
      'service': service ?? '',
      'loan': loan ?? '',
      'puc': puc ?? '',
      'challan': challan ?? '',
      'latitude': latitude ?? 0.0,
      'longitude': longitude ?? 0.0,
      'fullAddress': fullAddress ?? '',
      'other_model': otherModel ? kOtherOptionLabel : null,
      'other_variant': otherVariant ? kOtherOptionLabel : null,
      'other_color': otherColor ? kOtherOptionLabel : null,
    };
  }

  /// Body of POST/PUT cars/drafts (a flat string map, same keys as the server's RemoteCarDraft).
  Map<String, String?> toDraftFields() {
    return {
      'make': brandName,
      'model': modelName,
      'fuelType': fuelType,
      'transmission': transmission,
      'color': color,
      'registrationYear': registrationYear?.toString(),
      'owner': owner,
      'carPrice': carPrice,
      'kmDriven': kmDriven,
      'ownersType': ownersType,
      'carModified': carModified,
      'bodyType': bodyType?.toString(),
      'city': city,
      'phoneNumber': phoneNumber,
      'ownerName': ownerName,
      'seatingCapacity': seatingCapacity,
      'variantId': (variantId == null || variantId == kOtherOptionId)
          ? null
          : variantId.toString(),
    };
  }

  void clear() {
    brandName = null;
    modelName = null;
    modelId = null;
    variantName = null;
    variantId = null;
    availableColors = [];
    otherModel = false;
    otherVariant = false;
    otherColor = false;
    rcImagePath = null;
    registrationYear = null;
    owner = null;
    carPrice = null;
    kmDriven = null;
    transmission = null;
    fuelType = null;
    ownersType = null;
    carModified = null;
    bodyType = null;
    color = null;
    seatingCapacity = null;
    city = null;
    state = null;
    phoneNumber = null;
    ownerName = null;
    latitude = null;
    longitude = null;
    fullAddress = null;
    insurance = null;
    registration = null;
    battery = null;
    tyre = null;
    brakes = null;
    service = null;
    loan = null;
    puc = null;
    challan = null;
    imagePaths = [];
    exteriorVideoPath = null;
    interiorVideoPath = null;
    userId = null;
    isConfirmed = false;
  }

  @override
  String toString() {
    return 'SellCarFormData{brand: $brandName, model: $modelName, variant: $variantName, '
        'year: $registrationYear, price: $carPrice, km: $kmDriven, fuel: $fuelType, '
        'transmission: $transmission, owner: $owner, color: $color, '
        'images: ${imagePaths.length}}';
  }
}
