import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/profile_model.dart';

class ProfileRepository {
  ProfileRepository(this._client);

  final SupabaseClient _client;

  Future<ProfileModel?> fetchProfile(String userId) async {
    final row = await _client
        .from('profiles')
        .select()
        .eq('id', userId)
        .maybeSingle();
    if (row == null) return null;
    return ProfileModel.fromMap(Map<String, dynamic>.from(row));
  }

  Future<void> updateProfile(String userId, Map<String, dynamic> data) async {
    await _client.from('profiles').update(data).eq('id', userId);
  }
}
