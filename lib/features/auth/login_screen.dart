import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/config/env.dart';
import '../../providers/app_providers.dart';
import '../../theme/app_colors.dart';
import '../../widgets/app_logo.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/premium_auto_geometrics.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _loading = false;
  bool _oauthBusy = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
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
          _error =
              'Configure Supabase: flutter run --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...';
        });
        return;
      }
      await ref.read(authServiceProvider).signIn(
            email: _email.text.trim(),
            password: _password.text,
          );
      if (!mounted) return;
      context.go('/home');
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _oauth(OAuthProvider provider) async {
    if (!Env.hasSupabase) {
      setState(() {
        _error = 'Configure Supabase before using social sign-in.';
      });
      return;
    }
    setState(() {
      _error = null;
      _oauthBusy = true;
    });
    try {
      await ref.read(authServiceProvider).signInWithOAuth(provider);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Sign-in could not start: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _oauthBusy = false);
    }
  }

  Future<void> _showForgotPasswordDialog() async {
    final resetEmail = TextEditingController(text: _email.text.trim());
    final formKey = GlobalKey<FormState>();
    var sending = false;

    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('Reset password'),
            content: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'We will email you a link to choose a new password.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.65),
                        ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: resetEmail,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      prefixIcon: Icon(Icons.email_outlined),
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Enter your email';
                      if (!v.contains('@')) return 'Enter a valid email';
                      return null;
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: sending ? null : () => Navigator.pop(ctx), child: const Text('Cancel')),
              FilledButton(
                onPressed: sending
                    ? null
                    : () async {
                        if (!formKey.currentState!.validate()) return;
                        if (!Env.hasSupabase) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Supabase is not configured.')),
                          );
                          return;
                        }
                        final messenger = ScaffoldMessenger.of(context);
                        setDialogState(() => sending = true);
                        try {
                          await ref.read(authServiceProvider).resetPasswordForEmail(resetEmail.text.trim());
                          if (ctx.mounted) Navigator.pop(ctx);
                          if (!mounted) return;
                          messenger.showSnackBar(
                            const SnackBar(
                              content: Text('Check your email for the reset link.'),
                            ),
                          );
                        } catch (e) {
                          setDialogState(() => sending = false);
                          if (ctx.mounted) {
                            ScaffoldMessenger.of(ctx).showSnackBar(
                              SnackBar(content: Text('$e')),
                            );
                          }
                        }
                      },
                child: sending
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Send link'),
              ),
            ],
          );
        },
      ),
    );
    resetEmail.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final busy = _loading || _oauthBusy;

    return Scaffold(
      backgroundColor: Colors.transparent,
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
                padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 20),
                child: GlassCard(
                  padding: const EdgeInsets.fromLTRB(26, 32, 26, 28),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 400),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        AppLogo(height: 92)
                            .animate()
                            .fadeIn(duration: 450.ms)
                            .scale(
                              begin: const Offset(0.82, 0.82),
                              curve: Curves.easeOutBack,
                              duration: 600.ms,
                            )
                            .then(delay: 80.ms)
                            .shimmer(
                              duration: 1800.ms,
                              color: scheme.primary.withValues(alpha: 0.22),
                            ),
                        const SizedBox(height: 10),
                        Text(
                          'Welcome back',
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.6,
                              ),
                          textAlign: TextAlign.center,
                        )
                            .animate()
                            .fadeIn(delay: 60.ms)
                            .slideY(begin: 0.06, curve: Curves.easeOutCubic),
                        const SizedBox(height: 6),
                        Text(
                          'Sign in to continue your SmartAutoCar journey',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: scheme.onSurface.withValues(alpha: 0.52),
                                fontWeight: FontWeight.w500,
                                height: 1.35,
                              ),
                          textAlign: TextAlign.center,
                        )
                            .animate()
                            .fadeIn(delay: 120.ms)
                            .slideY(begin: 0.04, curve: Curves.easeOutCubic),
                        const SizedBox(height: 14),
                        AuthGeometricDivider(color: AppColors.primary.withValues(alpha: 0.35))
                            .animate()
                            .fadeIn(delay: 160.ms)
                            .scaleX(begin: 0.82, curve: Curves.easeOutCubic),
                        const SizedBox(height: 22),
                        Row(
                          children: [
                            Expanded(
                              child: _SocialOutlineButton(
                                label: 'Google',
                                busy: busy,
                                onPressed: () => _oauth(OAuthProvider.google),
                                leading: _GoogleMark(size: 22),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _SocialOutlineButton(
                                label: 'Facebook',
                                busy: busy,
                                onPressed: () => _oauth(OAuthProvider.facebook),
                                leading: _FacebookMark(size: 22),
                              ),
                            ),
                          ],
                        )
                            .animate()
                            .fadeIn(delay: 180.ms)
                            .slideY(begin: 0.05, curve: Curves.easeOutCubic),
                        const SizedBox(height: 18),
                        Row(
                          children: [
                            Expanded(child: Divider(color: scheme.outline.withValues(alpha: 0.35))),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              child: Text(
                                'or with email',
                                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                      color: scheme.onSurface.withValues(alpha: 0.45),
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                            ),
                            Expanded(child: Divider(color: scheme.outline.withValues(alpha: 0.35))),
                          ],
                        ).animate().fadeIn(delay: 220.ms),
                        const SizedBox(height: 18),
                        TextField(
                          controller: _email,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          decoration: const InputDecoration(
                            labelText: 'Email',
                            prefixIcon: Icon(Icons.alternate_email_rounded),
                          ),
                        ).animate().fadeIn(delay: 240.ms).slideX(begin: -0.02),
                        const SizedBox(height: 14),
                        TextField(
                          controller: _password,
                          obscureText: true,
                          textInputAction: TextInputAction.done,
                          onSubmitted: (_) {
                            if (!busy) _submit();
                          },
                          decoration: const InputDecoration(
                            labelText: 'Password',
                            prefixIcon: Icon(Icons.lock_outline_rounded),
                          ),
                        ).animate().fadeIn(delay: 280.ms).slideX(begin: -0.02),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: busy ? null : _showForgotPasswordDialog,
                            child: const Text('Forgot password?'),
                          ),
                        ).animate().fadeIn(delay: 300.ms),
                        if (_error != null) ...[
                          const SizedBox(height: 8),
                          Text(
                            _error!,
                            style: TextStyle(
                              color: scheme.error,
                              fontSize: 12,
                            ),
                          ),
                        ],
                        const SizedBox(height: 20),
                        FilledButton(
                          onPressed: busy ? null : _submit,
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
                              : const Text('Sign in', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                        )
                            .animate()
                            .fadeIn(delay: 320.ms)
                            .scale(begin: const Offset(0.96, 0.96), curve: Curves.easeOutCubic),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: busy ? null : () => context.push('/register'),
                          child: const Text('Create an account'),
                        ).animate().fadeIn(delay: 360.ms),
                      ],
                    ),
                  ),
                )
                    .animate()
                    .fadeIn(duration: 520.ms, delay: 80.ms)
                    .slideY(begin: 0.045, curve: Curves.easeOutCubic),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SocialOutlineButton extends StatelessWidget {
  const _SocialOutlineButton({
    required this.label,
    required this.onPressed,
    required this.leading,
    required this.busy,
  });

  final String label;
  final VoidCallback onPressed;
  final Widget leading;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return OutlinedButton(
      onPressed: busy ? null : onPressed,
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        side: BorderSide(color: scheme.outline.withValues(alpha: 0.45)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          leading,
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
        ],
      ),
    );
  }
}

class _GoogleMark extends StatelessWidget {
  const _GoogleMark({required this.size});
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: const Color(0xFF4285F4).withValues(alpha: 0.35)),
        ),
        child: const Center(
          child: Text(
            'G',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: Color(0xFF4285F4),
            ),
          ),
        ),
      ),
    );
  }
}

class _FacebookMark extends StatelessWidget {
  const _FacebookMark({required this.size});
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: const Color(0xFF1877F2),
        borderRadius: BorderRadius.circular(6),
      ),
      child: const Text(
        'f',
        style: TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.w800,
          height: 1,
        ),
      ),
    );
  }
}
