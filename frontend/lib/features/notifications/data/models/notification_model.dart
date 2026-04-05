import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import '../../../../core/constants/app_colors.dart';

class NotificationModel {
  final String id;
  final String type;
  final String title;
  final String body;
  final Map<String, dynamic>? data;
  final bool isRead;
  final DateTime? readAt;
  final DateTime createdAt;

  const NotificationModel({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    this.data,
    required this.isRead,
    this.readAt,
    required this.createdAt,
  });

  bool get isPending => !isRead;

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] as String? ?? '',
      type: json['type'] as String? ?? '',
      title: json['title'] as String? ?? '',
      body: json['body'] as String? ?? '',
      data: json['data'] as Map<String, dynamic>?,
      isRead: json['is_read'] as bool? ?? false,
      readAt: json['read_at'] != null
          ? DateTime.tryParse(json['read_at'] as String)
          : null,
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ??
          DateTime.now(),
    );
  }

  /// Icon based on notification type
  IconData get icon {
    switch (type) {
      case 'partner_approved':
        return Iconsax.tick_circle;
      case 'partner_rejected':
        return Iconsax.close_circle;
      case 'establishment_approved':
        return Iconsax.building;
      case 'establishment_rejected':
        return Iconsax.building_3;
      case 'payment_validated':
        return Iconsax.wallet_check;
      case 'subscription_expiring':
        return Iconsax.clock;
      case 'review_approved':
        return Iconsax.star_1;
      case 'review_new':
        return Iconsax.star;
      case 'review_reply':
        return Iconsax.message_text;
      default:
        return Iconsax.notification;
    }
  }

  /// Color based on notification type
  Color get color {
    switch (type) {
      case 'partner_approved':
      case 'establishment_approved':
      case 'payment_validated':
        return AppColors.success;
      case 'partner_rejected':
      case 'establishment_rejected':
        return AppColors.error;
      case 'subscription_expiring':
        return AppColors.warning;
      case 'review_approved':
      case 'review_new':
      case 'review_reply':
        return AppColors.primaryGreen;
      default:
        return AppColors.grey500;
    }
  }

  NotificationModel copyWith({bool? isRead, DateTime? readAt}) {
    return NotificationModel(
      id: id,
      type: type,
      title: title,
      body: body,
      data: data,
      isRead: isRead ?? this.isRead,
      readAt: readAt ?? this.readAt,
      createdAt: createdAt,
    );
  }
}
