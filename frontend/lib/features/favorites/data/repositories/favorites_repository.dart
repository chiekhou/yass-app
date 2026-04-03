import '../../../../core/network/api_client.dart';
import '../../../../core/constants/api_config.dart';
import '../../../../shared/models/api_response.dart';
import '../../../establishment/data/models/establishment_model.dart';

class FavoriteRepository {
  final ApiClient _apiClient = ApiClient.instance;

  /// Get user's favorites
  Future<PaginatedResponse<Establishment>> getFavorites({
    String? categoryId,
    String? wilayaId,
    int page = 1,
    int limit = 20,
  }) async {
    final response = await _apiClient.get(
      ApiConfig.favorites,
      queryParameters: {
        'page': page,
        'limit': limit,
        if (categoryId != null) 'category_id': categoryId,
        if (wilayaId != null) 'wilaya_id': wilayaId,
      },
    );

    final data = response.data['data']['favorites'] as List;
    final establishments = data.map((e) {
      return Establishment.fromJson(e['establishment']);
    }).toList();
    final pagination = Pagination.fromJson(response.data['data']['pagination']);

    return PaginatedResponse(items: establishments, pagination: pagination);
  }

  /// Get favorites count
  Future<int> getCount() async {
    final response = await _apiClient.get(ApiConfig.favoritesCount);
    return response.data['data']['count'] ?? 0;
  }

  /// Add to favorites
  Future<void> add(String establishmentId) async {
    await _apiClient.post(ApiConfig.favoriteById(establishmentId));
  }

  /// Remove from favorites
  Future<void> remove(String establishmentId) async {
    await _apiClient.delete(ApiConfig.favoriteById(establishmentId));
  }

  /// Toggle favorite
  Future<bool> toggle(String establishmentId) async {
    final response = await _apiClient.post(
      ApiConfig.toggleFavorite(establishmentId),
    );
    return response.data['data']['is_favorited'] ?? false;
  }

  /// Check if favorited
  Future<bool> isFavorited(String establishmentId) async {
    final response = await _apiClient.get(
      ApiConfig.checkFavorite(establishmentId),
    );
    return response.data['data']['is_favorited'] ?? false;
  }

  /// Check multiple favorites
  Future<Map<String, bool>> checkMultiple(List<String> establishmentIds) async {
    final response = await _apiClient.post(
      ApiConfig.checkMultipleFavorites,
      data: {'establishment_ids': establishmentIds},
    );

    final Map<String, dynamic> data = response.data['data']['favorites'] ?? {};
    return data.map((key, value) => MapEntry(key, value as bool));
  }

  /// Clear all favorites
  Future<void> clearAll() async {
    await _apiClient.delete(ApiConfig.favorites);
  }
}
