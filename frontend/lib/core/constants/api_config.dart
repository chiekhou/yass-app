import '../config/app_config.dart';

class ApiConfig {
  ApiConfig._();

  // Base URL — injectée via --dart-define-from-file=.env.*.json
  static String get baseUrl => AppConfig.baseUrl;

  // Timeouts
  static const int connectTimeout = 30000; // 30 seconds
  static const int receiveTimeout = 30000; // 30 seconds
  static const int sendTimeout = 30000; // 30 seconds

  // Endpoints
  static const String auth = '/auth';
  static const String login = '$auth/login';
  static const String register = '$auth/register';
  static const String registerPartner = '$auth/register/partner';
  static const String refreshToken = '$auth/refresh-token';
  static const String forgotPassword = '$auth/forgot-password';
  static const String forgotPasswordPhone = '$auth/forgot-password/phone';
  static const String resetPassword = '$auth/reset-password';
  static const String resetPasswordPhone = '$auth/reset-password/phone';
  static const String verifyEmail = '$auth/verify-email';
  static const String resendVerification = '$auth/resend-verification';
  static const String changePassword = '$auth/change-password';
  static const String me = '$auth/me';
  static const String updateProfile = '$auth/me';
  static const String updatePartnerProfile = '$auth/partner-profile';
  static const String logout = '$auth/logout';
  static const String registerPhone = '$auth/register/phone';
  static const String loginPhone = '$auth/login/phone';
  static const String sendEmailOtp = '$auth/email/send-otp';
  static const String verifyEmailOtp = '$auth/email/verify-otp';
  static const String sendPhoneOtp = '$auth/phone/send-otp';
  static const String verifyPhoneOtp = '$auth/phone/verify-otp';

  // Wilayas & Communes
  static const String wilayas = '/wilayas';
  static String wilayaById(String id) => '$wilayas/$id';
  static String wilayaByCode(String code) => '$wilayas/code/$code';
  static String communesByWilaya(String wilayaId) =>
      '$wilayas/$wilayaId/communes';
  static const String searchWilayas = '$wilayas/search';

  // Categories
  static const String categories = '/categories';
  static String categoryById(String id) => '$categories/$id';
  static String categoryBySlug(String slug) => '$categories/slug/$slug';
  static String subcategoriesByCategory(String categoryId) =>
      '$categories/$categoryId/subcategories';
  static const String searchCategories = '$categories/search';

  // Subcategories
  static const String subcategories = '/subcategories';
  static String subcategoryById(String id) => '$subcategories/$id';
  static String subcategoryBySlug(String slug) => '$subcategories/slug/$slug';

  // Establishments
  static const String establishments = '/establishments';
  static String establishmentById(String id) => '$establishments/$id';
  static String establishmentBySlug(String slug) =>
      '$establishments/slug/$slug';
  static const String featuredEstablishments = '$establishments/featured';
  static const String nearbyEstablishments = '$establishments/nearby';
  static String establishmentsByCategory(String categoryId) =>
      '$establishments/category/$categoryId';
  static String establishmentsByWilaya(String wilayaId) =>
      '$establishments/wilaya/$wilayaId';
  static String establishmentReviews(String id) =>
      '$establishments/$id/reviews';
  static String trackPhone(String id) => '$establishments/$id/track/phone';
  static String trackWhatsApp(String id) =>
      '$establishments/$id/track/whatsapp';
  static String trackContact(String id) =>
      '$establishments/$id/track/contact';

  // Featured payment (partner)
  static String partnerFeaturedCheckout(String id) =>
      '$partner/establishments/$id/feature/checkout';
  static String partnerFeaturedManual(String id) =>
      '$partner/establishments/$id/feature/manual';

  // Featured payment (admin)
  static String adminFeaturedCheckout(String id) =>
      '$adminEstablishments/$id/feature/checkout';
  static String adminFeaturedManual(String id) =>
      '$adminEstablishments/$id/feature/manual';

  // Favorites
  static const String favorites = '/favorites';
  static const String favoritesCount = '$favorites/count';
  static const String checkMultipleFavorites = '$favorites/check-multiple';
  static String favoriteById(String establishmentId) =>
      '$favorites/$establishmentId';
  static String toggleFavorite(String establishmentId) =>
      '$favorites/$establishmentId/toggle';
  static String checkFavorite(String establishmentId) =>
      '$favorites/$establishmentId/check';

