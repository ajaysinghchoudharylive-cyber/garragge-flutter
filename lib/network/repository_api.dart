import 'package:carsbuzz/models/category_response.dart';
import 'package:carsbuzz/models/get_all_groups_response.dart';
import 'package:carsbuzz/models/address_request.dart';
import 'package:carsbuzz/models/address_response.dart';
import 'package:carsbuzz/models/toggle_address_status_request.dart';
import 'package:carsbuzz/models/banner_data_response.dart';
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

  @GET(ApiConstants.getCategoryGroups)
  Future<List<GetAllGroupsResponse>> getGroup();
  
  // Address APIs
  @POST(ApiConstants.saveAddress)
  Future<bool> saveAddress(
    @Body() AddressRequest request,
  );
  
  @GET(ApiConstants.getCurrentAddress)
  Future<AddressResponse?> getCurrentAddress(
    @Path("userId") int userId,
  );
  
  @GET(ApiConstants.getAllAddresses)
  Future<List<AddressResponse>> getAllAddresses(
    @Path("userId") int userId,
  );
  
  @PUT(ApiConstants.updateStatusAddress)
  Future<List<AddressResponse>> updateStatusAddress(
    @Body() ToggleAddressStatusRequest request,
  );
  
  // Banners API
  @GET(ApiConstants.carDetailingBanners)
  Future<List<BannerDataResponse>> getBanners();
}
