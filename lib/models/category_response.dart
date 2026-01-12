import 'package:carsbuzz/models/category_item.dart';

class CategoryResponse {
  final int id;
  final String itemCategory;
  final List<CategoryItem> items;

  CategoryResponse({
    required this.id,
    required this.itemCategory,
    required this.items,
  });

  factory CategoryResponse.fromJson(Map<String, dynamic> json) {
    return CategoryResponse(
      id: json['id'],
      itemCategory: json['itemCategory'],
      items: (json['items'] as List)
          .map((e) => CategoryItem.fromJson(e))
          .toList(),
    );
  }
}
