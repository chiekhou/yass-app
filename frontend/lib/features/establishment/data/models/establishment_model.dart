import 'dart:convert';

import 'package:equatable/equatable.dart';
import 'package:win_app/features/home/data/models/category_model.dart';
import 'photo_category.dart';

// ==================== PHOTO ITEM ====================

class PhotoItem extends Equatable {
  final String url;
  final String category; // clé parmi kPhotoCategories, défaut 'autres'
  final String type;     // 'photo' ou 'video'

  const PhotoItem({
    required this.url,
    this.category = 'autres',
    this.type = 'photo',
  });

  bool get isVideo => type == 'video';

  /// Rétrocompatible : accepte une String (ancien format) ou un Map (nouveau)
  factory PhotoItem.fromJson(dynamic json) {
    if (json is String) return PhotoItem(url: json);
    if (json is Map) {
      return PhotoItem(
        url: (json['url'] as String?) ?? '',
        category: (json['category'] as String?) ?? 'autres',
        type: (json['type'] as String?) ?? 'photo',
      );
    }
    return PhotoItem(url: json.toString());
  }

  Map<String, dynamic> toJson() => {'url': url, 'category': category, 'type': type};

  PhotoItem copyWith({String? url, String? category, String? type}) =>
      PhotoItem(
        url: url ?? this.url,
        category: category ?? this.category,
        type: type ?? this.type,
      );

  String get categoryLabel => photoCategoryLabel(category);

  @override
  List<Object?> get props => [url, category, type];
}

/// Helper function to parse double from dynamic value (String or num)
double? _parseDouble(dynamic value) {
  if (value == null) return null;
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value);
  return null;
}

List<T>? _parseJsonList<T>(dynamic raw, T Function(dynamic) mapper) {
  if (raw == null) return null;
  if (raw is List) return raw.map(mapper).toList();
  if (raw is String) {
    try {
      final decoded = jsonDecode(raw);
      if (decoded is List) return decoded.map(mapper).toList();
    } catch (_) {}
  }
  return null;
}

Map<String, dynamic>? _parseJsonMap(dynamic raw) {
  if (raw is Map) return Map<String, dynamic>.from(raw);
  if (raw is String) {
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map) return Map<String, dynamic>.from(decoded);
    } catch (_) {}
  }
  return null;
}

/// Returns the effective subscription plan, treating expired subscriptions as 'free'.
String _effectivePlan(dynamic partner) {
  if (partner == null) return 'free';
  final plan = (partner['subscription_plan'] as String?) ?? 'free';
  if (plan == 'free') return 'free';
  final expiresAt = partner['subscription_expires_at'];
  if (expiresAt == null) return 'free';
  final expiry = DateTime.tryParse(expiresAt as String);
  if (expiry == null || expiry.isBefore(DateTime.now())) return 'free';
  return plan;
}

class Establishment extends Equatable {
  final String id;
  final String name;
  final String? nameAr;
  final String slug;
  final String? description;
  final String? descriptionAr;
  final String? logo;
  final String? coverImage;
  final List<PhotoItem>? images;
  final String address;
  final String? addressAr;
  final double? latitude;
  final double? longitude;
  final String phone;
  final String? phoneSecondary;
  final String? whatsapp;
  final String? email;
  final String? website;
  final String? facebook;
  final String? instagram;
  final String? tiktok;
  final String? snapchat;
  final Map<String, dynamic>? openingHours;
  final String? priceRange;
  final List<String>? services;
  final List<String>? amenities;
  final List<String>? tags;
  final double averageRating;
  final int totalReviews;
  final int totalViews;
  final int totalFavorites;
  final bool isVerified;
  final bool isFeatured;
  final String status;
  final Category? category;
  final SubCategory? subcategory;
  final Wilaya? wilaya;
  final Commune? commune;
  final double? distance;
  final bool? isFavorited;
  final String partnerSubscriptionPlan; // free | premium | gold
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? contactFirstName;
  final String? contactLastName;
  final String? contactPhone;
  final String? contactEmail;
  final String? contactPosition;

  const Establishment({
    required this.id,
    required this.name,
    this.nameAr,
    required this.slug,
    this.description,
    this.descriptionAr,
    this.logo,
    this.coverImage,
    this.images,
    required this.address,
    this.addressAr,
    this.latitude,
    this.longitude,
    required this.phone,
    this.phoneSecondary,
    this.whatsapp,
    this.email,
    this.website,
    this.facebook,
    this.instagram,
    this.tiktok,
    this.snapchat,
    this.openingHours,
    this.priceRange,
    this.services,
    this.amenities,
    this.tags,
    this.averageRating = 0,
    this.totalReviews = 0,
    this.totalViews = 0,
    this.totalFavorites = 0,
    this.isVerified = false,
    this.isFeatured = false,
    this.status = 'active',
    this.category,
    this.subcategory,
    this.wilaya,
    this.commune,
    this.distance,
    this.isFavorited,
    this.partnerSubscriptionPlan = 'free',
    required this.createdAt,
    required this.updatedAt,
    this.contactFirstName,
    this.contactLastName,
    this.contactPhone,
    this.contactEmail,
    this.contactPosition,
  });

