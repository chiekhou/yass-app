import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../shared/widgets/custom_text_field.dart';
import '../../data/repositories/reviews_repository.dart';
import '../bloc/review_bloc.dart';

class WriteReviewPage extends StatefulWidget {
  final String establishmentId;
  final String? establishmentName;

  const WriteReviewPage({
    super.key,
    required this.establishmentId,
    this.establishmentName,
  });

  @override
  State<WriteReviewPage> createState() => _WriteReviewPageState();
}

class _WriteReviewPageState extends State<WriteReviewPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _commentController = TextEditingController();
  final _imagePicker = ImagePicker();
  final _repository = ReviewRepository();
  double _rating = 0;
  List<XFile> _selectedImages = [];
  bool _isUploadingImages = false;

  @override
  void dispose() {
    _titleController.dispose();
    _commentController.dispose();
    super.dispose();
  }

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
    if (image != null) {
      setState(() => _selectedImages.add(image));
    }
  }

  void _removeImage(int index) {
    setState(() => _selectedImages.removeAt(index));
  }

  Future<void> _submitReview() async {
    if (!_formKey.currentState!.validate() || _rating == 0) {
      if (_rating == 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Veuillez donner une note'),
            backgroundColor: AppColors.error,
          ),
        );
      }
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
            rating: _rating.toInt(),
            title: _titleController.text.trim().isEmpty
                ? null
                : _titleController.text.trim(),
            comment: _commentController.text.trim(),
            images: imageUrls,
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
          context.pop(true); // Return true to indicate review was submitted
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
        appBar: AppBar(
          title: const Text(AppStrings.writeReview),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(AppDimens.paddingM),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Establishment name
                if (widget.establishmentName != null) ...[
                  Text(
                    widget.establishmentName!,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: AppDimens.paddingL),
                ],

                // Rating
                Text(
                  AppStrings.rating,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: AppDimens.paddingS),
                Center(
                  child: RatingBar.builder(
                    initialRating: _rating,
                    minRating: 1,
                    direction: Axis.horizontal,
                    allowHalfRating: false,
                    itemCount: 5,
                    itemSize: 48,
                    itemPadding: const EdgeInsets.symmetric(horizontal: 4),
                    itemBuilder: (context, _) => const Icon(
                      Icons.star_rounded,
                      color: AppColors.starFilled,
                    ),
                    unratedColor: AppColors.grey300,
                    onRatingUpdate: (rating) {
                      setState(() => _rating = rating);
                    },
                  ),
                ),
                const SizedBox(height: AppDimens.paddingS),
                Center(
                  child: Text(
                    _getRatingLabel(),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.grey600,
                        ),
                  ),
                ),
                const SizedBox(height: AppDimens.paddingL),

                // Title (optional)
                CustomTextField(
                  controller: _titleController,
                  label: 'Titre (optionnel)',
                  hint: 'Ex : Super expérience, Déçu par le service...',
                  maxLines: 1,
                  maxLength: 100,
                ),
                const SizedBox(height: AppDimens.paddingM),

                // Comment
                CustomTextField(
                  controller: _commentController,
                  label: AppStrings.yourReview,
                  hint: AppStrings.reviewHint,
                  maxLines: 5,
                  maxLength: 2000,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Le commentaire est requis';
                    }
                    if (value.length < 10) {
                      return 'Minimum 10 caractères';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppDimens.paddingL),

                // Photos (optional)
                Text(
                  'Photos (optionnel)',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: AppDimens.paddingS),
                SizedBox(
                  height: 100,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      // Add photo button
                      if (_selectedImages.length < 3)
                        GestureDetector(
                          onTap: _pickImage,
                          child: Container(
                            width: 100,
                            height: 100,
                            margin: const EdgeInsets.only(right: AppDimens.paddingS),
                            decoration: BoxDecoration(
                              color: AppColors.grey100,
                              borderRadius: BorderRadius.circular(AppDimens.radiusM),
                              border: Border.all(
                                color: AppColors.grey300,
                                style: BorderStyle.solid,
                              ),
                            ),
                            child: const Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Iconsax.camera, color: AppColors.grey500, size: 28),
                                SizedBox(height: 4),
                                Text(
                                  'Ajouter',
                                  style: TextStyle(
                                    color: AppColors.grey500,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      // Selected images preview
                      ..._selectedImages.asMap().entries.map((entry) {
                        final index = entry.key;
                        final image = entry.value;
                        return Stack(
                          children: [
                            Container(
                              width: 100,
                              height: 100,
                              margin: const EdgeInsets.only(right: AppDimens.paddingS),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(AppDimens.radiusM),
                                image: DecorationImage(
                                  image: FileImage(File(image.path)),
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            Positioned(
                              top: 4,
                              right: AppDimens.paddingS + 4,
                              child: GestureDetector(
                                onTap: () => _removeImage(index),
                                child: Container(
                                  padding: const EdgeInsets.all(3),
                                  decoration: const BoxDecoration(
                                    color: AppColors.grey900,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.close,
                                    size: 14,
                                    color: AppColors.white,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        );
                      }),
                    ],
                  ),
                ),
                const SizedBox(height: AppDimens.paddingL),

                // Submit Button
                BlocBuilder<ReviewBloc, ReviewState>(
                  builder: (context, state) {
                    final isLoading = state is ReviewSubmitting || _isUploadingImages;
                    return SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: isLoading ? null : _submitReview,
                        child: isLoading
                            ? Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: AppColors.white,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    _isUploadingImages ? 'Envoi des photos...' : 'Envoi...',
                                    style: const TextStyle(color: AppColors.white),
                                  ),
                                ],
                              )
                            : const Text(AppStrings.submitReview),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _getRatingLabel() {
    switch (_rating.toInt()) {
      case 1:
        return 'Très mauvais';
      case 2:
        return 'Mauvais';
      case 3:
        return 'Moyen';
      case 4:
        return 'Bon';
      case 5:
        return 'Excellent';
      default:
        return 'Touchez pour noter';
    }
  }
}
