import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:win_app/core/l10n/l10n_extensions.dart';

import 'features/onboarding/presentation/pages/onboarding_page.dart';
import 'features/auth/presentation/pages/login_page.dart';
import 'features/auth/presentation/pages/register_page.dart';
import 'features/auth/presentation/pages/register_partner_page.dart';
import 'features/auth/presentation/pages/forgot_password_page.dart';
import 'features/auth/presentation/pages/reset_password_page.dart';
import 'features/auth/presentation/pages/reset_password_phone_page.dart';
import 'features/auth/presentation/pages/verify_email_page.dart';
import 'features/auth/presentation/pages/verify_otp_page.dart';
import 'features/home/presentation/pages/home_page.dart';
import 'features/home/presentation/pages/main_page.dart';
import 'features/search/presentation/pages/search_page.dart';
import 'features/establishment/data/models/establishment_model.dart';
import 'features/establishment/presentation/pages/establishment_details_page.dart';
import 'features/establishment/presentation/pages/establishment_photos_page.dart';
import 'features/favorites/presentation/pages/favorites_page.dart';
import 'features/profile/presentation/pages/profile_page.dart';
import 'features/profile/presentation/pages/edit_profile_page.dart';
import 'features/profile/presentation/pages/edit_partner_profile_page.dart';
import 'features/reviews/presentation/pages/write_review_page.dart';
import 'features/reviews/presentation/pages/all_reviews_page.dart';
import 'features/reviews/presentation/pages/my_reviews_page.dart';
import 'features/reviews/data/models/review_model.dart';
import 'features/home/presentation/pages/category_page.dart';
import 'features/home/presentation/pages/all_categories_page.dart';
import 'features/home/data/models/category_model.dart';

// Admin imports
import 'features/admin/presentation/pages/admin_create_partner_page.dart';
import 'features/admin/presentation/pages/admin_create_establishment_page.dart';
import 'features/admin/presentation/pages/admin_dashboard_page.dart';
import 'features/admin/presentation/pages/admin_users_page.dart';
import 'features/admin/presentation/pages/admin_partners_page.dart';
import 'features/admin/presentation/pages/admin_partner_detail_page.dart';
import 'features/admin/presentation/pages/admin_user_detail_page.dart';
import 'features/admin/presentation/pages/admin_pending_establishments_page.dart';
import 'features/admin/presentation/pages/admin_establishments_page.dart';
import 'features/admin/presentation/bloc/admin_dashboard_bloc.dart';
import 'features/admin/presentation/bloc/admin_users_bloc.dart';
import 'features/admin/presentation/bloc/admin_partners_bloc.dart';
import 'features/admin/presentation/bloc/admin_establishments_bloc.dart';
import 'features/admin/presentation/bloc/admin_reviews_bloc.dart';
import 'features/admin/presentation/pages/admin_all_reviews_page.dart';
import 'features/admin/presentation/pages/admin_reported_reviews_page.dart';
import 'features/admin/presentation/pages/admin_payments_page.dart';
import 'features/admin/presentation/bloc/admin_payments_bloc.dart';

// Partner imports
import 'features/partner/presentation/pages/partner_dashboard_page.dart';
import 'features/partner/presentation/pages/partner_establishments_page.dart';
import 'features/partner/presentation/pages/partner_establishment_form_page.dart';
import 'features/partner/presentation/pages/partner_establishment_details_page.dart';
import 'features/partner/presentation/pages/partner_subscription_page.dart';
import 'features/partner/presentation/pages/partner_invoices_page.dart';
import 'features/partner/presentation/pages/partner_invoice_detail_page.dart';
import 'features/partner/presentation/pages/partner_reviews_page.dart';
import 'features/partner/presentation/bloc/partner_dashboard_bloc.dart';
import 'features/partner/presentation/bloc/partner_establishments_bloc.dart';
import 'features/partner/presentation/bloc/partner_subscription_bloc.dart';
import 'features/partner/presentation/bloc/partner_invoices_bloc.dart';

// Map
import 'features/map/presentation/pages/map_page.dart';

