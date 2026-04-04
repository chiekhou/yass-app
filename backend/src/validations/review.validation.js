const { body, param, query } = require("express-validator");

const createReview = [
  body("rating")
    .optional()
    .isInt({ min: 1, max: 5 })
    .withMessage("Rating must be between 1 and 5"),

  body("sub_ratings")
    .optional()
    .isObject()
    .withMessage("sub_ratings must be an object"),

  body("sub_ratings.quality").optional().isInt({ min: 1, max: 5 }),
  body("sub_ratings.welcome").optional().isInt({ min: 1, max: 5 }),
  body("sub_ratings.information").optional().isInt({ min: 1, max: 5 }),
  body("sub_ratings.value").optional().isInt({ min: 1, max: 5 }),
  body("sub_ratings.availability").optional().isInt({ min: 1, max: 5 }),
  body("sub_ratings.reliability").optional().isInt({ min: 1, max: 5 }),
  body("sub_ratings.comfort").optional().isInt({ min: 1, max: 5 }),

  body("title")
    .optional()
    .trim()
    .isLength({ min: 3, max: 100 })
    .withMessage("Title must be between 3 and 100 characters"),

  body("comment")
    .trim()
    .notEmpty()
    .withMessage("Comment is required")
    .isLength({ min: 10, max: 2000 })
    .withMessage("Comment must be between 10 and 2000 characters"),

  body("pros").optional().isArray().withMessage("Pros must be an array"),

  body("pros.*")
    .optional()
    .isString()
    .isLength({ max: 100 })
    .withMessage("Each pro must be less than 100 characters"),

  body("cons").optional().isArray().withMessage("Cons must be an array"),

  body("cons.*")
    .optional()
    .isString()
    .isLength({ max: 100 })
    .withMessage("Each con must be less than 100 characters"),

  body("images")
    .optional()
    .isArray({ max: 5 })
    .withMessage("Maximum 5 images allowed"),

  body("images.*")
    .optional()
    .isURL()
    .withMessage("Each image must be a valid URL"),

  body("visit_date")
    .optional()
    .isISO8601()
    .withMessage("Visit date must be a valid date"),
];

const updateReview = [
  param("id").isUUID().withMessage("Invalid review ID"),

  body("rating")
    .optional()
    .isInt({ min: 1, max: 5 })
    .withMessage("Rating must be between 1 and 5"),

  body("title")
    .optional()
    .trim()
    .isLength({ min: 3, max: 100 })
    .withMessage("Title must be between 3 and 100 characters"),

  body("comment")
    .optional()
    .trim()
    .isLength({ min: 10, max: 2000 })
    .withMessage("Comment must be between 10 and 2000 characters"),

  body("pros").optional().isArray().withMessage("Pros must be an array"),

  body("cons").optional().isArray().withMessage("Cons must be an array"),

  body("images")
    .optional()
    .isArray({ max: 5 })
    .withMessage("Maximum 5 images allowed"),

  body("visit_date")
    .optional()
    .isISO8601()
    .withMessage("Visit date must be a valid date"),
];

const reportReview = [
  param("id").isUUID().withMessage("Invalid review ID"),

  body("reason")
    .trim()
    .notEmpty()
    .withMessage("Report reason is required")
    .isLength({ min: 10, max: 500 })
    .withMessage("Reason must be between 10 and 500 characters"),
];

const partnerReply = [
  param("id").isUUID().withMessage("Invalid review ID"),

  body("reply")
    .trim()
    .notEmpty()
    .withMessage("Reply is required")
    .isLength({ min: 10, max: 1000 })
    .withMessage("Reply must be between 10 and 1000 characters"),
];

const rejectReview = [
  param("id").isUUID().withMessage("Invalid review ID"),

  body("reason")
    .trim()
    .notEmpty()
    .withMessage("Rejection reason is required")
    .isLength({ min: 10, max: 500 })
    .withMessage("Reason must be between 10 and 500 characters"),
];

module.exports = {
  createReview,
  updateReview,
  reportReview,
  partnerReply,
  rejectReview,
};
