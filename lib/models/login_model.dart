import 'user_response_data.dart';

class LoginModel {
  final String userToken;
  final String version;
  final String result;
  final String message;
  final String policies;
  final String terms;
  final UserResponseData? user;

  LoginModel({
    required this.userToken,
    required this.version,
    required this.result,
    required this.message,
    required this.policies,
    required this.terms,
    this.user,
  });

  bool get isSuccess {
    // Check for both HTTP success codes and success strings
    final resultLower = result.toLowerCase();
    return resultLower == "success" || 
           resultLower == "200" ; // Any 2xx status code
  }

  factory LoginModel.fromJson(Map<String, dynamic> json) {
    return LoginModel(
      userToken: json['userToken']?.toString() ?? "",
      version: json['version']?.toString() ?? "",
      result: json['result']?.toString() ?? "",
      message: json['message']?.toString() ?? "",
      policies: json['policies']?.toString() ?? "",
      terms: json['terms']?.toString() ?? "",
      user: json['user'] != null
          ? UserResponseData.fromJson(json['user'])
          : null,
    );
  }
}
