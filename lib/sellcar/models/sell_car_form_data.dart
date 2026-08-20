/// Equivalent to native SelectDetailsPojoJava.java
/// Collects all sell car form data across the wizard steps.
/// This is the single source of truth for the entire sell car flow.
class SellCarFormData {
  // Brand & Model
  String? brandName;
  String? modelName;
  String? variantName;
  int? variantId;

  // Car Details
  int? registrationYear;
  String? owner; // "1st owner", "2nd owner", etc.
  String? carPrice;
  String? kmDriven;
  String? transmission; // "Manual" or "Automatic"
  String? fuelType; // "Petrol", "Diesel", "CNG", "Electric", "Hybrid", "LPG"
  String? ownersType; // "Individual" or "Dealer"
  String? carModified; // "Yes" or "No"
  int? bodyType;
  String? color;
  String? seatingCapacity;

  // Contact & Location
  String? city;
  String? state;
  String? phoneNumber;
  String? ownerName;

  // Vehicle Condition Checklist (Additional Info)
  String? insurance; // "Comprehensive", "Third Party", "Expired"
  String? registration; // "HP", "DL", etc.
  String? battery; // "Good", "Average", "Poor"
  String? tyre; // "Good", "Average", "Poor"
  String? brakes; // "Good", "Average", "Poor"
  String? service; // "Regular", "Irregular"
  String? loan; // "Yes", "No"
  String? puc; // "Valid", "Expired"
  String? challan; // "Yes", "No"

  // Images & Videos
  List<String> imagePaths = [];
  String? exteriorVideoPath;
  String? interiorVideoPath;

  // Metadata
  int? userId;
  bool isConfirmed = false;

  SellCarFormData();

  /// Check if brand + model are selected (minimum to show wizard)
  bool get hasBrandAndModel =>
      brandName != null &&
      brandName!.isNotEmpty &&
      modelName != null &&
      modelName!.isNotEmpty;

  /// Check if all required fields for posting are filled
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

  /// Check if minimum images are uploaded (native requires 6)
  bool get hasMinimumImages => imagePaths.length >= 6;

  /// Get summary chips for display in the wizard
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

  /// Convert to JSON map for API request (matches native CarsListingModels.kt)
  Map<String, dynamic> toPostAdJson() {
    return {
      'make': brandName ?? '',
      'cars_model': modelName ?? '',
      'variantId': variantId,
      'cars_registration_year': registrationYear ?? 0,
      'cars_km_driven': kmDriven ?? '',
      'car_price': carPrice ?? '',
      'cars_fuel_type': fuelType ?? '',
      'cars_transmission': transmission ?? '',
      'cars_owners': owner ?? '',
      'cars_owner_type': ownersType ?? 'Individual',
      'cars_city': city ?? '',
      'cars_state': state ?? '',
      'body': bodyType ?? 0,
      'car_modified': carModified ?? 'No',
      'phone_number': phoneNumber ?? '',
      'owner_name': ownerName ?? '',
      'color': color ?? '',
      'seating_capacity': seatingCapacity ?? '',
      'user_id': userId ?? 0,
      'is_verified': 0,
      'isCarPopular': 0,
      'insurance': insurance ?? '',
      'registration': registration ?? '',
      'battery': battery ?? '',
      'tyre': tyre ?? '',
      'brakes': brakes ?? '',
      'service': service ?? '',
      'loan': loan ?? '',
      'puc': puc ?? '',
      'challan': challan ?? '',
    };
  }

  /// Convert to JSON for draft saving
  Map<String, dynamic> toDraftJson() {
    return {
      'make': brandName,
      'model': modelName,
      'variantName': variantName,
      'variantId': variantId,
      'fuelType': fuelType,
      'transmission': transmission,
      'color': color,
      'registrationYear': registrationYear,
      'owner': owner,
      'carPrice': carPrice,
      'kmDriven': kmDriven,
      'ownersType': ownersType,
      'carModified': carModified,
      'bodyType': bodyType,
      'city': city,
      'state': state,
      'phoneNumber': phoneNumber,
      'ownerName': ownerName,
      'seatingCapacity': seatingCapacity,
      'insurance': insurance,
      'registration': registration,
      'battery': battery,
      'tyre': tyre,
      'brakes': brakes,
      'service': service,
      'loan': loan,
      'puc': puc,
      'challan': challan,
    };
  }

  /// Create from draft JSON (for resuming)
  factory SellCarFormData.fromDraftJson(Map<String, dynamic> json) {
    final data = SellCarFormData();
    data.brandName = json['make'] as String?;
    data.modelName = json['model'] as String?;
    data.variantName = json['variantName'] as String?;
    data.variantId = json['variantId'] as int?;
    data.fuelType = json['fuelType'] as String?;
    data.transmission = json['transmission'] as String?;
    data.color = json['color'] as String?;
    data.registrationYear = json['registrationYear'] as int?;
    data.owner = json['owner'] as String?;
    data.carPrice = json['carPrice'] as String?;
    data.kmDriven = json['kmDriven'] as String?;
    data.ownersType = json['ownersType'] as String?;
    data.carModified = json['carModified'] as String?;
    data.bodyType = json['bodyType'] as int?;
    data.city = json['city'] as String?;
    data.state = json['state'] as String?;
    data.phoneNumber = json['phoneNumber'] as String?;
    data.ownerName = json['ownerName'] as String?;
    data.seatingCapacity = json['seatingCapacity'] as String?;
    data.insurance = json['insurance'] as String?;
    data.registration = json['registration'] as String?;
    data.battery = json['battery'] as String?;
    data.tyre = json['tyre'] as String?;
    data.brakes = json['brakes'] as String?;
    data.service = json['service'] as String?;
    data.loan = json['loan'] as String?;
    data.puc = json['puc'] as String?;
    data.challan = json['challan'] as String?;
    return data;
  }

  /// Reset all fields
  void clear() {
    brandName = null;
    modelName = null;
    variantName = null;
    variantId = null;
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
        'transmission: $transmission, owner: $owner, color: $color, city: $city, '
        'images: ${imagePaths.length}}';
  }
}
