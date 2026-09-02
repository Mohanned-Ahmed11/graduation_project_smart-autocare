import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../providers/app_providers.dart';
import '../../providers/theme_mode_provider.dart';
import '../../theme/app_colors.dart';
import '../../widgets/glass_card.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  Future<void> _pickAvatar(String userId) async {
    final picker = ImagePicker();
    final x = await picker.pickImage(source: ImageSource.gallery, maxWidth: 1024);
    if (x == null || !mounted) return;
    final file = File(x.path);
    try {
      final url =
          await ref.read(storageServiceProvider).uploadProfileImage(userId, file);
      await ref.read(profileRepositoryProvider).updateProfile(userId, {
        'profile_image': url,
      });
      ref.invalidate(profileProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile photo updated')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not upload photo: $e')),
        );
      }
    }
  }

  Future<void> _editFields(String userId, String? name, String? phone, String? car) async {
    final nameC = TextEditingController(text: name ?? '');
    final phoneC = TextEditingController(text: phone ?? '');
    final carC = TextEditingController(text: car ?? '');
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit profile'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameC,
                decoration: const InputDecoration(labelText: 'Name'),
              ),
              TextField(
                controller: phoneC,
                decoration: const InputDecoration(labelText: 'Phone'),
              ),
              TextField(
                controller: carC,
                decoration: const InputDecoration(labelText: 'Car model'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              await ref.read(profileRepositoryProvider).updateProfile(userId, {
                'name': nameC.text.trim(),
                'phone': phoneC.text.trim().isEmpty ? null : phoneC.text.trim(),
                'car_model': carC.text.trim().isEmpty ? null : carC.text.trim(),
              });
              ref.invalidate(profileProvider);
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
    nameC.dispose();
    phoneC.dispose();
    carC.dispose();
  }

  Future<void> _logout() async {
    final router = GoRouter.of(context);
    await ref.read(authServiceProvider).signOut();
    if (!context.mounted) return;
    router.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(profileProvider);
    final user = ref.watch(authUserProvider).valueOrNull;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton.filledTonal(
            tooltip: 'Light / dark',
            onPressed: () => ref.read(themeModeProvider.notifier).toggleLightDark(),
            icon: Icon(
              Theme.of(context).brightness == Brightness.dark
                  ? Icons.light_mode_rounded
                  : Icons.dark_mode_rounded,
            ),
          ),
        ],
      ),
      body: profileAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Padding(padding: const EdgeInsets.all(24), child: Text('$e'))),
        data: (p) {
          if (user == null || p == null) {
            return const Center(child: Text('Sign in to view your profile.'));
          }
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(profileProvider),
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Center(
                  child: GestureDetector(
                    onTap: () => _pickAvatar(user.id),
                    child: Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        CircleAvatar(
                          radius: 56,
                          backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                          backgroundImage: p.profileImage != null
                              ? CachedNetworkImageProvider(p.profileImage!)
                              : null,
                          child: p.profileImage == null
                              ? Icon(
                                  Icons.person_rounded,
                                  size: 56,
                                  color: AppColors.secondary.withValues(alpha: 0.7),
                                )
                              : null,
                        ),
                        CircleAvatar(
                          radius: 18,
                          backgroundColor: AppColors.primary,
                          child: const Icon(Icons.camera_alt, size: 18, color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Tap photo to change',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.55),
                      ),
                ),
                const SizedBox(height: 24),
                GlassCard(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _InfoRow(label: 'Name', value: p.name ?? '—'),
                      const Divider(height: 24),
                      _InfoRow(label: 'Phone', value: p.phone ?? '—'),
                      const Divider(height: 24),
                      _InfoRow(label: 'Car model', value: p.carModel ?? '—'),
                      const Divider(height: 24),
                      _InfoRow(
                        label: 'Email',
                        value: user.email ?? '—',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                FilledButton.tonalIcon(
                  onPressed: () => _editFields(user.id, p.name, p.phone, p.carModel),
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('Edit details'),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: _logout,
                  icon: const Icon(Icons.logout_rounded),
                  label: const Text('Sign out'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.55),
              ),
        ),
        const SizedBox(height: 4),
        Text(value, style: Theme.of(context).textTheme.titleMedium),
      ],
    );
  }
}
