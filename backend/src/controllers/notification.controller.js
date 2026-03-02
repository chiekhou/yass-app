const notificationService = require('../services/notification.service');
const { ApiResponse } = require('../utils/ApiResponse');

class NotificationController {
  /**
   * GET /api/v1/notifications
   */
  async getNotifications(req, res, next) {
    try {
      const page = parseInt(req.query.page) || 1;
      const limit = parseInt(req.query.limit) || 20;
      const result = await notificationService.getAll(req.userId, page, limit);
      result.send(res);
    } catch (err) {
      next(err);
    }
  }

  /**
   * GET /api/v1/notifications/unread-count
   */
  async getUnreadCount(req, res, next) {
    try {
      const data = await notificationService.getUnreadCount(req.userId);
      ApiResponse.success(data, 'Unread count retrieved').send(res);
    } catch (err) {
      next(err);
    }
  }

  /**
   * PATCH /api/v1/notifications/:id/read
   */
  async markAsRead(req, res, next) {
    try {
      const notification = await notificationService.markAsRead(req.params.id, req.userId);
      ApiResponse.success(notification, 'Notification marquée comme lue').send(res);
    } catch (err) {
      next(err);
    }
  }

  /**
   * POST /api/v1/notifications/read-all
   */
  async markAllAsRead(req, res, next) {
    try {
      const result = await notificationService.markAllAsRead(req.userId);
      ApiResponse.success(result, 'Toutes les notifications marquées comme lues').send(res);
    } catch (err) {
      next(err);
    }
  }

  /**
   * DELETE /api/v1/notifications/:id
   */
  async deleteNotification(req, res, next) {
    try {
      await notificationService.delete(req.params.id, req.userId);
      ApiResponse.noContent('Notification supprimée').send(res);
    } catch (err) {
      next(err);
    }
  }
}

module.exports = new NotificationController();
