import 'package:flutter/material.dart';
import 'package:win_app/core/l10n/l10n_extensions.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../app_router.dart';

class AboutPage extends StatefulWidget {
  const AboutPage({super.key});

  @override
  State<AboutPage> createState() => _AboutPageState();
}

class _AboutPageState extends State<AboutPage> {
  String _version = '';

  @override
  void initState() {
    super.initState();
    PackageInfo.fromPlatform().then((info) {
      if (mounted) setState(() => _version = info.version);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.white,
        title: Text(context.l10n.about),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppDimens.paddingL),
        children: [
          // Logo + nom
          const SizedBox(height: AppDimens.paddingL),
          Center(
            child: Column(
              children: [
                Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Iconsax.building,
                    size: 44,
                    color: AppColors.primaryGreen,
                  ),
                ),
                const SizedBox(height: AppDimens.paddingM),
                Text(
                  AppStrings.appName,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: AppColors.white,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                Text(
                  AppStrings.appNameAr,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppColors.white.withValues(alpha: 0.7),
                      ),
                ),
                if (_version.isNotEmpty) ...[
                  const SizedBox(height: AppDimens.paddingS),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppDimens.paddingM,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      context.l10n.versionNumber(_version),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.white,
                          ),
                    ),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: AppDimens.paddingXL),

          // Description
          Container(
            padding: const EdgeInsets.all(AppDimens.paddingM),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(AppDimens.radiusM),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.l10n.ourMission,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.grey900,
                      ),
                ),
                const SizedBox(height: AppDimens.paddingS),
                Text(
                  context.l10n.appDescription,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.grey700,
                        height: 1.6,
                      ),
                ),
              ],
            ),
          ),

          const SizedBox(height: AppDimens.paddingL),

          // Liens légaux
          _buildSectionTitle(context, context.l10n.legalInfo),
          const SizedBox(height: AppDimens.paddingS),
          _buildCard([
            _buildLinkItem(
              context,
              icon: Iconsax.shield_tick,
              title: context.l10n.privacyPolicy,
              onTap: () => context.push(AppRoutes.privacyPolicy),
            ),
            const Divider(height: 1, indent: 56),
            _buildLinkItem(
              context,
              icon: Iconsax.document_text,
              title: context.l10n.termsOfService,
              onTap: () => context.push(AppRoutes.termsOfService),
            ),
          ]),

          const SizedBox(height: AppDimens.paddingL),

          // Contact
          _buildSectionTitle(context, context.l10n.contactUs),
          const SizedBox(height: AppDimens.paddingS),
          _buildCard([
            _buildLinkItem(
              context,
              icon: Iconsax.sms,
              title: context.l10n.sendEmail,
              subtitle: 'Yassine-o@hotmail.fr',
              onTap: _openEmail,
            ),
          ]),

          const SizedBox(height: AppDimens.paddingXL),

          // Copyright
          Center(
            child: Text(
              context.l10n.copyrightNotice(DateTime.now().year),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.white.withValues(alpha: 0.5),
                  ),
            ),
          ),
          const SizedBox(height: AppDimens.paddingXL),
        ],
      ),
    );
  }

  Future<void> _openEmail() async {
    final uri = Uri(
      scheme: 'mailto',
      path: 'Yassine-o@hotmail.fr',
      queryParameters: {
        'subject': 'Contact Win App',
      },
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleSmall?.copyWith(
            color: AppColors.white,
            fontWeight: FontWeight.w600,
          ),
    );
  }

  Widget _buildCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppDimens.radiusM),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildLinkItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    String? subtitle,
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
      title: Text(
        title,
        style: const TextStyle(color: AppColors.scaffoldBackground),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.grey500,
                  ),
            )
          : null,
      trailing: const Icon(Iconsax.arrow_right_3,
          size: 18, color: AppColors.grey400),
      onTap: onTap,
    );
  }
}
