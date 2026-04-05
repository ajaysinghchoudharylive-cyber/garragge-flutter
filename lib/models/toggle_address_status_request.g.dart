// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'toggle_address_status_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ToggleAddressStatusRequest _$ToggleAddressStatusRequestFromJson(
        Map<String, dynamic> json) =>
    ToggleAddressStatusRequest(
      addressId: (json['addressId'] as num).toInt(),
      userId: (json['userId'] as num).toInt(),
      addressType: json['addressType'] as String,
      title: json['title'] as String,
    );

Map<String, dynamic> _$ToggleAddressStatusRequestToJson(
        ToggleAddressStatusRequest instance) =>
    <String, dynamic>{
      'addressId': instance.addressId,
      'userId': instance.userId,
      'addressType': instance.addressType,
      'title': instance.title,
    };
