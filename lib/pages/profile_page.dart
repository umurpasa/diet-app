import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/app_theme.dart';
import '../config/locale_controller.dart';
import '../l10n/app_localizations.dart';
import '../utils/error_messages.dart';
import '../widgets/page_header.dart';
import 'onboarding/onboarding_data.dart';
import 'onboarding/onboarding_steps.dart';
import 'onboarding/onboarding_widgets.dart';

/// Profil + hesap sayfası (docs/BACKLOG.md F madde 3).
///
/// Onboarding'in doldurduğu TÜM veriyi bölüm kartları halinde gösterir;
/// her kart modal bottom sheet ile düzenlenir. Sheet içerikleri onboarding
/// adım widget'larını (`Onb*Content`) ve [OnboardingData]'yı yeniden
/// kullanır; kaydetme onboarding ile aynı mantıktır (sayısal kolonlar +
/// `applyToPreferences` + TR özet kolonları) — AI bağlamı tutarlı kalır.
/// Hesap bölümü: e-posta (salt okunur), şifre değiştirme, dil (TR/EN),
/// çıkış. Bel/kalça burada düzenlenmez (İlerleme sayfasının işi olacak).
class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

/// Düzenlenebilir veri bölümleri (onboarding adımlarıyla aynı gruplar).
enum _Section { identity, body, goal, health, lifestyle, habits, prefs }

/// Sheet'ten başarıyla dönen sonuç: güncel cevaplar + preferences jsonb.
class _EditResult {
  const _EditResult(this.data, this.preferences);
  final OnboardingData data;
  final Map<String, dynamic> preferences;
}

class _ProfilePageState extends State<ProfilePage> {
  final _supabase = Supabase.instance.client;

  bool _loading = true;
  OnboardingData _data = OnboardingData();
  Map<String, dynamic> _preferences = {};

  String get _email => _supabase.auth.currentUser?.email ?? '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  static String _fmtNum(num v) =>
      v % 1 == 0 ? v.toInt().toString() : v.toString();

