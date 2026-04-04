import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:win_app/features/favorites/presentation/bloc/favorites_bloc.dart';
import 'package:win_app/l10n/app_localizations.dart';

import 'core/theme/app_theme.dart';
import 'core/theme/theme_cubit.dart';
import 'core/l10n/language_cubit.dart';
import 'core/constants/api_config.dart';
import 'core/network/api_client.dart';
import 'app_router.dart';
import 'package:firebase_core/firebase_core.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/home/presentation/bloc/home_bloc.dart';
import 'features/search/presentation/bloc/search_bloc.dart';
import 'features/reviews/presentation/bloc/review_bloc.dart';
import 'features/notifications/presentation/bloc/notifications_bloc.dart';
import 'core/services/fcm_service.dart';

final _languageCubit = LanguageCubit();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await _languageCubit.loadSavedLocale();

  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
    statusBarBrightness: Brightness.light,
  ));

  // Initialize Firebase and FCM (requires google-services.json / GoogleService-Info.plist)
  try {
    await Firebase.initializeApp();
    await FcmService.initialize();
  } catch (_) {
    // Firebase not configured yet — app works without push notifications
  }

  // TODO: retirer avant la prod
  /*final prefs = await SharedPreferences.getInstance();
  await prefs.remove('onboarding_done');*/

  // Init router (onboarding flag)
  await AppRouter.init();

  // Enregistre la visite (fire-and-forget, jamais bloquant)
  _trackVisit();

  runApp(const WinApp());
}

Future<void> _trackVisit() async {
  try {
    final String platform;
    if (defaultTargetPlatform == TargetPlatform.android) {
      platform = 'android';
    } else if (defaultTargetPlatform == TargetPlatform.iOS) {
      platform = 'ios';
    } else {
      platform = 'web';
    }
    await ApiClient.instance
        .post(ApiConfig.trackVisit, data: {'platform': platform});
  } catch (_) {
    // Silently ignore — le tracking ne doit jamais bloquer l'app
  }
}

class WinApp extends StatelessWidget {
  const WinApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        // Language Cubit - Global
        BlocProvider.value(value: _languageCubit),
        // Theme Cubit - Global
        BlocProvider(
          create: (_) => ThemeCubit(),
        ),
        // Auth BLoC - Global
        BlocProvider(
          create: (_) => AuthBloc()..add(AuthCheckRequested()),
        ),
        // Home BLoC - Global
        BlocProvider(
          create: (_) => HomeBloc()..add(HomeLoadData()),
        ),
        // Favorites BLoC - Global
        BlocProvider(
          create: (_) => FavoriteBloc(),
        ),
        // Search BLoC - Global
        BlocProvider(
          create: (_) => SearchBloc(),
        ),
        // Review BLoC - Global
        BlocProvider(
          create: (_) => ReviewBloc(),
        ),
        // Notifications BLoC - Global (badge count)
        BlocProvider(
          create: (_) => NotificationsBloc(),
        ),
      ],
      child: BlocListener<AuthBloc, AuthState>(
        listenWhen: (previous, current) =>
            previous.runtimeType != current.runtimeType &&
            (current is AuthAuthenticated || current is AuthUnauthenticated),
        listener: (context, state) {
          if (state is AuthAuthenticated) {
            // Reload notifications with valid token
            context.read<NotificationsBloc>().add(const LoadNotifications());
            // Register FCM token now that the user is authenticated
            FcmService.registerTokenIfAvailable();
          } else if (state is AuthUnauthenticated) {
            // Reset on logout
            context.read<HomeBloc>().add(HomeLoadData());
            context.read<NotificationsBloc>().add(const LoadNotifications());
            AppRouter.router.go(AppRoutes.main);
          }
        },
        child: BlocBuilder<LanguageCubit, Locale>(
          builder: (context, locale) => BlocBuilder<ThemeCubit, ThemeMode>(
            builder: (context, themeMode) => MaterialApp.router(
              title: 'Win',
              debugShowCheckedModeBanner: false,
              theme: AppTheme.lightTheme,
              darkTheme: AppTheme.darkTheme,
              themeMode: themeMode,
              locale: locale,
              localizationsDelegates: const [
                AppLocalizations.delegate,
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              supportedLocales: LanguageCubit.supportedLocales,
              routerConfig: AppRouter.router,
              builder: (context, child) {
                return MediaQuery(
                  data: MediaQuery.of(context).copyWith(
                    textScaler: const TextScaler.linear(1.0),
                  ),
                  child: child!,
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
