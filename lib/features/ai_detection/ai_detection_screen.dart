import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

import '../../providers/app_providers.dart';
import '../../providers/issues_list_provider.dart';
import '../../theme/app_colors.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/premium_auto_geometrics.dart';
import '../../widgets/scale_tap.dart';
import '../../widgets/shimmer_box.dart';
import '../../services/speech_service.dart';

class AiDetectionScreen extends ConsumerStatefulWidget {
  const AiDetectionScreen({super.key, this.initialMode});

  final String? initialMode;

  @override
  ConsumerState<AiDetectionScreen> createState() => _AiDetectionScreenState();
}

class _AiDetectionScreenState extends ConsumerState<AiDetectionScreen> {
  final _descController = TextEditingController();
  final _speech = SpeechService();
  final _audioRecorder = AudioRecorder();
  File? _imageFile;
  String? _voicePath;
  bool _listening = false;
  bool _recording = false;
  bool _analyzing = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    if (widget.initialMode == 'image') {
      WidgetsBinding.instance.addPostFrameCallback((_) => _pickImage());
    }
    if (widget.initialMode == 'voice') {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!mounted) return;
        await _toggleListen();
      });
    }
  }

  @override
  void dispose() {
    _descController.dispose();
    _audioRecorder.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final x = await picker.pickImage(source: ImageSource.camera, maxWidth: 1600);
    if (x == null) return;
    setState(() => _imageFile = File(x.path));
  }

  Future<void> _pickGallery() async {
    final picker = ImagePicker();
    final x = await picker.pickImage(source: ImageSource.gallery, maxWidth: 1600);
    if (x == null) return;
    setState(() => _imageFile = File(x.path));
  }

  Future<void> _toggleListen() async {
    if (_listening) {
      await _speech.stop();
      setState(() => _listening = false);
      return;
    }
    setState(() {
      _listening = true;
      _error = null;
    });
    await _speech.listen(
      onResult: (text) {
        if (mounted) {
          _descController.text = text;
          _descController.selection = TextSelection.collapsed(offset: text.length);
        }
      },
      onError: (e) {
        if (mounted) setState(() => _error = e);
      },
    );
    if (mounted) setState(() => _listening = false);
  }

  Future<void> _toggleRecord() async {
    if (_recording) {
      final path = await _audioRecorder.stop();
      setState(() => _recording = false);
      if (path != null && mounted) {
        setState(() => _voicePath = path);
      }
      return;
    }
    if (await _audioRecorder.hasPermission()) {
      final dir = await getTemporaryDirectory();
      final filePath = '${dir.path}/issue_${DateTime.now().millisecondsSinceEpoch}.m4a';
      await _audioRecorder.start(const RecordConfig(), path: filePath);
      setState(() => _recording = true);
    }
  }

  Future<void> _analyze() async {
    final user = ref.read(authUserProvider).valueOrNull;
    if (user == null) return;

    setState(() {
      _analyzing = true;
      _error = null;
    });

    try {
      String? imageUrl;
      String? voiceUrl;

      if (_imageFile != null) {
        imageUrl = await ref.read(storageServiceProvider).uploadIssueImage(user.id, _imageFile!);
      }
      if (_voicePath != null) {
        voiceUrl = await ref.read(storageServiceProvider).uploadVoice(user.id, File(_voicePath!));
      }

      final ai = ref.read(aiServiceProvider);
      List<int>? bytes;
      String? mime;
      if (_imageFile != null) {
        bytes = await _imageFile!.readAsBytes();
        mime = 'image/jpeg';
      }

      final desc = _descController.text.trim();
      final result = await ai.analyze(
        description: desc.isEmpty
            ? 'User did not type a description; use image/audio context.'
            : desc,
        imageBytes: bytes != null ? Uint8List.fromList(bytes) : null,
        mimeType: mime,
      );

      final issue = await ref.read(issuesRepositoryProvider).insert(
            userId: user.id,
            description: desc.isEmpty ? null : desc,
            imageUrl: imageUrl,
            voiceUrl: voiceUrl,
            aiResponse: result,
          );

      ref.invalidate(recentIssuesProvider);
      if (!mounted) return;
      context.pushReplacement('/ai-result', extra: issue);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _analyzing = false);
    }
  }

  InputDecoration _fieldDecoration(BuildContext context, String hint) {
    final scheme = Theme.of(context).colorScheme;
    return InputDecoration(
      hintText: hint,
      border: InputBorder.none,
      hintStyle: TextStyle(color: scheme.onSurface.withValues(alpha: 0.45)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
    );
  }

  Widget _sectionLabel(BuildContext context, String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 10),
      child: Text(
        text.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.45),
            ),
      ),
    );
  }

  Widget _captureTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color accent,
    required VoidCallback? onTap,
    bool active = false,
  }) {
    return ScaleTap(
      onTap: onTap,
      child: GlassCard(
        borderRadius: 22,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: LinearGradient(
                  colors: [
                    accent.withValues(alpha: active ? 0.35 : 0.2),
                    accent.withValues(alpha: active ? 0.18 : 0.08),
                  ],
                ),
                boxShadow: active
                    ? [
                        BoxShadow(
                          color: accent.withValues(alpha: 0.45),
                          blurRadius: 18,
                          spreadRadius: -2,
                        ),
                      ]
                    : null,
              ),
              child: Icon(icon, color: accent.withValues(alpha: 0.95), size: 26),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.2,
                        ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.52),
                        ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.28),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final bottom = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'AI diagnosis',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.4,
                  ),
            ),
            Text(
              'Smart symptom check',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: scheme.onSurface.withValues(alpha: 0.5),
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
        ),
        centerTitle: false,
        backgroundColor: scheme.surface.withValues(alpha: 0.88),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(
            child: IgnorePointer(
              child: Opacity(
                opacity: 0.4,
                child: const PremiumAutoGeometrics(intensity: 0.78),
              ),
            ),
          ),
          Positioned.fill(
            child: IgnorePointer(
              child: Opacity(
                opacity: 0.5,
                child: const FloatingAutoShapeAccents(),
              ),
            ),
          ),
          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: SizedBox(height: MediaQuery.paddingOf(context).top + kToolbarHeight + 8),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                colors: [
                                  AppColors.primary.withValues(alpha: 0.28),
                                  AppColors.secondary.withValues(alpha: 0.18),
                                ],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primary.withValues(alpha: 0.35),
                                  blurRadius: 24,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.auto_awesome_rounded,
                              size: 36,
                              color: AppColors.primary.withValues(alpha: 0.95),
                            ),
                          )
                              .animate(onPlay: (c) => c.repeat(reverse: true))
                              .scale(
                                begin: const Offset(1, 1),
                                end: const Offset(1.04, 1.04),
                                duration: 2200.ms,
                                curve: Curves.easeInOut,
                              ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Tell us what is wrong',
                                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: -0.6,
                                        height: 1.1,
                                      ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Type, speak, record audio, or add a photo — Gemini analyzes symptoms in plain language.',
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                        color: scheme.onSurface.withValues(alpha: 0.56),
                                        height: 1.45,
                                      ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  )
                      .animate()
                      .fadeIn(duration: 450.ms, curve: Curves.easeOutCubic)
                      .slideY(begin: 0.06, duration: 450.ms, curve: Curves.easeOutCubic),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _sectionLabel(context, 'Describe'),
                      GlassCard(
                        borderRadius: 22,
                        padding: const EdgeInsets.fromLTRB(18, 6, 18, 14),
                        child: TextField(
                          controller: _descController,
                          maxLines: 5,
                          minLines: 3,
                          textCapitalization: TextCapitalization.sentences,
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.45),
                          decoration: _fieldDecoration(
                            context,
                            'e.g. Grinding when braking, smell of burning rubber…',
                          ),
                        ),
                      ),
                    ],
                  )
                      .animate()
                      .fadeIn(delay: 80.ms, duration: 420.ms)
                      .slideY(begin: 0.05, delay: 80.ms, duration: 420.ms, curve: Curves.easeOutCubic),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 22, 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _sectionLabel(context, 'Capture'),
                      const SizedBox(height: 4),
                      _captureTile(
                        icon: Icons.mic_rounded,
                        title: _listening ? 'Listening…' : 'Speak',
                        subtitle: _listening ? 'Tap again to stop' : 'Voice-to-text into the box above',
                        accent: AppColors.primary,
                        onTap: _analyzing ? null : _toggleListen,
                        active: _listening,
                      ),
                      const SizedBox(height: 10),
                      _captureTile(
                        icon: Icons.graphic_eq_rounded,
                        title: _recording ? 'Recording…' : 'Record clip',
                        subtitle: _recording ? 'Tap to stop and attach' : 'Save a short audio note for AI',
                        accent: const Color(0xFFE53935),
                        onTap: _analyzing ? null : _toggleRecord,
                        active: _recording,
                      ),
                      const SizedBox(height: 10),
                      _captureTile(
                        icon: Icons.photo_camera_rounded,
                        title: 'Camera',
                        subtitle: 'Snap the problem area',
                        accent: AppColors.secondary,
                        onTap: _analyzing ? null : _pickImage,
                      ),
                      const SizedBox(height: 10),
                      _captureTile(
                        icon: Icons.photo_library_rounded,
                        title: 'Gallery',
                        subtitle: 'Choose a photo you already have',
                        accent: AppColors.secondary,
                        onTap: _analyzing ? null : _pickGallery,
                      ),
                    ],
                  )
                      .animate()
                      .fadeIn(delay: 140.ms, duration: 420.ms)
                      .slideY(begin: 0.05, delay: 140.ms, duration: 420.ms),
                ),
              ),
              if (_imageFile != null)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _sectionLabel(context, 'Photo preview'),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(22),
                          child: Stack(
                            alignment: Alignment.topRight,
                            children: [
                              Image.file(_imageFile!, height: 200, width: double.infinity, fit: BoxFit.cover),
                              Material(
                                color: Colors.black45,
                                borderRadius: BorderRadius.circular(14),
                                child: IconButton(
                                  icon: const Icon(Icons.close_rounded, color: Colors.white),
                                  onPressed: _analyzing ? null : () => setState(() => _imageFile = null),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    )
                        .animate(key: ValueKey(_imageFile!.path))
                        .fadeIn(duration: 350.ms)
                        .scale(begin: const Offset(0.96, 0.96), duration: 350.ms, curve: Curves.easeOutCubic),
                  ),
                ),
              if (_voicePath != null)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                    child: GlassCard(
                      borderRadius: 18,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Row(
                        children: [
                          Icon(Icons.audiotrack_rounded, color: AppColors.primary.withValues(alpha: 0.9)),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Voice clip attached',
                              style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                            ),
                          ),
                          TextButton(
                            onPressed: _analyzing ? null : () => setState(() => _voicePath = null),
                            child: const Text('Remove'),
                          ),
                        ],
                      ),
                    ).animate().fadeIn(duration: 300.ms),
                  ),
                ),
              if (_error != null)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                    child: GlassCard(
                      borderRadius: 18,
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.error_outline_rounded, color: scheme.error),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _error!,
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: scheme.error),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              SliverToBoxAdapter(child: SizedBox(height: 120 + bottom)),
            ],
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: ClipRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                child: Container(
                  padding: EdgeInsets.fromLTRB(20, 12, 20, 12 + bottom),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        scheme.surface.withValues(alpha: 0.2),
                        scheme.surface.withValues(alpha: 0.92),
                      ],
                    ),
                    border: Border(
                      top: BorderSide(color: scheme.outline.withValues(alpha: 0.12)),
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_analyzing) ...[
                        const ShimmerBox(height: 6, borderRadius: 8, width: double.infinity),
                        const SizedBox(height: 12),
                      ],
                      FilledButton(
                        onPressed: _analyzing ? null : _analyze,
                        style: FilledButton.styleFrom(
                          minimumSize: const Size(double.infinity, 54),
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          elevation: _analyzing ? 0 : 2,
                          shadowColor: AppColors.primary.withValues(alpha: 0.45),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                        ),
                        child: _analyzing
                            ? Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const SizedBox(
                                    height: 22,
                                    width: 22,
                                    child: CircularProgressIndicator(strokeWidth: 2.2, color: Colors.white),
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    'Analyzing…',
                                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w800,
                                        ),
                                  ),
                                ],
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.auto_awesome_rounded, size: 22),
                                  const SizedBox(width: 10),
                                  Text(
                                    'Analyze with AI',
                                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w800,
                                        ),
                                  ),
                                ],
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          )
              .animate()
              .fadeIn(duration: 400.ms, delay: 200.ms),
        ],
      ),
    );
  }
}
