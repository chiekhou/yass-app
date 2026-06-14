import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../app_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/network/api_client.dart';

class VerifyEmailPage extends StatefulWidget {
  final String token;

  const VerifyEmailPage({super.key, required this.token});

  @override
  State<VerifyEmailPage> createState() => _VerifyEmailPageState();
}

class _VerifyEmailPageState extends State<VerifyEmailPage> {
  _Status _status = _Status.loading;

  @override
  void initState() {
    super.initState();
    _verify();
  }

  Future<void> _verify() async {
    try {
      await ApiClient.instance.get('/auth/verify-email/${widget.token}');
      if (mounted) setState(() => _status = _Status.success);
      await Future.delayed(const Duration(seconds: 3));
      if (mounted) context.go(AppRoutes.login);
    } catch (_) {
      if (mounted) setState(() => _status = _Status.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppDimens.paddingXL),
            child: switch (_status) {
              _Status.loading => const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: AppColors.primaryGreen),
                    SizedBox(height: AppDimens.paddingL),
                    Text('Vérification en cours...'),
                  ],
                ),
              _Status.success => Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 100,
                      height: 100,
                      decoration: const BoxDecoration(
                        color: AppColors.greenSurface,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Iconsax.tick_circle,
                        size: 52,
                        color: AppColors.primaryGreen,
                      ),
                    ),
                    const SizedBox(height: AppDimens.paddingL),
                    Text(
                      'Email vérifié !',
                      style: Theme.of(context)
                          .textTheme
                          .headlineSmall
                          ?.copyWith(color: AppColors.white),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppDimens.paddingS),
                    Text(
                      'Votre compte est activé. Redirection vers la connexion...',
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(color: AppColors.white),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppDimens.paddingXL),
                    const CircularProgressIndicator(
                        color: AppColors.primaryGreen, strokeWidth: 2),
                  ],
                ),
              _Status.error => Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: AppColors.error.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Iconsax.close_circle,
                        size: 52,
                        color: AppColors.error,
                      ),
                    ),
                    const SizedBox(height: AppDimens.paddingL),
                    Text(
                      'Lien invalide ou expiré',
                      style: Theme.of(context)
                          .textTheme
                          .headlineSmall
                          ?.copyWith(color: AppColors.white),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppDimens.paddingS),
                    Text(
                      'Le lien de vérification a expiré ou est incorrect.',
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(color: AppColors.white),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppDimens.paddingXL),
                    ElevatedButton(
                      onPressed: () => context.go(AppRoutes.login),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryGreen,
                        foregroundColor: AppColors.white,
                        minimumSize:
                            const Size.fromHeight(AppDimens.buttonHeight),
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(AppDimens.radiusM),
                        ),
                      ),
                      child: const Text('Retour à la connexion'),
                    ),
                  ],
                ),
            },
          ),
        ),
      ),
    );
  }
}

enum _Status { loading, success, error }
