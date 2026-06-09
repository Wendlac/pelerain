import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../repositories/supabase_repository.dart';

/// Global Supabase client. The MVP mobile app reads anonymously through
/// the public RLS policies on trips / companies / agencies; no auth
/// providers are exposed here.
final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

/// Singleton repository instance.
final supabaseRepositoryProvider = Provider<SupabaseRepository>((ref) {
  return SupabaseRepository(ref.watch(supabaseClientProvider));
});
