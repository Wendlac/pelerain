import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/agency.dart';
import '../models/company.dart';
import '../models/trip.dart';

/// Read-only data access layer for the voyageur mobile app.
///
/// The MVP scope (per Pelerain_MVP_Specs.md §2) is a comparator only —
/// no auth, no booking. The mobile reads trips / companies / agencies
/// through the public RLS policies; the back-office continues to own the
/// write paths.
class SupabaseRepository {
  SupabaseRepository(this._client);

  final SupabaseClient _client;

  // ─── Companies ──────────────────────────────────────────────────────────

  /// Fetches all companies with their agencies attached (one query each).
  /// For a catalogue of this size (a few dozen rows) the extra round-trips
  /// are negligible and the code stays simple.
  Future<List<Company>> fetchCompanies() async {
    final companyRows = await _client
        .from('companies')
        .select()
        .order('name');

    final agencyRows = await _client
        .from('agencies')
        .select()
        .order('city');

    final agenciesByCompany = <String, List<Agency>>{};
    for (final row in agencyRows as List) {
      final json = row as Map<String, dynamic>;
      final companyId = json['company_id'] as String;
      (agenciesByCompany[companyId] ??= []).add(Agency.fromJson(json));
    }

    return (companyRows as List)
        .map((row) {
          final json = row as Map<String, dynamic>;
          return Company.fromJson(
            json,
            agencies: agenciesByCompany[json['id']] ?? const [],
          );
        })
        .toList();
  }

  /// Fetches a single company by id, with agencies populated.
  Future<Company?> fetchCompany(String id) async {
    final row = await _client
        .from('companies')
        .select()
        .eq('id', id)
        .maybeSingle();
    if (row == null) return null;

    final agencyRows = await _client
        .from('agencies')
        .select()
        .eq('company_id', id)
        .order('city');

    final agencies = (agencyRows as List)
        .map((r) => Agency.fromJson(r as Map<String, dynamic>))
        .toList();

    return Company.fromJson(row, agencies: agencies);
  }

  // ─── Trips (projected from recurring schedules) ─────────────────────────

  /// Searches active trips matching the criteria.
  ///
  /// The data model: recurring `schedules` (one row per "every-day"
  /// departure) are projected onto the calendar [date] picked by the
  /// traveler. Filters applied at SQL level: route + status + day-of-week
  /// presence in `days_of_week` + active window (`active_from`/`active_until`).
  ///
  /// Trips for "today" whose departure time has already passed are dropped
  /// in Dart after projection — pgSQL can't compare time-of-day against
  /// "now in the user's timezone" easily, so we do it client-side.
  Future<List<Trip>> searchTrips({
    required String departureCity,
    required String arrivalCity,
    required DateTime date,
  }) async {
    // ISO weekday: Mon=1 ... Sun=7. Matches the convention in schedules.days_of_week.
    final isoWeekday = date.weekday;
    final dateStr =
        '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

    final rows = await _client
        .from('schedules')
        .select('*, companies(*)')
        .ilike('departure_city', departureCity)
        .ilike('arrival_city', arrivalCity)
        .eq('status', 'active')
        .contains('days_of_week', [isoWeekday])
        .lte('active_from', dateStr)
        .or('active_until.is.null,active_until.gte.$dateStr')
        .order('departure_time_local');

    final now = DateTime.now();
    final trips = (rows as List).map((row) {
      final json = row as Map<String, dynamic>;
      final companyJson = json['companies'] as Map<String, dynamic>;
      final company = Company.fromJson(companyJson);
      return Trip.fromSchedule(json, company: company, date: date);
    }).where((trip) {
      // Hide already-departed trips when searching today.
      return trip.departureTime.isAfter(now);
    }).toList();

    return trips;
  }

  /// Fetches the next [limit] upcoming trips across all routes, useful for
  /// an "explore" UI. Projects each schedule onto whichever of the next 7
  /// days it actually runs, then keeps the earliest.
  Future<List<Trip>> fetchUpcomingTrips({int limit = 20}) async {
    final rows = await _client
        .from('schedules')
        .select('*, companies(*)')
        .eq('status', 'active')
        .order('departure_time_local');

    final now = DateTime.now();
    final trips = <Trip>[];

    for (final row in rows as List) {
      final json = row as Map<String, dynamic>;
      final companyJson = json['companies'] as Map<String, dynamic>;
      final company = Company.fromJson(companyJson);

      // Walk the next 7 days to find the first one where this schedule runs
      // AND whose projected departure is still in the future.
      for (var d = 0; d < 7; d++) {
        final date = DateTime(now.year, now.month, now.day + d);
        final daysOfWeek = (json['days_of_week'] as List)
            .map((e) => (e as num).toInt())
            .toSet();
        if (!daysOfWeek.contains(date.weekday)) continue;

        final trip =
            Trip.fromSchedule(json, company: company, date: date);
        if (trip.departureTime.isAfter(now)) {
          trips.add(trip);
          break;
        }
      }
    }

    trips.sort((a, b) => a.departureTime.compareTo(b.departureTime));
    return trips.take(limit).toList();
  }
}
