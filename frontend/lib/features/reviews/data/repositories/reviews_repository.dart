import 'package:image_picker/image_picker.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/constants/api_config.dart';
import '../../../../shared/models/api_response.dart';
import '../models/review_model.dart';

class ReviewRepository {
  final ApiClient _apiClient = ApiClient.instance;

  /// Get establishment reviews
  Future<ReviewsResponse> getEstablishmentReviews(
    String establishmentId, {
    int page = 1,
    int limit = 20,
    String? sortBy,
    String? sortOrder,
  }) async {
    final response = await _apiClient.get(
      ApiConfig.establishmentReviews(establishmentId),
      queryParameters: {
        'page': page,
        'limit': limit,
        if (sortBy != null) 'sort_by': sortBy,
        if (sortOrder != null) 'sort_order': sortOrder,
      },
    );

    return ReviewsResponse.fromJson(response.data['data']);
  }

  /// Get user's reviews
  Future<PaginatedResponse<Review>> getMyReviews({
    int page = 1,
    int limit = 20,
  }) async {
    final response = await _apiClient.get(
      ApiConfig.myReviews,
      queryParameters: {
        'page': page,
        'limit': limit,
      },
    );

    final data = response.data['data']['reviews'] as List;
    final reviews = data.map((e) => Review.fromJson(e)).toList();
    final pagination = Pagination.fromJson(response.data['data']['pagination']);

    return PaginatedResponse(items: reviews, pagination: pagination);
  }

  /// Create review
  Future<Review> create({
    required String establishmentId,
    int? rating,
    String? title,
    required String comment,
    List<String>? pros,
    List<String>? cons,
    List<String>? images,
    DateTime? visitDate,
    Map<String, int>? subRatings,
  }) async {
    final response = await _apiClient.post(
      ApiConfig.establishmentReviews(establishmentId),
      data: {
        if (rating != null) 'rating': rating,
        if (title != null) 'title': title,
        'comment': comment,
        if (pros != null) 'pros': pros,
        if (cons != null) 'cons': cons,
        if (images != null) 'images': images,
        if (visitDate != null) 'visit_date': visitDate.toIso8601String(),
        if (subRatings != null) 'sub_ratings': subRatings,
      },
    );

    return Review.fromJson(response.data['data']);
  }

  /// Update review
  Future<Review> update(
    String reviewId, {
    int? rating,
    String? title,
    String? comment,
    List<String>? pros,
    List<String>? cons,
    List<String>? images,
    DateTime? visitDate,
  }) async {
    final response = await _apiClient.put(
      ApiConfig.reviewById(reviewId),
      data: {
        if (rating != null) 'rating': rating,
        if (title != null) 'title': title,
        if (comment != null) 'comment': comment,
        if (pros != null) 'pros': pros,
        if (cons != null) 'cons': cons,
        if (images != null) 'images': images,
        if (visitDate != null) 'visit_date': visitDate.toIso8601String(),
      },
    );

    return Review.fromJson(response.data['data']);
  }

  /// Delete review
  Future<void> delete(String reviewId) async {
    await _apiClient.delete(ApiConfig.reviewById(reviewId));
  }

  /// Mark review as helpful
  Future<int> markHelpful(String reviewId) async {
    final response = await _apiClient.post(ApiConfig.markHelpful(reviewId));
    return response.data['data']['helpful_count'] ?? 0;
  }

  /// Upload review images and return their URLs
  Future<List<String>> uploadImages(List<XFile> images) async {
    final response = await _apiClient.uploadFiles(
      ApiConfig.uploadReviewImages,
      filePaths: images.map((e) => e.path).toList(),
      fieldName: 'images',
    );
    final data = response.data['data']['images'] as List;
    return data.cast<String>();
  }

  /// Report review
  Future<void> report(String reviewId, String reason) async {
    await _apiClient.post(
      ApiConfig.reportReview(reviewId),
      data: {'reason': reason},
    );
  }
}
