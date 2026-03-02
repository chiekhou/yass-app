import '../../../../core/network/api_client.dart';
import '../../../../core/constants/api_config.dart';
import '../models/notification_model.dart';

class NotificationRepository {
  final ApiClient _api = ApiClient.instance;

  /// Get paginated notifications for the current user.
  Future<({List<NotificationModel> notifications, int unreadCount})>
      getNotifications({int page = 1, int limit = 20}) async {
    final response = await _api.get(
      ApiConfig.notifications,
      queryParameters: {'page': page, 'limit': limit},
    );

    final items = (response.data['data'] as List? ?? [])
        .map((e) => NotificationModel.fromJson(e as Map<String, dynamic>))
        .toList();

    // Derive unread count from the loaded list
    final unread = items.where((n) => !n.isRead).length;
    return (notifications: items, unreadCount: unread);
  }

  /// Get the number of unread notifications.
  Future<int> getUnreadCount() async {
    final response = await _api.get(ApiConfig.notificationsUnreadCount);
    return (response.data['data']?['count'] as int?) ?? 0;
  }

  /// Mark a single notification as read.
  Future<void> markAsRead(String id) async {
    await _api.patch(ApiConfig.notificationRead(id));
  }

  /// Mark all notifications as read.
  Future<void> markAllAsRead() async {
    await _api.post(ApiConfig.notificationsReadAll);
  }

  /// Delete a notification.
  Future<void> deleteNotification(String id) async {
    await _api.delete(ApiConfig.notificationDelete(id));
  }

  /// Register the FCM token with the backend.
  Future<void> updateFcmToken(String token) async {
    await _api.put(ApiConfig.updateFcmToken, data: {'fcm_token': token});
  }
}
