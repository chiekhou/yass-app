import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:win_app/features/establishment/data/repositories/establishment_repository.dart';
import 'package:win_app/features/favorites/data/repositories/favorites_repository.dart';
import 'package:win_app/features/reviews/data/repositories/reviews_repository.dart';

import '../../data/models/establishment_model.dart';
import '../../../reviews/data/models/review_model.dart';

// ==================== EVENTS ====================

abstract class EstablishmentEvent extends Equatable {
  const EstablishmentEvent();

  @override
  List<Object?> get props => [];
}

class EstablishmentLoadById extends EstablishmentEvent {
  final String id;

  const EstablishmentLoadById({required this.id});

  @override
  List<Object?> get props => [id];
}

class EstablishmentLoadBySlug extends EstablishmentEvent {
  final String slug;

  const EstablishmentLoadBySlug({required this.slug});

  @override
  List<Object?> get props => [slug];
}

class EstablishmentToggleFavorite extends EstablishmentEvent {}

class EstablishmentLoadReviews extends EstablishmentEvent {
  final int page;

  const EstablishmentLoadReviews({this.page = 1});

  @override
  List<Object?> get props => [page];
}

class EstablishmentTrackPhone extends EstablishmentEvent {}

class EstablishmentTrackWhatsApp extends EstablishmentEvent {}

// ==================== STATES ====================

abstract class EstablishmentState extends Equatable {
  const EstablishmentState();

  @override
  List<Object?> get props => [];
}

class EstablishmentInitial extends EstablishmentState {}

class EstablishmentLoading extends EstablishmentState {}

class EstablishmentLoaded extends EstablishmentState {
  final Establishment establishment;
  final bool isFavorited;
  final List<Review> reviews;
  final ReviewsResponse? reviewsData;
  final bool isLoadingReviews;

  const EstablishmentLoaded({
    required this.establishment,
    this.isFavorited = false,
    this.reviews = const [],
    this.reviewsData,
    this.isLoadingReviews = false,
  });

  EstablishmentLoaded copyWith({
    Establishment? establishment,
    bool? isFavorited,
    List<Review>? reviews,
    ReviewsResponse? reviewsData,
    bool? isLoadingReviews,
  }) {
    return EstablishmentLoaded(
      establishment: establishment ?? this.establishment,
      isFavorited: isFavorited ?? this.isFavorited,
      reviews: reviews ?? this.reviews,
      reviewsData: reviewsData ?? this.reviewsData,
      isLoadingReviews: isLoadingReviews ?? this.isLoadingReviews,
    );
  }

  @override
  List<Object?> get props => [
        establishment,
        isFavorited,
        reviews,
        reviewsData,
        isLoadingReviews,
      ];
}

class EstablishmentError extends EstablishmentState {
  final String message;

  const EstablishmentError({required this.message});

  @override
  List<Object?> get props => [message];
}

// ==================== BLOC ====================

class EstablishmentBloc extends Bloc<EstablishmentEvent, EstablishmentState> {
  final EstablishmentRepository _repository = EstablishmentRepository();
  final ReviewRepository _reviewRepository = ReviewRepository();
  final FavoriteRepository _favoriteRepository = FavoriteRepository();

  EstablishmentBloc() : super(EstablishmentInitial()) {
    on<EstablishmentLoadById>(_onLoadById);
    on<EstablishmentLoadBySlug>(_onLoadBySlug);
    on<EstablishmentToggleFavorite>(_onToggleFavorite);
    on<EstablishmentLoadReviews>(_onLoadReviews);
    on<EstablishmentTrackPhone>(_onTrackPhone);
    on<EstablishmentTrackWhatsApp>(_onTrackWhatsApp);
  }

  Future<void> _onLoadById(
    EstablishmentLoadById event,
    Emitter<EstablishmentState> emit,
  ) async {
    emit(EstablishmentLoading());
    try {
      final establishment = await _repository.getById(event.id);

      // Check if favorited
      bool isFavorited = false;
      try {
        isFavorited = await _favoriteRepository.isFavorited(event.id);
      } catch (_) {}

      emit(EstablishmentLoaded(
        establishment: establishment,
        isFavorited: isFavorited,
      ));

      // Load reviews
      add(const EstablishmentLoadReviews());
    } catch (e) {
      emit(EstablishmentError(message: e.toString()));
    }
  }

  Future<void> _onLoadBySlug(
    EstablishmentLoadBySlug event,
    Emitter<EstablishmentState> emit,
  ) async {
    emit(EstablishmentLoading());
    try {
      final establishment = await _repository.getBySlug(event.slug);

      // Check if favorited
      bool isFavorited = false;
      try {
        isFavorited = await _favoriteRepository.isFavorited(establishment.id);
      } catch (_) {}

      emit(EstablishmentLoaded(
        establishment: establishment,
        isFavorited: isFavorited,
      ));

      // Load reviews
      add(const EstablishmentLoadReviews());
    } catch (e) {
      emit(EstablishmentError(message: e.toString()));
    }
  }

  Future<void> _onToggleFavorite(
    EstablishmentToggleFavorite event,
    Emitter<EstablishmentState> emit,
  ) async {
    final currentState = state;
    if (currentState is EstablishmentLoaded) {
      try {
        final isFavorited = await _favoriteRepository.toggle(
          currentState.establishment.id,
        );
        emit(currentState.copyWith(isFavorited: isFavorited));
      } catch (e) {
        // Silently fail
      }
    }
  }

  Future<void> _onLoadReviews(
    EstablishmentLoadReviews event,
    Emitter<EstablishmentState> emit,
  ) async {
    final currentState = state;
    if (currentState is EstablishmentLoaded) {
      emit(currentState.copyWith(isLoadingReviews: true));

      try {
        final reviewsData = await _reviewRepository.getEstablishmentReviews(
          currentState.establishment.id,
          page: event.page,
        );

        emit(currentState.copyWith(
          reviews: reviewsData.reviews,
          reviewsData: reviewsData,
          isLoadingReviews: false,
        ));
      } catch (e) {
        emit(currentState.copyWith(isLoadingReviews: false));
      }
    }
  }

  Future<void> _onTrackPhone(
    EstablishmentTrackPhone event,
    Emitter<EstablishmentState> emit,
  ) async {
    final currentState = state;
    if (currentState is EstablishmentLoaded) {
      try {
        await _repository.trackPhoneClick(currentState.establishment.id);
      } catch (_) {}
    }
  }

  Future<void> _onTrackWhatsApp(
    EstablishmentTrackWhatsApp event,
    Emitter<EstablishmentState> emit,
  ) async {
    final currentState = state;
    if (currentState is EstablishmentLoaded) {
      try {
        await _repository.trackWhatsAppClick(currentState.establishment.id);
      } catch (_) {}
    }
  }
}
