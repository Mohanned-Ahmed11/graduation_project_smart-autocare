import 'ai_issue_result.dart';

class IssueModel {
  const IssueModel({
    required this.id,
    required this.userId,
    this.description,
    this.imageUrl,
    this.voiceUrl,
    this.aiResponse,
    this.createdAt,
  });

  final String id;
  final String userId;
  final String? description;
  final String? imageUrl;
  final String? voiceUrl;
  final AiIssueResult? aiResponse;
  final DateTime? createdAt;

  factory IssueModel.fromMap(Map<String, dynamic> map) {
    final raw = map['ai_response'];
    AiIssueResult? parsed;
    if (raw is Map<String, dynamic>) {
      parsed = AiIssueResult.fromJson(
        Map<String, dynamic>.from(raw),
      );
    }
    return IssueModel(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      description: map['description'] as String?,
      imageUrl: map['image_url'] as String?,
      voiceUrl: map['voice_url'] as String?,
      aiResponse: parsed,
      createdAt: map['created_at'] != null
          ? DateTime.tryParse(map['created_at'].toString())
          : null,
    );
  }
}
