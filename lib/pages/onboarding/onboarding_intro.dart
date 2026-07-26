import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mesh_gradient/mesh_gradient.dart';

import '../../config/app_theme.dart';
import '../../l10n/app_localizations.dart';
import '../../widgets/mesh_blob.dart';
import 'onboarding_widgets.dart';

/// F-5b — "canlı AI" giriş sekansı ve orb (kurgu: docs/PROGRESS.md "F-5 kurgu").
/// Mesh gradient AI'nın bedeni: girişte tam ekran akar, soru adımlarında
/// küçük nefes alan orb'a çekilir, özette büyüyerek "seni tanıdım" der.

/// Giriş sahnesi ve orb'un ortak mesh renkleri (shader tam 4 renk ister).
const List<Color> _meshColors = [
  AppColors.meshA,
  AppColors.meshB,
  AppColors.meshC,
  AppColors.darkStage,
];

/// Fon meshinin karartılmış renkleri: darkStage'e doğru %75 çekilir —
/// tam ekran Opacity'nin saveLayer maliyeti olmadan ~0.25 opaklık etkisi.
final List<Color> _dimmedMeshColors = [
  for (final c in _meshColors) Color.lerp(c, AppColors.darkStage, 0.75)!,
];

/// Koyu sahnenin tam ekran zemini — AMBIYANS katmanı (rötuş 2: konuşan
/// varlık artık metnin üstündeki büyük blob, fon onu ezmesin diye çok
/// soluk). OnboardingFlow bunu içeriğin ARKASINA (Stack) koyar ki status
/// bar dahil tüm ekranı kaplasın ve 3 alt-ekran boyunca kesintisiz aksın.
///
/// Performans notu: girişte 2 mesh instance var (bu + blob) — tek sayfa
/// olduğu için kabul; cihazda jank görülürse bu fon `seed` verilerek
/// statikleştirilebilir (AnimatedMeshGradient.seed animasyonu durdurur).
class OnbIntroMesh extends StatelessWidget {
  const OnbIntroMesh({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedMeshGradient(
      colors: _dimmedMeshColors,
      // Düşük hız + hafif dalga: fonda hafif renk kıpırtısı.
      options: AnimatedMeshGradientOptions(
        speed: 1.2,
        frequency: 3,
        amplitude: 22,
      ),
    );
  }
}

/// Sayfa 0'ın içeriği: 3 alt-ekranlık typewriter sekansı.
///
/// Dokunma: yazı yazılırken → anında tamamlanır; tamamken → sonraki
/// alt-ekran. Son alt-ekranda ipucu yerine "Başla" butonu belirir ve
/// [onStart] çağrılır (akışın mevcut `_next`'i).
class OnbIntroSequence extends StatefulWidget {
  const OnbIntroSequence({super.key, required this.onStart});

  final VoidCallback onStart;

