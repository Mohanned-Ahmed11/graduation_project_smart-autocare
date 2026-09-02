import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../providers/app_providers.dart';
import '../../providers/my_requests_provider.dart';
import '../../providers/open_requests_provider.dart';
import '../../theme/app_colors.dart';
import '../../widgets/glass_card.dart';

class CreateRequestScreen extends ConsumerStatefulWidget {
  const CreateRequestScreen({super.key});

  @override
  ConsumerState<CreateRequestScreen> createState() => _CreateRequestScreenState();
}

class _CreateRequestScreenState extends ConsumerState<CreateRequestScreen> {
  final _title = TextEditingController();
  final _desc = TextEditingController();
  final _price = TextEditingController();
  final _scroll = ScrollController();
  File? _image;
  bool _saving = false;
  bool _showTitleHint = false;

  @override
  void initState() {
    super.initState();
    _title.addListener(_onFieldsChanged);
    _desc.addListener(_onFieldsChanged);
    _price.addListener(_onFieldsChanged);
  }

  void _onFieldsChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _title.removeListener(_onFieldsChanged);
    _desc.removeListener(_onFieldsChanged);
    _price.removeListener(_onFieldsChanged);
    _title.dispose();
    _desc.dispose();
    _price.dispose();
    _scroll.dispose();
    super.dispose();
  }

  InputDecoration _decoration(BuildContext context, String label, {String? hint, IconData? icon}) {
    final scheme = Theme.of(context).colorScheme;
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: icon != null
          ? Icon(icon, size: 22, color: scheme.onSurface.withValues(alpha: 0.45))
          : null,
      filled: true,
      fillColor: scheme.surface.withValues(alpha: 0.55),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(18)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide(color: scheme.outline.withValues(alpha: 0.12)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.6),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    final x = await ImagePicker().pickImage(source: source, maxWidth: 1600);
    if (x != null && mounted) {
      HapticFeedback.selectionClick();
      setState(() => _image = File(x.path));
    }
  }

  Future<void> _submit() async {
    if (_saving) return;
    if (_title.text.trim().isEmpty) {
      setState(() => _showTitleHint = true);
      HapticFeedback.lightImpact();
      return;
    }
    // Use the same uid the PostgREST client sends (avoids stale provider vs session).
    final sessionUid = ref.read(supabaseClientProvider).auth.currentUser?.id;
    if (sessionUid == null) return;

    setState(() {
      _saving = true;
      _showTitleHint = false;
    });
    HapticFeedback.mediumImpact();

    try {
      await ref.read(locationServiceProvider).ensurePermission();
      final loc = await ref.read(locationServiceProvider).currentPosition();
      String? imageUrl;
      if (_image != null) {
        imageUrl = await ref.read(storageServiceProvider).uploadIssueImage(sessionUid, _image!);
      }
      final priceVal = double.tryParse(_price.text.trim());
      await ref.read(requestsRepositoryProvider).create(
            userId: sessionUid,
            title: _title.text.trim(),
            description: _desc.text.trim().isEmpty ? null : _desc.text.trim(),
            imageUrl: imageUrl,
            price: priceVal,
            lat: loc?.latitude,
            lng: loc?.longitude,
          );
      ref.invalidate(openRequestsProvider);
      ref.invalidate(requestsFeedProvider);
      ref.invalidate(myRequestsProvider);
      ref.invalidate(myRequestPendingCountsProvider);
      if (!mounted) return;
      HapticFeedback.heavyImpact();
      context.go('/requests/mine');
    } catch (e) {
      if (mounted) {
        HapticFeedback.heavyImpact();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            content: Text('$e'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final bottom = MediaQuery.paddingOf(context).bottom;
    final canPost = _title.text.trim().isNotEmpty;

    return Scaffold(
      extendBodyBehindAppBar: true,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Positioned(
            top: -80,
            right: -40,
            child: IgnorePointer(
              child: Container(
                width: 220,
                height: 220,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primary.withValues(alpha: 0.14),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 120,
            left: -60,
            child: IgnorePointer(
              child: Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.secondary.withValues(alpha: 0.1),
                ),
              ),
            ),
          ),
          CustomScrollView(
            controller: _scroll,
            physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
            slivers: [
              SliverAppBar.medium(
                pinned: true,
                backgroundColor: scheme.surface.withValues(alpha: 0.82),
                surfaceTintColor: Colors.transparent,
                title: Text(
                  'Request help',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.35,
                      ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    Text(
                      'Broadcast to drivers',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            letterSpacing: 1.6,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary.withValues(alpha: 0.85),
                          ),
                    )
                        .animate()
                        .fadeIn(duration: 350.ms)
                        .slideX(begin: -0.02, curve: Curves.easeOutCubic),
                    const SizedBox(height: 6),
                    Text(
                      'Craft a clear offer. Drivers see distance, price, and your headline first.',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            height: 1.35,
                            color: scheme.onSurface.withValues(alpha: 0.62),
                            fontWeight: FontWeight.w500,
                          ),
                    )
                        .animate()
                        .fadeIn(delay: 40.ms, duration: 400.ms)
                        .slideY(begin: 0.04, curve: Curves.easeOutCubic),
                    const SizedBox(height: 22),
                    _SectionLabel(text: 'Essentials')
                        .animate()
                        .fadeIn(delay: 80.ms, duration: 350.ms),
                    const SizedBox(height: 10),
                    GlassCard(
                      borderRadius: 24,
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          TextField(
                            controller: _title,
                            textCapitalization: TextCapitalization.sentences,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                            decoration: _decoration(
                              context,
                              'Headline',
                              hint: 'e.g. Battery jump-start near me',
                              icon: Icons.title_rounded,
                            ),
                          ),
                          if (_showTitleHint) ...[
                            const SizedBox(height: 8),
                            Text(
                              'Add a short headline so drivers know what you need.',
                              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                    color: scheme.error,
                                  ),
                            ),
                          ],
                          const SizedBox(height: 16),
                          TextField(
                            controller: _desc,
                            maxLines: 4,
                            minLines: 3,
                            textCapitalization: TextCapitalization.sentences,
                            decoration: _decoration(
                              context,
                              'Details',
                              hint: 'Vehicle, location hint, timing…',
                              icon: Icons.notes_rounded,
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            controller: _price,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: _decoration(
                              context,
                              'Your offer (LE, optional)',
                              hint: 'Leave blank for open offer',
                              icon: Icons.payments_outlined,
                            ).copyWith(
                              prefixText: 'LE ',
                              prefixStyle: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.primary,
                                  ),
                            ),
                          ),
                        ],
                      ),
                    )
                        .animate()
                        .fadeIn(delay: 100.ms, duration: 450.ms)
                        .slideY(begin: 0.06, curve: Curves.easeOutCubic),
                    const SizedBox(height: 22),
                    _SectionLabel(text: 'Photo (optional)')
                        .animate()
                        .fadeIn(delay: 140.ms, duration: 350.ms),
                    const SizedBox(height: 10),
                    GlassCard(
                      borderRadius: 24,
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: _PhotoSourceChip(
                                  icon: Icons.photo_camera_rounded,
                                  label: 'Camera',
                                  onTap: () => _pickImage(ImageSource.camera),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _PhotoSourceChip(
                                  icon: Icons.photo_library_rounded,
                                  label: 'Gallery',
                                  onTap: () => _pickImage(ImageSource.gallery),
                                ),
                              ),
                            ],
                          ),
                          if (_image != null) ...[
                            const SizedBox(height: 14),
                            Stack(
                              clipBehavior: Clip.none,
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(18),
                                  child: Image.file(
                                    _image!,
                                    height: 160,
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                Positioned(
                                  top: 8,
                                  right: 8,
                                  child: Material(
                                    color: Colors.black.withValues(alpha: 0.45),
                                    borderRadius: BorderRadius.circular(20),
                                    child: IconButton(
                                      onPressed: () {
                                        HapticFeedback.selectionClick();
                                        setState(() => _image = null);
                                      },
                                      icon: const Icon(Icons.close_rounded, color: Colors.white, size: 20),
                                      tooltip: 'Remove photo',
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    )
                        .animate()
                        .fadeIn(delay: 160.ms, duration: 450.ms)
                        .slideY(begin: 0.05, curve: Curves.easeOutCubic),
                    const SizedBox(height: 18),
                    _ReadinessRow(
                      ready: canPost,
                      titleLen: _title.text.trim().length,
                    )
                        .animate()
                        .fadeIn(delay: 200.ms, duration: 400.ms),
                  ]),
                ),
              ),
            ],
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: ClipRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        scheme.surface.withValues(alpha: 0.0),
                        scheme.surface.withValues(alpha: 0.88),
                        scheme.surface.withValues(alpha: 0.96),
                      ],
                    ),
                  ),
                  child: SafeArea(
                    top: false,
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(20, 12, 20, 12 + bottom),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.bolt_rounded,
                                size: 20,
                                color: canPost ? AppColors.primary : scheme.onSurface.withValues(alpha: 0.35),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _saving
                                      ? 'Publishing your request…'
                                      : canPost
                                          ? 'Ready to publish'
                                          : 'Add a headline to continue',
                                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                        fontWeight: FontWeight.w600,
                                        color: scheme.onSurface.withValues(alpha: 0.72),
                                      ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          FilledButton.icon(
                            onPressed: !canPost ? null : _submit,
                            icon: _saving
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(Icons.rocket_launch_rounded, size: 22),
                            label: Text(_saving ? 'Publishing…' : 'Post request'),
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              disabledBackgroundColor: scheme.surfaceContainerHighest,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                              elevation: canPost && !_saving ? 2 : 0,
                              shadowColor: AppColors.primary.withValues(alpha: 0.45),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 18,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(3),
            gradient: const LinearGradient(
              colors: [AppColors.primary, AppColors.secondary],
            ),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          text.toUpperCase(),
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                letterSpacing: 1.35,
                fontWeight: FontWeight.w800,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.55),
              ),
        ),
      ],
    );
  }
}

