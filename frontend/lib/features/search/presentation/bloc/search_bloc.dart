import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:win_app/features/establishment/data/repositories/establishment_repository.dart';
import 'package:win_app/features/home/data/repositories/category_repository.dart';
import 'package:win_app/features/home/data/models/category_model.dart';

import '../../../establishment/data/models/establishment_model.dart';

// ==================== EVENTS ====================

abstract class SearchEvent extends Equatable {
  const SearchEvent();

  @override
  List<Object?> get props => [];
}

/// Event pour charger les données initiales (catégories et wilayas)
class SearchLoadInitialData extends SearchEvent {}

/// Event pour les suggestions en temps réel (debounced)
class SearchSuggestions extends SearchEvent {
  final String query;

  const SearchSuggestions({required this.query});

  @override
  List<Object?> get props => [query];
}

/// Event pour effacer les suggestions
class SearchClearSuggestions extends SearchEvent {}

/// Event interne pour exécuter les suggestions après debounce
class _SearchSuggestionsExecute extends SearchEvent {
  final String query;

  const _SearchSuggestionsExecute({required this.query});

  @override
  List<Object?> get props => [query];
}

class SearchQuery extends SearchEvent {
  final String query;
  final String? categoryId;
  final String? wilayaId;
  final String? priceRange;
  final double? minRating;
  final bool? isVerified;
  final String? sortBy;
  final String? sortOrder;
  final int page;

  const SearchQuery({
    required this.query,
    this.categoryId,
    this.wilayaId,
    this.priceRange,
    this.minRating,
    this.isVerified,
    this.sortBy,
    this.sortOrder,
    this.page = 1,
  });

  @override
  List<Object?> get props => [
        query,
        categoryId,
        wilayaId,
        priceRange,
        minRating,
        isVerified,
        sortBy,
        sortOrder,
        page,
      ];
}

class SearchLoadMore extends SearchEvent {}

class SearchClear extends SearchEvent {}

class SearchUpdateFilters extends SearchEvent {
  final String? categoryId;
  final String? wilayaId;
  final String? priceRange;
  final double? minRating;
  final bool? isVerified;
  final String? sortBy;
  final String? sortOrder;

  const SearchUpdateFilters({
    this.categoryId,
    this.wilayaId,
    this.priceRange,
    this.minRating,
    this.isVerified,
    this.sortBy,
    this.sortOrder,
  });

  @override
  List<Object?> get props => [
        categoryId,
        wilayaId,
        priceRange,
        minRating,
        isVerified,
        sortBy,
        sortOrder,
      ];
}

// ==================== STATES ====================

abstract class SearchState extends Equatable {
  final List<Category> categories;
  final List<Wilaya> wilayas;
  final List<Establishment> suggestions;
  final bool isLoadingSuggestions;

  const SearchState({
    this.categories = const [],
    this.wilayas = const [],
    this.suggestions = const [],
    this.isLoadingSuggestions = false,
  });

  @override
  List<Object?> get props => [categories, wilayas, suggestions, isLoadingSuggestions];
}

class SearchInitial extends SearchState {
  const SearchInitial({
    super.categories,
    super.wilayas,
    super.suggestions,
    super.isLoadingSuggestions,
  });
}

class SearchLoading extends SearchState {
  const SearchLoading({
    super.categories,
    super.wilayas,
    super.suggestions,
    super.isLoadingSuggestions,
  });
}

class SearchLoaded extends SearchState {
  final String query;
  final List<Establishment> results;
  final bool hasMore;
  final int currentPage;
  final bool isLoadingMore;
  final SearchFilters filters;

  const SearchLoaded({
    required this.query,
    required this.results,
    this.hasMore = false,
    this.currentPage = 1,
    this.isLoadingMore = false,
    this.filters = const SearchFilters(),
    super.categories,
    super.wilayas,
    super.suggestions,
    super.isLoadingSuggestions,
  });

  SearchLoaded copyWith({
    String? query,
    List<Establishment>? results,
    bool? hasMore,
    int? currentPage,
    bool? isLoadingMore,
    SearchFilters? filters,
    List<Category>? categories,
    List<Wilaya>? wilayas,
    List<Establishment>? suggestions,
    bool? isLoadingSuggestions,
  }) {
    return SearchLoaded(
      query: query ?? this.query,
      results: results ?? this.results,
      hasMore: hasMore ?? this.hasMore,
      currentPage: currentPage ?? this.currentPage,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      filters: filters ?? this.filters,
      categories: categories ?? this.categories,
      wilayas: wilayas ?? this.wilayas,
      suggestions: suggestions ?? this.suggestions,
      isLoadingSuggestions: isLoadingSuggestions ?? this.isLoadingSuggestions,
    );
  }

