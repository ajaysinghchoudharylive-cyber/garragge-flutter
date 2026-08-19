// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sell_car_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SellCarRequest _$SellCarRequestFromJson(Map<String, dynamic> json) =>
    SellCarRequest(
      carMake: json['make'] as String? ?? '',
      carModel: json['cars_model'] as String? ?? '',
      variant: json['variant'] as String?,
      registrationYear: json['cars_registration_year'] as int? ?? 2020,
      kmDriven: json['cars_km_driven'] as String? ?? '',
      price: json['car_price'] as String? ?? '',
      fuelType: json['cars_fuel_type'] as String? ?? '',
      transmission: json['cars_transmission'] as String? ?? '',
      numberOfOwners: json['cars_owners'] as String? ?? '',
      city: json['cars_city'] as String? ?? '',
      state: json['cars_state'] as String?,
      bodyType: json['body'] as String?,
      color: json['color'] as String?,
      userId: json['user_id'] as int? ?? 0,
      phoneNumber: json['phone_number'] as String? ?? '',
      ownerName: json['owner_name'] as String?,
      images:
          (json['images'] as List<dynamic>?)?.map((e) => e as String).toList(),
      additionalInfo: json['additional_info'] as String?,
    );

Map<String, dynamic> _$SellCarRequestToJson(SellCarRequest instance) =>
    <String, dynamic>{
      'make': instance.carMake,
      'cars_model': instance.carModel,
      'variant': instance.variant,
      'cars_registration_year': instance.registrationYear,
      'cars_km_driven': instance.kmDriven,
      'car_price': instance.price,
      'cars_fuel_type': instance.fuelType,
      'cars_transmission': instance.transmission,
      'cars_owners': instance.numberOfOwners,
      'cars_city': instance.city,
      'cars_state': instance.state,
      'body': instance.bodyType,
      'color': instance.color,
      'user_id': instance.userId,
      'phone_number': instance.phoneNumber,
      'owner_name': instance.ownerName,
      'images': instance.images,
      'additional_info': instance.additionalInfo,
    };
