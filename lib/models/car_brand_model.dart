/// A car brand from GET cars/carLogoAndNames -> [{id, cars_logo, cars_name}].
/// (Same shape as the Android app's CarsLogoAndNameModelNetworkEntity.)
class CarBrandModel {
  final int? id;
  final String brandName;
  final String? brandLogo;

  CarBrandModel({
    this.id,
    required this.brandName,
    this.brandLogo,
  });

  factory CarBrandModel.fromJson(Map<String, dynamic> json) {
    return CarBrandModel(
      id: json['id'] as int?,
      brandName: (json['cars_name'] ?? '').toString(),
      brandLogo: json['cars_logo']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'cars_name': brandName,
        'cars_logo': brandLogo,
      };
}