  @override
  List<Object?> get props => [
        query,
        results,
        hasMore,
        currentPage,
        isLoadingMore,
        filters,
        categories,
        wilayas,
        suggestions,
        isLoadingSuggestions,
      ];
}

class SearchError extends SearchState {
  final String message;

  const SearchError({
    required this.message,
    super.categories,
    super.wilayas,
    super.suggestions,
    super.isLoadingSuggestions,
  });

  @override
  List<Object?> get props => [message, categories, wilayas, suggestions, isLoadingSuggestions];
}

class SearchFilters extends Equatable {
  final String? categoryId;
  final String? wilayaId;
  final String? priceRange;
  final double? minRating;
  final bool? isVerified;
  final String? sortBy;
  final String? sortOrder;

  const SearchFilters({
    this.categoryId,
    this.wilayaId,
    this.priceRange,
    this.minRating,
    this.isVerified,
    this.sortBy,
    this.sortOrder,
  });

  SearchFilters copyWith({
    String? categoryId,
    String? wilayaId,
    String? priceRange,
    double? minRating,
    bool? isVerified,
    String? sortBy,
    String? sortOrder,
  }) {
    return SearchFilters(
      categoryId: categoryId ?? this.categoryId,
      wilayaId: wilayaId ?? this.wilayaId,
      priceRange: priceRange ?? this.priceRange,
      minRating: minRating ?? this.minRating,
      isVerified: isVerified ?? this.isVerified,
      sortBy: sortBy ?? this.sortBy,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }

  @override
  List<Object?> get props => [
        categoryId,
        wilayaId,
        priceRange,
        minRating,
        isVerified,
        sortBy,
        sortOrder,
      ];
}

// ==================== BLOC ====================

class SearchBloc extends Bloc<SearchEvent, SearchState> {
  final EstablishmentRepository _repository = EstablishmentRepository();
  final CategoryRepository _categoryRepository = CategoryRepository();
  final WilayaRepository _wilayaRepository = WilayaRepository();

  Timer? _debounceTimer;

  SearchBloc() : super(const SearchInitial()) {
    on<SearchLoadInitialData>(_onLoadInitialData);
    on<SearchSuggestions>(_onSuggestions);
    on<_SearchSuggestionsExecute>(_onSuggestionsExecute);
    on<SearchClearSuggestions>(_onClearSuggestions);
    on<SearchQuery>(_onSearch);
    on<SearchLoadMore>(_onLoadMore);
    on<SearchClear>(_onClear);
    on<SearchUpdateFilters>(_onUpdateFilters);
  }

  @override
  Future<void> close() {
    _debounceTimer?.cancel();
    return super.close();
  }

  Future<void> _onLoadInitialData(
    SearchLoadInitialData event,
    Emitter<SearchState> emit,
  ) async {
    try {
      final results = await Future.wait([
        _categoryRepository.getAll(),
        _wilayaRepository.getAll(),
      ]);

      final categories = results[0] as List<Category>;
      final wilayas = results[1] as List<Wilaya>;

      print('SearchBloc: Loaded ${categories.length} categories and ${wilayas.length} wilayas');

      emit(SearchInitial(
        categories: categories,
        wilayas: wilayas,
      ));
    } catch (e, stackTrace) {
      print('SearchBloc: Error loading initial data: $e');
      print('StackTrace: $stackTrace');
    }
  }

