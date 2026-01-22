const { body, param, query } = require("express-validator");

const createEstablishment = [
  body("name")
    .trim()
    .notEmpty()
    .withMessage("Name is required")
    .isLength({ min: 2, max: 255 })
    .withMessage("Name must be between 2 and 255 characters"),

  body("name_ar")
    .optional()
    .trim()
    .isLength({ max: 255 })
    .withMessage("Arabic name must be less than 255 characters"),

  body("description")
    .optional()
    .trim()
    .isLength({ max: 2000 })
    .withMessage("Description must be less than 2000 characters"),

  body("description_ar")
    .optional()
    .trim()
    .isLength({ max: 2000 })
    .withMessage("Arabic description must be less than 2000 characters"),

  body("category_id")
    .notEmpty()
    .withMessage("Category is required")
    .isUUID(4)
    .withMessage("Invalid category ID"),

  body("subcategory_id")
    .optional()
    .isUUID(4)
    .withMessage("Invalid subcategory ID"),

  body("wilaya_id")
    .notEmpty()
    .withMessage("Wilaya is required")
    .isUUID(4)
    .withMessage("Invalid wilaya ID"),

  body("commune_id").optional().isUUID(4).withMessage("Invalid commune ID"),

  body("address")
    .trim()
    .notEmpty()
    .withMessage("Address is required")
    .isLength({ max: 500 })
    .withMessage("Address must be less than 500 characters"),

  body("address_ar")
    .optional()
    .trim()
    .isLength({ max: 500 })
    .withMessage("Arabic address must be less than 500 characters"),

  body("latitude")
    .optional()
    .isFloat({ min: -90, max: 90 })
    .withMessage("Latitude must be between -90 and 90"),

  body("longitude")
    .optional()
    .isFloat({ min: -180, max: 180 })
    .withMessage("Longitude must be between -180 and 180"),

  body("phone")
    .trim()
    .notEmpty()
    .withMessage("Phone number is required")
    .matches(/^(\+?213|0)(2|3|4|5|6|7)\d{8}$/)
    .withMessage("Please provide a valid Algerian phone number"),

  body("phone_secondary")
    .optional()
    .trim()
    .matches(/^(\+?213|0)(2|3|4|5|6|7)\d{8}$/)
    .withMessage("Please provide a valid Algerian phone number"),

  body("whatsapp")
    .optional()
    .trim()
    .matches(/^(\+?213|0)(5|6|7)\d{8}$/)
    .withMessage("Please provide a valid Algerian mobile number for WhatsApp"),

  body("email")
    .optional()
    .trim()
    .isEmail()
    .withMessage("Please provide a valid email address")
    .normalizeEmail(),

  body("website")
    .optional()
    .trim()
    .isURL()
    .withMessage("Please provide a valid URL"),

  body("facebook")
    .optional()
    .trim()
    .isURL()
    .withMessage("Please provide a valid Facebook URL"),

  body("instagram")
    .optional()
    .trim()
    .isLength({ max: 255 })
    .withMessage("Instagram username must be less than 255 characters"),

  body("tiktok")
    .optional()
    .trim()
    .isLength({ max: 255 })
    .withMessage("TikTok username must be less than 255 characters"),

  body("opening_hours")
    .optional()
    .isObject()
    .withMessage("Opening hours must be an object"),

  body("price_range")
    .optional()
    .isIn(["$", "$$", "$$$", "$$$$"])
    .withMessage("Price range must be $, $$, $$$, or $$$$"),

  body("services")
    .optional()
    .isArray()
    .withMessage("Services must be an array"),

  body("services.*")
    .optional()
    .isString()
    .isLength({ max: 100 })
    .withMessage("Each service must be a string less than 100 characters"),

  body("amenities")
    .optional()
    .isArray()
    .withMessage("Amenities must be an array"),

  body("amenities.*")
    .optional()
    .isString()
    .isLength({ max: 100 })
    .withMessage("Each amenity must be a string less than 100 characters"),

  body("tags").optional().isArray().withMessage("Tags must be an array"),

  body("tags.*")
    .optional()
    .isString()
    .isLength({ max: 50 })
    .withMessage("Each tag must be a string less than 50 characters"),

  body("images").optional().isArray().withMessage("Images must be an array"),

  body("images.*")
    .optional()
    .isURL()
    .withMessage("Each image must be a valid URL"),

  body("logo").optional().isURL().withMessage("Logo must be a valid URL"),

  body("cover_image")
    .optional()
    .isURL()
    .withMessage("Cover image must be a valid URL"),

  body("meta_title")
    .optional()
    .trim()
    .isLength({ max: 100 })
    .withMessage("Meta title must be less than 100 characters"),

  body("meta_description")
    .optional()
    .trim()
    .isLength({ max: 255 })
    .withMessage("Meta description must be less than 255 characters"),
];

