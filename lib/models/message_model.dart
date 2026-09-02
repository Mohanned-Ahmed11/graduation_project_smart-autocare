class MessageModel {
  const MessageModel({
    required this.id,
    required this.chatId,
    required this.senderId,
    this.message,
    this.imageUrl,
    this.readAt,
    this.createdAt,
  });

  final String id;
  final String chatId;
  final String senderId;
  final String? message;
  final String? imageUrl;
  final DateTime? readAt;
  final DateTime? createdAt;

  factory MessageModel.fromMap(Map<String, dynamic> map) {
    return MessageModel(
      id: map['id'] as String,
      chatId: map['chat_id'] as String,
      senderId: map['sender_id'] as String,
      message: map['message'] as String?,
      imageUrl: map['image_url'] as String?,
      readAt: map['read_at'] != null
          ? DateTime.tryParse(map['read_at'].toString())
          : null,
      createdAt: map['created_at'] != null
          ? DateTime.tryParse(map['created_at'].toString())
          : null,
    );
  }
}
