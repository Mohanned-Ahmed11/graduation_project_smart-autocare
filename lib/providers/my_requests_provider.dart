import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/help_request_model.dart';
import 'app_providers.dart';

/// All requests created by the current user (any status).
final myRequestsProvider = FutureProvider.autoDispose<List<HelpRequestModel>>((ref) async {
  final user = ref.watch(authUserProvider).valueOrNull;
  if (user == null) return [];
  return ref.watch(requestsRepositoryProvider).listForUser(user.id);
});

/// Pending offer counts keyed by `request_id` for the current user's requests.
final myRequestPendingCountsProvider =
    FutureProvider.autoDispose<Map<String, int>>((ref) async {
  final list = await ref.watch(myRequestsProvider.future);
  final ids = list.map((r) => r.id).toList();
  if (ids.isEmpty) return {};
  return ref.watch(requestsRepositoryProvider).pendingOfferCountsForRequests(ids);
});
