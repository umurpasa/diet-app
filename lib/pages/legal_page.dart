import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;

import '../config/app_theme.dart';
import '../config/legal.dart';
import '../l10n/app_localizations.dart';
import '../widgets/page_header.dart';

/// Aydınlatma metni / gizlilik politikası (KVKK).
///
/// Uygulama diline göre repodaki `legal/` altındaki TR ya da EN markdown'ı
/// okur ve paket kullanmadan basit bir görüntüleyiciyle çizer (bkz.
/// [_MarkdownView]). `legal/` doğrudan asset — site de aynı dosyaları
/// kullanır, kopya yok.
class LegalPage extends StatefulWidget {
  const LegalPage({super.key});

  @override
  State<LegalPage> createState() => _LegalPageState();
}

class _LegalPageState extends State<LegalPage> {
  String? _assetPath;
  Future<String>? _future;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final path = Localizations.localeOf(context).languageCode == 'tr'
        ? Legal.noticeAssetTr
        : Legal.noticeAssetEn;
    if (path != _assetPath) {
      _assetPath = path;
      _future = rootBundle.loadString(path);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // İnce üst satır: geri ok (tasarım dili gereği AppBar yok).
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  tooltip: MaterialLocalizations.of(context).backButtonTooltip,
                  onPressed: () => Navigator.of(context).maybePop(),
                  icon: const Icon(Icons.arrow_back, color: AppColors.text),
                ),
              ),
            ),
            Expanded(
              child: FutureBuilder<String>(
                future: _future,
                builder: (context, snapshot) {
                  final header = PageHeader(
                    eyebrow: l10n.legalEyebrow,
                    title: l10n.legalTitle,
                    showAvatar: false,
                    padding: const EdgeInsets.only(bottom: 18),
                  );
                  final Widget body;
                  if (snapshot.hasError) {
                    body = Padding(
                      padding: const EdgeInsets.only(top: 24),
                      child: Text(
                        l10n.legalLoadFailed,
                        style: const TextStyle(color: AppColors.sos),
                      ),
                    );
                  } else if (!snapshot.hasData) {
                    body = const Padding(
                      padding: EdgeInsets.only(top: 48),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  } else {
                    body = _MarkdownView(source: snapshot.data!);
                  }
                  return ListView(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 48),
                    children: [header, body],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---- Basit markdown görüntüleyici ----
//
// Desteklenen alt küme (legal/*.md'nin kullandığı kadarı): `#`/`##` başlık,
// paragraf (ardışık satırlar satır sonuyla korunur), `- ` madde, `> ` alıntı
// kutusu, `|` tablo (her veri satırı küçük bir kart), satır içi `**kalın**`
// ve `*italik*`. Bilinmeyen sözdizimi düz metin olarak görünür.

sealed class _Block {}

class _Heading extends _Block {
  _Heading(this.level, this.text);
  final int level;
  final String text;
}

class _Paragraph extends _Block {
  _Paragraph(this.text);
  final String text;
}

class _Bullets extends _Block {
  _Bullets(this.items);
  final List<String> items;
}

class _Quote extends _Block {
  _Quote(this.text);
  final String text;
}

class _Table extends _Block {
  _Table(this.header, this.rows);
  final List<String> header;
  final List<List<String>> rows;
}

List<_Block> _parse(String source) {
  final lines = source.replaceAll('\r\n', '\n').split('\n');
  final blocks = <_Block>[];
  var i = 0;

  bool isSpecial(String l) =>
      l.startsWith('#') ||
      l.startsWith('- ') ||
      l.startsWith('>') ||
      l.startsWith('|');

  List<String> cells(String row) {
    var r = row.trim();
    if (r.startsWith('|')) r = r.substring(1);
    if (r.endsWith('|')) r = r.substring(0, r.length - 1);
    return r.split('|').map((c) => c.trim()).toList();
  }

  while (i < lines.length) {
    final line = lines[i].trimRight();
    final t = line.trimLeft();

    if (t.isEmpty) {
      i++;
    } else if (t.startsWith('#')) {
      final level = t.length - t.replaceFirst(RegExp(r'^#+'), '').length;
      blocks.add(_Heading(level, t.substring(level).trim()));
      i++;
    } else if (t.startsWith('- ')) {
      final items = <String>[];
      while (i < lines.length && lines[i].trimLeft().startsWith('- ')) {
        items.add(lines[i].trimLeft().substring(2).trim());
        i++;
      }
      blocks.add(_Bullets(items));
    } else if (t.startsWith('>')) {
      final buf = <String>[];
      while (i < lines.length && lines[i].trimLeft().startsWith('>')) {
        buf.add(lines[i].trimLeft().substring(1).trim());
        i++;
      }
      blocks.add(_Quote(buf.join('\n')));
    } else if (t.startsWith('|')) {
      final rows = <List<String>>[];
      while (i < lines.length && lines[i].trimLeft().startsWith('|')) {
        final c = cells(lines[i]);
        // Ayırıcı satır (|---|---|) atlanır.
        final isSeparator = c.every((x) => RegExp(r'^:?-+:?$').hasMatch(x));
        if (!isSeparator) rows.add(c);
        i++;
      }
      if (rows.isNotEmpty) {
        blocks.add(_Table(rows.first, rows.skip(1).toList()));
      }
    } else {
      final buf = <String>[];
      while (i < lines.length) {
        final l = lines[i].trim();
        if (l.isEmpty || isSpecial(l)) break;
        buf.add(l);
        i++;
      }
      blocks.add(_Paragraph(buf.join('\n')));
    }
  }
  return blocks;
}

/// `**kalın**` ve `*italik*` → TextSpan listesi.
List<TextSpan> _inline(String text, {TextStyle? base}) {
  final spans = <TextSpan>[];
  final pattern = RegExp(r'\*\*(.+?)\*\*|\*(.+?)\*');
  var last = 0;
  for (final m in pattern.allMatches(text)) {
    if (m.start > last) {
      spans.add(TextSpan(text: text.substring(last, m.start), style: base));
    }
    if (m.group(1) != null) {
      spans.add(TextSpan(
        text: m.group(1),
        style: (base ?? const TextStyle())
            .copyWith(fontWeight: FontWeight.w700),
      ));
    } else {
      spans.add(TextSpan(
        text: m.group(2),
        style: (base ?? const TextStyle())
            .copyWith(fontStyle: FontStyle.italic),
      ));
    }
    last = m.end;
  }
  if (last < text.length) {
    spans.add(TextSpan(text: text.substring(last), style: base));
  }
  return spans;
}

class _MarkdownView extends StatelessWidget {
  const _MarkdownView({required this.source});

  final String source;

  static const _body = TextStyle(
    fontSize: 15,
    height: 1.5,
    color: AppColors.text,
  );

  Widget _rich(String text, TextStyle style) =>
      SelectableText.rich(TextSpan(children: _inline(text, base: style)));

  Widget _block(_Block b) {
    switch (b) {
      case _Heading(:final level, :final text):
        return Padding(
          padding: EdgeInsets.only(top: level == 1 ? 4 : 20, bottom: 8),
          child: _rich(
            text,
            TextStyle(
              fontSize: level == 1 ? 21 : 17,
              fontWeight: FontWeight.w700,
              height: 1.3,
              color: AppColors.text,
            ),
          ),
        );
      case _Paragraph(:final text):
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _rich(text, _body),
        );
      case _Bullets(:final items):
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final item in items)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(top: 9, right: 10, left: 2),
                        child: CircleAvatar(
                          radius: 2.5,
                          backgroundColor: AppColors.primary,
                        ),
                      ),
                      Expanded(child: _rich(item, _body)),
                    ],
                  ),
                ),
            ],
          ),
        );
      case _Quote(:final text):
        return Container(
          margin: const EdgeInsets.only(bottom: 14),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.primaryContainer,
            borderRadius: BorderRadius.circular(16),
          ),
          child: _rich(
            text,
            _body.copyWith(color: AppColors.onPrimaryContainer),
          ),
        );
      case _Table(:final header, :final rows):
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Column(
            children: [
              for (final row in rows) _tableCard(header, row),
            ],
          ),
        );
    }
  }

  /// Tablo satırı → kart: ilk hücre başlık, kalanlar "Sütun: değer".
  Widget _tableCard(List<String> header, List<String> row) {
    String at(List<String> l, int i) => i < l.length ? l[i] : '';
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _rich(
            at(row, 0),
            const TextStyle(
              fontSize: 15.5,
              fontWeight: FontWeight.w700,
              height: 1.35,
              color: AppColors.text,
            ),
          ),
          for (var c = 1; c < row.length; c++) ...[
            const SizedBox(height: 6),
            SelectableText.rich(
              TextSpan(
                children: [
                  if (at(header, c).isNotEmpty)
                    TextSpan(
                      text: '${at(header, c)}: ',
                      style: const TextStyle(
                        fontSize: 14,
                        height: 1.45,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ..._inline(
                    row[c],
                    base: const TextStyle(
                      fontSize: 14,
                      height: 1.45,
                      color: AppColors.text,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final blocks = _parse(source);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [for (final b in blocks) _block(b)],
    );
  }
}
