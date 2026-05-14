import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gap/gap.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/haptic_service.dart';
import '../../../shared/providers/supabase_provider.dart';

/// Combined login / signup screen.
///
/// Toggles between the two modes locally — uses Supabase email + password auth.
/// After success, the router's auth-aware redirect takes the user to /home.
class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

enum _AuthMode { login, signup }

class _AuthScreenState extends ConsumerState<AuthScreen> {
  _AuthMode _mode = _AuthMode.login;

  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();

  bool _loading = false;
  String? _error;
  bool _obscure = true;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  bool get _isLogin => _mode == _AuthMode.login;

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    final client = ref.read(supabaseClientProvider);
    try {
      if (_isLogin) {
        await client.auth.signInWithPassword(
          email: _emailCtrl.text.trim(),
          password: _passwordCtrl.text,
        );
      } else {
        final response = await client.auth.signUp(
          email: _emailCtrl.text.trim(),
          password: _passwordCtrl.text,
          data: {'full_name': _nameCtrl.text.trim()},
        );
        // If the Supabase project requires email confirmation, signUp returns
        // a user but no session — meaning the router won't redirect. Try to
        // sign them in directly: in dev (confirmation disabled) this works
        // and gives us a session; in prod we surface a clearer message.
        if (response.session == null) {
          try {
            await client.auth.signInWithPassword(
              email: _emailCtrl.text.trim(),
              password: _passwordCtrl.text,
            );
          } on AuthException {
            // Sign-in failed → email confirmation is on. Tell the user.
            if (mounted) {
              setState(() {
                _error =
                    'Compte créé. Confirmez votre email avant de vous connecter.';
                _loading = false;
                _mode = _AuthMode.login;
              });
            }
            return;
          }
        }
      }
      HapticService.success();
      // The router redirects automatically once Supabase emits the new session
    } on AuthException catch (e) {
      HapticService.error();
      setState(() => _error = _frenchAuthError(e.message));
    } catch (e) {
      HapticService.error();
      setState(() => _error = 'Une erreur est survenue. Réessayez.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _frenchAuthError(String raw) {
    final lower = raw.toLowerCase();
    if (lower.contains('invalid login')) return 'Email ou mot de passe incorrect.';
    if (lower.contains('already registered') || lower.contains('user already')) {
      return 'Un compte existe déjà avec cet email.';
    }
    if (lower.contains('password')) return 'Mot de passe trop court (minimum 6 caractères).';
    if (lower.contains('email')) return 'Email invalide.';
    if (lower.contains('network')) return 'Pas de connexion internet.';
    return raw;
  }

  void _toggleMode() {
    HapticService.selection();
    setState(() {
      _mode = _isLogin ? _AuthMode.signup : _AuthMode.login;
      _error = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 32, 24, 32),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Brand header ──
                Center(
                  child: Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF5A0FA8), Color(0xFF9B4FFF)],
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(
                      Icons.directions_bus_rounded,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                ),
                const Gap(24),

                Text(
                  _isLogin ? 'Bon retour !' : 'Créer un compte',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.dmSans(
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    color: AppColors.content,
                    letterSpacing: -1.2,
                  ),
                ),
                const Gap(8),
                Text(
                  _isLogin
                      ? 'Connectez-vous pour réserver vos trajets'
                      : 'Rejoignez Pelerain en quelques secondes',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.dmSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: AppColors.contentTertiary,
                  ),
                ),
                const Gap(36),

                // ── Form fields ──
                if (!_isLogin) ...[
                  _LabelledField(
                    label: 'Nom complet',
                    child: TextFormField(
                      controller: _nameCtrl,
                      textInputAction: TextInputAction.next,
                      decoration: _inputDecoration('Awa Ouédraogo', Icons.person_outline_rounded),
                      validator: (v) {
                        if ((v ?? '').trim().length < 2) return 'Entrez votre nom';
                        return null;
                      },
                    ),
                  ),
                  const Gap(16),
                ],

                _LabelledField(
                  label: 'Email',
                  child: TextFormField(
                    controller: _emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    autocorrect: false,
                    decoration: _inputDecoration('vous@email.com', Icons.mail_outline_rounded),
                    validator: (v) {
                      final value = (v ?? '').trim();
                      if (value.isEmpty) return 'Entrez votre email';
                      if (!value.contains('@') || !value.contains('.')) {
                        return 'Email invalide';
                      }
                      return null;
                    },
                  ),
                ),
                const Gap(16),

                _LabelledField(
                  label: 'Mot de passe',
                  child: TextFormField(
                    controller: _passwordCtrl,
                    obscureText: _obscure,
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => _submit(),
                    decoration: _inputDecoration(
                      '••••••••',
                      Icons.lock_outline_rounded,
                      suffix: IconButton(
                        icon: Icon(
                          _obscure
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                          size: 20,
                          color: AppColors.contentTertiary,
                        ),
                        onPressed: () => setState(() => _obscure = !_obscure),
                      ),
                    ),
                    validator: (v) {
                      if ((v ?? '').length < 6) return 'Minimum 6 caractères';
                      return null;
                    },
                  ),
                ),

                // ── Error banner ──
                if (_error != null) ...[
                  const Gap(16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.error.withValues(alpha: 0.25)),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.error_outline_rounded,
                          color: AppColors.error,
                          size: 18,
                        ),
                        const Gap(10),
                        Expanded(
                          child: Text(
                            _error!,
                            style: GoogleFonts.dmSans(
                              fontSize: 13,
                              color: AppColors.errorDark,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const Gap(28),

                // ── Submit button ──
                ElevatedButton(
                  onPressed: _loading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 56),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(100),
                    ),
                    elevation: 0,
                  ),
                  child: _loading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          _isLogin ? 'Se connecter' : "Créer mon compte",
                          style: GoogleFonts.dmSans(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                ),

                const Gap(20),

                // ── Mode toggle ──
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _isLogin
                          ? 'Pas encore de compte ? '
                          : 'Déjà un compte ? ',
                      style: GoogleFonts.dmSans(
                        fontSize: 14,
                        color: AppColors.contentTertiary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    GestureDetector(
                      onTap: _toggleMode,
                      child: Text(
                        _isLogin ? "S'inscrire" : "Se connecter",
                        style: GoogleFonts.dmSans(
                          fontSize: 14,
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint, IconData icon, {Widget? suffix}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.dmSans(
        color: AppColors.contentDisabled,
        fontSize: 15,
        fontWeight: FontWeight.w500,
      ),
      prefixIcon: Icon(icon, color: AppColors.contentTertiary, size: 20),
      suffixIcon: suffix,
      filled: true,
      fillColor: AppColors.surfaceNeutral,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.error, width: 1.5),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.error, width: 1.5),
      ),
    );
  }
}

class _LabelledField extends StatelessWidget {
  final String label;
  final Widget child;
  const _LabelledField({required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.dmSans(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AppColors.content,
          ),
        ),
        const Gap(6),
        child,
      ],
    );
  }
}
