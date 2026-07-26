import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Uygulama dili (TR/EN) durumu.
///
/// Tercih cihazda `SharedPreferences` 'locale' anahtarında saklanır — bu bir
/// cihaz-yerel UI tercihi, sağlık verisi değil; sunucuya yazılmaz. Kayıt
/// yoksa [notifier] null kalır ve sistem dili kullanılır; sistem dili de
/// TR/EN değilse [resolve] EN'e düşer.
class LocaleController {
  LocaleController._();

  static const _prefsKey = 'locale';
  static const supported = [Locale('tr'), Locale('en')];

  /// Seçili dil; null → sistem dili. MaterialApp bunu dinler, dil
  /// değişince tüm uygulama yeniden çizilir.
  static final notifier = ValueNotifier<Locale?>(null);

  /// Kaydedilmiş tercihi yükler (runApp'ten önce çağrılır).
  static Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString(_prefsKey);
    if (code != null && supported.any((l) => l.languageCode == code)) {
      notifier.value = Locale(code);
    }
  }

  /// Dili değiştirir ve tercihi cihaza kaydeder.
  static Future<void> set(Locale locale) async {
    notifier.value = locale;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, locale.languageCode);
  }

  /// MaterialApp.localeResolutionCallback: sistem dili desteklenmiyorsa EN.
  static Locale resolve(Locale? device, Iterable<Locale> supportedLocales) {
    if (device != null &&
        supportedLocales.any((l) => l.languageCode == device.languageCode)) {
      return Locale(device.languageCode);
    }
    return const Locale('en');
  }
}
