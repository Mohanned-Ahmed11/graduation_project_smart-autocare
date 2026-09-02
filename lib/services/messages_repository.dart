import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/message_model.dart';

class MessagesRepository {
  MessagesRepository(this._client);

  final SupabaseClient _client;

  Future<List<MessageModel>> listForChat(String chatId) async {
    final rows = await _client
        .from('messages')
        .select()
        .eq('chat_id', chatId)
        .order('created_at', ascending: true);
    return (rows as List)
        .map((e) => MessageModel.fromMap(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<MessageModel> sendText({
    required String chatId,
    required String senderId,
    required String text,
  }) async {
    final row = await _client
        .from('messages')
        .insert({
          'chat_id': chatId,
          'sender_id': senderId,
          'message': text,
        })
        .select()
        .single();
    return MessageModel.fromMap(Map<String, dynamic>.from(row));
  }

  Future<MessageModel> sendImage({
    required String chatId,
    required String senderId,
    required String imageUrl,
  }) async {
    final row = await _client
        .from('messages')
        .insert({
          'chat_id': chatId,
          'sender_id': senderId,
          'image_url': imageUrl,
          'message': '',
        })
        .select()
        .single();
    return MessageModel.fromMap(Map<String, dynamic>.from(row));
  }

  Future<void> markRead(String messageId) async {
    await _client.from('messages').update({
      'read_at': DateTime.now().toUtc().toIso8601String(),
    }).eq('id', messageId);
  }

  RealtimeChannel subscribeMessages(
    String chatId,
    void Function(PostgresChangePayload payload) onInsert,
  ) {
    return _client
        .channel('messages_$chatId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'messages',
          callback: (payload) {
            final row = payload.newRecord;
            if (row['chat_id']?.toString() == chatId) onInsert(payload);
          },
        )
        .subscribe();
  }
}
