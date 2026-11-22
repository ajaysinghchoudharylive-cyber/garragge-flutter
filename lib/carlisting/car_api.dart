import 'package:carsbuzz/carlisting/car_ad.dart';
import 'package:carsbuzz/network/api_client.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// One page of cars/filter.
class CarPage {
  final List<CarAd> cars;
  final int total;
  final bool isLast;
  CarPage(this.cars, this.total, this.isLast);
}

/// Search parameters for the Buy listing (Android FragmentCarListingViewModel.SearchParams).
class CarSearch {
  final String? make;
  final String? model;
  final String? fuelType;
  final String? transmission;
  final String? minPrice; // rupees
  final String? maxPrice;
  final int? bodyType;
  final String? sortBy; // price | km | null
  final String sortDirection;
  /// Brand/model search from the home screen: Android drops city, state and coordinates.
  final bool isFromSearch;

  const CarSearch({
    this.make,
    this.model,
    this.fuelType,
    this.transmission,
    this.minPrice,
    this.maxPrice,
    this.bodyType,
    this.sortBy,
    this.sortDirection = 'desc',
    this.isFromSearch = false,
  });

  CarSearch copyWith({
    String? make,
    String? model,
    String? fuelType,
    String? transmission,
    String? minPrice,
    String? maxPrice,
    String? sortBy,
    String? sortDirection,
    bool clearMake = false,
    bool clearModel = false,
    bool clearFuel = false,
    bool clearTransmission = false,
    bool clearPrice = false,
    bool clearSort = false,
    bool clearBody = false,
  }) {
    return CarSearch(
      make: clearMake ? null : make ?? this.make,
      model: clearModel ? null : model ?? this.model,
      fuelType: clearFuel ? null : fuelType ?? this.fuelType,
      transmission: clearTransmission ? null : transmission ?? this.transmission,
      minPrice: clearPrice ? null : minPrice ?? this.minPrice,
      maxPrice: clearPrice ? null : maxPrice ?? this.maxPrice,
      bodyType: clearBody ? null : bodyType,
      sortBy: clearSort ? null : sortBy ?? this.sortBy,
      sortDirection: clearSort ? 'desc' : sortDirection ?? this.sortDirection,
      isFromSearch: isFromSearch,
    );
  }
}

/// The car endpoints used by the Buy, details, My Ads and notification screens. Same requests as
/// the Android app.
class CarApi {
  CarApi._();

  static const int pageSize = 10;

  static Future<int> userId() async {
    final prefs = await SharedPreferences.getInstance();
    return int.tryParse(prefs.getString('user_id') ?? '') ?? 0;
  }

  static Future<bool> isLoggedIn() async =>
      (await SharedPreferences.getInstance()).getBool('is_logged_in') ?? false;

  /// GET cars/filter. Same rules as Android CarListingPagingSource + FragmentCarListing:
  /// - always isVerified=1 (only approved ads),
  /// - with saved coordinates the feed is ranked nearest-first and city/state are NOT sent,
  /// - without coordinates the saved city/state narrow the feed,
  /// - a home search drops location entirely,
  /// - ads with make/model "any" or no registration year are hidden.
  static Future<CarPage> search(CarSearch s, int page) async {
    final prefs = await SharedPreferences.getInstance();
    double? readDouble(String key) {
      try {
        return prefs.getDouble(key);
      } catch (_) {
        return null;
      }
    }

    final lat = s.isFromSearch ? null : readDouble('latitude');
    final lng = s.isFromSearch ? null : readDouble('longitude');
    final hasCoords = lat != null && lng != null;
    final city = s.isFromSearch || hasCoords ? '' : (prefs.getString('city') ?? '');
    final state = s.isFromSearch || hasCoords ? '' : (prefs.getString('state') ?? '');

    String? nz(String? v) => (v == null || v.trim().isEmpty) ? null : v.trim();
    final min = nz(s.minPrice);
    final max = nz(s.maxPrice);

    final query = <String, dynamic>{
      if (nz(s.make) != null) 'make': s.make,
      if (nz(s.model) != null) 'carsModel': s.model,
      if (state.isNotEmpty) 'state': state,
      if (city.isNotEmpty) 'carsCity': city,
      if (nz(s.transmission) != null) 'carsTransmission': s.transmission,
      if (nz(s.fuelType) != null) 'carsFuelType': s.fuelType,
      if (min != null && max != null) 'carPrice': '$min-$max',
      if (s.bodyType != null) 'body': s.bodyType,
      'isVerified': 1,
      'page': page,
      'size': pageSize,
      if (s.sortBy != null) 'sortBy': s.sortBy,
      'sortDirection': s.sortDirection,
      if (hasCoords) 'latitude': lat,
      if (hasCoords) 'longitude': lng,
    };

    final res = await ApiClient.dio.get<dynamic>('cars/filter', queryParameters: query);
    final data = res.data;
    final raw = data is Map ? data['data'] : null;
    final count = data is Map ? (data['count'] as num?)?.toInt() ?? 0 : 0;
    final list = raw is List ? raw.whereType<Map>().toList() : const <Map>[];
    final cars = list
        .map((e) => CarAd.fromJson(Map<String, dynamic>.from(e)))
        .where((c) =>
            c.make.toLowerCase() != 'any' && c.model.toLowerCase() != 'any' && c.year > 0)
        .toList();
    final totalPages = count > 0 ? (count / pageSize).ceil() : 1;
    final isLast = page >= totalPages - 1 || list.length < pageSize;
    return CarPage(cars, count, isLast);
  }

