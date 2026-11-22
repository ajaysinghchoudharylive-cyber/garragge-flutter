import 'dart:math' as math;

import 'package:carsbuzz/sellcar/models/sell_car_models.dart';

/// One car ad as returned by cars/filter, cars/ad-details and cars/getCarAdsByUser
/// (Android CarListingEntity / MyCarAdsModelItem). Every field is tolerant of missing keys.
class CarAd {
  final int id;
  final String make;
  final String model;
  final String kmDriven;
  final String transmission;
  final String price; // as stored, e.g. "5,00,000"
  final String owners;
  final String fuelType;
  final String city;
  final String state;
  final String ownerType;
  final String phoneNumber;
  final String ownerName;
  final String color;
  final int body;
  final int year;
  final String seatingCapacity;
  final String? insurance, registration, battery, tyre, brakes, service, loan, puc, challan;
  final String statusMessage;
  final int isVerified;
  final double? latitude;
  final double? longitude;
  final List<String> images;

  // My Ads only
  final int viewCount;
  final int leadCount;

  CarAd({
    required this.id,
    required this.make,
    required this.model,
    required this.kmDriven,
    required this.transmission,
    required this.price,
    required this.owners,
    required this.fuelType,
    required this.city,
    required this.state,
    required this.ownerType,
    required this.phoneNumber,
    required this.ownerName,
    required this.color,
    required this.body,
    required this.year,
    required this.seatingCapacity,
    this.insurance,
    this.registration,
    this.battery,
    this.tyre,
    this.brakes,
    this.service,
    this.loan,
    this.puc,
    this.challan,
    required this.statusMessage,
    required this.isVerified,
    this.latitude,
    this.longitude,
    required this.images,
    this.viewCount = 0,
    this.leadCount = 0,
  });

  static String _s(dynamic v) {
    final s = v?.toString() ?? '';
    return s == 'null' ? '' : s;
  }

  static int _i(dynamic v) => v is num ? v.toInt() : int.tryParse(_s(v)) ?? 0;

  static double? _d(dynamic v) {
    final d = v is num ? v.toDouble() : double.tryParse(_s(v));
    return (d == null || d == 0) ? null : d;
  }

  factory CarAd.fromJson(Map<String, dynamic> j) {
    final rawImages = j['carsImagesUrlEntities'] ?? j['s3GenericImage'];
    final images = <String>[];
    if (rawImages is List) {
      for (final e in rawImages) {
        final url = e is Map ? _s(e['imagesUrls']) : _s(e);
        if (url.isNotEmpty) images.add(url);
      }
    }
    final carMake = _s(j['car_make']);
    return CarAd(
      id: _i(j['id']),
      make: carMake.isNotEmpty ? carMake : _s(j['make']),
      model: _s(j['cars_model']),
      kmDriven: _s(j['cars_km_driven']),
      transmission: _s(j['cars_transmission']),
      price: _s(j['car_price']),
      owners: _s(j['cars_owners']),
      fuelType: _s(j['cars_fuel_type']),
      city: _s(j['cars_city']),
      state: _s(j['state']),
      ownerType: _s(j['cars_owner_type']),
      phoneNumber: _s(j['phone_number']),
      ownerName: _s(j['owner_name']),
      color: _s(j['color']),
      body: _i(j['body']),
      year: _i(j['cars_registration_year']),
      seatingCapacity: _s(j['seating_capacity']),
      insurance: _s(j['insurance']),
      registration: _s(j['registration']),
      battery: _s(j['battery']),
      tyre: _s(j['tyre']),
      brakes: _s(j['brakes']),
      service: _s(j['service']),
      loan: _s(j['loan']),
      puc: _s(j['puc']),
      challan: _s(j['challan']),
      statusMessage: _s(j['status_message']),
      isVerified: _i(j['is_verified']),
      latitude: _d(j['latitude']),
      longitude: _d(j['longitude']),
      images: images,
      viewCount: _i(j['viewCount']),
      leadCount: _i(j['leadCount']),
    );
  }

  String? get firstImage => images.isEmpty ? null : images.first;

  String get bodyLabel => body >= 0 && body < kBodyTypeLabels.length ? kBodyTypeLabels[body] : '';

  /// Android CarsBuzzLinks.carAd.
  String get shareUrl => 'https://www.garragge.com/cars/$id';

  double get priceValue => double.tryParse(price.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0;
}

/// Android Utilities.calculateEMI: 80% loan, 9.5% a year, 60 months. Returns "₹16,801".
String emiFor(double price) {
  if (price <= 0) return '₹0';
  final p = price * 0.8;
  const r = 9.5 / 12 / 100;
  const n = 60;
  final pow = math.pow(1 + r, n).toDouble();
  final emi = pow <= 1 ? p / n : p * r * pow / (pow - 1);
  return '₹${groupThousands(emi.round())}';
}

/// Android Utilities.calculateSaveAmount.
String saveFor(double price) {
  final save = math.max(price * 0.025, 15000.0);
  if (save >= 100000) return 'Save ₹${(save / 100000).toStringAsFixed(1)}L';
  return 'Save ₹${(save / 1000).floor()}K';
}

String groupThousands(int v) {
  final s = v.abs().toString();
  final buf = StringBuffer();
  for (int i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
    buf.write(s[i]);
  }
  return v < 0 ? '-$buf' : buf.toString();
}

/// Great-circle distance in km, null when either side has no coordinates.
double? distanceKm(double? lat1, double? lng1, double? lat2, double? lng2) {
  if (lat1 == null || lng1 == null || lat2 == null || lng2 == null) return null;
  const r = 6371.0;
  double rad(double d) => d * math.pi / 180;
  final dLat = rad(lat2 - lat1);
  final dLng = rad(lng2 - lng1);
  final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
      math.cos(rad(lat1)) * math.cos(rad(lat2)) * math.sin(dLng / 2) * math.sin(dLng / 2);
  return 2 * r * math.asin(math.sqrt(a));
}
