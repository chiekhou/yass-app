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
  final VisitStats visitStats;
  final DemographicStats demographicStats;

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
    this.visitStats = const VisitStats(),
    this.demographicStats = const DemographicStats(),
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
      visitStats: json['visits'] != null
          ? VisitStats.fromJson(json['visits'] as Map<String, dynamic>)
          : const VisitStats(),
      demographicStats: json['demographics'] != null
          ? DemographicStats.fromJson(json['demographics'] as Map<String, dynamic>)
          : const DemographicStats(),
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
        visitStats,
        demographicStats,
      ];
}

class DemographicStats extends Equatable {
  final int male;
  final int female;
  final int young;
  final int child;
  final int unknown;
  final int ageUnder18;
  final int age18to25;
  final int age26to35;
  final int age36to50;
  final int ageOver50;
  final int ageUnknown;

  const DemographicStats({
    this.male = 0,
    this.female = 0,
    this.young = 0,
    this.child = 0,
    this.unknown = 0,
    this.ageUnder18 = 0,
    this.age18to25 = 0,
    this.age26to35 = 0,
    this.age36to50 = 0,
    this.ageOver50 = 0,
    this.ageUnknown = 0,
  });

  int get total => male + female + young + child + unknown;

  factory DemographicStats.fromJson(Map<String, dynamic> json) {
    return DemographicStats(
      male: json['male'] ?? 0,
      female: json['female'] ?? 0,
      young: json['young'] ?? 0,
      child: json['child'] ?? 0,
      unknown: json['unknown'] ?? 0,
      ageUnder18: json['age_under_18'] ?? 0,
      age18to25: json['age_18_25'] ?? 0,
      age26to35: json['age_26_35'] ?? 0,
      age36to50: json['age_36_50'] ?? 0,
      ageOver50: json['age_over_50'] ?? 0,
      ageUnknown: json['age_unknown'] ?? 0,
    );
  }

  @override
  List<Object?> get props => [male, female, young, child, unknown, ageUnder18, age18to25, age26to35, age36to50, ageOver50, ageUnknown];
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

class VisitStats extends Equatable {
  final int total;
  final int today;
  final int thisWeek;
  final int thisMonth;

  const VisitStats({
    this.total = 0,
    this.today = 0,
    this.thisWeek = 0,
    this.thisMonth = 0,
  });

  factory VisitStats.fromJson(Map<String, dynamic> json) {
    return VisitStats(
      total: json['total'] ?? 0,
      today: json['today'] ?? 0,
      thisWeek: json['this_week'] ?? json['thisWeek'] ?? 0,
      thisMonth: json['this_month'] ?? json['thisMonth'] ?? 0,
    );
  }

  @override
  List<Object?> get props => [total, today, thisWeek, thisMonth];
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