  Future<void> _load() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      setState(() => _loading = false);
      return;
    }

    try {
      final row = await _supabase
          .from('health_profiles')
          .select('age, height_cm, weight_kg, preferences')
          .eq('user_id', userId)
          .maybeSingle();
      final profile = await _supabase
          .from('profiles')
          .select('full_name')
          .eq('id', userId)
          .maybeSingle();

      final prefs =
          Map<String, dynamic>.from(row?['preferences'] as Map? ?? const {});

      if (mounted) {
        setState(() {
          _data = OnboardingData.restore(
            preferences: prefs,
            row: row,
            fullName: profile?['full_name'] as String?,
          );
          _preferences = prefs;
        });
      }
    } on PostgrestException catch (e) {
      if (mounted) {
        _showMessage(
          AppLocalizations.of(context)!.profLoadFailed(e.message),
          isError: true,
        );
      }
    } catch (e) {
      if (mounted) _showMessage(friendlyErrorMessage(e), isError: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showMessage(String text, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(text),
        backgroundColor: isError ? AppColors.sos : AppColors.primary,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ---- Düzenleme sheet'leri ----

  Future<void> _editSection(_Section section) async {
    final result = await showModalBottomSheet<_EditResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => _SectionEditSheet(
        section: section,
        data: _data.clone(),
        preferences: _preferences,
      ),
    );
    if (result != null && mounted) {
      setState(() {
        _data = result.data;
        _preferences = result.preferences;
      });
      _showMessage(AppLocalizations.of(context)!.profSaved);
    }
  }

  Future<void> _changePassword() async {
    final changed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => const _PasswordSheet(),
    );
    if (changed == true && mounted) {
      _showMessage(AppLocalizations.of(context)!.profPasswordChanged);
    }
  }

  Future<void> _confirmSignOut() async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.profSignOut),
        content: Text(l10n.profSignOutConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.commonCancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.profSignOut),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await _supabase.auth.signOut();
    }
  }

  // ---- Bölüm özetleri (onboarding l10n etiketleriyle) ----

  String _join(Iterable<String?> parts) =>
      parts.whereType<String>().where((s) => s.isNotEmpty).join(' · ');

  String _orNotFilled(AppLocalizations l10n, String s) =>
      s.isEmpty ? l10n.profNotFilled : s;

  String _identitySummary(AppLocalizations l10n) {
    final sexLabels = {
      'female': l10n.onbSexFemale,
      'male': l10n.onbSexMale,
      'unspecified': l10n.onbSexUnspecified,
    };
    return _orNotFilled(
        l10n,
        _join([
          _data.name.isEmpty ? null : _data.name,
          _data.age == null ? null : l10n.profAgeValue(_data.age!),
          _data.sex == null ? null : sexLabels[_data.sex],
        ]));
  }

  String _bodySummary(AppLocalizations l10n) {
    return _orNotFilled(
        l10n,
        _join([
          _data.heightCm == null ? null : '${_fmtNum(_data.heightCm!)} cm',
          _data.weightKg == null ? null : '${_fmtNum(_data.weightKg!)} kg',
        ]));
  }

  String _goalSummary(AppLocalizations l10n) {
    final goalLabels = {
      'lose': l10n.onbGoalLose,
      'gain': l10n.onbGoalGain,
      'maintain': l10n.onbGoalMaintain,
      'healthy': l10n.onbGoalHealthy,
    };
    final paceLabels = {
      'slow': l10n.onbPaceSlow,
      'balanced': l10n.onbPaceBalanced,
      'fast': l10n.onbPaceFast,
    };
    return _orNotFilled(
        l10n,
        _join([
          _data.goalType == null ? null : goalLabels[_data.goalType],
          !_data.goalNeedsDetails || _data.targetWeightKg == null
              ? null
              : '${_fmtNum(_data.targetWeightKg!)} kg',
          !_data.goalNeedsDetails || _data.pace == null
              ? null
              : paceLabels[_data.pace],
        ]));
  }

  String _healthSummary(AppLocalizations l10n) {
    final conditionLabels = {
      'diabetes': l10n.onbConditionDiabetes,
      'insulin_resistance': l10n.onbConditionInsulinResistance,
      'hypertension': l10n.onbConditionHypertension,
      'thyroid': l10n.onbConditionThyroid,
      'cholesterol': l10n.onbConditionCholesterol,
    };
    final allergyLabels = {
      'gluten': l10n.onbAllergyGluten,
      'lactose': l10n.onbAllergyLactose,
      'nuts': l10n.onbAllergyNuts,
      'seafood': l10n.onbAllergySeafood,
      'egg': l10n.onbAllergyEgg,
    };

    String multi(
      Set<String> values,
      Map<String, String> labels,
      String otherText,
    ) {
      if (values.contains('none')) return l10n.onbOptionNone;
      final names = [
        for (final v in values)
          if (labels.containsKey(v)) labels[v]!,
        if (values.contains('other') && otherText.trim().isNotEmpty)
          otherText.trim(),
      ];
      return names.join(', ');
    }

    final conditions =
        multi(_data.conditions, conditionLabels, _data.conditionsOther);
    final allergies =
        multi(_data.allergies, allergyLabels, _data.allergiesOther);
    return _orNotFilled(
        l10n,
        _join([
          conditions.isEmpty
              ? null
              : '${l10n.profConditionsShort}: $conditions',
          allergies.isEmpty ? null : '${l10n.profAllergiesShort}: $allergies',
          _data.medications.trim().isEmpty
              ? null
              : '${l10n.profMedicationsShort}: ${_data.medications.trim()}',
        ]));
  }

  String _lifestyleSummary(AppLocalizations l10n) {
    final activityLabels = {
      'sedentary': l10n.onbActivitySedentary,
      'light': l10n.onbActivityLight,
      'moderate': l10n.onbActivityModerate,
      'active': l10n.onbActivityActive,
      'very_active': l10n.onbActivityVeryActive,
    };
    final sleepLabels = {
      '<5': l10n.onbSleepLt5,
      '5-6': l10n.onbSleep5to6,
      '7-8': l10n.onbSleep7to8,
      '8+': l10n.onbSleep8plus,
    };
    final habitLabels = {
      'none': l10n.onbOptionNone,
      'occasional': l10n.onbHabitOccasional,
      'regular': l10n.onbHabitRegular,
    };
    return _orNotFilled(
        l10n,
        _join([
          _data.activityLevel == null
              ? null
              : activityLabels[_data.activityLevel],
          _data.waterGlasses == null
              ? null
              : '${l10n.profWaterShort}: ${_data.waterGlasses}',
          _data.sleepHours == null
              ? null
              : '${l10n.profSleepShort}: ${sleepLabels[_data.sleepHours]}',
          _data.smoking == null
              ? null
              : '${l10n.profSmokingShort}: ${habitLabels[_data.smoking]}',
          _data.alcohol == null
              ? null
              : '${l10n.profAlcoholShort}: ${habitLabels[_data.alcohol]}',
        ]));
  }

  String _habitsSummary(AppLocalizations l10n) {
    final breakfastLabels = {
      'never': l10n.onbBreakfastNever,
      'sometimes': l10n.onbBreakfastSometimes,
      'often': l10n.onbBreakfastOften,
    };
    final eatingOutLabels = {
      'rarely': l10n.onbEatingOutRarely,
      '1-2_per_week': l10n.onbEatingOutWeekly12,
      '3+_per_week': l10n.onbEatingOutWeekly3plus,
      'daily': l10n.onbEatingOutDaily,
    };
    final weakLabels = {
      'night_snacking': l10n.onbWeakNightSnacking,
      'sweet_craving': l10n.onbWeakSweetCraving,
      'hunger_between_meals': l10n.onbWeakHungerBetweenMeals,
      'stress_eating': l10n.onbWeakStressEating,
    };
    final weak = _data.weakMoments.contains('none')
        ? l10n.onbOptionNone
        : [
            for (final w in _data.weakMoments)
              if (weakLabels.containsKey(w)) weakLabels[w]!,
          ].join(', ');
    return _orNotFilled(
        l10n,
        _join([
          _data.mealsPerDay == null
              ? null
              : '${l10n.profMealsShort}: ${_data.mealsPerDay}',
          _data.skipsBreakfast == null
              ? null
              : '${l10n.profBreakfastShort}: ${breakfastLabels[_data.skipsBreakfast]}',
          _data.eatingOut == null
              ? null
              : '${l10n.profEatingOutShort}: ${eatingOutLabels[_data.eatingOut]}',
          weak.isEmpty ? null : '${l10n.profWeakShort}: $weak',
        ]));
  }

  String _prefsSummary(AppLocalizations l10n) {
    final dietLabels = {
      'omnivore': l10n.onbDietOmnivore,
      'vegetarian': l10n.onbDietVegetarian,
      'vegan': l10n.onbDietVegan,
    };
    return _orNotFilled(
        l10n,
        _join([
          _data.dietStyle == null ? null : dietLabels[_data.dietStyle],
          _data.dislikedFoods.trim().isEmpty
              ? null
              : '${l10n.profDislikedShort}: ${_data.dislikedFoods.trim()}',
        ]));
  }

  // ---- UI ----

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // İnce üst satır: geri ok — sayfa artık sekme değil, başlık
            // avatarından push edilir (tasarım dili gereği AppBar yok).
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
            Expanded(child: _buildContent(l10n)),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(AppLocalizations l10n) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 96),
      children: [
        PageHeader(
          eyebrow: l10n.profileHeaderEyebrow,
          title: l10n.profTitle,
          // Profil sayfasının kendisi — sağ üst avatar anlamsız.
          showAvatar: false,
          padding: const EdgeInsets.only(bottom: 18),
        ),
        _buildHeader(),
        const SizedBox(height: 24),
        _sectionCard(
          title: l10n.profSectionIdentity,
          summary: _identitySummary(l10n),
          onTap: () => _editSection(_Section.identity),
        ),
        _sectionCard(
          title: l10n.profSectionBody,
          summary: _bodySummary(l10n),
          onTap: () => _editSection(_Section.body),
        ),
        _sectionCard(
          title: l10n.profSectionGoal,
          summary: _goalSummary(l10n),
          onTap: () => _editSection(_Section.goal),
        ),
        _sectionCard(
          title: l10n.profSectionHealth,
          summary: _healthSummary(l10n),
          onTap: () => _editSection(_Section.health),
        ),
        _sectionCard(
          title: l10n.profSectionLifestyle,
          summary: _lifestyleSummary(l10n),
          onTap: () => _editSection(_Section.lifestyle),
        ),
        _sectionCard(
          title: l10n.profSectionHabits,
          summary: _habitsSummary(l10n),
          onTap: () => _editSection(_Section.habits),
        ),
        _sectionCard(
          title: l10n.profSectionPrefs,
          summary: _prefsSummary(l10n),
          onTap: () => _editSection(_Section.prefs),
        ),
        const SizedBox(height: 12),
        _buildAccountCard(l10n),
      ],
    );
  }

  Widget _buildHeader() {
    final name = _data.name.trim();
    final initialSource = name.isNotEmpty ? name : _email;
    final initial =
        initialSource.isNotEmpty ? initialSource[0].toUpperCase() : '?';

    return Row(
      children: [
        CircleAvatar(
          radius: 28,
          backgroundColor: AppColors.primaryContainer,
          child: Text(
            initial,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: AppColors.onPrimaryContainer,
            ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (name.isNotEmpty)
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.text,
                  ),
                ),
              if (_email.isNotEmpty)
                Text(
                  _email,
                  style: const TextStyle(
                    fontSize: 13.5,
                    color: AppColors.textSecondary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _sectionCard({
    required String title,
    required String summary,
    required VoidCallback onTap,
  }) {
    final radius = BorderRadius.circular(20);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: radius,
        boxShadow: onbSoftShadow,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: radius,
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 15.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.text,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        summary,
                        style: const TextStyle(
                          fontSize: 14,
                          height: 1.4,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                const Icon(
                  Icons.edit_outlined,
                  size: 20,
                  color: AppColors.primary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAccountCard(AppLocalizations l10n) {
    final languageCode = Localizations.localeOf(context).languageCode;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: onbSoftShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 4),
            child: Text(
              l10n.profSectionAccount,
              style: const TextStyle(
                fontSize: 15.5,
                fontWeight: FontWeight.w700,
                color: AppColors.text,
              ),
            ),
          ),
          _accountRow(
            icon: Icons.mail_outline,
            label: l10n.profEmailLabel,
            value: _email,
          ),
          _accountRow(
            icon: Icons.lock_outline,
            label: l10n.profChangePassword,
            onTap: _changePassword,
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 6),
            child: Row(
              children: [
                const Icon(
                  Icons.language,
                  size: 21,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: 12),
                Text(
                  l10n.profLanguageLabel,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.text,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(51, 2, 18, 14),
            child: Wrap(
              spacing: 8,
              children: [
                OnbChip(
                  label: l10n.languageTurkish,
                  selected: languageCode == 'tr',
                  onTap: () => LocaleController.set(const Locale('tr')),
                ),
                OnbChip(
                  label: l10n.languageEnglish,
                  selected: languageCode == 'en',
                  onTap: () => LocaleController.set(const Locale('en')),
                ),
              ],
            ),
          ),
          _accountRow(
            icon: Icons.logout,
            label: l10n.profSignOut,
            color: AppColors.sos,
            onTap: _confirmSignOut,
          ),
          const SizedBox(height: 6),
        ],
      ),
    );
  }

  Widget _accountRow({
    required IconData icon,
    required String label,
    String? value,
    VoidCallback? onTap,
    Color? color,
  }) {
    final content = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      child: Row(
        children: [
          Icon(icon, size: 21, color: color ?? AppColors.textSecondary),
          const SizedBox(width: 12),
          Text(
            label,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: color ?? AppColors.text,
            ),
          ),
          const SizedBox(width: 12),
          if (value != null)
            Expanded(
              child: Text(
                value,
                textAlign: TextAlign.right,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
            )
          else
            const Spacer(),
          if (onTap != null)
            const Icon(
              Icons.chevron_right,
              size: 20,
              color: AppColors.textSecondary,
            ),
        ],
      ),
    );
    if (onTap == null) return content;
    return Material(
      color: Colors.transparent,
      child: InkWell(onTap: onTap, child: content),
    );
  }
}

// ---- Bölüm düzenleme sheet'i ----

/// Bir veri bölümünü düzenleten modal bottom sheet. Onboarding adım
/// içeriklerini aynen kullanır; zorunluluk kuralları da onboarding ile
/// birebir aynı (`_canSave` ↔ `OnboardingFlow._canProceed`). Kaydetme
/// başarılı olursa [_EditResult] ile kapanır; iptalde hiçbir şey değişmez
/// (klonlanmış veri üzerinde çalışır).
class _SectionEditSheet extends StatefulWidget {
  const _SectionEditSheet({
    required this.section,
    required this.data,
    required this.preferences,
  });

  final _Section section;

  /// Sayfadaki verinin klonu — sheet serbestçe değiştirir.
  final OnboardingData data;

  /// Sunucudaki güncel jsonb (salt okunur; kopyası üzerine yazılır).
  final Map<String, dynamic> preferences;

  @override
  State<_SectionEditSheet> createState() => _SectionEditSheetState();
}

class _SectionEditSheetState extends State<_SectionEditSheet> {
  final _supabase = Supabase.instance.client;

  bool _saving = false;
  final List<TextEditingController> _controllers = [];

  TextEditingController? _nameC;
  TextEditingController? _ageC;
  TextEditingController? _heightC;
  TextEditingController? _weightC;
  TextEditingController? _targetC;
  TextEditingController? _condOtherC;
  TextEditingController? _medsC;
  TextEditingController? _allergyOtherC;
  TextEditingController? _dislikedC;

  OnboardingData get _d => widget.data;

  static String _fmt(num? v) {
    if (v == null) return '';
    return v % 1 == 0 ? v.toInt().toString() : v.toString();
  }

  TextEditingController _c(String text) {
    final c = TextEditingController(text: text);
    c.addListener(_onChanged);
    _controllers.add(c);
    return c;
  }

  @override
  void initState() {
    super.initState();
    switch (widget.section) {
      case _Section.identity:
        _nameC = _c(_d.name);
        _ageC = _c(_d.age?.toString() ?? '');
        break;
      case _Section.body:
        _heightC = _c(_fmt(_d.heightCm));
        _weightC = _c(_fmt(_d.weightKg));
        break;
      case _Section.goal:
        _targetC = _c(_fmt(_d.targetWeightKg));
        break;
      case _Section.health:
        _condOtherC = _c(_d.conditionsOther);
        _medsC = _c(_d.medications);
        _allergyOtherC = _c(_d.allergiesOther);
        break;
      case _Section.prefs:
        _dislikedC = _c(_d.dislikedFoods);
        break;
      case _Section.lifestyle:
      case _Section.habits:
        break;
    }
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _onChanged() => setState(() {});

  // ---- Parse + validasyon (onboarding_flow ile aynı desen) ----

  num? _num(TextEditingController c) =>
      num.tryParse(c.text.trim().replaceAll(',', '.'));

  bool _numOk(TextEditingController c, {required bool required}) {
    final t = c.text.trim();
    if (t.isEmpty) return !required;
    final v = num.tryParse(t.replaceAll(',', '.'));
    return v != null && v > 0;
  }

  /// Controller'lardaki metin/sayı değerlerini modele yazar.
  void _sync() {
    switch (widget.section) {
      case _Section.identity:
        _d.name = _nameC!.text.trim();
        _d.age = int.tryParse(_ageC!.text.trim());
        break;
      case _Section.body:
        _d.heightCm = _num(_heightC!);
        _d.weightKg = _num(_weightC!);
        break;
      case _Section.goal:
        _d.targetWeightKg = _num(_targetC!);
        break;
      case _Section.health:
        _d.conditionsOther = _condOtherC!.text.trim();
        _d.medications = _medsC!.text.trim();
        _d.allergiesOther = _allergyOtherC!.text.trim();
        break;
      case _Section.prefs:
        _d.dislikedFoods = _dislikedC!.text.trim();
        break;
      case _Section.lifestyle:
      case _Section.habits:
        break;
    }
  }

  /// Zorunlu alanlar tamam mı? Kurallar onboarding ile birebir aynı.
  bool get _canSave {
    switch (widget.section) {
      case _Section.identity:
        return _nameC!.text.trim().isNotEmpty &&
            (int.tryParse(_ageC!.text.trim()) ?? 0) > 0 &&
            _d.sex != null;
      case _Section.body:
        return _numOk(_heightC!, required: true) &&
            _numOk(_weightC!, required: true);
      case _Section.goal:
        if (_d.goalType == null) return false;
        if (_d.goalNeedsDetails) {
          if (_d.pace == null) return false;
          if (!_numOk(_targetC!, required: false)) return false;
        }
        return true;
      case _Section.health:
        // Kronik durum VE alerji "yok" ya da ≥1 seçim olmadan kaydedilemez
        // (güvenlik — AI planı için kritik), onboarding ile aynı.
        if (_d.conditions.isEmpty || _d.allergies.isEmpty) return false;
        if (_d.conditions.contains('other') &&
            _condOtherC!.text.trim().isEmpty) {
          return false;
        }
        if (_d.allergies.contains('other') &&
            _allergyOtherC!.text.trim().isEmpty) {
          return false;
        }
        return true;
      case _Section.lifestyle:
        return _d.activityLevel != null && _d.waterGlasses != null;
      case _Section.habits:
        return _d.mealsPerDay != null &&
            _d.skipsBreakfast != null &&
            _d.eatingOut != null &&
            _d.weakMoments.isNotEmpty;
      case _Section.prefs:
        return _d.dietStyle != null;
    }
  }

  // ---- Kayıt (onboarding _saveStep ile aynı mantık) ----

  void _showError(String text) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(text),
        backgroundColor: AppColors.sos,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context)!;
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      _showError(l10n.onbSessionLost);
      return;
    }
    _sync();
    setState(() => _saving = true);

    try {
      if (widget.section == _Section.identity) {
        await _supabase
            .from('profiles')
            .update({'full_name': _d.name}).eq('id', userId);
      }

      final prefs = Map<String, dynamic>.from(widget.preferences);
      _d.applyToPreferences(prefs);

      final payload = <String, dynamic>{
        'user_id': userId,
        'preferences': prefs,
        'updated_at': DateTime.now().toIso8601String(),
      };
      // İlgili bölümdeyse TR özet kolonları yeniden üretilir — Edge
      // Function'ın gördüğü bağlam jsonb ile tutarlı kalır.
      switch (widget.section) {
        case _Section.identity:
          payload['age'] = _d.age;
          break;
        case _Section.body:
          payload['height_cm'] = _d.heightCm;
          payload['weight_kg'] = _d.weightKg;
          break;
        case _Section.goal:
          payload['goal'] = _d.goalSummaryTr();
          break;
        case _Section.health:
          payload['health_history'] = _d.healthSummaryTr();
          payload['allergies'] = _d.allergySummaryTr();
          break;
        case _Section.lifestyle:
        case _Section.habits:
        case _Section.prefs:
          break;
      }

      await _supabase.from('health_profiles').upsert(payload);
      if (mounted) Navigator.of(context).pop(_EditResult(_d, prefs));
    } on PostgrestException catch (e) {
      if (mounted) {
        _showError(l10n.onbSaveFailed(e.message));
        setState(() => _saving = false);
      }
    } catch (e) {
      if (mounted) {
        _showError(friendlyErrorMessage(e));
        setState(() => _saving = false);
      }
    }
  }

  // ---- UI ----

  Widget _content(AppLocalizations l10n) {
    switch (widget.section) {
      case _Section.identity:
        return OnbIdentityContent(
          data: _d,
          nameController: _nameC!,
          ageController: _ageC!,
          onChanged: _onChanged,
        );
      case _Section.body:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            OnbBodyContent(
              heightController: _heightC!,
              weightController: _weightC!,
            ),
            const SizedBox(height: 14),
            Text(
              l10n.profBodyNote,
              style: const TextStyle(
                fontSize: 13.5,
                height: 1.4,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        );
      case _Section.goal:
        return OnbGoalContent(
          data: _d,
          targetWeightController: _targetC!,
          onChanged: _onChanged,
        );
      case _Section.health:
        return OnbHealthContent(
          data: _d,
          conditionsOtherController: _condOtherC!,
          medicationsController: _medsC!,
          allergiesOtherController: _allergyOtherC!,
          onChanged: _onChanged,
        );
      case _Section.lifestyle:
        return OnbLifestyleContent(data: _d, onChanged: _onChanged);
      case _Section.habits:
        return OnbHabitsContent(data: _d, onChanged: _onChanged);
      case _Section.prefs:
        return OnbPrefsContent(
          data: _d,
          dislikedController: _dislikedC!,
          onChanged: _onChanged,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.primaryContainer,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
                child: _content(l10n),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
              child: OnbPrimaryButton(
                label: l10n.commonSave,
                loading: _saving,
                onPressed: _canSave && !_saving ? _save : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---- Şifre değiştirme sheet'i ----

class _PasswordSheet extends StatefulWidget {
  const _PasswordSheet();

  @override
  State<_PasswordSheet> createState() => _PasswordSheetState();
}

class _PasswordSheetState extends State<_PasswordSheet> {
  final _supabase = Supabase.instance.client;
  final _passwordC = TextEditingController();
  final _repeatC = TextEditingController();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _passwordC.addListener(_onChanged);
    _repeatC.addListener(_onChanged);
  }

  @override
  void dispose() {
    _passwordC.dispose();
    _repeatC.dispose();
    super.dispose();
  }

  void _onChanged() => setState(() {});

  bool get _lengthOk => _passwordC.text.length >= 6;
  bool get _match =>
      _repeatC.text.isNotEmpty && _passwordC.text == _repeatC.text;
  bool get _showMismatch => _repeatC.text.isNotEmpty && !_match;
  bool get _canSave => _lengthOk && _match;

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context)!;
    setState(() => _saving = true);
    try {
      await _supabase.auth
          .updateUser(UserAttributes(password: _passwordC.text));
      if (mounted) Navigator.of(context).pop(true);
    } on AuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.onbSaveFailed(e.message)),
            backgroundColor: AppColors.sos,
            behavior: SnackBarBehavior.floating,
          ),
        );
        setState(() => _saving = false);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(friendlyErrorMessage(e)),
            backgroundColor: AppColors.sos,
            behavior: SnackBarBehavior.floating,
          ),
        );
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.primaryContainer,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              l10n.profChangePassword,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: AppColors.text,
              ),
            ),
            const SizedBox(height: 20),
            OnbTextField(
              controller: _passwordC,
              label: l10n.profNewPasswordLabel,
              hint: l10n.authPasswordHelper,
              obscureText: true,
            ),
            const SizedBox(height: 12),
            OnbTextField(
              controller: _repeatC,
              label: l10n.profNewPasswordRepeatLabel,
              obscureText: true,
            ),
            const SizedBox(height: 8),
            if (_passwordC.text.isNotEmpty && !_lengthOk)
              Text(
                l10n.authPasswordTooShort,
                style: const TextStyle(fontSize: 13, color: AppColors.sos),
              )
            else if (_showMismatch)
              Text(
                l10n.profPasswordMismatch,
                style: const TextStyle(fontSize: 13, color: AppColors.sos),
              ),
            const SizedBox(height: 16),
            OnbPrimaryButton(
              label: l10n.commonSave,
              loading: _saving,
              onPressed: _canSave && !_saving ? _save : null,
            ),
          ],
        ),
      ),
    );
  }
}
