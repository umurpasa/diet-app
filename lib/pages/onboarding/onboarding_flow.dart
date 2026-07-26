import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../config/app_theme.dart';
import '../../l10n/app_localizations.dart';
import '../../utils/error_messages.dart';
import 'onboarding_data.dart';
import 'onboarding_intro.dart';
import 'onboarding_steps.dart';
import 'onboarding_widgets.dart';

/// Kayıt/giriş sonrası diyetisyen ilk görüşmesini simüle eden onboarding
/// akışı (docs/BACKLOG.md F madde 2). 9 sayfa: 0-karanlık giriş sekansı
/// (F-5b: mesh + typewriter, 3 alt-ekran) + 8 adım. Sayfa numaralandırması
/// ve `onboarding_step` semantiği değişmedi.
///
/// Kısmi kayıt: her adımın "Devam et"inde o adımın verisi `health_profiles`'a
/// upsert edilir ve `preferences.onboarding_step` güncellenir; X ile çıkışta
/// veri durur, sonraki girişte kaldığı adımdan devam edilir (AuthGate karar
/// verir, bkz. main.dart `OnboardingGate`).
class OnboardingFlow extends StatefulWidget {
  const OnboardingFlow({
    super.key,
    required this.data,
    required this.preferences,
    this.initialPage = 0,
    required this.onCompleted,
    required this.onExit,
  });

  /// Kısmi kayıttan geri yüklenmiş (veya boş) cevaplar.
  final OnboardingData data;

  /// Sunucudaki mevcut `preferences` jsonb — akış bunun üzerine yazar ki
  /// bu akışın bilmediği anahtarlar kaybolmasın.
  final Map<String, dynamic> preferences;

  /// Devam edilen sayfa (0 = hoş geldin).
  final int initialPage;

  /// Akış bitti: ana ekrana geç. F-6'dan beri ilk sekme = Diyet Planı;
  /// özetteki iki buton da 0 gönderir (buton ayrımı yalnız spinner için).
  final void Function(int homeTabIndex) onCompleted;

  /// X ile çıkış: bu oturumda ana ekrana geç, akış sonraki girişte sürer.
  final VoidCallback onExit;

  @override
  State<OnboardingFlow> createState() => _OnboardingFlowState();
}

class _OnboardingFlowState extends State<OnboardingFlow> {
  static const int _totalSteps = 8; // hoş geldin hariç (1..8)

  final _supabase = Supabase.instance.client;
  late final PageController _pageController;
  late final OnboardingData _data;
  late int _page;

  bool _saving = false;

  /// Özet ekranında basılan bitirme butonu (0 = Başlayalım, 1 = İlk planım).
  int? _finishingTab;

  /// Tam ekran giriş mesh'i ağaçta mı? Sayfa 0'dan çıkınca fade-out biter
  /// bitmez kaldırılır (shader boşuna çalışmasın). Kısmi kayıtla dönen
  /// kullanıcı (`initialPage > 0`) girişi hiç görmez.
  late bool _introMeshMounted = widget.initialPage == 0;

  late final TextEditingController _nameController;
  late final TextEditingController _ageController;
  late final TextEditingController _heightController;
  late final TextEditingController _weightController;
  late final TextEditingController _waistController;
  late final TextEditingController _hipController;
  late final TextEditingController _targetWeightController;
  late final TextEditingController _conditionsOtherController;
  late final TextEditingController _medicationsController;
  late final TextEditingController _allergiesOtherController;
  late final TextEditingController _dislikedController;

  List<TextEditingController> get _allControllers => [
        _nameController,
        _ageController,
        _heightController,
        _weightController,
        _waistController,
        _hipController,
        _targetWeightController,
        _conditionsOtherController,
        _medicationsController,
        _allergiesOtherController,
        _dislikedController,
      ];

  static String _fmtNum(num? v) {
    if (v == null) return '';
    return v % 1 == 0 ? v.toInt().toString() : v.toString();
  }

