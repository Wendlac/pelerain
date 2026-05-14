/// Supabase project configuration.
///
/// In production, these should come from `--dart-define` flags so they don't
/// end up in version control. For development we keep them inline.
///
/// Run release builds with:
///   flutter build apk --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...
class SupabaseConfig {
  SupabaseConfig._();

  static const String url = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://eekuzvmrbyribnhmrihh.supabase.co',
  );

  static const String anonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue:
        'sb_publishable_YP9_D6NvTDyyOkx0adBFjQ_pfs-G-vR',
  );
}
