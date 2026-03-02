import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../app_router.dart';
import '../../../../shared/widgets/custom_text_field.dart';
import '../../../../shared/widgets/loading_overlay.dart';
import '../bloc/auth_bloc.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _usePhone = false;

  @override
  void dispose() {
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  String _maskEmail(String email) {
    if (email.isEmpty) return email;
    final parts = email.split('@');
    if (parts.length != 2) return email;
    final name = parts[0];
    final domain = parts[1];
    final masked = name.length <= 2
        ? '${name[0]}***'
        : '${name.substring(0, 2)}${'*' * (name.length - 2)}';
    return '$masked@$domain';
  }

  String _maskPhone(String phone) {
    if (phone.length < 6) return phone;
    return '${phone.substring(0, 4)}****${phone.substring(phone.length - 2)}';
  }

  void _onLogin() {
    if (_formKey.currentState!.validate()) {
      if (_usePhone) {
        context.read<AuthBloc>().add(AuthLoginWithPhoneRequested(
              phone: _phoneController.text.trim(),
              password: _passwordController.text,
            ));
      } else {
        context.read<AuthBloc>().add(AuthLoginRequested(
              email: _emailController.text.trim(),
              password: _passwordController.text,
            ));
      }
    }
  }

  void _goToOtp(AuthPendingVerification state) {
    FocusScope.of(context).unfocus();
    final destination = state.verificationType == 'email'
        ? _maskEmail(state.user.email)
        : _maskPhone(state.user.phone ?? '');
    context.push(
      AppRoutes.verifyOtp,
      extra: {
        'verificationType': state.verificationType,
        'destination': destination,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthAuthenticated) {
          final user = state.user;
          if (user.isAdmin) {
            context.go(AppRoutes.adminDashboard);
          } else if (user.isPartner) {
            context.go(AppRoutes.partnerDashboard);
          } else {
            context.go(AppRoutes.main);
          }
        } else if (state is AuthPendingVerification) {
          _goToOtp(state);
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
              body: SafeArea(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(AppDimens.paddingL),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: AppDimens.paddingXXL),

                        // Logo
                        Center(
                          child: Column(
                            children: [
                              Container(
                                width: 80,
                                height: 80,
                                decoration: BoxDecoration(
                                  color: AppColors.primaryGreen,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Center(
                                  child: Text(
                                    'W',
                                    style: TextStyle(
                                      fontSize: 40,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.white,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: AppDimens.paddingM),
                              Text(
                                AppStrings.appNameAr,
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineMedium
                                    ?.copyWith(
                                      color: AppColors.primaryRed,
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                              const SizedBox(height: AppDimens.paddingXS),
                              Text(
                                AppStrings.appTagline,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(color: AppColors.primaryGreen),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: AppDimens.paddingXXL),

                        // Title
                        Text(
                          AppStrings.login,
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: AppDimens.paddingM),

                        // Toggle email / phone
                        Container(
                          decoration: BoxDecoration(
                            color: AppColors.grey100,
                            borderRadius:
                                BorderRadius.circular(AppDimens.radiusM),
                          ),
                          child: Row(
                            children: [
                              _buildToggleTab(
                                label: 'Par email',
                                icon: Iconsax.sms,
                                selected: !_usePhone,
                                onTap: () => setState(() => _usePhone = false),
                              ),
                              _buildToggleTab(
                                label: 'Par téléphone',
                                icon: Iconsax.call,
                                selected: _usePhone,
                                onTap: () => setState(() => _usePhone = true),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: AppDimens.paddingL),

                        // Email or Phone field
                        if (!_usePhone)
                          CustomTextField(
                            controller: _emailController,
                            label: AppStrings.email,
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
                            controller: _phoneController,
                            label: AppStrings.phone,
                            hint: '0551234567',
                            keyboardType: TextInputType.phone,
                            prefixIcon: Iconsax.call,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Le numéro est requis';
                              }
                              if (!RegExp(r'^\+?[0-9]\d{6,14}$')
                                  .hasMatch(value)) {
                                return 'Numéro invalide (ex: 0551234567 ou +33612345678)';
                              }
                              return null;
                            },
                          ),
                        const SizedBox(height: AppDimens.paddingM),

                        // Password Field
                        CustomTextField(
                          controller: _passwordController,
                          label: AppStrings.password,
                          hint: '••••••••',
                          obscureText: _obscurePassword,
                          prefixIcon: Iconsax.lock,
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Iconsax.eye_slash
                                  : Iconsax.eye,
                              color: AppColors.grey500,
                            ),
                            onPressed: () {
                              setState(
                                  () => _obscurePassword = !_obscurePassword);
                            },
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Le mot de passe est requis';
                            }
                            if (value.length < 6) {
                              return 'Minimum 6 caractères';
                            }
                            return null;
                          },
                        ),

                        // Forgot Password
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () =>
                                context.push(AppRoutes.forgotPassword),
                            child: const Text(AppStrings.forgotPassword),
                          ),
                        ),

                        const SizedBox(height: AppDimens.paddingM),

                        // Login Button
                        ElevatedButton(
                          onPressed: _onLogin,
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
                          child: const Text(
                            AppStrings.login,
                            style: TextStyle(
                              fontSize: AppDimens.fontL,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),

                        const SizedBox(height: AppDimens.paddingL),

                        // Divider
                        Row(
                          children: [
                            const Expanded(child: Divider()),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: AppDimens.paddingM),
                              child: Text(
                                'ou',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(color: AppColors.primaryGreen),
                              ),
                            ),
                            const Expanded(child: Divider()),
                          ],
                        ),

                        const SizedBox(height: AppDimens.paddingL),

                        // Register Link
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              AppStrings.noAccount,
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                            TextButton(
                              onPressed: () => context.push(AppRoutes.register),
                              child: const Text(AppStrings.register),
                            ),
                          ],
                        ),

                        // Skip for now
                        TextButton(
                          onPressed: () => context.go(AppRoutes.main),
                          child: Text(
                            'Continuer sans compte',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(color: AppColors.primaryRed),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildToggleTab({
    required String label,
    required IconData icon,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.all(4),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? AppColors.primaryGreen : Colors.transparent,
            borderRadius: BorderRadius.circular(AppDimens.radiusS),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 16,
                color: selected ? AppColors.white : AppColors.grey600,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: AppDimens.fontS,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                  color: selected ? AppColors.white : AppColors.grey600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
