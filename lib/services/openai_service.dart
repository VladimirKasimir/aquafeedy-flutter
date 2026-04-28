import 'dart:convert';
import 'package:http/http.dart' as http;

class OpenAIService {
  static const _apiKey = const apiKey = String.fromEnvironment('OPENAI_API_KEY');;

  static Future<String> ask({
    required String prompt,
    required Map<String, dynamic> user,
  }) async {
    final res = await http.post(
      Uri.parse('https://api.openai.com/v1/chat/completions'),
      headers: {
        'Authorization': 'Bearer $_apiKey',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        "model": "gpt-4o-mini",
        "messages": [
          {
            "role": "system",
            "content": """
Kamu adalah Aqua AI.
Nama user: ${user['name']}
Jenis ikan: ${user['fishType']}
Ukuran akuarium: ${user['aquariumSize']}

Jawab santai, edukatif, dan praktis.
"""
          },
          {"role": "user", "content": prompt}
        ],
      }),
    );

    final data = jsonDecode(res.body);
    return data['choices'][0]['message']['content'];
  }
}
