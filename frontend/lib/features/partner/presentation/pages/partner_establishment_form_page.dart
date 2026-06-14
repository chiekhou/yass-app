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
                ? 'Établissement mis à jour'
                : 'Établissement créé avec succès'),
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
        title: const Text('Annuler ?'),
        content: const Text(
          'Êtes-vous sûr de vouloir annuler ? Les modifications non enregistrées seront perdues.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Non, continuer'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: AppColors.white,
            ),
            child: const Text('Oui, annuler'),
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
              ? 'Modifier l\'établissement'
              : 'Nouvel établissement'),
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
    final steps = ['Général', 'Lieu', 'Contact', 'Images'];
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
                  child: const Text('Précédent'),
                ),
              ),
            if (_currentStep > 0) const SizedBox(width: AppDimens.paddingM),
            Expanded(
              flex: _currentStep > 0 ? 1 : 2,
              child: ElevatedButton(
                onPressed: _isLoading
                    ? null
                    : () {
                        if (_currentStep < 3) {
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
                    : Text(_currentStep == 3 ? 'Enregistrer' : 'Suivant'),
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
        title: const Row(
          children: [
            Icon(Icons.error_outline, color: AppColors.error),
            SizedBox(width: 8),
            Text('Erreur'),
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
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  String _translateError(String error) {
    final e = error.toLowerCase();
    if (e.contains('phone') || e.contains('numéro')) {
      return 'Numéro de téléphone invalide. Formats acceptés : 0555123456, +213555123456, 0770 123 456';
    }
    if (e.contains('name') || e.contains('nom')) {
      return 'Le nom de l\'établissement est invalide.';
    }
    if (e.contains('address') || e.contains('adresse')) {
      return 'L\'adresse est invalide.';
    }
    if (e.contains('category') || e.contains('catégorie')) {
      return 'Veuillez sélectionner une catégorie.';
    }
    if (e.contains('wilaya')) {
      return 'Veuillez sélectionner une wilaya.';
    }
    if (e.contains('email')) {
      return 'Adresse e-mail invalide.';
    }
    if (e.contains('url') || e.contains('website') || e.contains('facebook')) {
      return 'L\'URL saisie est invalide.';
    }
    if (e.contains('unauthorized') || e.contains('401')) {
      return 'Session expirée. Veuillez vous reconnecter.';
    }
    if (e.contains('network') ||
        e.contains('connection') ||
        e.contains('socket')) {
      return 'Erreur de connexion. Vérifiez votre accès internet.';
    }
    if (e.contains('500') || e.contains('server')) {
      return 'Erreur serveur. Veuillez réessayer plus tard.';
    }
    return 'Une erreur est survenue. Veuillez réessayer.';
  }

  Widget _buildGeneralInfoStep() {
    return Column(
      children: [
        _buildTextField(
          controller: _nameController,
          label: 'Nom de l\'établissement *',
          icon: Iconsax.building,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Le nom est requis';
            }
            return null;
          },
        ),
        const SizedBox(height: AppDimens.paddingM),
        _buildTextField(
          controller: _nameArController,
          label: 'Nom en arabe',
          icon: Iconsax.translate,
        ),
        const SizedBox(height: AppDimens.paddingM),
        _buildTextField(
          controller: _descriptionController,
          label: 'Description',
          icon: Iconsax.document_text,
          maxLines: 4,
        ),
        const SizedBox(height: AppDimens.paddingM),
        _buildTextField(
          controller: _descriptionArController,
          label: 'Description en arabe',
          icon: Iconsax.translate,
          maxLines: 4,
        ),
        const SizedBox(height: AppDimens.paddingM),
        _buildDropdown<Category>(
          value:
              _categories.where((c) => c.id == _selectedCategoryId).firstOrNull,
          items: _categories,
          label: 'Catégorie *',
          icon: Iconsax.category,
          itemBuilder: (category) => category.name,
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
            label: 'Sous-catégorie',
            icon: Iconsax.category_2,
            itemBuilder: (subcategory) => subcategory.name,
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
          label: 'Gamme de prix',
          icon: Iconsax.dollar_circle,
          itemBuilder: (price) {
            switch (price) {
              case '\$':
                return 'Économique (\$)';
              case '\$\$':
                return 'Modéré (\$\$)';
              case '\$\$\$':
                return 'Élevé (\$\$\$)';
              case '\$\$\$\$':
                return 'Luxe (\$\$\$\$)';
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
          label: 'Wilaya *',
          icon: Iconsax.location,
          itemBuilder: (wilaya) => '${wilaya.code} - ${wilaya.name}',
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
            label: 'Commune',
            icon: Iconsax.building_3,
            itemBuilder: (commune) => commune.name,
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
          label: 'Adresse *',
          icon: Iconsax.location,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'L\'adresse est requise';
            }
            return null;
          },
        ),
        const SizedBox(height: AppDimens.paddingM),
        _buildTextField(
          controller: _addressArController,
          label: 'Adresse en arabe',
          icon: Iconsax.translate,
        ),
        const SizedBox(height: AppDimens.paddingM),
        Row(
          children: [
            Expanded(
              child: _buildTextField(
                controller: _latitudeController,
                label: 'Latitude',
                icon: Iconsax.global,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
              ),
            ),
            const SizedBox(width: AppDimens.paddingM),
            Expanded(
              child: _buildTextField(
                controller: _longitudeController,
                label: 'Longitude',
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
          label: 'Téléphone *',
          icon: Iconsax.call,
          keyboardType: TextInputType.phone,
          hintText: 'Ex: 0555123456 ou +213555123456',
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Le téléphone est requis';
            }
            final cleaned = value.replaceAll(RegExp(r'[\s\-().+]'), '');
            if (cleaned.length < 6) {
              return 'Numéro trop court';
            }
            return null;
          },
        ),
        const SizedBox(height: AppDimens.paddingM),
        _buildTextField(
          controller: _phoneSecondaryController,
          label: 'Téléphone secondaire',
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
          label: 'Site web',
          icon: Iconsax.global,
          keyboardType: TextInputType.url,
        ),
        const SizedBox(height: AppDimens.paddingL),
        const Align(
          alignment: Alignment.centerLeft,
          child: Text(
            'Réseaux sociaux',
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
        const Align(
          alignment: Alignment.centerLeft,
          child: Text(
            'Interlocuteur (optionnel)',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: AppColors.grey700,
            ),
          ),
        ),
        const SizedBox(height: AppDimens.paddingXS),
        const Align(
          alignment: Alignment.centerLeft,
          child: Text(
            'Personne de contact au sein de l\'établissement',
            style: TextStyle(fontSize: 12, color: AppColors.grey500),
          ),
        ),
        const SizedBox(height: AppDimens.paddingM),
        _buildTextField(
          controller: _contactFirstNameController,
          label: 'Prénom',
          icon: Iconsax.user,
        ),
        const SizedBox(height: AppDimens.paddingM),
        _buildTextField(
          controller: _contactLastNameController,
          label: 'Nom',
          icon: Iconsax.user,
        ),
        const SizedBox(height: AppDimens.paddingM),
        _buildTextField(
          controller: _contactPhoneController,
          label: 'Téléphone',
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
          label: 'Poste / Fonction',
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
        const Text(
          'Image de couverture',
          style:
              TextStyle(fontWeight: FontWeight.w600, color: AppColors.grey700),
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
            const Text(
              'Galerie d\'images',
              style: TextStyle(
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
            child: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Iconsax.gallery, color: AppColors.grey400, size: 32),
                  SizedBox(height: AppDimens.paddingXS),
                  Text(
                    'Aucune image',
                    style: TextStyle(color: AppColors.grey500, fontSize: 12),
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
        title: const Text('Supprimer l\'image ?'),
        content: const Text('Cette action est irréversible.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: AppColors.white,
            ),
            child: const Text('Supprimer'),
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
            const SnackBar(
              content: Text('Image supprimée'),
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
  }) {
    return DropdownButtonFormField<T>(
      initialValue: value,
      style: const TextStyle(color: AppColors.scaffoldBackground),
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
      items: items.map((item) {
        return DropdownMenuItem<T>(
          value: item,
          child: Text(itemBuilder(item)),
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
                        'Ajouter une image',
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
                title: const Text('Prendre une photo'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera, type);
                },
              ),
              ListTile(
                leading: const Icon(Iconsax.gallery),
                title: const Text('Choisir de la galerie'),
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
