import 'dart:async';
import 'package:carsbuzz/network/data_state.dart';

import '../network/repository_api.dart';
import '../models/signup_user_model.dart';
import '../models/login_model.dart';
import '../storage/app_shared_preferences.dart';

class LoginRepo {
  final RepositoryApi retrofit;
  final AppSharedPreferences sharedPreferences;

  LoginRepo({
    required this.retrofit,
    required this.sharedPreferences,
  });

  Stream<DataState<LoginModel>> getUsername(
    SignUpUserModel signUpUserModel,
  ) async* {
    try {
      final networkCall =
          await retrofit.sendOtp(signUpUserModel);

      final user = null;

      if (user != null) {
        await sharedPreferences.saveUserId(user.id);
        await sharedPreferences.saveUsername(user.username);
        await sharedPreferences.saveDealerCity(user.city);
        await sharedPreferences.saveDealerState(user.state);
        await sharedPreferences.savePremium(user.isPremium);
      }

      await sharedPreferences.setPolicies(networkCall.policies);
      await sharedPreferences.setTerms(networkCall.terms);
      await sharedPreferences.setIsLoggedIn(true);

      yield Success(networkCall);
    } catch (e) {
      yield Failure(e is Exception ? e : Exception(e.toString()));
    }
  }
}
