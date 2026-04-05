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
  static const String selectedCars = "cars/users/{userId}/selected-cars"; // Kept for backward compatibility
  static const String getSelectedCars = "cars/{userId}/selected-cars"; // GET endpoint
  static const String postSelectedCars = "cars/users/{userId}/selected-cars"; // POST endpoint
  
  // Car Brands and Models
  static const String carBrands = "cars/carLogoAndNames";
  static const String carModels = "cars/cars/{brandName}/models";
}
