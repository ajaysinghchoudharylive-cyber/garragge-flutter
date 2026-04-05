import 'package:json_annotation/json_annotation.dart';

part 'address_response.g.dart';

@JsonSerializable()
class AddressResponse {
  final int id;
  final String addressType;
  final String? title;
  final String address;
  final String? locality;
  final double? latitude;
  final double? longitude;
  final bool active;

  AddressResponse({
    required this.id,
    required this.addressType,
    this.title,
    required this.address,
    this.locality,
    this.latitude,
    this.longitude,
    required this.active,
  });

  factory AddressResponse.fromJson(Map<String, dynamic> json) => _$AddressResponseFromJson(json);

  Map<String, dynamic> toJson() => _$AddressResponseToJson(this);
}