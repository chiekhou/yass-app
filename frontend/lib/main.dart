import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:win_app/features/favorites/presentation/bloc/favorites_bloc.dart';

import 'core/theme/app_theme.dart';
import 'core/theme/theme_cubit.dart';
import 'core/constants/app_constants.dart';
import 'app_router.dart';
import 'package:firebase_core/firebase_core.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/home/presentation/bloc/home_bloc.dart';
import 'features/search/presentation/bloc/search_bloc.dart';
import 'features/reviews/presentation/bloc/review_bloc.dart';
import 'features/notifications/presentation/bloc/notifications_bloc.dart';
import 'core/services/fcm_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

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

  runApp(const WinApp());
}

class WinApp extends StatelessWidget {
  const WinApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
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
          create: (_) => NotificationsBloc()..add(const LoadNotifications()),
        ),
      ],
      child: BlocListener<AuthBloc, AuthState>(
        listenWhen: (previous, current) =>
            previous is! AuthUnauthenticated && current is AuthUnauthenticated,
        listener: (context, _) {
          // Reset home data on logout
          context.read<HomeBloc>().add(HomeLoadData());
          // Reset notifications on logout
          context.read<NotificationsBloc>().add(const LoadNotifications());
        },
        child: BlocBuilder<ThemeCubit, ThemeMode>(
          builder: (context, themeMode) => MaterialApp.router(
            title: AppStrings.appName,
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeMode,
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
    );
  }
}
