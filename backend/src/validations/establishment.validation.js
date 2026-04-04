const { body, param, query } = require("express-validator");

const createEstablishment = [
  body("name")
    .trim()
    .notEmpty()
    .withMessage("Le nom est requis")
    .isLength({ min: 2, max: 255 })
    .withMessage("Le nom doit contenir entre 2 et 255 caractères"),

  body("name_ar")
    .optional()
    .trim()
    .isLength({ max: 255 })
    .withMessage("Le nom en arabe doit contenir moins de 255 caractères"),

  body("description")
    .optional()
    .trim()
    .isLength({ max: 2000 })
    .withMessage("La description doit contenir moins de 2000 caractères"),

  body("description_ar")
    .optional()
    .trim()
    .isLength({ max: 2000 })
    .withMessage("La description en arabe doit contenir moins de 2000 caractères"),

  body("category_id")
    .notEmpty()
    .withMessage("La catégorie est requise")
    .isUUID(4)
    .withMessage("Identifiant de catégorie invalide"),

  body("subcategory_id")
    .optional()
    .isUUID(4)
    .withMessage("Identifiant de sous-catégorie invalide"),

  body("wilaya_id")
    .notEmpty()
    .withMessage("La wilaya est requise")
    .isUUID(4)
    .withMessage("Identifiant de wilaya invalide"),

  body("commune_id")
    .optional()
    .isUUID(4)
    .withMessage("Identifiant de commune invalide"),

  body("address")
    .trim()
    .notEmpty()
    .withMessage("L'adresse est requise")
    .isLength({ max: 500 })
    .withMessage("L'adresse doit contenir moins de 500 caractères"),

  body("address_ar")
    .optional()
    .trim()
    .isLength({ max: 500 })
    .withMessage("L'adresse en arabe doit contenir moins de 500 caractères"),

  body("latitude")
    .optional()
    .isFloat({ min: -90, max: 90 })
    .withMessage("La latitude doit être comprise entre -90 et 90"),

  body("longitude")
    .optional()
    .isFloat({ min: -180, max: 180 })
    .withMessage("La longitude doit être comprise entre -180 et 180"),

  body("phone")
    .trim()
    .notEmpty()
    .withMessage("Le numéro de téléphone est requis")
    .matches(/^[+\d\s\-().]{6,20}$/)
    .withMessage("Numéro de téléphone invalide"),

  body("phone_secondary")
    .optional()
    .trim()
    .matches(/^[+\d\s\-().]{6,20}$/)
    .withMessage("Numéro de téléphone secondaire invalide"),

  body("whatsapp")
    .optional()
    .trim()
    .matches(/^[+\d\s\-().]{6,20}$/)
    .withMessage("Numéro WhatsApp invalide"),

  body("email")
    .optional()
    .trim()
    .isEmail()
    .withMessage("Adresse e-mail invalide")
    .normalizeEmail(),

  body("website")
    .optional()
    .trim()
    .isURL()
    .withMessage("URL du site web invalide"),

  body("facebook")
    .optional()
    .trim()
    .isURL()
    .withMessage("URL Facebook invalide"),

  body("instagram")
    .optional()
    .trim()
    .isLength({ max: 255 })
    .withMessage("Le nom d'utilisateur Instagram doit contenir moins de 255 caractères"),

  body("tiktok")
    .optional()
    .trim()
    .isLength({ max: 255 })
    .withMessage("Le nom d'utilisateur TikTok doit contenir moins de 255 caractères"),

  body("snapchat")
    .optional()
    .trim()
    .isLength({ max: 255 })
    .withMessage("Le nom d'utilisateur Snapchat doit contenir moins de 255 caractères"),

  body("opening_hours")
    .optional()
    .isObject()
    .withMessage("Les horaires d'ouverture doivent être un objet"),

  body("price_range")
    .optional()
    .isIn(["$", "$$", "$$$", "$$$$"])
    .withMessage("La gamme de prix doit être $, $$, $$$ ou $$$$"),

  body("services")
    .optional()
    .isArray()
    .withMessage("Les services doivent être un tableau"),

  body("services.*")
    .optional()
    .isString()
    .isLength({ max: 100 })
    .withMessage("Chaque service doit être une chaîne de moins de 100 caractères"),

  body("amenities")
    .optional()
    .isArray()
    .withMessage("Les équipements doivent être un tableau"),

  body("amenities.*")
    .optional()
    .isString()
    .isLength({ max: 100 })
    .withMessage("Chaque équipement doit être une chaîne de moins de 100 caractères"),

  body("tags").optional().isArray().withMessage("Les tags doivent être un tableau"),

  body("tags.*")
    .optional()
    .isString()
    .isLength({ max: 50 })
    .withMessage("Chaque tag doit être une chaîne de moins de 50 caractères"),

  body("images").optional().isArray().withMessage("Les images doivent être un tableau"),

  body("images.*")
    .optional()
    .isURL()
    .withMessage("Chaque image doit être une URL valide"),

  body("logo").optional().isURL().withMessage("Le logo doit être une URL valide"),

  body("cover_image")
    .optional()
    .isURL()
    .withMessage("L'image de couverture doit être une URL valide"),

  body("meta_title")
    .optional()
    .trim()
    .isLength({ max: 100 })
    .withMessage("Le titre méta doit contenir moins de 100 caractères"),

  body("meta_description")
    .optional()
    .trim()
    .isLength({ max: 255 })
    .withMessage("La description méta doit contenir moins de 255 caractères"),
];

