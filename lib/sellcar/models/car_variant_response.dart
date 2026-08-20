/// Equivalent to native CarVariantResponse.kt
/// Detailed variant info with specs
class CarVariantResponse {
  final int? id;
  final String? variantName;
  final String? engine;
  final String? horsepower;
  final String? torque;
  final String? transmission;
  final String? mileage;
  final int? airbags;
  final String? seatingCapacity;
  final List<String>? colors;

  CarVariantResponse({
    this.id,
    this.variantName,
    this.engine,
    this.horsepower,
    this.torque,
    this.transmission,
    this.mileage,
    this.airbags,
    this.seatingCapacity,
    this.colors,
  });

  factory CarVariantResponse.fromJson(Map<String, dynamic> json) {
    return CarVariantResponse(
      id: json['id'] as int?,
      variantName: json['variantName'] as String?,
      engine: json['engine'] as String?,
      horsepower: json['horsepower'] as String?,
      torque: json['torque'] as String?,
      transmission: json['transmission'] as String?,
      mileage: json['mileage'] as String?,
      airbags: json['airbags'] as int?,
      seatingCapacity: json['seatingCapacity'] as String?,
      colors: (json['colors'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
    );
  }

  String get displaySpecs {
    final parts = <String>[];
    if (engine != null) parts.add(engine!);
    if (horsepower != null) parts.add('$horsepower HP');
    if (mileage != null) parts.add('$mileage kmpl');
    if (transmission != null) parts.add(transmission!);
    return parts.join(' | ');
  }
}
