import 'package:equatable/equatable.dart';

class PartnerStats extends Equatable {
  final int totalEstablishments;
  final int activeEstablishments;
  final int pendingEstablishments;
  final int totalViews;
  final int totalFavorites;
  final int totalReviews;
  final double averageRating;
  final int phoneClicks;
  final int whatsappClicks;
  final List<EstablishmentStats>? topEstablishments;

  const PartnerStats({
    required this.totalEstablishments,
    required this.activeEstablishments,
    required this.pendingEstablishments,
    required this.totalViews,
    required this.totalFavorites,
    required this.totalReviews,
    required this.averageRating,
    required this.phoneClicks,
    required this.whatsappClicks,
    this.topEstablishments,
  });

  factory PartnerStats.fromJson(Map<String, dynamic> json) {
    return PartnerStats(
      totalEstablishments: json['total_establishments'] ?? 0,
      activeEstablishments: json['active_establishments'] ?? 0,
      pendingEstablishments: json['pending_establishments'] ?? 0,
      totalViews: json['total_views'] ?? 0,
      totalFavorites: json['total_favorites'] ?? 0,
      totalReviews: json['total_reviews'] ?? 0,
      averageRating: double.tryParse(json['average_rating']?.toString() ?? '0') ?? 0.0,
      phoneClicks: json['phone_clicks'] ?? 0,
      whatsappClicks: json['whatsapp_clicks'] ?? 0,
      topEstablishments: json['top_establishments'] != null
          ? (json['top_establishments'] as List)
              .map((e) => EstablishmentStats.fromJson(e))
              .toList()
          : null,
    );
  }

  @override
  List<Object?> get props => [
        totalEstablishments,
        activeEstablishments,
        pendingEstablishments,
        totalViews,
        totalFavorites,
        totalReviews,
        averageRating,
        phoneClicks,
        whatsappClicks,
        topEstablishments,
      ];
}

class EstablishmentStats extends Equatable {
  final String id;
  final String name;
  final int views;
  final int favorites;
  final double rating;

  const EstablishmentStats({
    required this.id,
    required this.name,
    required this.views,
    required this.favorites,
    required this.rating,
  });

  factory EstablishmentStats.fromJson(Map<String, dynamic> json) {
    return EstablishmentStats(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      views: json['views'] ?? json['total_views'] ?? 0,
      favorites: json['favorites'] ?? json['total_favorites'] ?? 0,
      rating: double.tryParse((json['rating'] ?? json['average_rating'] ?? 0).toString()) ?? 0.0,
    );
  }

  @override
  List<Object?> get props => [id, name, views, favorites, rating];
}
