import 'package:carsbuzz/models/category_response.dart';
import 'package:carsbuzz/models/get_all_groups_response.dart';
import 'package:carsbuzz/models/address_request.dart';
import 'package:carsbuzz/models/address_response.dart';
import 'package:carsbuzz/models/toggle_address_status_request.dart';
import 'package:carsbuzz/models/banner_data_response.dart';
import 'package:carsbuzz/models/car_listing_model.dart';
import 'package:carsbuzz/models/car_listing_response.dart';
import 'package:carsbuzz/models/sell_car_request.dart';
import 'package:carsbuzz/models/car_brand_model.dart';
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
  
  // Car Brands & Models
  @GET(ApiConstants.carBrands)
  Future<List<CarBrandModel>> getCarBrands();
  
  @GET(ApiConstants.carModels)
  Future<List<String>> getCarModels(
    @Path("brandName") String brandName,
  );
  
  @GET(ApiConstants.carVariants)
  Future<List<String>> getCarVariants(
    @Path("brandName") String brandName,
    @Path("modelName") String modelName,
  );
  
  // Sell Car APIs
  @POST(ApiConstants.sellCarPost)
  Future<Map<String, dynamic>> postSellCar(
    @Body() SellCarRequest request,
  );
  
  // Car Listing APIs
  @GET(ApiConstants.carListing)
  Future<CarListingResponse> getCarListing(
    @Queries() Map<String, dynamic> queryParams,
  );
  
  @GET(ApiConstants.carDetails)
  Future<CarListingModel> getCarDetails(
    @Path("carId") int carId,
  );
  
  @POST(ApiConstants.toggleFavorite)
  Future<void> toggleFavorite(
    @Body() Map<String, dynamic> body,
  );
  
  @GET(ApiConstants.getFavorites)
  Future<List<int>> getFavorites(
    @Path("userId") int userId,
  );
}
