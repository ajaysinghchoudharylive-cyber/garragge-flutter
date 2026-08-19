class ApiConstants {
  ApiConstants._();

  static const String baseUrl = "http://cars.garagge.in/";

  // Auth
  static const String signupPhone = "cars/login/signup";
  static const String verifyOtp = "cars/login/verify-otp";
  static const String getAllCategories = "cars/getAllCategories";
  static const String getCategoryGroups = "cars/category-groups";
  
  // Address
  static const String saveAddress = "cars/user/addresses";
  static const String getCurrentAddress = "cars/current/{userId}";
  static const String getAllAddresses = "cars/user/addresses/{userId}";
  static const String updateStatusAddress = "cars/user/toggle-active";
  
  // Banners
  static const String carDetailingBanners = "banners";
  
  // Selected Cars
  static const String selectedCars = "cars/users/{userId}/selected-cars";
  static const String getSelectedCars = "cars/{userId}/selected-cars";
  static const String postSelectedCars = "cars/users/{userId}/selected-cars";
  
  // Car Brands and Models
  static const String carBrands = "cars/carLogoAndNames";
  static const String carModels = "cars/cars/{brandName}/models";
  static const String carVariants = "cars/cars/{brandName}/{modelName}/variants";
  
  // Sell Car
  static const String sellCarPost = "cars/sell-car";
  static const String sellCarDraft = "cars/sell-car/draft/{userId}";
  static const String uploadCarImage = "cars/sell-car/upload-image";
  
  // Car Listing (Buy Car)
  static const String carListing = "cars/car-listing";
  static const String carDetails = "cars/car-details/{carId}";
  static const String toggleFavorite = "cars/favorites/toggle";
  static const String getFavorites = "cars/favorites/{userId}";
}