class _PhotoSourceChip extends StatelessWidget {
  const _PhotoSourceChip({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.surface.withValues(alpha: 0.65),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: AppColors.primary, size: 22),
              const SizedBox(width: 8),
              Text(
                label,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReadinessRow extends StatelessWidget {
  const _ReadinessRow({
    required this.ready,
    required this.titleLen,
  });

  final bool ready;
  final int titleLen;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return GlassCard(
      borderRadius: 20,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 280),
            curve: Curves.easeOutCubic,
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: ready
                  ? AppColors.primary.withValues(alpha: 0.2)
                  : scheme.surfaceContainerHighest.withValues(alpha: 0.9),
              border: Border.all(
                color: ready ? AppColors.primary.withValues(alpha: 0.45) : scheme.outline.withValues(alpha: 0.15),
              ),
            ),
            child: Icon(
              ready ? Icons.verified_rounded : Icons.edit_note_rounded,
              color: ready ? AppColors.primary : scheme.onSurface.withValues(alpha: 0.35),
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ready ? 'Looks good' : 'Almost there',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 2),
                Text(
                  titleLen > 0
                      ? '$titleLen characters in headline — drivers scan this first.'
                      : 'Headline appears in the map list and notifications.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: scheme.onSurface.withValues(alpha: 0.55),
                        height: 1.3,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
