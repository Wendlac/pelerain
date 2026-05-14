import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../repositories/supabase_repository.dart';

/// Exposes the global Supabase client to the rest of the app via Riverpod.
final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

/// Singleton repository instance.
final supabaseRepositoryProvider = Provider<SupabaseRepository>((ref) {
  return SupabaseRepository(ref.watch(supabaseClientProvider));
});

/// Streams auth state changes. Used by the router to redirect unauth'd users.
final authStateChangesProvider = StreamProvider<AuthState>((ref) {
  return ref.watch(supabaseClientProvider).auth.onAuthStateChange;
});

/// Current session (or null if logged out). Synchronous — safe to read in
/// the router's `refreshListenable` or any place that just needs to know
/// "am I logged in right now".
final currentSessionProvider = Provider<Session?>((ref) {
  // Re-read whenever auth state changes
  ref.watch(authStateChangesProvider);
  return ref.watch(supabaseClientProvider).auth.currentSession;
});

/// Convenience: just the current user id, or null.
final currentUserIdProvider = Provider<String?>((ref) {
  return ref.watch(currentSessionProvider)?.user.id;
});
