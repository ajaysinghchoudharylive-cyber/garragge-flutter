import 'package:carsbuzz/models/car_brand_model.dart';
import 'package:carsbuzz/network/api_client.dart';
import 'package:carsbuzz/theme/app_colors.dart';
import 'package:flutter/foundation.dart';

/// Data for the home dashboard. Same public endpoints as the Android HomeViewModel /
/// CarsLogoNameRepository (no login needed). Every call is best-effort: on failure it returns an
/// empty list and the section hides, like Android.
class DashboardRepository {
  DashboardRepository._();

  /// GET banners/visible?clientName=mobile&placeBottom=... (admin-managed banners).
  static Future<List<DashboardBanner>> getBanners({required bool placeBottom}) async {
    try {
      final res = await ApiClient.dio.get<dynamic>(
        'banners/visible',
        queryParameters: {'clientName': 'mobile', 'placeBottom': placeBottom},
      );
      final data = res.data;
      if (data is! List) return [];
      return data
          .whereType<Map>()
          .map((e) => DashboardBanner.fromJson(Map<String, dynamic>.from(e)))
          .where((b) => b.shouldShow && b.imageUrl.isNotEmpty)
          .toList();
    } catch (e) {
      debugPrint('getBanners failed: $e');
      return [];
    }
  }

  /// GET cars/carLogoAndNames -> [{id, cars_logo, cars_name}]
  static Future<List<CarBrandModel>> getBrands() async {
    try {
      final res = await ApiClient.dio.get<dynamic>('cars/carLogoAndNames');
      final data = res.data;
      if (data is! List) return [];
      return data
          .whereType<Map>()
          .map((e) => CarBrandModel.fromJson(Map<String, dynamic>.from(e)))
          .where((b) => b.brandName.isNotEmpty)
          .toList();
    } catch (e) {
      debugPrint('getBrands failed: $e');
      return [];
    }
  }

  /// GET cars/suggestionsAll -> {brand: [model, ...]} for the search box.
  static Future<List<BrandModelPair>> getSearchSuggestions() async {
    try {
      final res = await ApiClient.dio.get<dynamic>('cars/suggestionsAll');
      final data = res.data;
      if (data is! Map) return [];
      final pairs = <BrandModelPair>[];
      data.forEach((brand, models) {
        if (models is List) {
          for (final m in models) {
            final model = m?.toString().trim() ?? '';
            if (model.isNotEmpty) {
              pairs.add(BrandModelPair(brand.toString().trim(), model));
            }
          }
        }
      });
      return pairs;
    } catch (e) {
      debugPrint('getSearchSuggestions failed: $e');
      return [];
    }
  }

  /// GET cars/popular-models -> [{id, brand, modelName, imageUrl, carBody, availableColors}]
  static Future<List<PopularModel>> getPopularModels() async {
    try {
      final res = await ApiClient.dio.get<dynamic>('cars/popular-models');
      final data = res.data;
      if (data is! List) return [];
      return data
          .whereType<Map>()
          .map((e) => PopularModel.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } catch (e) {
      debugPrint('getPopularModels failed: $e');
      return [];
    }
  }

  /// GET cars/news?page=0&size=50 -> {items: [...], page, totalPages}. Items without a slug are
  /// dropped (they can't be opened), same as Android.
  static Future<List<NewsItem>> getNews() async {
    try {
      final res = await ApiClient.dio.get<dynamic>(
        'cars/news',
        queryParameters: {'page': 0, 'size': 50},
      );
      final data = res.data;
      final items = data is Map ? data['items'] : null;
      if (items is! List) return [];
      return items
          .whereType<Map>()
          .map((e) => NewsItem.fromJson(Map<String, dynamic>.from(e)))
          .where((n) => n.slug.isNotEmpty)
          .toList();
    } catch (e) {
      debugPrint('getNews failed: $e');
      return [];
    }
  }
}

class DashboardBanner {
  final int id;
  final String imageUrl;
  final bool shouldShow;

  DashboardBanner({required this.id, required this.imageUrl, required this.shouldShow});

  factory DashboardBanner.fromJson(Map<String, dynamic> json) => DashboardBanner(
        id: (json['id'] as num?)?.toInt() ?? 0,
        imageUrl: json['imageUrl']?.toString() ?? '',
        shouldShow: json['shouldShow'] != false,
      );
}

class BrandModelPair {
  final String brand;
  final String model;
  BrandModelPair(this.brand, this.model);
}

class PopularModel {
  final int id;
  final String brand;
  final String modelName;
  final String? imageUrl;

  PopularModel({required this.id, required this.brand, required this.modelName, this.imageUrl});

  factory PopularModel.fromJson(Map<String, dynamic> json) => PopularModel(
        id: (json['id'] as num?)?.toInt() ?? 0,
        brand: json['brand']?.toString() ?? '',
        modelName: json['modelName']?.toString() ?? '',
        imageUrl: json['imageUrl']?.toString(),
      );
}

class NewsItem {
  final int id;
  final String title;
  final String slug;
  final String? categoryId;
  final String? imageUrl;
  final DateTime? publishedAt;

  NewsItem({
    required this.id,
    required this.title,
    required this.slug,
    this.categoryId,
    this.imageUrl,
    this.publishedAt,
  });

  factory NewsItem.fromJson(Map<String, dynamic> json) {
    String? url;
    final hero = json['heroImage'];
    final video = json['heroVideo'];
    if (hero is Map && (hero['url']?.toString() ?? '').isNotEmpty) {
      url = hero['url'].toString();
    } else if (video is Map && (video['url']?.toString() ?? '').isNotEmpty) {
      url = video['url'].toString();
    }
    // Relative paths are served from the news website.
    if (url != null && !url.startsWith('http')) {
      url = '${AppUrls.newsWebBase}${url.startsWith('/') ? '' : '/'}$url';
    }
    return NewsItem(
      id: (json['id'] as num?)?.toInt() ?? 0,
      title: json['title']?.toString() ?? '',
      slug: json['slug']?.toString() ?? '',
      categoryId: json['categoryId']?.toString(),
      imageUrl: url,
      publishedAt: DateTime.tryParse(json['publishedAt']?.toString() ?? ''),
    );
  }

  String get dateLabel {
    final d = publishedAt;
    if (d == null) return '';
    String two(int v) => v.toString().padLeft(2, '0');
    return '${two(d.day)}-${two(d.month)}-${d.year}';
  }

  String get articleUrl => '${AppUrls.newsWebBase}/news/$slug';
}
