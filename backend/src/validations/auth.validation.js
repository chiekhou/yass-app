const { body } = require("express-validator");

const register = [
  body("email")
    .trim()
    .isEmail()
    .withMessage("Veuillez fournir une adresse e-mail valide")
    .normalizeEmail(),

  body("password")
    .isLength({ min: 8 })
    .withMessage("Le mot de passe doit contenir au moins 8 caractères")
    .matches(/^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)/)
    .withMessage(
      "Le mot de passe doit contenir au moins une majuscule, une minuscule et un chiffre",
    ),

  body("first_name")
    .trim()
    .notEmpty()
    .withMessage("Le prénom est requis")
    .isLength({ min: 2, max: 100 })
    .withMessage("Le prénom doit contenir entre 2 et 100 caractères"),

  body("last_name")
    .trim()
    .notEmpty()
    .withMessage("Le nom est requis")
    .isLength({ min: 2, max: 100 })
    .withMessage("Le nom doit contenir entre 2 et 100 caractères"),

  body("phone")
    .optional()
    .trim()
    .matches(/^\+?[0-9]\d{6,14}$/)
    .withMessage("Veuillez fournir un numéro de téléphone valide (ex. 0551234567 ou +33612345678)"),

  body("language")
    .optional()
    .isIn(["fr", "ar", "en"])
    .withMessage("La langue doit être fr, ar ou en"),

  body("age")
    .optional()
    .isInt({ min: 1, max: 120 })
    .withMessage("L'âge doit être un entier entre 1 et 120"),

  body("gender")
    .optional()
    .isIn(["male", "female", "young", "child"])
    .withMessage("Le genre doit être male, female, young ou child"),

  body("wilaya_id").optional().isUUID(4).withMessage("Identifiant de wilaya invalide"),
];

const registerPartner = [
  // Champs utilisateur
  body("email")
    .trim()
    .isEmail()
    .withMessage("Veuillez fournir une adresse e-mail valide")
    .normalizeEmail(),

  body("password")
    .isLength({ min: 8 })
    .withMessage("Le mot de passe doit contenir au moins 8 caractères")
    .matches(/^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)/)
    .withMessage(
      "Le mot de passe doit contenir au moins une majuscule, une minuscule et un chiffre",
    ),

  body("first_name")
    .trim()
    .notEmpty()
    .withMessage("Le prénom est requis")
    .isLength({ min: 2, max: 100 })
    .withMessage("Le prénom doit contenir entre 2 et 100 caractères"),

  body("last_name")
    .trim()
    .notEmpty()
    .withMessage("Le nom est requis")
    .isLength({ min: 2, max: 100 })
    .withMessage("Le nom doit contenir entre 2 et 100 caractères"),

  body("phone")
    .trim()
    .notEmpty()
    .withMessage("Le numéro de téléphone est requis pour les partenaires")
    .matches(/^\+?[0-9]\d{6,14}$/)
    .withMessage("Veuillez fournir un numéro de téléphone valide (ex. 0551234567 ou +33612345678)"),

  body("language")
    .optional()
    .isIn(["fr", "ar", "en"])
    .withMessage("La langue doit être fr, ar ou en"),

  body("wilaya_id").optional().isUUID(4).withMessage("Identifiant de wilaya invalide"),

  // Champs partenaire
  body("company_name")
    .trim()
    .notEmpty()
    .withMessage("Le nom de l'entreprise est requis")
    .isLength({ min: 2, max: 255 })
    .withMessage("Le nom de l'entreprise doit contenir entre 2 et 255 caractères"),

  body("registration_number")
    .optional()
    .trim()
    .isLength({ max: 100 })
    .withMessage("Le numéro d'enregistrement ne doit pas dépasser 100 caractères"),

  body("tax_id")
    .optional()
    .trim()
    .isLength({ max: 100 })
    .withMessage("L'identifiant fiscal ne doit pas dépasser 100 caractères"),
];

const login = [
  body("email")
    .trim()
    .isEmail()
    .withMessage("Veuillez fournir une adresse e-mail valide")
    .normalizeEmail(),

  body("password").notEmpty().withMessage("Le mot de passe est requis"),
];

const forgotPassword = [
  body("email")
    .trim()
    .isEmail()
    .withMessage("Veuillez fournir une adresse e-mail valide")
    .normalizeEmail(),
];

const resetPassword = [
  body("token").notEmpty().withMessage("Le token de réinitialisation est requis"),

  body("password")
    .isLength({ min: 8 })
    .withMessage("Le mot de passe doit contenir au moins 8 caractères")
    .matches(/^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)/)
    .withMessage(
      "Le mot de passe doit contenir au moins une majuscule, une minuscule et un chiffre",
    ),
];

const changePassword = [
  body("current_password")
    .notEmpty()
    .withMessage("Le mot de passe actuel est requis"),

  body("new_password")
    .isLength({ min: 8 })
    .withMessage("Le nouveau mot de passe doit contenir au moins 8 caractères")
    .matches(/^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)/)
    .withMessage(
      "Le nouveau mot de passe doit contenir au moins une majuscule, une minuscule et un chiffre",
    ),
];

const refreshToken = [
  body("refresh_token").notEmpty().withMessage("Le token de rafraîchissement est requis"),
];

