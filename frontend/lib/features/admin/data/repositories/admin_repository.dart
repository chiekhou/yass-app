import '../../../../core/network/api_client.dart';
import '../../../../core/constants/api_config.dart';
import '../models/admin_stats_model.dart';
import '../models/admin_user_model.dart';
import '../models/admin_partner_model.dart';
import '../models/admin_establishment_model.dart';
import '../../../reviews/data/models/review_model.dart';

class AdminRepository {
  final ApiClient _apiClient = ApiClient.instance;

  // ==================== DASHBOARD ====================

  Future<AdminStats> getDashboardStats() async {
    final response = await _apiClient.get(ApiConfig.adminDashboard);
    return AdminStats.fromJson(response.data['data']);
  }

  // ==================== USER MANAGEMENT ====================

  Future<AdminUserPagination> getUsers({
    int page = 1,
    int limit = 20,
    String? role,
    String? status,
    String? search,
  }) async {
    final queryParams = <String, dynamic>{
      'page': page,
      'limit': limit,
    };
    if (role != null) queryParams['role'] = role;
    if (status != null) queryParams['status'] = status;
    if (search != null && search.isNotEmpty) queryParams['search'] = search;

    final response = await _apiClient.get(
      ApiConfig.adminUsers,
      queryParameters: queryParams,
    );
    return AdminUserPagination.fromJson(response.data['data']);
  }

  Future<AdminUser> getUserById(String id) async {
    final response = await _apiClient.get('${ApiConfig.adminUsers}/$id');
    return AdminUser.fromJson(response.data['data']);
  }

  Future<AdminUser> updateUserStatus(String id, String status) async {
    final response = await _apiClient.patch(
      '${ApiConfig.adminUsers}/$id/status',
      data: {'status': status},
    );
    return AdminUser.fromJson(response.data['data']);
  }

  Future<void> deleteUser(String id) async {
    await _apiClient.delete('${ApiConfig.adminUsers}/$id');
  }

  Future<AdminUser> toggleEliteStatus(String id) async {
    final response = await _apiClient.patch('${ApiConfig.adminUsers}/$id/elite');
    return AdminUser.fromJson(response.data['data']);
  }

  // ==================== ESTABLISHMENT STATS ====================

  Future<EstablishmentStatsData> getEstablishmentStats({
    String status = 'all',
  }) async {
    final response = await _apiClient.get(
      ApiConfig.adminEstablishmentStats,
      queryParameters: {'status': status},
    );
    return EstablishmentStatsData.fromJson(response.data['data']);
  }

  // ==================== PARTNER MANAGEMENT ====================

  Future<AdminPartnerPagination> getPartners({
    int page = 1,
    int limit = 20,
    String? status,
    String? search,
  }) async {
    final queryParams = <String, dynamic>{
      'page': page,
      'limit': limit,
    };
    if (status != null) queryParams['status'] = status;
    if (search != null && search.isNotEmpty) queryParams['search'] = search;

    final response = await _apiClient.get(
      ApiConfig.adminPartners,
      queryParameters: queryParams,
    );
    return AdminPartnerPagination.fromJson(response.data['data']);
  }

  Future<AdminPartnerPagination> getPendingPartners({
    int page = 1,
    int limit = 20,
  }) async {
    final response = await _apiClient.get(
      ApiConfig.adminPendingPartners,
      queryParameters: {
        'page': page,
        'limit': limit,
      },
    );
    return AdminPartnerPagination.fromJson(response.data['data']);
  }

  Future<AdminPartner> getPartnerById(String id) async {
    final response = await _apiClient.get('${ApiConfig.adminPartners}/$id');
    return AdminPartner.fromJson(response.data['data']);
  }

  Future<AdminPartner> createPartner(Map<String, dynamic> data) async {
    final response = await _apiClient.post(ApiConfig.adminPartners, data: data);
    return AdminPartner.fromJson(response.data['data']);
  }

  Future<Map<String, dynamic>> createEstablishment(Map<String, dynamic> data) async {
    final response = await _apiClient.post(ApiConfig.adminEstablishments, data: data);
    return response.data['data'] as Map<String, dynamic>;
  }

