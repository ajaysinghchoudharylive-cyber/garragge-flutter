class SignUpUserModel {
  final String phone;
  final String firebaseToken;

  SignUpUserModel({
    required this.phone,
    required this.firebaseToken,
  });

  Map<String, dynamic> toJson() => {
        "phone": phone,
        "firebaseToken": firebaseToken,
      };
}
