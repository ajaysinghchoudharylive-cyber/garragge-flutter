// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'address_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AddressResponse _$AddressResponseFromJson(Map<String, dynamic> json) =>
    AddressResponse(
      id: (json['id'] as num).toInt(),
      addressType: json['addressType'] as String,
      title: json['title'] as String?,
      address: json['address'] as String,
      locality: json['locality'] as String?,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      active: json['active'] as bool,
    );

Map<String, dynamic> _$AddressResponseToJson(AddressResponse instance) =>
    <String, dynamic>{
      'id': instance.id,
      'addressType': instance.addressType,
      'title': instance.title,
      'address': instance.address,
      'locality': instance.locality,
      'latitude': instance.latitude,
      'longitude': instance.longitude,
      'active': instance.active,
    };
