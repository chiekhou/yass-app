import 'package:flutter/material.dart';
import 'package:win_app/core/l10n/l10n_extensions.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../app_router.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../data/models/notification_model.dart';
import '../bloc/notifications_bloc.dart';

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.kleinBlue,
      appBar: AppBar(
        title: Text(context.l10n.notifications),
        backgroundColor: AppColors.kleinBlue,
        foregroundColor: AppColors.white,
        elevation: 0,
        actions: [
          BlocBuilder<NotificationsBloc, NotificationsState>(
            builder: (context, state) {
              if (state is NotificationsLoaded && state.unreadCount > 0) {
                return TextButton(
                  onPressed: () => context
                      .read<NotificationsBloc>()
                      .add(const MarkAllNotificationsRead()),
                  child: Text(
                    context.l10n.markAllRead,
                    style: const TextStyle(color: AppColors.white),
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
      body: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, authState) {
          if (authState is! AuthAuthenticated) {
            return _buildNotLoggedIn(context);
          }

          return BlocBuilder<NotificationsBloc, NotificationsState>(
            builder: (context, state) {
              if (state is NotificationsLoading) {
                return const Center(
                  child: CircularProgressIndicator(color: AppColors.white),
                );
              }

              if (state is NotificationsError) {
                return _buildError(context, state.message);
              }

              if (state is NotificationsLoaded) {
                if (state.notifications.isEmpty) return _buildEmpty(context);

                return RefreshIndicator(
                  color: AppColors.accentGreen,
                  onRefresh: () async {
                    context
                        .read<NotificationsBloc>()
                        .add(const RefreshNotifications());
                    await Future.delayed(const Duration(milliseconds: 400));
                  },
                  child: ListView.separated(
                    padding: const EdgeInsets.all(AppDimens.paddingM),
                    itemCount: state.notifications.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: AppDimens.paddingS),
                    itemBuilder: (context, index) => _NotificationCard(
                        notification: state.notifications[index]),
                  ),
                );
              }

              return const SizedBox.shrink();
            },
          );
        },
      ),
    );
  }

  Widget _buildNotLoggedIn(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppDimens.paddingXL),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Iconsax.notification,
                size: 48,
                color: AppColors.white,
              ),
            ),
            const SizedBox(height: AppDimens.paddingL),
            Text(
              context.l10n.loginToSeeNotifications,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.white,
                    fontWeight: FontWeight.bold,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppDimens.paddingS),
            Text(
              'Soyez alerté en temps réel des événements importants liés à votre compte',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.white.withValues(alpha: 0.8),
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppDimens.paddingL),
            ElevatedButton(
              onPressed: () => context.push(AppRoutes.login),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accentGreen,
                foregroundColor: AppColors.black,
              ),
              child: Text(context.l10n.login),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppDimens.paddingXL),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(AppDimens.paddingL),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Iconsax.notification,
                size: 64,
                color: AppColors.white,
              ),
            ),
            const SizedBox(height: AppDimens.paddingL),
            Text(
              context.l10n.noNotifications,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.white,
                  ),
            ),
            const SizedBox(height: AppDimens.paddingS),
            Text(
              'Vous serez notifié ici des événements importants',
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: AppColors.white),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildError(BuildContext context, String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppDimens.paddingXL),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(AppDimens.paddingL),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Iconsax.warning_2,
                size: 64,
                color: AppColors.error,
              ),
            ),
            const SizedBox(height: AppDimens.paddingL),
            Text(
              context.l10n.loadingError,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppDimens.paddingS),
            Text(
              message,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: AppColors.grey600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppDimens.paddingL),
            ElevatedButton.icon(
              onPressed: () => context
                  .read<NotificationsBloc>()
                  .add(const LoadNotifications()),
              icon: const Icon(Icons.refresh),
              label: Text(context.l10n.retry),
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accentGreen,
                  foregroundColor: AppColors.black),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Notification Card ───────────────────────────────────────────────────────

class _NotificationCard extends StatelessWidget {
  final NotificationModel notification;

