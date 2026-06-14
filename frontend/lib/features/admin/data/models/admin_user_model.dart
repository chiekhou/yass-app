import 'package:equatable/equatable.dart';
import '../../../auth/data/models/user_model.dart';

class AdminUser extends Equatable {
  final String id;
  final String email;
  final String firstName;
  final String lastName;
  final String? phone;
  final String? avatar;
  final String role;
  final String status;
  final String language;
  final bool emailVerified;
  final String? wilayaId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final PartnerProfile? partnerProfile;
  final int reviewsCount;
  final int favoritesCount;
  final int? age;
  final String? gender;
  final DateTime? lastLogin;
  final int loginCount;
  final bool isElite;

  const AdminUser({
    required this.id,
    required this.email,
    required this.firstName,
    required this.lastName,
    this.phone,
    this.avatar,
    required this.role,
    required this.status,
    required this.language,
    required this.emailVerified,
    this.wilayaId,
    required this.createdAt,
    required this.updatedAt,
    this.partnerProfile,
    this.reviewsCount = 0,
    this.favoritesCount = 0,
    this.age,
    this.gender,
    this.lastLogin,
    this.loginCount = 0,
    this.isElite = false,
  });

  String get fullName => '$firstName $lastName';

  bool get isPartner => role == 'partner';
  bool get isAdmin => role == 'admin' || role == 'super_admin';
  bool get isActive => status == 'active';
  bool get isSuspended => status == 'suspended';
  bool get isPending => status == 'pending';
  bool get isInactive => status == 'inactive';

  String get genderLabel {
    switch (gender) {
      case 'male':
        return 'Homme';
      case 'female':
        return 'Femme';
      case 'young':
        return 'Jeune';
      case 'child':
        return 'Enfant';
      default:
        return 'Non renseigné';
    }
  }

  String get ageCategory {
    if (age == null) return 'Non renseigné';
    if (age! < 18) return 'Moins de 18 ans';
    if (age! <= 25) return '18-25 ans';
    if (age! <= 35) return '26-35 ans';
    if (age! <= 50) return '36-50 ans';
    return 'Plus de 50 ans';
  }

  String get statusLabel {
    switch (status) {
      case 'active':
        return 'Actif';
      case 'inactive':
        return 'Inactif';
      case 'pending':
        return 'En attente';
      case 'suspended':
        return 'Suspendu';
      default:
        return status;
    }
  }

  String get roleLabel {
    switch (role) {
      case 'user':
        return 'Utilisateur';
      case 'partner':
        return 'Partenaire';
      case 'admin':
        return 'Administrateur';
      case 'super_admin':
        return 'Super Admin';
      default:
        return role;
    }
  }

  factory AdminUser.fromJson(Map<String, dynamic> json) {
    return AdminUser(
      id: json['id'] ?? '',
      email: json['email'] ?? '',
      firstName: json['first_name'] ?? json['firstName'] ?? '',
      lastName: json['last_name'] ?? json['lastName'] ?? '',
      phone: json['phone'],
      avatar: json['avatar'],
      role: json['role'] ?? 'user',
      status: json['status'] ?? 'active',
      language: json['language'] ?? 'fr',
      emailVerified: json['email_verified'] ?? json['emailVerified'] ?? false,
      wilayaId: json['wilaya_id'] ?? json['wilayaId'],
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
      partnerProfile: json['partner_profile'] != null
          ? PartnerProfile.fromJson(json['partner_profile'])
          : json['partnerProfile'] != null
              ? PartnerProfile.fromJson(json['partnerProfile'])
              : null,
      reviewsCount: json['reviews_count'] ?? json['reviewsCount'] ?? 0,
      favoritesCount: json['favorites_count'] ?? json['favoritesCount'] ?? 0,
      age: json['age'],
      gender: json['gender'],
      lastLogin: json['last_login'] != null
          ? DateTime.tryParse(json['last_login'])
          : null,
      loginCount: json['login_count'] ?? json['loginCount'] ?? 0,
      isElite: json['is_elite'] ?? false,
    );
  }

  @override
  List<Object?> get props => [
        id,
        email,
        firstName,
        lastName,
        phone,
        avatar,
        role,
        status,
        language,
        emailVerified,
        wilayaId,
        createdAt,
        updatedAt,
        partnerProfile,
        reviewsCount,
        favoritesCount,
        age,
        gender,
        lastLogin,
        loginCount,
        isElite,
      ];
}

class AdminUserPagination extends Equatable {
  final List<AdminUser> users;
  final int total;
  final int page;
  final int limit;
  final int totalPages;

  const AdminUserPagination({
    required this.users,
    required this.total,
    required this.page,
    required this.limit,
    required this.totalPages,
  });

  factory AdminUserPagination.fromJson(Map<String, dynamic> json) {
    return AdminUserPagination(
      users: (json['data'] ?? json['users'] ?? [])
          .map<AdminUser>((e) => AdminUser.fromJson(e))
          .toList(),
      total: json['total'] ?? json['pagination']?['total'] ?? 0,
      page: json['page'] ?? json['pagination']?['page'] ?? 1,
      limit: json['limit'] ?? json['pagination']?['limit'] ?? 20,
      totalPages: json['total_pages'] ??
          json['totalPages'] ??
          json['pagination']?['totalPages'] ??
          1,
    );
  }

  bool get hasMore => page < totalPages;

  @override
  List<Object?> get props => [users, total, page, limit, totalPages];
}
