class WarrantyDetailsOfItem {
  final String heading;
  final String warranty;
  final bool? isAttached;

  WarrantyDetailsOfItem({
    required this.heading,
    required this.warranty,
    required this.isAttached,
  });

  factory WarrantyDetailsOfItem.fromJson(Map<String, dynamic> json) {
    return WarrantyDetailsOfItem(
      heading: json['heading'],
      warranty: json['warranty'],
      isAttached: json['isAttached'],
    );
  }
}