  const _NotificationCard({required this.notification});

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(notification.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: AppDimens.paddingL),
        decoration: BoxDecoration(
          color: AppColors.error,
          borderRadius: BorderRadius.circular(AppDimens.radiusM),
        ),
        child: const Icon(Iconsax.trash, color: Colors.white),
      ),
      onDismissed: (_) {
        context
            .read<NotificationsBloc>()
            .add(DeleteNotification(notification.id));
      },
      child: InkWell(
        onTap: () {
          if (notification.isPending) {
            context
                .read<NotificationsBloc>()
                .add(MarkNotificationRead(notification.id));
          }
          _navigate(context, notification);
        },
        borderRadius: BorderRadius.circular(AppDimens.radiusM),
        child: Container(
          padding: const EdgeInsets.all(AppDimens.paddingM),
          decoration: BoxDecoration(
            color: notification.isRead ? AppColors.white : AppColors.grey50,
            borderRadius: BorderRadius.circular(AppDimens.radiusM),
            border: Border.all(
              color: notification.isRead
                  ? AppColors.grey200
                  : notification.color.withValues(alpha: 0.3),
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.black.withValues(alpha: 0.04),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: notification.color.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(notification.icon,
                    color: notification.color, size: 20),
              ),
              const SizedBox(width: AppDimens.paddingM),

              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            notification.title,
                            style: Theme.of(context)
                                .textTheme
                                .titleSmall
                                ?.copyWith(
                                  fontWeight: notification.isRead
                                      ? FontWeight.w500
                                      : FontWeight.bold,
                                  color: AppColors.grey900,
                                ),
                          ),
                        ),
                        if (!notification.isRead)
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: notification.color,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      notification.body,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.grey600,
                            height: 1.4,
                          ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            _timeAgo(notification.createdAt),
                            style: Theme.of(context)
                                .textTheme
                                .labelSmall
                                ?.copyWith(color: AppColors.grey400),
                          ),
                        ),
                        if (!notification.isRead)
                          GestureDetector(
                            onTap: () => context
                                .read<NotificationsBloc>()
                                .add(MarkNotificationRead(notification.id)),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color:
                                    notification.color.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color:
                                      notification.color.withValues(alpha: 0.3),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.check,
                                      size: 12, color: notification.color),
                                  const SizedBox(width: 3),
                                  Text(
                                    'Marquer comme lu',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: notification.color,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _navigate(BuildContext context, NotificationModel n) {
    final data = n.data;
    switch (n.type) {
      case 'review_approved':
        final establishmentId = data?['establishment_id'] as String?;
        if (establishmentId != null) {
          context.push('/partner/establishments/$establishmentId');
        }
        break;
      case 'review_new':
        context.push(AppRoutes.adminReviews);
        break;
      case 'review_reply':
        context.push(AppRoutes.myReviews);
        break;
      case 'payment_validated':
      case 'subscription_expiring':
        context.push(AppRoutes.partnerSubscription);
        break;
      case 'payment_pending':
        context.push(AppRoutes.adminPendingPayments);
        break;
      case 'establishment_approved':
      case 'establishment_rejected':
        context.push(AppRoutes.partnerEstablishments);
        break;
      case 'partner_approved':
      case 'partner_rejected':
        context.push(AppRoutes.partnerDashboard);
        break;
      case 'suggestion_approved':
      case 'suggestion_rejected':
        context.push(AppRoutes.mySuggestions);
        break;
      case 'suggestion_pending':
        context.push(AppRoutes.adminSuggestions);
        break;
      case 'contact_message':
        _showContactMessageSheet(context, notification);
        break;
      default:
        break;
    }
  }

  void _showContactMessageSheet(
      BuildContext context, NotificationModel notification) {
    final senderName = notification.data?['sender_name'] as String? ?? '';
    final senderEmail = notification.data?['sender_email'] as String? ?? '';
    final message = notification.data?['message'] as String? ?? '';
    final establishmentName =
        notification.data?['establishment_name'] as String? ?? '';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.scaffoldBackground,
      builder: (sheetCtx) => Container(
        decoration: const BoxDecoration(
          color: Color(0xFF1A1A2E),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primaryGreen.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Iconsax.sms,
                      color: AppColors.primaryGreen, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Nouveau message de contact',
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16),
                      ),
                      if (establishmentName.isNotEmpty)
                        Text(
                          establishmentName,
                          style: const TextStyle(
                              color: AppColors.primaryGreen, fontSize: 13),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (senderName.isNotEmpty) ...[
                    Row(
                      children: [
                        const Icon(Iconsax.user,
                            color: Colors.white54, size: 14),
                        const SizedBox(width: 6),
                        Text(senderName,
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 14)),
                      ],
                    ),
                    const SizedBox(height: 6),
                  ],
                  if (senderEmail.isNotEmpty) ...[
                    Row(
                      children: [
                        const Icon(Iconsax.sms,
                            color: Colors.white54, size: 14),
                        const SizedBox(width: 6),
                        Text(senderEmail,
                            style: const TextStyle(
                                color: AppColors.primaryGreen, fontSize: 13)),
                      ],
                    ),
                    const SizedBox(height: 12),
                  ],
                  if (message.isNotEmpty) ...[
                    const Divider(color: Colors.white12),
                    const SizedBox(height: 10),
                    const Text('Message',
                        style: TextStyle(
                            color: Colors.white54,
                            fontSize: 12,
                            fontWeight: FontWeight.w600)),
                    const SizedBox(height: 6),
                    Text(message,
                        style: const TextStyle(
                            color: Colors.white, fontSize: 14, height: 1.5)),
                  ] else
                    Text(
                      notification.body,
                      style: const TextStyle(
                          color: Colors.white70, fontSize: 14, height: 1.5),
                    ),
                ],
              ),
            ),
            /* const SizedBox(height: 16),
            if (senderEmail.isNotEmpty)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Iconsax.sms, size: 18),
                  label: const Text('Ouvrir l\'email'),
                  onPressed: () async {
                    final subject =
                        Uri.encodeComponent('Re: Contact - $establishmentName');
                    final uri =
                        Uri.parse('mailto:$senderEmail?subject=$subject');
                    if (await canLaunchUrl(uri)) {
                      await launchUrl(uri);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryGreen,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),*/
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => Navigator.pop(sheetCtx),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.white54,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: const Text('Fermer'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _timeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inDays >= 365) {
      return DateFormat('dd/MM/yyyy').format(date);
    } else if (diff.inDays >= 7) {
      return DateFormat('dd MMM', 'fr').format(date);
    } else if (diff.inDays > 0) {
      return 'il y a ${diff.inDays} jour${diff.inDays > 1 ? 's' : ''}';
    } else if (diff.inHours > 0) {
      return 'il y a ${diff.inHours}h';
    } else if (diff.inMinutes > 0) {
      return 'il y a ${diff.inMinutes} min';
    } else {
      return 'à l\'instant';
    }
  }
}
