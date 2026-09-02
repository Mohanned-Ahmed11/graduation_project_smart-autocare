import 'dart:convert';
import 'dart:typed_data';

import 'package:google_generative_ai/google_generative_ai.dart';

import '../core/config/env.dart';
import '../models/ai_issue_result.dart';

class AiService {
  GenerativeModel? _model;

  GenerativeModel get model {
    _model ??= GenerativeModel(
      model: 'gemini-2.5-flash',
      apiKey: Env.geminiApiKey,
    );
    return _model!;
  }

  static const String mechanicPrompt = '''
You are an expert car mechanic.

Analyze the following issue:

INPUT:
- Description: {description}
- Image: attached if provided

Return a JSON object ONLY (no markdown) with these exact keys:
{
  "issue_name": "...",
  "explanation": "...",
  "possible_causes": "...",
  "fix_steps": "...",
  "estimated_cost": "...",
  "urgency": "Low | Medium | High"
}

Make the content simple for non-technical drivers. Use LE (Egyptian pounds) for cost if relevant.
''';

  Future<AiIssueResult> analyze({
    required String description,
    Uint8List? imageBytes,
    String? mimeType,
  }) async {
    if (!Env.hasGemini) {
      return AiIssueResult.fromRawText(
        'Add GEMINI_API_KEY to your .env (copy from env.template) or pass --dart-define=GEMINI_API_KEY=... to enable AI diagnosis.',
      );
    }

    final prompt = mechanicPrompt.replaceAll('{description}', description);
    final parts = <Part>[TextPart(prompt)];
    if (imageBytes != null && mimeType != null) {
      parts.add(DataPart(mimeType, imageBytes));
    }

    final response = await model.generateContent([
      Content.multi(parts),
    ]);
    final text = response.text?.trim() ?? '';
    if (text.isEmpty) {
      return AiIssueResult.fromRawText('No response from AI.');
    }

    final jsonStr = _extractJson(text);
    if (jsonStr != null) {
      try {
        final map = json.decode(jsonStr) as Map<String, dynamic>;
        return AiIssueResult.fromJson(map);
      } catch (_) {}
    }
    return AiIssueResult.fromRawText(text);
  }

  String? _extractJson(String text) {
    final start = text.indexOf('{');
    final end = text.lastIndexOf('}');
    if (start >= 0 && end > start) {
      return text.substring(start, end + 1);
    }
    return null;
  }
}
