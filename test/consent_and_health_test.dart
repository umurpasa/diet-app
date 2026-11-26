import 'package:diet_app/config/app_theme.dart';
import 'package:diet_app/config/legal.dart';
import 'package:diet_app/main.dart' show OnboardingGate;
import 'package:diet_app/l10n/app_localizations.dart';
import 'package:diet_app/pages/consent_page.dart';
import 'package:diet_app/pages/legal_page.dart';
import 'package:diet_app/pages/onboarding/onboarding_data.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Widget _app(Widget home, String lang) => MaterialApp(
      locale: Locale(lang),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      theme: buildAppTheme(),
      home: home,
    );

List<String> _selectableTexts(WidgetTester t) => t
    .widgetList<EditableText>(find.byType(EditableText))
    .map((e) => e.controller.text)
    .toList();

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    // Uygulamadaki gibi: font ağdan değil, gömülü asset'ten.
    GoogleFonts.config.allowRuntimeFetching = false;
    SharedPreferences.setMockInitialValues({});
    // ConsentPage istemciyi alan olarak tutar; testte ağa çıkılmaz.
    await Supabase.initialize(url: 'http://localhost', publishableKey: 'test');
  });

  group('OnboardingData', () {
    test('yaş 18–120', () {
      expect(OnboardingData.isValidAge(null), isFalse);
      expect(OnboardingData.isValidAge(17), isFalse);
      expect(OnboardingData.isValidAge(18), isTrue);
      expect(OnboardingData.isValidAge(120), isTrue);
      expect(OnboardingData.isValidAge(121), isFalse);
    });

    test('atlanan sağlık adımı kolonları ve anahtarları temizler', () {
      final data = OnboardingData()
        ..conditions = {'diabetes'}
        ..medications = 'metformin'
        ..allergies = {'gluten'};
      final prefs = <String, dynamic>{};
      data.applyToPreferences(prefs);
      expect(prefs.keys, containsAll(['conditions', 'medications', 'allergies']));

      data.clearHealth();
      data.applyToPreferences(prefs);
      expect(data.healthNotShared, isTrue);
      expect(data.healthSummaryTr(), isNull);
      expect(data.allergySummaryTr(), isNull);
      expect(prefs.containsKey('conditions'), isFalse);
      expect(prefs.containsKey('medications'), isFalse);
      expect(prefs.containsKey('allergies'), isFalse);
    });

    test('"yok" cevabı "paylaşılmadı" ile karışmaz', () {
      final data = OnboardingData()
        ..conditions = {'none'}
        ..allergies = {'none'};
      expect(data.healthSummaryTr(), contains('Kronik rahatsızlık yok'));
      expect(data.allergySummaryTr(), 'Bilinen alerji/intolerans yok.');
    });
  });

  group('Aydınlatma metni', () {
    test('legal/ asset sürümü Legal.consentVersion ile aynı', () async {
      for (final path in [Legal.noticeAssetTr, Legal.noticeAssetEn]) {
        final text = await rootBundle.loadString(path);
        expect(text, contains(Legal.consentVersion), reason: path);
      }
    });

    for (final lang in ['tr', 'en']) {
      testWidgets('LegalPage $lang markdown çizer', (t) async {
        await t.pumpWidget(_app(const LegalPage(), lang));
        await t.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 200)));
        await t.pumpAndSettle();
        final texts = _selectableTexts(t);
        expect(texts, isNotEmpty);
        expect(texts.any((x) => x.contains('**') || x.startsWith('#')),
            isFalse);
        expect(t.takeException(), isNull);
      });
    }
  });

  testWidgets('ConsentPage: kutu işaretlenene kadar Devam pasif', (t) async {
    t.view.physicalSize = const Size(1080, 2340);
    t.view.devicePixelRatio = 3;
    addTearDown(t.view.reset);

    await t.pumpWidget(_app(ConsentPage(userId: 'u', onAccepted: () {}), 'tr'));
    await t.pumpAndSettle();

    ButtonStyleButton continueButton() => t.widget<ButtonStyleButton>(
          find.ancestor(
            of: find.text('Devam et'),
            matching: find.bySubtype<ButtonStyleButton>(),
          ),
        );

    expect(continueButton().onPressed, isNull);
    await t.scrollUntilVisible(find.byType(Checkbox), 200);
    expect(t.widget<Checkbox>(find.byType(Checkbox)).value, isFalse);

    await t.tap(find.byType(Checkbox));
    await t.pump();
    expect(continueButton().onPressed, isNotNull);
    expect(t.takeException(), isNull);
  });

  testWidgets('Profil okunamazsa rıza değil "Tekrar dene" gösterilir',
      (t) async {
    // Test ortamında ağ istekleri başarısız döner → profil okunamaz.
    await t.pumpWidget(_app(const OnboardingGate(userId: 'u'), 'tr'));
    for (var i = 0; i < 20 && find.text('Tekrar dene').evaluate().isEmpty; i++) {
      await t.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 100)));
      await t.pump();
    }
    expect(find.text('Bağlantı kurulamadı'), findsOneWidget);
    expect(find.text('Tekrar dene'), findsOneWidget);
    expect(find.byType(ConsentPage), findsNothing);
  });
}
