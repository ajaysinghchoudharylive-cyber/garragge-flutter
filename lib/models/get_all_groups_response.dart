import 'package:carsbuzz/models/category_response_body.dart';

class GetAllGroupsResponse {
  final int id;
  final String groupName;
  final String groupIcon;
  final bool attached;
  final bool launched;
  final List<CategoryResponseBody> categories;

  GetAllGroupsResponse({
    required this.id,
    required this.groupName,
    required this.groupIcon,
    required this.attached,
    required this.launched,
    required this.categories,
  });

  factory GetAllGroupsResponse.fromJson(Map<String, dynamic> json) {
    return GetAllGroupsResponse(
      id: json['id'] as int,
      groupName: json['groupName'] as String,
      groupIcon: json['groupIcon'] as String,
      attached: json['attached'] as bool,
      launched: json['launched'] as bool,
      categories: (json['categories'] as List)
          .map((e) => CategoryResponseBody.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'groupName': groupName,
      'groupIcon': groupIcon,
      'attached': attached,
      'launched': launched,
      'categories': categories.map((e) => e.toJson()).toList(),
    };
  }
}