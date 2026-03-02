import 'package:equatable/equatable.dart';

import 'package:win_app/features/auth/data/models/user_model.dart';

/// Helper function to parse double from dynamic value (String or num)
double? _parseDouble(dynamic value) {
  if (value == null) return null;
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value);
  return null;
}

class ReviewEstablishment {
  final String id;
  final String name;
  final String? nameAr;
  final String? slug;
  final String? logo;

  const ReviewEstablishment({
    required this.id,
    required this.name,
    this.nameAr,
    this.slug,
    this.logo,
  });

  factory ReviewEstablishment.fromJson(Map<String, dynamic> json) {
    return ReviewEstablishment(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      nameAr: json['name_ar'],
      slug: json['slug'],
      logo: json['logo'],
    );
  }
}

class Review extends Equatable {
  final String id;
  final String establishmentId;
  final String userId;
  final int rating;
  final String? title;
  final String comment;
  final List<String>? pros;
  final List<String>? cons;
  final List<String>? images;
  final DateTime? visitDate;
  final int helpfulCount;
  final String? partnerReply;
  final DateTime? partnerReplyAt;
  final String status;
  final String? rejectionReason;
  final User? user;
  final ReviewEstablishment? establishment;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Review({
    required this.id,
    required this.establishmentId,
    required this.userId,
    required this.rating,
    this.title,
    required this.comment,
    this.pros,
    this.cons,
    this.images,
    this.visitDate,
    this.helpfulCount = 0,
    this.partnerReply,
    this.partnerReplyAt,
    this.status = 'pending',
    this.rejectionReason,
    this.user,
    this.establishment,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get hasPartnerReply => partnerReply != null && partnerReply!.isNotEmpty;
  bool get hasImages => images != null && images!.isNotEmpty;
  bool get hasPros => pros != null && pros!.isNotEmpty;
  bool get hasCons => cons != null && cons!.isNotEmpty;
  bool get isApproved => status == 'approved';
  bool get isRejected => status == 'rejected';
  bool get hasRejectionReason => rejectionReason != null && rejectionReason!.isNotEmpty;

  factory Review.fromJson(Map<String, dynamic> json) {
    return Review(
      id: json['id'] ?? '',
      establishmentId: json['establishment_id'] ?? '',
      userId: json['user_id'] ?? '',
      rating: json['rating'] ?? 0,
      title: json['title'],
      comment: json['comment'] ?? '',
      pros: json['pros'] != null ? List<String>.from(json['pros']) : null,
      cons: json['cons'] != null ? List<String>.from(json['cons']) : null,
      images: json['images'] != null ? List<String>.from(json['images']) : null,
      visitDate: json['visit_date'] != null
          ? DateTime.parse(json['visit_date'])
          : null,
      helpfulCount: json['helpful_count'] ?? 0,
      partnerReply: json['partner_reply'],
      partnerReplyAt: json['partner_reply_at'] != null
          ? DateTime.parse(json['partner_reply_at'])
          : null,
      status: json['status'] ?? 'pending',
      rejectionReason: json['rejection_reason'],
      user: json['user'] != null ? User.fromJson(json['user']) : null,
      establishment: json['establishment'] != null
          ? ReviewEstablishment.fromJson(json['establishment'])
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'rating': rating,
      'title': title,
      'comment': comment,
      'pros': pros,
      'cons': cons,
      'images': images,
      'visit_date': visitDate?.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [
        id,
        establishmentId,
        userId,
        rating,
        comment,
        helpfulCount,
        status,
        createdAt,
      ];
}

class ReviewsResponse {
  final List<Review> reviews;
  final Map<int, int> ratingDistribution;
  final double averageRating;
  final int totalReviews;

  ReviewsResponse({
    required this.reviews,
    required this.ratingDistribution,
    required this.averageRating,
    required this.totalReviews,
  });

  factory ReviewsResponse.fromJson(Map<String, dynamic> json) {
    final reviewsList =
        (json['reviews'] as List?)?.map((e) => Review.fromJson(e)).toList() ??
            [];

    final distribution = <int, int>{1: 0, 2: 0, 3: 0, 4: 0, 5: 0};
    if (json['rating_distribution'] != null) {
      final dist = json['rating_distribution'] as Map<String, dynamic>;
      dist.forEach((key, value) {
        distribution[int.parse(key)] = value as int;
      });
    }

    return ReviewsResponse(
      reviews: reviewsList,
      ratingDistribution: distribution,
      averageRating: _parseDouble(json['average_rating']) ?? 0.0,
      totalReviews: json['total_reviews'] ?? 0,
    );
  }
}
