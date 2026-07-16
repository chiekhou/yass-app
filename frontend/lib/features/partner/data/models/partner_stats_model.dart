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
  final int totalContacts;
  final List<EstablishmentStats>? topEstablishments;
  final Map<int, int> ratingDistribution;
  final List<WilayaStat> topWilayas;
  final List<RatingTrend> ratingTrend;

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
    required this.totalContacts,
    this.topEstablishments,
    this.ratingDistribution = const {},
    this.topWilayas = const [],
    this.ratingTrend = const [],
  });

  factory PartnerStats.fromJson(Map<String, dynamic> json) {
    final totals = json['totals'] as Map<String, dynamic>?;
    final byStatus = json['by_status'] as Map<String, dynamic>?;

    final rawDist = json['rating_distribution'] as Map<String, dynamic>? ?? {};
    final dist = <int, int>{};
    for (int i = 1; i <= 5; i++) {
      dist[i] = (rawDist[i.toString()] ?? 0) as int;
    }

    return PartnerStats(
      totalEstablishments: json['total_establishments'] ?? 0,
      activeEstablishments: byStatus?['active'] ?? json['active_establishments'] ?? 0,
      pendingEstablishments: byStatus?['pending'] ?? json['pending_establishments'] ?? 0,
      totalViews: totals?['views'] ?? json['total_views'] ?? 0,
      totalFavorites: totals?['favorites'] ?? json['total_favorites'] ?? 0,
      totalReviews: totals?['reviews'] ?? json['total_reviews'] ?? 0,
      averageRating: double.tryParse(json['average_rating']?.toString() ?? '0') ?? 0.0,
      phoneClicks: totals?['calls'] ?? json['phone_clicks'] ?? 0,
      whatsappClicks: totals?['whatsapp_clicks'] ?? json['whatsapp_clicks'] ?? 0,
      totalContacts: totals?['contacts'] ?? json['total_contacts'] ?? 0,
      topEstablishments: json['top_establishments'] != null
          ? (json['top_establishments'] as List)
              .map((e) => EstablishmentStats.fromJson(e))
              .toList()
          : null,
      ratingDistribution: dist,
      topWilayas: (json['top_wilayas'] as List? ?? [])
          .map((e) => WilayaStat.fromJson(e))
          .toList(),
      ratingTrend: (json['rating_trend'] as List? ?? [])
          .map((e) => RatingTrend.fromJson(e))
          .toList(),
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
        totalContacts,
        topEstablishments,
        ratingDistribution,
        topWilayas,
        ratingTrend,
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

class WilayaStat extends Equatable {
  final String name;
  final int count;

  const WilayaStat({required this.name, required this.count});

  factory WilayaStat.fromJson(Map<String, dynamic> json) {
    return WilayaStat(
      name: json['name'] ?? '',
      count: (json['count'] ?? 0) as int,
    );
  }

  @override
  List<Object?> get props => [name, count];
}

class RatingTrend extends Equatable {
  final String month;
  final double average;
  final int count;

  const RatingTrend({
    required this.month,
    required this.average,
    required this.count,
  });

  factory RatingTrend.fromJson(Map<String, dynamic> json) {
    return RatingTrend(
      month: json['month'] ?? '',
      average: double.tryParse(json['average']?.toString() ?? '0') ?? 0.0,
      count: (json['count'] ?? 0) as int,
    );
  }

  @override
  List<Object?> get props => [month, average, count];
}
