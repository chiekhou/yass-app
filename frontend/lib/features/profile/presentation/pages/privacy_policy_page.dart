import 'package:flutter/material.dart';
import 'package:win_app/core/l10n/l10n_extensions.dart';
import 'package:iconsax/iconsax.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';

class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.white,
        title: Text(context.l10n.privacyPolicy),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppDimens.paddingL),
        children: [
          _Header(
            icon: Iconsax.shield_tick,
            title: context.l10n.privacyHeaderTitle,
            subtitle: context.l10n.lastUpdatedJuly2026,
          ),
          const SizedBox(height: AppDimens.paddingL),
          _Section(title: context.l10n.privacyS1Title, content: context.l10n.privacyS1Content),
          _Section(title: context.l10n.privacyS2Title, content: context.l10n.privacyS2Content),
          _Section(title: context.l10n.privacyS3Title, content: context.l10n.privacyS3Content),
          _Section(title: context.l10n.privacyS4Title, content: context.l10n.privacyS4Content),
          _Section(title: context.l10n.privacyS5Title, content: context.l10n.privacyS5Content),
          _Section(title: context.l10n.privacyS6Title, content: context.l10n.privacyS6Content),
          _Section(title: context.l10n.privacyS7Title, content: context.l10n.privacyS7Content),
          _Section(title: context.l10n.privacyS8Title, content: context.l10n.privacyS8Content),
          _Section(title: context.l10n.privacyS9Title, content: context.l10n.privacyS9Content),
          const SizedBox(height: AppDimens.paddingXL),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _Header({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppDimens.paddingL),
      decoration: BoxDecoration(
        color: AppColors.greenSurface,
        borderRadius: BorderRadius.circular(AppDimens.radiusL),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: AppColors.primaryGreen.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppColors.primaryGreen, size: 26),
          ),
          const SizedBox(width: AppDimens.paddingM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.grey900,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.grey600,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final String content;

  const _Section({required this.title, required this.content});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppDimens.paddingL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.white,
                ),
          ),
          const SizedBox(height: AppDimens.paddingS),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppDimens.paddingM),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(AppDimens.radiusM),
            ),
            child: Text(
              content,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.grey800,
                    height: 1.6,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
