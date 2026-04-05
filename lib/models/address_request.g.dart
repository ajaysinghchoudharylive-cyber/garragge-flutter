// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'address_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AddressRequest _$AddressRequestFromJson(Map<String, dynamic> json) =>
    AddressRequest(
      userId: (json['userId'] as num).toInt(),
      addressType: json['addressType'] as String,
      title: json['title'] as String?,
      address: json['address'] as String,
      locality: json['locality'] as String?,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      active: json['active'] as bool,
    );

Map<String, dynamic> _$AddressRequestToJson(AddressRequest instance) =>
    <String, dynamic>{
      'userId': instance.userId,
      'addressType': instance.addressType,
      'title': instance.title,
      'address': instance.address,
      'locality': instance.locality,
      'latitude': instance.latitude,
      'longitude': instance.longitude,
      'active': instance.active,
    };
