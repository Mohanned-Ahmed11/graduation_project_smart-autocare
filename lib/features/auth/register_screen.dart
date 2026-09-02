import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/config/env.dart';
import '../../providers/app_providers.dart';
import '../../theme/app_colors.dart';
import '../../widgets/app_logo.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/premium_auto_geometrics.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirmPassword = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    _confirmPassword.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _error = null;
      _loading = true;
    });
    try {
      if (!Env.hasSupabase) {
        setState(() {
          _error = 'Configure Supabase dart-define keys first.';
        });
        return;
      }
      if (_password.text != _confirmPassword.text) {
        setState(() {
          _error = 'Passwords do not match.';
        });
        return;
      }
      if (_password.text.length < 6) {
        setState(() {
          _error = 'Password must be at least 6 characters.';
        });
        return;
      }
      await ref.read(authServiceProvider).signUp(
            email: _email.text.trim(),
            password: _password.text,
            name: _name.text.trim().isEmpty ? null : _name.text.trim(),
          );
      if (!mounted) return;
      context.go('/home');
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Create account',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: -0.4,
              ),
        ),
        centerTitle: true,
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          const Positioned.fill(
            child: IgnorePointer(
              child: AuthGeometricMotionLayer(intensity: 0.95),
            ),
          ),
          const FloatingAutoShapeAccents(),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(22, 8, 22, 24),
                child: GlassCard(
                  padding: const EdgeInsets.fromLTRB(26, 28, 26, 28),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 400),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        AppLogo(height: 84)
                            .animate()
                            .fadeIn(duration: 420.ms)
                            .scale(begin: const Offset(0.86, 0.86), curve: Curves.easeOutBack, duration: 560.ms)
                            .then(delay: 70.ms)
                            .shimmer(
                              duration: 1600.ms,
                              color: scheme.primary.withValues(alpha: 0.2),
                            ),
                        const SizedBox(height: 12),
                        Text(
                          'Your driver profile',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.35,
                              ),
                          textAlign: TextAlign.center,
                        ).animate().fadeIn(delay: 60.ms).slideY(begin: 0.05),
                        const SizedBox(height: 6),
                        Text(
                          'AI diagnosis, nearby help, and community — all in one place.',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: scheme.onSurface.withValues(alpha: 0.52),
                                fontWeight: FontWeight.w500,
                                height: 1.4,
                              ),
                          textAlign: TextAlign.center,
                        )
                            .animate()
                            .fadeIn(delay: 110.ms)
                            .slideY(begin: 0.03, curve: Curves.easeOutCubic),
                        const SizedBox(height: 14),
                        AuthGeometricDivider(color: AppColors.primary.withValues(alpha: 0.35))
                            .animate()
                            .fadeIn(delay: 150.ms)
                            .scaleX(begin: 0.82, curve: Curves.easeOutCubic),
                        const SizedBox(height: 22),
                        TextField(
                          controller: _name,
                          textInputAction: TextInputAction.next,
                          textCapitalization: TextCapitalization.words,
                          decoration: const InputDecoration(
                            labelText: 'Full name',
                            prefixIcon: Icon(Icons.person_outline_rounded),
                          ),
                        ).animate().fadeIn(delay: 170.ms).slideX(begin: -0.02),
                        const SizedBox(height: 14),
                        TextField(
                          controller: _email,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          decoration: const InputDecoration(
                            labelText: 'Email',
                            prefixIcon: Icon(Icons.alternate_email_rounded),
                          ),
                        ).animate().fadeIn(delay: 200.ms).slideX(begin: -0.02),
                        const SizedBox(height: 14),
                        TextField(
                          controller: _password,
                          obscureText: true,
                          textInputAction: TextInputAction.next,
                          decoration: const InputDecoration(
                            labelText: 'Password',
                            prefixIcon: Icon(Icons.lock_outline_rounded),
                          ),
                        ).animate().fadeIn(delay: 230.ms).slideX(begin: -0.02),
                        const SizedBox(height: 14),
                        TextField(
                          controller: _confirmPassword,
                          obscureText: true,
                          textInputAction: TextInputAction.done,
                          onSubmitted: (_) {
                            if (!_loading) _submit();
                          },
                          decoration: const InputDecoration(
                            labelText: 'Confirm password',
                            prefixIcon: Icon(Icons.verified_user_outlined),
                          ),
                        ).animate().fadeIn(delay: 260.ms).slideX(begin: -0.02),
                        if (_error != null) ...[
                          const SizedBox(height: 12),
                          Text(
                            _error!,
                            style: TextStyle(
                              color: scheme.error,
                              fontSize: 12,
                            ),
                          ),
                        ],
                        const SizedBox(height: 22),
                        FilledButton(
                          onPressed: _loading ? null : _submit,
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            elevation: 2,
                            shadowColor: AppColors.primary.withValues(alpha: 0.4),
                          ),
                          child: _loading
                              ? const SizedBox(
                                  height: 22,
                                  width: 22,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Text(
                                  'Sign up',
                                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                                ),
                        )
                            .animate()
                            .fadeIn(delay: 290.ms)
                            .scale(begin: const Offset(0.96, 0.96), curve: Curves.easeOutCubic),
                        const SizedBox(height: 10),
                        Text(
                          'By signing up you agree to use the app responsibly for automotive help.',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                color: scheme.onSurface.withValues(alpha: 0.42),
                                height: 1.35,
                              ),
                        ).animate().fadeIn(delay: 320.ms),
                      ],
                    ),
                  ),
                )
                    .animate()
                    .fadeIn(duration: 500.ms, delay: 70.ms)
                    .slideY(begin: 0.04, curve: Curves.easeOutCubic),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
