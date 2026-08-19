import 'package:json_annotation/json_annotation.dart';

part 'car_brand_model.g.dart';

@JsonSerializable()
class CarBrandModel {
  @JsonKey(name: 'brand_name')
  final String brandName;

  @JsonKey(name: 'brand_logo')
  final String? brandLogo;

  CarBrandModel({
    required this.brandName,
    this.brandLogo,
  });

  factory CarBrandModel.fromJson(Map<String, dynamic> json) =>
      _$CarBrandModelFromJson(json);

  Map<String, dynamic> toJson() => _$CarBrandModelToJson(this);
}