  @override
  State<OnbIntroSequence> createState() => _OnbIntroSequenceState();
}

class _OnbIntroSequenceState extends State<OnbIntroSequence>
    with SingleTickerProviderStateMixin {
  static const Duration _charInterval = Duration(milliseconds: 45);

  /// Alt-ekran 1 ("Merhaba."): kısa cümlenin dramı yavaşlıktan gelir —
  /// yazmadan önce kısa bekleme + belirgin yavaş harf akışı (~1.2 sn toplam).
  static const Duration _firstLineDelay = Duration(milliseconds: 350);
  static const Duration _firstLineCharInterval = Duration(milliseconds: 110);

  /// Alt-ekran 1 ("Merhaba.") kısa ve vurucu — gücü büyüklükten gelir.
  static const TextStyle _displayStyle = TextStyle(
    fontSize: 36,
    fontWeight: FontWeight.w800,
    height: 1.2,
    color: AppColors.textOnDark,
  );

  /// Alt-ekran 2-3: daha uzun cümleler, gövde boyutu.
  static const TextStyle _bodyStyle = TextStyle(
    fontSize: 23,
    fontWeight: FontWeight.w600,
    height: 1.35,
    color: AppColors.textOnDark,
  );

  /// İmleç yanıp sönmesi (yazı tamamken).
  late final AnimationController _cursor;

  Timer? _typeTimer;

  /// l10n'den bir kez okunan 3 cümle (didChangeDependencies'te dolar).
  List<String>? _lines;
  int _line = 0;
  int _shownChars = 0;

  /// "Başla"ya basıldı: büyük blob küçülüp solarak sahneden çekilir
  /// (adım 1'de üst barda beliren mini blob'la "aynı varlık" hissi).
  bool _leaving = false;

  String get _fullText => _lines![_line];
  bool get _typingDone => _lines != null && _shownChars >= _fullText.length;
  bool get _isLastLine => _line == 2;

  @override
  void initState() {
    super.initState();
    _cursor = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 550),
    )..repeat(reverse: true);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_lines == null) {
      final l10n = AppLocalizations.of(context)!;
      _lines = [l10n.introLine1, l10n.introLine2, l10n.introLine3];
      _startTyping();
    }
  }

  @override
  void dispose() {
    _typeTimer?.cancel();
    _cursor.dispose();
    super.dispose();
  }

  void _startTyping() {
    _typeTimer?.cancel();
    _shownChars = 0;
    final first = _line == 0;
    final interval = first ? _firstLineCharInterval : _charInterval;

    void beginPeriodic() {
      _typeTimer = Timer.periodic(interval, (timer) {
        if (_shownChars >= _fullText.length) {
          timer.cancel();
          return;
        }
        setState(() => _shownChars++);
      });
    }

    // Bekleme sırasında da _typeTimer dolu: dokunuş onu iptal edip yazıyı
    // anında tamamlayabilir (davranış her fazda aynı).
    if (first) {
      _typeTimer = Timer(_firstLineDelay, beginPeriodic);
    } else {
      beginPeriodic();
    }
  }

  void _handleTap() {
    if (_lines == null) return;
    if (!_typingDone) {
      // İlk dokunuş: yazıyı bekletme, anında tamamla.
      _typeTimer?.cancel();
      setState(() => _shownChars = _fullText.length);
    } else if (!_isLastLine) {
      setState(() => _line++);
      _startTyping();
    }
    // Son alt-ekranda ilerleme butona bırakılır.
  }

  void _handleStart() {
    if (_leaving) return;
    setState(() => _leaving = true);
    widget.onStart();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (_lines == null) return const SizedBox.shrink();

    final full = _fullText;
    final typed = full.substring(0, _shownChars.clamp(0, full.length));
    final done = _typingDone;
    final style = _line == 0 ? _displayStyle : _bodyStyle;
    final cursorHeight = (style.fontSize ?? 24) * 0.95;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _handleTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          // Metin bloğu ortada; blok genişliğini görünmez tam metin belirler.
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Spacer(flex: 3),
            // Konuşan varlık: metnin üstünde büyük, nefes alan blob (fon
            // meshi ambiyansa çekildi, başrol burada). IgnorePointer:
            // dokunmaları yutmaz, ekranın her yeri dokunulabilir kalır.
            IgnorePointer(
              child: AnimatedOpacity(
                opacity: _leaving ? 0 : 1,
                duration: const Duration(milliseconds: 200),
                child: AnimatedScale(
                  scale: _leaving ? 0.3 : 1.0,
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeIn,
                  child: const OnbOrb(size: 130),
                ),
              ),
            ),
            const SizedBox(height: 36),
            // Görünmez tam metin yer tutar: yazı aktıkça layout zıplamaz,
            // görünen kısmi yazı blok İÇİNDE soldan akar (kısmi metni her
            // karakterde yeniden ortalamak titretirdi).
            Stack(
              children: [
                Opacity(
                  opacity: 0,
                  child: Text(full, style: style),
                ),
                Text.rich(
                  TextSpan(
                    text: typed,
                    children: [
                      WidgetSpan(
                        alignment: PlaceholderAlignment.middle,
                        child: FadeTransition(
                          opacity: done
                              ? _cursor
                              : const AlwaysStoppedAnimation(1.0),
                          child: Container(
                            width: 2.5,
                            height: cursorHeight,
                            margin: const EdgeInsets.only(left: 3),
                            decoration: BoxDecoration(
                              color: AppColors.textOnDark,
                              borderRadius: BorderRadius.circular(1),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  style: style,
                ),
              ],
            ),
            const Spacer(flex: 5),
            // Alt bölge: 1-2'de soluk ipucu, 3'te fade-in "Başla" butonu.
            SizedBox(
              height: 54,
              child: _isLastLine
                  ? AnimatedOpacity(
                      opacity: done ? 1 : 0,
                      duration: const Duration(milliseconds: 500),
                      child: IgnorePointer(
                        ignoring: !done,
                        child: OnbPrimaryButton(
                          label: l10n.onbWelcomeStart,
                          onPressed: _handleStart,
                        ),
                      ),
                    )
                  : AnimatedOpacity(
                      opacity: done ? 1 : 0,
                      duration: const Duration(milliseconds: 500),
                      child: Center(
                        child: Text(
                          l10n.introTapHint,
                          style: const TextStyle(
                            fontSize: 14,
                            letterSpacing: 0.4,
                            color: AppColors.textOnDarkSecondary,
                          ),
                        ),
                      ),
                    ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

/// Soru adımlarının üst bölgesinde nefes alan mini mesh orb'u — soruları
/// soran "canlı varlık". Shader maliyeti yüzünden akışta TEK instance
/// kullanılır (OnboardingFlow'un üst barında, sayfalar arasında sabit).
///
/// Gövde F-5c'de paylaşılan [MeshBlob]'a taşındı; burası yalnız onboarding
/// davranışlarını (mesh renkleri, emphasized büyüme/hızlanma) sarmalar.
class OnbOrb extends StatelessWidget {
  const OnbOrb({super.key, this.emphasized = false, this.size = 38});

  /// Özet adımında true: orb büyür + hafif hızlanır ("seni tanıdım, hazırım").
  final bool emphasized;

  /// Çap: üst barda 38 (varsayılan), giriş sahnesinde büyük başrol (~130).
  final double size;

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: emphasized ? 1.55 : 1.0,
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOutCubic,
      child: MeshBlob(
        size: size,
        colors: _meshColors,
        speed: emphasized ? 3 : 2,
        breathe: true,
      ),
    );
  }
}
