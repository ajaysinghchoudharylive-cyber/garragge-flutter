// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'car_listing_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CarListingModel _$CarListingModelFromJson(Map<String, dynamic> json) =>
    CarListingModel(
      id: json['id'] as int?,
      carMake: json['make'] as String?,
      carModel: json['cars_model'] as String?,
      carKmDriven: json['cars_km_driven'] as String?,
      carTransmission: json['cars_transmission'] as String?,
      carPrice: json['car_price'] as String?,
      carsOwners: json['cars_owners'] as String?,
      carFuelType: json['cars_fuel_type'] as String?,
      carsCity: json['cars_city'] as String?,
      carsOwnerType: json['cars_owner_type'] as String?,
      userId: json['user_id'] as int?,
      carsRegistrationYear: json['cars_registration_year'] as int?,
      carModified: json['car_modified'] as String?,
      bodyType: json['body'] as int?,
      phoneNumber: json['phone_number'] as String?,
      ownerName: json['owner_name'] as String?,
      isVerified: json['is_verified'] as int?,
      state: json['cars_state'] as String?,
      isCarPopular: json['isCarPopular'] as int?,
      variantId: json['variantId'] as int?,
      seatingCapacity: json['seating_capacity'] as String?,
      color: json['color'] as String?,
      insurance: json['insurance'] as String?,
      registration: json['registration'] as String?,
      imageUrl: json['image_url'] as String?,
      images: (json['images'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      fullAddress: json['fullAddress'] as String?,
    );

Map<String, dynamic> _$CarListingModelToJson(CarListingModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'make': instance.carMake,
      'cars_model': instance.carModel,
      'cars_km_driven': instance.carKmDriven,
      'cars_transmission': instance.carTransmission,
      'car_price': instance.carPrice,
      'cars_owners': instance.carsOwners,
      'cars_fuel_type': instance.carFuelType,
      'cars_city': instance.carsCity,
      'cars_owner_type': instance.carsOwnerType,
      'user_id': instance.userId,
      'cars_registration_year': instance.carsRegistrationYear,
      'car_modified': instance.carModified,
      'body': instance.bodyType,
      'phone_number': instance.phoneNumber,
      'owner_name': instance.ownerName,
      'is_verified': instance.isVerified,
      'cars_state': instance.state,
      'isCarPopular': instance.isCarPopular,
      'variantId': instance.variantId,
      'seating_capacity': instance.seatingCapacity,
      'color': instance.color,
      'insurance': instance.insurance,
      'registration': instance.registration,
      'image_url': instance.imageUrl,
      'images': instance.images,
      'latitude': instance.latitude,
      'longitude': instance.longitude,
      'fullAddress': instance.fullAddress,
    };
