import 'package:flutter/material.dart';
import 'package:win_app/core/l10n/l10n_extensions.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/l10n/language_cubit.dart';
import '../../../../app_router.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      body: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {
          if (state is AuthAuthenticated) {
            return _buildProfile(context, state.user);
          }
          return _buildNotLoggedIn(context);
        },
      ),
    );
  }

  Widget _buildNotLoggedIn(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppDimens.paddingL),
        child: Column(
          children: [
            const Spacer(),
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: AppColors.redSurface,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Iconsax.user,
                size: 60,
                color: AppColors.primaryRed,
              ),
            ),
            const SizedBox(height: AppDimens.paddingL),
            Text(
              context.l10n.welcomeTitle,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: AppDimens.paddingS),
            Text(
              context.l10n.welcomeSubtitle,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.white,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppDimens.paddingXL),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => context.push(AppRoutes.login),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.white,
                  foregroundColor: AppColors.primaryGreen,
                ),
                child: Text(context.l10n.login),
              ),
            ),
            const SizedBox(height: AppDimens.paddingM),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => context.push(AppRoutes.register),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.white,
                  side: const BorderSide(color: AppColors.white),
                ),
                child: Text(context.l10n.register),
              ),
            ),
            const Spacer(),
            _buildGuestMenuItem(
              context,
              icon: Iconsax.info_circle,
              title: context.l10n.about,
              onTap: () => context.push(AppRoutes.about),
            ),
            _buildGuestMenuItem(
              context,
              icon: Iconsax.message_question,
              title: context.l10n.contactUs,
              onTap: _openContactEmail,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfile(BuildContext context, user) {
    return CustomScrollView(
      slivers: [
        // Header
        SliverToBoxAdapter(
          child: Container(
            padding: const EdgeInsets.all(AppDimens.paddingL),
            decoration: const BoxDecoration(
              color: AppColors.background,
            ),
            child: SafeArea(
              bottom: false,
              child: Column(
                children: [
                  // Avatar
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: AppColors.white,
                    backgroundImage:
                        user.avatar != null ? NetworkImage(user.avatar) : null,
                    child: user.avatar == null
                        ? Text(
                            user.firstName.isNotEmpty
                                ? user.firstName[0].toUpperCase()
                                : '?',
                            style: const TextStyle(
                              fontSize: 36,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primaryGreen,
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(height: AppDimens.paddingM),

                  // Name
                  Text(
                    user.fullName,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: AppColors.white,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: AppDimens.paddingXS),

                  // Email
                  Text(
                    user.email,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.white.withOpacity(0.8),
                        ),
                  ),
                  const SizedBox(height: AppDimens.paddingM),

                  // Edit Profile Button
                  OutlinedButton.icon(
                    onPressed: () => context.push(AppRoutes.editProfile),
                    icon: const Icon(Iconsax.edit,
                        size: 18, color: AppColors.primaryRed),
                    label: Text(context.l10n.editProfile),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.white,
                      side: const BorderSide(color: AppColors.white),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        // Menu Items
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(AppDimens.paddingM),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: AppDimens.paddingM),

                // Account Section
                Text(
                  context.l10n.myAccount,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: AppColors.white,
                      ),
                ),
                const SizedBox(height: AppDimens.paddingS),
                _buildMenuCard(
                  context,
                  items: [
                    _MenuItem(
                      icon: Iconsax.notification,
                      title: context.l10n.notifications,
                      onTap: () => context.push(AppRoutes.notifications),
                    ),
                    _MenuItem(
                      icon: Iconsax.heart,
                      title: context.l10n.myFavorites,
                      onTap: () => context.push(AppRoutes.favorites),
                    ),
                    _MenuItem(
                      icon: Iconsax.shop_add,
                      title: context.l10n.mySuggestions,
                      onTap: () => context.push(AppRoutes.mySuggestions),
                    ),
                  ],
                ),

                const SizedBox(height: AppDimens.paddingL),

                // Admin Section (if admin)
                if (user.isAdmin) ...[
                  Text(
                    context.l10n.adminSpace,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: AppColors.white,
                        ),
                  ),
                  const SizedBox(height: AppDimens.paddingS),
                  _buildMenuCard(
                    context,
                    items: [
                      _MenuItem(
                        icon: Iconsax.setting_2,
                        title: context.l10n.dashboard,
                        onTap: () => context.push(AppRoutes.adminDashboard),
                      ),
                      _MenuItem(
                        icon: Iconsax.people,
                        title: context.l10n.usersManagement,
                        onTap: () => context.push(AppRoutes.adminUsers),
                      ),
                      _MenuItem(
                        icon: Iconsax.briefcase,
                        title: context.l10n.partnersManagement,
                        onTap: () => context.push(AppRoutes.adminPartners),
                      ),
                      _MenuItem(
                        icon: Iconsax.message_text,
                        title: context.l10n.reviewsManagement,
                        onTap: () => context.push(AppRoutes.adminReviews),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppDimens.paddingL),
                ],

                // Partner Section (if partner)
                if (user.isPartner) ...[
                  Text(
                    context.l10n.partnerSpace,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: AppColors.white,
                        ),
                  ),
                  const SizedBox(height: AppDimens.paddingS),
                  _buildMenuCard(
                    context,
                    items: [
                      _MenuItem(
                        icon: Iconsax.chart_2,
                        title: context.l10n.dashboard,
                        onTap: () => context.push(AppRoutes.partnerDashboard),
                      ),
                      _MenuItem(
                        icon: Iconsax.building,
                        title: context.l10n.myEstablishments,
                        onTap: () =>
                            context.push(AppRoutes.partnerEstablishments),
                      ),
                      _MenuItem(
                        icon: Iconsax.add_circle,
                        title: context.l10n.addEstablishment,
                        onTap: () =>
                            context.push(AppRoutes.partnerEstablishmentCreate),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppDimens.paddingL),
                ],

                // Settings Section
                Text(
                  context.l10n.settings,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: AppColors.white,
                      ),
                ),
                const SizedBox(height: AppDimens.paddingS),
                BlocBuilder<LanguageCubit, Locale>(
                  builder: (ctx, locale) => _buildMenuCard(
                    ctx,
                    items: [
                      _MenuItem(
                        icon: Iconsax.language_square,
                        title: context.l10n.language,
                        trailing:
                            LanguageCubit.localeNames[locale.languageCode] ??
                                locale.languageCode,
                        onTap: () => _showLanguagePicker(context),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: AppDimens.paddingL),

                // About Section
                Text(
                  context.l10n.about,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.white,
                      ),
                ),
                const SizedBox(height: AppDimens.paddingS),
                _buildMenuCard(
                  context,
                  items: [
                    _MenuItem(
                      icon: Iconsax.document,
                      title: context.l10n.privacyPolicy,
                      onTap: () => context.push(AppRoutes.privacyPolicy),
                    ),
                    _MenuItem(
                      icon: Iconsax.document_text,
                      title: context.l10n.termsOfService,
                      onTap: () => context.push(AppRoutes.termsOfService),
                    ),
                    _MenuItem(
                      icon: Iconsax.star,
                      title: context.l10n.rateApp,
                      onTap: () => _rateApp(),
                    ),
                  ],
                ),

                const SizedBox(height: AppDimens.paddingXL),

                // Logout Button
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      context.read<AuthBloc>().add(AuthLogoutRequested());
                    },
                    icon: const Icon(Iconsax.logout, color: AppColors.redLight),
                    label: Text(
                      context.l10n.logout,
                      style: const TextStyle(color: AppColors.white),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.white),
                    ),
                  ),
                ),
                const SizedBox(height: AppDimens.paddingXL),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _rateApp() async {
    final inAppReview = InAppReview.instance;
    if (await inAppReview.isAvailable()) {
      inAppReview.requestReview();
    } else {
      inAppReview.openStoreListing();
    }
  }

  Future<void> _openContactEmail() async {
    final uri = Uri(
      scheme: 'mailto',
      path: 'Yassine-o@hotmail.fr',
      queryParameters: {'subject': 'Contact Win App'},
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Widget _buildGuestMenuItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppColors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(AppDimens.radiusS),
        ),
        child: Icon(icon, color: AppColors.white, size: 20),
      ),
      title: Text(title, style: const TextStyle(color: AppColors.white)),
      trailing: Icon(
        Iconsax.arrow_right_3,
        size: 18,
        color: AppColors.white.withValues(alpha: 0.6),
      ),
      onTap: onTap,
    );
  }

  void _showLanguagePicker(BuildContext context) {
    final current = context.read<LanguageCubit>().state;
    showModalBottomSheet(
      backgroundColor: AppColors.scaffoldBackground,
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(AppDimens.radiusL)),
      ),
      builder: (_) => SingleChildScrollView(
        padding: EdgeInsets.only(
          top: AppDimens.paddingL,
          bottom: AppDimens.paddingL + MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: AppDimens.paddingM),
              decoration: BoxDecoration(
                color: AppColors.grey400,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Text(
              context.l10n.language,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: AppDimens.paddingM),
            ...LanguageCubit.supportedLocales.map((locale) {
              final isSelected = locale.languageCode == current.languageCode;
              final name = LanguageCubit.localeNames[locale.languageCode] ??
                  locale.languageCode;
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor:
                      isSelected ? AppColors.primaryGreen : AppColors.grey100,
                  radius: 18,
                  child: Text(
                    _localeFlag(locale.languageCode),
                    style: const TextStyle(fontSize: 18),
                  ),
                ),
                title: Text(
                  name,
                  style: TextStyle(
                    fontWeight:
                        isSelected ? FontWeight.w600 : FontWeight.normal,
                    color: isSelected ? AppColors.primaryGreen : null,
                  ),
                ),
                trailing: isSelected
                    ? const Icon(Icons.check_circle,
                        color: AppColors.primaryGreen)
                    : null,
                onTap: () {
                  context.read<LanguageCubit>().changeLanguage(locale);
                  Navigator.pop(context);
                },
              );
            }),
          ],
        ),
      ),
    );
  }

  String _localeFlag(String code) {
    const flags = {
      'fr': '🇫🇷',
      'ar': '🇩🇿',
      'es': '🇪🇸',
      'de': '🇩🇪',
      'nl': '🇳🇱',
      'it': '🇮🇹',
    };
    return flags[code] ?? '🌐';
  }

  Widget _buildMenuCard(BuildContext context,
      {required List<_MenuItem> items}) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppDimens.radiusM),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: items.map((item) {
          final isLast = items.last == item;
          return Column(
            children: [
              _buildMenuItem(
                context,
                icon: item.icon,
                title: item.title,
                trailing: item.trailing,
                onTap: item.onTap,
              ),
              if (!isLast) const Divider(height: 1, indent: 56),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildMenuItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    String? trailing,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppColors.greenSurface,
          borderRadius: BorderRadius.circular(AppDimens.radiusS),
        ),
        child: Icon(icon, color: AppColors.redDark, size: 20),
      ),
      title: Text(title,
          style: const TextStyle(color: AppColors.scaffoldBackground)),
      trailing: trailing != null
          ? Text(
              trailing,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.redDark,
                  ),
            )
          : const Icon(Iconsax.arrow_right_3,
              size: 18, color: AppColors.grey400),
      onTap: onTap,
    );
  }
}

class _MenuItem {
  final IconData icon;
  final String title;
  final String? trailing;
  final VoidCallback onTap;

  _MenuItem({
    required this.icon,
    required this.title,
    this.trailing,
    required this.onTap,
  });
}