  Future<AdminPartner> approvePartner(String id) async {
    final response = await _apiClient.post(
      '${ApiConfig.adminPartners}/$id/approve',
    );
    return AdminPartner.fromJson(response.data['data']);
  }

  Future<AdminPartner> rejectPartner(String id, String reason) async {
    final response = await _apiClient.post(
      '${ApiConfig.adminPartners}/$id/reject',
      data: {'reason': reason},
    );
    return AdminPartner.fromJson(response.data['data']);
  }

  Future<AdminPartner> suspendPartner(String id, String reason) async {
    final response = await _apiClient.post(
      '${ApiConfig.adminPartners}/$id/suspend',
      data: {'reason': reason},
    );
    return AdminPartner.fromJson(response.data['data']);
  }

  // ==================== ESTABLISHMENT MANAGEMENT ====================

  Future<AdminEstablishmentPagination> getEstablishments({
    int page = 1,
    int limit = 20,
    String? status,
    String? search,
    String? subscriptionPlan,
  }) async {
    final queryParams = <String, dynamic>{
      'page': page,
      'limit': limit,
    };
    if (status != null) queryParams['status'] = status;
    if (search != null && search.isNotEmpty) queryParams['search'] = search;
    if (subscriptionPlan != null) queryParams['subscription_plan'] = subscriptionPlan;

    final response = await _apiClient.get(
      ApiConfig.adminEstablishments,
      queryParameters: queryParams,
    );
    return AdminEstablishmentPagination.fromJson(response.data['data']);
  }

  Future<AdminEstablishmentPagination> getPendingEstablishments({
    int page = 1,
    int limit = 20,
  }) async {
    final response = await _apiClient.get(
      ApiConfig.adminPendingEstablishments,
      queryParameters: {
        'page': page,
        'limit': limit,
      },
    );
    return AdminEstablishmentPagination.fromJson(response.data['data']);
  }

  Future<AdminEstablishment> approveEstablishment(String id) async {
    final response = await _apiClient.post(
      '${ApiConfig.adminEstablishments}/$id/approve',
    );
    return AdminEstablishment.fromJson(response.data['data']);
  }

  Future<AdminEstablishment> rejectEstablishment(String id, String reason) async {
    final response = await _apiClient.post(
      '${ApiConfig.adminEstablishments}/$id/reject',
      data: {'reason': reason},
    );
    return AdminEstablishment.fromJson(response.data['data']);
  }

  Future<AdminEstablishment> getEstablishmentById(String id) async {
    final response = await _apiClient.get(ApiConfig.adminEstablishmentById(id));
    return AdminEstablishment.fromJson(response.data['data']);
  }

  Future<AdminEstablishment> updateEstablishment(String id, Map<String, dynamic> data) async {
    final response = await _apiClient.patch(
      ApiConfig.adminEstablishmentById(id),
      data: data,
    );
    return AdminEstablishment.fromJson(response.data['data']);
  }

  Future<void> deleteEstablishment(String id) async {
    await _apiClient.delete(ApiConfig.adminEstablishmentById(id));
  }

  /// Associe (ou dissocie) un partenaire à un établissement.
  /// partnerId = null → détacher le partenaire
  Future<AdminEstablishment> assignPartner(String id, String? partnerId) async {
    final response = await _apiClient.patch(
      '${ApiConfig.adminEstablishments}/$id/assign-partner',
      data: {'partner_id': partnerId},
    );
    return AdminEstablishment.fromJson(response.data['data']);
  }

  /// durationDays = null → sans limite, 0 → retirer, >0 → durée en jours
  Future<AdminEstablishment> setFeatured(String id, {int? durationDays}) async {
    final response = await _apiClient.post(
      ApiConfig.adminFeatureEstablishment(id),
      data: {'duration_days': durationDays},
    );
    return AdminEstablishment.fromJson(response.data['data']);
  }

  // ==================== REVIEW MODERATION ====================

