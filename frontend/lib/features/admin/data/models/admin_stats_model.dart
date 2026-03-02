import 'package:equatable/equatable.dart';

class AdminStats extends Equatable {
  final int totalUsers;
  final int totalPartners;
  final int totalEstablishments;
  final int pendingPartners;
  final int pendingEstablishments;
  final int activeUsers;
  final int totalReviews;
  final int pendingReviews;
  final int reportedReviews;
  final UserStats userStats;
  final PartnerStats partnerStats;
  final EstablishmentStats establishmentStats;
  final List<RecentActivity> recentActivities;

  const AdminStats({
    required this.totalUsers,
    required this.totalPartners,
    required this.totalEstablishments,
    required this.pendingPartners,
    required this.pendingEstablishments,
    required this.activeUsers,
    required this.totalReviews,
    required this.pendingReviews,
    required this.reportedReviews,
    required this.userStats,
    required this.partnerStats,
    required this.establishmentStats,
    this.recentActivities = const [],
  });

  factory AdminStats.fromJson(Map<String, dynamic> json) {
    final users = json['users'] as Map<String, dynamic>?;
    final partners = json['partners'] as Map<String, dynamic>?;
    final establishments = json['establishments'] as Map<String, dynamic>?;
    final reviews = json['reviews'] as Map<String, dynamic>?;

    return AdminStats(
      totalUsers: users?['total'] ?? json['total_users'] ?? json['totalUsers'] ?? 0,
      totalPartners: partners?['total'] ?? json['total_partners'] ?? json['totalPartners'] ?? 0,
      totalEstablishments: establishments?['total'] ?? json['total_establishments'] ?? json['totalEstablishments'] ?? 0,
      pendingPartners: partners?['pending'] ?? json['pending_partners'] ?? json['pendingPartners'] ?? 0,
      pendingEstablishments: establishments?['pending'] ?? json['pending_establishments'] ?? json['pendingEstablishments'] ?? 0,
      activeUsers: establishments?['active'] ?? json['active_users'] ?? json['activeUsers'] ?? 0,
      totalReviews: reviews?['total'] ?? json['total_reviews'] ?? json['totalReviews'] ?? 0,
      pendingReviews: reviews?['pending'] ?? json['pending_reviews'] ?? json['pendingReviews'] ?? 0,
      reportedReviews: reviews?['reported'] ?? json['reported_reviews'] ?? json['reportedReviews'] ?? 0,
      userStats: json['user_stats'] != null
          ? UserStats.fromJson(json['user_stats'])
          : json['userStats'] != null
              ? UserStats.fromJson(json['userStats'])
              : const UserStats(),
      partnerStats: json['partner_stats'] != null
          ? PartnerStats.fromJson(json['partner_stats'])
          : json['partnerStats'] != null
              ? PartnerStats.fromJson(json['partnerStats'])
              : const PartnerStats(),
      establishmentStats: json['establishment_stats'] != null
          ? EstablishmentStats.fromJson(json['establishment_stats'])
          : json['establishmentStats'] != null
              ? EstablishmentStats.fromJson(json['establishmentStats'])
              : const EstablishmentStats(),
      recentActivities: json['recent_activities'] != null
          ? (json['recent_activities'] as List)
              .map((e) => RecentActivity.fromJson(e))
              .toList()
          : json['recentActivities'] != null
              ? (json['recentActivities'] as List)
                  .map((e) => RecentActivity.fromJson(e))
                  .toList()
              : [],
    );
  }

  @override
  List<Object?> get props => [
        totalUsers,
        totalPartners,
        totalEstablishments,
        pendingPartners,
        pendingEstablishments,
        activeUsers,
        totalReviews,
        pendingReviews,
        reportedReviews,
        userStats,
        partnerStats,
        establishmentStats,
        recentActivities,
      ];
}

class UserStats extends Equatable {
  final int total;
  final int active;
  final int inactive;
  final int banned;
  final int newThisWeek;
  final int newThisMonth;

  const UserStats({
    this.total = 0,
    this.active = 0,
    this.inactive = 0,
    this.banned = 0,
    this.newThisWeek = 0,
    this.newThisMonth = 0,
  });

  factory UserStats.fromJson(Map<String, dynamic> json) {
    return UserStats(
      total: json['total'] ?? 0,
      active: json['active'] ?? 0,
      inactive: json['inactive'] ?? 0,
      banned: json['banned'] ?? 0,
      newThisWeek: json['new_this_week'] ?? json['newThisWeek'] ?? 0,
      newThisMonth: json['new_this_month'] ?? json['newThisMonth'] ?? 0,
    );
  }

  @override
  List<Object?> get props => [total, active, inactive, banned, newThisWeek, newThisMonth];
}

class PartnerStats extends Equatable {
  final int total;
  final int approved;
  final int pending;
  final int rejected;
  final int suspended;

  const PartnerStats({
    this.total = 0,
    this.approved = 0,
    this.pending = 0,
    this.rejected = 0,
    this.suspended = 0,
  });

  factory PartnerStats.fromJson(Map<String, dynamic> json) {
    return PartnerStats(
      total: json['total'] ?? 0,
      approved: json['approved'] ?? 0,
      pending: json['pending'] ?? 0,
      rejected: json['rejected'] ?? 0,
      suspended: json['suspended'] ?? 0,
    );
  }

  @override
  List<Object?> get props => [total, approved, pending, rejected, suspended];
}

class EstablishmentStats extends Equatable {
  final int total;
  final int active;
  final int pending;
  final int rejected;
  final int featured;

  const EstablishmentStats({
    this.total = 0,
    this.active = 0,
    this.pending = 0,
    this.rejected = 0,
    this.featured = 0,
  });

  factory EstablishmentStats.fromJson(Map<String, dynamic> json) {
    return EstablishmentStats(
      total: json['total'] ?? 0,
      active: json['active'] ?? 0,
      pending: json['pending'] ?? 0,
      rejected: json['rejected'] ?? 0,
      featured: json['featured'] ?? 0,
    );
  }

  @override
  List<Object?> get props => [total, active, pending, rejected, featured];
}

class RecentActivity extends Equatable {
  final String id;
  final String type;
  final String description;
  final String? userId;
  final String? userName;
  final DateTime createdAt;

  const RecentActivity({
    required this.id,
    required this.type,
    required this.description,
    this.userId,
    this.userName,
    required this.createdAt,
  });

  factory RecentActivity.fromJson(Map<String, dynamic> json) {
    return RecentActivity(
      id: json['id'] ?? '',
      type: json['type'] ?? '',
      description: json['description'] ?? '',
      userId: json['user_id'] ?? json['userId'],
      userName: json['user_name'] ?? json['userName'],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : json['createdAt'] != null
              ? DateTime.parse(json['createdAt'])
              : DateTime.now(),
    );
  }

  @override
  List<Object?> get props => [id, type, description, userId, userName, createdAt];
}
