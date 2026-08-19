import 'package:json_annotation/json_annotation.dart';
import 'car_listing_model.dart';

part 'car_listing_response.g.dart';

@JsonSerializable()
class CarListingResponse {
  final List<CarListingModel> content;
  final int totalElements;
  final int totalPages;
  final int currentPage;
  final bool isLast;

  CarListingResponse({
    required this.content,
    this.totalElements = 0,
    this.totalPages = 0,
    this.currentPage = 0,
    this.isLast = true,
  });

  factory CarListingResponse.fromJson(Map<String, dynamic> json) =>
      _$CarListingResponseFromJson(json);

  Map<String, dynamic> toJson() => _$CarListingResponseToJson(this);
}
