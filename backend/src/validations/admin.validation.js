const { body, param } = require("express-validator");

const updateUserStatus = [
  param("id").isUUID().withMessage("Invalid user ID"),

  body("status")
    .isIn(["active", "inactive", "suspended", "pending"])
    .withMessage("Status must be active, inactive, suspended, or pending"),
];

const rejectPartner = [
  param("id").isUUID().withMessage("Invalid partner ID"),

  body("reason")
    .trim()
    .notEmpty()
    .withMessage("Rejection reason is required")
    .isLength({ min: 10, max: 500 })
    .withMessage("Reason must be between 10 and 500 characters"),
];

const suspendPartner = [
  param("id").isUUID().withMessage("Invalid partner ID"),

  body("reason")
    .trim()
    .notEmpty()
    .withMessage("Suspension reason is required")
    .isLength({ min: 10, max: 500 })
    .withMessage("Reason must be between 10 and 500 characters"),
];

const rejectEstablishment = [
  param("id").isUUID().withMessage("Invalid establishment ID"),

  body("reason")
    .trim()
    .notEmpty()
    .withMessage("Rejection reason is required")
    .isLength({ min: 10, max: 500 })
    .withMessage("Reason must be between 10 and 500 characters"),
];

const createPartner = [
  body("email")
    .trim()
    .isEmail()
    .withMessage("Please provide a valid email address")
    .normalizeEmail(),

  body("password")
    .isLength({ min: 8 })
    .withMessage("Password must be at least 8 characters long")
    .matches(/^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)/)
    .withMessage(
      "Password must contain at least one uppercase letter, one lowercase letter, and one number",
    ),

  body("first_name")
    .trim()
    .notEmpty()
    .withMessage("First name is required")
    .isLength({ min: 2, max: 100 })
    .withMessage("First name must be between 2 and 100 characters"),

  body("last_name")
    .trim()
    .notEmpty()
    .withMessage("Last name is required")
    .isLength({ min: 2, max: 100 })
    .withMessage("Last name must be between 2 and 100 characters"),

  body("phone")
    .trim()
    .notEmpty()
    .withMessage("Phone number is required")
    .matches(/^\+?\d{7,15}$/)
    .withMessage("Please provide a valid phone number (e.g. 0551234567 or +33612345678)"),

  body("language")
    .optional()
    .isIn(["fr", "ar", "en"])
    .withMessage("Language must be fr, ar, or en"),

  body("wilaya_id").optional().isUUID().withMessage("Invalid wilaya ID"),

  body("company_name")
    .trim()
    .notEmpty()
    .withMessage("Company name is required")
    .isLength({ min: 2, max: 255 })
    .withMessage("Company name must be between 2 and 255 characters"),

  body("registration_number")
    .optional()
    .trim()
    .isLength({ max: 100 })
    .withMessage("Registration number must be less than 100 characters"),

  body("tax_id")
    .optional()
    .trim()
    .isLength({ max: 100 })
    .withMessage("Tax ID must be less than 100 characters"),
];

const createEstablishment = [
  body("partner_id")
    .isUUID()
    .withMessage("Invalid partner ID"),

  body("subcategory_id")
    .isUUID()
    .withMessage("Invalid subcategory ID"),

  body("commune_id")
    .isUUID()
    .withMessage("Invalid commune ID"),

  body("name")
    .trim()
    .notEmpty()
    .withMessage("Name is required")
    .isLength({ min: 2, max: 255 })
    .withMessage("Name must be between 2 and 255 characters"),

  body("name_ar").optional().trim(),

  body("description").trim().notEmpty().withMessage("Description is required"),

  body("description_ar").optional().trim(),

  body("address").trim().notEmpty().withMessage("Address is required"),

  body("address_ar").optional().trim(),

  body("latitude")
    .optional()
    .isFloat({ min: -90, max: 90 })
    .withMessage("Invalid latitude"),

  body("longitude")
    .optional()
    .isFloat({ min: -180, max: 180 })
    .withMessage("Invalid longitude"),

  body("phone")
    .optional()
    .trim()
    .matches(/^\+?\d{7,15}$/)
    .withMessage("Please provide a valid phone number (e.g. 0551234567 or +33612345678)"),

  body("whatsapp")
    .optional()
    .trim()
    .matches(/^\+?\d{7,15}$/)
    .withMessage("Please provide a valid WhatsApp number (e.g. 0551234567 or +33612345678)"),

  body("email")
    .optional()
    .trim()
    .isEmail()
    .withMessage("Please provide a valid email address")
    .normalizeEmail(),

  body("website").optional().trim().isURL().withMessage("Please provide a valid URL"),

  body("price_range")
    .optional()
    .isIn(["$", "$$", "$$$", "$$$$"])
    .withMessage("Price range must be $, $$, $$$ or $$$$"),

  body("opening_hours").optional().isObject().withMessage("Opening hours must be an object"),

  body("services").optional().isArray().withMessage("Services must be an array"),

  body("amenities").optional().isArray().withMessage("Amenities must be an array"),

  body("tags").optional().isArray().withMessage("Tags must be an array"),
];

module.exports = {
  updateUserStatus,
  rejectPartner,
  suspendPartner,
  rejectEstablishment,
  createPartner,
  createEstablishment,
};
