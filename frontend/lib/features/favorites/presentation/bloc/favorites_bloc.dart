import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:win_app/features/favorites/data/repositories/favorites_repository.dart';

import '../../../establishment/data/models/establishment_model.dart';

// ==================== EVENTS ====================

abstract class FavoriteEvent extends Equatable {
  const FavoriteEvent();

  @override
  List<Object?> get props => [];
}

class FavoriteLoadList extends FavoriteEvent {
  final int page;
  final bool refresh;

  const FavoriteLoadList({this.page = 1, this.refresh = false});

  @override
  List<Object?> get props => [page, refresh];
}

class FavoriteToggle extends FavoriteEvent {
  final String establishmentId;

  const FavoriteToggle({required this.establishmentId});

  @override
  List<Object?> get props => [establishmentId];
}

class FavoriteRemove extends FavoriteEvent {
  final String establishmentId;

  const FavoriteRemove({required this.establishmentId});

  @override
  List<Object?> get props => [establishmentId];
}

class FavoriteClearAll extends FavoriteEvent {}

// ==================== STATES ====================

abstract class FavoriteState extends Equatable {
  const FavoriteState();

  @override
  List<Object?> get props => [];
}

class FavoriteInitial extends FavoriteState {}

class FavoriteLoading extends FavoriteState {}

class FavoriteLoaded extends FavoriteState {
  final List<Establishment> favorites;
  final bool hasMore;
  final int currentPage;
  final bool isLoadingMore;

  const FavoriteLoaded({
    required this.favorites,
    this.hasMore = false,
    this.currentPage = 1,
    this.isLoadingMore = false,
  });

  FavoriteLoaded copyWith({
    List<Establishment>? favorites,
    bool? hasMore,
    int? currentPage,
    bool? isLoadingMore,
  }) {
    return FavoriteLoaded(
      favorites: favorites ?? this.favorites,
      hasMore: hasMore ?? this.hasMore,
      currentPage: currentPage ?? this.currentPage,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    );
  }

  @override
  List<Object?> get props => [favorites, hasMore, currentPage, isLoadingMore];
}

class FavoriteError extends FavoriteState {
  final String message;

  const FavoriteError({required this.message});

  @override
  List<Object?> get props => [message];
}

class FavoriteToggleSuccess extends FavoriteState {
  final String establishmentId;
  final bool isFavorited;

  const FavoriteToggleSuccess({
    required this.establishmentId,
    required this.isFavorited,
  });

  @override
  List<Object?> get props => [establishmentId, isFavorited];
}

// ==================== BLOC ====================

class FavoriteBloc extends Bloc<FavoriteEvent, FavoriteState> {
  final FavoriteRepository _repository = FavoriteRepository();

  FavoriteBloc() : super(FavoriteInitial()) {
    on<FavoriteLoadList>(_onLoadList);
    on<FavoriteToggle>(_onToggle);
    on<FavoriteRemove>(_onRemove);
    on<FavoriteClearAll>(_onClearAll);
  }

  Future<void> _onLoadList(
    FavoriteLoadList event,
    Emitter<FavoriteState> emit,
  ) async {
    final currentState = state;

    if (event.refresh || currentState is! FavoriteLoaded) {
      emit(FavoriteLoading());
    } else {
      emit(currentState.copyWith(isLoadingMore: true));
    }

    try {
      final response = await _repository.getFavorites(
        page: event.page,
        limit: 20,
      );

      if (event.page == 1 || event.refresh) {
        emit(FavoriteLoaded(
          favorites: response.items,
          hasMore: response.hasMore,
          currentPage: event.page,
        ));
      } else if (currentState is FavoriteLoaded) {
        emit(FavoriteLoaded(
          favorites: [...currentState.favorites, ...response.items],
          hasMore: response.hasMore,
          currentPage: event.page,
        ));
      }
    } catch (e) {
      emit(FavoriteError(message: e.toString()));
    }
  }

  Future<void> _onToggle(
    FavoriteToggle event,
    Emitter<FavoriteState> emit,
  ) async {
    try {
      final isFavorited = await _repository.toggle(event.establishmentId);
      emit(FavoriteToggleSuccess(
        establishmentId: event.establishmentId,
        isFavorited: isFavorited,
      ));

      // Reload favorites if we're in loaded state
      add(const FavoriteLoadList(refresh: true));
    } catch (e) {
      emit(FavoriteError(message: e.toString()));
    }
  }

  Future<void> _onRemove(
    FavoriteRemove event,
    Emitter<FavoriteState> emit,
  ) async {
    final currentState = state;

    try {
      await _repository.remove(event.establishmentId);

      if (currentState is FavoriteLoaded) {
        final updatedFavorites = currentState.favorites
            .where((e) => e.id != event.establishmentId)
            .toList();
        emit(currentState.copyWith(favorites: updatedFavorites));
      }
    } catch (e) {
      emit(FavoriteError(message: e.toString()));
    }
  }

  Future<void> _onClearAll(
    FavoriteClearAll event,
    Emitter<FavoriteState> emit,
  ) async {
    try {
      await _repository.clearAll();
      emit(const FavoriteLoaded(favorites: []));
    } catch (e) {
      emit(FavoriteError(message: e.toString()));
    }
  }
}
