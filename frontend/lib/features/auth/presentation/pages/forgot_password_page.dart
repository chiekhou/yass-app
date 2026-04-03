import 'package:flutter/material.dart';
import 'package:win_app/core/l10n/l10n_extensions.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
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
  bool _emailSent = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  void _onSubmit() {
    if (_formKey.currentState!.validate()) {
      context.read<AuthBloc>().add(
            AuthForgotPasswordRequested(email: _emailController.text.trim()),
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthForgotPasswordSuccess) {
          setState(() {
            _emailSent = true;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: AppColors.success,
            ),
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
              backgroundColor: AppColors.white,
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

          // Title
          Text(
            context.l10n.forgotPassword,
            style: Theme.of(context).textTheme.headlineSmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppDimens.paddingS),
          Text(
            'Entrez votre adresse email pour recevoir un lien de réinitialisation',
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: AppColors.grey600),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppDimens.paddingXL),

          // Email Field
          CustomTextField(
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
          ),
          const SizedBox(height: AppDimens.paddingL),

          // Submit Button
          CustomButton(
            text: 'Envoyer le lien',
            onPressed: _onSubmit,
          ),
          const SizedBox(height: AppDimens.paddingS),
          TextButton(
            onPressed: () => context.pop(),
            child: const Text(
              '← Retour à la connexion',
              style: TextStyle(color: AppColors.grey600),
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

        // Success Icon
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

        // Title
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

        // Back to Login Button
        CustomButton(
          text: 'Retour à la connexion',
          onPressed: () => context.pop(),
        ),
        const SizedBox(height: AppDimens.paddingM),

        // Resend
        TextButton(
          onPressed: () {
            setState(() {
              _emailSent = false;
            });
          },
          child: const Text('Renvoyer l\'email'),
        ),
      ],
    );
  }
}
