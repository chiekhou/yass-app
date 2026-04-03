import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';

class EditPartnerProfilePage extends StatefulWidget {
  const EditPartnerProfilePage({super.key});

  @override
  State<EditPartnerProfilePage> createState() => _EditPartnerProfilePageState();
}

class _EditPartnerProfilePageState extends State<EditPartnerProfilePage> {
  final _formKey = GlobalKey<FormState>();

  final _companyNameController = TextEditingController();
  final _registrationNumberController = TextEditingController();
  final _taxIdController = TextEditingController();

  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadPartnerData();
  }

  @override
  void dispose() {
    _companyNameController.dispose();
    _registrationNumberController.dispose();
    _taxIdController.dispose();
    super.dispose();
  }

  void _loadPartnerData() {
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthAuthenticated && authState.user.partnerProfile != null) {
      final partner = authState.user.partnerProfile!;
      _companyNameController.text = partner.companyName;
      _registrationNumberController.text = partner.registrationNumber ?? '';
      _taxIdController.text = partner.taxId ?? '';
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    context.read<AuthBloc>().add(AuthUpdatePartnerProfile(
          companyName: _companyNameController.text.trim(),
          registrationNumber: _registrationNumberController.text.trim().isNotEmpty
              ? _registrationNumberController.text.trim()
              : null,
          taxId: _taxIdController.text.trim().isNotEmpty
              ? _taxIdController.text.trim()
              : null,
        ));
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthAuthenticated) {
          setState(() {
            _isLoading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Informations entreprise mises à jour'),
              backgroundColor: AppColors.success,
            ),
          );
          context.pop();
        } else if (state is AuthError) {
          setState(() {
            _isLoading = false;
            _errorMessage = state.message;
          });
        } else if (state is AuthLoading) {
          setState(() {
            _isLoading = true;
          });
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.grey50,
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Iconsax.arrow_left),
            onPressed: () => context.pop(),
          ),
          title: const Text('Informations entreprise'),
          backgroundColor: AppColors.primaryGreen,
          foregroundColor: AppColors.white,
          elevation: 0,
        ),
        body: _buildForm(),
      ),
    );
  }

  Widget _buildForm() {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        if (state is! AuthAuthenticated || !state.user.isPartner) {
          return const Center(
            child: Text('Accès réservé aux partenaires'),
          );
        }

        return Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppDimens.paddingM),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_errorMessage != null)
                  Container(
                    margin: const EdgeInsets.only(bottom: AppDimens.paddingM),
                    padding: const EdgeInsets.all(AppDimens.paddingM),
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppDimens.radiusM),
                    ),
                    child: Row(
                      children: [
                        const Icon(Iconsax.warning_2, color: AppColors.error),
                        const SizedBox(width: AppDimens.paddingS),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: const TextStyle(color: AppColors.error),
                          ),
                        ),
                      ],
                    ),
                  ),

                // Info card
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
                      const Icon(Iconsax.building, color: AppColors.info, size: 24),
                      const SizedBox(width: AppDimens.paddingM),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Informations de votre entreprise',
                              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.info,
                                  ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Ces informations sont utilisées pour la validation de votre compte partenaire.',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppColors.grey600,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: AppDimens.paddingXL),

                // Company Name
                Text(
                  'Nom de l\'entreprise *',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.grey800,
                      ),
                ),
                const SizedBox(height: AppDimens.paddingS),
                _buildTextField(
                  controller: _companyNameController,
                  hint: 'Nom de votre entreprise',
                  icon: Iconsax.building,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Le nom de l\'entreprise est requis';
                    }
                    if (value.length < 2) {
                      return 'Minimum 2 caractères';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: AppDimens.paddingL),

                // Registration Number
                Text(
                  'Numéro de registre de commerce',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.grey800,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Numéro d\'inscription au registre de commerce (RC)',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.grey500,
                      ),
                ),
                const SizedBox(height: AppDimens.paddingS),
                _buildTextField(
                  controller: _registrationNumberController,
                  hint: 'Ex: 16/00-0123456B00',
                  icon: Iconsax.document,
                ),

                const SizedBox(height: AppDimens.paddingL),

                // Tax ID (NIF)
                Text(
                  'NIF - Numéro d\'identification fiscale',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.grey800,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Numéro d\'identification fiscale de votre entreprise',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.grey500,
                      ),
                ),
                const SizedBox(height: AppDimens.paddingS),
                _buildTextField(
                  controller: _taxIdController,
                  hint: 'Ex: 000016012345678',
                  icon: Iconsax.receipt,
                ),

                const SizedBox(height: AppDimens.paddingXL),

                // Submit Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _submitForm,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryGreen,
                      foregroundColor: AppColors.white,
                      padding: const EdgeInsets.symmetric(
                        vertical: AppDimens.paddingM,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppDimens.radiusM),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: AppColors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            'Enregistrer',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),

                const SizedBox(height: AppDimens.paddingXL),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon, color: AppColors.grey500),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimens.radiusM),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimens.radiusM),
          borderSide: const BorderSide(color: AppColors.grey300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimens.radiusM),
          borderSide: const BorderSide(color: AppColors.primaryGreen, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimens.radiusM),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        filled: true,
        fillColor: AppColors.white,
      ),
    );
  }
}
