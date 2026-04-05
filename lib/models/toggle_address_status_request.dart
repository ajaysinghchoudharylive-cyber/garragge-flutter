import 'package:json_annotation/json_annotation.dart';

part 'toggle_address_status_request.g.dart';

@JsonSerializable()
class ToggleAddressStatusRequest {
  final int addressId;
  final int userId;
  final String addressType;
  final String title;

  ToggleAddressStatusRequest({
    required this.addressId,
    required this.userId,
    required this.addressType,
    required this.title,
  });

  Map<String, dynamic> toJson() => _$ToggleAddressStatusRequestToJson(this);

  factory ToggleAddressStatusRequest.fromJson(Map<String, dynamic> json) => _$ToggleAddressStatusRequestFromJson(json);
}