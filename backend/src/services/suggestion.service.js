const { Op } = require("sequelize");
const {
  EstablishmentSuggestion,
  SuggestionVote,
  SuggestionDownvote,
  User,
  Category,
  Wilaya,
} = require("../models");
const { ApiError, PaginatedResponse } = require("../utils");
const notificationService = require('./notification.service');

const SUGGESTER_ATTRS = ["id", "first_name", "last_name", "avatar"];
const ADMIN_SUGGESTER_ATTRS = ["id", "first_name", "last_name", "email"];
const CATEGORY_ATTRS = ["id", "name", "slug"];
const WILAYA_ATTRS = ["id", "name", "code"];

class SuggestionService {
  // ==================== USER ====================

  /**
   * Soumettre une nouvelle suggestion d'établissement.
   * Le soumetteur compte automatiquement comme premier vote.
   */
  async create(userId, data) {
    const { name, address, phone, description, contact_email, reason, category_id, wilaya_id } = data;

    if (!name || !name.trim()) {
      throw new ApiError(400, "Le nom de l'établissement est obligatoire");
    }
    if (!address || !address.trim()) {
      throw new ApiError(400, "L'adresse est obligatoire");
    }

    const suggestion = await EstablishmentSuggestion.create({
      name: name.trim(),
      address: address.trim(),
      phone: phone?.trim() || null,
      description: description?.trim() || null,
      contact_email: contact_email?.trim() || null,
      reason: reason?.trim() || null,
      category_id: category_id || null,
      wilaya_id: wilaya_id || null,
      suggested_by: userId,
      vote_count: 1,
      status: "pending",
    });

    // Vote automatique du soumetteur
    await SuggestionVote.create({
      suggestion_id: suggestion.id,
      user_id: userId,
    });

    // Notifier les admins (fire-and-forget)
    const suggester = await User.findByPk(userId, { attributes: ['first_name', 'last_name'] });
    const suggesterName = suggester ? `${suggester.first_name} ${suggester.last_name}` : 'Un utilisateur';
    notificationService.notifyAdminNewSuggestion(suggestion, suggesterName)
      .catch((err) => console.error('[Notif] Suggestion admin notif failed:', err.message));

    return suggestion;
  }

  /**
   * Liste paginée des suggestions validées par l'admin, triée par votes décroissants.
   * Inclut si l'utilisateur connecté a déjà voté.
   */
  async getAll(userId, options = {}) {
    const { page = 1, limit = 20 } = options;
    const offset = (page - 1) * limit;

    const { count, rows } = await EstablishmentSuggestion.findAndCountAll({
      where: { status: "approved" },
      include: [
        { model: User, as: "suggester", attributes: SUGGESTER_ATTRS },
        { model: Category, as: "category", attributes: CATEGORY_ATTRS },
        { model: Wilaya, as: "wilaya", attributes: WILAYA_ATTRS },
      ],
      order: [
        ["vote_count", "DESC"],
        ["created_at", "DESC"],
      ],
      limit,
      offset,
    });

    // Récupérer les votes et downvotes de l'utilisateur courant
    let userVotedIds = new Set();
    let userDownvotedIds = new Set();
    if (userId && rows.length > 0) {
      const suggestionIds = rows.map((s) => s.id);
      const [votes, downvotes] = await Promise.all([
        SuggestionVote.findAll({
          where: { suggestion_id: { [Op.in]: suggestionIds }, user_id: userId },
          attributes: ["suggestion_id"],
        }),
        SuggestionDownvote.findAll({
          where: { suggestion_id: { [Op.in]: suggestionIds }, user_id: userId },
          attributes: ["suggestion_id"],
        }),
      ]);
      userVotedIds = new Set(votes.map((v) => v.suggestion_id));
      userDownvotedIds = new Set(downvotes.map((v) => v.suggestion_id));
    }

    const items = rows.map((s) => ({
      ...s.toJSON(),
      has_voted: userVotedIds.has(s.id),
      has_downvoted: userDownvotedIds.has(s.id),
    }));

    return PaginatedResponse.paginate(items, page, limit, count);
  }

  /**
   * Mes suggestions soumises.
   */
  async getMySuggestions(userId, options = {}) {
    const { page = 1, limit = 20 } = options;
    const offset = (page - 1) * limit;

    const { count, rows } = await EstablishmentSuggestion.findAndCountAll({
      where: { suggested_by: userId },
      include: [
        { model: Category, as: "category", attributes: CATEGORY_ATTRS },
        { model: Wilaya, as: "wilaya", attributes: WILAYA_ATTRS },
      ],
      order: [["created_at", "DESC"]],
      limit,
      offset,
    });

    const items = rows.map((s) => ({ ...s.toJSON(), has_voted: true }));
    return PaginatedResponse.paginate(items, page, limit, count);
  }

