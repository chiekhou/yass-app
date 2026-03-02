import 'package:equatable/equatable.dart';
import 'admin_partner_model.dart';

/// Helper function to parse double from dynamic value (String or num)
double? _parseDouble(dynamic value) {
  if (value == null) return null;
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value);
  return null;
}

class AdminEstablishment extends Equatable {
  final String id;
  final String partnerId;
  final String name;
  final String? slug;
  final String? description;
  final String? logo;
  final String? coverImage;
  final String? address;
  final String? phone;
  final String? whatsapp;
  final String? email;
  final String? website;
  final double? latitude;
  final double? longitude;
  final String status;
  final bool isFeatured;
  final bool isVerified;
  final String? rejectionReason;
  final String? categoryId;
  final String? categoryName;
  final String? subcategoryId;
  final String? subcategoryName;
  final String? wilayaId;
  final String? wilayaName;
  final String? communeId;
  final String? communeName;
  final DateTime createdAt;
  final DateTime updatedAt;
  final AdminPartner? partner;
  final double averageRating;
  final int reviewsCount;

  const AdminEstablishment({
    required this.id,
    required this.partnerId,
    required this.name,
    this.slug,
    this.description,
    this.logo,
    this.coverImage,
    this.address,
    this.phone,
    this.whatsapp,
    this.email,
    this.website,
    this.latitude,
    this.longitude,
    required this.status,
    this.isFeatured = false,
    this.isVerified = false,
    this.rejectionReason,
    this.categoryId,
    this.categoryName,
    this.subcategoryId,
    this.subcategoryName,
    this.wilayaId,
    this.wilayaName,
    this.communeId,
    this.communeName,
    required this.createdAt,
    required this.updatedAt,
    this.partner,
    this.averageRating = 0.0,
    this.reviewsCount = 0,
  });

  bool get isPending => status == 'pending';
  bool get isActive => status == 'active';
  bool get isRejected => status == 'rejected';
  bool get isSuspended => status == 'suspended';

  String get statusLabel {
    switch (status) {
      case 'pending':
        return 'En attente';
      case 'active':
        return 'Actif';
      case 'rejected':
        return 'Rejeté';
      case 'suspended':
        return 'Suspendu';
      case 'draft':
        return 'Brouillon';
      default:
        return status;
    }
  }

  factory AdminEstablishment.fromJson(Map<String, dynamic> json) {
    return AdminEstablishment(
      id: json['id'] ?? '',
      partnerId: json['partner_id'] ?? json['partnerId'] ?? '',
      name: json['name'] ?? '',
      slug: json['slug'],
      description: json['description'],
      logo: json['logo'],
      coverImage: json['cover_image'] ?? json['coverImage'],
      address: json['address'],
      phone: json['phone'],
      whatsapp: json['whatsapp'],
      email: json['email'],
      website: json['website'],
      latitude: _parseDouble(json['latitude']),
      longitude: _parseDouble(json['longitude']),
      status: json['status'] ?? 'pending',
      isFeatured: json['is_featured'] ?? json['isFeatured'] ?? false,
      isVerified: json['is_verified'] ?? json['isVerified'] ?? false,
      rejectionReason: json['rejection_reason'] ?? json['rejectionReason'],
      categoryId: json['category_id'] ?? json['categoryId'],
      categoryName: json['category']?['name'] ?? json['categoryName'],
      subcategoryId: json['subcategory_id'] ?? json['subcategoryId'],
      subcategoryName: json['subcategory']?['name'] ?? json['subcategoryName'],
      wilayaId: json['wilaya_id'] ?? json['wilayaId'],
      wilayaName: json['wilaya']?['name'] ?? json['wilayaName'],
      communeId: json['commune_id'] ?? json['communeId'],
      communeName: json['commune']?['name'] ?? json['communeName'],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : json['createdAt'] != null
              ? DateTime.parse(json['createdAt'])
              : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : json['updatedAt'] != null
              ? DateTime.parse(json['updatedAt'])
              : DateTime.now(),
      partner: json['partner'] != null ? AdminPartner.fromJson(json['partner']) : null,
      averageRating: _parseDouble(json['average_rating'] ?? json['averageRating']) ?? 0.0,
      reviewsCount: json['reviews_count'] ?? json['reviewsCount'] ?? 0,
    );
  }

  @override
  List<Object?> get props => [
        id,
        partnerId,
        name,
        slug,
        description,
        logo,
        coverImage,
        address,
        phone,
        whatsapp,
        email,
        website,
        latitude,
        longitude,
        status,
        isFeatured,
        isVerified,
        rejectionReason,
        categoryId,
        categoryName,
        subcategoryId,
        subcategoryName,
        wilayaId,
        wilayaName,
        communeId,
        communeName,
        createdAt,
        updatedAt,
        partner,
        averageRating,
        reviewsCount,
      ];
}

class AdminEstablishmentPagination extends Equatable {
  final List<AdminEstablishment> establishments;
  final int total;
  final int page;
  final int limit;
  final int totalPages;

  const AdminEstablishmentPagination({
    required this.establishments,
    required this.total,
    required this.page,
    required this.limit,
    required this.totalPages,
  });

  factory AdminEstablishmentPagination.fromJson(Map<String, dynamic> json) {
    return AdminEstablishmentPagination(
      establishments: (json['data'] ?? json['establishments'] ?? [])
          .map<AdminEstablishment>((e) => AdminEstablishment.fromJson(e))
          .toList(),
      total: json['total'] ?? json['pagination']?['total'] ?? 0,
      page: json['page'] ?? json['pagination']?['page'] ?? 1,
      limit: json['limit'] ?? json['pagination']?['limit'] ?? 20,
      totalPages: json['total_pages'] ?? json['totalPages'] ?? json['pagination']?['totalPages'] ?? 1,
    );
  }

  bool get hasMore => page < totalPages;

  @override
  List<Object?> get props => [establishments, total, page, limit, totalPages];
}
