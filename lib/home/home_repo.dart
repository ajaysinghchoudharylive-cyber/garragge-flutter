import 'package:carsbuzz/models/category_response.dart';
import 'package:carsbuzz/network/api_client.dart';
import 'package:carsbuzz/network/repository_api.dart';

class HomeRepo {
  final RepositoryApi _api = ApiClient.create();

  Future<void> fetchHomeData({
    required Function(List<CategoryResponse>) onSuccess,
    required Function(String) onError,
  }) async {
    try {
      final response = await _api.getAllCategories();
      onSuccess(response);
    } catch (e) {
      onError('Failed to load services$e');
    }
  }
}
