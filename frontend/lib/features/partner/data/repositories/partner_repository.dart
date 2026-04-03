import '../../../../core/network/api_client.dart';
import '../../../../core/constants/api_config.dart';
import '../../../../shared/models/api_response.dart';
import '../../../establishment/data/models/establishment_model.dart';
import '../../../reviews/data/models/review_model.dart';
import '../models/partner_stats_model.dart';
import '../models/subscription_model.dart';
import '../models/invoice_model.dart';

class PartnerRepository {
  final ApiClient _apiClient = ApiClient.instance;

  /// Get partner statistics
  Future<PartnerStats> getStats() async {
    final response = await _apiClient.get(ApiConfig.partnerStats);
    return PartnerStats.fromJson(response.data['data']);
  }

  /// Get partner establishments
  Future<PaginatedResponse<Establishment>> getEstablishments({
    String? status,
    int page = 1,
    int limit = 20,
  }) async {
    final response = await _apiClient.get(
      ApiConfig.partnerEstablishments,
      queryParameters: {
        'page': page,
        'limit': limit,
        if (status != null) 'status': status,
      },
    );

    final responseData = response.data['data'] as Map<String, dynamic>;
    final data = responseData['establishments'] as List? ?? [];
    final establishments = data.map((e) => Establishment.fromJson(e)).toList();
    final pagination = Pagination.fromJson(
      responseData['pagination'] ??
          {
            'page': page,
            'limit': limit,
            'total': data.length,
            'total_pages': 1
          },
    );

    return PaginatedResponse(items: establishments, pagination: pagination);
  }

  /// Get establishment by ID
  Future<Establishment> getEstablishmentById(String id) async {
    final response =
        await _apiClient.get(ApiConfig.partnerEstablishmentById(id));
    return Establishment.fromJson(response.data['data']);
  }

  /// Create establishment
  Future<Establishment> createEstablishment(Map<String, dynamic> data) async {
    final response = await _apiClient.post(
      ApiConfig.partnerEstablishments,
      data: data,
    );
    return Establishment.fromJson(response.data['data']);
  }

  /// Update establishment
  Future<Establishment> updateEstablishment(
      String id, Map<String, dynamic> data) async {
    final response = await _apiClient.put(
      ApiConfig.partnerEstablishmentById(id),
      data: data,
    );
    return Establishment.fromJson(response.data['data']);
  }

  /// Delete establishment
  Future<void> deleteEstablishment(String id) async {
    await _apiClient.delete(ApiConfig.partnerEstablishmentById(id));
  }

  /// Update establishment status
  Future<Establishment> updateEstablishmentStatus(
      String id, String status) async {
    final response = await _apiClient.patch(
      ApiConfig.partnerEstablishmentStatus(id),
      data: {'status': status},
    );
    return Establishment.fromJson(response.data['data']);
  }

  /// Upload establishment logo
  Future<String> uploadLogo(String establishmentId, String filePath) async {
    final response = await _apiClient.uploadFile(
      ApiConfig.partnerEstablishmentLogo(establishmentId),
      filePath: filePath,
      fieldName: 'logo',
    );
    return response.data['data']['url'] ?? '';
  }

  /// Upload establishment cover image
  Future<String> uploadCover(String establishmentId, String filePath) async {
    final response = await _apiClient.uploadFile(
      ApiConfig.partnerEstablishmentCover(establishmentId),
      filePath: filePath,
      fieldName: 'cover',
    );
    return response.data['data']['url'] ?? '';
  }

  /// Upload gallery images
  Future<List<String>> uploadGalleryImages(
      String establishmentId, List<String> filePaths) async {
    final urls = <String>[];
    for (final path in filePaths) {
      final response = await _apiClient.uploadFile(
        ApiConfig.partnerEstablishmentGallery(establishmentId),
        filePath: path,
        fieldName: 'images',
      );
      urls.add(response.data['data']['url'] ?? '');
    }
    return urls;
  }

  /// Delete gallery image
  Future<void> deleteGalleryImage(String establishmentId, String imageUrl) async {
    await _apiClient.delete(
      ApiConfig.partnerEstablishmentGallery(establishmentId),
      data: {'image_url': imageUrl},
    );
  }

  /// Delete logo
  Future<void> deleteLogo(String establishmentId) async {
    await _apiClient.delete(ApiConfig.partnerEstablishmentLogo(establishmentId));
  }

  /// Delete cover
  Future<void> deleteCover(String establishmentId) async {
    await _apiClient.delete(ApiConfig.partnerEstablishmentCover(establishmentId));
  }

  // ==================== REVIEWS ====================

  /// Get reviews for a partner's establishment
  Future<ReviewsResponse> getEstablishmentReviews(
    String establishmentId, {
    int page = 1,
    int limit = 20,
  }) async {
    final response = await _apiClient.get(
      ApiConfig.establishmentReviews(establishmentId),
      queryParameters: {
        'page': page,
        'limit': limit,
      },
    );
    return ReviewsResponse.fromJson(response.data['data']);
  }

  /// Reply to a review
  Future<Review> replyToReview(String reviewId, String reply) async {
    final response = await _apiClient.post(
      ApiConfig.partnerReviewReply(reviewId),
      data: {'reply': reply},
    );
    return Review.fromJson(response.data['data']);
  }

  // ==================== SUBSCRIPTION ====================

  /// Get current subscription status
  Future<SubscriptionStatus> getSubscriptionStatus() async {
    final response = await _apiClient.get(ApiConfig.partnerSubscriptionStatus);
    return SubscriptionStatus.fromJson(response.data['data']);
  }

  /// Créer une session Chargily (paiement en ligne CIB/EDAHABIA)
  Future<String> createCheckoutSession(String plan) async {
    final response = await _apiClient.post(
      ApiConfig.partnerSubscriptionCheckout,
      data: {'plan': plan},
    );
    return response.data['data']['checkout_url'] as String;
  }

  /// Demande de paiement manuel (virement/CCP)
  Future<ManualPaymentResult> requestManualPayment(
    String plan, {
    String? transferReference,
  }) async {
    final response = await _apiClient.post(
      ApiConfig.partnerSubscriptionManual,
      data: {
        'plan': plan,
        if (transferReference != null && transferReference.isNotEmpty)
          'transfer_reference': transferReference,
      },
    );
    return ManualPaymentResult.fromJson(response.data['data']);
  }

  /// Annuler l'abonnement actif
  Future<void> cancelSubscription() async {
    await _apiClient.post(ApiConfig.partnerSubscriptionCancel);
  }

  // ==================== INVOICES ====================

  /// Liste des factures du partenaire
  Future<List<Invoice>> getInvoices() async {
    final response = await _apiClient.get(ApiConfig.partnerInvoices);
    final data = response.data['data'] as List? ?? [];
    return data.map((e) => Invoice.fromJson(e)).toList();
  }

  /// Détail d'une facture
  Future<Invoice> getInvoice(String id) async {
    final response =
        await _apiClient.get(ApiConfig.partnerInvoiceById(id));
    return Invoice.fromJson(response.data['data']);
  }
}
