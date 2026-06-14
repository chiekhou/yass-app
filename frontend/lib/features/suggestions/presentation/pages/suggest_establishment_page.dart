import 'package:flutter/material.dart';
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
                  const Text(
                    'Suggestion envoyée !',
                    style: TextStyle(
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
                  const Text(
                    'Merci pour votre contribution !\nD\'autres utilisateurs pourront voter pour votre suggestion. L\'admin l\'examinera et pourra l\'ajouter à l\'annuaire.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
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
                      child: const Text('Retour à la liste'),
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
                      child: const Text('Suggérer un autre'),
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
          title: const Text('Suggérer un établissement'),
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
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppDimens.radiusM),
              ),
              child: Row(
                children: [
                  const Icon(Iconsax.info_circle,
                      color: AppColors.accentGreen, size: 20),
                  const SizedBox(width: AppDimens.paddingS),
                  Expanded(
                    child: Text(
                      'Signalez un établissement manquant dans l\'annuaire. Plus il y a de votes, plus vite il sera ajouté.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.primaryGreen,
                          ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppDimens.paddingL),

            _label('Nom de l\'établissement *'),
            _field(
              controller: _nameCtrl,
              hint: 'Ex: Café Central, Clinique El Amel...',
              icon: Iconsax.shop,
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Champ obligatoire' : null,
            ),

            const SizedBox(height: AppDimens.paddingM),
            _label('Adresse *'),
            _field(
              controller: _addressCtrl,
              hint: 'Rue, quartier, ville...',
              icon: Iconsax.location,
              maxLines: 2,
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Champ obligatoire' : null,
            ),

            const SizedBox(height: AppDimens.paddingM),
            _label('Téléphone (optionnel)'),
            _field(
              controller: _phoneCtrl,
              hint: '05 XX XX XX XX',
              icon: Iconsax.call,
              keyboardType: TextInputType.phone,
            ),

            const SizedBox(height: AppDimens.paddingM),
            _label('Email de contact *'),
            _field(
              controller: _emailCtrl,
              hint: 'votre@email.com',
              icon: Iconsax.sms,
              keyboardType: TextInputType.emailAddress,
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Champ obligatoire';
                if (!v.contains('@')) return 'Email invalide';
                return null;
              },
            ),

            const SizedBox(height: AppDimens.paddingM),
            _label('Catégorie (optionnel)'),
            _buildCategoryDropdown(),

            const SizedBox(height: AppDimens.paddingM),
            _label('Wilaya (optionnel)'),
            _buildWilayaDropdown(),

            const SizedBox(height: AppDimens.paddingM),
            _label('Description (optionnel)'),
            _field(
              controller: _descCtrl,
              hint: 'Décrivez brièvement cet établissement...',
              icon: Iconsax.document_text,
              maxLines: 3,
            ),

            const SizedBox(height: AppDimens.paddingM),
            _label('Motif de la suggestion (optionnel)'),
            _field(
              controller: _reasonCtrl,
              hint:
                  'Ex: souvent demandé dans le quartier, nouveau établissement...',
              icon: Iconsax.message_question,
              maxLines: 2,
            ),

            const SizedBox(height: AppDimens.paddingXL),

            Center(
              child: ElevatedButton.icon(
                onPressed: _submit,
                icon: const Icon(Iconsax.send_1),
                label: const Text('Envoyer ma suggestion'),
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
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon, size: 18, color: AppColors.black),
        filled: true,
        fillColor: AppColors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimens.radiusM),
          borderSide: const BorderSide(color: AppColors.black),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimens.radiusM),
          borderSide: const BorderSide(color: AppColors.black),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimens.radiusM),
          borderSide:
              const BorderSide(color: AppColors.accentGreen, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppDimens.paddingM,
          vertical: AppDimens.paddingM,
        ),
      ),
    );
  }

  Widget _buildCategoryDropdown() {
    return DropdownButtonFormField<String>(
      initialValue: _selectedCategoryId,
      decoration: InputDecoration(
        hintText: 'Sélectionner une catégorie',
        prefixIcon:
            const Icon(Iconsax.category, size: 18, color: AppColors.black),
        filled: true,
        fillColor: AppColors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimens.radiusM),
          borderSide: const BorderSide(color: AppColors.black),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimens.radiusM),
          borderSide: const BorderSide(color: AppColors.black),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimens.radiusM),
          borderSide:
              const BorderSide(color: AppColors.accentGreen, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppDimens.paddingM,
          vertical: AppDimens.paddingM,
        ),
      ),
      items: [
        const DropdownMenuItem<String>(
            value: null, child: Text('Aucune catégorie séléctionnée')),
        ..._categories.map((c) => DropdownMenuItem<String>(
              value: c.id,
              child: Text(c.name, overflow: TextOverflow.ellipsis),
            )),
      ],
      onChanged: (v) => setState(() => _selectedCategoryId = v),
    );
  }

  Widget _buildWilayaDropdown() {
    return DropdownButtonFormField<String>(
      initialValue: _selectedWilayaId,
      decoration: InputDecoration(
        hintText: 'Sélectionner une wilaya',
        prefixIcon:
            const Icon(Iconsax.location, size: 18, color: AppColors.black),
        filled: true,
        fillColor: AppColors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimens.radiusM),
          borderSide: const BorderSide(color: AppColors.grey200),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimens.radiusM),
          borderSide: const BorderSide(color: AppColors.grey200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimens.radiusM),
          borderSide:
              const BorderSide(color: AppColors.accentGreen, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppDimens.paddingM,
          vertical: AppDimens.paddingM,
        ),
      ),
      items: [
        const DropdownMenuItem<String>(
            value: null, child: Text('Aucune wilaya séléctionnée')),
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
