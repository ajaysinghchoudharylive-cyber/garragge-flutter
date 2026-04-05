class BannerDataResponse {
  final int id;
  final String imageUrl;
  final bool shouldShow;

  BannerDataResponse({
    required this.id,
    required this.imageUrl,
    required this.shouldShow,
  });

  factory BannerDataResponse.fromJson(Map<String, dynamic> json) {
    return BannerDataResponse(
      id: json['id'],
      imageUrl: json['imageUrl'],
      shouldShow: json['shouldShow'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'imageUrl': imageUrl,
      'shouldShow': shouldShow,
    };
  }
}