import 'package:flutter/material.dart';
import 'package:win_app/core/l10n/l10n_extensions.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../app_router.dart';
import '../../../../shared/widgets/custom_text_field.dart';
import '../../../../shared/widgets/loading_overlay.dart';
import '../bloc/auth_bloc.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();

  bool _usePhone = false;
  bool _emailSent = false;

  @override
  void dispose() {
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _onSubmit() {
    if (_formKey.currentState!.validate()) {
      if (_usePhone) {
        context.read<AuthBloc>().add(
              AuthForgotPasswordByPhoneRequested(
                  phone: _phoneController.text.trim()),
            );
      } else {
        context.read<AuthBloc>().add(
              AuthForgotPasswordRequested(email: _emailController.text.trim()),
            );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthForgotPasswordSuccess) {
          setState(() => _emailSent = true);
        } else if (state is AuthForgotPasswordPhoneSent) {
          context.push(
            AppRoutes.resetPasswordPhone,
            extra: state.phone,
          );
        } else if (state is AuthError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: AppColors.error,
            ),
          );
        }
      },
      child: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {
          return LoadingOverlay(
            isLoading: state is AuthLoading,
            child: Scaffold(
              backgroundColor: AppColors.scaffoldBackground,
              appBar: AppBar(
                backgroundColor: Colors.transparent,
                elevation: 0,
                leading: IconButton(
                  icon: const Icon(Iconsax.arrow_left),
                  onPressed: () => context.pop(),
                ),
              ),
              body: SafeArea(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(AppDimens.paddingL),
                  child:
                      _emailSent ? _buildSuccessContent() : _buildFormContent(),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFormContent() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: AppDimens.paddingL),

          // Icon
          Center(
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.greenSurface,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Iconsax.lock_1,
                size: 40,
                color: AppColors.primaryGreen,
              ),
            ),
          ),
          const SizedBox(height: AppDimens.paddingL),

          Text(
            context.l10n.forgotPassword,
            style: Theme.of(context).textTheme.headlineSmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppDimens.paddingS),
          Text(
            _usePhone
                ? 'Entrez votre numéro de téléphone pour recevoir un code par SMS'
                : 'Entrez votre adresse email pour recevoir un lien de réinitialisation',
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: AppColors.white),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppDimens.paddingL),

          // Toggle email / téléphone
          Container(
            decoration: BoxDecoration(
              color: AppColors.grey100,
              borderRadius: BorderRadius.circular(AppDimens.radiusM),
            ),
            padding: const EdgeInsets.all(4),
            child: Row(
              children: [
                Expanded(
                  child: _ToggleButton(
                    label: 'Email',
                    icon: Iconsax.sms,
                    selected: !_usePhone,
                    onTap: () => setState(() => _usePhone = false),
                  ),
                ),
                Expanded(
                  child: _ToggleButton(
                    label: 'Téléphone',
                    icon: Iconsax.mobile,
                    selected: _usePhone,
                    onTap: () => setState(() => _usePhone = true),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppDimens.paddingL),

          if (!_usePhone)
            CustomTextField(
              textColor: AppColors.scaffoldBackground,
              controller: _emailController,
              label: context.l10n.email,
              hint: 'exemple@email.com',
              keyboardType: TextInputType.emailAddress,
              prefixIcon: Iconsax.sms,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'L\'email est requis';
                }
                if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                    .hasMatch(value)) {
                  return 'Email invalide';
                }
                return null;
              },
            )
          else
            CustomTextField(
              textColor: AppColors.scaffoldBackground,
              controller: _phoneController,
              label: 'Numéro de téléphone',
              hint: '+33612345678',
              keyboardType: TextInputType.phone,
              prefixIcon: Iconsax.mobile,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Le numéro est requis';
                }
                return null;
              },
            ),

          const SizedBox(height: AppDimens.paddingL),

          CustomButton(
            text: _usePhone ? 'Envoyer le code SMS' : 'Envoyer le lien',
            onPressed: _onSubmit,
          ),
          const SizedBox(height: AppDimens.paddingS),
          TextButton(
            onPressed: () => context.pop(),
            child: const Text(
              '← Retour à la connexion',
              style: TextStyle(color: AppColors.primaryGreen),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: AppDimens.paddingXXL),
        Center(
          child: Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: AppColors.successLight,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Iconsax.tick_circle,
              size: 50,
              color: AppColors.success,
            ),
          ),
        ),
        const SizedBox(height: AppDimens.paddingL),
        Text(
          'Email envoyé !',
          style: Theme.of(context).textTheme.headlineSmall,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppDimens.paddingS),
        Text(
          'Vérifiez votre boîte de réception à ${_emailController.text}',
          style: Theme.of(context)
              .textTheme
              .bodyMedium
              ?.copyWith(color: AppColors.grey600),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppDimens.paddingXL),
        CustomButton(
          text: 'Retour à la connexion',
          onPressed: () => context.pop(),
        ),
        const SizedBox(height: AppDimens.paddingM),
        TextButton(
          onPressed: () => setState(() => _emailSent = false),
          child: const Text('Renvoyer l\'email'),
        ),
      ],
    );
  }
}

class _ToggleButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _ToggleButton({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: selected ? AppColors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(AppDimens.radiusS),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  )
                ]
              : [],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 16,
              color: selected ? AppColors.primaryGreen : AppColors.grey500,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                color: selected ? AppColors.primaryGreen : AppColors.grey500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
