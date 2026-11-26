/// Aydınlatma metni / açık rıza sabitleri (KVKK).
class Legal {
  Legal._();

  /// legal/*.md içindeki "Sürüm" ile aynı olmalı. Değişirse kullanıcıdan yeniden rıza istenir.
  static const String consentVersion = '2026-11-1';

  // Site yayına girince doldurulacak (4. adım):
  static const String privacyPolicyUrl = '';
  static const String accountDeletionUrl = '';

  /// Uygulama içi metinler — repodaki `legal/` doğrudan asset (tek kaynak).
  static const String noticeAssetTr = 'legal/aydinlatma-metni.tr.md';
  static const String noticeAssetEn = 'legal/privacy-policy.en.md';
}
