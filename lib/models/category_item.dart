

import 'categories/BookingStepsOfItem.dart';
import 'categories/CouponOfItem.dart';
import 'categories/FacilityOfItem.dart';
import 'categories/FaqOfItem.dart';
import 'categories/FreebieOfItem.dart';
import 'categories/TermsOfItem.dart';
import 'categories/UploadImageOfItem.dart';
import 'categories/WarrantyDetailsOfItem.dart';
import 'categories/WarrantyOfItem.dart';

class CategoryItem {
  final int? id;
  final String? itemName;
  final double? price;
  final double? discount;
  final String? itemIcon;

  final List<WarrantyOfItem> warranty;
  final List<FacilityOfItem> facilities;
  final List<FreebieOfItem> freebies;
  final List<UploadImageOfItem> media;
  final List<CouponOfItem> coupons;
  final List<FaqOfItem> faqs;
  final List<BookingStepsOfItem> bookingSteps;
  final List<TermsOfItem> terms;
  final List<WarrantyDetailsOfItem> warrantiesDetails;

  final String? categoryName;
  final String? couponPrice;
  final String? couponCode;

  CategoryItem({
    this.id,
    this.itemName,
    this.price,
    this.discount,
    this.itemIcon,
    required this.warranty,
    required this.facilities,
    required this.freebies,
    required this.media,
    required this.coupons,
    required this.faqs,
    required this.bookingSteps,
    required this.terms,
    required this.warrantiesDetails,
    this.categoryName,
    this.couponPrice,
    this.couponCode,
  });

  factory CategoryItem.fromJson(Map<String, dynamic> json) {
    return CategoryItem(
      id: json['id'] as int?,
      itemName: json['itemName'] as String?,
      price: (json['price'] as num?)?.toDouble(),
      discount: (json['discount'] as num?)?.toDouble(),
      itemIcon: json['itemIcon'] as String?,

      warranty: (json['warranty'] as List? ?? [])
          .map((e) => WarrantyOfItem.fromJson(e as Map<String, dynamic>))
          .toList(),

      facilities: (json['facilities'] as List? ?? [])
          .map((e) => FacilityOfItem.fromJson(e as Map<String, dynamic>))
          .toList(),

      freebies: (json['freebies'] as List? ?? [])
          .map((e) => FreebieOfItem.fromJson(e as Map<String, dynamic>))
          .toList(),

      media: (json['media'] as List? ?? [])
          .map((e) => UploadImageOfItem.fromJson(e as Map<String, dynamic>))
          .toList(),

      coupons: (json['coupons'] as List? ?? [])
          .map((e) => CouponOfItem.fromJson(e as Map<String, dynamic>))
          .toList(),

      faqs: (json['faqs'] as List? ?? [])
          .map((e) => FaqOfItem.fromJson(e as Map<String, dynamic>))
          .toList(),

      bookingSteps: (json['bookingSteps'] as List? ?? [])
          .map((e) => BookingStepsOfItem.fromJson(e as Map<String, dynamic>))
          .toList(),

      terms: (json['terms'] as List? ?? [])
          .map((e) => TermsOfItem.fromJson(e as Map<String, dynamic>))
          .toList(),

      warrantiesDetails: (json['warrantiesDetails'] as List? ?? [])
          .map((e) => WarrantyDetailsOfItem.fromJson(e as Map<String, dynamic>))
          .toList(),

      categoryName: json['categoryName'] as String?,
      couponPrice: json['couponPrice']?.toString(),
      couponCode: json['couponCode'] as String?,
    );
  }
}
