import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../../app_router.dart';
import '../../../../../core/constants/app_colors.dart';
import 'package:win_app/features/auth/presentation/bloc/auth_bloc.dart';
import '../bloc/notifications_bloc.dart';

class NotificationBellWidget extends StatefulWidget {
  const NotificationBellWidget({super.key});

  @override
  State<NotificationBellWidget> createState() => _NotificationBellWidgetState();
}

class _NotificationBellWidgetState extends State<NotificationBellWidget> {
  @override
  void initState() {
    super.initState();
    final authState = context.read<AuthBloc>().state;
    if (authState is! AuthAuthenticated) return;

    final bloc = context.read<NotificationsBloc>();
    if (bloc.state is NotificationsInitial || bloc.state is NotificationsError) {
      bloc.add(const LoadNotifications());
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<NotificationsBloc, NotificationsState>(
      builder: (context, state) {
        final unread = state is NotificationsLoaded ? state.unreadCount : 0;

        return IconButton(
          color: AppColors.white,
          onPressed: () async {
            await context.push(AppRoutes.notifications);
            if (context.mounted) {
              context.read<NotificationsBloc>().add(const LoadNotifications());
            }
          },
          icon: Badge(
            isLabelVisible: unread > 0,
            label: Text(
              unread > 9 ? '9+' : '$unread',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
            backgroundColor: AppColors.error,
            child: const Icon(Iconsax.notification),
          ),
          tooltip: 'Notifications',
        );
      },
    );
  }
}
