import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../app_router.dart';
import '../../../../shared/widgets/custom_text_field.dart';
import '../../../../shared/widgets/custom_button.dart' hide CustomButton;
import '../../../../shared/widgets/loading_overlay.dart';
import '../../../home/data/models/category_model.dart';
import '../../../home/data/repositories/category_repository.dart';
import '../bloc/auth_bloc.dart';

class RegisterPartnerPage extends StatefulWidget {
  const RegisterPartnerPage({super.key});

  @override
  State<RegisterPartnerPage> createState() => _RegisterPartnerPageState();
}

class _RegisterPartnerPageState extends State<RegisterPartnerPage> {
  final _formKey = GlobalKey<FormState>();
  final _wilayaRepository = WilayaRepository();
  int _currentStep = 0;

  // Step 1: Personal Info
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  // Step 2: Company Info
  final _companyNameController = TextEditingController();
  final _registrationNumberController = TextEditingController();
  final _taxIdController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _acceptTerms = false;

  List<Wilaya> _wilayas = [];
  String? _selectedWilayaId;
  bool _isLoadingWilayas = true;

  @override
  void initState() {
    super.initState();
    _loadWilayas();
  }

  Future<void> _loadWilayas() async {
    try {
      _wilayas = await _wilayaRepository.getAll();
    } catch (e) {
      // Ignore error
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingWilayas = false;
        });
      }
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
    _companyNameController.dispose();
    _registrationNumberController.dispose();
    _taxIdController.dispose();
    super.dispose();
  }

  bool _validateStep1() {
    if (_firstNameController.text.trim().isEmpty) {
      _showError('Le prénom est requis');
      return false;
    }
    if (_lastNameController.text.trim().isEmpty) {
      _showError('Le nom est requis');
      return false;
    }
    if (_emailController.text.trim().isEmpty ||
        !RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
            .hasMatch(_emailController.text.trim())) {
      _showError('Veuillez entrer un email valide');
      return false;
    }
    if (_phoneController.text.trim().isEmpty) {
      _showError('Le numéro de téléphone est requis pour les partenaires');
      return false;
    }
    if (!RegExp(r'^(\+?213|0)(5|6|7)\d{8}$')
        .hasMatch(_phoneController.text.trim())) {
      _showError('Veuillez entrer un numéro de téléphone algérien valide');
      return false;
    }
    if (_selectedWilayaId == null) {
      _showError('Veuillez sélectionner votre wilaya');
      return false;
    }
    if (_passwordController.text.length < 8) {
      _showError('Le mot de passe doit contenir au moins 8 caractères');
      return false;
    }
    if (!RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)')
        .hasMatch(_passwordController.text)) {
      _showError(
          'Le mot de passe doit contenir une majuscule, une minuscule et un chiffre');
      return false;
    }
    if (_passwordController.text != _confirmPasswordController.text) {
      _showError('Les mots de passe ne correspondent pas');
      return false;
    }
    return true;
  }

  bool _validateStep2() {
    if (_companyNameController.text.trim().isEmpty) {
      _showError('Le nom de l\'entreprise est requis');
      return false;
    }
    if (_companyNameController.text.trim().length < 2) {
      _showError('Le nom de l\'entreprise doit contenir au moins 2 caractères');
      return false;
    }
    if (!_acceptTerms) {
      _showError('Veuillez accepter les conditions d\'utilisation');
      return false;
    }
    return true;
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
      ),
    );
  }

  void _onContinue() {
    if (_currentStep == 0) {
      if (_validateStep1()) {
        setState(() {
          _currentStep = 1;
        });
      }
    } else {
      if (_validateStep2()) {
        _onRegister();
      }
    }
  }

  void _onBack() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
      });
    }
  }

  void _onRegister() {
    context.read<AuthBloc>().add(AuthRegisterPartnerRequested(
          firstName: _firstNameController.text.trim(),
          lastName: _lastNameController.text.trim(),
          email: _emailController.text.trim(),
          password: _passwordController.text,
          phone: _phoneController.text.trim(),
          companyName: _companyNameController.text.trim(),
          registrationNumber:
              _registrationNumberController.text.trim().isNotEmpty
                  ? _registrationNumberController.text.trim()
                  : null,
          taxId: _taxIdController.text.trim().isNotEmpty
              ? _taxIdController.text.trim()
              : null,
          wilayaId: _selectedWilayaId,
        ));
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthAuthenticated) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                  'Inscription réussie ! Votre compte est en attente de validation.'),
              backgroundColor: AppColors.success,
            ),
          );
          context.go(AppRoutes.main);
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
                foregroundColor: AppColors.primaryGreen,
                leading: IconButton(
                  icon: const Icon(Iconsax.arrow_left),
                  color: AppColors.greenDark,
                  onPressed: _currentStep > 0 ? _onBack : () => context.pop(),
                ),
                title: const Text('Devenir partenaire'),
              ),
              body: SafeArea(
                child: Column(
                  children: [
                    // Stepper indicator
                    _buildStepIndicator(),

                    // Form content
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(AppDimens.paddingL),
                        child: Form(
                          key: _formKey,
                          child:
                              _currentStep == 0 ? _buildStep1() : _buildStep2(),
                        ),
                      ),
                    ),

                    // Bottom buttons
                    _buildBottomButtons(),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStepIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimens.paddingL,
        vertical: AppDimens.paddingM,
      ),
      child: Row(
        children: [
          _buildStepCircle(0, 'Informations'),
          Expanded(
            child: Container(
              height: 2,
              color: _currentStep >= 1
                  ? AppColors.primaryGreen
                  : AppColors.grey300,
            ),
          ),
          _buildStepCircle(1, 'Entreprise'),
        ],
      ),
    );
  }

  Widget _buildStepCircle(int step, String label) {
    final isActive = _currentStep >= step;
    final isCurrent = _currentStep == step;

    return Column(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isActive ? AppColors.primaryGreen : AppColors.grey200,
            border: isCurrent
                ? Border.all(color: AppColors.primaryGreen, width: 2)
                : null,
          ),
          child: Center(
            child: isActive && !isCurrent
                ? const Icon(Icons.check, color: AppColors.white, size: 20)
                : Text(
                    '${step + 1}',
                    style: TextStyle(
                      color: isActive ? AppColors.white : AppColors.grey500,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: isActive ? AppColors.primaryGreen : AppColors.grey500,
            fontWeight: isCurrent ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  Widget _buildStep1() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Informations personnelles',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: AppDimens.paddingXS),
        Text(
          'Ces informations seront utilisées pour votre compte',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.grey600,
              ),
        ),
        const SizedBox(height: AppDimens.paddingL),

        // Name Row
        Row(
          children: [
            Expanded(
              child: CustomTextField(
                controller: _firstNameController,
                label: 'Prénom *',
                hint: 'Prénom',
                prefixIcon: Iconsax.user,
              ),
            ),
            const SizedBox(width: AppDimens.paddingM),
            Expanded(
              child: CustomTextField(
                controller: _lastNameController,
                label: 'Nom *',
                hint: 'Nom',
                prefixIcon: Iconsax.user,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppDimens.paddingM),

        // Email
        CustomTextField(
          controller: _emailController,
          label: 'Email *',
          hint: 'exemple@email.com',
          keyboardType: TextInputType.emailAddress,
          prefixIcon: Iconsax.sms,
        ),
        const SizedBox(height: AppDimens.paddingM),

        // Phone
        CustomTextField(
          controller: _phoneController,
          label: 'Téléphone *',
          hint: '0551234567',
          keyboardType: TextInputType.phone,
          prefixIcon: Iconsax.call,
        ),
        const SizedBox(height: AppDimens.paddingM),

        // Wilaya Dropdown
        _isLoadingWilayas
            ? const Center(
                child: Padding(
                  padding: EdgeInsets.all(AppDimens.paddingM),
                  child: CircularProgressIndicator(
                    color: AppColors.primaryGreen,
                    strokeWidth: 2,
                  ),
                ),
              )
            : DropdownButtonFormField<String>(
                initialValue: _selectedWilayaId,
                decoration: InputDecoration(
                  labelText: 'Wilaya *',
                  prefixIcon:
                      const Icon(Iconsax.location, color: AppColors.grey500),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppDimens.radiusM),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppDimens.radiusM),
                    borderSide: const BorderSide(color: AppColors.grey300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppDimens.radiusM),
                    borderSide: const BorderSide(
                        color: AppColors.primaryGreen, width: 2),
                  ),
                  filled: true,
                  fillColor: AppColors.white,
                ),
                items: _wilayas.map((wilaya) {
                  return DropdownMenuItem<String>(
                    value: wilaya.id,
                    child: Text('${wilaya.code} - ${wilaya.name}'),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedWilayaId = value;
                  });
                },
              ),
        const SizedBox(height: AppDimens.paddingM),

        // Password
        CustomTextField(
          controller: _passwordController,
          label: 'Mot de passe *',
          hint: '••••••••',
          obscureText: _obscurePassword,
          prefixIcon: Iconsax.lock,
          suffixIcon: IconButton(
            icon: Icon(
              _obscurePassword ? Iconsax.eye_slash : Iconsax.eye,
              color: AppColors.grey500,
            ),
            onPressed: () {
              setState(() {
                _obscurePassword = !_obscurePassword;
              });
            },
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Min. 8 caractères, 1 majuscule, 1 minuscule, 1 chiffre',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.grey500,
              ),
        ),
        const SizedBox(height: AppDimens.paddingM),

        // Confirm Password
        CustomTextField(
          controller: _confirmPasswordController,
          label: 'Confirmer le mot de passe *',
          hint: '••••••••',
          obscureText: _obscureConfirmPassword,
          prefixIcon: Iconsax.lock,
          suffixIcon: IconButton(
            icon: Icon(
              _obscureConfirmPassword ? Iconsax.eye_slash : Iconsax.eye,
              color: AppColors.grey500,
            ),
            onPressed: () {
              setState(() {
                _obscureConfirmPassword = !_obscureConfirmPassword;
              });
            },
          ),
        ),
      ],
    );
  }

  Widget _buildStep2() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Informations de l\'entreprise',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: AppDimens.paddingXS),
        Text(
          'Ces informations permettront de valider votre compte partenaire',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.grey600,
              ),
        ),
        const SizedBox(height: AppDimens.paddingL),

        // Company Name
        CustomTextField(
          controller: _companyNameController,
          label: 'Nom de l\'entreprise *',
          hint: 'Nom de votre entreprise',
          prefixIcon: Iconsax.building,
        ),
        const SizedBox(height: AppDimens.paddingM),

        // Registration Number
        CustomTextField(
          controller: _registrationNumberController,
          label: 'Numéro de registre de commerce (optionnel)',
          hint: 'Ex: 16/00-0123456B00',
          prefixIcon: Iconsax.document,
        ),
        const SizedBox(height: 4),
        Text(
          'Numéro d\'inscription au registre de commerce',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.grey500,
              ),
        ),
        const SizedBox(height: AppDimens.paddingM),

        // Tax ID (NIF)
        CustomTextField(
          controller: _taxIdController,
          label: 'NIF - Numéro d\'identification fiscale (optionnel)',
          hint: 'Ex: 000016012345678',
          prefixIcon: Iconsax.receipt,
        ),
        const SizedBox(height: AppDimens.paddingL),

        // Info box
        Container(
          padding: const EdgeInsets.all(AppDimens.paddingM),
          decoration: BoxDecoration(
            color: AppColors.info.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppDimens.radiusM),
            border: Border.all(color: AppColors.info.withValues(alpha: 0.3)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Iconsax.info_circle, color: AppColors.info, size: 20),
              const SizedBox(width: AppDimens.paddingS),
              Expanded(
                child: Text(
                  'Votre compte sera vérifié par notre équipe avant activation. '
                  'Vous recevrez un email de confirmation.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.info,
                      ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppDimens.paddingL),

        // Terms Checkbox
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 24,
              height: 24,
              child: Checkbox(
                value: _acceptTerms,
                onChanged: (value) {
                  setState(() {
                    _acceptTerms = value ?? false;
                  });
                },
                activeColor: AppColors.primaryGreen,
              ),
            ),
            const SizedBox(width: AppDimens.paddingS),
            Expanded(
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _acceptTerms = !_acceptTerms;
                  });
                },
                child: RichText(
                  text: TextSpan(
                    style: Theme.of(context).textTheme.bodySmall,
                    children: [
                      const TextSpan(text: 'J\'accepte les '),
                      TextSpan(
                        text: 'conditions d\'utilisation',
                        style: TextStyle(
                          color: AppColors.primaryGreen,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const TextSpan(text: ', la '),
                      TextSpan(
                        text: 'politique de confidentialité',
                        style: TextStyle(
                          color: AppColors.primaryGreen,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const TextSpan(text: ' et les '),
                      TextSpan(
                        text: 'conditions partenaires',
                        style: TextStyle(
                          color: AppColors.primaryGreen,
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
      ],
    );
  }

  Widget _buildBottomButtons() {
    return Container(
      padding: const EdgeInsets.all(AppDimens.paddingL),
      decoration: BoxDecoration(
        color: AppColors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        children: [
          if (_currentStep > 0)
            Expanded(
              child: OutlinedButton(
                onPressed: _onBack,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  side: const BorderSide(color: AppColors.primaryGreen),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppDimens.radiusM),
                  ),
                ),
                child: const Text('Retour'),
              ),
            ),
          if (_currentStep > 0) const SizedBox(width: AppDimens.paddingM),
          Expanded(
            flex: _currentStep == 0 ? 1 : 1,
            child: CustomButton(
              text: _currentStep == 0 ? 'Continuer' : 'S\'inscrire',
              onPressed: _onContinue,
            ),
          ),
        ],
      ),
    );
  }
}
