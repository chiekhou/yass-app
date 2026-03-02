import '../../../../core/network/api_client.dart';
import '../../../../core/constants/api_config.dart';
import '../../../../shared/models/api_response.dart';
import '../models/establishment_model.dart';

class EstablishmentRepository {
  final ApiClient _apiClient = ApiClient.instance;

  /// Search establishments with filters
  Future<PaginatedResponse<Establishment>> search({
    String? query,
    String? categoryId,
    String? subcategoryId,
    String? wilayaId,
    String? communeId,
    String? priceRange,
    double? minRating,
    bool? isVerified,
    bool? isFeatured,
    double? latitude,
    double? longitude,
    int? radius,
    String? sortBy,
    String? sortOrder,
    int page = 1,
    int limit = 20,
  }) async {
    final queryParams = <String, dynamic>{
      'page': page,
      'limit': limit,
      if (query != null && query.isNotEmpty) 'q': query,
      if (categoryId != null) 'category_id': categoryId,
      if (subcategoryId != null) 'subcategory_id': subcategoryId,
      if (wilayaId != null) 'wilaya_id': wilayaId,
      if (communeId != null) 'commune_id': communeId,
      if (priceRange != null) 'price_range': priceRange,
      if (minRating != null) 'min_rating': minRating,
      if (isVerified != null) 'is_verified': isVerified,
      if (isFeatured != null) 'is_featured': isFeatured,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      if (radius != null) 'radius': radius,
      if (sortBy != null) 'sort_by': sortBy,
      if (sortOrder != null) 'sort_order': sortOrder,
    };

    final response = await _apiClient.get(
      ApiConfig.establishments,
      queryParameters: queryParams,
    );

    final responseData = response.data['data'] as Map<String, dynamic>;
    final data = responseData['establishments'] as List;
    final establishments = data.map((e) => Establishment.fromJson(e)).toList();
    final pagination = Pagination.fromJson(responseData['pagination']);

    return PaginatedResponse(items: establishments, pagination: pagination);
  }

  /// Get featured establishments
  Future<List<Establishment>> getFeatured({int limit = 10}) async {
    final response = await _apiClient.get(
      ApiConfig.featuredEstablishments,
      queryParameters: {'limit': limit},
    );

    final data = response.data['data'] as List;
    return data.map((e) => Establishment.fromJson(e)).toList();
  }

  /// Get top-rated establishments (sorted by average_rating DESC, min 3.5★)
  Future<List<Establishment>> getTopRated({int limit = 10}) async {
    final result = await search(
      sortBy: 'average_rating',
      sortOrder: 'desc',
      minRating: 3.5,
      limit: limit,
    );
    return result.items;
  }

  /// Get nearby establishments
  Future<List<Establishment>> getNearby({
    required double latitude,
    required double longitude,
    int radius = 5,
    int limit = 10,
  }) async {
    final response = await _apiClient.get(
      ApiConfig.nearbyEstablishments,
      queryParameters: {
        'latitude': latitude,
        'longitude': longitude,
        'radius': radius,
        'limit': limit,
      },
    );

    final data = response.data['data'] as List;
    return data.map((e) => Establishment.fromJson(e)).toList();
  }

  /// Get establishments by category
  Future<PaginatedResponse<Establishment>> getByCategory(
    String categoryId, {
    String? wilayaId,
    int page = 1,
    int limit = 20,
  }) async {
    final response = await _apiClient.get(
      ApiConfig.establishmentsByCategory(categoryId),
      queryParameters: {
        'page': page,
        'limit': limit,
        if (wilayaId != null) 'wilaya_id': wilayaId,
      },
    );

    final responseData = response.data['data'] as Map<String, dynamic>;
    final data = responseData['establishments'] as List;
    final establishments = data.map((e) => Establishment.fromJson(e)).toList();
    final pagination = Pagination.fromJson(responseData['pagination']);

    return PaginatedResponse(items: establishments, pagination: pagination);
  }

  /// Get establishments by wilaya
  Future<PaginatedResponse<Establishment>> getByWilaya(
    String wilayaId, {
    String? categoryId,
    int page = 1,
    int limit = 20,
  }) async {
    final response = await _apiClient.get(
      ApiConfig.establishmentsByWilaya(wilayaId),
      queryParameters: {
        'page': page,
        'limit': limit,
        if (categoryId != null) 'category_id': categoryId,
      },
    );

    final responseData = response.data['data'] as Map<String, dynamic>;
    final data = responseData['establishments'] as List;
    final establishments = data.map((e) => Establishment.fromJson(e)).toList();
    final pagination = Pagination.fromJson(responseData['pagination']);

    return PaginatedResponse(items: establishments, pagination: pagination);
  }

  /// Get establishment by ID
  Future<Establishment> getById(String id) async {
    final response = await _apiClient.get(ApiConfig.establishmentById(id));
    return Establishment.fromJson(response.data['data']);
  }

  /// Get establishment by slug
  Future<Establishment> getBySlug(String slug) async {
    final response = await _apiClient.get(ApiConfig.establishmentBySlug(slug));
    return Establishment.fromJson(response.data['data']);
  }

  /// Track phone click
  Future<void> trackPhoneClick(String id) async {
    await _apiClient.post(ApiConfig.trackPhone(id));
  }

  /// Track WhatsApp click
  Future<void> trackWhatsAppClick(String id) async {
    await _apiClient.post(ApiConfig.trackWhatsApp(id));
  }
}