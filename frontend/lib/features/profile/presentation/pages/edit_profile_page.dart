import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_exceptions.dart';
import '../../../../core/constants/api_config.dart';
import '../../../../app_router.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/data/models/user_model.dart';
import '../../../home/data/models/category_model.dart';
import '../../../home/data/repositories/category_repository.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _wilayaRepository = WilayaRepository();

  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController();

  List<Wilaya> _wilayas = [];
  String? _selectedWilayaId;
  File? _selectedAvatar;
  bool _isLoading = false;
  bool _isLoadingData = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    final authBloc = context.read<AuthBloc>();

    try {
      _wilayas = await _wilayaRepository.getAll();

      final authState = authBloc.state;
      if (authState is AuthAuthenticated) {
        _populateForm(authState.user);
      }

      if (mounted) {
        setState(() {
          _isLoadingData = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingData = false;
          _errorMessage = 'Erreur lors du chargement des données';
        });
      }
    }
  }

  void _populateForm(User user) {
    _firstNameController.text = user.firstName;
    _lastNameController.text = user.lastName;
    _phoneController.text = user.phone ?? '';
    _selectedWilayaId = user.wilayaId;
  }

  Future<void> _pickAvatar() async {
    final picker = ImagePicker();

    final source = await showModalBottomSheet<ImageSource>(
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
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Iconsax.gallery),
                title: const Text('Choisir de la galerie'),
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
            ],
          ),
        ),
      ),
    );

    if (source != null) {
      final image = await picker.pickImage(
        source: source,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 80,
      );
      if (image != null) {
        setState(() {
          _selectedAvatar = File(image.path);
        });
      }
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final authBloc = context.read<AuthBloc>();

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Capture old avatar URL for cache eviction
      final oldAvatarUrl = authBloc.state is AuthAuthenticated
          ? (authBloc.state as AuthAuthenticated).user.avatar
          : null;

      // Upload avatar if selected — get back the new URL from the response
      String? newAvatarUrl;
      if (_selectedAvatar != null) {
        newAvatarUrl = await _uploadAvatar();
      }

      // Update profile — include avatar URL so the returned user is guaranteed
      // to have the correct value regardless of DB read timing
      authBloc.add(AuthUpdateProfile(
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        phone: _phoneController.text.trim().isNotEmpty
            ? _phoneController.text.trim()
            : null,
        wilayaId: _selectedWilayaId,
        avatar: newAvatarUrl,
      ));

      // Wait for the bloc to finish processing (AuthLoading → AuthAuthenticated/AuthError)
      await authBloc.stream
          .firstWhere((s) => s is AuthAuthenticated || s is AuthError)
          .timeout(const Duration(seconds: 10));

      // Evict old avatar from Flutter's image cache + pre-cache new one
      if (newAvatarUrl != null && mounted) {
        if (oldAvatarUrl != null) {
          PaintingBinding.instance.imageCache.evict(NetworkImage(oldAvatarUrl));
        }
        try {
          await precacheImage(NetworkImage(newAvatarUrl), context);
        } catch (_) {
          // Pre-caching is best-effort — the image will still load on the profile page
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profil mis à jour avec succès'),
            backgroundColor: AppColors.success,
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<String?> _uploadAvatar() async {
    if (_selectedAvatar == null) return null;

    final response = await ApiClient.instance.uploadFile(
      ApiConfig.uploadAvatar,
      filePath: _selectedAvatar!.path,
      fieldName: 'avatar',
    );
    return response.data['data']?['avatar'] as String?;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.grey50,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Iconsax.arrow_left),
          onPressed: () => context.pop(),
        ),
        title: const Text('Modifier le profil'),
        backgroundColor: AppColors.scaffoldBackground,
        foregroundColor: AppColors.white,
        elevation: 0,
      ),
      body: _isLoadingData
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primaryGreen),
            )
          : _buildForm(),
    );
  }

  Widget _buildForm() {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        if (state is! AuthAuthenticated) {
          return const Center(child: Text('Non connecté'));
        }

        final user = state.user;

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

                // Avatar Section
                Center(
                  child: Column(
                    children: [
                      Stack(
                        children: [
                          CircleAvatar(
                            radius: 60,
                            backgroundColor: AppColors.greenSurface,
                            backgroundImage: _selectedAvatar != null
                                ? FileImage(_selectedAvatar!)
                                : (user.avatar != null
                                    ? NetworkImage(user.avatar!)
                                    : null) as ImageProvider?,
                            child:
                                _selectedAvatar == null && user.avatar == null
                                    ? Text(
                                        user.firstName.isNotEmpty
                                            ? user.firstName[0].toUpperCase()
                                            : '?',
                                        style: const TextStyle(
                                          fontSize: 40,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.primaryGreen,
                                        ),
                                      )
                                    : null,
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: GestureDetector(
                              onTap: _pickAvatar,
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: const BoxDecoration(
                                  color: AppColors.primaryGreen,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Iconsax.camera,
                                  color: AppColors.white,
                                  size: 20,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppDimens.paddingS),
                      TextButton(
                        onPressed: _pickAvatar,
                        child: const Text('Changer la photo'),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: AppDimens.paddingXL),

                // Personal Info Section
                Text(
                  'Informations personnelles',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.grey800,
                      ),
                ),
                const SizedBox(height: AppDimens.paddingM),

                // First Name
                _buildTextField(
                  controller: _firstNameController,
                  label: 'Prénom *',
                  icon: Iconsax.user,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Le prénom est requis';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppDimens.paddingM),

                // Last Name
                _buildTextField(
                  controller: _lastNameController,
                  label: 'Nom *',
                  icon: Iconsax.user,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Le nom est requis';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppDimens.paddingM),

                // Email (read-only)
                _buildTextField(
                  controller: TextEditingController(text: user.email),
                  label: 'Email',
                  icon: Iconsax.sms,
                  enabled: false,
                ),
                const SizedBox(height: AppDimens.paddingM),

                // Phone
                _buildTextField(
                  controller: _phoneController,
                  label: 'Téléphone',
                  icon: Iconsax.call,
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: AppDimens.paddingM),

                // Wilaya
                _buildDropdown<Wilaya>(
                  value: _wilayas
                      .where((w) => w.id == _selectedWilayaId)
                      .firstOrNull,
                  items: _wilayas,
                  label: 'Wilaya',
                  icon: Iconsax.location,
                  itemBuilder: (wilaya) => '${wilaya.code} - ${wilaya.name}',
                  onChanged: (wilaya) {
                    setState(() {
                      _selectedWilayaId = wilaya?.id;
                    });
                  },
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
                        : const Text('Enregistrer'),
                  ),
                ),

                const SizedBox(height: AppDimens.paddingL),

                // Change Password Link
                Center(
                  child: TextButton.icon(
                    onPressed: () => _showChangePasswordDialog(),
                    icon: const Icon(Iconsax.lock),
                    label: const Text('Changer le mot de passe'),
                  ),
                ),

                // Partner Profile Link (only for partners)
                if (user.isPartner) ...[
                  const SizedBox(height: AppDimens.paddingM),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(AppDimens.paddingM),
                    decoration: BoxDecoration(
                      color: AppColors.greenSurface,
                      borderRadius: BorderRadius.circular(AppDimens.radiusM),
                      border: Border.all(
                        color: AppColors.primaryGreen.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Iconsax.building,
                              color: AppColors.primaryGreen,
                            ),
                            const SizedBox(width: AppDimens.paddingS),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Informations entreprise',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleSmall
                                        ?.copyWith(
                                          fontWeight: FontWeight.w600,
                                        ),
                                  ),
                                  if (user.partnerProfile != null)
                                    Text(
                                      user.partnerProfile!.companyName,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                            color: AppColors.grey600,
                                          ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppDimens.paddingM),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () =>
                                context.push(AppRoutes.editPartnerProfile),
                            icon: const Icon(Iconsax.edit, size: 18),
                            label: const Text('Modifier les informations'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.primaryGreen,
                              side: const BorderSide(
                                  color: AppColors.primaryGreen),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

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
    required String label,
    required IconData icon,
    bool enabled = true,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      keyboardType: keyboardType,
      validator: validator,
      style: TextStyle(
        color: enabled
            ? AppColors.scaffoldBackground
            : AppColors.scaffoldBackground.withValues(alpha: 0.5),
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          color: enabled
              ? AppColors.scaffoldBackground.withValues(alpha: 0.75)
              : AppColors.scaffoldBackground.withValues(alpha: 0.4),
        ),
        prefixIcon:
            Icon(icon, color: enabled ? AppColors.grey500 : AppColors.grey400),
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
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimens.radiusM),
          borderSide: const BorderSide(color: AppColors.grey200),
        ),
        filled: true,
        fillColor: enabled ? AppColors.white : AppColors.grey100,
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

  String _extractPasswordError(Object e) {
    if (e is ValidationException) {
      final fieldErrors = e.fieldErrors;
      if (fieldErrors.isNotEmpty) {
        return fieldErrors.values.expand((msgs) => msgs).join('\n');
      }
      return e.message.isNotEmpty ? e.message : 'Erreur de validation';
    }
    if (e is BadRequestException) {
      const map = {
        'Current password is incorrect': 'Le mot de passe actuel est incorrect',
      };
      return map[e.message] ?? e.message;
    }
    return 'Une erreur est survenue. Veuillez réessayer.';
  }

  void _showChangePasswordDialog() {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool isLoading = false;
    String? errorMessage;
    bool obscureCurrent = true;
    bool obscureNew = true;
    bool obscureConfirm = true;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Changer le mot de passe'),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (errorMessage != null)
                    Container(
                      margin: const EdgeInsets.only(bottom: AppDimens.paddingM),
                      padding: const EdgeInsets.all(AppDimens.paddingS),
                      decoration: BoxDecoration(
                        color: AppColors.error.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(AppDimens.radiusS),
                      ),
                      child: Text(
                        errorMessage!,
                        style: const TextStyle(
                          color: AppColors.error,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  TextFormField(
                    controller: currentPasswordController,
                    obscureText: obscureCurrent,
                    decoration: InputDecoration(
                      labelText: 'Mot de passe actuel',
                      prefixIcon: const Icon(Iconsax.lock),
                      suffixIcon: IconButton(
                        icon: Icon(
                          obscureCurrent ? Iconsax.eye_slash : Iconsax.eye,
                          size: 20,
                          color: AppColors.grey500,
                        ),
                        onPressed: () => setDialogState(
                            () => obscureCurrent = !obscureCurrent),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Requis';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: AppDimens.paddingM),
                  TextFormField(
                    controller: newPasswordController,
                    obscureText: obscureNew,
                    decoration: InputDecoration(
                      labelText: 'Nouveau mot de passe',
                      prefixIcon: const Icon(Iconsax.lock_1),
                      suffixIcon: IconButton(
                        icon: Icon(
                          obscureNew ? Iconsax.eye_slash : Iconsax.eye,
                          size: 20,
                          color: AppColors.grey500,
                        ),
                        onPressed: () =>
                            setDialogState(() => obscureNew = !obscureNew),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Requis';
                      }
                      if (value.length < 6) {
                        return 'Minimum 6 caractères';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: AppDimens.paddingM),
                  TextFormField(
                    controller: confirmPasswordController,
                    obscureText: obscureConfirm,
                    decoration: InputDecoration(
                      labelText: 'Confirmer le mot de passe',
                      prefixIcon: const Icon(Iconsax.lock_1),
                      suffixIcon: IconButton(
                        icon: Icon(
                          obscureConfirm ? Iconsax.eye_slash : Iconsax.eye,
                          size: 20,
                          color: AppColors.grey500,
                        ),
                        onPressed: () => setDialogState(
                            () => obscureConfirm = !obscureConfirm),
                      ),
                    ),
                    validator: (value) {
                      if (value != newPasswordController.text) {
                        return 'Les mots de passe ne correspondent pas';
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: isLoading ? null : () => Navigator.pop(dialogContext),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: isLoading
                  ? null
                  : () async {
                      if (!formKey.currentState!.validate()) return;

                      setDialogState(() {
                        isLoading = true;
                        errorMessage = null;
                      });

                      try {
                        await ApiClient.instance.post(
                          ApiConfig.changePassword,
                          data: {
                            'current_password': currentPasswordController.text,
                            'new_password': newPasswordController.text,
                            'new_password_confirmation':
                                confirmPasswordController.text,
                          },
                        );

                        if (context.mounted) {
                          Navigator.pop(dialogContext);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Mot de passe modifié avec succès'),
                              backgroundColor: AppColors.success,
                            ),
                          );
                        }
                      } catch (e) {
                        final msg = _extractPasswordError(e);
                        setDialogState(() {
                          errorMessage = msg;
                          isLoading = false;
                        });
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryGreen,
                foregroundColor: AppColors.white,
              ),
              child: isLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        color: AppColors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text('Changer'),
            ),
          ],
        ),
      ),
    );
  }
}