// Notifications
import 'features/notifications/presentation/pages/notifications_page.dart';
import 'features/notifications/presentation/bloc/notifications_bloc.dart';

// Suggestions
import 'features/suggestions/presentation/pages/suggestions_list_page.dart';
import 'features/suggestions/presentation/pages/suggest_establishment_page.dart';
import 'features/suggestions/presentation/pages/my_suggestions_page.dart';
import 'features/admin/presentation/pages/admin_suggestions_page.dart';
import 'features/admin/presentation/pages/admin_wilayas_page.dart';
import 'features/admin/presentation/pages/admin_categories_availability_page.dart';
import 'features/profile/presentation/pages/privacy_policy_page.dart';
import 'features/profile/presentation/pages/terms_of_service_page.dart';
import 'features/profile/presentation/pages/about_page.dart';

class AppRoutes {
  static const String splash = '/';
  static const String onboarding = '/onboarding';
  static const String login = '/login';
  static const String register = '/register';
  static const String registerPartner = '/register/partner';
  static const String forgotPassword = '/forgot-password';
  static const String verifyOtp = '/verify-otp';
  static const String main = '/main';
  static const String home = '/home';
  static const String search = '/search';
  static const String map = '/map';
  static const String favorites = '/favorites';
  static const String profile = '/profile';
  static const String establishment = '/establishment/:id';
  static const String establishmentBySlug = '/e/:slug';
  static const String category = '/category/:id';
  static const String allCategories = '/categories';
  static const String writeReview = '/review/:establishmentId';
  static const String editProfile = '/profile/edit';
  static const String editPartnerProfile = '/partner/profile/edit';
  static const String settings = '/settings';
  static const String myReviews = '/my-reviews';
  static const String allReviews = '/establishment/:establishmentId/reviews';
  static const String establishmentPhotos = '/establishment/:id/photos';

  // Partner routes
  static const String partnerDashboard = '/partner';
  static const String partnerSubscription = '/partner/subscription';
  static const String partnerInvoices = '/partner/invoices';
  static const String _partnerInvoiceDetailPath = '/partner/invoices/:id';
  static String partnerInvoiceDetail(String id) => '/partner/invoices/$id';
  static const String partnerReviews = '/partner/reviews';
  static const String partnerEstablishments = '/partner/establishments';
  static const String partnerEstablishmentCreate = '/partner/establishments/create';
  static const String partnerEstablishmentDetails = '/partner/establishments/:id';
  static const String partnerEstablishmentEdit = '/partner/establishments/:id/edit';

  // Admin create/edit routes
  static const String adminCreatePartner = '/admin/partners/create';
  static const String adminCreateEstablishment = '/admin/establishments/create';
  static const String adminEditEstablishment = '/admin/establishments/:id/edit';

  // Admin routes
  static const String adminDashboard = '/admin';
  static const String adminUsers = '/admin/users';
  static const String adminUserDetails = '/admin/users/:id';
  static const String adminPartners = '/admin/partners';
  static const String adminPendingPartners = '/admin/partners/pending';
  static const String adminPartnerDetails = '/admin/partners/:id';
  static const String adminPendingEstablishments = '/admin/establishments/pending';
  static const String adminEstablishments = '/admin/establishments';
  static const String adminReviews = '/admin/reviews';
  static const String adminReportedReviews = '/admin/reviews/reported';
  static const String adminPendingPayments = '/admin/payments/pending';
  static const String adminSuggestions = '/admin/suggestions';
  static const String adminWilayas = '/admin/wilayas';
  static const String adminCategoriesAvailability = '/admin/categories';

  // Notifications
  static const String notifications = '/notifications';

  // Deep link targets
  static const String verifyEmail = '/verify-email';
  static const String resetPassword = '/reset-password';
  static const String resetPasswordPhone = '/reset-password/phone';

  // Legal / About
  static const String about = '/about';
  static const String privacyPolicy = '/privacy-policy';
  static const String termsOfService = '/terms';

  // Suggestions
  static const String suggestions = '/suggestions';
  static const String newSuggestion = '/suggestions/new';
  static const String mySuggestions = '/suggestions/mine';
}

