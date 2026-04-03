import 'package:equatable/equatable.dart';
import '../../../auth/data/models/user_model.dart';

/// Résumé léger d'un établissement inclus dans la réponse du partenaire
class PartnerEstablishmentSummary extends Equatable {
  final String id;
  final String name;
  final String status;
  final String? address;
  final String? phone;
  final String? categoryName;
  final String? communeName;
  final String? wilayaName;

  const PartnerEstablishmentSummary({
    required this.id,
    required this.name,
    required this.status,
    this.address,
    this.phone,
    this.categoryName,
    this.communeName,
    this.wilayaName,
  });

  String get statusLabel {
    switch (status) {
      case 'active': return 'Actif';
      case 'pending': return 'En attente';
      case 'rejected': return 'Rejeté';
      case 'suspended': return 'Suspendu';
      case 'draft': return 'Brouillon';
      default: return status;
    }
  }

  factory PartnerEstablishmentSummary.fromJson(Map<String, dynamic> json) {
    return PartnerEstablishmentSummary(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      status: json['status'] ?? 'pending',
      address: json['address'],
      phone: json['phone'],
      categoryName: json['subcategory']?['name'] ?? json['subcategoryName'],
      communeName: json['commune']?['name'] ?? json['communeName'],
      wilayaName: json['wilaya']?['name'] ?? json['wilayaName'],
    );
  }

  @override
  List<Object?> get props => [id, name, status, address, phone];
}

class AdminPartner extends Equatable {
  final String id;
  final String userId;
  final String companyName;
  final String? registrationNumber;
  final String? taxId;
  final String status;
  final String subscriptionPlan;
  final String? rejectionReason;
  final String? suspensionReason;
  final DateTime? verifiedAt;
  final String? verifiedBy;
  final DateTime createdAt;
  final DateTime updatedAt;
  final User? user;
  final int establishmentsCount;
  final List<PartnerEstablishmentSummary>? establishments;

  const AdminPartner({
    required this.id,
    required this.userId,
    required this.companyName,
    this.registrationNumber,
    this.taxId,
    required this.status,
    required this.subscriptionPlan,
    this.rejectionReason,
    this.suspensionReason,
    this.verifiedAt,
    this.verifiedBy,
    required this.createdAt,
    required this.updatedAt,
    this.user,
    this.establishmentsCount = 0,
    this.establishments,
  });

  bool get isPending => status == 'pending';
  bool get isApproved => status == 'approved';
  bool get isRejected => status == 'rejected';
  bool get isSuspended => status == 'suspended';

  String get statusLabel {
    switch (status) {
      case 'pending':
        return 'En attente';
      case 'approved':
        return 'Approuvé';
      case 'rejected':
        return 'Rejeté';
      case 'suspended':
        return 'Suspendu';
      default:
        return status;
    }
  }

  factory AdminPartner.fromJson(Map<String, dynamic> json) {
    return AdminPartner(
      id: json['id'] ?? '',
      userId: json['user_id'] ?? json['userId'] ?? '',
      companyName: json['company_name'] ?? json['companyName'] ?? '',
      registrationNumber: json['registration_number'] ?? json['registrationNumber'],
      taxId: json['tax_id'] ?? json['taxId'],
      status: json['status'] ?? 'pending',
      subscriptionPlan: json['subscription_plan'] ?? json['subscriptionPlan'] ?? 'free',
      rejectionReason: json['rejection_reason'] ?? json['rejectionReason'],
      suspensionReason: json['suspension_reason'] ?? json['suspensionReason'],
      verifiedAt: json['verified_at'] != null
          ? DateTime.parse(json['verified_at'])
          : json['verifiedAt'] != null
              ? DateTime.parse(json['verifiedAt'])
              : null,
      verifiedBy: json['verified_by'] ?? json['verifiedBy'],
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
      user: json['user'] != null ? User.fromJson(json['user']) : null,
      establishments: json['establishments'] != null
          ? (json['establishments'] as List)
              .map((e) => PartnerEstablishmentSummary.fromJson(e))
              .toList()
          : null,
      establishmentsCount: json['establishments_count'] != null
          ? int.tryParse(json['establishments_count'].toString()) ?? 0
          : json['establishmentsCount'] != null
              ? json['establishmentsCount'] as int
              : (json['establishments'] as List?)?.length ?? 0,
    );
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        companyName,
        registrationNumber,
        taxId,
        status,
        subscriptionPlan,
        rejectionReason,
        suspensionReason,
        verifiedAt,
        verifiedBy,
        createdAt,
        updatedAt,
        user,
        establishmentsCount,
        establishments,
      ];
}

class AdminPartnerPagination extends Equatable {
  final List<AdminPartner> partners;
  final int total;
  final int page;
  final int limit;
  final int totalPages;

  const AdminPartnerPagination({
    required this.partners,
    required this.total,
    required this.page,
    required this.limit,
    required this.totalPages,
  });

  factory AdminPartnerPagination.fromJson(Map<String, dynamic> json) {
    return AdminPartnerPagination(
      partners: (json['data'] ?? json['partners'] ?? [])
          .map<AdminPartner>((e) => AdminPartner.fromJson(e))
          .toList(),
      total: json['total'] ?? json['pagination']?['total'] ?? 0,
      page: json['page'] ?? json['pagination']?['page'] ?? 1,
      limit: json['limit'] ?? json['pagination']?['limit'] ?? 20,
      totalPages: json['total_pages'] ?? json['totalPages'] ?? json['pagination']?['totalPages'] ?? 1,
    );
  }

  bool get hasMore => page < totalPages;

  @override
  List<Object?> get props => [partners, total, page, limit, totalPages];
}