  /// GET cars/ad-details/{carId}?userId= -> {car, variantName, alreadyContacted, ...}
  static Future<CarDetails> details(int carId) async {
    final uid = await userId();
    final res = await ApiClient.dio
        .get<dynamic>('cars/ad-details/$carId', queryParameters: {'userId': uid});
    final data = res.data;
    if (data is! Map || data['car'] is! Map) throw Exception('Car not found');
    return CarDetails(
      car: CarAd.fromJson(Map<String, dynamic>.from(data['car'] as Map)),
      variantName: data['variantName']?.toString(),
      alreadyContacted: data['alreadyContacted'] == true,
    );
  }

  /// POST cars/increment-views {carId, userId} (logged-in users only, like Android).
  static Future<void> incrementViews(int carId) async {
    try {
      if (!await isLoggedIn()) return;
      await ApiClient.dio
          .post<dynamic>('cars/increment-views', data: {'carId': carId, 'userId': await userId()});
    } catch (e) {
      debugPrint('incrementViews failed: $e');
    }
  }

  /// POST cars/lead-record {carId, userId, type: "interested" | "contacted"}
  static Future<void> recordLead(int carId, String type) async {
    try {
      await ApiClient.dio.post<dynamic>('cars/lead-record',
          data: {'carId': carId, 'userId': await userId(), 'type': type});
    } catch (e) {
      debugPrint('recordLead failed: $e');
    }
  }

  /// GET cars/getCarAdsByUser?userId= -> [ad]
  static Future<List<CarAd>> myAds() async {
    final res = await ApiClient.dio
        .get<dynamic>('cars/getCarAdsByUser', queryParameters: {'userId': await userId()});
    final data = res.data;
    if (data is! List) return [];
    return data.whereType<Map>().map((e) => CarAd.fromJson(Map<String, dynamic>.from(e))).toList();
  }

  /// DELETE cars/removeMyAds?adId= -> {message}
  static Future<String> deleteAd(int adId) async {
    final res =
        await ApiClient.dio.delete<dynamic>('cars/removeMyAds', queryParameters: {'adId': adId});
    final data = res.data;
    return (data is Map ? data['message']?.toString() : null) ?? 'Your ad has been deleted';
  }

  /// POST cars/updatePrice {carId, price, userId}
  static Future<void> updatePrice(int carId, int price) async {
    await ApiClient.dio.post<dynamic>('cars/updatePrice',
        data: {'carId': carId, 'price': price, 'userId': await userId()});
  }

  /// GET cars/notifications?userId= -> {today: [...], last7Days: [...]}
  static Future<(List<AppNotification>, List<AppNotification>)> notifications() async {
    final res = await ApiClient.dio
        .get<dynamic>('cars/notifications', queryParameters: {'userId': await userId()});
    final data = res.data;
    List<AppNotification> parse(dynamic v) => v is List
        ? v.whereType<Map>().map((e) => AppNotification.fromJson(Map<String, dynamic>.from(e))).toList()
        : [];
    if (data is! Map) return (<AppNotification>[], <AppNotification>[]);
    return (parse(data['today']), parse(data['last7Days']));
  }

  /// Unread count for the home bell (0 for guests or on error).
  static Future<int> unreadCount() async {
    try {
      if (!await isLoggedIn()) return 0;
      final (today, week) = await notifications();
      return [...today, ...week].where((n) => !n.read).length;
    } catch (_) {
      return 0;
    }
  }

  /// PUT cars/notifications/read/{id}
  static Future<void> markRead(int id) async {
    try {
      await ApiClient.dio.put<dynamic>('cars/notifications/read/$id');
    } catch (e) {
      debugPrint('markRead failed: $e');
    }
  }
}

class CarDetails {
  final CarAd car;
  final String? variantName;
  final bool alreadyContacted;
  CarDetails({required this.car, this.variantName, required this.alreadyContacted});
}

class AppNotification {
  final int id;
  final String title;
  final String body;
  final String type;
  final int? carId;
  final String? carImage;
  bool read;

  AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    this.carId,
    this.carImage,
    required this.read,
  });

  factory AppNotification.fromJson(Map<String, dynamic> j) => AppNotification(
        id: (j['id'] as num?)?.toInt() ?? 0,
        title: j['title']?.toString() ?? '',
        body: j['body']?.toString() ?? '',
        type: j['type']?.toString() ?? '',
        carId: (j['carId'] as num?)?.toInt(),
        carImage: j['carImage']?.toString(),
        read: j['read'] == true,
      );
}

/// Favourite car ids, kept on the device like Android's Room FavouriteEntity table.
class FavoritesStore {
  FavoritesStore._();
  static const _key = 'favorite_car_ids';

  static Future<Set<int>> all() async {
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getStringList(_key) ?? []).map(int.tryParse).whereType<int>().toSet();
  }

  /// Toggles [id]; returns true if it is now a favourite.
  static Future<bool> toggle(int id) async {
    final prefs = await SharedPreferences.getInstance();
    final ids = (prefs.getStringList(_key) ?? []).toSet();
    final added = !ids.remove('$id');
    if (added) ids.add('$id');
    await prefs.setStringList(_key, ids.toList());
    return added;
  }
}
