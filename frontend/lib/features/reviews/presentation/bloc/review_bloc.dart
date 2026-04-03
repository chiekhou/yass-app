import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:win_app/features/reviews/data/repositories/reviews_repository.dart';

import '../../data/models/review_model.dart';

// ==================== EVENTS ====================

abstract class ReviewEvent extends Equatable {
  const ReviewEvent();

  @override
  List<Object?> get props => [];
}

class ReviewSubmit extends ReviewEvent {
  final String establishmentId;
  final int? rating;
  final String? title;
  final String comment;
  final List<String>? pros;
  final List<String>? cons;
  final List<String>? images;
  final DateTime? visitDate;
  final Map<String, int>? subRatings;

  const ReviewSubmit({
    required this.establishmentId,
    this.rating,
    this.title,
    required this.comment,
    this.pros,
    this.cons,
    this.images,
    this.visitDate,
    this.subRatings,
  });

  @override
  List<Object?> get props => [
        establishmentId,
        rating,
        title,
        comment,
        pros,
        cons,
        images,
        visitDate,
        subRatings,
      ];
}

class ReviewUpdate extends ReviewEvent {
  final String reviewId;
  final int? rating;
  final String? title;
  final String? comment;
  final List<String>? pros;
  final List<String>? cons;

  const ReviewUpdate({
    required this.reviewId,
    this.rating,
    this.title,
    this.comment,
    this.pros,
    this.cons,
  });

  @override
  List<Object?> get props => [reviewId, rating, title, comment, pros, cons];
}

class ReviewDelete extends ReviewEvent {
  final String reviewId;

  const ReviewDelete({required this.reviewId});

  @override
  List<Object?> get props => [reviewId];
}

class ReviewMarkHelpful extends ReviewEvent {
  final String reviewId;

  const ReviewMarkHelpful({required this.reviewId});

  @override
  List<Object?> get props => [reviewId];
}

class ReviewReport extends ReviewEvent {
  final String reviewId;
  final String reason;

  const ReviewReport({required this.reviewId, required this.reason});

  @override
  List<Object?> get props => [reviewId, reason];
}

class ReviewLoadMine extends ReviewEvent {
  final int page;

  const ReviewLoadMine({this.page = 1});

  @override
  List<Object?> get props => [page];
}

// ==================== STATES ====================

abstract class ReviewState extends Equatable {
  const ReviewState();

  @override
  List<Object?> get props => [];
}

class ReviewInitial extends ReviewState {}

class ReviewLoading extends ReviewState {}

class ReviewSubmitting extends ReviewState {}

class ReviewSubmitSuccess extends ReviewState {
  final Review review;
  final String message;

  const ReviewSubmitSuccess({required this.review, required this.message});

  @override
  List<Object?> get props => [review, message];
}

class ReviewUpdateSuccess extends ReviewState {
  final Review review;

  const ReviewUpdateSuccess({required this.review});

  @override
  List<Object?> get props => [review];
}

class ReviewDeleteSuccess extends ReviewState {
  final String reviewId;

  const ReviewDeleteSuccess({required this.reviewId});

  @override
  List<Object?> get props => [reviewId];
}

class ReviewHelpfulSuccess extends ReviewState {
  final String reviewId;
  final int helpfulCount;

  const ReviewHelpfulSuccess({
    required this.reviewId,
    required this.helpfulCount,
  });

  @override
  List<Object?> get props => [reviewId, helpfulCount];
}

class ReviewReportSuccess extends ReviewState {}

class ReviewMyListLoaded extends ReviewState {
  final List<Review> reviews;
  final bool hasMore;
  final int currentPage;

  const ReviewMyListLoaded({
    required this.reviews,
    this.hasMore = false,
    this.currentPage = 1,
  });

  @override
  List<Object?> get props => [reviews, hasMore, currentPage];
}

class ReviewError extends ReviewState {
  final String message;

  const ReviewError({required this.message});

  @override
  List<Object?> get props => [message];
}

// ==================== BLOC ====================

class ReviewBloc extends Bloc<ReviewEvent, ReviewState> {
  final ReviewRepository _repository = ReviewRepository();

  ReviewBloc() : super(ReviewInitial()) {
    on<ReviewSubmit>(_onSubmit);
    on<ReviewUpdate>(_onUpdate);
    on<ReviewDelete>(_onDelete);
    on<ReviewMarkHelpful>(_onMarkHelpful);
    on<ReviewReport>(_onReport);
    on<ReviewLoadMine>(_onLoadMine);
  }

  Future<void> _onSubmit(
    ReviewSubmit event,
    Emitter<ReviewState> emit,
  ) async {
    emit(ReviewSubmitting());
    try {
      final review = await _repository.create(
        establishmentId: event.establishmentId,
        rating: event.rating,
        title: event.title,
        comment: event.comment,
        pros: event.pros,
        cons: event.cons,
        images: event.images,
        visitDate: event.visitDate,
        subRatings: event.subRatings,
      );

      emit(ReviewSubmitSuccess(
        review: review,
        message: 'Avis envoyé ! Il sera publié après modération.',
      ));
    } catch (e) {
      emit(ReviewError(message: e.toString()));
    }
  }

  Future<void> _onUpdate(
    ReviewUpdate event,
    Emitter<ReviewState> emit,
  ) async {
    emit(ReviewLoading());
    try {
      final review = await _repository.update(
        event.reviewId,
        rating: event.rating,
        title: event.title,
        comment: event.comment,
        pros: event.pros,
        cons: event.cons,
      );

      emit(ReviewUpdateSuccess(review: review));
    } catch (e) {
      emit(ReviewError(message: e.toString()));
    }
  }

  Future<void> _onDelete(
    ReviewDelete event,
    Emitter<ReviewState> emit,
  ) async {
    emit(ReviewLoading());
    try {
      await _repository.delete(event.reviewId);
      emit(ReviewDeleteSuccess(reviewId: event.reviewId));
    } catch (e) {
      emit(ReviewError(message: e.toString()));
    }
  }

  Future<void> _onMarkHelpful(
    ReviewMarkHelpful event,
    Emitter<ReviewState> emit,
  ) async {
    try {
      final count = await _repository.markHelpful(event.reviewId);
      emit(ReviewHelpfulSuccess(
        reviewId: event.reviewId,
        helpfulCount: count,
      ));
    } catch (e) {
      emit(ReviewError(message: e.toString()));
    }
  }

  Future<void> _onReport(
    ReviewReport event,
    Emitter<ReviewState> emit,
  ) async {
    try {
      await _repository.report(event.reviewId, event.reason);
      emit(ReviewReportSuccess());
    } catch (e) {
      emit(ReviewError(message: e.toString()));
    }
  }

  Future<void> _onLoadMine(
    ReviewLoadMine event,
    Emitter<ReviewState> emit,
  ) async {
    emit(ReviewLoading());
    try {
      final response = await _repository.getMyReviews(page: event.page);

      emit(ReviewMyListLoaded(
        reviews: response.items,
        hasMore: response.hasMore,
        currentPage: event.page,
      ));
    } catch (e) {
      emit(ReviewError(message: e.toString()));
    }
  }
}
