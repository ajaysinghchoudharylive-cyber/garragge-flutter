import 'package:json_annotation/json_annotation.dart';

part 'address_request.g.dart';

@JsonSerializable()
class AddressRequest {
  final int userId;
  final String addressType; // LATEST / CONFIRMED
  final String? title;
  final String address;
  final String? locality;
  final double? latitude;
  final double? longitude;
  final bool active;

  AddressRequest({
    required this.userId,
    required this.addressType,
    this.title,
    required this.address,
    this.locality,
    this.latitude,
    this.longitude,
    required this.active,
  });

  Map<String, dynamic> toJson() => _$AddressRequestToJson(this);

  factory AddressRequest.fromJson(Map<String, dynamic> json) => _$AddressRequestFromJson(json);
}