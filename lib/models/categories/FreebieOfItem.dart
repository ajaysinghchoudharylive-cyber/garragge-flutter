class FreebieOfItem {
  final String name;

  FreebieOfItem({required this.name});

  factory FreebieOfItem.fromJson(Map<String, dynamic> json) {
    return FreebieOfItem(name: json['name']);
  }
}
