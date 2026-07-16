import 'package:flutter/material.dart';
import 'package:win_app/core/l10n/l10n_extensions.dart';
import 'package:iconsax/iconsax.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';

class TermsOfServicePage extends StatelessWidget {
  const TermsOfServicePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.white,
        title: Text(context.l10n.termsOfService),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppDimens.paddingL),
        children: [
          _Header(
            icon: Iconsax.document_text,
            title: context.l10n.termsOfService,
            subtitle: context.l10n.lastUpdatedJuly2026,
          ),
          const SizedBox(height: AppDimens.paddingL),
          _Section(title: context.l10n.termsS1Title, content: context.l10n.termsS1Content),
          _Section(title: context.l10n.termsS2Title, content: context.l10n.termsS2Content),
          _Section(title: context.l10n.termsS3Title, content: context.l10n.termsS3Content),
          _Section(title: context.l10n.termsS4Title, content: context.l10n.termsS4Content),
          _Section(title: context.l10n.termsS5Title, content: context.l10n.termsS5Content),
          _Section(title: context.l10n.termsS6Title, content: context.l10n.termsS6Content),
          _Section(title: context.l10n.termsS7Title, content: context.l10n.termsS7Content),
          _Section(title: context.l10n.termsS8Title, content: context.l10n.termsS8Content),
          _Section(title: context.l10n.termsS9Title, content: context.l10n.termsS9Content),
          _Section(title: context.l10n.termsS10Title, content: context.l10n.termsS10Content),
          _Section(title: context.l10n.termsS11Title, content: context.l10n.termsS11Content),
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
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppDimens.radiusL),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: AppColors.redDark.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppColors.redDark, size: 26),
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
