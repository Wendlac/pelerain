import 'agency.dart';

class Company {
  final String id;
  final String name;
  final String phone;
  final String? logoUrl;
  final double rating;
  final int totalTrips;
  final String? description;
  final List<Agency> agencies;

  const Company({
    required this.id,
    required this.name,
    required this.phone,
    this.logoUrl,
    this.rating = 4.0,
    this.totalTrips = 0,
    this.description,
    this.agencies = const [],
  });

  /// Returns agencies grouped by city: { 'Ouagadougou': [...], 'Bobo-Dioulasso': [...] }
  Map<String, List<Agency>> get agenciesByCity {
    final map = <String, List<Agency>>{};
    for (final a in agencies) {
      map.putIfAbsent(a.city, () => []).add(a);
    }
    return map;
  }
}
