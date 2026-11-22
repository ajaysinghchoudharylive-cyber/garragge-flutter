/// Backend endpoints. These mirror the native Android app (`rest/Constants.kt`) so both apps talk
/// to the same live API. Paths are relative to [baseUrl].
class ApiConstants {
  ApiConstants._();

  static const String baseUrl = "https://cars.garagge.in/";

  // ── Auth ────────────────────────────────────────────────────────────────────
  static const String signupPhone = "cars/login/signup";
  static const String loginRefresh = "cars/login/refresh";

  /// Paths that must be called WITHOUT an Authorization header (public auth endpoints).
  static const List<String> noAuthPaths = [
    "/cars/login/signup",
    "/cars/login/refresh",
    "/cars/session/start",
  ];

  // Legacy value kept so existing references keep compiling. Not used by the live backend.
  static const String verifyOtp = "cars/login/verify-otp";

  static const String getAllCategories = "cars/getAllCategories";
  static const String getCategoryGroups = "cars/category-groups";

  // ── Address ─────────────────────────────────────────────────────────────────
  static const String saveAddress = "cars/user/addresses";
  static const String getCurrentAddress = "cars/current/{userId}";
  static const String getAllAddresses = "cars/user/addresses/{userId}";
  static const String updateStatusAddress = "cars/user/toggle-active";

  // ── Banners ─────────────────────────────────────────────────────────────────
  static const String carDetailingBanners = "banners";

  // ── Selected Cars ───────────────────────────────────────────────────────────
  static const String selectedCars = "cars/users/{userId}/selected-cars";
  static const String getSelectedCars = "cars/{userId}/selected-cars";
  static const String postSelectedCars = "cars/users/{userId}/selected-cars";

  // ── Sell car (live endpoints, same as the Android app) ──────────────────────
  /// GET -> [{id, cars_logo, cars_name}]
  static const String carBrands = "cars/carLogoAndNames";

  /// GET -> [{registration_years: int}]
  static const String registrationYears = "cars/carsRegistrationsYears";

  /// GET cars/{brandName}/models -> [{id, imageUrl, model_name, available_colors, car_body}]
  static String modelsOf(String brandName) =>
      "cars/${Uri.encodeComponent(brandName)}/models";

  /// GET cars/{brandName}/models/{modelId}/variants
  static String variantsOf(String brandName, int modelId) =>
      "cars/${Uri.encodeComponent(brandName)}/models/$modelId/variants";

  /// POST multipart: parts `carDetails` (JSON), `file` (images), optional `rcFile`; query `draftId`.
  static const String postAd = "cars/postad";

  /// GET ?userId= -> {canUpload, hasUploadPlan, unlimitedUploads, freeUploadsRemaining, ...}
  static const String uploadStatus = "cars/upload-status";

  /// GET (public) -> admin flags incl. `uploadLimitEnabled`.
  static const String featureFlags = "cars/feature-flags";

  // Remote drafts
  static const String drafts = "cars/drafts";
  static String draftById(int id) => "cars/drafts/$id";
  static String draftImages(int id) => "cars/drafts/$id/images";
  static String draftImage(int id, int imageId) =>
      "cars/drafts/$id/images/$imageId";
  static String draftComplete(int id) => "cars/drafts/$id/complete";

  // Legacy sell-car paths from the first prototype (NOT valid on the live backend). Kept only so
  // old code that still references them compiles; the sell-car module no longer uses them.
  static const String carModels = "cars/{brandName}/models";
  static const String carVariants = "cars/{brandName}/models/{modelId}/variants";
  static const String sellCarPost = "cars/postad";
  static const String sellCarDraft = "cars/drafts";
  static const String uploadCarImage = "cars/postad";

  // ── Car Listing (Buy Car) — NOT yet aligned with the Android app (next phase) ─
  static const String carListing = "cars/car-listing";
  static const String carDetails = "cars/car-details/{carId}";
  static const String toggleFavorite = "cars/favorites/toggle";
  static const String getFavorites = "cars/favorites/{userId}";
}