const updateProfile = [
  body("first_name")
    .optional()
    .trim()
    .isLength({ min: 2, max: 100 })
    .withMessage("Le prénom doit contenir entre 2 et 100 caractères"),

  body("last_name")
    .optional()
    .trim()
    .isLength({ min: 2, max: 100 })
    .withMessage("Le nom doit contenir entre 2 et 100 caractères"),

  body("phone")
    .optional()
    .trim()
    .matches(/^\+?[0-9]\d{6,14}$/)
    .withMessage("Veuillez fournir un numéro de téléphone valide (ex. 0551234567 ou +33612345678)"),

  body("language")
    .optional()
    .isIn(["fr", "ar", "en"])
    .withMessage("La langue doit être fr, ar ou en"),

  body("age")
    .optional()
    .isInt({ min: 1, max: 120 })
    .withMessage("L'âge doit être un entier entre 1 et 120"),

  body("gender")
    .optional()
    .isIn(["male", "female", "young", "child"])
    .withMessage("Le genre doit être male, female, young ou child"),

  body("wilaya_id").optional().isUUID(4).withMessage("Identifiant de wilaya invalide"),
];

const updatePartnerProfile = [
  body("company_name")
    .optional()
    .trim()
    .isLength({ min: 2, max: 255 })
    .withMessage("Le nom de l'entreprise doit contenir entre 2 et 255 caractères"),

  body("registration_number")
    .optional()
    .trim()
    .isLength({ max: 100 })
    .withMessage("Le numéro d'enregistrement ne doit pas dépasser 100 caractères"),

  body("tax_id")
    .optional()
    .trim()
    .isLength({ max: 100 })
    .withMessage("L'identifiant fiscal ne doit pas dépasser 100 caractères"),
];

const registerWithPhone = [
  body("phone")
    .trim()
    .notEmpty()
    .withMessage("Le numéro de téléphone est requis")
    .matches(/^\+?[0-9]\d{6,14}$/)
    .withMessage("Veuillez fournir un numéro de téléphone valide (ex. 0551234567 ou +33612345678)"),

  body("password")
    .isLength({ min: 8 })
    .withMessage("Le mot de passe doit contenir au moins 8 caractères")
    .matches(/^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)/)
    .withMessage(
      "Le mot de passe doit contenir au moins une majuscule, une minuscule et un chiffre",
    ),

  body("first_name")
    .trim()
    .notEmpty()
    .withMessage("Le prénom est requis")
    .isLength({ min: 2, max: 100 })
    .withMessage("Le prénom doit contenir entre 2 et 100 caractères"),

  body("last_name")
    .trim()
    .notEmpty()
    .withMessage("Le nom est requis")
    .isLength({ min: 2, max: 100 })
    .withMessage("Le nom doit contenir entre 2 et 100 caractères"),

  body("email")
    .optional({ nullable: true, checkFalsy: true })
    .trim()
    .isEmail()
    .withMessage("Veuillez fournir une adresse e-mail valide")
    .normalizeEmail(),

  body("language")
    .optional()
    .isIn(["fr", "ar", "en"])
    .withMessage("La langue doit être fr, ar ou en"),

  body("age")
    .optional()
    .isInt({ min: 1, max: 120 })
    .withMessage("L'âge doit être un entier entre 1 et 120"),

  body("gender")
    .optional()
    .isIn(["male", "female", "young", "child"])
    .withMessage("Le genre doit être male, female, young ou child"),

  body("wilaya_id").optional().isUUID(4).withMessage("Identifiant de wilaya invalide"),
];

const loginWithPhone = [
  body("phone")
    .trim()
    .notEmpty()
    .withMessage("Le numéro de téléphone est requis")
    .matches(/^\+?[0-9]\d{6,14}$/)
    .withMessage("Veuillez fournir un numéro de téléphone valide (ex. 0551234567 ou +33612345678)"),

  body("password").notEmpty().withMessage("Le mot de passe est requis"),
];

const verifyPhoneOtp = [
  body("otp")
    .trim()
    .notEmpty()
    .withMessage("Le code OTP est requis")
    .isLength({ min: 6, max: 6 })
    .withMessage("Le code OTP doit contenir exactement 6 chiffres")
    .isNumeric()
    .withMessage("Le code OTP ne doit contenir que des chiffres"),
];

// L'OTP par e-mail utilise les mêmes règles de validation que l'OTP par téléphone
const verifyEmailOtp = verifyPhoneOtp;

const forgotPasswordByPhone = [
  body("phone").notEmpty().withMessage("Le numéro de téléphone est requis"),
];

const resetPasswordByPhone = [
  body("phone").notEmpty().withMessage("Le numéro de téléphone est requis"),
  body("otp")
    .notEmpty().withMessage("Le code OTP est requis")
    .isLength({ min: 6, max: 6 }).withMessage("Le code OTP doit contenir 6 chiffres")
    .isNumeric().withMessage("Le code OTP ne doit contenir que des chiffres"),
  body("new_password")
    .isLength({ min: 8 }).withMessage("Le mot de passe doit contenir au moins 8 caractères")
    .matches(/^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)/)
    .withMessage("Le mot de passe doit contenir au moins une majuscule, une minuscule et un chiffre"),
];

module.exports = {
  register,
  registerPartner,
  registerWithPhone,
  login,
  loginWithPhone,
  forgotPassword,
  resetPassword,
  forgotPasswordByPhone,
  resetPasswordByPhone,
  changePassword,
  refreshToken,
  updateProfile,
  updatePartnerProfile,
  verifyPhoneOtp,
  verifyEmailOtp,
};