class AppRouter {
  static bool _onboardingDone = false;
  static final _rootNavigatorKey = GlobalKey<NavigatorState>();
  static final _shellNavigatorKey = GlobalKey<NavigatorState>();

  /// Doit être appelé dans main() avant runApp().
  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _onboardingDone = prefs.getBool('onboarding_done') ?? false;
  }

  /// Appelé depuis OnboardingPage pour débloquer la navigation en mémoire.
  static void setOnboardingDone() => _onboardingDone = true;

  static final router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: AppRoutes.main,
    debugLogDiagnostics: true,
    redirect: (context, state) {
      // GoRouter intercepte les deep links win:// de la plateforme avant
      // app_links — on les convertit ici en chemin GoRouter valide.
      if (state.uri.scheme == 'win') {
        final host = state.uri.host;   // ex: "reset-password"
        final path = state.uri.path;   // ex: "" ou "/subscription"
        final query = state.uri.query; // ex: "token=abc"
        return '/$host$path${query.isNotEmpty ? '?$query' : ''}';
      }
      if (!_onboardingDone &&
          state.matchedLocation != AppRoutes.onboarding) {
        return AppRoutes.onboarding;
      }
      return null;
    },
    routes: [
      // Onboarding
      GoRoute(
        path: AppRoutes.onboarding,
        name: 'onboarding',
        builder: (context, state) => const OnboardingPage(),
      ),
      // Auth Routes
      GoRoute(
        path: AppRoutes.login,
        name: 'login',
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: AppRoutes.register,
        name: 'register',
        builder: (context, state) => const RegisterPage(),
      ),
      GoRoute(
        path: AppRoutes.registerPartner,
        name: 'registerPartner',
        builder: (context, state) => const RegisterPartnerPage(),
      ),
      GoRoute(
        path: AppRoutes.forgotPassword,
        name: 'forgotPassword',
        builder: (context, state) => const ForgotPasswordPage(),
      ),
      GoRoute(
        path: AppRoutes.resetPasswordPhone,
        name: 'resetPasswordPhone',
        builder: (context, state) => ResetPasswordPhonePage(
          phone: state.extra as String? ?? '',
        ),
      ),
      GoRoute(
        path: AppRoutes.verifyOtp,
        name: 'verifyOtp',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>? ?? {};
          return VerifyOtpPage(
            verificationType: extra['verificationType'] as String? ?? 'email',
            destination: extra['destination'] as String? ?? '',
          );
        },
      ),

      // Edit Profile (before ShellRoute to avoid conflict with /profile)
      GoRoute(
        path: AppRoutes.editProfile,
        name: 'editProfile',
        builder: (context, state) => const EditProfilePage(),
      ),

      // Edit Partner Profile (company info)
      GoRoute(
        path: AppRoutes.editPartnerProfile,
        name: 'editPartnerProfile',
        builder: (context, state) => const EditPartnerProfilePage(),
      ),

      // Main Shell Route with Bottom Navigation
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) => MainPage(child: child),
        routes: [
          GoRoute(
            path: AppRoutes.main,
            name: 'main',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: HomePage()),
          ),
          GoRoute(
            path: AppRoutes.search,
            name: 'search',
            pageBuilder: (context, state) {
              final query = state.uri.queryParameters['q'];
              final categoryId = state.uri.queryParameters['category'];
              final wilayaId = state.uri.queryParameters['wilaya'];
              return NoTransitionPage(
                child: SearchPage(
                  initialQuery: query,
                  categoryId: categoryId,
                  wilayaId: wilayaId,
                ),
              );
            },
          ),
          GoRoute(
            path: AppRoutes.favorites,
            name: 'favorites',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: FavoritesPage()),
          ),
          GoRoute(
            path: AppRoutes.profile,
            name: 'profile',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: ProfilePage()),
          ),
        ],
      ),

      // Map (full-screen push, no bottom nav)
      GoRoute(
        path: AppRoutes.map,
        name: 'map',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>? ?? {};
          return MapPage(
            initialQuery: extra['query'] as String?,
            initialCategoryId: extra['categoryId'] as String?,
            initialSubcategoryId: extra['subcategoryId'] as String?,
            initialWilayaId: extra['wilayaId'] as String?,
          );
        },
      ),

      // Establishment Details
      GoRoute(
        path: AppRoutes.establishment,
        name: 'establishment',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return EstablishmentDetailsPage(establishmentId: id);
        },
      ),
      GoRoute(
        path: AppRoutes.establishmentBySlug,
        name: 'establishmentBySlug',
        builder: (context, state) {
          final slug = state.pathParameters['slug']!;
          return EstablishmentDetailsPage(slug: slug);
        },
      ),
      GoRoute(
        path: AppRoutes.establishmentPhotos,
        name: 'establishmentPhotos',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>;
          return EstablishmentPhotosPage(
            establishmentName: extra['name'] as String,
            photos: List<PhotoItem>.from(extra['photos'] as List),
          );
        },
      ),

      // Category
      GoRoute(
        path: AppRoutes.category,
        name: 'category',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          final name = state.uri.queryParameters['name'];
          return CategoryPage(categoryId: id, categoryName: name);
        },
      ),
      GoRoute(
        path: AppRoutes.allCategories,
        name: 'allCategories',
        builder: (context, state) {
          final cats = state.extra as List<Category>?;
          return AllCategoriesPage(initialCategories: cats);
        },
      ),

      // Write Review
      GoRoute(
        path: AppRoutes.writeReview,
        name: 'writeReview',
        builder: (context, state) {
          final establishmentId = state.pathParameters['establishmentId']!;
          final establishmentName = state.uri.queryParameters['name'];
          final categoryName = state.uri.queryParameters['category'];
          final initialRating = int.tryParse(
                  state.uri.queryParameters['initialRating'] ?? '') ??
              0;
          return WriteReviewPage(
            establishmentId: establishmentId,
            establishmentName: establishmentName,
            categoryName: categoryName,
            initialRating: initialRating,
          );
        },
      ),

      // All Reviews for an establishment
      GoRoute(
        path: AppRoutes.allReviews,
        name: 'allReviews',
        builder: (context, state) {
          final establishmentId = state.pathParameters['establishmentId']!;
          final extra = state.extra as Map<String, dynamic>?;
          return AllReviewsPage(
            establishmentId: establishmentId,
            establishmentName: extra?['establishmentName'] as String?,
            categoryName: extra?['categoryName'] as String?,
            initialData: extra?['reviewsData'] as ReviewsResponse?,
          );
        },
      ),

      // My Reviews
      GoRoute(
        path: AppRoutes.myReviews,
        name: 'myReviews',
        builder: (context, state) => const MyReviewsPage(),
      ),

      // Admin Create Routes (avant adminDashboard pour éviter les conflits)
      GoRoute(
        path: AppRoutes.adminCreatePartner,
        name: 'adminCreatePartner',
        builder: (context, state) => BlocProvider(
          create: (context) => AdminPartnersBloc(),
          child: const AdminCreatePartnerPage(),
        ),
      ),
      GoRoute(
        path: AppRoutes.adminCreateEstablishment,
        name: 'adminCreateEstablishment',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>? ?? {};
          return AdminCreateEstablishmentPage(
            partnerId: extra['partnerId'] as String? ?? '',
            partnerName: extra['partnerName'] as String? ?? '',
          );
        },
      ),
      GoRoute(
        path: AppRoutes.adminEditEstablishment,
        name: 'adminEditEstablishment',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          final extra = state.extra as Map<String, dynamic>? ?? {};
          return AdminCreateEstablishmentPage(
            establishmentId: id,
            partnerId: extra['partnerId'] as String? ?? '',
            partnerName: extra['partnerName'] as String? ?? '',
          );
        },
      ),

      // Admin Routes
      GoRoute(
        path: AppRoutes.adminDashboard,
        name: 'adminDashboard',
        builder: (context, state) => BlocProvider(
          create: (context) => AdminDashboardBloc(),
          child: const AdminDashboardPage(),
        ),
      ),
      GoRoute(
        path: AppRoutes.adminUsers,
        name: 'adminUsers',
        builder: (context, state) => BlocProvider(
          create: (context) => AdminUsersBloc(),
          child: const AdminUsersPage(),
        ),
      ),
      GoRoute(
        path: AppRoutes.adminUserDetails,
        name: 'adminUserDetails',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return BlocProvider(
            create: (context) => AdminUsersBloc()
              ..add(AdminUserLoadDetails(userId: id)),
            child: const AdminUserDetailPage(),
          );
        },
      ),
      GoRoute(
        path: AppRoutes.adminPartners,
        name: 'adminPartners',
        builder: (context, state) => BlocProvider(
          create: (context) => AdminPartnersBloc(),
          child: const AdminPartnersPage(),
        ),
      ),
      GoRoute(
        path: AppRoutes.adminPendingPartners,
        name: 'adminPendingPartners',
        builder: (context, state) => BlocProvider(
          create: (context) => AdminPartnersBloc(),
          child: const AdminPartnersPage(pendingOnly: true),
        ),
      ),
      GoRoute(
        path: AppRoutes.adminPartnerDetails,
        name: 'adminPartnerDetails',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return BlocProvider(
            create: (context) => AdminPartnersBloc()
              ..add(AdminPartnerLoadDetails(partnerId: id)),
            child: const AdminPartnerDetailPage(),
          );
        },
      ),
      GoRoute(
        path: AppRoutes.adminEstablishments,
        name: 'adminEstablishments',
        builder: (context, state) => BlocProvider(
          create: (context) => AdminEstablishmentsBloc(),
          child: const AdminEstablishmentsPage(),
        ),
      ),
      GoRoute(
        path: AppRoutes.adminPendingEstablishments,
        name: 'adminPendingEstablishments',
        builder: (context, state) => BlocProvider(
          create: (context) => AdminEstablishmentsBloc(),
          child: const AdminPendingEstablishmentsPage(),
        ),
      ),

      // Admin Reviews Management
      GoRoute(
        path: AppRoutes.adminReviews,
        name: 'adminReviews',
        builder: (context, state) => BlocProvider(
          create: (context) => AdminReviewsBloc(),
          child: const AdminAllReviewsPage(),
        ),
      ),
      GoRoute(
        path: AppRoutes.adminReportedReviews,
        name: 'adminReportedReviews',
        builder: (context, state) => BlocProvider(
          create: (context) => AdminReviewsBloc(),
          child: const AdminReportedReviewsPage(),
        ),
      ),

      // Admin Payments
      GoRoute(
        path: AppRoutes.adminPendingPayments,
        name: 'adminPendingPayments',
        builder: (context, state) => BlocProvider(
          create: (context) => AdminPaymentsBloc(),
          child: const AdminPaymentsPage(),
        ),
      ),

      // Partner Routes
      GoRoute(
        path: AppRoutes.partnerDashboard,
        name: 'partnerDashboard',
        builder: (context, state) => MultiBlocProvider(
          providers: [
            BlocProvider(create: (context) => PartnerDashboardBloc()),
            BlocProvider(
              create: (context) => PartnerSubscriptionBloc()
                ..add(const LoadSubscriptionStatus()),
            ),
          ],
          child: const PartnerDashboardPage(),
        ),
      ),
      GoRoute(
        path: AppRoutes.partnerEstablishments,
        name: 'partnerEstablishments',
        builder: (context, state) => BlocProvider(
          create: (context) => PartnerEstablishmentsBloc(),
          child: const PartnerEstablishmentsPage(),
        ),
      ),
      GoRoute(
        path: AppRoutes.partnerEstablishmentCreate,
        name: 'partnerEstablishmentCreate',
        builder: (context, state) => const PartnerEstablishmentFormPage(),
      ),
      GoRoute(
        path: AppRoutes.partnerEstablishmentDetails,
        name: 'partnerEstablishmentDetails',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          final q = state.uri.queryParameters;
          final paymentResult = q.containsKey('featured_success')
              ? 'featured_success'
              : q.containsKey('featured_failed')
                  ? 'featured_failed'
                  : null;
          return PartnerEstablishmentDetailsPage(
            establishmentId: id,
            paymentResult: paymentResult,
          );
        },
      ),
      GoRoute(
        path: AppRoutes.partnerEstablishmentEdit,
        name: 'partnerEstablishmentEdit',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return PartnerEstablishmentFormPage(establishmentId: id);
        },
      ),
      GoRoute(
        path: AppRoutes.partnerSubscription,
        name: 'partnerSubscription',
        builder: (context, state) {
          final q = state.uri.queryParameters;
          final paymentResult = q.containsKey('success')
              ? 'success'
              : q.containsKey('failed')
                  ? 'failed'
                  : null;
          return BlocProvider(
            create: (context) => PartnerSubscriptionBloc()
              ..add(const LoadSubscriptionStatus()),
            child: PartnerSubscriptionPage(paymentResult: paymentResult),
          );
        },
      ),
      GoRoute(
        path: AppRoutes.partnerReviews,
        name: 'partnerReviews',
        builder: (context, state) => const PartnerReviewsPage(),
      ),
      GoRoute(
        path: AppRoutes.partnerInvoices,
        name: 'partnerInvoices',
        builder: (context, state) => BlocProvider(
          create: (context) => PartnerInvoicesBloc()
            ..add(const LoadInvoices()),
          child: const PartnerInvoicesPage(),
        ),
      ),
      GoRoute(
        path: AppRoutes._partnerInvoiceDetailPath,
        name: 'partnerInvoiceDetail',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return BlocProvider(
            create: (context) => PartnerInvoicesBloc(),
            child: PartnerInvoiceDetailPage(invoiceId: id),
          );
        },
      ),

      // Deep link targets — email verification & password reset
      GoRoute(
        path: AppRoutes.verifyEmail,
        name: 'verifyEmail',
        builder: (context, state) {
          final token = state.uri.queryParameters['token'] ?? '';
          return VerifyEmailPage(token: token);
        },
      ),
      GoRoute(
        path: AppRoutes.resetPassword,
        name: 'resetPassword',
        builder: (context, state) {
          final token = state.uri.queryParameters['token'] ?? '';
          return ResetPasswordPage(token: token);
        },
      ),

      // Notifications
      GoRoute(
        path: AppRoutes.notifications,
        name: 'notifications',
        builder: (context, state) => BlocProvider(
          create: (_) => NotificationsBloc()..add(const LoadNotifications()),
          child: const NotificationsPage(),
        ),
      ),

      // Suggestions (community)
      GoRoute(
        path: AppRoutes.suggestions,
        name: 'suggestions',
        builder: (context, state) => const SuggestionsListPage(),
      ),
      GoRoute(
        path: AppRoutes.newSuggestion,
        name: 'newSuggestion',
        builder: (context, state) => const SuggestEstablishmentPage(),
      ),
      GoRoute(
        path: AppRoutes.mySuggestions,
        name: 'mySuggestions',
        builder: (context, state) => const MySuggestionsPage(),
      ),

      // Admin suggestions
      GoRoute(
        path: AppRoutes.adminSuggestions,
        name: 'adminSuggestions',
        builder: (context, state) => const AdminSuggestionsPage(),
      ),

      // Legal pages
      GoRoute(
        path: AppRoutes.about,
        name: 'about',
        builder: (context, state) => const AboutPage(),
      ),
      GoRoute(
        path: AppRoutes.privacyPolicy,
        name: 'privacyPolicy',
        builder: (context, state) => const PrivacyPolicyPage(),
      ),
      GoRoute(
        path: AppRoutes.termsOfService,
        name: 'termsOfService',
        builder: (context, state) => const TermsOfServicePage(),
      ),

      // Admin availability
      GoRoute(
        path: AppRoutes.adminWilayas,
        name: 'adminWilayas',
        builder: (context, state) => const AdminWilayasPage(),
      ),
      GoRoute(
        path: AppRoutes.adminCategoriesAvailability,
        name: 'adminCategoriesAvailability',
        builder: (context, state) => const AdminCategoriesAvailabilityPage(),
      ),
    ],

    // Error Page
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              context.l10n.pageNotFound,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(state.uri.toString()),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.go(AppRoutes.main),
              child: Text(context.l10n.backToHome),
            ),
          ],
        ),
      ),
    ),
  );
}