  /**
   * Voter (ou retirer son vote) pour une suggestion.
   * Le soumetteur ne peut pas retirer son vote initial.
   */
  async vote(userId, suggestionId) {
    const suggestion = await EstablishmentSuggestion.findByPk(suggestionId);
    if (!suggestion) throw new ApiError(404, "Suggestion introuvable");
    if (suggestion.status !== "approved") {
      throw new ApiError(400, "Cette suggestion n'est plus en cours de vote");
    }

    const existing = await SuggestionVote.findOne({
      where: { suggestion_id: suggestionId, user_id: userId },
    });

    if (existing) {
      // Le soumetteur ne peut pas retirer son vote
      if (suggestion.suggested_by === userId) {
        throw new ApiError(
          400,
          "Vous ne pouvez pas retirer votre recommandation initiale"
        );
      }
      await existing.destroy();
      await suggestion.decrement("vote_count");
      await suggestion.reload();
      return { voted: false, vote_count: suggestion.vote_count };
    } else {
      await SuggestionVote.create({
        suggestion_id: suggestionId,
        user_id: userId,
      });
      await suggestion.increment("vote_count");
      await suggestion.reload();
      return { voted: true, vote_count: suggestion.vote_count };
    }
  }

  /**
   * Voter contre (downvote) ou retirer son downvote pour une suggestion.
   */
  async downvote(userId, suggestionId) {
    const suggestion = await EstablishmentSuggestion.findByPk(suggestionId);
    if (!suggestion) throw new ApiError(404, "Suggestion introuvable");
    if (suggestion.status !== "approved") {
      throw new ApiError(400, "Cette suggestion n'est plus en cours de vote");
    }

    const existing = await SuggestionDownvote.findOne({
      where: { suggestion_id: suggestionId, user_id: userId },
    });

    if (existing) {
      await existing.destroy();
      await suggestion.decrement("downvote_count");
      await suggestion.reload();
      return { downvoted: false, downvote_count: suggestion.downvote_count };
    } else {
      await SuggestionDownvote.create({
        suggestion_id: suggestionId,
        user_id: userId,
      });
      await suggestion.increment("downvote_count");
      await suggestion.reload();
      return { downvoted: true, downvote_count: suggestion.downvote_count };
    }
  }

  // ==================== ADMIN ====================

  /**
   * Liste admin avec filtre par statut.
   */
  async adminGetAll(options = {}) {
    const { page = 1, limit = 20, status } = options;
    const offset = (page - 1) * limit;

    const where = {};
    if (status) where.status = status;

    const { count, rows } = await EstablishmentSuggestion.findAndCountAll({
      where,
      include: [
        {
          model: User,
          as: "suggester",
          attributes: ADMIN_SUGGESTER_ATTRS,
        },
        { model: Category, as: "category", attributes: CATEGORY_ATTRS },
        { model: Wilaya, as: "wilaya", attributes: WILAYA_ATTRS },
      ],
      order: [
        ["vote_count", "DESC"],
        ["created_at", "DESC"],
      ],
      limit,
      offset,
    });

    return PaginatedResponse.paginate(rows, page, limit, count);
  }

  /**
   * Approuver une suggestion (elle reste dans le système, l'admin ajoute
   * manuellement l'établissement depuis la page admin établissements).
   */
  async adminApprove(suggestionId, adminUserId) {
    const suggestion = await EstablishmentSuggestion.findByPk(suggestionId);
    if (!suggestion) throw new ApiError(404, "Suggestion introuvable");

    await suggestion.update({
      status: "approved",
      reviewed_by: adminUserId,
      reviewed_at: new Date(),
    });

    notificationService.notifySuggestionApproved(suggestion, suggestion.suggested_by).catch(() => {});

    return suggestion;
  }

  /**
   * Rejeter une suggestion avec une note optionnelle.
   */
  async adminReject(suggestionId, adminUserId, note) {
    const suggestion = await EstablishmentSuggestion.findByPk(suggestionId, {
      include: [
        { model: User, as: "suggester", attributes: ADMIN_SUGGESTER_ATTRS },
      ],
    });
    if (!suggestion) throw new ApiError(404, "Suggestion introuvable");

    await suggestion.update({
      status: "rejected",
      admin_note: note || null,
      reviewed_by: adminUserId,
      reviewed_at: new Date(),
    });

    notificationService.notifySuggestionRejected(suggestion, suggestion.suggested_by, note).catch(() => {});

    return suggestion;
  }
}

module.exports = new SuggestionService();
