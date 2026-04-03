import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
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

  const WriteReviewPage({
    super.key,
    required this.establishmentId,
    this.establishmentName,
    this.categoryName,
  });

  @override
  State<WriteReviewPage> createState() => _WriteReviewPageState();
}

class _WriteReviewPageState extends State<WriteReviewPage> {
  final _commentController = TextEditingController();
  final _imagePicker = ImagePicker();
  final _repository = ReviewRepository();

  // sub-ratings: key → note (0 = non noté)
  final Map<String, int> _subRatings = {
    for (final c in _criteria) c.key: 0,
  };

  final List<XFile> _selectedImages = [];
  bool _isUploadingImages = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  // Note globale = moyenne arrondie des critères notés
  int get _globalRating {
    final rated = _subRatings.values.where((v) => v > 0).toList();
    if (rated.isEmpty) return 0;
    return (rated.reduce((a, b) => a + b) / rated.length).round();
  }

  int get _ratedCount => _subRatings.values.where((v) => v > 0).length;
  bool get _allRated => _ratedCount == _criteria.length;

  Future<void> _pickImage() async {
    if (_selectedImages.length >= 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Maximum 3 photos par avis'),
          backgroundColor: AppColors.grey700,
        ),
      );
      return;
    }
    final image = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (image != null) setState(() => _selectedImages.add(image));
  }

  void _removeImage(int index) {
    setState(() => _selectedImages.removeAt(index));
  }

  Future<void> _submitReview() async {
    if (!_allRated) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez noter tous les critères'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }
    if (_commentController.text.trim().length < 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Décrivez votre expérience (min. 10 caractères)'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    List<String>? imageUrls;
    if (_selectedImages.isNotEmpty) {
      setState(() => _isUploadingImages = true);
      try {
        imageUrls = await _repository.uploadImages(_selectedImages);
      } catch (_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Erreur lors de l\'envoi des photos'),
              backgroundColor: AppColors.error,
            ),
          );
        }
        setState(() => _isUploadingImages = false);
        return;
      }
      setState(() => _isUploadingImages = false);
    }

    if (mounted) {
      context.read<ReviewBloc>().add(ReviewSubmit(
            establishmentId: widget.establishmentId,
            comment: _commentController.text.trim(),
            images: imageUrls,
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

                    // ── Photos ────────────────────────────────────────
                    GestureDetector(
                      onTap: _pickImage,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                            vertical: AppDimens.paddingL),
                        decoration: BoxDecoration(
                          borderRadius:
                              BorderRadius.circular(AppDimens.radiusM),
                          border: Border.all(
                            color: AppColors.white,
                            width: 1.5,
                          ),
                        ),
                        child: Column(
                          children: [
                            Icon(Iconsax.camera,
                                color: AppColors.grey400,
                                size: AppDimens.iconL),
                            const SizedBox(height: AppDimens.paddingS),
                            Text(
                              'Ajouter des photos (optionnel)',
                              style: TextStyle(
                                color: AppColors.white,
                                fontSize: AppDimens.fontS,
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
                          itemBuilder: (_, index) => Stack(
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
                    ],
                    const SizedBox(height: AppDimens.paddingXL),
                  ],
                ),
              ),
            ),

            // ── Bouton publier ─────────────────────────────────────────
            BlocBuilder<ReviewBloc, ReviewState>(
              builder: (context, state) {
                final isLoading =
                    state is ReviewSubmitting || _isUploadingImages;
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
                                    _isUploadingImages
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

  // ─── Note globale ──────────────────────────────────────────────────────────

  Widget _buildGlobalSummary() {
    final g = _globalRating;
    return Container(
      padding: const EdgeInsets.all(AppDimens.paddingL),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppDimens.radiusL),
        border:
            Border.all(color: AppColors.primaryGreen.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          // Drapeaux
          Column(
            children: [
              Row(
                children: List.generate(5, (i) {
                  return Text(
                    '🇩🇿',
                    style: TextStyle(
                      fontSize: i < g ? 22 : 16,
                      color: i < g ? null : null,
                    ).copyWith(
                      color: i < g ? null : null,
                    ),
                  );
                }),
              ),
              const SizedBox(height: 4),
              Text(
                g > 0 ? _ratingLabels[g]! : 'Notez les critères',
                style: TextStyle(
                  color: AppColors.primaryGreen
                      .withValues(alpha: g > 0 ? 1.0 : 0.5),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(width: AppDimens.paddingL),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  g > 0 ? '$g / 5' : '— / 5',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryGreen
                        .withValues(alpha: g > 0 ? 1.0 : 0.4),
                  ),
                ),
                Text(
                  'Note globale (moyenne)',
                  style: TextStyle(
                    color: AppColors.primaryGreen,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
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