  Future<void> _onSuggestions(
    SearchSuggestions event,
    Emitter<SearchState> emit,
  ) async {
    // Cancel previous timer
    _debounceTimer?.cancel();

    // If query is too short, clear suggestions
    if (event.query.length < 2) {
      emit(_copyStateWith(suggestions: [], isLoadingSuggestions: false));
      return;
    }

    // Debounce: wait 300ms before making API call
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      add(_SearchSuggestionsExecute(query: event.query));
    });
  }

  Future<void> _onClearSuggestions(
    SearchClearSuggestions event,
    Emitter<SearchState> emit,
  ) async {
    _debounceTimer?.cancel();
    emit(_copyStateWith(suggestions: [], isLoadingSuggestions: false));
  }

  Future<void> _onSuggestionsExecute(
    _SearchSuggestionsExecute event,
    Emitter<SearchState> emit,
  ) async {
    emit(_copyStateWith(isLoadingSuggestions: true));

    try {
      final response = await _repository.search(
        query: event.query,
        limit: 5,
      );

      emit(_copyStateWith(
        suggestions: response.items,
        isLoadingSuggestions: false,
      ));
    } catch (e) {
      emit(_copyStateWith(suggestions: [], isLoadingSuggestions: false));
    }
  }

  SearchState _copyStateWith({
    List<Category>? categories,
    List<Wilaya>? wilayas,
    List<Establishment>? suggestions,
    bool? isLoadingSuggestions,
  }) {
    final currentState = state;
    if (currentState is SearchLoaded) {
      return currentState.copyWith(
        categories: categories,
        wilayas: wilayas,
        suggestions: suggestions,
        isLoadingSuggestions: isLoadingSuggestions,
      );
    }
    return SearchInitial(
      categories: categories ?? currentState.categories,
      wilayas: wilayas ?? currentState.wilayas,
      suggestions: suggestions ?? currentState.suggestions,
      isLoadingSuggestions: isLoadingSuggestions ?? currentState.isLoadingSuggestions,
    );
  }

  Future<void> _onSearch(
    SearchQuery event,
    Emitter<SearchState> emit,
  ) async {
    final currentCategories = state.categories;
    final currentWilayas = state.wilayas;

    if (event.page == 1) {
      emit(SearchLoading(
        categories: currentCategories,
        wilayas: currentWilayas,
      ));
    }

    try {
      final response = await _repository.search(
        query: event.query,
        categoryId: event.categoryId,
        wilayaId: event.wilayaId,
        priceRange: event.priceRange,
        minRating: event.minRating,
        isVerified: event.isVerified,
        sortBy: event.sortBy,
        sortOrder: event.sortOrder,
        page: event.page,
      );

      emit(SearchLoaded(
        query: event.query,
        results: response.items,
        hasMore: response.hasMore,
        currentPage: event.page,
        filters: SearchFilters(
          categoryId: event.categoryId,
          wilayaId: event.wilayaId,
          priceRange: event.priceRange,
          minRating: event.minRating,
          isVerified: event.isVerified,
          sortBy: event.sortBy,
          sortOrder: event.sortOrder,
        ),
        categories: currentCategories,
        wilayas: currentWilayas,
        suggestions: [],
      ));
    } catch (e) {
      emit(SearchError(
        message: e.toString(),
        categories: currentCategories,
        wilayas: currentWilayas,
      ));
    }
  }

  Future<void> _onLoadMore(
    SearchLoadMore event,
    Emitter<SearchState> emit,
  ) async {
    final currentState = state;
    if (currentState is SearchLoaded && currentState.hasMore) {
      emit(currentState.copyWith(isLoadingMore: true));

      try {
        final response = await _repository.search(
          query: currentState.query,
          categoryId: currentState.filters.categoryId,
          wilayaId: currentState.filters.wilayaId,
          priceRange: currentState.filters.priceRange,
          minRating: currentState.filters.minRating,
          isVerified: currentState.filters.isVerified,
          sortBy: currentState.filters.sortBy,
          sortOrder: currentState.filters.sortOrder,
          page: currentState.currentPage + 1,
        );

        emit(currentState.copyWith(
          results: [...currentState.results, ...response.items],
          hasMore: response.hasMore,
          currentPage: currentState.currentPage + 1,
          isLoadingMore: false,
        ));
      } catch (e) {
        emit(currentState.copyWith(isLoadingMore: false));
      }
    }
  }

  void _onClear(
    SearchClear event,
    Emitter<SearchState> emit,
  ) {
    emit(SearchInitial());
  }

  void _onUpdateFilters(
    SearchUpdateFilters event,
    Emitter<SearchState> emit,
  ) {
    final currentState = state;
    if (currentState is SearchLoaded) {
      // Re-search with new filters
      add(SearchQuery(
        query: currentState.query,
        categoryId: event.categoryId,
        wilayaId: event.wilayaId,
        priceRange: event.priceRange,
        minRating: event.minRating,
        isVerified: event.isVerified,
        sortBy: event.sortBy,
        sortOrder: event.sortOrder,
      ));
    }
  }
}
