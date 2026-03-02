import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/theme_cubit.dart';
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
              'Bienvenue sur Win !',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: AppDimens.paddingS),
            Text(
              'Connectez-vous pour accéder à toutes les fonctionnalités',
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
                child: const Text(AppStrings.login),
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
                child: const Text(AppStrings.register),
              ),
            ),
            const Spacer(),
            _buildMenuItem(
              context,
              icon: Iconsax.info_circle,
              title: AppStrings.about_,
              onTap: () {},
            ),
            _buildMenuItem(
              context,
              icon: Iconsax.message_question,
              title: AppStrings.contactUs,
              onTap: () {},
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
              color: AppColors.primaryGreen,
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
                    icon: const Icon(Iconsax.edit, size: 18),
                    label: const Text(AppStrings.editProfile),
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
                  'Mon compte',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: AppColors.white,
                      ),
                ),
                const SizedBox(height: AppDimens.paddingS),
                _buildMenuCard(
                  context,
                  items: [
                    _MenuItem(
                      icon: Iconsax.star,
                      title: AppStrings.myReviews,
                      onTap: () => context.push(AppRoutes.myReviews),
                    ),
                    _MenuItem(
                      icon: Iconsax.notification,
                      title: AppStrings.notifications,
                      onTap: () => context.push(AppRoutes.notifications),
                    ),
                  ],
                ),

                const SizedBox(height: AppDimens.paddingL),

                // Admin Section (if admin)
                if (user.isAdmin) ...[
                  Text(
                    'Espace administration',
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
                        title: 'Tableau de bord',
                        onTap: () => context.push(AppRoutes.adminDashboard),
                      ),
                      _MenuItem(
                        icon: Iconsax.people,
                        title: 'Gestion utilisateurs',
                        onTap: () => context.push(AppRoutes.adminUsers),
                      ),
                      _MenuItem(
                        icon: Iconsax.briefcase,
                        title: 'Gestion partenaires',
                        onTap: () => context.push(AppRoutes.adminPartners),
                      ),
                      _MenuItem(
                        icon: Iconsax.message_text,
                        title: 'Gestion des avis',
                        onTap: () => context.push(AppRoutes.adminReviews),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppDimens.paddingL),
                ],

                // Partner Section (if partner)
                if (user.isPartner) ...[
                  Text(
                    'Espace partenaire',
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
                        title: 'Tableau de bord',
                        onTap: () => context.push(AppRoutes.partnerDashboard),
                      ),
                      _MenuItem(
                        icon: Iconsax.building,
                        title: AppStrings.myEstablishments,
                        onTap: () =>
                            context.push(AppRoutes.partnerEstablishments),
                      ),
                      _MenuItem(
                        icon: Iconsax.add_circle,
                        title: 'Ajouter établissement',
                        onTap: () =>
                            context.push(AppRoutes.partnerEstablishmentCreate),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppDimens.paddingL),
                ],

                // Settings Section
                Text(
                  'Paramètres',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: AppColors.white,
                      ),
                ),
                const SizedBox(height: AppDimens.paddingS),
                BlocBuilder<ThemeCubit, ThemeMode>(
                  builder: (ctx, themeMode) => _buildMenuCard(
                    ctx,
                    items: [
                      _MenuItem(
                        icon: Iconsax.language_square,
                        title: AppStrings.language,
                        trailing: 'Français',
                        onTap: () {},
                      ),
                      /*  _MenuItem(
                        icon: themeMode == ThemeMode.dark
                            ? Iconsax.sun_1
                            : Iconsax.moon,
                        title: AppStrings.darkMode,
                        trailing: themeMode == ThemeMode.dark
                            ? 'Activé'
                            : 'Désactivé',
                        onTap: () => ctx.read<ThemeCubit>().toggle(),
                      ),*/
                    ],
                  ),
                ),

                const SizedBox(height: AppDimens.paddingL),

                // About Section
                Text(
                  'À propos',
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
                      title: AppStrings.privacyPolicy,
                      onTap: () {},
                    ),
                    _MenuItem(
                      icon: Iconsax.document_text,
                      title: AppStrings.termsOfService,
                      onTap: () {},
                    ),
                    _MenuItem(
                      icon: Iconsax.star,
                      title: AppStrings.rateApp,
                      onTap: () {},
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
                      AppStrings.logout,
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
      title: Text(title),
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
