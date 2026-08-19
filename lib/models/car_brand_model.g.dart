// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'car_brand_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CarBrandModel _$CarBrandModelFromJson(Map<String, dynamic> json) =>
    CarBrandModel(
      brandName: json['brand_name'] as String? ?? '',
      brandLogo: json['brand_logo'] as String?,
    );

Map<String, dynamic> _$CarBrandModelToJson(CarBrandModel instance) =>
    <String, dynamic>{
      'brand_name': instance.brandName,
      'brand_logo': instance.brandLogo,
    };