const updateEstablishment = [
  param("id").isUUID(4).withMessage("Invalid establishment ID"),

  body("name")
    .optional()
    .trim()
    .isLength({ min: 2, max: 255 })
    .withMessage("Name must be between 2 and 255 characters"),

  body("name_ar")
    .optional()
    .trim()
    .isLength({ max: 255 })
    .withMessage("Arabic name must be less than 255 characters"),

  body("description")
    .optional()
    .trim()
    .isLength({ max: 2000 })
    .withMessage("Description must be less than 2000 characters"),

  body("description_ar")
    .optional()
    .trim()
    .isLength({ max: 2000 })
    .withMessage("Arabic description must be less than 2000 characters"),

  body("category_id").optional().isUUID(4).withMessage("Invalid category ID"),

  body("subcategory_id")
    .optional()
    .isUUID(4)
    .withMessage("Invalid subcategory ID"),

  body("wilaya_id").optional().isUUID(4).withMessage("Invalid wilaya ID"),

  body("commune_id").optional().isUUID(4).withMessage("Invalid commune ID"),

  body("address")
    .optional()
    .trim()
    .isLength({ max: 500 })
    .withMessage("Address must be less than 500 characters"),

  body("address_ar")
    .optional()
    .trim()
    .isLength({ max: 500 })
    .withMessage("Arabic address must be less than 500 characters"),

  body("latitude")
    .optional()
    .isFloat({ min: -90, max: 90 })
    .withMessage("Latitude must be between -90 and 90"),

  body("longitude")
    .optional()
    .isFloat({ min: -180, max: 180 })
    .withMessage("Longitude must be between -180 and 180"),

  body("phone")
    .optional()
    .trim()
    .matches(/^(\+?213|0)(2|3|4|5|6|7)\d{8}$/)
    .withMessage("Please provide a valid Algerian phone number"),

  body("phone_secondary")
    .optional()
    .trim()
    .matches(/^(\+?213|0)(2|3|4|5|6|7)\d{8}$/)
    .withMessage("Please provide a valid Algerian phone number"),

  body("whatsapp")
    .optional()
    .trim()
    .matches(/^(\+?213|0)(5|6|7)\d{8}$/)
    .withMessage("Please provide a valid Algerian mobile number for WhatsApp"),

  body("email")
    .optional()
    .trim()
    .isEmail()
    .withMessage("Please provide a valid email address")
    .normalizeEmail(),

  body("website")
    .optional()
    .trim()
    .isURL()
    .withMessage("Please provide a valid URL"),

  body("opening_hours")
    .optional()
    .isObject()
    .withMessage("Opening hours must be an object"),

  body("price_range")
    .optional()
    .isIn(["$", "$$", "$$$", "$$$$"])
    .withMessage("Price range must be $, $$, $$$, or $$$$"),

  body("services")
    .optional()
    .isArray()
    .withMessage("Services must be an array"),

  body("amenities")
    .optional()
    .isArray()
    .withMessage("Amenities must be an array"),

  body("tags").optional().isArray().withMessage("Tags must be an array"),
];

const updateStatus = [
  param("id").isUUID(4).withMessage("Invalid establishment ID"),

  body("status")
    .isIn(["inactive", "pending"])
    .withMessage("Status must be inactive or pending"),
];

const searchQuery = [
  query("page")
    .optional()
    .isInt({ min: 1 })
    .withMessage("Page must be a positive integer"),

  query("limit")
    .optional()
    .isInt({ min: 1, max: 100 })
    .withMessage("Limit must be between 1 and 100"),

  query("latitude")
    .optional()
    .isFloat({ min: -90, max: 90 })
    .withMessage("Latitude must be between -90 and 90"),

  query("longitude")
    .optional()
    .isFloat({ min: -180, max: 180 })
    .withMessage("Longitude must be between -180 and 180"),

  query("radius")
    .optional()
    .isFloat({ min: 0.1, max: 100 })
    .withMessage("Radius must be between 0.1 and 100 km"),

  query("min_rating")
    .optional()
    .isFloat({ min: 0, max: 5 })
    .withMessage("Min rating must be between 0 and 5"),

  query("sort_by")
    .optional()
    .isIn([
      "created_at",
      "average_rating",
      "total_reviews",
      "total_views",
      "name",
    ])
    .withMessage("Invalid sort field"),

  query("sort_order")
    .optional()
    .isIn(["ASC", "DESC", "asc", "desc"])
    .withMessage("Sort order must be ASC or DESC"),
];

module.exports = {
  createEstablishment,
  updateEstablishment,
  updateStatus,
  searchQuery,
};
