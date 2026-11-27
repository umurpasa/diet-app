import 'package:diet_app/config/app_theme.dart';
import 'package:diet_app/l10n/app_localizations.dart';
import 'package:diet_app/widgets/delete_account_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' show ClientException;

/// Hesap silme akışını açan bir buton; sonucu [onResult]'a bildirir.
Widget _app(String lang, AccountDeleter deleter, void Function(bool) onResult) =>
    MaterialApp(
      locale: Locale(lang),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      theme: buildAppTheme(),
      home: Scaffold(
        body: Builder(
          builder: (context) => TextButton(
            onPressed: () async =>
                onResult(await showDeleteAccountFlow(context, deleter: deleter)),
            child: const Text('open'),
          ),
        ),
      ),
    );

final _button = find.byKey(const ValueKey('deleteConfirmButton'));
final _field = find.byKey(const ValueKey('deleteConfirmField'));

bool _enabled(WidgetTester t) =>
    t.widget<FilledButton>(_button).onPressed != null;

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  test('deleteConfirmMatches: trim + birebir, büyük harf dönüşümü yok', () {
    expect(deleteConfirmMatches('SİL', 'SİL'), isTrue);
    expect(deleteConfirmMatches('  SİL \n', 'SİL'), isTrue);
    expect(deleteConfirmMatches('sil', 'SİL'), isFalse);
    expect(deleteConfirmMatches('SIL', 'SİL'), isFalse); // noktasız I
    expect(deleteConfirmMatches('DELETE', 'DELETE'), isTrue);
    expect(deleteConfirmMatches('delete', 'DELETE'), isFalse);
    expect(deleteConfirmMatches('', 'DELETE'), isFalse);
  });

  const cases = {
    'tr': (word: 'SİL', wrong: ['sil', 'SIL', 'Sİ'], cont: 'Devam'),
    'en': (word: 'DELETE', wrong: ['delete', 'DELET', 'SİL'], cont: 'Continue'),
  };

  for (final MapEntry(key: lang, value: c) in cases.entries) {
    testWidgets('$lang: kelime eşleşmeden buton pasif, eşleşince aktif',
        (t) async {
      var calls = 0;
      bool? result;
      await t.pumpWidget(_app(lang, () async => calls++, (r) => result = r));

      await t.tap(find.text('open'));
      await t.pumpAndSettle();
      await t.tap(find.text(c.cont));
      await t.pumpAndSettle();

      expect(_enabled(t), isFalse);
      for (final w in c.wrong) {
        await t.enterText(_field, w);
        await t.pump();
        expect(_enabled(t), isFalse, reason: w);
      }

      await t.enterText(_field, ' ${c.word} ');
      await t.pump();
      expect(_enabled(t), isTrue);

      await t.tap(_button);
      await t.pumpAndSettle();
      expect(calls, 1);
      expect(result, isTrue);
      expect(_button, findsNothing);
    });
  }

  testWidgets('ilk adımda Vazgeç → silme yok, false', (t) async {
    var calls = 0;
    bool? result;
    await t.pumpWidget(_app('tr', () async => calls++, (r) => result = r));
    await t.tap(find.text('open'));
    await t.pumpAndSettle();
    await t.tap(find.text('Vazgeç'));
    await t.pumpAndSettle();
    expect(calls, 0);
    expect(result, isFalse);
  });

  testWidgets('ağ hatasında dialog açık kalır, bağlantı mesajı', (t) async {
    bool? result;
    await t.pumpWidget(_app(
      'tr',
      () async => throw ClientException('Failed host lookup'),
      (r) => result = r,
    ));
    await t.tap(find.text('open'));
    await t.pumpAndSettle();
    await t.tap(find.text('Devam'));
    await t.pumpAndSettle();
    await t.enterText(_field, 'SİL');
    await t.pump();
    await t.tap(_button);
    await t.pumpAndSettle();

    expect(result, isNull);
    expect(_button, findsOneWidget);
    expect(_enabled(t), isTrue);
    expect(find.textContaining('Bağlantı hatası'), findsOneWidget);
  });

  testWidgets('sunucu hatasında genel silinemedi mesajı', (t) async {
    await t.pumpWidget(_app(
      'en',
      () async => throw Exception('FunctionException(status: 500)'),
      (_) {},
    ));
    await t.tap(find.text('open'));
    await t.pumpAndSettle();
    await t.tap(find.text('Continue'));
    await t.pumpAndSettle();
    await t.enterText(_field, 'DELETE');
    await t.pump();
    await t.tap(_button);
    await t.pumpAndSettle();

    expect(_button, findsOneWidget);
    expect(find.textContaining("Couldn't delete your account"), findsOneWidget);
  });
}
