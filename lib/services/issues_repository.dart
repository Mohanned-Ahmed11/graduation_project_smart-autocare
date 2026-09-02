import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/ai_issue_result.dart';
import '../models/issue_model.dart';

class IssuesRepository {
  IssuesRepository(this._client);

  final SupabaseClient _client;

  Future<List<IssueModel>> listForUser(String userId) async {
    final rows = await _client
        .from('issues')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .limit(20);
    return (rows as List)
        .map((e) => IssueModel.fromMap(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<IssueModel> insert({
    required String userId,
    String? description,
    String? imageUrl,
    String? voiceUrl,
    AiIssueResult? aiResponse,
  }) async {
    final row = await _client
        .from('issues')
        .insert({
          'user_id': userId,
          'description': description,
          'image_url': imageUrl,
          'voice_url': voiceUrl,
          'ai_response': aiResponse?.toJson(),
        })
        .select()
        .single();
    return IssueModel.fromMap(Map<String, dynamic>.from(row));
  }
}
