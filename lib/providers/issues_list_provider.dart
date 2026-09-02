import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/issue_model.dart';
import 'app_providers.dart';

final recentIssuesProvider = FutureProvider.autoDispose<List<IssueModel>>((ref) async {
  final user = ref.watch(authUserProvider).valueOrNull;
  if (user == null) return [];
  return ref.watch(issuesRepositoryProvider).listForUser(user.id);
});
