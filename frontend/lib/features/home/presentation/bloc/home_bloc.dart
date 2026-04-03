import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:win_app/features/establishment/data/repositories/establishment_repository.dart';

import '../../../../core/services/location_service.dart';
import '../../data/models/category_model.dart';
import '../../data/repositories/category_repository.dart';
import '../../../establishment/data/models/establishment_model.dart';

// ==================== EVENTS ====================

abstract class HomeEvent extends Equatable {
  const HomeEvent();

  @override
  List<Object?> get props => [];
}

class HomeLoadData extends HomeEvent {}

class HomeRefresh extends HomeEvent {}

class HomeLoadFeatured extends HomeEvent {}

class HomeLoadByWilaya extends HomeEvent {
  final String wilayaId;

  const HomeLoadByWilaya({required this.wilayaId});

  @override
  List<Object?> get props => [wilayaId];
}

class HomeLoadNearby extends HomeEvent {
  final String? fallbackWilayaId;

  const HomeLoadNearby({this.fallbackWilayaId});

  @override
  List<Object?> get props => [fallbackWilayaId];
}

// ==================== STATES ====================

abstract class HomeState extends Equatable {
  const HomeState();

  @override
  List<Object?> get props => [];
}

class HomeInitial extends HomeState {}

class HomeLoading extends HomeState {}

class HomeLoaded extends HomeState {
  final List<Category> categories;
  final List<Establishment> featured;
  final List<Establishment> nearby;
  final bool isLoadingNearby;

  const HomeLoaded({
    required this.categories,
    required this.featured,
    this.nearby = const [],
    this.isLoadingNearby = false,
  });

  HomeLoaded copyWith({
    List<Category>? categories,
    List<Establishment>? featured,
    List<Establishment>? nearby,
    bool? isLoadingNearby,
  }) {
    return HomeLoaded(
      categories: categories ?? this.categories,
      featured: featured ?? this.featured,
      nearby: nearby ?? this.nearby,
      isLoadingNearby: isLoadingNearby ?? this.isLoadingNearby,
    );
  }

  @override
  List<Object?> get props => [categories, featured, nearby, isLoadingNearby];
}

class HomeError extends HomeState {
  final String message;

  const HomeError({required this.message});

  @override
  List<Object?> get props => [message];
}

// ==================== BLOC ====================

class HomeBloc extends Bloc<HomeEvent, HomeState> {
  final CategoryRepository _categoryRepository = CategoryRepository();
  final EstablishmentRepository _establishmentRepository =
      EstablishmentRepository();

  HomeBloc() : super(HomeInitial()) {
    on<HomeLoadData>(_onLoadData);
    on<HomeRefresh>(_onRefresh);
    on<HomeLoadByWilaya>(_onLoadByWilaya);
    on<HomeLoadNearby>(_onLoadNearby);
  }

  Future<void> _onLoadData(
    HomeLoadData event,
    Emitter<HomeState> emit,
  ) async {
    emit(HomeLoading());
    try {
      // Load categories and top-rated in parallel
      final results = await Future.wait([
        _categoryRepository.getAll(),
        _establishmentRepository.getFeatured(limit: 10),
      ]);

      final categories = results[0] as List<Category>;
      final featured = results[1] as List<Establishment>;

      emit(HomeLoaded(
        categories: categories,
        featured: featured,
      ));
    } catch (e) {
      emit(HomeError(message: e.toString()));
    }
  }

  Future<void> _onRefresh(
    HomeRefresh event,
    Emitter<HomeState> emit,
  ) async {
    try {
      final results = await Future.wait([
        _categoryRepository.getAll(),
        _establishmentRepository.getFeatured(limit: 10),
      ]);

      final categories = results[0] as List<Category>;
      final featured = results[1] as List<Establishment>;

      final currentState = state;
      if (currentState is HomeLoaded) {
        emit(currentState.copyWith(
          categories: categories,
          featured: featured,
        ));
      } else {
        emit(HomeLoaded(
          categories: categories,
          featured: featured,
        ));
      }
    } catch (e) {
      // Keep current state on refresh error
      if (state is! HomeLoaded) {
        emit(HomeError(message: e.toString()));
      }
    }
  }

  Future<void> _onLoadByWilaya(
    HomeLoadByWilaya event,
    Emitter<HomeState> emit,
  ) async {
    final currentState = state;
    if (currentState is HomeLoaded) {
      emit(currentState.copyWith(isLoadingNearby: true));

      try {
        final result = await _establishmentRepository.getByWilaya(
          event.wilayaId,
          limit: 10,
        );

        emit(currentState.copyWith(
          nearby: result.items,
          isLoadingNearby: false,
        ));
      } catch (e) {
        emit(currentState.copyWith(isLoadingNearby: false));
      }
    }
  }

  Future<void> _onLoadNearby(
    HomeLoadNearby event,
    Emitter<HomeState> emit,
  ) async {
    final currentState = state;
    if (currentState is! HomeLoaded) return;

    emit(currentState.copyWith(isLoadingNearby: true));

    try {
      // Tente la géolocalisation GPS
      final position = await LocationService().getCurrentPosition();

      if (position != null) {
        final nearby = await _establishmentRepository.getNearby(
          latitude: position.latitude,
          longitude: position.longitude,
          radius: 5,
          limit: 10,
        );
        emit(currentState.copyWith(nearby: nearby, isLoadingNearby: false));
        return;
      }
    } catch (_) {}

    // Fallback : wilaya de l'utilisateur
    if (event.fallbackWilayaId != null) {
      try {
        final result = await _establishmentRepository.getByWilaya(
          event.fallbackWilayaId!,
          limit: 10,
        );
        emit(currentState.copyWith(
            nearby: result.items, isLoadingNearby: false));
        return;
      } catch (_) {}
    }

    emit(currentState.copyWith(isLoadingNearby: false));
  }
}
