import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mesh_gradient/mesh_gradient.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/app_theme.dart';
import '../l10n/app_localizations.dart';
import '../widgets/mesh_blob.dart';

/// Acil Buton — kriz anı için tamamen statik, yargılamayan akış (AI yok).
///
/// F-5d: SOS'a basınca koyu kırmızı giriş sahnesi (onboarding girişinin
/// aynası — "alarma bastım, duyuldum") → adımlara geçince zemin açığa
/// yumuşar. Adımlar yeni tasarım dilinde (AppBar yok, büyük başlık,
/// kenarlıksız kartlar, hap butonlar); tüm metinler l10n'de (`em` öneki).
///
/// Adımlar: giriş → tetikleyici seçimi → nefes egzersizi (30 sn geri sayım)
/// → bir bardak su + opsiyonel 5 dk zamanlayıcı → tetikleyiciye göre sağlıklı
/// alternatifler → yargısız kapanış → sonuç seçimi → teşekkür ekranı.
/// Sonuç `emergency_logs`'a yazılır (trigger_type + outcome, değerler
/// İngilizce anahtar olarak sabit); insert hata verirse sessiz geçilir,
/// akış bozulmaz. Geri okla önceki adıma dönülebilir (girişe dönüş yok),
/// sağ üstteki X her adımda çıkış.

/// F-5c — acil akışın "canlı AI" renk ailesi (shader tam 4 renk ister):
/// kırmızı odaklı ama yumuşak — sos + açık türevleri + koyu sahnenin sıcak
/// ışıltısı (meshC). Agresif neon değil; hedef sakinleştirmek.
const List<Color> _sosMeshColors = [
  AppColors.sos,
  AppColors.sosContainer,
  AppColors.meshC,
  AppColors.sosSoft,
];

/// Adımların arkasındaki soluk ambiyansın renkleri: sosBackground'a
/// %85 harmanlanır (~0.15 etki) — tam ekran Opacity'nin saveLayer maliyeti
/// olmadan soluklaştırma (onboarding fonundaki teknik).
final List<Color> _sosAmbientColors = [
  for (final c in _sosMeshColors) Color.lerp(c, AppColors.sosBackground, 0.85)!,
];

/// Giriş sahnesinin mesh renkleri: sosStage'e %65 çekilir (~0.35 etki) —
/// adımlardaki ambiyanstan belirgin ("alarm" anı) ama büyük blob'u ezmez.
final List<Color> _sosStageMeshColors = [
  for (final c in _sosMeshColors) Color.lerp(c, AppColors.sosStage, 0.65)!,
];

/// Kenarlıksız beyaz kartlarda zeminden ayrım için çok hafif gölge
/// (onboarding `onbSoftShadow` ile aynı değerler — tasarım dili).
const List<BoxShadow> _softShadow = [
  BoxShadow(color: Color(0x0D000000), blurRadius: 10, offset: Offset(0, 2)),
];

class EmergencyPage extends StatefulWidget {
  const EmergencyPage({super.key});

  @override
  State<EmergencyPage> createState() => _EmergencyPageState();
}

