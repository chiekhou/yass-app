const { Notification, User } = require('../models');
const { PaginatedResponse } = require('../utils/ApiResponse');
const ApiError = require('../utils/ApiError');
const fcmService = require('./fcm.service');

class NotificationService {
  // ─── Core CRUD ──────────────────────────────────────────────────────────────

  /**
   * Create a notification and send a push if the user has an FCM token.
   */
  async create(userId, type, title, body, data = null) {
    const notification = await Notification.create({
      user_id: userId,
      type,
      title,
      body,
      data,
    });

    // Fire-and-forget push notification
    this._sendPush(userId, title, body, data).catch(() => {});

    return notification;
  }

  /**
   * Get paginated notifications for a user (newest first).
   */
  async getAll(userId, page = 1, limit = 20) {
    const offset = (page - 1) * limit;

    const { count, rows } = await Notification.findAndCountAll({
      where: { user_id: userId },
      order: [['created_at', 'DESC']],
      limit,
      offset,
    });

    return PaginatedResponse.paginate(rows, page, limit, count, 'Notifications retrieved');
  }

  /**
   * Count unread notifications for a user.
   */
  async getUnreadCount(userId) {
    const count = await Notification.count({
      where: { user_id: userId, is_read: false },
    });
    return { count };
  }

  /**
   * Mark a single notification as read.
   */
  async markAsRead(notificationId, userId) {
    const notification = await Notification.findOne({
      where: { id: notificationId, user_id: userId },
    });

    if (!notification) throw ApiError.notFound('Notification introuvable');

    await notification.update({ is_read: true, read_at: new Date() });
    return notification;
  }

  /**
   * Mark all notifications as read for a user.
   */
  async markAllAsRead(userId) {
    const [count] = await Notification.update(
      { is_read: true, read_at: new Date() },
      { where: { user_id: userId, is_read: false } }
    );
    return { updated: count };
  }

  /**
   * Delete a notification.
   */
  async delete(notificationId, userId) {
    const notification = await Notification.findOne({
      where: { id: notificationId, user_id: userId },
    });

    if (!notification) throw ApiError.notFound('Notification introuvable');
    await notification.destroy();
  }

  // ─── Event helpers ───────────────────────────────────────────────────────────

  async notifyPartnerApproved(partner, partnerUserId) {
    return this.create(
      partnerUserId,
      'partner_approved',
      'Compte approuvé 🎉',
      `Bienvenue sur YASS ! Votre compte partenaire "${partner.company_name}" a été approuvé. Votre essai de 14 jours commence maintenant.`,
      { partner_id: partner.id }
    );
  }

  async notifyPartnerRejected(partner, partnerUserId, reason = null) {
    const body = reason
      ? `Votre demande a été refusée. Raison : ${reason}`
      : 'Votre demande de compte partenaire a été refusée.';

    return this.create(
      partnerUserId,
      'partner_rejected',
      'Demande refusée',
      body,
      { partner_id: partner.id }
    );
  }

  async notifyEstablishmentApproved(establishment, partnerUserId) {
    return this.create(
      partnerUserId,
      'establishment_approved',
      'Établissement approuvé ✅',
      `Votre établissement "${establishment.name}" est maintenant visible sur YASS.`,
      { establishment_id: establishment.id }
    );
  }

  async notifyEstablishmentRejected(establishment, partnerUserId, reason = null) {
    const body = reason
      ? `"${establishment.name}" a été refusé. Raison : ${reason}`
      : `Votre établissement "${establishment.name}" a été refusé.`;

    return this.create(
      partnerUserId,
      'establishment_rejected',
      'Établissement refusé',
      body,
      { establishment_id: establishment.id }
    );
  }

