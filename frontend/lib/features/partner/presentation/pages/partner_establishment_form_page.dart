import 'package:flutter/material.dart';
import 'package:win_app/core/l10n/l10n_extensions.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../app_router.dart';
import '../../../establishment/data/models/establishment_model.dart';
import '../../../home/data/models/category_model.dart';
import '../../../home/data/repositories/category_repository.dart';
import '../../data/repositories/partner_repository.dart';

class PartnerEstablishmentFormPage extends StatefulWidget {
  final String? establishmentId;

  const PartnerEstablishmentFormPage({super.key, this.establishmentId});

  bool get isEditing => establishmentId != null;

  @override
  State<PartnerEstablishmentFormPage> createState() =>
      _PartnerEstablishmentFormPageState();
}

class _PartnerEstablishmentFormPageState
    extends State<PartnerEstablishmentFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _partnerRepository = PartnerRepository();
  final _categoryRepository = CategoryRepository();
  final _wilayaRepository = WilayaRepository();

  // Controllers
  final _nameController = TextEditingController();
  final _nameArController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _descriptionArController = TextEditingController();
  final _addressController = TextEditingController();
  final _addressArController = TextEditingController();
  final _phoneController = TextEditingController();
  final _phoneSecondaryController = TextEditingController();
  final _whatsappController = TextEditingController();
  final _emailController = TextEditingController();
  final _websiteController = TextEditingController();
  final _facebookController = TextEditingController();
  final _instagramController = TextEditingController();
  final _tiktokController = TextEditingController();
  final _snapchatController = TextEditingController();
  final _latitudeController = TextEditingController();
  final _longitudeController = TextEditingController();
  final _contactFirstNameController = TextEditingController();
  final _contactLastNameController = TextEditingController();
  final _contactPhoneController = TextEditingController();
  final _contactEmailController = TextEditingController();
  final _contactPositionController = TextEditingController();

  // Services & amenities
  final List<String> _services = [];
  final List<String> _amenities = [];
  final _newServiceCtrl = TextEditingController();
  final _newAmenityCtrl = TextEditingController();

  // Opening hours
  static const _days = [
    'monday', 'tuesday', 'wednesday', 'thursday',
    'friday', 'saturday', 'sunday',
  ];
  Map<String, String> _getDayLabels(BuildContext context) => {
    'monday': context.l10n.monday,
    'tuesday': context.l10n.tuesday,
    'wednesday': context.l10n.wednesday,
    'thursday': context.l10n.thursday,
    'friday': context.l10n.friday,
    'saturday': context.l10n.saturday,
    'sunday': context.l10n.sunday,
  };
  late final Map<String, bool> _dayClosed;
  late final Map<String, bool> _hasPause;
  late final Map<String, TextEditingController> _openCtrl;
  late final Map<String, TextEditingController> _closeCtrl;
  late final Map<String, TextEditingController> _pauseStartCtrl;
  late final Map<String, TextEditingController> _pauseEndCtrl;

  // State
  bool _isLoading = false;
  bool _isLoadingData = true;
  Establishment? _establishment;

  List<Category> _categories = [];
  List<SubCategory> _subcategories = [];
  List<Wilaya> _wilayas = [];
  List<Commune> _communes = [];

  String? _selectedCategoryId;
  String? _selectedSubcategoryId;
  String? _selectedWilayaId;
  String? _selectedCommuneId;
  String? _selectedPriceRange;

  File? _selectedLogo;
  File? _selectedCover;
  final List<File> _selectedImages = [];

  // Track existing images
  List<String> _existingGalleryImages = [];
  bool _logoDeleted = false;
  bool _coverDeleted = false;
  final List<String> _deletedGalleryImages = [];

  int _currentStep = 0;

  @override
  void initState() {
    super.initState();
    _dayClosed = {for (final d in _days) d: false};
    _hasPause = {for (final d in _days) d: false};
    _openCtrl = {for (final d in _days) d: TextEditingController()};
    _closeCtrl = {for (final d in _days) d: TextEditingController()};
    _pauseStartCtrl = {for (final d in _days) d: TextEditingController()};
    _pauseEndCtrl = {for (final d in _days) d: TextEditingController()};
    _loadInitialData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _nameArController.dispose();
    _descriptionController.dispose();
    _descriptionArController.dispose();
    _addressController.dispose();
    _addressArController.dispose();
    _phoneController.dispose();
    _phoneSecondaryController.dispose();
    _whatsappController.dispose();
    _emailController.dispose();
    _websiteController.dispose();
    _facebookController.dispose();
    _instagramController.dispose();
    _tiktokController.dispose();
    _snapchatController.dispose();
    _latitudeController.dispose();
    _longitudeController.dispose();
    _contactFirstNameController.dispose();
    _contactLastNameController.dispose();
    _contactPhoneController.dispose();
    _contactEmailController.dispose();
    _contactPositionController.dispose();
    _newServiceCtrl.dispose();
    _newAmenityCtrl.dispose();
    for (final d in _days) {
      _openCtrl[d]!.dispose();
      _closeCtrl[d]!.dispose();
      _pauseStartCtrl[d]!.dispose();
      _pauseEndCtrl[d]!.dispose();
    }
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    try {
      final futures = await Future.wait([
        _categoryRepository.getAll(),
        _wilayaRepository.getAll(),
        if (widget.isEditing)
          _partnerRepository.getEstablishmentById(widget.establishmentId!),
      ]);

      _categories = futures[0] as List<Category>;
      _wilayas = futures[1] as List<Wilaya>;

      if (widget.isEditing && futures.length > 2) {
        _establishment = futures[2] as Establishment;
        _populateForm(_establishment!);
      }

      setState(() {
        _isLoadingData = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingData = false;
      });
    }
  }

  void _populateForm(Establishment establishment) {
    _nameController.text = establishment.name;
    _nameArController.text = establishment.nameAr ?? '';
    _descriptionController.text = establishment.description ?? '';
    _descriptionArController.text = establishment.descriptionAr ?? '';
    _addressController.text = establishment.address;
    _addressArController.text = establishment.addressAr ?? '';
    _phoneController.text = establishment.phone;
    _phoneSecondaryController.text = establishment.phoneSecondary ?? '';
    _whatsappController.text = establishment.whatsapp ?? '';
    _emailController.text = establishment.email ?? '';
    _websiteController.text = establishment.website ?? '';
    _facebookController.text = establishment.facebook ?? '';
    _instagramController.text = establishment.instagram ?? '';
    _tiktokController.text = establishment.tiktok ?? '';
    _snapchatController.text = establishment.snapchat ?? '';
    _latitudeController.text = establishment.latitude?.toString() ?? '';
    _longitudeController.text = establishment.longitude?.toString() ?? '';
    _contactFirstNameController.text = establishment.contactFirstName ?? '';
    _contactLastNameController.text = establishment.contactLastName ?? '';
    _contactPhoneController.text = establishment.contactPhone ?? '';
    _contactEmailController.text = establishment.contactEmail ?? '';
    _contactPositionController.text = establishment.contactPosition ?? '';

    _selectedCategoryId = establishment.category?.id;
    _selectedSubcategoryId = establishment.subcategory?.id;
    _selectedWilayaId = establishment.wilaya?.id;
    _selectedCommuneId = establishment.commune?.id;
    _selectedPriceRange = establishment.priceRange;

    if (_selectedCategoryId != null) {
      _loadSubcategories(_selectedCategoryId!);
    }
    if (_selectedWilayaId != null) {
      _loadCommunes(_selectedWilayaId!);
    }

    // Opening hours
    if (establishment.openingHours != null) {
      for (final day in _days) {
        final hours = establishment.openingHours![day];
        if (hours != null) {
          _dayClosed[day] = false;
          _openCtrl[day]!.text = (hours['open'] ?? '').toString();
          _closeCtrl[day]!.text = (hours['close'] ?? '').toString();
          if (hours['break_start'] != null || hours['break_end'] != null) {
            _hasPause[day] = true;
            _pauseStartCtrl[day]!.text = (hours['break_start'] ?? '').toString();
            _pauseEndCtrl[day]!.text = (hours['break_end'] ?? '').toString();
          }
        } else {
          _dayClosed[day] = true;
        }
      }
    }
    // Services & amenities
    if (establishment.services != null) {
      _services.addAll(establishment.services!);
    }
    if (establishment.amenities != null) {
      _amenities.addAll(establishment.amenities!);
    }

    // Initialize existing images
    _existingGalleryImages =
        (establishment.images ?? []).map((p) => p.url).toList();
  }

  Future<void> _loadSubcategories(String categoryId) async {
    try {
      final subcategories =
          await _categoryRepository.getSubcategories(categoryId);
      setState(() {
        _subcategories = subcategories;
      });
    } catch (e) {
      // Handle error silently
    }
  }

  Future<void> _loadCommunes(String wilayaId) async {
    try {
      final communes = await _wilayaRepository.getCommunes(wilayaId);
      setState(() {
        _communes = communes;
      });
    } catch (e) {
      // Handle error silently
    }
  }

  Future<void> _pickImage(ImageSource source, String type) async {
    final picker = ImagePicker();
    if (type == 'images') {
      final images = await picker.pickMultiImage();
      if (images.isNotEmpty) {
        setState(() {
          _selectedImages.addAll(images.map((e) => File(e.path)));
        });
      }
    } else {
      final image = await picker.pickImage(source: source);
      if (image != null) {
        setState(() {
          if (type == 'logo') {
            _selectedLogo = File(image.path);
          } else if (type == 'cover') {
            _selectedCover = File(image.path);
          }
        });
      }
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final data = {
        'name': _nameController.text.trim(),
        if (_nameArController.text.isNotEmpty)
          'name_ar': _nameArController.text.trim(),
        if (_descriptionController.text.isNotEmpty)
          'description': _descriptionController.text.trim(),
        if (_descriptionArController.text.isNotEmpty)
          'description_ar': _descriptionArController.text.trim(),
        'address': _addressController.text.trim(),
        if (_addressArController.text.isNotEmpty)
          'address_ar': _addressArController.text.trim(),
        'phone': _phoneController.text.trim(),
        if (_phoneSecondaryController.text.isNotEmpty)
          'phone_secondary': _phoneSecondaryController.text.trim(),
        if (_whatsappController.text.isNotEmpty)
          'whatsapp': _whatsappController.text.trim(),
        if (_emailController.text.isNotEmpty)
          'email': _emailController.text.trim(),
        if (_websiteController.text.isNotEmpty)
          'website': _websiteController.text.trim(),
        if (_facebookController.text.isNotEmpty)
          'facebook': _facebookController.text.trim(),
        if (_instagramController.text.isNotEmpty)
          'instagram': _instagramController.text.trim(),
        if (_tiktokController.text.isNotEmpty)
          'tiktok': _tiktokController.text.trim(),
        if (_snapchatController.text.isNotEmpty)
          'snapchat': _snapchatController.text.trim(),
        if (_latitudeController.text.isNotEmpty)
          'latitude': double.tryParse(_latitudeController.text),
        if (_longitudeController.text.isNotEmpty)
          'longitude': double.tryParse(_longitudeController.text),
        if (_selectedCategoryId != null) 'category_id': _selectedCategoryId,
        if (_selectedSubcategoryId != null)
          'subcategory_id': _selectedSubcategoryId,
        if (_selectedWilayaId != null) 'wilaya_id': _selectedWilayaId,
        if (_selectedCommuneId != null) 'commune_id': _selectedCommuneId,
        if (_selectedPriceRange != null) 'price_range': _selectedPriceRange,
        if (_contactFirstNameController.text.isNotEmpty)
          'contact_first_name': _contactFirstNameController.text.trim(),
        if (_contactLastNameController.text.isNotEmpty)
          'contact_last_name': _contactLastNameController.text.trim(),
        if (_contactPhoneController.text.isNotEmpty)
          'contact_phone': _contactPhoneController.text.trim(),
        if (_contactEmailController.text.isNotEmpty)
          'contact_email': _contactEmailController.text.trim(),
        if (_contactPositionController.text.isNotEmpty)
          'contact_position': _contactPositionController.text.trim(),
        if (_services.isNotEmpty) 'services': _services,
        if (_amenities.isNotEmpty) 'amenities': _amenities,
        if (_buildOpeningHours().isNotEmpty)
          'opening_hours': _buildOpeningHours(),
      };

      Establishment result;

      if (widget.isEditing) {
        result = await _partnerRepository.updateEstablishment(
          widget.establishmentId!,
          data,
        );
      } else {
        result = await _partnerRepository.createEstablishment(data);
      }

      // Handle logo
      if (_logoDeleted && widget.isEditing) {
        await _partnerRepository.deleteLogo(result.id);
      } else if (_selectedLogo != null) {
        await _partnerRepository.uploadLogo(result.id, _selectedLogo!.path);
      }

      // Handle cover
      if (_coverDeleted && widget.isEditing) {
        await _partnerRepository.deleteCover(result.id);
      } else if (_selectedCover != null) {
        await _partnerRepository.uploadCover(result.id, _selectedCover!.path);
      }

      // Upload new gallery images
      if (_selectedImages.isNotEmpty) {
        await _partnerRepository.uploadGalleryImages(
          result.id,
          _selectedImages.map((f) => f.path).toList(),
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.isEditing
                ? context.l10n.establishmentUpdated
                : context.l10n.establishmentCreated),
            backgroundColor: AppColors.success,
          ),
        );
        context.go(AppRoutes.partnerEstablishments);
      }
    } catch (e) {
      if (mounted) {
        _showErrorDialog(_translateError(e.toString()));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<bool> _onWillPop() async {
    final shouldPop = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.l10n.cancelQuestion),
        content: Text(context.l10n.cancelConfirmBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(context.l10n.noContinue),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: AppColors.white,
            ),
            child: Text(context.l10n.yesCancel),
          ),
        ],
      ),
    );
    return shouldPop ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldPop = await _onWillPop();
        if (shouldPop && context.mounted) {
          context.go(AppRoutes.partnerEstablishments);
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.grey50,
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Iconsax.arrow_left),
            onPressed: () async {
              final shouldPop = await _onWillPop();
              if (shouldPop && context.mounted) {
                context.go(AppRoutes.partnerEstablishments);
              }
            },
          ),
          title: Text(widget.isEditing
              ? context.l10n.editEstablishment
              : context.l10n.newEstablishment),
          backgroundColor: AppColors.scaffoldBackground,
          foregroundColor: AppColors.white,
          elevation: 0,
        ),
        body: _isLoadingData
            ? const Center(
                child: CircularProgressIndicator(color: AppColors.primaryGreen))
            : _buildForm(),
      ),
    );
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          // Step Indicators
          _buildStepIndicators(),
          // Form Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppDimens.paddingM),
              child: _buildCurrentStep(),
            ),
          ),
          // Bottom Navigation
          _buildBottomNavigation(),
        ],
      ),
    );
  }

  Widget _buildStepIndicators() {
    final steps = [
      context.l10n.stepGeneral,
      context.l10n.stepLocation,
      context.l10n.contact,
      context.l10n.stepDetails,
      context.l10n.stepImages,
    ];
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimens.paddingM,
        vertical: AppDimens.paddingS,
      ),
      color: AppColors.white,
      child: Row(
        children: List.generate(steps.length, (index) {
          final isActive = index == _currentStep;
          final isCompleted = index < _currentStep;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _currentStep = index),
              child: Column(
                children: [
                  Row(
                    children: [
                      if (index > 0)
                        Expanded(
                          child: Container(
                            height: 2,
                            color: isCompleted || isActive
                                ? AppColors.primaryGreen
                                : AppColors.grey300,
                          ),
                        ),
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: isCompleted
                              ? AppColors.primaryGreen
                              : isActive
                                  ? AppColors.primaryGreen
                                      .withValues(alpha: 0.2)
                                  : AppColors.grey200,
                          shape: BoxShape.circle,
                          border: isActive
                              ? Border.all(
                                  color: AppColors.primaryGreen, width: 2)
                              : null,
                        ),
                        child: Center(
                          child: isCompleted
                              ? const Icon(Icons.check,
                                  color: AppColors.white, size: 16)
                              : Text(
                                  '${index + 1}',
                                  style: TextStyle(
                                    color: isActive
                                        ? AppColors.primaryGreen
                                        : AppColors.grey600,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12,
                                  ),
                                ),
                        ),
                      ),
                      if (index < steps.length - 1)
                        Expanded(
                          child: Container(
                            height: 2,
                            color: isCompleted
                                ? AppColors.primaryGreen
                                : AppColors.grey300,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: AppDimens.paddingXS),
                  Text(
                    steps[index],
                    style: TextStyle(
                      fontSize: 11,
                      color:
                          isActive ? AppColors.primaryGreen : AppColors.grey600,
                      fontWeight:
                          isActive ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildCurrentStep() {
    switch (_currentStep) {
      case 0:
        return _buildGeneralInfoStep();
      case 1:
        return _buildLocationStep();
      case 2:
        return _buildContactStep();
      case 3:
        return _buildDetailsStep();
      case 4:
        return _buildImagesStep();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildBottomNavigation() {
    return Container(
      padding: const EdgeInsets.all(AppDimens.paddingM),
      decoration: BoxDecoration(
        color: AppColors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            if (_currentStep > 0)
              Expanded(
                child: OutlinedButton(
                  onPressed:
                      _isLoading ? null : () => setState(() => _currentStep--),
                  child: Text(context.l10n.previous),
                ),
              ),
            if (_currentStep > 0) const SizedBox(width: AppDimens.paddingM),
            Expanded(
              flex: _currentStep > 0 ? 1 : 2,
              child: ElevatedButton(
                onPressed: _isLoading
                    ? null
                    : () {
                        if (_currentStep < 4) {
                          setState(() => _currentStep++);
                        } else {
                          _submitForm();
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.scaffoldBackground,
                  foregroundColor: AppColors.white,
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
                    : Text(_currentStep == 4 ? context.l10n.save : context.l10n.next),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.error_outline, color: AppColors.error),
            const SizedBox(width: 8),
            Text(context.l10n.error),
          ],
        ),
        content: Text(message),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryGreen,
              foregroundColor: AppColors.white,
            ),
            child: Text(context.l10n.ok),
          ),
        ],
      ),
    );
  }

  String _translateError(String error) {
    final e = error.toLowerCase();
    if (e.contains('phone') || e.contains('numéro')) {
      return context.l10n.errorInvalidPhone;
    }
    if (e.contains('name') || e.contains('nom')) {
      return context.l10n.errorInvalidEstablishmentName;
    }
    if (e.contains('address') || e.contains('adresse')) {
      return context.l10n.errorInvalidAddress;
    }
    if (e.contains('category') || e.contains('catégorie')) {
      return context.l10n.errorSelectCategory;
    }
    if (e.contains('wilaya')) {
      return context.l10n.errorSelectWilaya;
    }
    if (e.contains('email')) {
      return context.l10n.errorInvalidEmail;
    }
    if (e.contains('url') || e.contains('website') || e.contains('facebook')) {
      return context.l10n.errorInvalidUrl;
    }
    if (e.contains('unauthorized') || e.contains('401')) {
      return context.l10n.errorSessionExpired;
    }
    if (e.contains('network') ||
        e.contains('connection') ||
        e.contains('socket')) {
      return context.l10n.errorNetworkConnection;
    }
    if (e.contains('500') || e.contains('server')) {
      return context.l10n.serverError;
    }
    return context.l10n.genericError;
  }

  Widget _buildGeneralInfoStep() {
    return Column(
      children: [
        _buildTextField(
          controller: _nameController,
          label: context.l10n.establishmentNameLabel,
          icon: Iconsax.building,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return context.l10n.nameRequired;
            }
            return null;
          },
        ),
        const SizedBox(height: AppDimens.paddingM),
        _buildTextField(
          controller: _nameArController,
          label: context.l10n.nameAr,
          icon: Iconsax.translate,
        ),
        const SizedBox(height: AppDimens.paddingM),
        _buildTextField(
          controller: _descriptionController,
          label: context.l10n.descriptionLabel,
          icon: Iconsax.document_text,
          maxLines: 4,
        ),
        const SizedBox(height: AppDimens.paddingM),
        _buildTextField(
          controller: _descriptionArController,
          label: context.l10n.descriptionAr,
          icon: Iconsax.translate,
          maxLines: 4,
        ),
        const SizedBox(height: AppDimens.paddingM),
        _buildDropdown<Category>(
          value:
              _categories.where((c) => c.id == _selectedCategoryId).firstOrNull,
          items: _categories,
          label: context.l10n.categoryRequired,
          icon: Iconsax.category,
          itemBuilder: (category) => category.name,
          itemTextColor: AppColors.white,
          selectedTextColor: AppColors.primaryBlue,
          onChanged: (category) {
            setState(() {
              _selectedCategoryId = category?.id;
              _selectedSubcategoryId = null;
              _subcategories = [];
            });
            if (category != null) {
              _loadSubcategories(category.id);
            }
          },
        ),
        if (_subcategories.isNotEmpty) ...[
          const SizedBox(height: AppDimens.paddingM),
          _buildDropdown<SubCategory>(
            value: _subcategories
                .where((s) => s.id == _selectedSubcategoryId)
                .firstOrNull,
            items: _subcategories,
            label: context.l10n.subcategoryLabel,
            icon: Iconsax.category_2,
            itemBuilder: (subcategory) => subcategory.name,
            itemTextColor: AppColors.white,
            selectedTextColor: AppColors.primaryBlue,
            onChanged: (subcategory) {
              setState(() {
                _selectedSubcategoryId = subcategory?.id;
              });
            },
          ),
        ],
        const SizedBox(height: AppDimens.paddingM),
        _buildDropdown<String>(
          value: _selectedPriceRange,
          items: const ['\$', '\$\$', '\$\$\$', '\$\$\$\$'],
          label: context.l10n.priceRange,
          icon: Iconsax.dollar_circle,
          itemTextColor: AppColors.white,
          selectedTextColor: AppColors.primaryBlue,
          itemBuilder: (price) {
            switch (price) {
              case '\$':
                return context.l10n.priceEconomy;
              case '\$\$':
                return context.l10n.priceModerate;
              case '\$\$\$':
                return context.l10n.priceHigh;
              case '\$\$\$\$':
                return context.l10n.priceLuxury;
              default:
                return price;
            }
          },
          onChanged: (price) {
            setState(() {
              _selectedPriceRange = price;
            });
          },
        ),
      ],
    );
  }

  Widget _buildLocationStep() {
    return Column(
      children: [
        _buildDropdown<Wilaya>(
          value: _wilayas.where((w) => w.id == _selectedWilayaId).firstOrNull,
          items: _wilayas,
          label: context.l10n.wilayaRequired,
          icon: Iconsax.location,
          itemBuilder: (wilaya) => '${wilaya.code} - ${wilaya.name}',
          itemTextColor: AppColors.white,
          selectedTextColor: AppColors.primaryBlue,
          onChanged: (wilaya) {
            setState(() {
              _selectedWilayaId = wilaya?.id;
              _selectedCommuneId = null;
              _communes = [];
            });
            if (wilaya != null) {
              _loadCommunes(wilaya.id);
            }
          },
        ),
        if (_communes.isNotEmpty) ...[
          const SizedBox(height: AppDimens.paddingM),
          _buildDropdown<Commune>(
            value:
                _communes.where((c) => c.id == _selectedCommuneId).firstOrNull,
            items: _communes,
            label: context.l10n.communeLabel,
            icon: Iconsax.building_3,
            itemBuilder: (commune) => commune.name,
            itemTextColor: AppColors.white,
            selectedTextColor: AppColors.primaryBlue,
            onChanged: (commune) {
              setState(() {
                _selectedCommuneId = commune?.id;
              });
            },
          ),
        ],
        const SizedBox(height: AppDimens.paddingM),
        _buildTextField(
          controller: _addressController,
          label: context.l10n.addressLabel,
          icon: Iconsax.location,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return context.l10n.addressRequired;
            }
            return null;
          },
        ),
        const SizedBox(height: AppDimens.paddingM),
        _buildTextField(
          controller: _addressArController,
          label: context.l10n.addressAr,
          icon: Iconsax.translate,
        ),
        const SizedBox(height: AppDimens.paddingM),
        Row(
          children: [
            Expanded(
              child: _buildTextField(
                controller: _latitudeController,
                label: context.l10n.latitudeLabel,
                icon: Iconsax.global,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
              ),
            ),
            const SizedBox(width: AppDimens.paddingM),
            Expanded(
              child: _buildTextField(
                controller: _longitudeController,
                label: context.l10n.longitudeLabel,
                icon: Iconsax.global,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildContactStep() {
    return Column(
      children: [
        _buildTextField(
          controller: _phoneController,
          label: '${context.l10n.phone} *',
          icon: Iconsax.call,
          keyboardType: TextInputType.phone,
          hintText: 'Ex: 0555123456 ou +213555123456',
          validator: (value) {
            if (value == null || value.isEmpty) {
              return context.l10n.phoneRequired;
            }
            final cleaned = value.replaceAll(RegExp(r'[\s\-().+]'), '');
            if (cleaned.length < 6) {
              return context.l10n.phoneTooShort;
            }
            return null;
          },
        ),
        const SizedBox(height: AppDimens.paddingM),
        _buildTextField(
          controller: _phoneSecondaryController,
          label: context.l10n.secondaryPhone,
          icon: Iconsax.call,
          keyboardType: TextInputType.phone,
          hintText: 'Ex: 0770123456',
        ),
        const SizedBox(height: AppDimens.paddingM),
        _buildTextField(
          controller: _whatsappController,
          label: 'WhatsApp',
          icon: Iconsax.message,
          keyboardType: TextInputType.phone,
          hintText: 'Ex: 0555123456 ou +213555123456',
        ),
        const SizedBox(height: AppDimens.paddingM),
        _buildTextField(
          controller: _emailController,
          label: 'Email',
          icon: Iconsax.sms,
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: AppDimens.paddingM),
        _buildTextField(
          controller: _websiteController,
          label: context.l10n.websiteLabel,
          icon: Iconsax.global,
          keyboardType: TextInputType.url,
        ),
        const SizedBox(height: AppDimens.paddingL),
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            context.l10n.socialNetworks,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: AppColors.grey700,
            ),
          ),
        ),
        const SizedBox(height: AppDimens.paddingM),
        _buildTextField(
          controller: _facebookController,
          label: 'Facebook',
          icon: Iconsax.link,
          keyboardType: TextInputType.url,
        ),
        const SizedBox(height: AppDimens.paddingM),
        _buildTextField(
          controller: _instagramController,
          label: 'Instagram',
          icon: Iconsax.instagram,
          keyboardType: TextInputType.url,
        ),
        const SizedBox(height: AppDimens.paddingM),
        _buildTextField(
          controller: _tiktokController,
          label: 'TikTok',
          icon: Iconsax.video,
          keyboardType: TextInputType.url,
        ),
        const SizedBox(height: AppDimens.paddingM),
        _buildTextField(
          controller: _snapchatController,
          label: 'Snapchat',
          icon: Iconsax.ghost,
          keyboardType: TextInputType.text,
          hintText: 'Ex: mon.username',
        ),
        const SizedBox(height: AppDimens.paddingL),
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            context.l10n.interlocutorOptional,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: AppColors.grey700,
            ),
          ),
        ),
        const SizedBox(height: AppDimens.paddingXS),
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            context.l10n.contactPersonDesc,
            style: const TextStyle(fontSize: 12, color: AppColors.grey500),
          ),
        ),
        const SizedBox(height: AppDimens.paddingM),
        _buildTextField(
          controller: _contactFirstNameController,
          label: context.l10n.firstName,
          icon: Iconsax.user,
        ),
        const SizedBox(height: AppDimens.paddingM),
        _buildTextField(
          controller: _contactLastNameController,
          label: context.l10n.lastName,
          icon: Iconsax.user,
        ),
        const SizedBox(height: AppDimens.paddingM),
        _buildTextField(
          controller: _contactPhoneController,
          label: context.l10n.phone,
          icon: Iconsax.call,
          keyboardType: TextInputType.phone,
        ),
        const SizedBox(height: AppDimens.paddingM),
        _buildTextField(
          controller: _contactEmailController,
          label: 'Email',
          icon: Iconsax.sms,
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: AppDimens.paddingM),
        _buildTextField(
          controller: _contactPositionController,
          label: context.l10n.positionFunctionLabel,
          icon: Iconsax.briefcase,
          hintText: 'Ex: Directeur, Responsable commercial...',
        ),
      ],
    );
  }

  Widget _buildImagesStep() {
    // Determine if we should show existing logo/cover (not deleted and exists)
    final showExistingLogo =
        !_logoDeleted && _establishment?.logo != null && _selectedLogo == null;
    final showExistingCover = !_coverDeleted &&
        _establishment?.coverImage != null &&
        _selectedCover == null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Logo',
          style:
              TextStyle(fontWeight: FontWeight.w600, color: AppColors.grey700),
        ),
        const SizedBox(height: AppDimens.paddingS),
        _buildImagePicker(
          selectedFile: _selectedLogo,
          existingUrl: showExistingLogo ? _establishment?.logo : null,
          onPick: () => _showImageSourceDialog('logo'),
          onRemove: () {
            setState(() {
              if (_selectedLogo != null) {
                _selectedLogo = null;
              } else if (_establishment?.logo != null) {
                _logoDeleted = true;
              }
            });
          },
          isSquare: true,
        ),
        const SizedBox(height: AppDimens.paddingL),
        Text(
          context.l10n.coverImageLabel,
          style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.grey700),
        ),
        const SizedBox(height: AppDimens.paddingS),
        _buildImagePicker(
          selectedFile: _selectedCover,
          existingUrl: showExistingCover ? _establishment?.coverImage : null,
          onPick: () => _showImageSourceDialog('cover'),
          onRemove: () {
            setState(() {
              if (_selectedCover != null) {
                _selectedCover = null;
              } else if (_establishment?.coverImage != null) {
                _coverDeleted = true;
              }
            });
          },
        ),
        const SizedBox(height: AppDimens.paddingL),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              context.l10n.imageGallery,
              style: const TextStyle(
                  fontWeight: FontWeight.w600, color: AppColors.grey700),
            ),
            TextButton.icon(
              onPressed: () => _pickImage(ImageSource.gallery, 'images'),
              icon: const Icon(Iconsax.add, size: 18),
              label: Text(context.l10n.add),
            ),
          ],
        ),
        const SizedBox(height: AppDimens.paddingS),
        if (_selectedImages.isEmpty && _existingGalleryImages.isEmpty)
          Container(
            height: 100,
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppColors.grey100,
              borderRadius: BorderRadius.circular(AppDimens.radiusM),
              border: Border.all(color: AppColors.grey300),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Iconsax.gallery, color: AppColors.grey400, size: 32),
                  const SizedBox(height: AppDimens.paddingXS),
                  Text(
                    context.l10n.noImage,
                    style: const TextStyle(color: AppColors.grey500, fontSize: 12),
                  ),
                ],
              ),
            ),
          )
        else
          Wrap(
            spacing: AppDimens.paddingS,
            runSpacing: AppDimens.paddingS,
            children: [
              ..._existingGalleryImages.map((url) => _buildImageTile(
                    imageUrl: url,
                    onRemove: () => _confirmDeleteGalleryImage(url),
                  )),
              ..._selectedImages.map((file) => _buildImageTile(
                    file: file,
                    onRemove: () {
                      setState(() {
                        _selectedImages.remove(file);
                      });
                    },
                  )),
            ],
          ),
      ],
    );
  }

  Future<void> _confirmDeleteGalleryImage(String imageUrl) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.l10n.deleteImageTitle),
        content: Text(context.l10n.irreversibleAction),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(context.l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: AppColors.white,
            ),
            child: Text(context.l10n.delete),
          ),
        ],
      ),
    );

    if (confirmed == true && widget.establishmentId != null) {
      try {
        await _partnerRepository.deleteGalleryImage(
          widget.establishmentId!,
          imageUrl,
        );
        setState(() {
          _existingGalleryImages.remove(imageUrl);
          _deletedGalleryImages.add(imageUrl);
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(context.l10n.imageDeleted),
              backgroundColor: AppColors.success,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erreur: ${e.toString()}'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }
  }

  Map<String, Map<String, String>> _buildOpeningHours() {
    final result = <String, Map<String, String>>{};
    for (final day in _days) {
      if (!_dayClosed[day]! && _openCtrl[day]!.text.isNotEmpty) {
        if (_hasPause[day]!) {
          result[day] = {
            'open': _openCtrl[day]!.text,
            'break_start': _pauseStartCtrl[day]!.text,
            'break_end': _pauseEndCtrl[day]!.text,
            'close': _closeCtrl[day]!.text,
          };
        } else {
          result[day] = {
            'open': _openCtrl[day]!.text,
            'close': _closeCtrl[day]!.text,
          };
        }
      }
    }
    return result;
  }

  Widget _buildDetailsStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle(context.l10n.servicesOptional),
        const SizedBox(height: AppDimens.paddingXS),
        Text(
          'Ex : WiFi, Parking, Livraison, Réservation...',
          style: TextStyle(fontSize: 12, color: AppColors.grey500),
        ),
        const SizedBox(height: AppDimens.paddingM),
        _buildTagInput(
          controller: _newServiceCtrl,
          items: _services,
          hint: context.l10n.addService,
          onAdd: (v) => setState(() => _services.add(v)),
          onRemove: (v) => setState(() => _services.remove(v)),
        ),
        const SizedBox(height: AppDimens.paddingL),
        _sectionTitle(context.l10n.amenitiesOptional),
        const SizedBox(height: AppDimens.paddingXS),
        Text(
          'Ex : Climatisation, Terrasse, Bar, Salle de prière...',
          style: TextStyle(fontSize: 12, color: AppColors.grey500),
        ),
        const SizedBox(height: AppDimens.paddingM),
        _buildTagInput(
          controller: _newAmenityCtrl,
          items: _amenities,
          hint: context.l10n.addAmenity,
          onAdd: (v) => setState(() => _amenities.add(v)),
          onRemove: (v) => setState(() => _amenities.remove(v)),
        ),
        const SizedBox(height: AppDimens.paddingL),
        _sectionTitle(context.l10n.openingHoursOptional),
        const SizedBox(height: AppDimens.paddingXS),
        Text(
          'Activez "Pause" pour saisir des horaires matin / après-midi',
          style: TextStyle(fontSize: 12, color: AppColors.grey500),
        ),
        const SizedBox(height: AppDimens.paddingM),
        ..._days.map((day) => _buildDayRow(day)),
        const SizedBox(height: AppDimens.paddingL),
      ],
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontWeight: FontWeight.w700,
        fontSize: 14,
        color: AppColors.primaryGreen,
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
                style: const TextStyle(color: AppColors.scaffoldBackground),
                decoration: InputDecoration(
                  hintText: hint,
                  hintStyle: const TextStyle(
                      color: AppColors.grey500, fontSize: 13),
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
                    borderSide: const BorderSide(
                        color: AppColors.primaryGreen, width: 2),
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
              icon: const Icon(Iconsax.add_square,
                  color: AppColors.primaryGreen),
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
                      label: Text(item,
                          style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.scaffoldBackground)),
                      deleteIcon:
                          const Icon(Iconsax.close_circle, size: 14),
                      onDeleted: () => onRemove(item),
                      backgroundColor:
                          AppColors.primaryGreen.withValues(alpha: 0.08),
                      side: BorderSide(
                          color:
                              AppColors.primaryGreen.withValues(alpha: 0.3)),
                    ))
                .toList(),
          ),
        ],
      ],
    );
  }

  Widget _buildDayRow(String day) {
    final isClosed = _dayClosed[day]!;
    final hasPause = _hasPause[day]!;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppDimens.paddingS),
      child: Container(
        padding: const EdgeInsets.all(AppDimens.paddingS),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(AppDimens.radiusM),
          border: Border.all(color: AppColors.grey200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header: label + switch + badge pause ──
            Row(
              children: [
                SizedBox(
                  width: 78,
                  child: Text(
                    _getDayLabels(context)[day]!,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color: AppColors.scaffoldBackground,
                    ),
                  ),
                ),
                Switch(
                  value: !isClosed,
                  onChanged: (v) => setState(() => _dayClosed[day] = !v),
                  activeTrackColor: AppColors.primaryGreen,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                if (!isClosed) ...[
                  const Spacer(),
                  GestureDetector(
                    onTap: () => setState(() => _hasPause[day] = !hasPause),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: hasPause
                            ? AppColors.accentOrange.withValues(alpha: 0.1)
                            : AppColors.scaffoldBackground
                                .withValues(alpha: 0.07),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: hasPause
                              ? AppColors.accentOrange.withValues(alpha: 0.5)
                              : AppColors.scaffoldBackground
                                  .withValues(alpha: 0.25),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            hasPause
                                ? Icons.coffee_outlined
                                : Icons.add_rounded,
                            size: 13,
                            color: hasPause
                                ? AppColors.accentOrange
                                : AppColors.scaffoldBackground,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            hasPause ? 'Pause déj.' : 'Pause',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: hasPause
                                  ? AppColors.accentOrange
                                  : AppColors.scaffoldBackground,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
                if (isClosed) ...[
                  const SizedBox(width: 4),
                  Text(
                    context.l10n.closed,
                    style: const TextStyle(
                        color: AppColors.grey400,
                        fontSize: 13,
                        fontStyle: FontStyle.italic),
                  ),
                ],
              ],
            ),

            // ── Time fields ──
            if (!isClosed) ...[
              const SizedBox(height: 8),
              if (!hasPause)
                _buildTimeRow(
                  leftCtrl: _openCtrl[day]!,
                  leftLabel: context.l10n.openAbbrev,
                  leftHint: '08:00',
                  rightCtrl: _closeCtrl[day]!,
                  rightLabel: context.l10n.closeAbbrev,
                  rightHint: '18:00',
                )
              else ...[
                // Matin
                Row(
                  children: [
                    SizedBox(
                      width: 52,
                      child: Text(
                        'Matin',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color:
                              AppColors.scaffoldBackground.withValues(alpha: 0.6),
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: _buildTimeRow(
                        leftCtrl: _openCtrl[day]!,
                        leftLabel: context.l10n.openAbbrev,
                        leftHint: '08:00',
                        rightCtrl: _pauseStartCtrl[day]!,
                        rightLabel: 'Pause',
                        rightHint: '12:00',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                // Après-midi
                Row(
                  children: [
                    SizedBox(
                      width: 52,
                      child: Text(
                        'A-midi',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color:
                              AppColors.scaffoldBackground.withValues(alpha: 0.6),
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: _buildTimeRow(
                        leftCtrl: _pauseEndCtrl[day]!,
                        leftLabel: 'Reprise',
                        leftHint: '14:00',
                        rightCtrl: _closeCtrl[day]!,
                        rightLabel: context.l10n.closeAbbrev,
                        rightHint: '18:00',
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTimeRow({
    required TextEditingController leftCtrl,
    required String leftLabel,
    required String leftHint,
    required TextEditingController rightCtrl,
    required String rightLabel,
    required String rightHint,
  }) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: leftCtrl,
            style: const TextStyle(
              color: AppColors.scaffoldBackground,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
            decoration: _hoursDecoration(leftLabel, leftHint),
            keyboardType: TextInputType.datetime,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: Icon(Icons.arrow_forward_rounded,
              size: 14, color: AppColors.grey300),
        ),
        Expanded(
          child: TextField(
            controller: rightCtrl,
            style: const TextStyle(
              color: AppColors.scaffoldBackground,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
            decoration: _hoursDecoration(rightLabel, rightHint),
            keyboardType: TextInputType.datetime,
          ),
        ),
      ],
    );
  }

  InputDecoration _hoursDecoration(String label, [String hint = '00:00']) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(
        color: AppColors.scaffoldBackground,
        fontSize: 11,
        fontWeight: FontWeight.w500,
      ),
      hintText: hint,
      hintStyle: const TextStyle(color: AppColors.grey300, fontSize: 12),
      filled: true,
      fillColor: AppColors.grey50,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppDimens.radiusS),
        borderSide: const BorderSide(color: AppColors.grey200),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppDimens.radiusS),
        borderSide: const BorderSide(color: AppColors.grey200),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppDimens.radiusS),
        borderSide:
            const BorderSide(color: AppColors.primaryGreen, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppDimens.paddingS,
        vertical: AppDimens.paddingS,
      ),
      isDense: true,
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    String? hintText,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator: validator,
      style: const TextStyle(color: AppColors.scaffoldBackground),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          color: AppColors.scaffoldBackground.withValues(alpha: 0.75),
        ),
        hintText: hintText,
        hintStyle:
            const TextStyle(color: AppColors.scaffoldBackground, fontSize: 13),
        prefixIcon: Icon(icon, color: AppColors.scaffoldBackground),
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
        filled: true,
        fillColor: AppColors.white,
      ),
    );
  }

  Widget _buildDropdown<T>({
    required T? value,
    required List<T> items,
    required String label,
    required IconData icon,
    required String Function(T) itemBuilder,
    required void Function(T?) onChanged,
    Color itemTextColor = AppColors.scaffoldBackground,
    Color selectedTextColor = AppColors.scaffoldBackground,
  }) {
    return DropdownButtonFormField<T>(
      initialValue: value,
      style: TextStyle(color: selectedTextColor),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          color: AppColors.scaffoldBackground.withValues(alpha: 0.75),
        ),
        prefixIcon: Icon(icon, color: AppColors.scaffoldBackground),
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
        filled: true,
        fillColor: AppColors.white,
      ),
      selectedItemBuilder: (_) => items.map((item) {
        return Text(
          itemBuilder(item),
          style: TextStyle(color: selectedTextColor),
        );
      }).toList(),
      items: items.map((item) {
        return DropdownMenuItem<T>(
          value: item,
          child: Text(
            itemBuilder(item),
            style: TextStyle(color: itemTextColor),
          ),
        );
      }).toList(),
      onChanged: onChanged,
    );
  }

  Widget _buildImagePicker({
    File? selectedFile,
    String? existingUrl,
    required VoidCallback onPick,
    required VoidCallback onRemove,
    bool isSquare = false,
  }) {
    final hasImage = selectedFile != null || existingUrl != null;
    final size = isSquare ? 120.0 : 200.0;
    final height = isSquare ? 120.0 : 150.0;

    return Stack(
      children: [
        GestureDetector(
          onTap: onPick,
          child: Container(
            width: isSquare ? size : double.infinity,
            height: height,
            decoration: BoxDecoration(
              color: AppColors.grey100,
              borderRadius: BorderRadius.circular(AppDimens.radiusM),
              border: Border.all(color: AppColors.grey300),
              image: hasImage
                  ? DecorationImage(
                      image: selectedFile != null
                          ? FileImage(selectedFile)
                          : NetworkImage(existingUrl!) as ImageProvider,
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: !hasImage
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        isSquare ? Iconsax.gallery : Iconsax.image,
                        color: AppColors.grey400,
                        size: 40,
                      ),
                      const SizedBox(height: AppDimens.paddingS),
                      Text(
                        context.l10n.addImage,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.grey500,
                            ),
                      ),
                    ],
                  )
                : null,
          ),
        ),
        if (hasImage)
          Positioned(
            top: AppDimens.paddingXS,
            right: AppDimens.paddingXS,
            child: GestureDetector(
              onTap: onRemove,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: AppColors.error,
                  shape: BoxShape.circle,
                ),
                child:
                    const Icon(Icons.close, color: AppColors.white, size: 16),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildImageTile(
      {File? file, String? imageUrl, required VoidCallback onRemove}) {
    return Stack(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppDimens.radiusS),
            image: DecorationImage(
              image: file != null
                  ? FileImage(file)
                  : NetworkImage(imageUrl!) as ImageProvider,
              fit: BoxFit.cover,
            ),
          ),
        ),
        Positioned(
          top: 4,
          right: 4,
          child: GestureDetector(
            onTap: onRemove,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: const BoxDecoration(
                color: AppColors.error,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close, color: AppColors.white, size: 12),
            ),
          ),
        ),
      ],
    );
  }

  void _showImageSourceDialog(String type) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(AppDimens.radiusL)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppDimens.paddingL),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Iconsax.camera),
                title: Text(context.l10n.takePhoto),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera, type);
                },
              ),
              ListTile(
                leading: const Icon(Iconsax.gallery),
                title: Text(context.l10n.chooseFromGallery),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery, type);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