class _EmergencyPageState extends State<EmergencyPage>
    with TickerProviderStateMixin {
  final _supabase = Supabase.instance.client;
  final _pageController = PageController();

  // Adım indeksleri (PageView sırası).
  static const _stepIntro = 0;
  static const _stepTrigger = 1;
  static const _stepBreathing = 2;
  static const _stepWater = 3;
  static const _stepAlternatives = 4;
  static const _stepClosing = 5;
  static const _stepOutcome = 6;
  static const _stepThanks = 7;

  static const _breathSeconds = 30;
  static const _waterTimerSeconds = 5 * 60;

  /// DB'ye yazılan tetikleyici anahtarları (ekran etiketi l10n'den gelir).
  static const _triggerKeys = [
    'night_snacking',
    'sweet_craving',
    'hunger_between_meals',
    'stress_eating',
  ];

  int _step = _stepIntro;
  String? _selectedTrigger;
  bool _isSaving = false;

  /// Giriş meshi ağaçta mı? Girişten çıkınca fade-out biter bitmez
  /// kaldırılır (shader boşuna çalışmasın — onboarding deseni).
  bool _introMeshMounted = true;

  /// 30 sn geri sayım (nefes adımı).
  late final AnimationController _countdownController;

  /// 4 sn'lik al/ver döngüsü (blob ölçeği + faz metni).
  late final AnimationController _breathController;

  Timer? _waterTimer;
  int _waterSecondsLeft = _waterTimerSeconds;
  bool _waterTimerRunning = false;
  bool _waterTimerDone = false;

  @override
  void initState() {
    super.initState();
    _countdownController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: _breathSeconds),
    )..addStatusListener((status) {
        // Geri sayım bitince "Devam" butonunu aktifleştirmek için rebuild.
        if (status == AnimationStatus.completed && mounted) setState(() {});
      });
    _breathController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    _countdownController.dispose();
    _breathController.dispose();
    _waterTimer?.cancel();
    super.dispose();
  }

  void _goToStep(int step) {
    // Adıma özel zamanlayıcılar: sadece ilgili adımda çalışsın.
    if (step == _stepBreathing) {
      _countdownController.forward(from: 0);
      _breathController.repeat(reverse: true);
    } else {
      _countdownController.stop();
      _breathController.stop();
    }
    if (step != _stepWater) _cancelWaterTimer();

    setState(() => _step = step);
    _pageController.animateToPage(
      step,
      // Koyu→açık zemin geçişiyle (giriş→adımlar) aynı süre/eğri.
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOutCubic,
    );
  }

  void _startWaterTimer() {
    _waterTimer?.cancel();
    setState(() {
      _waterSecondsLeft = _waterTimerSeconds;
      _waterTimerRunning = true;
      _waterTimerDone = false;
    });
    _waterTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() {
        _waterSecondsLeft--;
        if (_waterSecondsLeft <= 0) {
          timer.cancel();
          _waterTimerRunning = false;
          _waterTimerDone = true;
        }
      });
    });
  }

  void _cancelWaterTimer() {
    _waterTimer?.cancel();
    _waterTimer = null;
    _waterTimerRunning = false;
    _waterTimerDone = false;
    _waterSecondsLeft = _waterTimerSeconds;
  }

  /// Sonucu kaydeder ve teşekkür ekranına geçer. Insert başarısız olsa bile
  /// akış bozulmaz (kayıt kritik değil, kullanıcı kriz anında).
  Future<void> _saveOutcome(String outcome) async {
    if (_isSaving) return;
    setState(() => _isSaving = true);

    final userId = _supabase.auth.currentUser?.id;
    if (userId != null) {
      try {
        await _supabase.from('emergency_logs').insert({
          'user_id': userId,
          'trigger_type': _selectedTrigger,
          'outcome': outcome,
        });
      } catch (_) {
        // Sessiz geç: teşekkür ekranı her durumda gösterilir.
      }
    }

    if (!mounted) return;
    setState(() => _isSaving = false);
    _goToStep(_stepThanks);
  }

  // ---- l10n eşlemeleri (DB anahtarı → ekran etiketi) ----

  String _triggerLabel(AppLocalizations l10n, String key) => switch (key) {
        'night_snacking' => l10n.emTriggerNightSnacking,
        'sweet_craving' => l10n.emTriggerSweetCraving,
        'hunger_between_meals' => l10n.emTriggerHungerBetweenMeals,
        _ => l10n.emTriggerStressEating,
      };

  List<String> _alternativesFor(AppLocalizations l10n, String? key) =>
      switch (key) {
        'sweet_craving' => [
            l10n.emAltSweetCraving1,
            l10n.emAltSweetCraving2,
            l10n.emAltSweetCraving3,
          ],
        'hunger_between_meals' => [
            l10n.emAltHungerBetweenMeals1,
            l10n.emAltHungerBetweenMeals2,
            l10n.emAltHungerBetweenMeals3,
          ],
        'stress_eating' => [
            l10n.emAltStressEating1,
            l10n.emAltStressEating2,
            l10n.emAltStressEating3,
          ],
        // Varsayılan: gece atıştırması (tetikleyici seçilmeden gelinemez).
        _ => [
            l10n.emAltNightSnacking1,
            l10n.emAltNightSnacking2,
            l10n.emAltNightSnacking3,
          ],
      };

  // ---------------------------------------------------------------- yapı

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final intro = _step == _stepIntro;
    final canGoBack = _step > _stepTrigger && _step != _stepThanks;

    // Koyu girişte status bar ikonları açık renk, adımlarda normale döner.
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: intro ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Scaffold(
        // Meshler zemini tamamen örter; bu renk yalnız ilk kare emniyeti.
        backgroundColor: intro ? AppColors.sosStage : AppColors.sosBackground,
        body: Stack(
          children: [
            // Soluk ambiyans: sos-ailesi kıpırtı, adımlar boyunca kesintisiz
            // (tek instance, sayfayla dispose). Girişte mount edilmez —
            // koyu→açık geçiş iki meshin çapraz solmasıyla yumuşar.
            if (!intro)
              Positioned.fill(
                child: AnimatedMeshGradient(
                  colors: _sosAmbientColors,
                  options: AnimatedMeshGradientOptions(
                    speed: 1.2,
                    frequency: 3,
                    amplitude: 22,
                  ),
                ),
              ),
            // Giriş sahnesinin koyu meshi — adımlara geçince 400ms fade-out
            // edip ağaçtan kalkar (zemin geçişi PageView ile eş süre).
            if (_introMeshMounted)
              Positioned.fill(
                child: AnimatedOpacity(
                  opacity: intro ? 1 : 0,
                  duration: const Duration(milliseconds: 400),
                  onEnd: () {
                    if (_step != _stepIntro && mounted) {
                      setState(() => _introMeshMounted = false);
                    }
                  },
                  child: AnimatedMeshGradient(
                    colors: _sosStageMeshColors,
                    options: AnimatedMeshGradientOptions(
                      speed: 1.2,
                      frequency: 3,
                      amplitude: 22,
                    ),
                  ),
                ),
              ),
            SafeArea(
              child: Column(
                children: [
                  // İnce üst satır: geri ok (adım 2+) · boşluk · X (AppBar yok).
                  Padding(
                    padding: const EdgeInsets.fromLTRB(8, 4, 8, 0),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 48,
                          height: 48,
                          child: canGoBack
                              ? IconButton(
                                  icon: const Icon(Icons.arrow_back,
                                      color: AppColors.text),
                                  tooltip: l10n.onbBackTooltip,
                                  onPressed: () => _goToStep(_step - 1),
                                )
                              : null,
                        ),
                        const Spacer(),
                        IconButton(
                          icon: Icon(
                            Icons.close,
                            color:
                                intro ? AppColors.textOnDark : AppColors.text,
                          ),
                          tooltip: l10n.onbExitTooltip,
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: PageView(
                      controller: _pageController,
                      physics: const NeverScrollableScrollPhysics(),
                      children: [
                        _EmIntroSequence(
                          onDone: () => _goToStep(_stepTrigger),
                        ),
                        _buildTriggerStep(l10n),
                        _buildBreathingStep(l10n),
                        _buildWaterStep(l10n),
                        _buildAlternativesStep(l10n),
                        _buildClosingStep(l10n),
                        _buildOutcomeStep(l10n),
                        _buildThanksStep(l10n),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  ButtonStyle get _primaryStyle => ElevatedButton.styleFrom(
        backgroundColor: AppColors.sos,
        foregroundColor: Colors.white,
        minimumSize: const Size.fromHeight(54),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      );

  Widget _stepBody({
    required String title,
    String? subtitle,
    required Widget child,
    List<Widget> bottom = const [],
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              height: 1.15,
              color: AppColors.sosDark,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 10),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 15,
                height: 1.45,
                color: AppColors.textSecondary,
              ),
            ),
          ],
          const SizedBox(height: 24),
          Expanded(child: child),
          ...bottom,
        ],
      ),
    );
  }

  // ------------------------------------------------------- adım: tetikleyici

  Widget _buildTriggerStep(AppLocalizations l10n) {
    const icons = <String, IconData>{
      'night_snacking': Icons.nightlight_round,
      'sweet_craving': Icons.icecream,
      'hunger_between_meals': Icons.schedule,
      'stress_eating': Icons.psychology,
    };

    return _stepBody(
      title: l10n.emTriggerTitle,
      subtitle: l10n.emTriggerSubtitle,
      child: ListView(
        children: [
          for (final key in _triggerKeys)
            _EmSelectCard(
              icon: icons[key],
              label: _triggerLabel(l10n, key),
              // Seçim=ilerleme: seçili dolgu sayfa kayarken kısa görünür.
              selected: _selectedTrigger == key,
              onTap: () {
                setState(() => _selectedTrigger = key);
                _goToStep(_stepBreathing);
              },
            ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------- adım: nefes

  Widget _buildBreathingStep(AppLocalizations l10n) {
    final done = _countdownController.status == AnimationStatus.completed;

    return _stepBody(
      title: l10n.emBreathTitle,
      subtitle: l10n.emBreathSubtitle,
      child: Center(
        child: AnimatedBuilder(
          animation:
              Listenable.merge([_countdownController, _breathController]),
          builder: (context, _) {
            final remaining =
                (_breathSeconds * (1 - _countdownController.value))
                    .ceil()
                    .clamp(0, _breathSeconds);
            final inhaling =
                _breathController.status != AnimationStatus.reverse;
            final scale = 0.75 + 0.25 * _breathController.value;

            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 200,
                  height: 200,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 200,
                        height: 200,
                        child: CircularProgressIndicator(
                          value: 1 - _countdownController.value,
                          strokeWidth: 6,
                          color: AppColors.sos,
                          backgroundColor: AppColors.sosSoft,
                        ),
                      ),
                      Transform.scale(
                        scale: scale,
                        child: SizedBox(
                          width: 150,
                          height: 150,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              // Canlı blob yalnız bu adım aktifken mount
                              // edilir (shader boşuna çalışmasın —
                              // _breathController.stop() deseniyle uyumlu);
                              // diğer adımlarda eski statik daire yer tutar,
                              // sayfa geçiş animasyonunda görünüm bozulmaz.
                              if (_step == _stepBreathing)
                                const MeshBlob(
                                  size: 150,
                                  colors: _sosMeshColors,
                                )
                              else
                                Container(
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: AppColors.sosContainer,
                                  ),
                                ),
                              Text(
                                '$remaining',
                                style: const TextStyle(
                                  fontSize: 44,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.sosDark,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),
                Text(
                  done
                      ? l10n.emBreathDone
                      : (inhaling ? l10n.emBreathInhale : l10n.emBreathExhale),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppColors.sosDark,
                  ),
                ),
              ],
            );
          },
        ),
      ),
      bottom: [
        ElevatedButton(
          style: _primaryStyle,
          onPressed: done ? () => _goToStep(_stepWater) : null,
          child: Text(l10n.commonNext),
        ),
        if (!done)
          TextButton(
            onPressed: () => _goToStep(_stepWater),
            child: Text(
              l10n.commonSkip,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          ),
      ],
    );
  }

  // ------------------------------------------------------------- adım: su

  String get _waterTimeLabel {
    final m = (_waterSecondsLeft ~/ 60).toString();
    final s = (_waterSecondsLeft % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  Widget _buildWaterStep(AppLocalizations l10n) {
    return _stepBody(
      title: l10n.emWaterTitle,
      subtitle: l10n.emWaterSubtitle,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.water_drop, size: 96, color: Colors.blue.shade400),
            const SizedBox(height: 32),
            if (_waterTimerRunning)
              Text(
                _waterTimeLabel,
                style: const TextStyle(
                  fontSize: 56,
                  fontWeight: FontWeight.bold,
                  color: AppColors.sosDark,
                ),
              )
            else if (_waterTimerDone)
              Text(
                l10n.emWaterTimerDone,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: AppColors.sosDark,
                ),
              )
            else
              OutlinedButton.icon(
                onPressed: _startWaterTimer,
                icon: const Icon(Icons.timer),
                label: Text(l10n.emWaterStartTimer),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.sos,
                  side: const BorderSide(color: AppColors.sos),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                ),
              ),
          ],
        ),
      ),
      bottom: [
        ElevatedButton(
          style: _primaryStyle,
          onPressed: () => _goToStep(_stepAlternatives),
          child: Text(_waterTimerDone ? l10n.commonNext : l10n.commonSkip),
        ),
      ],
    );
  }

  // -------------------------------------------------- adım: alternatifler

  Widget _buildAlternativesStep(AppLocalizations l10n) {
    return _stepBody(
      title: l10n.emAlternativesTitle,
      subtitle: l10n.emAlternativesSubtitle,
      child: ListView(
        children: [
          for (final text in _alternativesFor(l10n, _selectedTrigger))
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(18),
                boxShadow: _softShadow,
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.sosSoft,
                    ),
                    child: const Icon(
                      Icons.lightbulb_outline,
                      color: AppColors.sos,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      text,
                      style: const TextStyle(
                        fontSize: 15,
                        height: 1.4,
                        color: AppColors.text,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
      bottom: [
        ElevatedButton(
          style: _primaryStyle,
          onPressed: () => _goToStep(_stepClosing),
          child: Text(l10n.commonNext),
        ),
      ],
    );
  }

  // ------------------------------------------------------ adım: kapanış

  Widget _buildClosingStep(AppLocalizations l10n) {
    return _stepBody(
      title: l10n.emClosingTitle,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.favorite, size: 72, color: AppColors.sos),
            const SizedBox(height: 28),
            Text(
              l10n.emClosingBody,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 17,
                height: 1.5,
                color: AppColors.text,
              ),
            ),
          ],
        ),
      ),
      bottom: [
        ElevatedButton(
          style: _primaryStyle,
          onPressed: () => _goToStep(_stepOutcome),
          child: Text(l10n.commonNext),
        ),
      ],
    );
  }

  // -------------------------------------------------------- adım: sonuç

  Widget _buildOutcomeStep(AppLocalizations l10n) {
    return _stepBody(
      title: l10n.emOutcomeTitle,
      subtitle: l10n.emOutcomeSubtitle,
      child: Center(
        child: _isSaving
            ? const CircularProgressIndicator(color: AppColors.sos)
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _EmSelectCard(
                    icon: Icons.emoji_events_outlined,
                    label: l10n.emOutcomeOvercame,
                    selected: false,
                    onTap: () => _saveOutcome('overcame'),
                  ),
                  _EmSelectCard(
                    icon: Icons.self_improvement,
                    label: l10n.emOutcomeAteAnyway,
                    selected: false,
                    onTap: () => _saveOutcome('ate_anyway'),
                  ),
                ],
              ),
      ),
    );
  }

  // -------------------------------------------------------- teşekkür ekranı

  Widget _buildThanksStep(AppLocalizations l10n) {
    return _stepBody(
      title: l10n.emThanksTitle,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle, size: 96, color: AppColors.primary),
            const SizedBox(height: 28),
            Text(
              l10n.emThanksBody,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 17,
                height: 1.5,
                color: AppColors.text,
              ),
            ),
          ],
        ),
      ),
      bottom: [
        ElevatedButton(
          style: _primaryStyle,
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.commonClose),
        ),
      ],
    );
  }
}

