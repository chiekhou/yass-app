const { body, param, query } = require("express-validator");

const updateUserStatus = [
  param("id").isUUID(4).withMessage("Invalid user ID"),

  body("status")
    .isIn(["active", "inactive", "suspended", "pending"])
    .withMessage("Status must be active, inactive, suspended, or pending"),
];

const rejectPartner = [
  param("id").isUUID(4).withMessage("Invalid partner ID"),

  body("reason")
    .trim()
    .notEmpty()
    .withMessage("Rejection reason is required")
    .isLength({ min: 10, max: 500 })
    .withMessage("Reason must be between 10 and 500 characters"),
];

const suspendPartner = [
  param("id").isUUID(4).withMessage("Invalid partner ID"),

  body("reason")
    .trim()
    .notEmpty()
    .withMessage("Suspension reason is required")
    .isLength({ min: 10, max: 500 })
    .withMessage("Reason must be between 10 and 500 characters"),
];

const rejectEstablishment = [
  param("id").isUUID(4).withMessage("Invalid establishment ID"),

  body("reason")
    .trim()
    .notEmpty()
    .withMessage("Rejection reason is required")
    .isLength({ min: 10, max: 500 })
    .withMessage("Reason must be between 10 and 500 characters"),
];

module.exports = {
  updateUserStatus,
  rejectPartner,
  suspendPartner,
  rejectEstablishment,
};