  Future<Map<String, dynamic>> getAllReviews({
    int page = 1,
    int limit = 20,
    String status = 'all',
    String? search,
  }) async {
    final queryParams = <String, dynamic>{
      'page': page,
      'limit': limit,
      'status': status,
    };
    if (search != null && search.isNotEmpty) queryParams['search'] = search;
    final response = await _apiClient.get(
      ApiConfig.adminReviews,
      queryParameters: queryParams,
    );
    return response.data['data'] as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getPendingReviews({
    int page = 1,
    int limit = 20,
  }) async {
    final response = await _apiClient.get(
      ApiConfig.adminPendingReviews,
      queryParameters: {
        'page': page,
        'limit': limit,
      },
    );
    return response.data['data'] as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getReportedReviews({
    int page = 1,
    int limit = 20,
  }) async {
    final response = await _apiClient.get(
      ApiConfig.adminReportedReviews,
      queryParameters: {
        'page': page,
        'limit': limit,
      },
    );
    return response.data['data'] as Map<String, dynamic>;
  }

  Future<Review> approveReview(String id) async {
    final response = await _apiClient.post(
      ApiConfig.adminApproveReview(id),
    );
    return Review.fromJson(response.data['data']);
  }

  Future<Review> rejectReview(String id, String reason) async {
    final response = await _apiClient.post(
      ApiConfig.adminRejectReview(id),
      data: {'reason': reason},
    );
    return Review.fromJson(response.data['data']);
  }

  Future<Review> revokeReview(String id) async {
    final response = await _apiClient.post(ApiConfig.adminRevokeReview(id));
    return Review.fromJson(response.data['data']);
  }

  Future<Review> dismissReport(String id) async {
    final response = await _apiClient.post(
      ApiConfig.adminDismissReport(id),
    );
    return Review.fromJson(response.data['data']);
  }

  // ==================== PAYMENT MANAGEMENT ====================

  Future<List<Map<String, dynamic>>> getPendingPayments({
    int page = 1,
    int limit = 20,
  }) async {
    final response = await _apiClient.get(
      ApiConfig.adminPendingPayments,
      queryParameters: {'page': page, 'limit': limit},
    );
    final data = response.data['data'];
    final invoices = data['invoices'] as List? ?? [];
    return invoices.cast<Map<String, dynamic>>();
  }

  Future<Map<String, dynamic>> validatePayment(String invoiceId) async {
    final response = await _apiClient.post(
      ApiConfig.adminValidatePayment(invoiceId),
    );
    return response.data['data'] as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> cancelPayment(String invoiceId) async {
    final response = await _apiClient.post(
      ApiConfig.adminCancelPayment(invoiceId),
    );
    return response.data['data'] as Map<String, dynamic>;
  }

  // ==================== WILAYA AVAILABILITY ====================

  Future<List<Map<String, dynamic>>> getAdminWilayas() async {
    final response = await _apiClient.get(ApiConfig.adminWilayas);
    return (response.data['data'] as List).cast<Map<String, dynamic>>();
  }

  Future<Map<String, dynamic>> toggleWilaya(String id) async {
    final response = await _apiClient.patch(ApiConfig.adminToggleWilaya(id));
    return response.data['data'] as Map<String, dynamic>;
  }

  // ==================== CATEGORY AVAILABILITY ====================

  Future<List<Map<String, dynamic>>> getAdminCategories() async {
    final response = await _apiClient.get(ApiConfig.adminCategories);
    return (response.data['data'] as List).cast<Map<String, dynamic>>();
  }

  Future<Map<String, dynamic>> toggleCategory(String id) async {
    final response = await _apiClient.patch(ApiConfig.adminToggleCategory(id));
    return response.data['data'] as Map<String, dynamic>;
  }

  // ==================== SUGGESTIONS ====================

  Future<int> getPendingSuggestionsCount() async {
    final response = await _apiClient.get(
      ApiConfig.adminSuggestions,
      queryParameters: {'status': 'pending', 'limit': 1, 'page': 1},
    );
    final pagination = response.data['pagination'];
    return (pagination?['total_items'] ?? 0) as int;
  }
}