  bool get hasCoordinates => latitude != null && longitude != null;
  bool get hasWhatsApp => whatsapp != null && whatsapp!.isNotEmpty;
  bool get hasEmail => email != null && email!.isNotEmpty;
  bool get hasWebsite => website != null && website!.isNotEmpty;

  String get displayRating => averageRating.toStringAsFixed(1);

  String get priceRangeDisplay {
    switch (priceRange) {
      case '\$':
        return 'Économique';
      case '\$\$':
        return 'Modéré';
      case '\$\$\$':
        return 'Élevé';
      case '\$\$\$\$':
        return 'Luxe';
      default:
        return '';
    }
  }

  String? get formattedPhone {
    if (phone.isEmpty) return null;
    // Format Algerian phone: 0551234567 -> 05 51 23 45 67
    if (phone.length == 10) {
      return '${phone.substring(0, 2)} ${phone.substring(2, 4)} ${phone.substring(4, 6)} ${phone.substring(6, 8)} ${phone.substring(8)}';
    }
    return phone;
  }

  factory Establishment.fromJson(Map<String, dynamic> json) {
    return Establishment(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      nameAr: json['name_ar'],
      slug: json['slug'] ?? '',
      description: json['description'],
      descriptionAr: json['description_ar'],
      logo: json['logo'],
      coverImage: json['cover_image'],
      images: _parseJsonList(json['images'], (e) => PhotoItem.fromJson(e)),
      address: json['address'] ?? '',
      addressAr: json['address_ar'],
      latitude: _parseDouble(json['latitude']),
      longitude: _parseDouble(json['longitude']),
      phone: json['phone'] ?? '',
      phoneSecondary: json['phone_secondary'],
      whatsapp: json['whatsapp'],
      email: json['email'],
      website: json['website'],
      facebook: json['facebook'],
      instagram: json['instagram'],
      tiktok: json['tiktok'],
      snapchat: json['snapchat'],
      openingHours: _parseJsonMap(json['opening_hours']),
      priceRange: json['price_range'],
      services: _parseJsonList(json['services'], (e) => e.toString()),
      amenities: _parseJsonList(json['amenities'], (e) => e.toString()),
      tags: _parseJsonList(json['tags'], (e) => e.toString()),
      averageRating: _parseDouble(json['average_rating']) ?? 0,
      totalReviews: json['total_reviews'] ?? 0,
      totalViews: json['total_views'] ?? 0,
      totalFavorites: json['total_favorites'] ?? 0,
      isVerified: json['is_verified'] ?? false,
      isFeatured: json['is_featured'] ?? false,
      status: json['status'] ?? 'active',
      category:
          json['category'] != null ? Category.fromJson(json['category']) : null,
      subcategory: json['subcategory'] != null
          ? SubCategory.fromJson(json['subcategory'])
          : null,
      wilaya: json['wilaya'] != null ? Wilaya.fromJson(json['wilaya']) : null,
      commune:
          json['commune'] != null ? Commune.fromJson(json['commune']) : null,
      distance: _parseDouble(json['distance']),
      isFavorited: json['is_favorited'],
      partnerSubscriptionPlan: _effectivePlan(json['partner']),
      contactFirstName: json['contact_first_name'],
      contactLastName: json['contact_last_name'],
      contactPhone: json['contact_phone'],
      contactEmail: json['contact_email'],
      contactPosition: json['contact_position'],
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
      'id': id,
      'name': name,
      'name_ar': nameAr,
      'slug': slug,
      'description': description,
      'description_ar': descriptionAr,
      'logo': logo,
      'cover_image': coverImage,
      'images': images?.map((e) => e.toJson()).toList(),
      'address': address,
      'address_ar': addressAr,
      'latitude': latitude,
      'longitude': longitude,
      'phone': phone,
      'phone_secondary': phoneSecondary,
      'whatsapp': whatsapp,
      'email': email,
      'website': website,
      'facebook': facebook,
      'instagram': instagram,
      'tiktok': tiktok,
      'snapchat': snapchat,
      'opening_hours': openingHours,
      'price_range': priceRange,
      'services': services,
      'amenities': amenities,
      'tags': tags,
      'average_rating': averageRating,
      'total_reviews': totalReviews,
      'is_verified': isVerified,
      'is_featured': isFeatured,
      'status': status,
      'contact_first_name': contactFirstName,
      'contact_last_name': contactLastName,
      'contact_phone': contactPhone,
      'contact_email': contactEmail,
      'contact_position': contactPosition,
    };
  }

