// ignore: file_names
class FacilityOfItem {
  final String? iconUrl;
  final String? name;

  FacilityOfItem({this.iconUrl, this.name});

  factory FacilityOfItem.fromJson(Map<String, dynamic> json) {
    return FacilityOfItem(
      iconUrl: json['iconUrl'],
      name: json['name'],
    );
  }
}
