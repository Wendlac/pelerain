import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/search_params.dart';
import '../models/trip.dart';
import '../repositories/mock_data.dart';

final searchParamsProvider = StateProvider<SearchParams?>((ref) => null);

final searchResultsProvider = StateNotifierProvider<SearchResultsNotifier, AsyncValue<List<Trip>>>(
  (ref) => SearchResultsNotifier(),
);

class SearchResultsNotifier extends StateNotifier<AsyncValue<List<Trip>>> {
  SearchResultsNotifier() : super(const AsyncValue.data([]));

  Future<void> search(SearchParams params) async {
    state = const AsyncValue.loading();
    await Future.delayed(const Duration(milliseconds: 800)); // simulate API
    final results = MockData.getTrips(
      departureCity: params.departureCity,
      arrivalCity: params.arrivalCity,
      date: params.date,
    );
    state = AsyncValue.data(results);
  }

  void clear() => state = const AsyncValue.data([]);
}

// Sort
enum SortOption { price, time, duration }

final sortOptionProvider = StateProvider<SortOption>((ref) => SortOption.price);

// Filters
enum TimeSlot { any, morning, afternoon, evening }

extension TimeSlotLabel on TimeSlot {
  String get label {
    switch (this) {
      case TimeSlot.any: return 'Tous';
      case TimeSlot.morning: return 'Matin (6h–12h)';
      case TimeSlot.afternoon: return 'Après-midi (12h–18h)';
      case TimeSlot.evening: return 'Soir (18h+)';
    }
  }

  String get shortLabel {
    switch (this) {
      case TimeSlot.any: return 'Tous horaires';
      case TimeSlot.morning: return 'Matin';
      case TimeSlot.afternoon: return 'Après-midi';
      case TimeSlot.evening: return 'Soir';
    }
  }
}

/// Set of selected company IDs — empty means "all"
final companyFilterProvider = StateProvider<Set<String>>((ref) => const {});

/// Selected time slot
final timeSlotFilterProvider = StateProvider<TimeSlot>((ref) => TimeSlot.any);

/// Number of active filters (for the badge)
final activeFilterCountProvider = Provider<int>((ref) {
  int count = 0;
  if (ref.watch(companyFilterProvider).isNotEmpty) count++;
  if (ref.watch(timeSlotFilterProvider) != TimeSlot.any) count++;
  return count;
});

final filteredTripsProvider = Provider<List<Trip>>((ref) {
  final results = ref.watch(searchResultsProvider);
  final sort = ref.watch(sortOptionProvider);
  final companyFilter = ref.watch(companyFilterProvider);
  final timeSlot = ref.watch(timeSlotFilterProvider);

  return results.when(
    data: (trips) {
      var filtered = List<Trip>.from(trips);

      // Company filter
      if (companyFilter.isNotEmpty) {
        filtered = filtered.where((t) => companyFilter.contains(t.company.id)).toList();
      }

      // Time slot filter
      if (timeSlot != TimeSlot.any) {
        filtered = filtered.where((t) {
          final h = t.departureTime.hour;
          switch (timeSlot) {
            case TimeSlot.morning:   return h >= 6  && h < 12;
            case TimeSlot.afternoon: return h >= 12 && h < 18;
            case TimeSlot.evening:   return h >= 18;
            case TimeSlot.any:       return true;
          }
        }).toList();
      }

      // Sort
      switch (sort) {
        case SortOption.price:
          filtered.sort((a, b) => a.price.compareTo(b.price));
        case SortOption.time:
          filtered.sort((a, b) => a.departureTime.compareTo(b.departureTime));
        case SortOption.duration:
          filtered.sort((a, b) => a.duration.compareTo(b.duration));
      }
      return filtered;
    },
    loading: () => [],
    error: (_, __) => [],
  );
});
