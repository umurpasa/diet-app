import 'package:flutter/material.dart';

/// "Derin Teal" renk paleti (karar: docs/BACKLOG.md F-1 + F-5, 2026-07-09).
///
/// Ana palette kırmızı YOK — [sos] yalnızca acil akışı ve error için;
/// SOS butonu tek başına dikkat çeker. Tek mod (dark mode bilinçli yok).
class AppColors {
  AppColors._();

  static const Color primary = Color(0xFF3E6660);
  static const Color onPrimary = Color(0xFFFCFDFC);
  static const Color primaryContainer = Color(0xFFBCD4CE);
  static const Color onPrimaryContainer = Color(0xFF1C2B28);

  /// Vurgu rengi — az ve anlamlı kullan (motivasyon/hedef öğeleri).
  static const Color secondary = Color(0xFFC98F52);

  /// Eski #54350F yeni secondary üstünde ~4.0:1 kalıyordu (4.5 altı);
  /// koyulaştırıldı → ~5.0:1.
  static const Color onSecondary = Color(0xFF3E2708);

  /// Scaffold zemini — görünür sage-teal tint (koyu çapa + renkli açık zemin).
  static const Color background = Color(0xFFE3EDE9);

  /// Kart/surface.
  static const Color surface = Color(0xFFFCFDFC);

  /// Input/chip dolgusu — hem zeminden hem beyaz karttan ayrışır.
  static const Color fieldFill = Color(0xFFDCE7E1);

  /// Ana metin.
  static const Color text = Color(0xFF1C2B28);

  /// İkincil metin (alt yazılar, ipuçları).
  static const Color textSecondary = Color(0xFF5F7772);

  // Koyu sahne (onboarding girişi; ileride Acil mesh'i — F-5c).
  /// Dramatik anların koyu zemini.
  static const Color darkStage = Color(0xFF16221F);

  /// Koyu sahnede ana metin.
  static const Color textOnDark = Color(0xFFE8EFEA);

  /// Koyu sahnede ikincil metin.
  static const Color textOnDarkSecondary = Color(0xFF7FA097);

  // Mesh/orb renkleri ("yaşayan AI" görsel kimliği).
  static const Color meshA = Color(0xFF3E6660);
  static const Color meshB = Color(0xFF7FB0A5);

  /// Koyu sahnede sıcak ışıltı (eski apricot).
  static const Color meshC = Color(0xFFD9A268);

  /// SOS/acil kırmızısı (mat tuğla) — error rengi de bu.
  static const Color sos = Color(0xFFC94F42);

  // SOS türevleri — acil akışındaki eski Colors.red.shade* tonlarının
  // mat tuğla karşılıkları.
  static const Color sosDark = Color(0xFF7F2F26); // koyu başlık/metin
  static const Color sosContainer = Color(0xFFE8C2BC); // nefes dairesi dolgusu
  static const Color sosSoft = Color(0xFFF0D8D4); // progress zemini
  static const Color sosBackground = Color(0xFFFBF0EE); // acil sayfa zemini

  /// Acil giriş sahnesinin koyu zemini — [darkStage]'in sos ailesi kardeşi
  /// (F-5d: SOS'a basınca "alarma bastım, duyuldum" anı; adımlarda açık
  /// zemine yumuşar).
  static const Color sosStage = Color(0xFF2B1714);
}

/// Uygulamanın merkezi Material 3 teması.
ThemeData buildAppTheme() {
  const colorScheme = ColorScheme.light(
    primary: AppColors.primary,
    onPrimary: AppColors.onPrimary,
    primaryContainer: AppColors.primaryContainer,
    onPrimaryContainer: AppColors.onPrimaryContainer,
    secondary: AppColors.secondary,
    onSecondary: AppColors.onSecondary,
    surface: AppColors.surface,
    onSurface: AppColors.text,
    onSurfaceVariant: AppColors.textSecondary,
    outline: AppColors.textSecondary,
    error: AppColors.sos,
    onError: AppColors.onPrimary,
  );

  final base = ThemeData(useMaterial3: true, colorScheme: colorScheme);

  return base.copyWith(
    scaffoldBackgroundColor: AppColors.background,
    textTheme: base.textTheme
        .apply(bodyColor: AppColors.text, displayColor: AppColors.text)
        .copyWith(
          bodySmall: base.textTheme.bodySmall
              ?.copyWith(color: AppColors.textSecondary),
        ),
    // Sayfalar sırası gelene kadar mevcut AppBar'lar renkli blok gibi
    // durmasın, zemine karışsın (tasarım dili: renkli klasik AppBar yok).
    appBarTheme: const AppBarTheme(
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: AppColors.background,
      foregroundColor: AppColors.text,
      surfaceTintColor: Colors.transparent,
      centerTitle: false,
    ),
    // Kenarlık/gölge yok — kart, zemin ton farkıyla ayrışır.
    cardTheme: CardThemeData(
      color: AppColors.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: const StadiumBorder(),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: const StadiumBorder(),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.primary,
        side: const BorderSide(color: AppColors.primary),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: const StadiumBorder(),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.primary,
        shape: const StadiumBorder(),
      ),
    ),
    chipTheme: base.chipTheme.copyWith(
      backgroundColor: AppColors.fieldFill,
      selectedColor: AppColors.primaryContainer,
      checkmarkColor: AppColors.onPrimaryContainer,
      side: BorderSide.none,
      shape: const StadiumBorder(),
      labelStyle: TextStyle(
        color: WidgetStateColor.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? AppColors.onPrimaryContainer
              : AppColors.text,
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.fieldFill,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.sos),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.sos, width: 1.5),
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: AppColors.surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: AppColors.surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: AppColors.primary,
      foregroundColor: AppColors.onPrimary,
      shape: StadiumBorder(),
      elevation: 1,
      highlightElevation: 2,
    ),
  );
}
