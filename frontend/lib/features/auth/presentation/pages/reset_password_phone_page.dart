import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';
import 'package:win_app/core/l10n/l10n_extensions.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../app_router.dart';
import '../../../../shared/widgets/loading_overlay.dart';
import '../bloc/auth_bloc.dart';

class ResetPasswordPhonePage extends StatefulWidget {
  final String phone;

  const ResetPasswordPhonePage({super.key, required this.phone});

  @override
  State<ResetPasswordPhonePage> createState() => _ResetPasswordPhonePageState();
}

class _ResetPasswordPhonePageState extends State<ResetPasswordPhonePage> {
  // Étape 1 : saisie OTP / Étape 2 : nouveau mot de passe
  bool _otpVerified = false;
  String _otp = '';

  final List<TextEditingController> _otpControllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());

  final _passwordFormKey = GlobalKey<FormState>();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  Timer? _timer;
  int _secondsLeft = 60;
  bool _canResend = false;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (final c in _otpControllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _startTimer() {
    setState(() {
      _secondsLeft = 60;
      _canResend = false;
    });
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_secondsLeft == 0) {
        t.cancel();
        setState(() => _canResend = true);
      } else {
        setState(() => _secondsLeft--);
      }
    });
  }

  String get _currentOtp => _otpControllers.map((c) => c.text).join();
  bool get _isOtpComplete => _currentOtp.length == 6;

  void _onDigitChanged(String value, int index) {
    if (value.length == 1 && index < 5) {
      _focusNodes[index + 1].requestFocus();
    } else if (value.isEmpty && index > 0) {
      _focusNodes[index - 1].requestFocus();
    }
    setState(() {});
  }

  void _onVerifyOtp() {
    if (!_isOtpComplete) return;
    setState(() {
      _otp = _currentOtp;
      _otpVerified = true;
    });
  }

  void _onResend() {
    if (!_canResend) return;
    for (final c in _otpControllers) {
      c.clear();
    }
    _focusNodes.first.requestFocus();
    context
        .read<AuthBloc>()
        .add(AuthForgotPasswordByPhoneRequested(phone: widget.phone));
    _startTimer();
  }

  void _onSubmitNewPassword() {
    if (_passwordFormKey.currentState!.validate()) {
      context.read<AuthBloc>().add(AuthResetPasswordByPhoneRequested(
            phone: widget.phone,
            otp: _otp,
            newPassword: _newPasswordController.text,
          ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthResetPasswordByPhoneSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(context.l10n.passwordResetSuccess),
              backgroundColor: AppColors.success,
            ),
          );
          context.go(AppRoutes.login);
        } else if (state is AuthError) {
          // Si l'OTP est mauvais, revenir à l'étape 1
          if (_otpVerified) {
            setState(() {
              _otpVerified = false;
              _otp = '';
              for (final c in _otpControllers) {
                c.clear();
              }
            });
          }
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
                  icon: const Icon(Iconsax.arrow_left,
                      color: AppColors.primaryGreen),
                  onPressed: () => context.pop(),
                ),
              ),
              body: SafeArea(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(AppDimens.paddingL),
                  child: _otpVerified ? _buildPasswordStep() : _buildOtpStep(),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ─── Étape 1 : saisie du code OTP ───────────────────────────────────────────

  Widget _buildOtpStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: AppDimens.paddingL),

        Center(
          child: Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              color: AppColors.greenSurface,
              shape: BoxShape.circle,
              border: Border.all(
                  color: AppColors.primaryGreen.withValues(alpha: 0.3),
                  width: 2),
            ),
            child: const Center(
              child: Text('📱', style: TextStyle(fontSize: 40)),
            ),
          ),
        ),
        const SizedBox(height: AppDimens.paddingL),

        Text(
          'Code de vérification',
          textAlign: TextAlign.center,
          style: Theme.of(context)
              .textTheme
              .headlineSmall
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: AppDimens.paddingS),
        Text(
          'Entrez le code reçu par SMS au',
          textAlign: TextAlign.center,
          style: Theme.of(context)
              .textTheme
              .bodyMedium
              ?.copyWith(color: AppColors.white),
        ),
        const SizedBox(height: 4),
        Text(
          widget.phone,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.primaryGreen,
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: AppDimens.paddingXXL),

        // OTP boxes
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(6, _buildOtpBox),
        ),
        const SizedBox(height: AppDimens.paddingXXL),

        ElevatedButton(
          onPressed: _isOtpComplete ? _onVerifyOtp : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryGreen,
            disabledBackgroundColor: const Color.fromARGB(120, 224, 224, 224),
            foregroundColor: AppColors.white,
            minimumSize: const Size.fromHeight(AppDimens.buttonHeight),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppDimens.radiusM),
            ),
          ),
          child: Text(context.l10n.verifyCode,
              style: const TextStyle(
                  fontSize: AppDimens.fontL,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFFE0E0E0))),
        ),
        const SizedBox(height: AppDimens.paddingL),

        Center(
          child: _canResend
              ? TextButton.icon(
                  onPressed: _onResend,
                  icon: const Icon(Iconsax.refresh,
                      size: 18, color: AppColors.primaryGreen),
                  label: Text(context.l10n.resendCode,
                      style: const TextStyle(
                          color: AppColors.primaryGreen,
                          fontWeight: FontWeight.w600)),
                )
              : RichText(
                  text: TextSpan(
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(color: AppColors.white),
                    children: [
                      const TextSpan(text: 'Renvoyer dans '),
                      TextSpan(
                        text: '${_secondsLeft}s',
                        style: const TextStyle(
                            color: AppColors.primaryGreen,
                            fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildOtpBox(int index) {
    return SizedBox(
      width: 48,
      height: 56,
      child: TextFormField(
        controller: _otpControllers[index],
        focusNode: _focusNodes[index],
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        maxLength: 1,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        style: Theme.of(context)
            .textTheme
            .headlineSmall
            ?.copyWith(fontWeight: FontWeight.bold, color: AppColors.black),
        decoration: InputDecoration(
          counterText: '',
          filled: true,
          fillColor: _otpControllers[index].text.isNotEmpty
              ? AppColors.greenSurface
              : AppColors.grey100,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppDimens.radiusM),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppDimens.radiusM),
            borderSide:
                const BorderSide(color: AppColors.primaryGreen, width: 2),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppDimens.radiusM),
            borderSide: BorderSide(
              color: _otpControllers[index].text.isNotEmpty
                  ? AppColors.primaryGreen
                  : AppColors.grey300,
              width: 1.5,
            ),
          ),
        ),
        onChanged: (v) => _onDigitChanged(v, index),
      ),
    );
  }

  // ─── Étape 2 : nouveau mot de passe ─────────────────────────────────────────

  Widget _buildPasswordStep() {
    return Form(
      key: _passwordFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: AppDimens.paddingL),
          Center(
            child: Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: AppColors.greenSurface,
                shape: BoxShape.circle,
                border: Border.all(
                    color: AppColors.primaryGreen.withValues(alpha: 0.3),
                    width: 2),
              ),
              child: const Icon(Iconsax.lock,
                  size: 40, color: AppColors.primaryGreen),
            ),
          ),
          const SizedBox(height: AppDimens.paddingL),
          Text(
            'Nouveau mot de passe',
            textAlign: TextAlign.center,
            style: Theme.of(context)
                .textTheme
                .headlineSmall
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: AppDimens.paddingS),
          Text(
            'Choisissez un mot de passe sécurisé pour votre compte',
            textAlign: TextAlign.center,
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: AppColors.grey600),
          ),
          const SizedBox(height: AppDimens.paddingXL),
          TextFormField(
            controller: _newPasswordController,
            obscureText: _obscureNew,
            decoration: InputDecoration(
              labelText: 'Nouveau mot de passe',
              prefixIcon: const Icon(Iconsax.lock),
              suffixIcon: IconButton(
                icon: Icon(_obscureNew ? Iconsax.eye_slash : Iconsax.eye),
                onPressed: () => setState(() => _obscureNew = !_obscureNew),
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Le mot de passe est requis';
              }
              if (value.length < 8) {
                return 'Au moins 8 caractères';
              }
              if (!RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)').hasMatch(value)) {
                return 'Doit contenir une majuscule, une minuscule et un chiffre';
              }
              return null;
            },
          ),
          const SizedBox(height: AppDimens.paddingM),
          TextFormField(
            controller: _confirmPasswordController,
            obscureText: _obscureConfirm,
            decoration: InputDecoration(
              labelText: 'Confirmer le mot de passe',
              prefixIcon: const Icon(Iconsax.lock_1),
              suffixIcon: IconButton(
                icon: Icon(_obscureConfirm ? Iconsax.eye_slash : Iconsax.eye),
                onPressed: () =>
                    setState(() => _obscureConfirm = !_obscureConfirm),
              ),
            ),
            validator: (value) {
              if (value != _newPasswordController.text) {
                return 'Les mots de passe ne correspondent pas';
              }
              return null;
            },
          ),
          const SizedBox(height: AppDimens.paddingXL),
          ElevatedButton(
            onPressed: _onSubmitNewPassword,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryGreen,
              foregroundColor: AppColors.white,
              minimumSize: const Size.fromHeight(AppDimens.buttonHeight),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppDimens.radiusM),
              ),
            ),
            child: Text(context.l10n.resetPassword,
                style: const TextStyle(
                    fontSize: AppDimens.fontL, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}