const updateEstablishment = [
  param("id").isUUID(4).withMessage("Identifiant d'établissement invalide"),

  body("name")
    .optional()
    .trim()
    .isLength({ min: 2, max: 255 })
    .withMessage("Le nom doit contenir entre 2 et 255 caractères"),

  body("name_ar")
    .optional()
    .trim()
    .isLength({ max: 255 })
    .withMessage("Le nom en arabe doit contenir moins de 255 caractères"),

  body("description")
    .optional()
    .trim()
    .isLength({ max: 2000 })
    .withMessage("La description doit contenir moins de 2000 caractères"),

  body("description_ar")
    .optional()
    .trim()
    .isLength({ max: 2000 })
    .withMessage("La description en arabe doit contenir moins de 2000 caractères"),

  body("category_id")
    .optional()
    .isUUID(4)
    .withMessage("Identifiant de catégorie invalide"),

  body("subcategory_id")
    .optional()
    .isUUID(4)
    .withMessage("Identifiant de sous-catégorie invalide"),

  body("wilaya_id")
    .optional()
    .isUUID(4)
    .withMessage("Identifiant de wilaya invalide"),

  body("commune_id")
    .optional()
    .isUUID(4)
    .withMessage("Identifiant de commune invalide"),

  body("address")
    .optional()
    .trim()
    .isLength({ max: 500 })
    .withMessage("L'adresse doit contenir moins de 500 caractères"),

  body("address_ar")
    .optional()
    .trim()
    .isLength({ max: 500 })
    .withMessage("L'adresse en arabe doit contenir moins de 500 caractères"),

  body("latitude")
    .optional()
    .isFloat({ min: -90, max: 90 })
    .withMessage("La latitude doit être comprise entre -90 et 90"),

  body("longitude")
    .optional()
    .isFloat({ min: -180, max: 180 })
    .withMessage("La longitude doit être comprise entre -180 et 180"),

  body("phone")
    .optional()
    .trim()
    .matches(/^[+\d\s\-().]{6,20}$/)
    .withMessage("Numéro de téléphone invalide"),

  body("phone_secondary")
    .optional()
    .trim()
    .matches(/^[+\d\s\-().]{6,20}$/)
    .withMessage("Numéro de téléphone secondaire invalide"),

  body("whatsapp")
    .optional()
    .trim()
    .matches(/^[+\d\s\-().]{6,20}$/)
    .withMessage("Numéro WhatsApp invalide"),

  body("email")
    .optional()
    .trim()
    .isEmail()
    .withMessage("Adresse e-mail invalide")
    .normalizeEmail(),

  body("website")
    .optional()
    .trim()
    .isURL()
    .withMessage("URL du site web invalide"),

  body("snapchat")
    .optional()
    .trim()
    .isLength({ max: 255 })
    .withMessage("Le nom d'utilisateur Snapchat doit contenir moins de 255 caractères"),

  body("opening_hours")
    .optional()
    .isObject()
    .withMessage("Les horaires d'ouverture doivent être un objet"),

  body("price_range")
    .optional()
    .isIn(["$", "$$", "$$$", "$$$$"])
    .withMessage("La gamme de prix doit être $, $$, $$$ ou $$$$"),

  body("services")
    .optional()
    .isArray()
    .withMessage("Les services doivent être un tableau"),

  body("amenities")
    .optional()
    .isArray()
    .withMessage("Les équipements doivent être un tableau"),

  body("tags").optional().isArray().withMessage("Les tags doivent être un tableau"),
];

const updateStatus = [
  param("id").isUUID(4).withMessage("Identifiant d'établissement invalide"),

  body("status")
    .isIn(["inactive", "pending"])
    .withMessage("Le statut doit être inactive ou pending"),
];

const searchQuery = [
  query("page")
    .optional()
    .isInt({ min: 1 })
    .withMessage("La page doit être un entier positif"),

  query("limit")
    .optional()
    .isInt({ min: 1, max: 100 })
    .withMessage("La limite doit être comprise entre 1 et 100"),

  query("latitude")
    .optional()
    .isFloat({ min: -90, max: 90 })
    .withMessage("La latitude doit être comprise entre -90 et 90"),

  query("longitude")
    .optional()
    .isFloat({ min: -180, max: 180 })
    .withMessage("La longitude doit être comprise entre -180 et 180"),

  query("radius")
    .optional()
    .isFloat({ min: 0.1, max: 100 })
    .withMessage("Le rayon doit être compris entre 0.1 et 100 km"),

  query("min_rating")
    .optional()
    .isFloat({ min: 0, max: 5 })
    .withMessage("La note minimale doit être comprise entre 0 et 5"),

  query("sort_by")
    .optional()
    .isIn([
      "created_at",
      "average_rating",
      "total_reviews",
      "total_views",
      "name",
      "distance",
    ])
    .withMessage("Champ de tri invalide"),

  query("sort_order")
    .optional()
    .isIn(["ASC", "DESC", "asc", "desc"])
    .withMessage("L'ordre de tri doit être ASC ou DESC"),
];

module.exports = {
  createEstablishment,
  updateEstablishment,
  updateStatus,
  searchQuery,
};
