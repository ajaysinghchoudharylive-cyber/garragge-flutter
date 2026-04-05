import 'package:carsbuzz/models/category_item.dart';

class CategoryResponseBody {
  final int id;
  final String itemCategory;
  final String? imageUrl;
  final String? imageIcon;
  final List<CategoryItem> items;

  CategoryResponseBody({
    required this.id,
    required this.itemCategory,
    this.imageUrl,
    this.imageIcon,
    required this.items,
  });

  factory CategoryResponseBody.fromJson(Map<String, dynamic> json) {
    return CategoryResponseBody(
      id: json['id'] as int,
      itemCategory: json['itemCategory'] as String,
      imageUrl: json['imageUrl'] as String?,
      imageIcon: json['imageIcon'] as String?,
      items: (json['items'] as List? ?? [])
          .map((e) => CategoryItem.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'itemCategory': itemCategory,
      'imageUrl': imageUrl,
      'imageIcon': imageIcon,
      'items': items.map((e) => e.toJson()).toList(),
    };
  }
}