import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/features.dart';

/// AI servis katmanı.
///
/// Tüm AI çağrıları artık Supabase Edge Function ("ai") üzerinden yapılır.
/// Gemini API anahtarı SUNUCUDA (Edge Function secret) tutulur; istemcide
/// hiçbir anahtar bulunmaz. Kullanıcı profili sunucu tarafında `health_profiles`
/// tablosundan (RLS ile) okunur; istemci profil göndermez.
class AIService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Kişiselleştirilmiş diyet planı (yapılandırılmış JSON obje).
  /// [forceRegenerate] false ise sunucu önbellekteki aktif planı döndürür
  /// (yoksa yeni üretir); true ise her zaman yeniden üretir.
  Future<Map<String, dynamic>> getDietPlan({bool forceRegenerate = false}) {
    return _invokePlan(
        {'mode': 'diet_plan', 'forceRegenerate': forceRegenerate});
  }

  /// Aktif planı kullanıcı geri bildirimine göre revize eder;
  /// revize edilmiş yeni plan objesini döndürür.
  Future<Map<String, dynamic>> revisePlan({
    required List<String> reasons,
    String? note,
  }) {
    return _invokePlan({
      'mode': 'revise',
      'reasons': reasons,
      if (note != null && note.trim().isNotEmpty) 'note': note,
    });
  }

  /// AI beslenme danışmanına mesaj gönderir, yanıtı döndürür.
  Future<String> sendChatMessage(String message) async {
    final data = await _invoke({'mode': 'chat', 'message': message});
    if (data is Map && data['content'] is String) {
      return data['content'] as String;
    }
    throw AIException('Beklenmeyen sunucu yanıtı.');
  }

  Future<Map<String, dynamic>> _invokePlan(Map<String, dynamic> body) async {
    final data = await _invoke(body);
    if (data is Map && data['plan'] is Map) {
      return Map<String, dynamic>.from(data['plan'] as Map);
    }
    throw AIException('Beklenmeyen sunucu yanıtı.');
  }

  Future<dynamic> _invoke(Map<String, dynamic> body) async {
    // Store sürümünde AI kapalı: Edge Function hiçbir koşulda çağrılmaz
    // (arayüz zaten gizliyor; bu, ikinci savunma hattı).
    if (!Features.aiEnabled) throw AIException.disabled();
    try {
      final res = await _supabase.functions.invoke('ai', body: body);
      return res.data;
    } on FunctionException catch (e) {
      // Edge Function non-2xx döndürünce buraya düşer; gövde e.details'te.
      String message = 'AI isteği başarısız oldu. Lütfen tekrar dene.';
      final details = e.details;
      if (details is Map && details['error'] is String) {
        message = details['error'] as String;
      }
      throw AIException(message, isLimit: e.status == 429);
    } catch (e) {
      throw AIException(
          'Bağlantı hatası. İnternetini kontrol edip tekrar dene.');
    }
  }
}

/// AI katmanından fırlatılan, kullanıcıya gösterilebilir hata.
class AIException implements Exception {
  final String message;

  /// Günlük kullanım limiti aşıldıysa true.
  final bool isLimit;

  /// Özellik bu sürümde kapalıysa true ([Features.aiEnabled] == false).
  final bool isDisabled;

  AIException(this.message, {this.isLimit = false, this.isDisabled = false});

  /// AI kapalıyken fırlatılır. Arayüz bunu metniyle değil [isDisabled]
  /// ile tanır ve l10n'li "aktif değil" durumunu gösterir; mesaj yalnızca
  /// log/geliştirici içindir.
  AIException.disabled()
      : message = 'AI features are disabled in this build.',
        isLimit = false,
        isDisabled = true;

  @override
  String toString() => message;
}
