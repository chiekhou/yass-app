import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../app_router.dart';
import '../../../../shared/widgets/loading_overlay.dart';
import '../bloc/auth_bloc.dart';

class VerifyOtpPage extends StatefulWidget {
  final String verificationType; // 'email' | 'phone'
  final String destination; // masked email or phone

  const VerifyOtpPage({
    super.key,
    required this.verificationType,
    required this.destination,
  });

  @override
  State<VerifyOtpPage> createState() => _VerifyOtpPageState();
}

class _VerifyOtpPageState extends State<VerifyOtpPage> {
  final List<TextEditingController> _controllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());

  Timer? _timer;
  int _secondsLeft = 60;
  bool _canResend = false;
  bool _showSuccess = false;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
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

  String get _otp => _controllers.map((c) => c.text).join();

  bool get _isComplete => _otp.length == 6;

  void _onVerify() {
    if (!_isComplete) return;
    if (widget.verificationType == 'email') {
      context.read<AuthBloc>().add(AuthVerifyEmailOtpRequested(otp: _otp));
    } else {
      context.read<AuthBloc>().add(AuthVerifyPhoneOtpRequested(otp: _otp));
    }
  }

  void _onResend() {
    if (!_canResend) return;
    // Clear boxes
    for (final c in _controllers) {
      c.clear();
    }
    _focusNodes.first.requestFocus();

    if (widget.verificationType == 'email') {
      context.read<AuthBloc>().add(const AuthSendEmailOtpRequested());
    } else {
      context.read<AuthBloc>().add(const AuthSendPhoneOtpRequested());
    }
    _startTimer();
  }

  void _onDigitChanged(String value, int index) {
    if (value.length == 1 && index < 5) {
      _focusNodes[index + 1].requestFocus();
    } else if (value.isEmpty && index > 0) {
      _focusNodes[index - 1].requestFocus();
    }
    setState(() {});
  }

  String get _icon => widget.verificationType == 'email' ? '📧' : '📱';

  String get _title => widget.verificationType == 'email'
      ? 'Vérification email'
      : 'Vérification téléphone';

  String get _subtitle => widget.verificationType == 'email'
      ? 'Entrez le code envoyé à votre adresse'
      : 'Entrez le code reçu par SMS au';

  void _showSuccessAndRedirect() {
    setState(() => _showSuccess = true);
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        context.read<AuthBloc>().add(AuthLogoutRequested());
        context.go(AppRoutes.login);
      }
    });
  }

  Widget _buildSuccessView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppDimens.paddingXL),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 600),
              curve: Curves.elasticOut,
              builder: (context, value, child) => Transform.scale(
                scale: value,
                child: child,
              ),
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: AppColors.greenSurface,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.primaryGreen.withValues(alpha: 0.3),
                    width: 3,
                  ),
                ),
                child: const Icon(
                  Iconsax.tick_circle,
                  color: AppColors.primaryGreen,
                  size: 52,
                ),
              ),
            ),
            const SizedBox(height: AppDimens.paddingXL),
            Text(
              'Compte validé ! 🎉',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.white,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppDimens.paddingM),
            Text(
              'Super ! Votre compte a été vérifié avec succès.\nVous allez être redirigé vers la page de connexion.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.white,
                    height: 1.5,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppDimens.paddingXXL),
            const CircularProgressIndicator(
              color: AppColors.primaryGreen,
              strokeWidth: 3,
            ),
            const SizedBox(height: AppDimens.paddingM),
            Text(
              'Redirection en cours...',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.white,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthVerificationSuccess) {
          _showSuccessAndRedirect();
        } else if (state is AuthAuthenticated) {
          final user = state.user;
          if (user.isAdmin) {
            context.go(AppRoutes.adminDashboard);
          } else if (user.isPartner) {
            context.go(AppRoutes.partnerDashboard);
          }
        } else if (state is AuthOtpSent) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Code renvoyé avec succès'),
              backgroundColor: AppColors.primaryGreen,
            ),
          );
        } else if (state is AuthError) {
          // Clear boxes on error
          for (final c in _controllers) {
            c.clear();
          }
          _focusNodes.first.requestFocus();
          setState(() {});
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
              body: _showSuccess
                  ? _buildSuccessView()
                  : SafeArea(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppDimens.paddingL,
                          vertical: AppDimens.paddingM,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const SizedBox(height: AppDimens.paddingL),

                            // Icon circle
                            Center(
                              child: Container(
                                width: 88,
                                height: 88,
                                decoration: BoxDecoration(
                                  color: AppColors.greenSurface,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: AppColors.primaryGreen
                                        .withValues(alpha: 0.3),
                                    width: 2,
                                  ),
                                ),
                                child: Center(
                                  child: Text(
                                    _icon,
                                    style: const TextStyle(fontSize: 40),
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(height: AppDimens.paddingL),

                            // Title
                            Text(
                              _title,
                              textAlign: TextAlign.center,
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineSmall
                                  ?.copyWith(
                                    color: AppColors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            const SizedBox(height: AppDimens.paddingS),

                            // Subtitle + destination
                            Text(
                              _subtitle,
                              textAlign: TextAlign.center,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(color: AppColors.white),
                            ),
                            const SizedBox(height: AppDimens.paddingXS),
                            Text(
                              widget.destination,
                              textAlign: TextAlign.center,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    color: AppColors.primaryGreen,
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),

                            const SizedBox(height: AppDimens.paddingXXL),

                            // OTP boxes
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children:
                                  List.generate(6, (i) => _buildOtpBox(i)),
                            ),

                            const SizedBox(height: AppDimens.paddingXXL),

                            // Verify button
                            ElevatedButton(
                              onPressed: _isComplete ? _onVerify : null,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF70E010),
                                disabledBackgroundColor:
                                    const Color.fromARGB(83, 255, 255, 255),
                                foregroundColor: const Color(0xFFFFFFFF),
                                minimumSize: const Size.fromHeight(
                                    AppDimens.buttonHeight),
                                shape: RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius.circular(AppDimens.radiusM),
                                ),
                              ),
                              child: const Text(
                                'Vérifier le code',
                                style: TextStyle(
                                    fontSize: AppDimens.fontL,
                                    fontWeight: FontWeight.w600,
                                    color: Color.fromARGB(255, 255, 255, 255)),
                              ),
                            ),

                            const SizedBox(height: AppDimens.paddingL),

                            // Resend section
                            Center(
                              child: _canResend
                                  ? TextButton.icon(
                                      onPressed: _onResend,
                                      icon: const Icon(
                                        Iconsax.refresh,
                                        size: 18,
                                        color: AppColors.primaryGreen,
                                      ),
                                      label: const Text(
                                        'Renvoyer le code',
                                        style: TextStyle(
                                          color: AppColors.primaryGreen,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    )
                                  : RichText(
                                      text: TextSpan(
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium
                                            ?.copyWith(color: AppColors.white),
                                        children: [
                                          const TextSpan(
                                              text: 'Renvoyer dans '),
                                          TextSpan(
                                            text: '${_secondsLeft}s',
                                            style: const TextStyle(
                                              color: AppColors.primaryGreen,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                            ),

                            const SizedBox(height: AppDimens.paddingXL),

                            // Info note
                            Container(
                              padding: const EdgeInsets.all(AppDimens.paddingM),
                              decoration: BoxDecoration(
                                color: AppColors.greenSurface,
                                borderRadius:
                                    BorderRadius.circular(AppDimens.radiusM),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Iconsax.info_circle,
                                    size: 18,
                                    color: AppColors.primaryGreen,
                                  ),
                                  const SizedBox(width: AppDimens.paddingS),
                                  Expanded(
                                    child: Text(
                                      'Le code expire dans 10 minutes. Ne le partagez avec personne.',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(color: AppColors.grey700),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildOtpBox(int index) {
    return SizedBox(
      width: 48,
      height: 56,
      child: TextFormField(
        controller: _controllers[index],
        focusNode: _focusNodes[index],
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        maxLength: 1,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.black,
            ),
        decoration: InputDecoration(
          counterText: '',
          filled: true,
          fillColor: _controllers[index].text.isNotEmpty
              ? AppColors.greenSurface
              : AppColors.grey100,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppDimens.radiusM),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppDimens.radiusM),
            borderSide: const BorderSide(
              color: AppColors.primaryGreen,
              width: 2,
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppDimens.radiusM),
            borderSide: BorderSide(
              color: _controllers[index].text.isNotEmpty
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
}
