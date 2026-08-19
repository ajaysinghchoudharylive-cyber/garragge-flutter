// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'car_listing_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CarListingResponse _$CarListingResponseFromJson(Map<String, dynamic> json) =>
    CarListingResponse(
      content: (json['content'] as List<dynamic>?)
              ?.map((e) => CarListingModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      totalElements: json['totalElements'] as int? ?? 0,
      totalPages: json['totalPages'] as int? ?? 0,
      currentPage: json['currentPage'] as int? ?? 0,
      isLast: json['isLast'] as bool? ?? true,
    );

Map<String, dynamic> _$CarListingResponseToJson(CarListingResponse instance) =>
    <String, dynamic>{
      'content': instance.content.map((e) => e.toJson()).toList(),
      'totalElements': instance.totalElements,
      'totalPages': instance.totalPages,
      'currentPage': instance.currentPage,
      'isLast': instance.isLast,
    };
