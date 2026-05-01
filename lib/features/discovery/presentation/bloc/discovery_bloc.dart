import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../domain/entities/charger_entity.dart';
import '../../domain/usecases/get_nearby_chargers_usecase.dart';

// ──── Events ────
abstract class DiscoveryEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class LoadNearbyChargers extends DiscoveryEvent {
  final double latitude;
  final double longitude;
  final double radiusMeters;
  final String? connectorType;

  LoadNearbyChargers({
    required this.latitude,
    required this.longitude,
    this.radiusMeters = 5000,
    this.connectorType,
  });

  @override
  List<Object?> get props => [latitude, longitude, radiusMeters, connectorType];
}

class SearchChargers extends DiscoveryEvent {
  final String query;
  SearchChargers(this.query);
  @override
  List<Object?> get props => [query];
}

class FilterByConnector extends DiscoveryEvent {
  final String? connectorType;
  FilterByConnector(this.connectorType);
  @override
  List<Object?> get props => [connectorType];
}

class SelectCharger extends DiscoveryEvent {
  final ChargerEntity charger;
  SelectCharger(this.charger);
  @override
  List<Object?> get props => [charger];
}

// ──── States ────
abstract class DiscoveryState extends Equatable {
  @override
  List<Object?> get props => [];
}

class DiscoveryInitial extends DiscoveryState {}

class DiscoveryLoading extends DiscoveryState {}

class DiscoveryLoaded extends DiscoveryState {
  final List<ChargerEntity> chargers;
  final ChargerEntity? selectedCharger;
  final String? activeFilter;

  DiscoveryLoaded({
    required this.chargers,
    this.selectedCharger,
    this.activeFilter,
  });

  @override
  List<Object?> get props => [chargers, selectedCharger, activeFilter];
}

class DiscoveryError extends DiscoveryState {
  final String message;
  DiscoveryError(this.message);
  @override
  List<Object?> get props => [message];
}

// ──── BLoC ────
class DiscoveryBloc extends Bloc<DiscoveryEvent, DiscoveryState> {
  final GetNearbyChargersUseCase getNearbyChargers;
  List<ChargerEntity> _allChargers = [];

  DiscoveryBloc({required this.getNearbyChargers}) : super(DiscoveryInitial()) {
    on<LoadNearbyChargers>(_onLoadNearby);
    on<SearchChargers>(_onSearch);
    on<FilterByConnector>(_onFilter);
    on<SelectCharger>(_onSelect);
  }

  Future<void> _onLoadNearby(
    LoadNearbyChargers event,
    Emitter<DiscoveryState> emit,
  ) async {
    emit(DiscoveryLoading());
    try {
      final chargers = await getNearbyChargers(
        latitude: event.latitude,
        longitude: event.longitude,
        radiusMeters: event.radiusMeters,
        connectorType: event.connectorType,
      );
      _allChargers = chargers;
      emit(DiscoveryLoaded(chargers: chargers));
    } catch (e) {
      emit(DiscoveryError(e.toString()));
    }
  }

  void _onFilter(FilterByConnector event, Emitter<DiscoveryState> emit) {
    final filtered = event.connectorType == null
        ? _allChargers
        : _allChargers
              .where((c) => c.connectorType == event.connectorType)
              .toList();
    emit(
      DiscoveryLoaded(chargers: filtered, activeFilter: event.connectorType),
    );
  }

  void _onSearch(SearchChargers event, Emitter<DiscoveryState> emit) {
    final query = event.query.trim().toLowerCase();
    if (query.isEmpty) {
      emit(DiscoveryLoaded(chargers: _allChargers));
      return;
    }
    final filtered = _allChargers.where((charger) {
      final title = charger.title.toLowerCase();
      final address = charger.address.toLowerCase();
      final city = charger.city.toLowerCase();
      return title.contains(query) ||
          address.contains(query) ||
          city.contains(query);
    }).toList();
    emit(DiscoveryLoaded(chargers: filtered));
  }

  void _onSelect(SelectCharger event, Emitter<DiscoveryState> emit) {
    if (state is DiscoveryLoaded) {
      final curr = state as DiscoveryLoaded;
      emit(
        DiscoveryLoaded(
          chargers: curr.chargers,
          selectedCharger: event.charger,
          activeFilter: curr.activeFilter,
        ),
      );
    }
  }
}
