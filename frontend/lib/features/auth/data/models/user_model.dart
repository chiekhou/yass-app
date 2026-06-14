import 'package:equatable/equatable.dart';

class User extends Equatable {
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
  final bool isElite;
  final DateTime createdAt;
  final DateTime updatedAt;
  final PartnerProfile? partnerProfile;

  const User({
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
    this.isElite = false,
    required this.createdAt,
    required this.updatedAt,
    this.partnerProfile,
  });

  String get fullName => '$firstName $lastName';

  bool get isPartner => role == 'partner';
  bool get isAdmin => role == 'admin' || role == 'super_admin';
  bool get isActive => status == 'active';

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? '',
      email: json['email'] ?? '',
      firstName: json['first_name'] ?? '',
      lastName: json['last_name'] ?? '',
      phone: json['phone'],
      avatar: json['avatar'],
      role: json['role'] ?? 'user',
      status: json['status'] ?? 'active',
      language: json['language'] ?? 'fr',
      emailVerified: json['email_verified'] ?? false,
      wilayaId: json['wilaya_id'],
      isElite: json['is_elite'] ?? false,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at']) 
          : DateTime.now(),
      updatedAt: json['updated_at'] != null 
          ? DateTime.parse(json['updated_at']) 
          : DateTime.now(),
      partnerProfile: json['partner_profile'] != null
          ? PartnerProfile.fromJson(json['partner_profile'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'first_name': firstName,
      'last_name': lastName,
      'phone': phone,
      'avatar': avatar,
      'role': role,
      'status': status,
      'language': language,
      'email_verified': emailVerified,
      'wilaya_id': wilayaId,
      'is_elite': isElite,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  User copyWith({
    String? id,
    String? email,
    String? firstName,
    String? lastName,
    String? phone,
    String? avatar,
    String? role,
    String? status,
    String? language,
    bool? emailVerified,
    String? wilayaId,
    bool? isElite,
    DateTime? createdAt,
    DateTime? updatedAt,
    PartnerProfile? partnerProfile,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      phone: phone ?? this.phone,
      avatar: avatar ?? this.avatar,
      role: role ?? this.role,
      status: status ?? this.status,
      language: language ?? this.language,
      emailVerified: emailVerified ?? this.emailVerified,
      wilayaId: wilayaId ?? this.wilayaId,
      isElite: isElite ?? this.isElite,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      partnerProfile: partnerProfile ?? this.partnerProfile,
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
        isElite,
        createdAt,
        updatedAt,
        partnerProfile,
      ];
}

class PartnerEstablishmentBasic extends Equatable {
  final String id;
  final String name;
  final String status;
  final String? contactFirstName;
  final String? contactLastName;
  final String? contactPhone;
  final String? contactEmail;
  final String? contactPosition;

  const PartnerEstablishmentBasic({
    required this.id,
    required this.name,
    required this.status,
    this.contactFirstName,
    this.contactLastName,
    this.contactPhone,
    this.contactEmail,
    this.contactPosition,
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

  factory PartnerEstablishmentBasic.fromJson(Map<String, dynamic> json) {
    return PartnerEstablishmentBasic(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      status: json['status'] ?? 'pending',
      contactFirstName: json['contact_first_name'],
      contactLastName: json['contact_last_name'],
      contactPhone: json['contact_phone'],
      contactEmail: json['contact_email'],
      contactPosition: json['contact_position'],
    );
  }

  @override
  List<Object?> get props => [id, name, status, contactFirstName, contactLastName, contactPhone, contactEmail, contactPosition];
}

class PartnerProfile extends Equatable {
  final String id;
  final String companyName;
  final String? registrationNumber;
  final String? taxId;
  final String status;
  final String subscriptionPlan;
  final DateTime? verifiedAt;
  final List<PartnerEstablishmentBasic>? establishments;

  const PartnerProfile({
    required this.id,
    required this.companyName,
    this.registrationNumber,
    this.taxId,
    required this.status,
    required this.subscriptionPlan,
    this.verifiedAt,
    this.establishments,
  });

  bool get isApproved => status == 'approved';
  bool get isPending => status == 'pending';

  factory PartnerProfile.fromJson(Map<String, dynamic> json) {
    return PartnerProfile(
      id: json['id'] ?? '',
      companyName: json['company_name'] ?? '',
      registrationNumber: json['registration_number'],
      taxId: json['tax_id'],
      status: json['status'] ?? 'pending',
      subscriptionPlan: json['subscription_plan'] ?? 'free',
      verifiedAt: json['verified_at'] != null
          ? DateTime.parse(json['verified_at'])
          : null,
      establishments: json['establishments'] != null
          ? (json['establishments'] as List)
              .map((e) => PartnerEstablishmentBasic.fromJson(e))
              .toList()
          : null,
    );
  }

  @override
  List<Object?> get props => [
        id,
        companyName,
        registrationNumber,
        taxId,
        status,
        subscriptionPlan,
        verifiedAt,
        establishments,
      ];
}
