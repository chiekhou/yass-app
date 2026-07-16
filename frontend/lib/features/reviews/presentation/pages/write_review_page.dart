import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:win_app/core/l10n/l10n_extensions.dart';
import 'package:iconsax/iconsax.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../establishment/data/models/establishment_model.dart';
import '../../../establishment/data/models/photo_category.dart';
import '../../data/repositories/reviews_repository.dart';
import '../bloc/review_bloc.dart';

// ─── Définition des 7 critères ───────────────────────────────────────────────

class _Criterion {
  final String key;
  final String label;
  final String description;
  final IconData icon;

  const _Criterion({
    required this.key,
    required this.label,
    required this.description,
    required this.icon,
  });
}

const _criteria = [
  _Criterion(
    key: 'quality',
    label: 'Qualité de la prestation',
    description: 'Goût, fraîcheur, efficacité, état des installations…',
    icon: Iconsax.star,
  ),
  _Criterion(
    key: 'welcome',
    label: 'Accueil et relation client',
    description: 'Amabilité, écoute, capacité à expliquer clairement',
    icon: Iconsax.people,
  ),
  _Criterion(
    key: 'information',
    label: 'Clarté des informations',
    description: 'Transparence sur les horaires, tarifs et explications',
    icon: Iconsax.info_circle,
  ),
  _Criterion(
    key: 'value',
    label: 'Rapport qualité / prix',
    description: 'Est-ce que le service vaut son prix ?',
    icon: Iconsax.wallet,
  ),
  _Criterion(
    key: 'availability',
    label: 'Disponibilité et accessibilité',
    description: 'Facilité de rendez-vous, horaires pratiques, réactivité',
    icon: Iconsax.clock,
  ),
  _Criterion(
    key: 'reliability',
    label: 'Fiabilité / professionnalisme',
    description: 'Respect des engagements, sérieux et compétence',
    icon: Iconsax.verify,
  ),
  _Criterion(
    key: 'comfort',
    label: 'Confort et environnement',
    description: 'Propreté, ambiance, équipements',
    icon: Iconsax.home,
  ),
];

// ─── Labels par note ─────────────────────────────────────────────────────────

const _ratingLabels = {
  1: 'Très mauvais',
  2: 'Décevant',
  3: 'Correct',
  4: 'Bon',
  5: 'Excellent !',
};

// ─── Page ─────────────────────────────────────────────────────────────────────

class WriteReviewPage extends StatefulWidget {
  final String establishmentId;
  final String? establishmentName;
  final String? categoryName;
  final int initialRating; // 0 = non pré-sélectionné

  const WriteReviewPage({
    super.key,
    required this.establishmentId,
    this.establishmentName,
    this.categoryName,
    this.initialRating = 0,
  });

  @override
  State<WriteReviewPage> createState() => _WriteReviewPageState();
}

class _WriteReviewPageState extends State<WriteReviewPage> {
  final _commentController = TextEditingController();
  final _imagePicker = ImagePicker();
  final _repository = ReviewRepository();

  // Note d'ensemble : initialisée depuis initialRating si fourni
  late int _overallRating;

  // Date de visite
  DateTime? _visitDate;

  // sub-ratings: key → note (0 = non noté)
  final Map<String, int> _subRatings = {
    for (final c in _criteria) c.key: 0,
  };

  final List<XFile> _selectedImages = [];
  final List<String> _imageCategories = [];
  final List<XFile> _selectedVideos = [];
  final List<String> _videoCategories = [];
  bool _isUploadingImages = false;
  bool _isUploadingVideos = false;