  Establishment copyWith({
    String? id,
    String? name,
    String? nameAr,
    String? slug,
    String? description,
    String? descriptionAr,
    String? logo,
    String? coverImage,
    List<PhotoItem>? images,
    String? address,
    String? addressAr,
    double? latitude,
    double? longitude,
    String? phone,
    String? phoneSecondary,
    String? whatsapp,
    String? email,
    String? website,
    String? facebook,
    String? instagram,
    String? tiktok,
    String? snapchat,
    Map<String, dynamic>? openingHours,
    String? priceRange,
    List<String>? services,
    List<String>? amenities,
    List<String>? tags,
    double? averageRating,
    int? totalReviews,
    int? totalViews,
    int? totalFavorites,
    bool? isVerified,
    bool? isFeatured,
    String? status,
    Category? category,
    SubCategory? subcategory,
    Wilaya? wilaya,
    Commune? commune,
    double? distance,
    bool? isFavorited,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Establishment(
      id: id ?? this.id,
      name: name ?? this.name,
      nameAr: nameAr ?? this.nameAr,
      slug: slug ?? this.slug,
      description: description ?? this.description,
      descriptionAr: descriptionAr ?? this.descriptionAr,
      logo: logo ?? this.logo,
      coverImage: coverImage ?? this.coverImage,
      images: images ?? this.images,
      address: address ?? this.address,
      addressAr: addressAr ?? this.addressAr,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      phone: phone ?? this.phone,
      phoneSecondary: phoneSecondary ?? this.phoneSecondary,
      whatsapp: whatsapp ?? this.whatsapp,
      email: email ?? this.email,
      website: website ?? this.website,
      facebook: facebook ?? this.facebook,
      instagram: instagram ?? this.instagram,
      tiktok: tiktok ?? this.tiktok,
      snapchat: snapchat ?? this.snapchat,
      openingHours: openingHours ?? this.openingHours,
      priceRange: priceRange ?? this.priceRange,
      services: services ?? this.services,
      amenities: amenities ?? this.amenities,
      tags: tags ?? this.tags,
      averageRating: averageRating ?? this.averageRating,
      totalReviews: totalReviews ?? this.totalReviews,
      totalViews: totalViews ?? this.totalViews,
      totalFavorites: totalFavorites ?? this.totalFavorites,
      isVerified: isVerified ?? this.isVerified,
      isFeatured: isFeatured ?? this.isFeatured,
      status: status ?? this.status,
      category: category ?? this.category,
      subcategory: subcategory ?? this.subcategory,
      wilaya: wilaya ?? this.wilaya,
      commune: commune ?? this.commune,
      distance: distance ?? this.distance,
      isFavorited: isFavorited ?? this.isFavorited,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      contactFirstName: contactFirstName ?? this.contactFirstName,
      contactLastName: contactLastName ?? this.contactLastName,
      contactPhone: contactPhone ?? this.contactPhone,
      contactEmail: contactEmail ?? this.contactEmail,
      contactPosition: contactPosition ?? this.contactPosition,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        slug,
        averageRating,
        totalReviews,
        isVerified,
        isFeatured,
        isFavorited,
      ];
}

// Opening Hours Helper
class OpeningHoursHelper {
  static bool isOpenNow(Map<String, dynamic>? openingHours) {
    if (openingHours == null) return false;

    final now = DateTime.now();
    final dayNames = [
      'monday', 'tuesday', 'wednesday', 'thursday',
      'friday', 'saturday', 'sunday',
    ];
    final todayHours = openingHours[dayNames[now.weekday - 1]];

    if (todayHours == null) return false;
    if (todayHours['is_closed'] == true) return false;

    final openTime = todayHours['open'];
    final closeTime = todayHours['close'];
    if (openTime == null || closeTime == null) return false;

    DateTime todt(String t) {
      final p = t.split(':');
      return DateTime(now.year, now.month, now.day, int.parse(p[0]), int.parse(p[1]));
    }

    final openDT = todt(openTime);
    final closeDT = todt(closeTime);

    final breakStart = todayHours['break_start'];
    final breakEnd = todayHours['break_end'];
    if (breakStart != null && breakEnd != null) {
      final breakStartDT = todt(breakStart);
      final breakEndDT = todt(breakEnd);
      return (now.isAfter(openDT) && now.isBefore(breakStartDT)) ||
             (now.isAfter(breakEndDT) && now.isBefore(closeDT));
    }

    return now.isAfter(openDT) && now.isBefore(closeDT);
  }

  static String? getTodayHours(Map<String, dynamic>? openingHours) {
    if (openingHours == null) return null;

    final now = DateTime.now();
    final dayNames = [
      'monday', 'tuesday', 'wednesday', 'thursday',
      'friday', 'saturday', 'sunday',
    ];
    final todayHours = openingHours[dayNames[now.weekday - 1]];

    if (todayHours == null) return null;
    if (todayHours['is_closed'] == true) return 'Fermé';

    final openTime = todayHours['open'];
    final closeTime = todayHours['close'];
    if (openTime == null || closeTime == null) return null;

    final breakStart = todayHours['break_start'];
    final breakEnd = todayHours['break_end'];
    if (breakStart != null && breakEnd != null) {
      return '$openTime-$breakStart · $breakEnd-$closeTime';
    }

    return '$openTime - $closeTime';
  }
}
