import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Calls Edge Function to FCM-notify other chat participants (server skips if they have chat open).
class ChatPushService {
  ChatPushService(this._client);

  final SupabaseClient _client;

  /// Best-effort: message is already saved. Pass [messageId] so the Edge Function does not rely on
  /// ordering the latest row (avoids rare 400 / invoke failures).
  Future<void> notifyParticipants({
    required String chatId,
    required String messageId,
  }) async {
    if (_client.auth.currentUser == null) return;
    try {
      final res = await _client.functions.invoke(
        'send-chat-message-push',
        body: {
          'chat_id': chatId,
          'message_id': messageId,
        },
      );
      if (kDebugMode && res.data is Map) {
        final map = Map<String, dynamic>.from(res.data as Map);
        if (map['skipped'] == true) {
          debugPrint('Chat push skipped: ${map['error']}');
        }
      }
    } on FunctionException catch (e, st) {
      if (kDebugMode) {
        debugPrint('Chat push FunctionException ${e.status} ${e.details} $st');
      }
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('Chat push error: $e $st');
      }
    }
  }
}
