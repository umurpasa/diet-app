import 'dart:convert';
import 'package:http/http.dart' as http;

class AIService {
  final String apiKey =
      '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'; // Replace with your API Key

  Future<String> generateDietPlan(String userInfo) async {
    final String apiUrl = 'https://api.openai.com/v1/chat/completions';

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: jsonEncode({
          "model": "gpt-4o-mini",
          "messages": [
            {
              "role": "system",
              "content":
                  "You are a dietitian. Provide a meal plan based on user information."
            },
            {"role": "user", "content": userInfo}
          ],
          "temperature": 0.7
        }),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return responseData['choices'][0]['message']['content'];
      } else {
        return 'Error: ${response.body}';
      }
    } catch (e) {
      return 'Error: $e';
    }
  }
}
