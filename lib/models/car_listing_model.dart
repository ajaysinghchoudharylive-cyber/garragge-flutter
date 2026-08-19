import 'package:json_annotation/json_annotation.dart';

part 'car_listing_model.g.dart';

@JsonSerializable()
class CarListingModel {
  final int? id;

  @JsonKey(name: 'make')
  final String? carMake;

  @JsonKey(name: 'cars_model')
  final String? carModel;

  @JsonKey(name: 'cars_km_driven')
  final String? carKmDriven;

  @JsonKey(name: 'cars_transmission')
  final String? carTransmission;

  @JsonKey(name: 'car_price')
  final String? carPrice;

  @JsonKey(name: 'cars_owners')
  final String? carsOwners;

  @JsonKey(name: 'cars_fuel_type')
  final String? carFuelType;

  @JsonKey(name: 'cars_city')
  final String? carsCity;

  @JsonKey(name: 'cars_owner_type')
  final String? carsOwnerType;

  @JsonKey(name: 'user_id')
  final int? userId;

  @JsonKey(name: 'cars_registration_year')
  final int? carsRegistrationYear;

  @JsonKey(name: 'car_modified')
  final String? carModified;

  @JsonKey(name: 'body')
  final int? bodyType;

  @JsonKey(name: 'phone_number')
  final String? phoneNumber;

  @JsonKey(name: 'owner_name')
  final String? ownerName;

  @JsonKey(name: 'is_verified')
  final int? isVerified;

  @JsonKey(name: 'cars_state')
  final String? state;

  @JsonKey(name: 'isCarPopular')
  final int? isCarPopular;

  @JsonKey(name: 'variantId')
  final int? variantId;

  @JsonKey(name: 'seating_capacity')
  final String? seatingCapacity;

  final String? color;
  final String? insurance;
  final String? registration;

  @JsonKey(name: 'image_url')
  final String? imageUrl;

  @JsonKey(name: 'images')
  final List<String>? images;

  final double? latitude;
  final double? longitude;

  @JsonKey(name: 'fullAddress')
  final String? fullAddress;

  CarListingModel({
    this.id,
    this.carMake,
    this.carModel,
    this.carKmDriven,
    this.carTransmission,
    this.carPrice,
    this.carsOwners,
    this.carFuelType,
    this.carsCity,
    this.carsOwnerType,
    this.userId,
    this.carsRegistrationYear,
    this.carModified,
    this.bodyType,
    this.phoneNumber,
    this.ownerName,
    this.isVerified,
    this.state,
    this.isCarPopular,
    this.variantId,
    this.seatingCapacity,
    this.color,
    this.insurance,
    this.registration,
    this.imageUrl,
    this.images,
    this.latitude,
    this.longitude,
    this.fullAddress,
  });

  factory CarListingModel.fromJson(Map<String, dynamic> json) =>
      _$CarListingModelFromJson(json);

  Map<String, dynamic> toJson() => _$CarListingModelToJson(this);

  String get displayTitle => '${carMake ?? ''} ${carModel ?? ''}'.trim();

  String get displayPrice {
    if (carPrice == null) return 'Price on request';
    final price = double.tryParse(carPrice!);
    if (price == null) return '\u20B9$carPrice';
    if (price >= 100000) {
      return '\u20B9${(price / 100000).toStringAsFixed(2)} Lakh';
    }
    return '\u20B9${price.toStringAsFixed(0)}';
  }

  String get displayKm {
    if (carKmDriven == null) return '';
    final km = double.tryParse(carKmDriven!);
    if (km == null) return '$carKmDriven km';
    if (km >= 1000) {
      return '${(km / 1000).toStringAsFixed(0)}k km';
    }
    return '${km.toStringAsFixed(0)} km';
  }
}