  @override
  void initState() {
    super.initState();
    _data = widget.data;
    _page = widget.initialPage;
    _pageController = PageController(initialPage: widget.initialPage);

    _nameController = TextEditingController(text: _data.name);
    _ageController = TextEditingController(text: _data.age?.toString() ?? '');
    _heightController = TextEditingController(text: _fmtNum(_data.heightCm));
    _weightController = TextEditingController(text: _fmtNum(_data.weightKg));
    _waistController = TextEditingController(text: _fmtNum(_data.waistCm));
    _hipController = TextEditingController(text: _fmtNum(_data.hipCm));
    _targetWeightController =
        TextEditingController(text: _fmtNum(_data.targetWeightKg));
    _conditionsOtherController =
        TextEditingController(text: _data.conditionsOther);
    _medicationsController = TextEditingController(text: _data.medications);
    _allergiesOtherController =
        TextEditingController(text: _data.allergiesOther);
    _dislikedController = TextEditingController(text: _data.dislikedFoods);

    // Yazıldıkça İleri butonunun aktifliği güncellensin.
    for (final c in _allControllers) {
      c.addListener(_onFieldChanged);
    }

    // Kısmi kayıttan devam ediliyorsa kısa bir "kaldığın yerden" hissi.
    if (widget.initialPage > 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.onbResumeToast),
            behavior: SnackBarBehavior.floating,
          ),
        );
      });
    }
  }

  @override
  void dispose() {
    for (final c in _allControllers) {
      c.dispose();
    }
    _pageController.dispose();
    super.dispose();
  }

  void _onFieldChanged() => setState(() {});

  // ---- Parse yardımcıları (profile_page ile aynı: virgül→nokta) ----

  num? _num(TextEditingController c) =>
      num.tryParse(c.text.trim().replaceAll(',', '.'));

  /// Alan geçerli mi: boşsa yalnızca opsiyonelse, doluysa pozitif sayıysa.
  bool _numOk(TextEditingController c, {required bool required}) {
    final t = c.text.trim();
    if (t.isEmpty) return !required;
    final v = num.tryParse(t.replaceAll(',', '.'));
    return v != null && v > 0;
  }

  /// Controller'lardaki serbest metin/sayı değerlerini modele yazar.
  void _syncControllers() {
    _data
      ..name = _nameController.text.trim()
      ..age = int.tryParse(_ageController.text.trim())
      ..heightCm = _num(_heightController)
      ..weightKg = _num(_weightController)
      ..waistCm = _num(_waistController)
      ..hipCm = _num(_hipController)
      ..targetWeightKg = _num(_targetWeightController)
      ..conditionsOther = _conditionsOtherController.text.trim()
      ..medications = _medicationsController.text.trim()
      ..allergiesOther = _allergiesOtherController.text.trim()
      ..dislikedFoods = _dislikedController.text.trim();
  }

  /// Bulunulan adımın zorunlu alanları tamam mı ("Devam et" aktifliği)?
  bool get _canProceed {
    switch (_page) {
      case 1:
        return _nameController.text.trim().isNotEmpty &&
            (int.tryParse(_ageController.text.trim()) ?? 0) > 0 &&
            _data.sex != null;
      case 2:
        return _numOk(_heightController, required: true) &&
            _numOk(_weightController, required: true) &&
            _numOk(_waistController, required: false) &&
            _numOk(_hipController, required: false);
      case 3:
        if (_data.goalType == null) return false;
        if (_data.goalNeedsDetails) {
          if (_data.pace == null) return false;
          if (!_numOk(_targetWeightController, required: false)) return false;
        }
        return true;
      case 4:
        // Alerji adımı "yok" ya da en az bir seçim olmadan geçilemez
        // (güvenlik — AI planı için kritik). Kronik durumlar da aynı.
        if (_data.conditions.isEmpty || _data.allergies.isEmpty) return false;
        if (_data.conditions.contains('other') &&
            _conditionsOtherController.text.trim().isEmpty) {
          return false;
        }
        if (_data.allergies.contains('other') &&
            _allergiesOtherController.text.trim().isEmpty) {
          return false;
        }
        return true;
      case 5:
        return _data.activityLevel != null && _data.waterGlasses != null;
      case 6:
        return _data.mealsPerDay != null &&
            _data.skipsBreakfast != null &&
            _data.eatingOut != null &&
            _data.weakMoments.isNotEmpty;
      case 7:
        return _data.dietStyle != null;
      default:
        return true;
    }
  }

  // ---- Kayıt ----

  void _showError(String text) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(text),
        backgroundColor: AppColors.sos,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// Bel/kalça girildiyse bugünün `progress` satırına yazar
  /// (progress_page ile aynı desen: aynı güne satır varsa update).
  Future<void> _saveMeasurements(String userId) async {
    _syncControllers();
    final waist = _data.waistCm;
    final hip = _data.hipCm;
    if (waist == null && hip == null) return;

    final now = DateTime.now();
    final dateStr = '${now.year}-'
        '${now.month.toString().padLeft(2, '0')}-'
        '${now.day.toString().padLeft(2, '0')}';

    final existing = await _supabase
        .from('progress')
        .select('id, measurements')
        .eq('user_id', userId)
        .eq('log_date', dateStr)
        .order('created_at', ascending: false)
        .limit(1)
        .maybeSingle();

    final measurements = Map<String, dynamic>.from(
        existing?['measurements'] as Map? ?? const {});
    if (waist != null) measurements['waist_cm'] = waist;
    if (hip != null) measurements['hip_cm'] = hip;

    if (existing != null) {
      await _supabase.from('progress').update(
          {'measurements': measurements}).eq('id', existing['id'] as String);
    } else {
      await _supabase.from('progress').insert({
        'user_id': userId,
        'log_date': dateStr,
        'measurements': measurements,
      });
    }
  }

  /// Adımın verisini upsert eder; başarıda true. Hata SnackBar ile gösterilir
  /// ve kullanıcı aynı adımda kalır (tekrar deneyebilir).
  Future<bool> _saveStep(int step) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      _showError(AppLocalizations.of(context)!.onbSessionLost);
      return false;
    }
    _syncControllers();

    try {
      if (step == 1) {
        await _supabase
            .from('profiles')
            .update({'full_name': _data.name}).eq('id', userId);
      }

      final payload = <String, dynamic>{
        'user_id': userId,
        'updated_at': DateTime.now().toIso8601String(),
      };
      if (step == 1) {
        payload['age'] = _data.age;
      } else if (step == 2) {
        payload['height_cm'] = _data.heightCm;
        payload['weight_kg'] = _data.weightKg;
      } else if (step == 3) {
        payload['goal'] = _data.goalSummaryTr();
      } else if (step == 4) {
        payload['health_history'] = _data.healthSummaryTr();
        payload['allergies'] = _data.allergySummaryTr();
      }

      _data.applyToPreferences(widget.preferences);
      // Geri dönüp erken bir adımı yeniden kaydetmek ilerlemeyi geriletmesin.
      final prev = widget.preferences['onboarding_step'];
      widget.preferences['onboarding_step'] =
          (prev is int && prev > step) ? prev : step;
      payload['preferences'] = widget.preferences;

      await _supabase.from('health_profiles').upsert(payload);

      if (step == 2) await _saveMeasurements(userId);
      return true;
    } on PostgrestException catch (e) {
      if (mounted) {
        _showError(AppLocalizations.of(context)!.onbSaveFailed(e.message));
      }
      return false;
    } catch (e) {
      if (mounted) _showError(friendlyErrorMessage(e));
      return false;
    }
  }

  // ---- Gezinme ----

  void _goTo(int page) {
    setState(() => _page = page);
    _pageController.animateToPage(
      page,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOutCubic,
    );
  }

  Future<void> _next() async {
    if (_saving) return;
    if (_page == 0) {
      _goTo(1);
      return;
    }
    if (!_canProceed) return;

    setState(() => _saving = true);
    final ok = await _saveStep(_page);
    if (!mounted) return;
    setState(() => _saving = false);
    if (ok && _page < _totalSteps) _goTo(_page + 1);
  }

  Future<void> _finish(int button) async {
    if (_finishingTab != null) return;
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      _showError(AppLocalizations.of(context)!.onbSessionLost);
      return;
    }

    setState(() => _finishingTab = button);
    try {
      widget.preferences['onboarding_completed'] = true;
      widget.preferences['onboarding_step'] = _totalSteps;
      await _supabase.from('health_profiles').upsert({
        'user_id': userId,
        'preferences': widget.preferences,
        'updated_at': DateTime.now().toIso8601String(),
      });
      // Profil sekmesi kalktı (F-6): iki bitirme butonu da ilk sekmeye
      // (Diyet Planı, index 0) çıkar; homeTab yalnız spinner ayrımı.
      if (mounted) widget.onCompleted(0);
    } on PostgrestException catch (e) {
      if (mounted) {
        _showError(AppLocalizations.of(context)!.onbSaveFailed(e.message));
        setState(() => _finishingTab = null);
      }
    } catch (e) {
      if (mounted) {
        _showError(friendlyErrorMessage(e));
        setState(() => _finishingTab = null);
      }
    }
  }

  // ---- UI ----

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final busy = _saving || _finishingTab != null;
    final darkStage = _page == 0;

    // Karanlık girişte status bar ikonları açık renk, adımlarda normale döner.
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: darkStage ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Scaffold(
        // Karanlık→açık geçiş: zemin PageView animasyonuyla aynı sürede
        // yumuşar (Scaffold rengi animate edilemediği için body'de).
        body: AnimatedContainer(
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOutCubic,
          color: darkStage ? AppColors.darkStage : AppColors.background,
          child: Stack(
            children: [
              // Tam ekran giriş mesh'i — içeriğin arkasında, status bar
              // dahil. 3 alt-ekran boyunca kesintisiz; sayfa 0'dan çıkınca
              // fade-out edip ağaçtan kalkar.
              if (_introMeshMounted)
                Positioned.fill(
                  child: AnimatedOpacity(
                    opacity: darkStage ? 1 : 0,
                    duration: const Duration(milliseconds: 400),
                    onEnd: () {
                      if (_page != 0 && mounted) {
                        setState(() => _introMeshMounted = false);
                      }
                    },
                    child: const OnbIntroMesh(),
                  ),
                ),
              SafeArea(
                child: Column(
                  children: [
                    // Üst bar: geri ok · orb · ilerleme çubuğu · X (AppBar yok).
                    Padding(
                      padding: const EdgeInsets.fromLTRB(8, 4, 8, 0),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 48,
                            height: 48,
                            // Adım 1'in gerisi giriş sekansı — form değil,
                            // oraya geri dönüş yok (ok yalnız adım 2+).
                            child: _page > 1
                                ? IconButton(
                                    icon: const Icon(Icons.arrow_back,
                                        color: AppColors.text),
                                    tooltip: l10n.onbBackTooltip,
                                    onPressed:
                                        busy ? null : () => _goTo(_page - 1),
                                  )
                                : null,
                          ),
                          // Yaşayan orb: soruları soran "canlı varlık".
                          // Girişte gizli (orada tam ekran mesh var), adım
                          // 1-8'de sabit; özette büyür. Tek instance.
                          if (_page >= 1) ...[
                            OnbOrb(emphasized: _page == _totalSteps),
                            const SizedBox(width: 4),
                          ],
                          Expanded(
                            child: _page >= 1
                                ? Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8),
                                    child: LinearProgressIndicator(
                                      value: _page / _totalSteps,
                                      minHeight: 6,
                                      color: AppColors.primary,
                                      backgroundColor: AppColors
                                          .primaryContainer
                                          .withValues(alpha: 0.45),
                                      borderRadius: BorderRadius.circular(3),
                                    ),
                                  )
                                : const SizedBox.shrink(),
                          ),
                          IconButton(
                            icon: Icon(
                              Icons.close,
                              color: darkStage
                                  ? AppColors.textOnDark
                                  : AppColors.text,
                            ),
                            tooltip: l10n.onbExitTooltip,
                            onPressed: busy ? null : widget.onExit,
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: PageView(
                        controller: _pageController,
                        physics: const NeverScrollableScrollPhysics(),
                        children: [
                          OnbIntroSequence(onStart: _next),
                          _wrapStep(
                              1,
                              OnbIdentityContent(
                                data: _data,
                                nameController: _nameController,
                                ageController: _ageController,
                                onChanged: _onFieldChanged,
                              )),
                          _wrapStep(
                              2,
                              OnbBodyContent(
                                heightController: _heightController,
                                weightController: _weightController,
                                waistController: _waistController,
                                hipController: _hipController,
                              )),
                          _wrapStep(
                              3,
                              OnbGoalContent(
                                data: _data,
                                targetWeightController: _targetWeightController,
                                onChanged: _onFieldChanged,
                              )),
                          _wrapStep(
                              4,
                              OnbHealthContent(
                                data: _data,
                                conditionsOtherController:
                                    _conditionsOtherController,
                                medicationsController: _medicationsController,
                                allergiesOtherController:
                                    _allergiesOtherController,
                                onChanged: _onFieldChanged,
                              )),
                          _wrapStep(
                              5,
                              OnbLifestyleContent(
                                data: _data,
                                onChanged: _onFieldChanged,
                              )),
                          _wrapStep(
                              6,
                              OnbHabitsContent(
                                data: _data,
                                onChanged: _onFieldChanged,
                              )),
                          _wrapStep(
                              7,
                              OnbPrefsContent(
                                data: _data,
                                dislikedController: _dislikedController,
                                onChanged: _onFieldChanged,
                              )),
                          _wrapStep(8, OnbSummaryContent(data: _data)),
                        ],
                      ),
                    ),
                    // Girişte alt buton alanı yok — ipucu/buton sekansın
                    // kendi içinde (OnbIntroSequence).
                    if (_page > 0)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                        child: _buildBottomButtons(l10n),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _wrapStep(int step, Widget content) {
    final l10n = AppLocalizations.of(context)!;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.onbStepCounter(step),
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.3,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 10),
          content,
        ],
      ),
    );
  }

  Widget _buildBottomButtons(AppLocalizations l10n) {
    if (_page < _totalSteps) {
      return OnbPrimaryButton(
        label: l10n.onbNext,
        loading: _saving,
        onPressed: _canProceed && !_saving ? _next : null,
      );
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        OnbPrimaryButton(
          label: l10n.onbSummaryStart,
          loading: _finishingTab == 0,
          onPressed: _finishingTab == null ? () => _finish(0) : null,
        ),
        const SizedBox(height: 12),
        OnbSecondaryButton(
          label: l10n.onbSummaryCreatePlan,
          loading: _finishingTab == 1,
          // Plan sayfası plan yoksa üretim akışını zaten gösteriyor,
          // burada tetiklenmez.
          onPressed: _finishingTab == null ? () => _finish(1) : null,
        ),
      ],
    );
  }
}
