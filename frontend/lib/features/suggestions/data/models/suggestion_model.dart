import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';

class SuggestionModel {
  final String id;
  final String name;
  final String address;
  final String? phone;
  final String? description;
  final String? categoryId;
  final String? categoryName;
  final String? wilayaId;
  final String? wilayaName;
  final String suggestedBy;
  final String? suggesterName;
  final String? suggesterAvatar;
  final int voteCount;
  final bool hasVoted;
  final int downvoteCount;
  final bool hasDownvoted;
  final String status;
  final String? adminNote;
  final DateTime createdAt;

  const SuggestionModel({
    required this.id,
    required this.name,
    required this.address,
    this.phone,
    this.description,
    this.categoryId,
    this.categoryName,
    this.wilayaId,
    this.wilayaName,
    required this.suggestedBy,
    this.suggesterName,
    this.suggesterAvatar,
    required this.voteCount,
    required this.hasVoted,
    this.downvoteCount = 0,
    this.hasDownvoted = false,
    required this.status,
    this.adminNote,
    required this.createdAt,
  });

  factory SuggestionModel.fromJson(Map<String, dynamic> json) {
    final suggester = json['suggester'] as Map<String, dynamic>?;
    final category = json['category'] as Map<String, dynamic>?;
    final wilaya = json['wilaya'] as Map<String, dynamic>?;

    String? suggesterName;
    if (suggester != null) {
      final firstName = suggester['first_name'] as String? ?? '';
      final lastName = suggester['last_name'] as String? ?? '';
      suggesterName = '$firstName $lastName'.trim();
    }

    return SuggestionModel(
      id: json['id'] as String,
      name: json['name'] as String,
      address: json['address'] as String,
      phone: json['phone'] as String?,
      description: json['description'] as String?,
      categoryId: category?['id'] as String?,
      categoryName: category?['name'] as String?,
      wilayaId: wilaya?['id'] as String?,
      wilayaName: wilaya?['name'] as String?,
      suggestedBy: json['suggested_by'] as String,
      suggesterName: suggesterName?.isEmpty == true ? null : suggesterName,
      suggesterAvatar: suggester?['avatar'] as String?,
      voteCount: json['vote_count'] as int? ?? 1,
      hasVoted: json['has_voted'] as bool? ?? false,
      downvoteCount: json['downvote_count'] as int? ?? 0,
      hasDownvoted: json['has_downvoted'] as bool? ?? false,
      status: json['status'] as String? ?? 'pending',
      adminNote: json['admin_note'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  bool get isPending => status == 'pending';
  bool get isApproved => status == 'approved';
  bool get isRejected => status == 'rejected';

  Color get statusColor {
    switch (status) {
      case 'approved':
        return const Color(0xFF4CAF50);
      case 'rejected':
        return const Color(0xFFF44336);
      default:
        return const Color(0xFFFF9800);
    }
  }

  String get statusLabel {
    switch (status) {
      case 'approved':
        return 'Approuvée';
      case 'rejected':
        return 'Rejetée';
      default:
        return 'En attente';
    }
  }

  IconData get statusIcon {
    switch (status) {
      case 'approved':
        return Iconsax.tick_circle;
      case 'rejected':
        return Iconsax.close_circle;
      default:
        return Iconsax.clock;
    }
  }
}

class SuggestionPagination {
  final int currentPage;
  final int perPage;
  final int totalItems;
  final int totalPages;
  final bool hasNext;

  const SuggestionPagination({
    required this.currentPage,
    required this.perPage,
    required this.totalItems,
    required this.totalPages,
    required this.hasNext,
  });

  factory SuggestionPagination.fromJson(Map<String, dynamic> json) {
    return SuggestionPagination(
      currentPage: json['current_page'] as int? ?? 1,
      perPage: json['per_page'] as int? ?? 20,
      totalItems: json['total_items'] as int? ?? 0,
      totalPages: json['total_pages'] as int? ?? 1,
      hasNext: json['has_next'] as bool? ?? false,
    );
  }
}

class SuggestionListResult {
  final List<SuggestionModel> items;
  final SuggestionPagination pagination;

  const SuggestionListResult({
    required this.items,
    required this.pagination,
  });
}
