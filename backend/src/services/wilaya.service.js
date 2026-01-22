const { Wilaya, Commune } = require("../models");
const ApiError = require("../utils/ApiError");

class WilayaService {
  /**
   * Get all active wilayas
   */
  async getAllWilayas(options = {}) {
    const { includeCommunes = false, activeOnly = true } = options;

    const where = {};
    if (activeOnly) {
      where.is_active = true;
    }

    const include = [];
    if (includeCommunes) {
      include.push({
        model: Commune,
        as: "communes",
        where: activeOnly ? { is_active: true } : {},
        required: false,
        attributes: ["id", "code", "name", "name_ar", "name_en", "postal_code"],
      });
    }

    const wilayas = await Wilaya.findAll({
      where,
      include,
      order: [
        ["order", "ASC"],
        ["code", "ASC"],
      ],
      attributes: [
        "id",
        "code",
        "name",
        "name_ar",
        "name_en",
        "latitude",
        "longitude",
      ],
    });

    return wilayas;
  }

  /**
   * Get wilaya by ID
   */
  async getWilayaById(id, options = {}) {
    const { includeCommunes = true } = options;

    const include = [];
    if (includeCommunes) {
      include.push({
        model: Commune,
        as: "communes",
        where: { is_active: true },
        required: false,
        attributes: [
          "id",
          "code",
          "name",
          "name_ar",
          "name_en",
          "postal_code",
          "latitude",
          "longitude",
        ],
        order: [["name", "ASC"]],
      });
    }

    const wilaya = await Wilaya.findByPk(id, {
      include,
      attributes: [
        "id",
        "code",
        "name",
        "name_ar",
        "name_en",
        "latitude",
        "longitude",
      ],
    });

    if (!wilaya) {
      throw ApiError.notFound("Wilaya not found");
    }

    return wilaya;
  }

  /**
   * Get wilaya by code
   */
  async getWilayaByCode(code, options = {}) {
    const { includeCommunes = true } = options;

    const include = [];
    if (includeCommunes) {
      include.push({
        model: Commune,
        as: "communes",
        where: { is_active: true },
        required: false,
        attributes: [
          "id",
          "code",
          "name",
          "name_ar",
          "name_en",
          "postal_code",
          "latitude",
          "longitude",
        ],
      });
    }

    const wilaya = await Wilaya.findOne({
      where: { code },
      include,
      attributes: [
        "id",
        "code",
        "name",
        "name_ar",
        "name_en",
        "latitude",
        "longitude",
      ],
    });

    if (!wilaya) {
      throw ApiError.notFound("Wilaya not found");
    }

    return wilaya;
  }

  /**
   * Get communes by wilaya ID
   */
  async getCommunesByWilaya(wilayaId) {
    const wilaya = await Wilaya.findByPk(wilayaId);

    if (!wilaya) {
      throw ApiError.notFound("Wilaya not found");
    }

    const communes = await Commune.findAll({
      where: {
        wilaya_id: wilayaId,
        is_active: true,
      },
      attributes: [
        "id",
        "code",
        "name",
        "name_ar",
        "name_en",
        "postal_code",
        "latitude",
        "longitude",
      ],
      order: [["name", "ASC"]],
    });

    return communes;
  }

  /**
   * Search wilayas by name
   */
  async searchWilayas(query) {
    const { Op } = require("sequelize");

    const wilayas = await Wilaya.findAll({
      where: {
        is_active: true,
        [Op.or]: [
          { name: { [Op.iLike]: `%${query}%` } },
          { name_ar: { [Op.iLike]: `%${query}%` } },
          { code: { [Op.iLike]: `%${query}%` } },
        ],
      },
      attributes: [
        "id",
        "code",
        "name",
        "name_ar",
        "name_en",
        "latitude",
        "longitude",
      ],
      order: [["name", "ASC"]],
      limit: 10,
    });

    return wilayas;
  }
}

module.exports = new WilayaService();
