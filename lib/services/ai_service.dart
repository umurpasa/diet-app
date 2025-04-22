import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AIService {
  final storage = FlutterSecureStorage();
  final String _apiKeyName = 'openai_api_key';

  // API anahtarını güvenli bir şekilde kaydetme
  Future<void> saveAPIKey(String apiKey) async {
    await storage.write(key: _apiKeyName, value: apiKey);
  }

  // API anahtarını güvenli bir şekilde alma
  Future<String?> getAPIKey() async {
    return await storage.read(key: _apiKeyName);
  }

  // Diyet planı oluşturma
  Future<String> generateDietPlan(String userInfo) async {
    final String prompt =
        "Sen bir diyetisyensin. Aşağıdaki kullanıcı bilgilerine göre 7 günlük sağlıklı bir diyet planı oluştur. Her gün için 3 ana öğün ve 2 ara öğün detaylandır. Beslenme değerlerini ve kalori miktarlarını da ekle. Kullanıcı verileri: $userInfo";

    return await _makeOpenAIRequest(prompt);
  }

  // Diyet tavsiyeleri oluşturma (AI Chat için)
  Future<String> generateDietAdvice(String userQuery) async {
    final String prompt =
        "Sen bir beslenme ve diyet uzmanısın. Lütfen aşağıdaki kullanıcı sorusuna kapsamlı ve faydalı bir yanıt ver: $userQuery";

    return await _makeOpenAIRequest(prompt);
  }

  // OpenAI API isteği yapma
  Future<String> _makeOpenAIRequest(String prompt) async {
    final String apiUrl = 'https://api.openai.com/v1/chat/completions';
    String? apiKey = await getAPIKey();

    // Eğer kayıtlı bir API anahtarı yoksa varsayılan anahtarı kullan
    if (apiKey == null || apiKey.isEmpty) {
      apiKey =
          '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';
    }

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {
          'Content-Type':
              'application/json; charset=utf-8', // Specify UTF-8 charset
          'Authorization': 'Bearer $apiKey',
          'Accept': 'application/json; charset=utf-8', // Accept UTF-8 response
        },
        body: utf8.encode(jsonEncode({
          // Explicitly encode using UTF-8
          "model": "gpt-4o-mini",
          "messages": [
            {
              "role": "system",
              "content":
                  "Sen bir beslenme ve diyet uzmanısın. Sağlıklı beslenme, kilo yönetimi ve beslenme alışkanlıkları konusunda profesyonel tavsiyeler veriyorsun."
            },
            {"role": "user", "content": prompt}
          ],
          "temperature": 0.7
        })),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(
            utf8.decode(response.bodyBytes)); // Explicitly decode using UTF-8
        return responseData['choices'][0]['message']['content'];
      } else {
        print(
            'API Hatası: ${response.statusCode} - ${utf8.decode(response.bodyBytes)}');
        return 'Üzgünüm, bir hata oluştu. Lütfen tekrar deneyin. (Hata kodu: ${response.statusCode})';
      }
    } catch (e) {
      print('İstek Hatası: $e');
      return 'Üzgünüm, bir bağlantı hatası oluştu. İnternet bağlantınızı kontrol edin ve tekrar deneyin.';
    }
  }
}
