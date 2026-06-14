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
import '../../../home/data/models/category_model.dart';
import '../../../home/data/repositories/category_repository.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _acceptTerms = false;
  bool _usePhone = false;

  final _ageController = TextEditingController();

  List<Wilaya> _wilayas = [];
  String? _selectedWilayaId;
  String? _selectedGender;
  bool _loadingWilayas = false;

  @override
  void initState() {
    super.initState();
    _loadWilayas();
  }

  Future<void> _loadWilayas() async {
    setState(() => _loadingWilayas = true);
    try {
      final wilayas = await WilayaRepository().getAll();
      if (mounted) setState(() => _wilayas = wilayas);
    } catch (_) {
    } finally {
      if (mounted) setState(() => _loadingWilayas = false);
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _ageController.dispose();
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

  void _onRegister() {
    if (_formKey.currentState!.validate()) {
      if (!_acceptTerms) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Veuillez accepter les conditions d\'utilisation'),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }
      final age = int.tryParse(_ageController.text.trim());
      if (_usePhone) {
        context.read<AuthBloc>().add(AuthRegisterWithPhoneRequested(
              firstName: _firstNameController.text.trim(),
              lastName: _lastNameController.text.trim(),
              phone: _phoneController.text.trim(),
              password: _passwordController.text,
              wilayaId: _selectedWilayaId,
              gender: _selectedGender,
              age: age,
            ));
      } else {
        context.read<AuthBloc>().add(AuthRegisterRequested(
              firstName: _firstNameController.text.trim(),
              lastName: _lastNameController.text.trim(),
              email: _emailController.text.trim(),
              password: _passwordController.text,
              phone: null,
              wilayaId: _selectedWilayaId,
              gender: _selectedGender,
              age: age,
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
          context.go(AppRoutes.main);
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
              backgroundColor: AppColors.kleinBlue,
              appBar: AppBar(
                backgroundColor: Colors.transparent,
                elevation: 0,
                leading: IconButton(
                  icon: const Icon(Iconsax.arrow_left),
                  color: AppColors.white,
                  onPressed: () => context.pop(),
                ),
              ),
              body: SafeArea(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(AppDimens.paddingL),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Title
                        Text(
                          context.l10n.register,
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: AppDimens.paddingXS),
                        Text(
                          'Créez votre compte pour commencer',
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(
                                  color: Colors.white.withValues(alpha: 0.7)),
                        ),
                        const SizedBox(height: AppDimens.paddingM),

                        // Toggle email / phone
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.12),
                            borderRadius:
                                BorderRadius.circular(AppDimens.radiusM),
                          ),
                          child: Row(
                            children: [
                              _buildToggleTab(
                                label: context.l10n.byEmail,
                                icon: Iconsax.sms,
                                selected: !_usePhone,
                                onTap: () => setState(() => _usePhone = false),
                              ),
                              _buildToggleTab(
                                label: context.l10n.byPhone,
                                icon: Iconsax.call,
                                selected: _usePhone,
                                onTap: () => setState(() => _usePhone = true),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: AppDimens.paddingL),

                        // Name Row
                        Row(
                          children: [
                            Expanded(
                              child: CustomTextField(
                                controller: _firstNameController,
                                label: context.l10n.firstName,
                                hint: 'Prénom',
                                prefixIcon: Iconsax.user,
                                isDark: true,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Requis';
                                  }
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(width: AppDimens.paddingM),
                            Expanded(
                              child: CustomTextField(
                                controller: _lastNameController,
                                label: context.l10n.lastName,
                                hint: 'Nom',
                                prefixIcon: Iconsax.user,
                                isDark: true,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Requis';
                                  }
                                  return null;
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppDimens.paddingM),

                        // Email or Phone field
                        if (!_usePhone)
                          CustomTextField(
                            controller: _emailController,
                            label: context.l10n.email,
                            hint: 'exemple@email.com',
                            keyboardType: TextInputType.emailAddress,
                            prefixIcon: Iconsax.sms,
                            isDark: true,
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
                            label: context.l10n.phone,
                            hint: '0551234567',
                            keyboardType: TextInputType.phone,
                            prefixIcon: Iconsax.call,
                            isDark: true,
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

                        // Password
                        CustomTextField(
                          controller: _passwordController,
                          label: context.l10n.password,
                          hint: '••••••••',
                          obscureText: _obscurePassword,
                          prefixIcon: Iconsax.lock,
                          isDark: true,
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Iconsax.eye_slash
                                  : Iconsax.eye,
                              color: Colors.white.withValues(alpha: 0.65),
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
                        const SizedBox(height: AppDimens.paddingM),

                        // Confirm Password
                        CustomTextField(
                          controller: _confirmPasswordController,
                          label: context.l10n.confirmPassword,
                          hint: '••••••••',
                          obscureText: _obscureConfirmPassword,
                          prefixIcon: Iconsax.lock,
                          isDark: true,
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscureConfirmPassword
                                  ? Iconsax.eye_slash
                                  : Iconsax.eye,
                              color: Colors.white.withValues(alpha: 0.65),
                            ),
                            onPressed: () {
                              setState(() => _obscureConfirmPassword =
                                  !_obscureConfirmPassword);
                            },
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Confirmation requise';
                            }
                            if (value != _passwordController.text) {
                              return 'Les mots de passe ne correspondent pas';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: AppDimens.paddingM),

                        // Wilaya dropdown (required)
                        DropdownButtonFormField<String>(
                          initialValue: _selectedWilayaId,
                          decoration: InputDecoration(
                            labelText: 'Wilaya *',
                            prefixIcon: const Icon(Iconsax.location,
                                size: AppDimens.iconS),
                            border: OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.circular(AppDimens.radiusM),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.circular(AppDimens.radiusM),
                              borderSide: BorderSide(
                                  color: Colors.white.withValues(alpha: 0.3)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.circular(AppDimens.radiusM),
                              borderSide: const BorderSide(
                                  color: AppColors.accentGreen, width: 2),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: AppDimens.paddingM,
                              vertical: AppDimens.paddingM,
                            ),
                          ),
                          hint: _loadingWilayas
                              ? const Text('Chargement...')
                              : const Text('Sélectionner votre wilaya'),
                          items: _wilayas
                              .map((w) => DropdownMenuItem(
                                    value: w.id,
                                    child: Text('${w.code} - ${w.name}'),
                                  ))
                              .toList(),
                          onChanged: (value) =>
                              setState(() => _selectedWilayaId = value),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Veuillez sélectionner votre wilaya';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: AppDimens.paddingM),

                        // Age field
                        TextFormField(
                          controller: _ageController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: 'Âge',
                            hintText: 'Ex: 25',
                            prefixIcon: const Icon(Iconsax.calendar,
                                size: AppDimens.iconS),
                            border: OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.circular(AppDimens.radiusM),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.circular(AppDimens.radiusM),
                              borderSide: BorderSide(
                                  color: Colors.white.withValues(alpha: 0.3)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.circular(AppDimens.radiusM),
                              borderSide: const BorderSide(
                                  color: AppColors.accentGreen, width: 2),
                            ),
                          ),
                          validator: (value) {
                            if (value != null && value.isNotEmpty) {
                              final age = int.tryParse(value);
                              if (age == null || age < 1 || age > 120) {
                                return 'Âge invalide (1–120)';
                              }
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: AppDimens.paddingM),

                        // Genre selector
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Qui êtes-vous ?',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w500,
                                  ),
                            ),
                            const SizedBox(height: AppDimens.paddingS),
                            Row(
                              children: [
                                _buildGenderOption('male', 'Homme', Icons.male),
                                const SizedBox(width: AppDimens.paddingS),
                                _buildGenderOption(
                                    'female', 'Femme', Icons.female),
                                const SizedBox(width: AppDimens.paddingS),
                                _buildGenderOption(
                                    'young', 'Jeune', Icons.emoji_people),
                                const SizedBox(width: AppDimens.paddingS),
                                _buildGenderOption(
                                    'child', 'Enfant', Icons.child_care),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: AppDimens.paddingM),

                        // Terms Checkbox
                        Row(
                          children: [
                            SizedBox(
                              width: 24,
                              height: 24,
                              child: Checkbox(
                                value: _acceptTerms,
                                onChanged: (value) {
                                  setState(() => _acceptTerms = value ?? false);
                                },
                                activeColor: AppColors.accentGreen,
                              ),
                            ),
                            const SizedBox(width: AppDimens.paddingS),
                            Expanded(
                              child: GestureDetector(
                                onTap: () {
                                  setState(() => _acceptTerms = !_acceptTerms);
                                },
                                child: RichText(
                                  text: TextSpan(
                                    style:
                                        Theme.of(context).textTheme.bodySmall,
                                    children: [
                                      const TextSpan(text: 'J\'accepte les '),
                                      TextSpan(
                                        text: 'conditions d\'utilisation',
                                        style: TextStyle(
                                          color: AppColors.accentGreen,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const TextSpan(text: ' et la '),
                                      TextSpan(
                                        text: 'politique de confidentialité',
                                        style: TextStyle(
                                          color: AppColors.accentGreen,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppDimens.paddingL),

                        // Register Button
                        ElevatedButton(
                          onPressed: _onRegister,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.accentGreen,
                            foregroundColor: AppColors.black,
                            minimumSize:
                                const Size.fromHeight(AppDimens.buttonHeight),
                            shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(AppDimens.radiusM),
                            ),
                          ),
                          child: Text(
                            context.l10n.register,
                            style: TextStyle(
                              fontSize: AppDimens.fontL,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),

                        const SizedBox(height: AppDimens.paddingL),

                        // Login Link
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              context.l10n.hasAccount,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                      fontWeight: FontWeight.w500,
                                      color: AppColors.white),
                            ),
                            TextButton(
                              onPressed: () => context.pop(),
                              style: TextButton.styleFrom(
                                foregroundColor: AppColors.primaryGreen,
                              ),
                              child: Text(context.l10n.login),
                            ),
                          ],
                        ),

                        const SizedBox(height: AppDimens.paddingM),

                        // Partner Registration Link
                        Container(
                          padding: const EdgeInsets.all(AppDimens.paddingM),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.08),
                            borderRadius:
                                BorderRadius.circular(AppDimens.radiusM),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.2),
                            ),
                          ),
                          child: Column(
                            children: [
                              Text(
                                'Vous êtes un professionnel ?',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(
                                        fontWeight: FontWeight.w500,
                                        color: AppColors.white),
                              ),
                              const SizedBox(height: AppDimens.paddingXS),
                              TextButton.icon(
                                onPressed: () =>
                                    context.push(AppRoutes.registerPartner),
                                icon: const Icon(Iconsax.building, size: 18),
                                label: const Text('Devenir partenaire'),
                                style: TextButton.styleFrom(
                                  foregroundColor: AppColors.accentGreen,
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
            ),
          );
        },
      ),
    );
  }

  Widget _buildGenderOption(String value, String label, IconData icon) {
    final selected = _selectedGender == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedGender = selected ? null : value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: AppDimens.paddingS),
          decoration: BoxDecoration(
            color: selected
                ? Colors.white.withValues(alpha: 0.2)
                : Colors.white.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(AppDimens.radiusS),
            border: Border.all(
              color: selected ? AppColors.accentGreen : Colors.transparent,
              width: 1.5,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 20,
                color: selected
                    ? AppColors.accentGreen
                    : Colors.white.withValues(alpha: 0.6),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                  color: selected
                      ? AppColors.white
                      : Colors.white.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
        ),
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
            color: selected
                ? Colors.white.withValues(alpha: 0.2)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(AppDimens.radiusS),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 16,
                color: selected
                    ? AppColors.white
                    : Colors.white.withValues(alpha: 0.55),
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: AppDimens.fontS,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                  color: selected
                      ? AppColors.white
                      : Colors.white.withValues(alpha: 0.55),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