  @override
  void initState() {
    super.initState();
    _overallRating = widget.initialRating.clamp(0, 5);
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  int get _ratedCount => _subRatings.values.where((v) => v > 0).length;
  bool get _allRated => _ratedCount == _criteria.length;

  Future<void> _pickImage() async {
    if (_selectedImages.length >= 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n.maxPhotosPerReview),
          backgroundColor: AppColors.grey700,
        ),
      );
      return;
    }

    final images = await _imagePicker.pickMultiImage(imageQuality: 80);
    if (images.isEmpty) return;

    // Limiter au nombre de slots restants
    final remaining = 5 - _selectedImages.length;
    final toAdd = images.take(remaining).toList();

    // Une seule sélection de catégorie pour tout le lot
    final category = await _showCategoryPicker();
    if (!mounted) return;
    setState(() {
      for (final image in toAdd) {
        _selectedImages.add(image);
        _imageCategories.add(category ?? 'autres');
      }
    });
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
      _imageCategories.removeAt(index);
    });
  }

  Future<void> _changeCategory(int index) async {
    final category =
        await _showCategoryPicker(current: _imageCategories[index]);
    if (category != null && mounted) {
      setState(() => _imageCategories[index] = category);
    }
  }

  Future<void> _pickVideo() async {
    if (_selectedVideos.length >= 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n.maxVideosPerReview),
          backgroundColor: AppColors.grey700,
        ),
      );
      return;
    }

    final video = await _imagePicker.pickVideo(
      source: ImageSource.gallery,
      maxDuration: const Duration(minutes: 3),
    );
    if (video == null) return;

    final category = await _showCategoryPicker();
    if (!mounted) return;
    setState(() {
      _selectedVideos.add(video);
      _videoCategories.add(category ?? 'autres');
    });
  }

  void _removeVideo(int index) {
    setState(() {
      _selectedVideos.removeAt(index);
      _videoCategories.removeAt(index);
    });
  }

  Future<void> _changeVideoCategory(int index) async {
    final category =
        await _showCategoryPicker(current: _videoCategories[index]);
    if (category != null && mounted) {
      setState(() => _videoCategories[index] = category);
    }
  }

  Future<String?> _showCategoryPicker({String? current}) {
    return showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.grey300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Quel type de photo ?',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.grey900,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 320,
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: kPhotoCategories.length,
                  itemBuilder: (context, i) {
                    final cat = kPhotoCategories[i];
                    final isSelected = cat.key == current;
                    return ListTile(
                      leading: Icon(cat.icon,
                          color: isSelected
                              ? AppColors.primaryGreen
                              : AppColors.grey600,
                          size: 22),
                      title: Text(
                        cat.label,
                        style: TextStyle(
                          color: isSelected
                              ? AppColors.primaryGreen
                              : AppColors.grey900,
                          fontWeight:
                              isSelected ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                      trailing: isSelected
                          ? const Icon(Icons.check,
                              color: AppColors.primaryGreen, size: 18)
                          : null,
                      onTap: () => Navigator.pop(context, cat.key),
                    );
                  },
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  Future<void> _submitReview() async {
    if (_overallRating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n.ratingRequired),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }
    if (!_allRated) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n.allCriteriaRequired),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }
    if (_commentController.text.trim().length < 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n.reviewMinChars),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    List<PhotoItem>? photoItems;
    if (_selectedImages.isNotEmpty) {
      setState(() => _isUploadingImages = true);
      try {
        final urls = await _repository.uploadImages(_selectedImages);
        photoItems = List.generate(
          urls.length,
          (i) => PhotoItem(
            url: urls[i],
            category: i < _imageCategories.length ? _imageCategories[i] : 'autres',
            type: 'photo',
          ),
        );
      } catch (_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(context.l10n.photoUploadError),
              backgroundColor: AppColors.error,
            ),
          );
          setState(() => _isUploadingImages = false);
        }
        return;
      }
      if (mounted) setState(() => _isUploadingImages = false);
    }

    List<PhotoItem>? videoItems;
    if (_selectedVideos.isNotEmpty) {
      if (mounted) setState(() => _isUploadingVideos = true);
      try {
        final urls = await _repository.uploadVideos(_selectedVideos);
        videoItems = List.generate(
          urls.length,
          (i) => PhotoItem(
            url: urls[i],
            category: i < _videoCategories.length ? _videoCategories[i] : 'autres',
            type: 'video',
          ),
        );
      } catch (_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(context.l10n.videoUploadError),
              backgroundColor: AppColors.error,
            ),
          );
          setState(() => _isUploadingVideos = false);
        }
        return;
      }
      if (mounted) setState(() => _isUploadingVideos = false);
    }

    if (mounted) {
      context.read<ReviewBloc>().add(ReviewSubmit(
            establishmentId: widget.establishmentId,
            rating: _overallRating,
            comment: _commentController.text.trim(),
            images: photoItems,
            videos: videoItems,
            visitDate: _visitDate,
            subRatings: Map<String, int>.from(_subRatings),
          ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<ReviewBloc, ReviewState>(
      listener: (context, state) {
        if (state is ReviewSubmitSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: AppColors.success,
            ),
          );
          context.pop(true);
        } else if (state is ReviewError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: AppColors.error,
            ),
          );
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.background,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.close, color: AppColors.white),
            onPressed: () => context.pop(),
          ),
          title: Text(
            widget.establishmentName ?? 'Écrire un avis',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.infoLight,
                ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        body: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimens.paddingL,
                  vertical: AppDimens.paddingM,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Note globale synthèse ──────────────────────────
                    _buildGlobalSummary(),
                    const SizedBox(height: AppDimens.paddingL),
                    const Divider(height: 1, color: AppColors.white),
                    const SizedBox(height: AppDimens.paddingL),

                    // ── 7 critères ────────────────────────────────────
                    Text(
                      'Évaluez chaque critère',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold, color: AppColors.white),
                    ),
                    const SizedBox(height: AppDimens.paddingXS),
                    Text(
                      '$_ratedCount/${_criteria.length} critères notés',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color:
                                _allRated ? AppColors.white : AppColors.success,
                          ),
                    ),
                    const SizedBox(height: AppDimens.paddingM),
                    ..._criteria.map((c) => _buildCriterionRow(c)),

                    const SizedBox(height: AppDimens.paddingL),
                    const Divider(height: 1, color: AppColors.grey800),
                    const SizedBox(height: AppDimens.paddingL),

                    // ── Commentaire ───────────────────────────────────
                    Text(
                      'Parlez-nous de votre expérience',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold, color: AppColors.white),
                    ),
                    const SizedBox(height: AppDimens.paddingM),
                    TextField(
                      controller: _commentController,
                      maxLines: 5,
                      maxLength: 2000,
                      style: const TextStyle(color: AppColors.primaryGreen),
                      decoration: InputDecoration(
                        hintText: 'Décrivez votre expérience...',
                        hintStyle: const TextStyle(color: AppColors.grey700),
                        border: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(AppDimens.radiusM),
                          borderSide: const BorderSide(color: AppColors.white),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(AppDimens.radiusM),
                          borderSide:
                              const BorderSide(color: AppColors.grey700),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(AppDimens.radiusM),
                          borderSide: const BorderSide(
                            color: AppColors.white,
                            width: 1.5,
                          ),
                        ),
                        contentPadding:
                            const EdgeInsets.all(AppDimens.paddingM),
                        counterStyle: const TextStyle(color: AppColors.white),
                      ),
                    ),

                    const SizedBox(height: AppDimens.paddingM),

                    // ── Date de visite ────────────────────────────────
                    GestureDetector(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: _visitDate ?? DateTime.now(),
                          firstDate: DateTime(2000),
                          lastDate: DateTime.now(),
                          helpText: 'Date de votre visite',
                          cancelText: 'Annuler',
                          confirmText: 'Confirmer',
                          builder: (context, child) => Theme(
                            data: Theme.of(context).copyWith(
                              colorScheme: const ColorScheme.light(
                                primary: AppColors.primaryGreen,
                                onPrimary: Colors.white,
                                surface: Colors.white,
                              ),
                            ),
                            child: child!,
                          ),
                        );
                        if (picked != null && mounted) {
                          setState(() => _visitDate = picked);
                        }
                      },
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          borderRadius:
                              BorderRadius.circular(AppDimens.radiusM),
                          border: Border.all(
                            color: _visitDate != null
                                ? AppColors.successLight
                                : AppColors.white,
                            width: 1.5,
                          ),
                          color: _visitDate != null
                              ? AppColors.successLight
                              : Colors.transparent,
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Iconsax.calendar_1,
                              color: _visitDate != null
                                  ? AppColors.primaryGreen
                                  : AppColors.grey400,
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _visitDate != null
                                    ? 'Visité le ${_visitDate!.day.toString().padLeft(2, '0')}/${_visitDate!.month.toString().padLeft(2, '0')}/${_visitDate!.year}'
                                    : 'Date de votre visite (optionnel)',
                                style: TextStyle(
                                  color: _visitDate != null
                                      ? AppColors.primaryGreen
                                      : AppColors.grey400,
                                  fontSize: AppDimens.fontS,
                                  fontWeight: _visitDate != null
                                      ? FontWeight.w600
                                      : FontWeight.normal,
                                ),
                              ),
                            ),
                            if (_visitDate != null)
                              GestureDetector(
                                onTap: () => setState(() => _visitDate = null),
                                child: const Icon(Icons.close,
                                    size: 16, color: AppColors.grey500),
                              ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: AppDimens.paddingM),

                    // ── Photos ────────────────────────────────────────
                    GestureDetector(
                      onTap: _selectedImages.length < 5 ? _pickImage : null,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                            vertical: AppDimens.paddingL),
                        decoration: BoxDecoration(
                          borderRadius:
                              BorderRadius.circular(AppDimens.radiusM),
                          border: Border.all(
                            color: _selectedImages.length >= 5
                                ? AppColors.grey700
                                : AppColors.white,
                            width: 1.5,
                          ),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              Iconsax.camera,
                              color: _selectedImages.length >= 5
                                  ? AppColors.grey700
                                  : AppColors.grey400,
                              size: AppDimens.iconL,
                            ),
                            const SizedBox(height: AppDimens.paddingS),
                            Text(
                              _selectedImages.isEmpty
                                  ? 'Ajouter des photos (optionnel)'
                                  : _selectedImages.length >= 5
                                      ? 'Maximum atteint (5/5)'
                                      : 'Ajouter d\'autres photos (${_selectedImages.length}/5)',
                              style: TextStyle(
                                color: _selectedImages.length >= 5
                                    ? AppColors.grey700
                                    : AppColors.white,
                                fontSize: AppDimens.fontS,
                              ),
                            ),
                            if (_selectedImages.isEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                  'Sélectionnez plusieurs photos à la fois',
                                  style: TextStyle(
                                    color: AppColors.white,
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),

                    if (_selectedImages.isNotEmpty) ...[
                      const SizedBox(height: AppDimens.paddingS),
                      SizedBox(
                        height: 90,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: _selectedImages.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(width: AppDimens.paddingS),
                          itemBuilder: (_, index) => SizedBox(
                            width: 90,
                            height: 90,
                            child: Stack(
                              children: [
                                ClipRRect(
                                  borderRadius:
                                      BorderRadius.circular(AppDimens.radiusS),
                                  child: Image.file(
                                    File(_selectedImages[index].path),
                                    width: 90,
                                    height: 90,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                // Badge catégorie (cliquable pour changer)
                                Positioned(
                                  bottom: 4,
                                  left: 4,
                                  right: 20,
                                  child: GestureDetector(
                                    onTap: () => _changeCategory(index),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 5, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: AppColors.primaryGreen
                                            .withValues(alpha: 0.9),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        photoCategoryLabel(
                                            _imageCategories.length > index
                                                ? _imageCategories[index]
                                                : null),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 9,
                                          fontWeight: FontWeight.w600,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ),
                                ),
                                // Bouton supprimer
                                Positioned(
                                  top: 4,
                                  right: 4,
                                  child: GestureDetector(
                                    onTap: () => _removeImage(index),
                                    child: Container(
                                      padding: const EdgeInsets.all(3),
                                      decoration: const BoxDecoration(
                                        color: AppColors.grey900,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(Icons.close,
                                          size: 12, color: AppColors.white),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],

                    const SizedBox(height: AppDimens.paddingM),

                    // ── Vidéos ────────────────────────────────────────
                    GestureDetector(
                      onTap: _selectedVideos.length < 3 ? _pickVideo : null,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                            vertical: AppDimens.paddingL),
                        decoration: BoxDecoration(
                          borderRadius:
                              BorderRadius.circular(AppDimens.radiusM),
                          border: Border.all(
                            color: _selectedVideos.length >= 3
                                ? AppColors.grey700
                                : AppColors.white,
                            width: 1.5,
                          ),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              Iconsax.video,
                              color: _selectedVideos.length >= 3
                                  ? AppColors.grey700
                                  : AppColors.grey400,
                              size: AppDimens.iconL,
                            ),
                            const SizedBox(height: AppDimens.paddingS),
                            Text(
                              _selectedVideos.isEmpty
                                  ? 'Ajouter des vidéos (optionnel)'
                                  : _selectedVideos.length >= 3
                                      ? 'Maximum atteint (3/3)'
                                      : 'Ajouter une autre vidéo (${_selectedVideos.length}/3)',
                              style: TextStyle(
                                color: _selectedVideos.length >= 3
                                    ? AppColors.grey700
                                    : AppColors.white,
                                fontSize: AppDimens.fontS,
                              ),
                            ),
                            if (_selectedVideos.isEmpty)
                              const Padding(
                                padding: EdgeInsets.only(top: 4),
                                child: Text(
                                  'Max 3 min · 50 Mo par vidéo',
                                  style: TextStyle(
                                    color: AppColors.white,
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),

                    if (_selectedVideos.isNotEmpty) ...[
                      const SizedBox(height: AppDimens.paddingS),
                      SizedBox(
                        height: 90,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: _selectedVideos.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(width: AppDimens.paddingS),
                          itemBuilder: (_, index) => SizedBox(
                            width: 90,
                            height: 90,
                            child: Stack(
                              children: [
                                // Placeholder vidéo
                                ClipRRect(
                                  borderRadius:
                                      BorderRadius.circular(AppDimens.radiusS),
                                  child: Container(
                                    width: 90,
                                    height: 90,
                                    color: AppColors.grey900,
                                    child: const Center(
                                      child: Icon(
                                        Iconsax.play_circle,
                                        color: AppColors.white,
                                        size: 32,
                                      ),
                                    ),
                                  ),
                                ),
                                // Badge catégorie (cliquable pour changer)
                                Positioned(
                                  bottom: 4,
                                  left: 4,
                                  right: 20,
                                  child: GestureDetector(
                                    onTap: () => _changeVideoCategory(index),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 5, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Colors.blue
                                            .withValues(alpha: 0.9),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        photoCategoryLabel(
                                            _videoCategories.length > index
                                                ? _videoCategories[index]
                                                : null),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 9,
                                          fontWeight: FontWeight.w600,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ),
                                ),
                                // Bouton supprimer
                                Positioned(
                                  top: 4,
                                  right: 4,
                                  child: GestureDetector(
                                    onTap: () => _removeVideo(index),
                                    child: Container(
                                      padding: const EdgeInsets.all(3),
                                      decoration: const BoxDecoration(
                                        color: AppColors.grey900,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(Icons.close,
                                          size: 12, color: AppColors.white),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],

                    const SizedBox(height: AppDimens.paddingXL),
                  ],
                ),
              ),
            ),

            // ── Bouton publier ─────────────────────────────────────────
            BlocBuilder<ReviewBloc, ReviewState>(
              builder: (context, state) {
                final isLoading = state is ReviewSubmitting ||
                    _isUploadingImages ||
                    _isUploadingVideos;
                return SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppDimens.paddingL,
                      AppDimens.paddingS,
                      AppDimens.paddingL,
                      AppDimens.paddingM,
                    ),
                    child: SizedBox(
                      width: double.infinity,
                      height: AppDimens.buttonHeight,
                      child: ElevatedButton(
                        onPressed: isLoading ? null : _submitReview,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.white,
                          foregroundColor: AppColors.primaryGreen,
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(AppDimens.radiusM),
                          ),
                        ),
                        child: isLoading
                            ? Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: AppColors.white,
                                    ),
                                  ),
                                  const SizedBox(width: AppDimens.paddingS),
                                  Text(
                                    _isUploadingVideos
                                        ? 'Envoi des vidéos...'
                                        : _isUploadingImages
                                            ? 'Envoi des photos...'
                                            : 'Publication...',
                                    style: const TextStyle(
                                      color: AppColors.white,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              )
                            : const Text(
                                'Publier l\'avis',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                ),
                              ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // ─── Note d'ensemble (saisie explicite) ───────────────────────────────────

  Widget _buildGlobalSummary() {
    final g = _overallRating;
    final label = g > 0 ? _ratingLabels[g]! : 'Donnez votre note d\'ensemble';
    return Container(
      padding: const EdgeInsets.all(AppDimens.paddingL),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppDimens.radiusL),
        border: Border.all(
          color: g > 0
              ? AppColors.primaryGreen.withValues(alpha: 0.6)
              : AppColors.grey300,
          width: g > 0 ? 1.5 : 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            'Note d\'ensemble',
            style: TextStyle(
              color: AppColors.primaryGreen,
              fontSize: 13,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: g > 0 ? AppColors.grey800 : AppColors.grey400,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: AppDimens.paddingM),
          // 5 étoiles interactives
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (i) {
              final filled = i < g;
              return GestureDetector(
                onTap: () => setState(() => _overallRating = i + 1),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 150),
                    child: Icon(
                      filled ? Icons.star_rounded : Icons.star_outline_rounded,
                      key: ValueKey(filled),
                      size: 44,
                      color: filled ? Colors.amber : AppColors.grey300,
                    ),
                  ),
                ),
              );
            }),
          ),
          if (g > 0) ...[
            const SizedBox(height: AppDimens.paddingS),
            Text(
              '$g / 5',
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryGreen,
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ─── Ligne critère ─────────────────────────────────────────────────────────

  Widget _buildCriterionRow(_Criterion criterion) {
    final current = _subRatings[criterion.key] ?? 0;
    return Container(
      margin: const EdgeInsets.only(bottom: AppDimens.paddingM),
      padding: const EdgeInsets.all(AppDimens.paddingM),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppDimens.radiusM),
        border: Border.all(
          color: current > 0
              ? AppColors.primaryGreen.withValues(alpha: 0.5)
              : AppColors.white.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(criterion.icon, color: AppColors.primaryGreen),
              const SizedBox(width: AppDimens.paddingS),
              Expanded(
                child: Text(
                  criterion.label,
                  style: const TextStyle(
                    color: AppColors.primaryGreen,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
              if (current > 0)
                Text(
                  _ratingLabels[current]!,
                  style: const TextStyle(
                    color: AppColors.primaryGreen,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            criterion.description,
            style: TextStyle(
                color: AppColors.primaryGreen.withValues(alpha: 0.6),
                fontSize: 12),
          ),
          const SizedBox(height: AppDimens.paddingM),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(5, (i) {
              final value = i + 1;
              final isSelected = value <= current;
              return GestureDetector(
                onTap: () => setState(() => _subRatings[criterion.key] = value),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  width: 48,
                  height: 44,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primaryGreen.withValues(alpha: 0.15)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(AppDimens.radiusS),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.primaryRed
                          : AppColors.white.withValues(alpha: 0.3),
                      width: isSelected ? 1.5 : 1,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '🇩🇿',
                        style: TextStyle(fontSize: isSelected ? 16 : 13),
                      ),
                      Text(
                        '$value',
                        style: TextStyle(
                          fontSize: 11,
                          color: isSelected
                              ? AppColors.primaryGreen
                              : AppColors.primaryRed.withValues(alpha: 0.5),
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}
