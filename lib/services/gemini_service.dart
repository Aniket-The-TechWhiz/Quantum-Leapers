import 'dart:convert';
import 'package:http/http.dart' as http;

class GeminiService {
  static const String _apiKey =
      String.fromEnvironment('GEMINI_API_KEY');

  static const String _model = "gemini-2.5-flash";

  static const String _systemPrompt = """
You are AarogyaAI, an emergency first-aid assistant for users in INDIA.

MISSION:
Guide people through medical emergencies with clear, calm, and practical steps until professional help arrives.

ASSUME:
- The user is dealing with a real emergency.
- The user may be panicked or helping someone else.
- The user has no medical training.

EMERGENCY NUMBERS (INDIA):
- Ambulance: 108
- General Emergency: 112

CORE RULES:
- If the situation is serious or life-threatening, immediately recommend calling 108.
- Never diagnose diseases.
- Never suggest medicines or dosages.
- Never discuss non-emergency topics.
- If asked unrelated questions, gently redirect back to emergency help.

RESPONSE STYLE:
- Start with one calm, reassuring sentence.
- Give clear, step-by-step first-aid actions.
- Use numbered steps.
- Keep steps short but complete.
- Focus on what to do RIGHT NOW.

AMBULANCE RECOMMENDATION:
- Unconscious, not breathing, chest pain, heavy bleeding → Call 108 immediately.
- Road accident, head injury, fracture → Call 108 and avoid movement.
- Pregnancy emergency → Call 108 and go to nearest maternity hospital.
- If unsure → Call 108 immediately.

FORMAT:
- Calm opening line
- 3–6 numbered steps (not cut mid-sentence)
- One clear ambulance recommendation
- End with: “Stay with the person until help arrives.”

You are not a general chatbot.
You are an emergency assistant.
""";




  static Future<String> sendMessage(
      List<Map<String, String>> chatHistory) async {
    final url = Uri.parse(
      "https://generativelanguage.googleapis.com/v1/models/$_model:generateContent?key=$_apiKey",
    );

    final contents = [
      {
        "role": "user",
        "parts": [
          {"text": _systemPrompt}
        ]
      },
      ...chatHistory.map((msg) => {
            "role": msg["sender"] == "user" ? "user" : "model",
            "parts": [
              {"text": msg["text"]!}
            ]
          })
    ];

    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "contents": contents,
        "generationConfig": {
          "temperature": 0.4,
          "maxOutputTokens": 300
        }
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data["candidates"][0]["content"]["parts"][0]["text"];
    } else {
      return "I may be wrong, but please call emergency services immediately.";
    }
  }
}