  async notifyPaymentValidated(invoice, partnerUserId) {
    const planLabels = {
      monthly: 'Mensuel', yearly: 'Annuel',
      featured_7: '7 jours', featured_15: '15 jours', featured_30: '30 jours',
    };
    const planLabel = planLabels[invoice.plan] || invoice.plan;
    const isFeatured = invoice.type === 'featured';
    const title = isFeatured ? 'Mise à la une activée ⭐' : 'Paiement confirmé ✅';
    const body = isFeatured
      ? `Votre mise à la une (${planLabel}) a été activée.`
      : `Votre abonnement ${planLabel} est actif. (${invoice.invoice_number})`;
    return this.create(
      partnerUserId,
      'payment_validated',
      title,
      body,
      { invoice_id: invoice.id, invoice_number: invoice.invoice_number }
    );
  }

  /**
   * Notifie tous les admins/super_admins qu'une nouvelle suggestion est en attente.
   */
  async notifyAdminNewSuggestion(suggestion, suggesterName) {
    const { Op } = require('sequelize');
    const admins = await User.findAll({
      where: { role: { [Op.in]: ['admin', 'super_admin'] }, status: 'active' },
      attributes: ['id'],
    });

    const promises = admins.map((admin) =>
      this.create(
        admin.id,
        'suggestion_pending',
        'Nouvelle suggestion en attente',
        `${suggesterName} a suggéré l'établissement "${suggestion.name}". En attente de validation.`,
        { suggestion_id: suggestion.id }
      )
    );

    await Promise.allSettled(promises);
  }

  /**
   * Notifie tous les admins/super_admins qu'un nouveau paiement manuel est en attente.
   */
  async notifyAdminNewPayment(invoice, partnerCompanyName) {
    const { Op } = require('sequelize');
    const admins = await User.findAll({
      where: { role: { [Op.in]: ['admin', 'super_admin'] }, status: 'active' },
      attributes: ['id'],
    });

    const methodLabel =
      invoice.payment_method === 'cash' ? 'Espèces' :
      invoice.payment_method === 'manual' ? 'Virement bancaire' : 'Chargily';

    const promises = admins.map((admin) =>
      this.create(
        admin.id,
        'payment_pending',
        'Nouveau paiement en attente',
        `${partnerCompanyName} a soumis un paiement (${invoice.invoice_number}) — ${methodLabel}. En attente de validation.`,
        { invoice_id: invoice.id, invoice_number: invoice.invoice_number }
      )
    );

    await Promise.allSettled(promises);
  }

  async notifyReviewReply(review, reviewAuthorUserId) {
    return this.create(
      reviewAuthorUserId,
      'review_reply',
      'Nouvelle réponse à votre avis',
      'Le partenaire a répondu à votre avis.',
      { review_id: review.id }
    );
  }


  async notifySuggestionApproved(suggestion, suggestedByUserId) {
    return this.create(
      suggestedByUserId,
      'suggestion_approved',
      'Suggestion approuvée ✅',
      `Votre suggestion "${suggestion.name}" a été approuvée par l'équipe.  Elle sera bientôt ajoutée à l'annuaire.`,
      { suggestion_id: suggestion.id }
    );
  }

  async notifySuggestionRejected(suggestion, suggestedByUserId, note = null) {
    const body = note
      ? `Votre suggestion "${suggestion.name}" a été refusée. Note : ${note}`
      : `Votre suggestion "${suggestion.name}" a été refusée.`;
    return this.create(
      suggestedByUserId,
      'suggestion_rejected',
      'Suggestion refusée',
      body,
      { suggestion_id: suggestion.id }
    );
  }

  async notifyPartnerNewContact(partnerUserId, establishmentName, senderName, senderEmail) {
    await this.create(
      partnerUserId,
      'contact_message',
      'Nouveau message de contact',
      `${senderName} (${senderEmail}) vous a envoyé un message pour "${establishmentName}".`,
      { sender_name: senderName, sender_email: senderEmail }
    );
  }

  // ─── Internal ────────────────────────────────────────────────────────────────

  async _sendPush(userId, title, body, data) {
    const user = await User.findByPk(userId, { attributes: ['fcm_token'] });
    if (user?.fcm_token) {
      await fcmService.sendToDevice(user.fcm_token, title, body, data || {});
    }
  }
}

module.exports = new NotificationService();
