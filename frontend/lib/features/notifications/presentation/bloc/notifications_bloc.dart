import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/models/notification_model.dart';
import '../../data/repositories/notification_repository.dart';

// ─── Events ──────────────────────────────────────────────────────────────────

abstract class NotificationsEvent extends Equatable {
  const NotificationsEvent();

  @override
  List<Object?> get props => [];
}

class LoadNotifications extends NotificationsEvent {
  const LoadNotifications();
}

class RefreshNotifications extends NotificationsEvent {
  const RefreshNotifications();
}

class MarkNotificationRead extends NotificationsEvent {
  final String id;
  const MarkNotificationRead(this.id);

  @override
  List<Object?> get props => [id];
}

class MarkAllNotificationsRead extends NotificationsEvent {
  const MarkAllNotificationsRead();
}

class DeleteNotification extends NotificationsEvent {
  final String id;
  const DeleteNotification(this.id);

  @override
  List<Object?> get props => [id];
}

// ─── States ──────────────────────────────────────────────────────────────────

abstract class NotificationsState extends Equatable {
  const NotificationsState();

  @override
  List<Object?> get props => [];
}

class NotificationsInitial extends NotificationsState {}

class NotificationsLoading extends NotificationsState {}

class NotificationsLoaded extends NotificationsState {
  final List<NotificationModel> notifications;
  final int unreadCount;

  const NotificationsLoaded({
    required this.notifications,
    required this.unreadCount,
  });

  NotificationsLoaded copyWith({
    List<NotificationModel>? notifications,
    int? unreadCount,
  }) {
    return NotificationsLoaded(
      notifications: notifications ?? this.notifications,
      unreadCount: unreadCount ?? this.unreadCount,
    );
  }

  @override
  List<Object?> get props => [notifications, unreadCount];
}

class NotificationsError extends NotificationsState {
  final String message;
  const NotificationsError(this.message);

  @override
  List<Object?> get props => [message];
}

// ─── BLoC ────────────────────────────────────────────────────────────────────

class NotificationsBloc extends Bloc<NotificationsEvent, NotificationsState> {
  final NotificationRepository _repository = NotificationRepository();

  NotificationsBloc() : super(NotificationsInitial()) {
    on<LoadNotifications>(_onLoad);
    on<RefreshNotifications>(_onRefresh);
    on<MarkNotificationRead>(_onMarkRead);
    on<MarkAllNotificationsRead>(_onMarkAllRead);
    on<DeleteNotification>(_onDelete);
  }

  Future<void> _onLoad(
    LoadNotifications event,
    Emitter<NotificationsState> emit,
  ) async {
    emit(NotificationsLoading());
    try {
      final result = await _repository.getNotifications();
      emit(NotificationsLoaded(
        notifications: result.notifications,
        unreadCount: result.unreadCount,
      ));
    } catch (e) {
      emit(NotificationsError(e.toString()));
    }
  }

  Future<void> _onRefresh(
    RefreshNotifications event,
    Emitter<NotificationsState> emit,
  ) async {
    try {
      final result = await _repository.getNotifications();
      emit(NotificationsLoaded(
        notifications: result.notifications,
        unreadCount: result.unreadCount,
      ));
    } catch (e) {
      // Keep previous state on refresh failure
    }
  }

  Future<void> _onMarkRead(
    MarkNotificationRead event,
    Emitter<NotificationsState> emit,
  ) async {
    if (state is! NotificationsLoaded) return;
    final current = state as NotificationsLoaded;

    try {
      await _repository.markAsRead(event.id);

      final updated = current.notifications.map((n) {
        if (n.id == event.id) return n.copyWith(isRead: true, readAt: DateTime.now());
        return n;
      }).toList();

      final newUnread = updated.where((n) => !n.isRead).length;
      emit(current.copyWith(notifications: updated, unreadCount: newUnread));
    } catch (_) {}
  }

  Future<void> _onMarkAllRead(
    MarkAllNotificationsRead event,
    Emitter<NotificationsState> emit,
  ) async {
    if (state is! NotificationsLoaded) return;
    final current = state as NotificationsLoaded;

    try {
      await _repository.markAllAsRead();

      final updated = current.notifications
          .map((n) => n.copyWith(isRead: true, readAt: DateTime.now()))
          .toList();

      emit(current.copyWith(notifications: updated, unreadCount: 0));
    } catch (_) {}
  }

  Future<void> _onDelete(
    DeleteNotification event,
    Emitter<NotificationsState> emit,
  ) async {
    if (state is! NotificationsLoaded) return;
    final current = state as NotificationsLoaded;

    try {
      await _repository.deleteNotification(event.id);

      final updated =
          current.notifications.where((n) => n.id != event.id).toList();
      final newUnread = updated.where((n) => !n.isRead).length;
      emit(current.copyWith(notifications: updated, unreadCount: newUnread));
    } catch (_) {}
  }
}
