import '../../../../core/network/api_client.dart';
import '../../../../core/constants/api_config.dart';
import '../models/suggestion_model.dart';

class SuggestionRepository {
  final ApiClient _api = ApiClient.instance;

  /// Soumettre une nouvelle suggestion
  Future<SuggestionModel> create({
    required String name,
    required String address,
    String? phone,
    String? description,
    String? contactEmail,
    String? reason,
    String? categoryId,
    String? wilayaId,
  }) async {
    final response = await _api.post(ApiConfig.suggestions, data: {
      'name': name,
      'address': address,
      if (phone != null && phone.isNotEmpty) 'phone': phone,
      if (description != null && description.isNotEmpty) 'description': description,
      if (contactEmail != null && contactEmail.isNotEmpty) 'contact_email': contactEmail,
      if (reason != null && reason.isNotEmpty) 'reason': reason,
      if (categoryId != null) 'category_id': categoryId,
      if (wilayaId != null) 'wilaya_id': wilayaId,
    });
    return SuggestionModel.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  /// Liste des suggestions en attente (triées par votes)
  Future<SuggestionListResult> getAll({int page = 1, int limit = 20}) async {
    final response = await _api.get(
      ApiConfig.suggestions,
      queryParameters: {'page': page, 'limit': limit},
    );
    final items = (response.data['data'] as List)
        .map((e) => SuggestionModel.fromJson(e as Map<String, dynamic>))
        .toList();
    final pagination = SuggestionPagination.fromJson(
        response.data['pagination'] as Map<String, dynamic>);
    return SuggestionListResult(items: items, pagination: pagination);
  }

  /// Mes suggestions
  Future<SuggestionListResult> getMine({int page = 1, int limit = 20}) async {
    final response = await _api.get(
      ApiConfig.mySuggestions,
      queryParameters: {'page': page, 'limit': limit},
    );
    final items = (response.data['data'] as List)
        .map((e) => SuggestionModel.fromJson(e as Map<String, dynamic>))
        .toList();
    final pagination = SuggestionPagination.fromJson(
        response.data['pagination'] as Map<String, dynamic>);
    return SuggestionListResult(items: items, pagination: pagination);
  }

  /// Voter / retirer son vote
  Future<Map<String, dynamic>> vote(String suggestionId) async {
    final response = await _api.post(ApiConfig.suggestionVote(suggestionId));
    return response.data['data'] as Map<String, dynamic>;
  }

  /// Voter contre / retirer son vote contre
  Future<Map<String, dynamic>> downvote(String suggestionId) async {
    final response = await _api.post(ApiConfig.suggestionDownvote(suggestionId));
    return response.data['data'] as Map<String, dynamic>;
  }

  // ── Admin ──────────────────────────────────────────────────────────────────

  Future<SuggestionListResult> adminGetAll({
    int page = 1,
    int limit = 20,
    String? status,
  }) async {
    final response = await _api.get(
      ApiConfig.adminSuggestions,
      queryParameters: {
        'page': page,
        'limit': limit,
        if (status != null) 'status': status,
      },
    );
    final items = (response.data['data'] as List)
        .map((e) => SuggestionModel.fromJson(e as Map<String, dynamic>))
        .toList();
    final pagination = SuggestionPagination.fromJson(
        response.data['pagination'] as Map<String, dynamic>);
    return SuggestionListResult(items: items, pagination: pagination);
  }

  Future<void> adminApprove(String id) async {
    await _api.post(ApiConfig.adminApproveSuggestion(id));
  }

  Future<void> adminReject(String id, {String? note}) async {
    await _api.post(
      ApiConfig.adminRejectSuggestion(id),
      data: {if (note != null && note.isNotEmpty) 'note': note},
    );
  }
}
