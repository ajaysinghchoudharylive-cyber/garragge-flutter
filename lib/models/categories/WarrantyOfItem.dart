class WarrantyOfItem {
  final String time;
  final String price;
  final String name;
  final bool? isAttached;

  WarrantyOfItem({
    required this.time,
    required this.price,
    required this.name,
    required this.isAttached,
  });

  factory WarrantyOfItem.fromJson(Map<String, dynamic> json) {
    return WarrantyOfItem(
      time: json['time'],
      price: json['price'],
      name: json['name'],
      isAttached: json['isAttached'],
    );
  }
}
