import '../models/signup_user_model.dart';
import '../models/login_model.dart';
import '../network/api_client.dart';
import '../network/repository_api.dart';
import '../network/firebase_service.dart';

class AuthRepo {
  final RepositoryApi _api;

  AuthRepo() : _api = ApiClient.create();

  Future<void> sendOtp({
    required String phone,
    required Function(LoginModel data) onSuccess,
    required Function(String message) onError,
  }) async {
    try {
      final fcmToken = await FirebaseService.getToken();

      final response = await _api.sendOtp(
        SignUpUserModel(
          phone: phone,
          firebaseToken: fcmToken,
        ),
      );

      if (response.result == "200" ||
          response.result.toLowerCase() == "success") {
        onSuccess(response);
      } else {
        onError(response.message);
      }
    } catch (e, stack) {
      // ignore: avoid_print
      print(e);
      // ignore: avoid_print
      print(stack);
      onError("Something went wrong. Please try again");
    }
  }
}
