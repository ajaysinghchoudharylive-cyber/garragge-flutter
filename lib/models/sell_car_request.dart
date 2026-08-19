import 'package:json_annotation/json_annotation.dart';

part 'sell_car_request.g.dart';

@JsonSerializable()
class SellCarRequest {
  @JsonKey(name: 'make')
  final String carMake;

  @JsonKey(name: 'cars_model')
  final String carModel;

  @JsonKey(name: 'variant')
  final String? variant;

  @JsonKey(name: 'cars_registration_year')
  final int registrationYear;

  @JsonKey(name: 'cars_km_driven')
  final String kmDriven;

  @JsonKey(name: 'car_price')
  final String price;

  @JsonKey(name: 'cars_fuel_type')
  final String fuelType;

  @JsonKey(name: 'cars_transmission')
  final String transmission;

  @JsonKey(name: 'cars_owners')
  final String numberOfOwners;

  @JsonKey(name: 'cars_city')
  final String city;

  @JsonKey(name: 'cars_state')
  final String? state;

  @JsonKey(name: 'body')
  final String? bodyType;

  final String? color;

  @JsonKey(name: 'user_id')
  final int userId;

  @JsonKey(name: 'phone_number')
  final String phoneNumber;

  @JsonKey(name: 'owner_name')
  final String? ownerName;

  @JsonKey(name: 'images')
  final List<String>? images;

  @JsonKey(name: 'additional_info')
  final String? additionalInfo;

  SellCarRequest({
    required this.carMake,
    required this.carModel,
    this.variant,
    required this.registrationYear,
    required this.kmDriven,
    required this.price,
    required this.fuelType,
    required this.transmission,
    required this.numberOfOwners,
    required this.city,
    this.state,
    this.bodyType,
    this.color,
    required this.userId,
    required this.phoneNumber,
    this.ownerName,
    this.images,
    this.additionalInfo,
  });

  factory SellCarRequest.fromJson(Map<String, dynamic> json) =>
      _$SellCarRequestFromJson(json);

  Map<String, dynamic> toJson() => _$SellCarRequestToJson(this);
}
