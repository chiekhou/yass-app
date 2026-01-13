const crypto = require("crypto");

/**
 * Generate a random token
 */
const generateToken = (length = 32) => {
  return crypto.randomBytes(length).toString("hex");
};

/**
 * Generate a slug from a string
 */
const generateSlug = (str, suffix = "") => {
  let slug = str
    .toLowerCase()
    .trim()
    .replace(/[àáâãäå]/g, "a")
    .replace(/[èéêë]/g, "e")
    .replace(/[ìíîï]/g, "i")
    .replace(/[òóôõö]/g, "o")
    .replace(/[ùúûü]/g, "u")
    .replace(/[ñ]/g, "n")
    .replace(/[ç]/g, "c")
    .replace(/[^\w\s-]/g, "")
    .replace(/[\s_-]+/g, "-")
    .replace(/^-+|-+$/g, "");

  if (suffix) {
    slug = `${slug}-${suffix}`;
  }

  return slug;
};

/**
 * Generate unique slug
 */
const generateUniqueSlug = async (Model, baseSlug, excludeId = null) => {
  let slug = baseSlug;
  let counter = 1;
  let exists = true;

  while (exists) {
    const where = { slug };
    if (excludeId) {
      where.id = { [require("sequelize").Op.ne]: excludeId };
    }

    const found = await Model.findOne({ where });
    if (found) {
      slug = `${baseSlug}-${counter}`;
      counter++;
    } else {
      exists = false;
    }
  }

  return slug;
};

/**
 * Calculate distance between two coordinates (Haversine formula)
 * Returns distance in kilometers
 */
const calculateDistance = (lat1, lon1, lat2, lon2) => {
  const R = 6371; // Earth's radius in kilometers
  const dLat = toRad(lat2 - lat1);
  const dLon = toRad(lon2 - lon1);

  const a =
    Math.sin(dLat / 2) * Math.sin(dLat / 2) +
    Math.cos(toRad(lat1)) *
      Math.cos(toRad(lat2)) *
      Math.sin(dLon / 2) *
      Math.sin(dLon / 2);

  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
  const distance = R * c;

  return Math.round(distance * 100) / 100; // Round to 2 decimal places
};

const toRad = (deg) => {
  return deg * (Math.PI / 180);
};

/**
 * Parse pagination parameters
 */
const parsePagination = (query, defaults = {}) => {
  const defaultLimit = defaults.limit || 20;
  const maxLimit = defaults.maxLimit || 100;

  let page = parseInt(query.page, 10) || 1;
  let limit = parseInt(query.limit, 10) || defaultLimit;

  if (page < 1) page = 1;
  if (limit < 1) limit = defaultLimit;
  if (limit > maxLimit) limit = maxLimit;

  const offset = (page - 1) * limit;

  return { page, limit, offset };
};

/**
 * Parse sorting parameters
 */
const parseSorting = (
  query,
  allowedFields = [],
  defaultSort = "created_at",
  defaultOrder = "DESC"
) => {
  let sortField = query.sort || defaultSort;
  let sortOrder = (query.order || defaultOrder).toUpperCase();

  // Validate sort field
  if (allowedFields.length > 0 && !allowedFields.includes(sortField)) {
    sortField = defaultSort;
  }

  // Validate sort order
  if (!["ASC", "DESC"].includes(sortOrder)) {
    sortOrder = defaultOrder;
  }

  return { sortField, sortOrder };
};

/**
 * Clean phone number (remove spaces, dashes, etc.)
 */
const cleanPhoneNumber = (phone) => {
  if (!phone) return null;
  return phone.replace(/[\s\-\(\)\.]/g, "");
};

/**
 * Format phone number for Algeria
 */
const formatAlgerianPhone = (phone) => {
  const cleaned = cleanPhoneNumber(phone);
  if (!cleaned) return null;

  // If starts with 0, replace with +213
  if (cleaned.startsWith("0")) {
    return "+213" + cleaned.substring(1);
  }

  // If starts with 213, add +
  if (cleaned.startsWith("213")) {
    return "+" + cleaned;
  }

  // If already has +213, return as is
  if (cleaned.startsWith("+213")) {
    return cleaned;
  }

  // Otherwise, assume it's a local number
  return "+213" + cleaned;
};

/**
 * Validate Algerian phone number
 */
const isValidAlgerianPhone = (phone) => {
  const cleaned = cleanPhoneNumber(phone);
  if (!cleaned) return false;

  // Algerian phone pattern: +213 followed by 9 digits starting with 5, 6, or 7 (mobile)
  // Or starting with 2, 3, 4 (landline)
  const pattern = /^(\+?213|0)(5|6|7|2|3|4)\d{8}$/;
  return pattern.test(cleaned);
};

/**
 * Sanitize string for search
 */
const sanitizeSearchQuery = (query) => {
  if (!query) return "";
  return query
    .trim()
    .replace(/[<>\"\'`;]/g, "")
    .substring(0, 100);
};

/**
 * Get localized field
 */
const getLocalizedField = (obj, field, lang = "fr") => {
  if (lang === "ar" && obj[`${field}_ar`]) {
    return obj[`${field}_ar`];
  }
  if (lang === "en" && obj[`${field}_en`]) {
    return obj[`${field}_en`];
  }
  return obj[field];
};

module.exports = {
  generateToken,
  generateSlug,
  generateUniqueSlug,
  calculateDistance,
  parsePagination,
  parseSorting,
  cleanPhoneNumber,
  formatAlgerianPhone,
  isValidAlgerianPhone,
  sanitizeSearchQuery,
  getLocalizedField,
};
