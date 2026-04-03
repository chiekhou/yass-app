import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../shared/widgets/custom_text_field.dart';
import '../../../home/data/models/category_model.dart';
import '../../../home/data/repositories/category_repository.dart';
import '../../data/repositories/admin_repository.dart';

class AdminCreateEstablishmentPage extends StatefulWidget {
  final String partnerId;
  final String partnerName;

  const AdminCreateEstablishmentPage({
    super.key,
    required this.partnerId,
    required this.partnerName,
  });

  @override
  State<AdminCreateEstablishmentPage> createState() =>
      _AdminCreateEstablishmentPageState();
}

class _AdminCreateEstablishmentPageState
    extends State<AdminCreateEstablishmentPage> {
  final _formKey = GlobalKey<FormState>();
  final _adminRepository = AdminRepository();
  final _categoryRepository = CategoryRepository();
  final _wilayaRepository = WilayaRepository();

  // Controllers
  final _nameCtrl = TextEditingController();
  final _nameArCtrl = TextEditingController();
  final _descriptionCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _whatsappCtrl = TextEditingController();

  // Data
  List<Category> _categories = [];
  List<SubCategory> _subcategories = [];
  List<Wilaya> _wilayas = [];
  List<Commune> _communes = [];

  // Selected
  String? _selectedCategoryId;
  String? _selectedSubcategoryId;
  String? _selectedWilayaId;
  String? _selectedCommuneId;
  String? _selectedPriceRange;

  // Services & amenities
  final List<String> _services = [];
  final List<String> _amenities = [];
  final _newServiceCtrl = TextEditingController();
  final _newAmenityCtrl = TextEditingController();

  // Opening hours
  static const _days = [
    'monday',
    'tuesday',
    'wednesday',
    'thursday',
    'friday',
    'saturday',
    'sunday',
  ];
  static const _dayLabels = {
    'monday': 'Lundi',
    'tuesday': 'Mardi',
    'wednesday': 'Mercredi',
    'thursday': 'Jeudi',
    'friday': 'Vendredi',
    'saturday': 'Samedi',
    'sunday': 'Dimanche',
  };
  late final Map<String, bool> _dayClosed;
  late final Map<String, TextEditingController> _openCtrl;
  late final Map<String, TextEditingController> _closeCtrl;

  bool _isLoadingData = true;
  bool _isSubmitting = false;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _dayClosed = {for (final d in _days) d: false};
    _openCtrl = {for (final d in _days) d: TextEditingController()};
    _closeCtrl = {for (final d in _days) d: TextEditingController()};
    _loadInitialData();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _nameArCtrl.dispose();
    _descriptionCtrl.dispose();
    _addressCtrl.dispose();
    _phoneCtrl.dispose();
    _whatsappCtrl.dispose();
    _newServiceCtrl.dispose();
    _newAmenityCtrl.dispose();
    for (final d in _days) {
      _openCtrl[d]!.dispose();
      _closeCtrl[d]!.dispose();
    }
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    try {
      final results = await Future.wait([
        _categoryRepository.getAll(),
        _wilayaRepository.getAll(),
      ]);
      setState(() {
        _categories = results[0] as List<Category>;
        _wilayas = results[1] as List<Wilaya>;
        _isLoadingData = false;
      });
    } catch (e) {
      setState(() {
        _loadError = e.toString();
        _isLoadingData = false;
      });
    }
  }

  Future<void> _onCategoryChanged(String? categoryId) async {
    setState(() {
      _selectedCategoryId = categoryId;
      _selectedSubcategoryId = null;
      _subcategories = [];
    });
    if (categoryId == null) return;
    try {
      final subs = await _categoryRepository.getSubcategories(categoryId);
      setState(() => _subcategories = subs);
    } catch (_) {}
  }

  Future<void> _onWilayaChanged(String? wilayaId) async {
    setState(() {
      _selectedWilayaId = wilayaId;
      _selectedCommuneId = null;
      _communes = [];
    });
    if (wilayaId == null) return;
    try {
      final communes = await _wilayaRepository.getCommunes(wilayaId);
      setState(() => _communes = communes);
    } catch (_) {}
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedSubcategoryId == null) {
      _showError('Veuillez sélectionner une sous-catégorie');
      return;
    }
    if (_selectedCommuneId == null) {
      _showError('Veuillez sélectionner une commune');
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final openingHours = <String, Map<String, String>>{};
      for (final day in _days) {
        if (!_dayClosed[day]! && _openCtrl[day]!.text.isNotEmpty) {
          openingHours[day] = {
            'open': _openCtrl[day]!.text,
            'close': _closeCtrl[day]!.text,
          };
        }
      }

      await _adminRepository.createEstablishment({
        'partner_id': widget.partnerId,
        'subcategory_id': _selectedSubcategoryId,
        'commune_id': _selectedCommuneId,
        'name': _nameCtrl.text.trim(),
        if (_nameArCtrl.text.trim().isNotEmpty)
          'name_ar': _nameArCtrl.text.trim(),
        'description': _descriptionCtrl.text.trim(),
        'address': _addressCtrl.text.trim(),
        if (_phoneCtrl.text.trim().isNotEmpty) 'phone': _phoneCtrl.text.trim(),
        if (_whatsappCtrl.text.trim().isNotEmpty)
          'whatsapp': _whatsappCtrl.text.trim(),
        if (_selectedPriceRange != null) 'price_range': _selectedPriceRange,
        if (_services.isNotEmpty) 'services': _services,
        if (_amenities.isNotEmpty) 'amenities': _amenities,
        if (openingHours.isNotEmpty) 'opening_hours': openingHours,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Établissement "${_nameCtrl.text}" créé avec succès'),
            backgroundColor: AppColors.success,
          ),
        );
        context.pop();
      }
    } catch (e) {
      _showError(e.toString());
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.error),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.grey50,
      appBar: AppBar(
        title: const Text('Créer un établissement'),
        backgroundColor: AppColors.primaryGreen,
        foregroundColor: AppColors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Iconsax.arrow_left),
          onPressed: () => context.pop(),
        ),
      ),
      body: _isLoadingData
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primaryGreen))
          : _loadError != null
              ? _buildError()
              : _buildForm(),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppDimens.paddingXL),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Iconsax.warning_2, size: 64, color: AppColors.error),
            const SizedBox(height: AppDimens.paddingM),
            Text(_loadError!,
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.grey600)),
            const SizedBox(height: AppDimens.paddingL),
            ElevatedButton.icon(
              onPressed: () {
                setState(() => _isLoadingData = true);
                _loadInitialData();
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Réessayer'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppDimens.paddingL),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Partner info banner
            Container(
              padding: const EdgeInsets.all(AppDimens.paddingM),
              decoration: BoxDecoration(
                color: AppColors.primaryGreen.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(AppDimens.radiusM),
                border: Border.all(
                    color: AppColors.primaryGreen.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Iconsax.briefcase,
                      color: AppColors.primaryGreen, size: 20),
                  const SizedBox(width: AppDimens.paddingS),
                  Expanded(
                    child: Text(
                      'Partenaire : ${widget.partnerName}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppColors.primaryGreen,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppDimens.paddingL),

            _sectionTitle('Localisation'),
            const SizedBox(height: AppDimens.paddingM),

            // Wilaya dropdown
            DropdownButtonFormField<String>(
              initialValue: _selectedWilayaId,
              decoration: _dropdownDecoration('Wilaya'),
              items: _wilayas
                  .map(
                      (w) => DropdownMenuItem(value: w.id, child: Text(w.name)))
                  .toList(),
              onChanged: _onWilayaChanged,
              validator: (v) => v == null ? 'Wilaya requise' : null,
            ),
            const SizedBox(height: AppDimens.paddingM),

            // Commune dropdown
            DropdownButtonFormField<String>(
              initialValue: _selectedCommuneId,
              decoration: _dropdownDecoration('Commune'),
              items: _communes
                  .map(
                      (c) => DropdownMenuItem(value: c.id, child: Text(c.name)))
                  .toList(),
              onChanged: (v) => setState(() => _selectedCommuneId = v),
              validator: (v) => v == null ? 'Commune requise' : null,
            ),
            const SizedBox(height: AppDimens.paddingL),

            _sectionTitle('Catégorie'),
            const SizedBox(height: AppDimens.paddingM),

            // Category dropdown
            DropdownButtonFormField<String>(
              initialValue: _selectedCategoryId,
              decoration: _dropdownDecoration('Catégorie'),
              items: _categories
                  .map(
                      (c) => DropdownMenuItem(value: c.id, child: Text(c.name)))
                  .toList(),
              onChanged: _onCategoryChanged,
              validator: (v) => v == null ? 'Catégorie requise' : null,
            ),
            const SizedBox(height: AppDimens.paddingM),

            // Subcategory dropdown
            DropdownButtonFormField<String>(
              initialValue: _selectedSubcategoryId,
              decoration: _dropdownDecoration('Sous-catégorie'),
              items: _subcategories
                  .map(
                      (s) => DropdownMenuItem(value: s.id, child: Text(s.name)))
                  .toList(),
              onChanged: (v) => setState(() => _selectedSubcategoryId = v),
              validator: (v) => v == null ? 'Sous-catégorie requise' : null,
            ),
            const SizedBox(height: AppDimens.paddingL),

            _sectionTitle('Informations générales'),
            const SizedBox(height: AppDimens.paddingM),

            CustomTextField(
              controller: _nameCtrl,
              label: 'Nom de l\'établissement',
              hint: 'Restaurant El Djazair',
              prefixIcon: Iconsax.building,
              validator: (v) => (v == null || v.isEmpty) ? 'Nom requis' : null,
            ),
            const SizedBox(height: AppDimens.paddingM),
            CustomTextField(
              controller: _nameArCtrl,
              label: 'Nom en arabe (optionnel)',
              hint: 'مطعم الجزائر',
              prefixIcon: Iconsax.building,
            ),
            const SizedBox(height: AppDimens.paddingM),
            CustomTextField(
              controller: _descriptionCtrl,
              label: 'Description',
              hint: 'Décrivez l\'établissement...',
              prefixIcon: Iconsax.document_text,
              maxLines: 3,
              validator: (v) =>
                  (v == null || v.isEmpty) ? 'Description requise' : null,
            ),
            const SizedBox(height: AppDimens.paddingM),
            CustomTextField(
              controller: _addressCtrl,
              label: 'Adresse',
              hint: '15 Rue Didouche Mourad, Alger',
              prefixIcon: Iconsax.location,
              validator: (v) =>
                  (v == null || v.isEmpty) ? 'Adresse requise' : null,
            ),
            const SizedBox(height: AppDimens.paddingL),

            _sectionTitle('Contact'),
            const SizedBox(height: AppDimens.paddingM),

            CustomTextField(
              controller: _phoneCtrl,
              label: 'Téléphone (optionnel)',
              hint: '023456789',
              keyboardType: TextInputType.phone,
              prefixIcon: Iconsax.call,
            ),
            const SizedBox(height: AppDimens.paddingM),
            CustomTextField(
              controller: _whatsappCtrl,
              label: 'WhatsApp (optionnel)',
              hint: '0551234567',
              keyboardType: TextInputType.phone,
              prefixIcon: Iconsax.call_calling,
            ),
            const SizedBox(height: AppDimens.paddingL),

            _sectionTitle('Tarification'),
            const SizedBox(height: AppDimens.paddingM),

            DropdownButtonFormField<String>(
              initialValue: _selectedPriceRange,
              decoration: _dropdownDecoration('Gamme de prix (optionnel)'),
              items: const [
                DropdownMenuItem(value: r'$', child: Text(r'$ — Économique')),
                DropdownMenuItem(value: r'$$', child: Text(r'$$ — Modéré')),
                DropdownMenuItem(value: r'$$$', child: Text(r'$$$ — Élevé')),
                DropdownMenuItem(value: r'$$$$', child: Text(r'$$$$ — Luxe')),
              ],
              onChanged: (v) => setState(() => _selectedPriceRange = v),
            ),
            const SizedBox(height: AppDimens.paddingL),
            _sectionTitle('Services (optionnel)'),
            const SizedBox(height: AppDimens.paddingM),
            _buildTagInput(
              controller: _newServiceCtrl,
              items: _services,
              hint: 'Ex: WiFi, Parking, Livraison...',
              onAdd: (v) => setState(() => _services.add(v)),
              onRemove: (v) => setState(() => _services.remove(v)),
            ),
            const SizedBox(height: AppDimens.paddingL),
            _sectionTitle('Équipements (optionnel)'),
            const SizedBox(height: AppDimens.paddingM),
            _buildTagInput(
              controller: _newAmenityCtrl,
              items: _amenities,
              hint: 'Ex: Climatisation, Terrasse, Bar...',
              onAdd: (v) => setState(() => _amenities.add(v)),
              onRemove: (v) => setState(() => _amenities.remove(v)),
            ),
            const SizedBox(height: AppDimens.paddingL),
            _sectionTitle('Horaires d\'ouverture (optionnel)'),
            const SizedBox(height: AppDimens.paddingM),
            ..._days.map((day) => _buildDayRow(day)),
            const SizedBox(height: AppDimens.paddingXL),

            ElevatedButton(
              onPressed: _isSubmitting ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryGreen,
                foregroundColor: AppColors.white,
                padding:
                    const EdgeInsets.symmetric(vertical: AppDimens.paddingM),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppDimens.radiusM),
                ),
              ),
              child: _isSubmitting
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                          color: AppColors.white, strokeWidth: 2),
                    )
                  : const Text(
                      'Créer l\'établissement',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
            ),
            const SizedBox(height: AppDimens.paddingXL),
          ],
        ),
      ),
    );
  }

  Widget _buildTagInput({
    required TextEditingController controller,
    required List<String> items,
    required String hint,
    required void Function(String) onAdd,
    required void Function(String) onRemove,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                decoration: InputDecoration(
                  hintText: hint,
                  filled: true,
                  fillColor: AppColors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppDimens.radiusM),
                    borderSide: const BorderSide(color: AppColors.grey300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppDimens.radiusM),
                    borderSide: const BorderSide(color: AppColors.grey300),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppDimens.paddingM,
                    vertical: AppDimens.paddingS,
                  ),
                ),
                onSubmitted: (v) {
                  final val = v.trim();
                  if (val.isNotEmpty && !items.contains(val)) {
                    onAdd(val);
                    controller.clear();
                  }
                },
              ),
            ),
            const SizedBox(width: AppDimens.paddingS),
            IconButton(
              icon:
                  const Icon(Iconsax.add_square, color: AppColors.primaryGreen),
              onPressed: () {
                final val = controller.text.trim();
                if (val.isNotEmpty && !items.contains(val)) {
                  onAdd(val);
                  controller.clear();
                }
              },
            ),
          ],
        ),
        if (items.isNotEmpty) ...[
          const SizedBox(height: AppDimens.paddingS),
          Wrap(
            spacing: AppDimens.paddingS,
            runSpacing: AppDimens.paddingXS,
            children: items
                .map((item) => Chip(
                      label: Text(item, style: const TextStyle(fontSize: 12)),
                      deleteIcon: const Icon(Iconsax.close_circle, size: 14),
                      onDeleted: () => onRemove(item),
                      backgroundColor:
                          AppColors.primaryGreen.withValues(alpha: 0.08),
                      side: BorderSide(
                          color: AppColors.primaryGreen.withValues(alpha: 0.3)),
                    ))
                .toList(),
          ),
        ],
      ],
    );
  }

  Widget _buildDayRow(String day) {
    final isClosed = _dayClosed[day]!;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppDimens.paddingS),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              _dayLabels[day]!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w500,
                    color: AppColors.grey800,
                  ),
            ),
          ),
          Switch(
            value: !isClosed,
            onChanged: (v) => setState(() => _dayClosed[day] = !v),
            activeThumbColor: AppColors.primaryGreen,
          ),
          if (!isClosed) ...[
            Expanded(
              child: TextField(
                controller: _openCtrl[day],
                decoration: _hoursDecoration('Ouv.'),
                keyboardType: TextInputType.datetime,
              ),
            ),
            const SizedBox(width: AppDimens.paddingXS),
            Expanded(
              child: TextField(
                controller: _closeCtrl[day],
                decoration: _hoursDecoration('Ferm.'),
                keyboardType: TextInputType.datetime,
              ),
            ),
          ] else
            Expanded(
              child: Text(
                'Fermé',
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: AppColors.grey500),
              ),
            ),
        ],
      ),
    );
  }

  InputDecoration _hoursDecoration(String label) {
    return InputDecoration(
      labelText: label,
      hintText: '08:00',
      filled: true,
      fillColor: AppColors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppDimens.radiusS),
        borderSide: const BorderSide(color: AppColors.grey300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppDimens.radiusS),
        borderSide: const BorderSide(color: AppColors.grey300),
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppDimens.paddingS,
        vertical: AppDimens.paddingS,
      ),
      isDense: true,
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
            color: AppColors.primaryGreen,
          ),
    );
  }

  InputDecoration _dropdownDecoration(String label) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: AppColors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppDimens.radiusM),
        borderSide: const BorderSide(color: AppColors.grey300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppDimens.radiusM),
        borderSide: const BorderSide(color: AppColors.grey300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppDimens.radiusM),
        borderSide: const BorderSide(color: AppColors.primaryGreen, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(
          horizontal: AppDimens.paddingM, vertical: AppDimens.paddingM),
    );
  }
}