  // Reviews
  static const String reviews = '/reviews';
  static const String myReviews = '$reviews/me';
  static String reviewById(String id) => '$reviews/$id';
  static String markHelpful(String id) => '$reviews/$id/helpful';
  static String reportReview(String id) => '$reviews/$id/report';

  // Upload
  static const String upload = '/upload';
  static const String uploadAvatar = '$upload/avatar';
  static const String uploadReviewImages = '$upload/review-images';
  static const String uploadReviewVideos = '$upload/review-videos';

  // Partner
  static const String partner = '/partner';
  static const String partnerStats = '$partner/stats';
  static const String partnerEstablishments = '$partner/establishments';
  static String partnerEstablishmentById(String id) =>
      '$partner/establishments/$id';
  static String partnerEstablishmentStatus(String id) =>
      '$partner/establishments/$id/status';
  static String partnerEstablishmentLogo(String id) =>
      '$partner/establishments/$id/logo';
  static String partnerEstablishmentCover(String id) =>
      '$partner/establishments/$id/cover';
  static String partnerEstablishmentGallery(String id) =>
      '$partner/establishments/$id/gallery';
  static const String partnerReviews = '$partner/reviews';
  static String partnerReviewReply(String id) => '$partner/reviews/$id/reply';

  // Partner Subscription
  static const String partnerSubscriptionStatus =
      '$partner/subscription/status';
  static const String partnerSubscriptionCheckout =
      '$partner/subscription/checkout';
  static const String partnerSubscriptionManual =
      '$partner/subscription/manual';
  static const String partnerSubscriptionCancel =
      '$partner/subscription/cancel';

  // Partner Invoices
  static const String partnerInvoices = '$partner/invoices';
  static String partnerInvoiceById(String id) => '$partner/invoices/$id';

  // Admin
  static const String admin = '/admin';
  static const String adminDashboard = '$admin/dashboard';
  static const String adminUsers = '$admin/users';
  static const String adminPartners = '$admin/partners';
  static const String adminPendingPartners = '$admin/partners/pending';
  static const String adminEstablishments = '$admin/establishments';
  static String adminEstablishmentById(String id) => '$adminEstablishments/$id';
  static String adminFeatureEstablishment(String id) => '$adminEstablishments/$id/feature';
  static const String adminPendingEstablishments =
      '$admin/establishments/pending';
  static const String adminReviews = '$admin/reviews';
  static const String adminPendingReviews = '$admin/reviews/pending';
  static const String adminReportedReviews = '$admin/reviews/reported';
  static String adminApproveReview(String id) => '$admin/reviews/$id/approve';
  static String adminRejectReview(String id) => '$admin/reviews/$id/reject';
  static String adminDismissReport(String id) =>
      '$admin/reviews/$id/dismiss-report';
  static String adminRevokeReview(String id) => '$admin/reviews/$id/revoke';

  // Admin Payments
  static const String adminPendingPayments = '$admin/payments/pending';
  static String adminValidatePayment(String id) =>
      '$admin/payments/$id/validate';
  static String adminCancelPayment(String id) =>
      '$admin/payments/$id/cancel';

  // Notifications
  static const String notifications = '/notifications';
  static const String notificationsUnreadCount = '$notifications/unread-count';
  static const String notificationsReadAll = '$notifications/read-all';
  static String notificationRead(String id) => '$notifications/$id/read';
  static String notificationDelete(String id) => '$notifications/$id';
  static const String notificationsDeleteAll = notifications;

  // Admin Availability
  static const String adminWilayas = '$admin/wilayas';
  static String adminToggleWilaya(String id) => '$adminWilayas/$id/toggle';
  static const String adminCategories = '$admin/categories';
  static String adminToggleCategory(String id) => '$adminCategories/$id/toggle';

  // FCM Token
  static const String updateFcmToken = '$auth/fcm-token';

  // Suggestions d'établissements
  static const String suggestions = '/suggestions';
  static const String mySuggestions = '$suggestions/mine';
  static String suggestionVote(String id) => '$suggestions/$id/vote';
  static String suggestionDownvote(String id) => '$suggestions/$id/downvote';
  static const String adminSuggestions = '$admin/suggestions';
  static String adminApproveSuggestion(String id) =>
      '$admin/suggestions/$id/approve';
  static String adminRejectSuggestion(String id) =>
      '$admin/suggestions/$id/reject';

  // App tracking
  static const String trackVisit = '/app/visit';
}
