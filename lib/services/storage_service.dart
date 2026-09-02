import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

class StorageService {
  StorageService(this._client);

  final SupabaseClient _client;
  static const _uuid = Uuid();

  Future<String> uploadProfileImage(String userId, File file) async {
    final path = '$userId/${_uuid.v4()}.jpg';
    await _client.storage.from('profile_images').upload(
          path,
          file,
          fileOptions: const FileOptions(upsert: true, contentType: 'image/jpeg'),
        );
    return _client.storage.from('profile_images').getPublicUrl(path);
  }

  /// Private bucket: returns signed URL string for display (use duration).
  Future<String> uploadIssueImage(String userId, File file) async {
    final path = '$userId/${_uuid.v4()}.jpg';
    await _client.storage.from('issue_images').upload(
          path,
          file,
          fileOptions: const FileOptions(contentType: 'image/jpeg'),
        );
    final signed =
        await _client.storage.from('issue_images').createSignedUrl(path, 3600);
    return signed;
  }

  Future<String> uploadVoice(String userId, File file) async {
    final path = '$userId/${_uuid.v4()}.m4a';
    await _client.storage.from('voice_records').upload(
          path,
          file,
          fileOptions: const FileOptions(contentType: 'audio/m4a'),
        );
    final signed =
        await _client.storage.from('voice_records').createSignedUrl(path, 3600);
    return signed;
  }

  Future<String> uploadChatImage(String userId, File file) async {
    final path = '$userId/${_uuid.v4()}.jpg';
    await _client.storage.from('chat_images').upload(
          path,
          file,
          fileOptions: const FileOptions(contentType: 'image/jpeg'),
        );
    final signed =
        await _client.storage.from('chat_images').createSignedUrl(path, 3600);
    return signed;
  }
}
