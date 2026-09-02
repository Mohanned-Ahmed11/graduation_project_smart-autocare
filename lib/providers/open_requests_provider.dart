import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/help_request_model.dart';
import 'app_providers.dart';

final openRequestsProvider =
    FutureProvider.autoDispose<List<HelpRequestModel>>((ref) async {
  return ref.watch(requestsRepositoryProvider).listOpen();
});

/// Open + user's non-open requests (so requester can open chat after accept).
final requestsFeedProvider =
    FutureProvider.autoDispose<List<HelpRequestModel>>((ref) async {
  final user = ref.watch(authUserProvider).valueOrNull;
  if (user == null) return ref.watch(requestsRepositoryProvider).listOpen();
  return ref.watch(requestsRepositoryProvider).listOpenAndMine(user.id);
});
