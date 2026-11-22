/// Backend sentinel id for the synthetic "Other" model / variant option. Picking it means the exact
/// option isn't listed: the seller types the value and uploads an RC (registration certificate)
/// photo so an admin can resolve it. Mirrors Android Constants.OTHER_OPTION_ID.
const int kOtherOptionId = -1;
const String kOtherOptionLabel = 'Other';

/// Body-type labels; the INDEX is the backend body code (same as Android Utilities.getBodyTypes).
const List<String> kBodyTypeLabels = [
  'Hatchback', // 0
  'Sedan', // 1
  'Coupe', // 2
  'SUV/MUV', // 3
  'Mini van', // 4
  'Truck', // 5
  'Convertible', // 6
  'Station wagon', // 7
  'Compact Sedan', // 8
  'MUV', // 9
  'Compact SUV', // 10
  'Crossover', // 11
  'Luxury', // 12
  'Sports', // 13
  'Coupe Convertible', // 14
  'Limo', // 15
];

/// Maps a model's `car_body` label (e.g. "SUV", "Sedan") to the backend body code.
/// Keep in step with the backend CarModelService.bodyLabelToCode. Unknown -> null.
int? bodyCodeForLabel(String? label) {
  if (label == null || label.trim().isEmpty) return null;
  switch (label.trim().toLowerCase()) {
    case 'hatchback':
      return 0;
    case 'sedan':
      return 1;
    case 'coupe':
      return 2;
    case 'suv':
    case 'suv/muv':
      return 3;
    case 'minivan':
    case 'mini van':
    case 'mpv':
      return 4;
    case 'truck':
      return 5;
    case 'convertible':
      return 6;
    case 'station wagon':
      return 7;
    case 'compact sedan':
      return 8;
    case 'muv':
      return 9;
    case 'compact suv':
      return 10;
    case 'crossover':
      return 11;
    case 'luxury':
      return 12;
    case 'sports':
      return 13;
    case 'coupe convertible':
      return 14;
    case 'limo':
    case 'limousine':
      return 15;
  }
  return null;
}

/// A model of a brand: GET cars/{brandName}/models.
class CarModelItem {
  final int id;
  final String name;
  final String? imageUrl;

  /// Comma-separated colour names available for this model (may be null/empty).
  final String? availableColors;

  /// Body-type label for this model; used to set the ad's body type automatically.
  final String? carBody;

  const CarModelItem({
    required this.id,
    required this.name,
    this.imageUrl,
    this.availableColors,
    this.carBody,
  });

  bool get isOther => id == kOtherOptionId;

  List<String> get colorList => (availableColors ?? '')
      .split(',')
      .map((c) => c.trim())
      .where((c) => c.isNotEmpty)
      .toList();

  factory CarModelItem.fromJson(Map<String, dynamic> json) {
    return CarModelItem(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: (json['model_name'] ?? json['modelName'] ?? '').toString(),
      imageUrl: json['imageUrl']?.toString(),
      availableColors: json['available_colors']?.toString(),
      carBody: json['car_body']?.toString(),
    );
  }
}

/// A variant of a model: GET cars/{brandName}/models/{modelId}/variants.
class CarVariantItem {
  final int id;
  final String name;
  final String? price;
  final String? engineSize;
  final String? engineType;
  final String? horsepower;
  final String? torque;
  final String? transmission;
  final String? mileage;
  final String? seatingCapacity;
  final String? availableColors;

  const CarVariantItem({
    required this.id,
    required this.name,
    this.price,
    this.engineSize,
    this.engineType,
    this.horsepower,
    this.torque,
    this.transmission,
    this.mileage,
    this.seatingCapacity,
    this.availableColors,
  });

  bool get isOther => id == kOtherOptionId;

  factory CarVariantItem.fromJson(Map<String, dynamic> json) {
    String? s(String key) => json[key]?.toString();
    return CarVariantItem(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: (json['variantName'] ?? '').toString(),
      price: s('price'),
      engineSize: s('engineSize'),
      engineType: s('engineType'),
      horsepower: s('horsepower'),
      torque: s('torque'),
      transmission: s('transmission'),
      mileage: s('mileage'),
      seatingCapacity: s('seatingCapacity'),
      availableColors: s('availableColors'),
    );
  }

  // Some backend records have fuel and transmission swapped between `engineType` and
  // `transmission`. The two vocabularies don't overlap, so classify by value (same approach as
  // the Android CarVariantResponse.resolvedFuelType / resolvedTransmission).
  static const List<String> _fuelWords = [
    'petrol', 'gasoline', 'diesel', 'cng', 'lpg', 'electric', 'ev', 'hybrid', 'hydrogen',
  ];
  static const List<String> _transmissionWords = [
    'manual', 'automatic', 'amt', 'cvt', 'dct', 'dsg', 'imt', 'torque converter', 'at', 'mt',
  ];

  static bool _isFuel(String? v) {
    final t = (v ?? '').trim().toLowerCase();
    return t.isNotEmpty && _fuelWords.any(t.contains);
  }

  static bool _isTransmission(String? v) {
    final t = (v ?? '').trim().toLowerCase();
    return t.isNotEmpty && _transmissionWords.any(t.contains);
  }

  String? get resolvedFuelType {
    if (_isFuel(engineType)) return engineType;
    if (_isFuel(transmission)) return transmission;
    return engineType;
  }

  String? get resolvedTransmission {
    if (_isTransmission(transmission)) return transmission;
    if (_isTransmission(engineType)) return engineType;
    return transmission;
  }

  /// One-line summary shown under the variant name.
  String get displaySpecs {
    final parts = <String>[];
    void add(String? v, [String suffix = '']) {
      if (v != null && v.trim().isNotEmpty && v.trim().toLowerCase() != 'null') {
        parts.add('${v.trim()}$suffix');
      }
    }

    add(engineSize);
    add(resolvedFuelType);
    add(resolvedTransmission);
    add(horsepower, ' HP');
    add(mileage, ' kmpl');
    return parts.join(' | ');
  }
}

/// GET cars/upload-status?userId= : whether the user may post another ad.
class UploadStatus {
  final bool canUpload;
  final bool hasUploadPlan;
  final int? freeUploadsRemaining;
  final int? monthlyUploadLimit;

  const UploadStatus({
    required this.canUpload,
    this.hasUploadPlan = false,
    this.freeUploadsRemaining,
    this.monthlyUploadLimit,
  });

  /// Permissive default so a failed pre-check never blocks the user (the server still enforces).
  static const UploadStatus allowed = UploadStatus(canUpload: true);

  factory UploadStatus.fromJson(Map<String, dynamic> json) {
    return UploadStatus(
      canUpload: json['canUpload'] as bool? ?? true,
      hasUploadPlan: json['hasUploadPlan'] as bool? ?? false,
      freeUploadsRemaining: (json['freeUploadsRemaining'] as num?)?.toInt(),
      monthlyUploadLimit: (json['monthlyUploadLimit'] as num?)?.toInt(),
    );
  }
}
