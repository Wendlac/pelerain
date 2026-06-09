/// Static lookup data used by the mobile MVP city picker.
///
/// The real catalogue lives in Supabase (`public.cities`) and is managed by
/// the Pelerain team via the back-office. Mobile reads anonymously through
/// the public RLS policies. Until we wire a `citiesProvider` against
/// Supabase, this static list keeps the picker working and matches the seed.
class MockData {
  MockData._();

  /// Cities served by Pelerain partners. The MVP focuses on the
  /// Ouagadougou ↔ Bobo-Dioulasso axis (per Pelerain_MVP_Specs.md §2)
  /// but the picker still exposes the wider list so the codebase is ready
  /// when more axes go live.
  static const List<String> cities = [
    'Ouagadougou',
    'Bobo-Dioulasso',
    'Koudougou',
    'Banfora',
    'Ouahigouya',
    'Kaya',
    'Tenkodogo',
    "Fada N'Gourma",
    'Dédougou',
    'Gaoua',
    'Kongoussi',
    'Ziniaré',
    'Réo',
    'Houndé',
    'Léo',
  ];
}
