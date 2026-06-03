import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../constants.dart';
import '../models/job.dart';

class AiService {
  late final GenerativeModel _model;

  AiService() {
    _model = GenerativeModel(
      model: 'gemini-1.5-flash',
      apiKey: Constants.geminiApiKey,
      generationConfig: GenerationConfig(
        responseMimeType: 'application/json',
        temperature: 0.1,
      ),
    );
  }

  Future<Map<String, dynamic>> parseVoiceCommand(String text, List<Job> activeJobs) async {
    try {
      final jobsListString = activeJobs
          .map((j) => '- Code: "${j.jobCode}" (also known as "${j.id}"), Title: "${j.title}", Description: "${j.description}"')
          .join('\n');

      final systemPrompt = '''
You are the voice assistant for "JobIt", a construction and work order management app.
Your task is to parse a spoken voice command (which can be in English or Swedish) and translate it into a structured JSON action.

Here is the list of active jobs currently assigned/available to the user:
$jobsListString

Supported Actions & Extraction Rules:
1. "log_hours": The user wants to log hours worked.
   - Extract "hours" as a number (e.g. 4.5).
   - Extract "notes" as a brief description of the work done.
   - Extract "jobCode" (match to one of the active jobs above, matching either the code or title or description. If a code is directly spoken, use that. Otherwise, map the title or context to the correct Job Code).
2. "navigate": The user wants to view the route/map or start driving/tracking a job route.
   - Extract "jobCode" (map the spoken job name or code to the correct Job Code).
3. "join_job": The user wants to join a new job using a job code.
   - Extract "jobCode" (this might not be in the active jobs list yet, extract the raw spoken code, e.g., "ABCDEF" or "CITY-PLAZA").
4. "unknown": If the command does not match any of these intents.

You MUST return a JSON object with this EXACT structure:
{
  "action": "log_hours" | "navigate" | "join_job" | "unknown",
  "jobCode": "string or null",
  "hours": number or null,
  "notes": "string or null"
}

Do not include any markdown formatting or extra text. Just the raw JSON.
''';

      final content = [
        Content.system(systemPrompt),
        Content.text('Parse this input: "$text"'),
      ];

      final response = await _model.generateContent(content);
      final responseText = response.text;

      if (responseText == null || responseText.isEmpty) {
        return {'action': 'unknown'};
      }

      final cleanJson = responseText.trim();
      final Map<String, dynamic> result = json.decode(cleanJson);
      debugPrint('AI Voice Parsing Result: $result');
      return result;
    } catch (e) {
      debugPrint('AI Voice Parsing Error: $e');
      return {'action': 'unknown', 'error': e.toString()};
    }
  }
}
