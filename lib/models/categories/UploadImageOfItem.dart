class UploadImageOfItem {
  final String mediaUrl;
  final String mediaType;

  UploadImageOfItem({
    required this.mediaUrl,
    required this.mediaType,
  });

  factory UploadImageOfItem.fromJson(Map<String, dynamic> json) {
    return UploadImageOfItem(
      mediaUrl: json['mediaUrl'],
      mediaType: json['mediaType'],
    );
  }
}
