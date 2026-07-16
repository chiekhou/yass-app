import 'package:flutter/material.dart';
import 'package:win_app/core/l10n/l10n_extensions.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../shared/widgets/loading_overlay.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../home/data/models/category_model.dart';
import '../../../home/data/repositories/category_repository.dart';
import '../../data/repositories/suggestion_repository.dart';

class SuggestEstablishmentPage extends StatefulWidget {
  const SuggestEstablishmentPage({super.key});

  @override
  State<SuggestEstablishmentPage> createState() =>
      _SuggestEstablishmentPageState();
}

class _SuggestEstablishmentPageState extends State<SuggestEstablishmentPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _reasonCtrl = TextEditingController();

  final _repo = SuggestionRepository();
  final _categoryRepo = CategoryRepository();

  List<Category> _categories = [];
  List<Wilaya> _wilayas = [];
  String? _selectedCategoryId;
  String? _selectedWilayaId;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _loadFilters();
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthAuthenticated) {
      _emailCtrl.text = authState.user.email;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _addressCtrl.dispose();
    _phoneCtrl.dispose();
    _descCtrl.dispose();
    _emailCtrl.dispose();
    _reasonCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadFilters() async {
    try {
      final results = await Future.wait([
        _categoryRepo.getAll(),
        WilayaRepository().getAll(),
      ]);
      if (mounted) {
        setState(() {
          _categories = results[0] as List<Category>;
          _wilayas = results[1] as List<Wilaya>;
        });
      }
    } catch (_) {}
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    try {
      await _repo.create(
        name: _nameCtrl.text.trim(),
        address: _addressCtrl.text.trim(),
        phone: _phoneCtrl.text.trim(),
        description: _descCtrl.text.trim(),
        contactEmail: _emailCtrl.text.trim(),
        reason: _reasonCtrl.text.trim(),
        categoryId: _selectedCategoryId,
        wilayaId: _selectedWilayaId,
      );

      if (mounted) {
        setState(() => _loading = false);
        _showSuccessDialog();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: AppColors.redLight,
          ),
        );
      }
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimens.radiusL),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header aux couleurs du drapeau algérien
            Container(
              width: double.infinity,
              padding:
                  const EdgeInsets.symmetric(vertical: AppDimens.paddingXL),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.primaryBlue, AppColors.primaryBlueDark],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                children: [
                  // Croissant + étoile style drapeau
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          color: AppColors.white.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const Icon(
                        Iconsax.tick_circle,
                        size: 40,
                        color: AppColors.white,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppDimens.paddingM),
                  Text(
                    context.l10n.suggestionSent,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.white,
                      fontFamily: 'Cairo',
                    ),
                  ),
                  const SizedBox(height: AppDimens.paddingXS),
                  // Bande rouge façon drapeau
                  Container(
                    width: 48,
                    height: 3,
                    decoration: BoxDecoration(
                      color: AppColors.primaryRed,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ],
              ),
            ),

            // Corps
            Padding(
              padding: const EdgeInsets.all(AppDimens.paddingL),
              child: Column(
                children: [
                  Text(
                    context.l10n.suggestionSentBody,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                      height: 1.5,
                      fontFamily: 'Cairo',
                    ),
                  ),
                  const SizedBox(height: AppDimens.paddingL),

                  // Bouton Retour (vert)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accentGreen,
                        foregroundColor: AppColors.white,
                      ),
                      child: Text(context.l10n.backToList),
                    ),
                  ),
                  const SizedBox(height: AppDimens.paddingS),

                  // Bouton Suggérer un autre (rouge)
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        _nameCtrl.clear();
                        _addressCtrl.clear();
                        _phoneCtrl.clear();
                        _descCtrl.clear();
                        _reasonCtrl.clear();
                        // On garde l'email pré-rempli
                        setState(() {
                          _selectedCategoryId = null;
                          _selectedWilayaId = null;
                        });
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primaryRed,
                        side: const BorderSide(color: AppColors.primaryRed),
                      ),
                      child: Text(context.l10n.suggestAnother),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LoadingOverlay(
      isLoading: _loading,
      child: Scaffold(
        backgroundColor: AppColors.kleinBlue,
        appBar: AppBar(
          backgroundColor: AppColors.kleinBlue,
          foregroundColor: AppColors.white,
          title: Text(context.l10n.suggestEstablishment),
        ),
        body: _buildForm(),
      ),
    );
  }

  Widget _buildForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppDimens.paddingM),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Info banner
            Container(
              padding: const EdgeInsets.all(AppDimens.paddingM),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(AppDimens.radiusM),
              ),
              child: Row(
                children: [
                  const Icon(Iconsax.info_circle,
                      color: AppColors.accentGreen, size: 20),
                  const SizedBox(width: AppDimens.paddingS),
                  Expanded(
                    child: Text(
                      context.l10n.infoBannerSuggest,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.primaryGreen,
                          ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppDimens.paddingL),

            _label(context.l10n.establishmentNameLabel),
            _field(
              controller: _nameCtrl,
              hint: context.l10n.nameHint,
              icon: Iconsax.shop,
              validator: (v) => v == null || v.trim().isEmpty
                  ? context.l10n.fieldRequired
                  : null,
            ),

            const SizedBox(height: AppDimens.paddingM),
            _label(context.l10n.addressLabel),
            _field(
              controller: _addressCtrl,
              hint: context.l10n.addressHint,
              icon: Iconsax.location,
              maxLines: 2,
              validator: (v) => v == null || v.trim().isEmpty
                  ? context.l10n.fieldRequired
                  : null,
            ),

            const SizedBox(height: AppDimens.paddingM),
            _label(context.l10n.phoneOptional),
            _field(
              controller: _phoneCtrl,
              hint: '05 XX XX XX XX',
              icon: Iconsax.call,
              keyboardType: TextInputType.phone,
            ),

            const SizedBox(height: AppDimens.paddingM),
            _label(context.l10n.contactEmailLabel),
            _field(
              controller: _emailCtrl,
              hint: 'votre@email.com',
              icon: Iconsax.sms,
              keyboardType: TextInputType.emailAddress,
              validator: (v) {
                if (v == null || v.trim().isEmpty)
                  return context.l10n.fieldRequired;
                if (!v.contains('@')) return context.l10n.invalidEmail;
                return null;
              },
            ),

            const SizedBox(height: AppDimens.paddingM),
            _label(context.l10n.categoryOptional),
            _buildCategoryDropdown(),

            const SizedBox(height: AppDimens.paddingM),
            _label(context.l10n.wilayaOptional),
            _buildWilayaDropdown(),

            const SizedBox(height: AppDimens.paddingM),
            _label(context.l10n.descriptionOptional),
            _field(
              controller: _descCtrl,
              hint: context.l10n.descriptionHint,
              icon: Iconsax.document_text,
              maxLines: 3,
            ),

            const SizedBox(height: AppDimens.paddingM),
            _label(context.l10n.suggestionReasonOptional),
            _field(
              controller: _reasonCtrl,
              hint: context.l10n.reasonHint,
              icon: Iconsax.message_question,
              maxLines: 2,
            ),

            const SizedBox(height: AppDimens.paddingXL),

            Center(
              child: ElevatedButton.icon(
                onPressed: _submit,
                icon: const Icon(Iconsax.send_1),
                label: Text(context.l10n.submitSuggestion),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accentGreen,
                  foregroundColor: AppColors.black,
                  minimumSize: Size.zero,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppDimens.paddingL,
                    vertical: AppDimens.paddingM,
                  ),
                ),
              ),
            ),

            const SizedBox(height: AppDimens.paddingL),
          ],
        ),
      ),
    );
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: AppDimens.paddingS),
        child: Text(
          text,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.white,
              ),
        ),
      );

  Widget _field({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator: validator,
      style: const TextStyle(color: AppColors.white),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: AppColors.white.withValues(alpha: 0.45)),
        prefixIcon: Icon(icon, size: 18, color: Colors.white70),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimens.radiusM),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.25)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimens.radiusM),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.25)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimens.radiusM),
          borderSide:
              const BorderSide(color: AppColors.accentGreen, width: 1.5),
        ),
        errorStyle: const TextStyle(color: AppColors.redLight),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppDimens.paddingM,
          vertical: AppDimens.paddingM,
        ),
      ),
    );
  }

  InputDecoration _dropdownDecoration({
    required String hint,
    required IconData icon,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: AppColors.white.withValues(alpha: 0.45)),
      prefixIcon: Icon(icon, size: 18, color: Colors.white70),
      filled: true,
      fillColor: Colors.white.withValues(alpha: 0.12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppDimens.radiusM),
        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.25)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppDimens.radiusM),
        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.25)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppDimens.radiusM),
        borderSide: const BorderSide(color: AppColors.accentGreen, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppDimens.paddingM,
        vertical: AppDimens.paddingM,
      ),
    );
  }

  Widget _buildCategoryDropdown() {
    final lang = Localizations.localeOf(context).languageCode;
    return DropdownButtonFormField<String>(
      initialValue: _selectedCategoryId,
      style: const TextStyle(color: AppColors.white),
      dropdownColor: AppColors.primaryBlueDark,
      iconEnabledColor: Colors.white70,
      decoration: _dropdownDecoration(
        hint: context.l10n.selectCategory,
        icon: Iconsax.category,
      ),
      items: [
        DropdownMenuItem<String>(
            value: null, child: Text(context.l10n.noCategorySelected)),
        ..._categories.map((c) => DropdownMenuItem<String>(
              value: c.id,
              child: Text(c.localizedName(lang), overflow: TextOverflow.ellipsis),
            )),
      ],
      onChanged: (v) => setState(() => _selectedCategoryId = v),
    );
  }

  Widget _buildWilayaDropdown() {
    return DropdownButtonFormField<String>(
      initialValue: _selectedWilayaId,
      style: const TextStyle(color: AppColors.white),
      dropdownColor: AppColors.primaryBlueDark,
      iconEnabledColor: Colors.white70,
      decoration: _dropdownDecoration(
        hint: context.l10n.selectAWilaya,
        icon: Iconsax.location,
      ),
      items: [
        DropdownMenuItem<String>(
            value: null, child: Text(context.l10n.noWilayaSelected)),
        ..._wilayas.map((w) => DropdownMenuItem<String>(
              value: w.id,
              child: Text('${w.code} - ${w.name}',
                  overflow: TextOverflow.ellipsis),
            )),
      ],
      onChanged: (v) => setState(() => _selectedWilayaId = v),
    );
  }
}
