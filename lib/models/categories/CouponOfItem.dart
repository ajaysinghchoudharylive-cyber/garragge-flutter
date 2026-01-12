class CouponOfItem {
  final String code;
  final String? description;
  final bool? isAttached;
  final String price;
  final String? name;
  final bool? isSelected;

  CouponOfItem({
    required this.code,
    this.description,
    required this.isAttached,
    required this.price,
    this.name,
    required this.isSelected,
  });

  factory CouponOfItem.fromJson(Map<String, dynamic> json) {
    return CouponOfItem(
      code: json['code'],
      description: json['description'],
      isAttached: json['isAttached'],
      price: json['price'],
      name: json['name'],
      isSelected: json['isSelected'],
    );
  }
}