/// Giriş sahnesi: koyu kırmızı zemin üstünde büyük sos blob'u + iki satır
/// typewriter (onboarding girişinin kriz-modu aynası). Kullanıcı kriz
/// anında — BEKLETME yok: 45ms/harf, iki satır bitince ~1,5 sn sonra
/// otomatik ilerler; dokunma her an atlar (önce yazıyı tamamlar, sonra
/// geçer). Buton yok.
class _EmIntroSequence extends StatefulWidget {
  const _EmIntroSequence({required this.onDone});

  /// Tetikleyici adımına geçiş (otomatik veya dokunmayla; bir kez çağrılır).
  final VoidCallback onDone;

  @override
  State<_EmIntroSequence> createState() => _EmIntroSequenceState();
}

class _EmIntroSequenceState extends State<_EmIntroSequence> {
  static const Duration _charInterval = Duration(milliseconds: 45);

  /// İlk satır bitince ikinci satıra geçmeden kısa nefes.
  static const Duration _linePause = Duration(milliseconds: 300);

  /// İki satır da tamamlandıktan sonra otomatik ilerleme gecikmesi.
  static const Duration _autoAdvanceDelay = Duration(milliseconds: 1500);

  static const TextStyle _line1Style = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.w800,
    height: 1.2,
    color: AppColors.textOnDark,
  );

  /// İkinci satır hafif soluk — hiyerarşi (koyu kırmızı zeminde yeşilimsi
  /// textOnDarkSecondary yerine ana rengin düşük opaklığı).
  static final TextStyle _line2Style = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    height: 1.4,
    color: AppColors.textOnDark.withValues(alpha: 0.88),
  );

  /// l10n'den bir kez okunan 2 satır (didChangeDependencies'te dolar).
  List<String>? _lines;
  int _line = 0;
  int _shownChars = 0;
  bool _done = false;

  Timer? _typeTimer;
  Timer? _autoTimer;

  bool get _allTyped =>
      _lines != null && _line == 1 && _shownChars >= _lines![1].length;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_lines == null) {
      final l10n = AppLocalizations.of(context)!;
      _lines = [l10n.emIntroLine1, l10n.emIntroLine2];
      _typeLine();
    }
  }

  @override
  void dispose() {
    _typeTimer?.cancel();
    _autoTimer?.cancel();
    super.dispose();
  }

  void _typeLine() {
    _typeTimer?.cancel();
    _typeTimer = Timer.periodic(_charInterval, (timer) {
      final full = _lines![_line];
      if (_shownChars < full.length) {
        setState(() => _shownChars++);
        if (_shownChars < full.length) return;
      }
      // Satır bitti: ya kısa duraksayıp 2. satır, ya otomatik ilerleme.
      timer.cancel();
      if (_line == 0) {
        _typeTimer = Timer(_linePause, () {
          setState(() {
            _line = 1;
            _shownChars = 0;
          });
          _typeLine();
        });
      } else {
        _scheduleAdvance();
      }
    });
  }

  void _scheduleAdvance() {
    _autoTimer ??= Timer(_autoAdvanceDelay, _finish);
  }

  void _finish() {
    if (_done) return;
    _done = true;
    widget.onDone();
  }

  void _handleTap() {
    if (_lines == null || _done) return;
    if (!_allTyped) {
      // İlk dokunuş: iki satırı da anında tamamla (kriz anı, bekletme yok).
      _typeTimer?.cancel();
      setState(() {
        _line = 1;
        _shownChars = _lines![1].length;
      });
      _scheduleAdvance();
    } else {
      _autoTimer?.cancel();
      _finish();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_lines == null) return const SizedBox.shrink();

    final line1Full = _lines![0];
    final line2Full = _lines![1];
    final line1Typed = _line > 0
        ? line1Full
        : line1Full.substring(0, _shownChars.clamp(0, line1Full.length));
    final line2Typed = _line > 0
        ? line2Full.substring(0, _shownChars.clamp(0, line2Full.length))
        : '';

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _handleTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Spacer(flex: 3),
            // Kriz modundaki "aynı varlık": onboarding girişindeki büyük
            // blob kompozisyonu, sos renkleriyle. IgnorePointer: dokunmaları
            // yutmaz, ekranın her yeri dokunulabilir kalır.
            const IgnorePointer(
              child: MeshBlob(
                size: 130,
                colors: _sosMeshColors,
                breathe: true,
              ),
            ),
            const SizedBox(height: 36),
            _typedLine(full: line1Full, typed: line1Typed, style: _line1Style),
            const SizedBox(height: 14),
            _typedLine(full: line2Full, typed: line2Typed, style: _line2Style),
            const Spacer(flex: 5),
          ],
        ),
      ),
    );
  }

  /// Görünmez tam metin yer tutar: yazı aktıkça layout zıplamaz, görünen
  /// kısmi yazı blok İÇİNDE soldan akar (onboarding girişindeki teknik).
  Widget _typedLine({
    required String full,
    required String typed,
    required TextStyle style,
  }) {
    return Stack(
      children: [
        Opacity(opacity: 0, child: Text(full, style: style)),
        Text(typed, style: style),
      ],
    );
  }
}

/// Seçim kartı (onboarding `OnbSelectCard`'ın sos versiyonu): kenarlıksız
/// beyaz kart + hafif gölge, seçilide sosContainer dolgu; başta opsiyonel
/// ikon dairesi (sosSoft zemin + sos ikon).
class _EmSelectCard extends StatelessWidget {
  const _EmSelectCard({
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(18);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: selected ? AppColors.sosContainer : AppColors.surface,
        borderRadius: radius,
        boxShadow: selected ? null : _softShadow,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: radius,
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            child: Row(
              children: [
                if (icon != null) ...[
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: selected ? AppColors.surface : AppColors.sosSoft,
                    ),
                    child: Icon(icon, color: AppColors.sos, size: 24),
                  ),
                  const SizedBox(width: 14),
                ],
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: selected ? AppColors.sosDark : AppColors.text,
                    ),
                  ),
                ),
                if (selected)
                  const Icon(
                    Icons.check_circle_rounded,
                    size: 20,
                    color: AppColors.sosDark,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
