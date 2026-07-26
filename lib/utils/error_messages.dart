import 'package:http/http.dart' show ClientException;

/// Ağ kaynaklı hatalarda kullanıcıya gösterilecek ortak mesaj.
const String connectionErrorMessage =
    'Bağlantı hatası. İnternet bağlantını kontrol edip tekrar dene.';

/// Hatanın internet bağlantısı kaynaklı olup olmadığını tahmin eder.
///
/// `SocketException` `dart:io`'da olduğundan (web derlemesi için) tip
/// yerine mesaj metninden tanınır.
bool isNetworkError(Object e) {
  if (e is ClientException) return true;
  final text = e.toString();
  return text.contains('SocketException') ||
      text.contains('Failed host lookup') ||
      text.contains('Connection refused') ||
      text.contains('Network is unreachable');
}

/// Generic catch bloklarında kullanılacak mesaj: ağ hatasıysa anlaşılır
/// bağlantı mesajı, değilse mevcut "Beklenmeyen hata: ..." davranışı.
String friendlyErrorMessage(Object e) =>
    isNetworkError(e) ? connectionErrorMessage : 'Beklenmeyen hata: $e';
