import '../../../../core/network/api_client.dart';
import '../../../../core/constants/api_config.dart';
import '../models/category_model.dart';

class CategoryRepository {
  final ApiClient _apiClient = ApiClient.instance;

  /// Get all categories
  Future<List<Category>> getAll() async {
    final response = await _apiClient.get(ApiConfig.categories);
    final data = response.data['data'] as List;
    return data.map((e) => Category.fromJson(e)).toList();
  }

  /// Get category by ID
  Future<Category> getById(String id) async {
    final response = await _apiClient.get(ApiConfig.categoryById(id));
    return Category.fromJson(response.data['data']);
  }

  /// Get category by slug
  Future<Category> getBySlug(String slug) async {
    final response = await _apiClient.get(ApiConfig.categoryBySlug(slug));
    return Category.fromJson(response.data['data']);
  }

  /// Get subcategories by category
  Future<List<SubCategory>> getSubcategories(String categoryId) async {
    final response = await _apiClient.get(
      ApiConfig.subcategoriesByCategory(categoryId),
    );
    final data = response.data['data'] as List;
    return data.map((e) => SubCategory.fromJson(e)).toList();
  }

  /// Search categories
  Future<List<Category>> search(String query) async {
    final response = await _apiClient.get(
      ApiConfig.searchCategories,
      queryParameters: {'q': query},
    );
    final data = response.data['data'] as List;
    return data.map((e) => Category.fromJson(e)).toList();
  }
}

class WilayaRepository {
  final ApiClient _apiClient = ApiClient.instance;

  /// Get all wilayas
  Future<List<Wilaya>> getAll() async {
    final response = await _apiClient.get(ApiConfig.wilayas);
    final data = response.data['data'] as List;
    return data.map((e) => Wilaya.fromJson(e)).toList();
  }

  /// Get wilaya by ID
  Future<Wilaya> getById(String id) async {
    final response = await _apiClient.get(ApiConfig.wilayaById(id));
    return Wilaya.fromJson(response.data['data']);
  }

  /// Get wilaya by code
  Future<Wilaya> getByCode(String code) async {
    final response = await _apiClient.get(ApiConfig.wilayaByCode(code));
    return Wilaya.fromJson(response.data['data']);
  }

  /// Get communes by wilaya
  Future<List<Commune>> getCommunes(String wilayaId) async {
    final response = await _apiClient.get(
      ApiConfig.communesByWilaya(wilayaId),
    );
    final data = response.data['data'] as List;
    return data.map((e) => Commune.fromJson(e)).toList();
  }

  /// Search wilayas
  Future<List<Wilaya>> search(String query) async {
    final response = await _apiClient.get(
      ApiConfig.searchWilayas,
      queryParameters: {'q': query},
    );
    final data = response.data['data'] as List;
    return data.map((e) => Wilaya.fromJson(e)).toList();
  }
}
