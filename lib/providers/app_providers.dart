import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/profile_model.dart';
import '../services/ai_service.dart';
import '../services/auth_service.dart';
import '../services/chat_push_service.dart';
import '../services/issues_repository.dart';
import '../services/location_service.dart';
import '../services/messages_repository.dart';
import '../services/places_service.dart';
import '../services/profile_repository.dart';
import '../services/requests_repository.dart';
import '../services/storage_service.dart';

final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService(ref.watch(supabaseClientProvider));
});

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return ProfileRepository(ref.watch(supabaseClientProvider));
});

final storageServiceProvider = Provider<StorageService>((ref) {
  return StorageService(ref.watch(supabaseClientProvider));
});

final issuesRepositoryProvider = Provider<IssuesRepository>((ref) {
  return IssuesRepository(ref.watch(supabaseClientProvider));
});

final requestsRepositoryProvider = Provider<RequestsRepository>((ref) {
  return RequestsRepository(ref.watch(supabaseClientProvider));
});

final messagesRepositoryProvider = Provider<MessagesRepository>((ref) {
  return MessagesRepository(ref.watch(supabaseClientProvider));
});

final chatPushServiceProvider = Provider<ChatPushService>((ref) {
  return ChatPushService(ref.watch(supabaseClientProvider));
});

final aiServiceProvider = Provider<AiService>((ref) => AiService());

final locationServiceProvider =
    Provider<LocationService>((ref) => LocationService());

final placesServiceProvider = Provider<PlacesService>((ref) => PlacesService());

final authUserProvider = StreamProvider<User?>((ref) {
  final stream = ref.watch(supabaseClientProvider).auth.onAuthStateChange;
  return stream.map((e) => e.session?.user);
});

final profileProvider = FutureProvider<ProfileModel?>((ref) async {
  final user = ref.watch(authUserProvider).valueOrNull;
  if (user == null) return null;
  return ref.watch(profileRepositoryProvider).fetchProfile(user.id);
});
