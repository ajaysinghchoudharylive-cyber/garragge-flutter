import 'package:carsbuzz/models/category_response.dart';
import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../models/signup_user_model.dart';
import '../models/login_model.dart';
import 'api_constants.dart';

part 'repository_api.g.dart';

@RestApi()
abstract class RepositoryApi {
  factory RepositoryApi(Dio dio) = _RepositoryApi;

  @POST(ApiConstants.signupPhone)
  Future<LoginModel> sendOtp(
    @Body() SignUpUserModel signUpUserModel,
  );

  @GET(ApiConstants.getAllCategories)
  Future<List<CategoryResponse>> getAllCategories();

}
