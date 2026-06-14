import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../shared/widgets/custom_text_field.dart';
import '../bloc/admin_partners_bloc.dart';
import '../../../../app_router.dart';

class AdminCreatePartnerPage extends StatefulWidget {
  const AdminCreatePartnerPage({super.key});

  @override
  State<AdminCreatePartnerPage> createState() => _AdminCreatePartnerPageState();
}

class _AdminCreatePartnerPageState extends State<AdminCreatePartnerPage> {
  final _formKey = GlobalKey<FormState>();

  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _companyNameCtrl = TextEditingController();
  final _registrationNumberCtrl = TextEditingController();
  final _taxIdCtrl = TextEditingController();

  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _phoneCtrl.dispose();
    _companyNameCtrl.dispose();
    _registrationNumberCtrl.dispose();
    _taxIdCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    context.read<AdminPartnersBloc>().add(
          AdminPartnerCreate(data: {
            'email': _emailCtrl.text.trim(),
            'password': _passwordCtrl.text,
            'first_name': _firstNameCtrl.text.trim(),
            'last_name': _lastNameCtrl.text.trim(),
            'phone': _phoneCtrl.text.trim(),
            'company_name': _companyNameCtrl.text.trim(),
            if (_registrationNumberCtrl.text.trim().isNotEmpty)
              'registration_number': _registrationNumberCtrl.text.trim(),
            if (_taxIdCtrl.text.trim().isNotEmpty)
              'tax_id': _taxIdCtrl.text.trim(),
          }),
        );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AdminPartnersBloc, AdminPartnersState>(
      listener: (context, state) {
        if (state is AdminPartnerCreated) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  'Partenaire ${state.partner.companyName} créé avec succès'),
              backgroundColor: AppColors.success,
            ),
          );
          context.go(AppRoutes.adminDashboard);
        } else if (state is AdminPartnersError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: AppColors.error,
            ),
          );
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.grey50,
        appBar: AppBar(
          title: const Text('Créer un partenaire'),
          backgroundColor: const Color(0xFF002FA7),
          foregroundColor: AppColors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Iconsax.arrow_left),
            onPressed: () => context.go(AppRoutes.adminDashboard),
          ),
        ),
        body: BlocBuilder<AdminPartnersBloc, AdminPartnersState>(
          builder: (context, state) {
            final isLoading = state is AdminPartnersLoading;
            return SingleChildScrollView(
              padding: const EdgeInsets.all(AppDimens.paddingL),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _sectionTitle(context, 'Informations du compte'),
                    const SizedBox(height: AppDimens.paddingM),
                    CustomTextField(
                      controller: _emailCtrl,
                      label: 'Email',
                      hint: 'partenaire@exemple.com',
                      keyboardType: TextInputType.emailAddress,
                      prefixIcon: Iconsax.sms,
                      textColor: AppColors.scaffoldBackground,
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Email requis';
                        if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(v)) {
                          return 'Email invalide';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: AppDimens.paddingM),
                    CustomTextField(
                      controller: _passwordCtrl,
                      label: 'Mot de passe',
                      hint: 'Min. 8 caractères',
                      obscureText: _obscurePassword,
                      prefixIcon: Iconsax.lock,
                      textColor: AppColors.scaffoldBackground,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword ? Iconsax.eye_slash : Iconsax.eye,
                          color: AppColors.scaffoldBackground
                              .withValues(alpha: 0.6),
                        ),
                        onPressed: () => setState(
                            () => _obscurePassword = !_obscurePassword),
                      ),
                      validator: (v) {
                        if (v == null || v.length < 8) {
                          return 'Au moins 8 caractères';
                        }
                        if (!RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)')
                            .hasMatch(v)) {
                          return 'Doit contenir majuscule, minuscule et chiffre';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: AppDimens.paddingL),
                    _sectionTitle(context, 'Informations personnelles'),
                    const SizedBox(height: AppDimens.paddingM),
                    Row(
                      children: [
                        Expanded(
                          child: CustomTextField(
                            controller: _firstNameCtrl,
                            label: 'Prénom',
                            hint: 'Karim',
                            prefixIcon: Iconsax.user,
                            textColor: AppColors.scaffoldBackground,
                            validator: (v) =>
                                (v == null || v.isEmpty) ? 'Requis' : null,
                          ),
                        ),
                        const SizedBox(width: AppDimens.paddingM),
                        Expanded(
                          child: CustomTextField(
                            controller: _lastNameCtrl,
                            label: 'Nom',
                            hint: 'Benali',
                            prefixIcon: Iconsax.user,
                            textColor: AppColors.scaffoldBackground,
                            validator: (v) =>
                                (v == null || v.isEmpty) ? 'Requis' : null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppDimens.paddingM),
                    CustomTextField(
                      controller: _phoneCtrl,
                      label: 'Téléphone',
                      hint: '0551234567',
                      keyboardType: TextInputType.phone,
                      prefixIcon: Iconsax.call,
                      textColor: AppColors.scaffoldBackground,
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Téléphone requis';
                        if (!RegExp(r'^\+?\d{7,15}$').hasMatch(v)) {
                          return 'Numéro invalide';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: AppDimens.paddingL),
                    _sectionTitle(context, 'Informations de la société'),
                    const SizedBox(height: AppDimens.paddingM),
                    CustomTextField(
                      controller: _companyNameCtrl,
                      label: 'Nom de la société',
                      hint: 'Restaurant El Djazair',
                      prefixIcon: Iconsax.building,
                      textColor: AppColors.scaffoldBackground,
                      validator: (v) => (v == null || v.isEmpty)
                          ? 'Nom de la société requis'
                          : null,
                    ),
                    const SizedBox(height: AppDimens.paddingM),
                    CustomTextField(
                      controller: _registrationNumberCtrl,
                      label: 'N° registre de commerce (optionnel)',
                      hint: 'RC16/00-12345',
                      prefixIcon: Iconsax.document,
                      textColor: AppColors.scaffoldBackground,
                    ),
                    const SizedBox(height: AppDimens.paddingM),
                    CustomTextField(
                      controller: _taxIdCtrl,
                      label: 'NIF / Identifiant fiscal (optionnel)',
                      hint: 'NIF001234567890',
                      prefixIcon: Iconsax.receipt,
                      textColor: AppColors.scaffoldBackground,
                    ),
                    const SizedBox(height: AppDimens.paddingXL),
                    ElevatedButton(
                      onPressed: isLoading ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.scaffoldBackground,
                        foregroundColor: AppColors.white,
                        padding: const EdgeInsets.symmetric(
                            vertical: AppDimens.paddingM),
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(AppDimens.radiusM),
                        ),
                      ),
                      child: isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                  color: AppColors.white, strokeWidth: 2),
                            )
                          : const Text(
                              'Créer le partenaire',
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.w600),
                            ),
                    ),
                    const SizedBox(height: AppDimens.paddingXL),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _sectionTitle(BuildContext context, String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
            color: AppColors.primaryGreen,
          ),
    );
  }
}
