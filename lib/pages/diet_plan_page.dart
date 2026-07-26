import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../config/app_theme.dart';
import '../l10n/app_localizations.dart';
import '../services/ai_service.dart';
import '../widgets/page_header.dart';

/// Kişiselleştirilmiş AI diyet planını gösterir.
///
/// Plan yapılandırılmış JSON (plan_json) olarak gelir ve kart görünümüyle
/// basılır: hero özet kartı + sağlık notu + Pzt–Paz gün seçici + seçili günün
/// öğün kartları. Plan "revize et" (nedenli, bottom sheet) veya onaylı
/// "sıfırdan" akışıyla yenilenir; her ikisi başlık yanındaki menüden açılır.
/// Alan eksik/yanlış tipteyse çökmeden atlanır.
class DietPlanPage extends StatefulWidget {
  const DietPlanPage({super.key, this.profileName});

  /// Başlıktaki avatar için `profiles.full_name` (HomeScreen çeker).
  final ValueListenable<String?>? profileName;

  @override
  State<DietPlanPage> createState() => _DietPlanPageState();
}

enum _PlanMenuAction { revise, regenerate }

class _DietPlanPageState extends State<DietPlanPage> {
  final AIService _aiService = AIService();
  Map<String, dynamic>? _plan;
  bool _isLoading = false;
  String? _error;
  int _selectedDay = DateTime.now().weekday; // 1=Pzt ... 7=Paz

  @override
  void initState() {
    super.initState();
    // İlk açılışta önbellekteki planı getir (yoksa sunucu yeni üretir).
    _loadPlan(forceRegenerate: false);
  }

  Future<void> _loadPlan({required bool forceRegenerate}) async {
    if (_isLoading) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final plan =
          await _aiService.getDietPlan(forceRegenerate: forceRegenerate);
      if (mounted) _applyPlan(plan);
    } on AIException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (e) {
      if (mounted) {
        setState(
            () => _error = AppLocalizations.of(context)!.unexpectedError('$e'));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _revise(_ReviseInput input) async {
    if (_isLoading) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final plan =
          await _aiService.revisePlan(reasons: input.reasons, note: input.note);
      if (mounted) _applyPlan(plan);
    } on AIException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (e) {
      if (mounted) {
        setState(
            () => _error = AppLocalizations.of(context)!.unexpectedError('$e'));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Yeni planı state'e yazar; seçili gün planda yoksa 1'e düşer.
  void _applyPlan(Map<String, dynamic> plan) {
    final dayNumbers = _daysOf(plan).map(_dayNumber).whereType<int>().toSet();
    setState(() {
      _plan = plan;
      if (!dayNumbers.contains(_selectedDay)) _selectedDay = 1;
    });
  }

  // ---- Menü ve akışlar ----

  Future<void> _openMenu() async {
    final l10n = AppLocalizations.of(context)!;
    final action = await showModalBottomSheet<_PlanMenuAction>(
      context: context,
      builder: (context) => SafeArea(
        top: false,
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
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(Icons.edit_note, color: AppColors.primary),
              title: Text(l10n.dpMenuRevise),
              onTap: () => Navigator.of(context).pop(_PlanMenuAction.revise),
            ),
            ListTile(
              leading: const Icon(Icons.restart_alt, color: AppColors.primary),
              title: Text(l10n.dpMenuRegenerate),
              onTap: () =>
                  Navigator.of(context).pop(_PlanMenuAction.regenerate),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (!mounted) return;
    switch (action) {
      case _PlanMenuAction.revise:
        await _openReviseSheet();
      case _PlanMenuAction.regenerate:
        await _confirmRegenerate();
      case null:
        break;
    }
  }

  Future<void> _openReviseSheet() async {
    final input = await showModalBottomSheet<_ReviseInput>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const _ReviseSheet(),
    );
    if (input == null || !mounted) return;
    await _revise(input);
  }

  Future<void> _confirmRegenerate() async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.dpMenuRegenerate),
        content: Text(l10n.dpRegenerateConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.dpRegenerateContinue),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      await _loadPlan(forceRegenerate: true);
    }
  }

  // ---- Savunmacı JSON erişimi (eksik/yanlış tip alanlar atlanır) ----

  List<Map<String, dynamic>> _daysOf(Map<String, dynamic> plan) {
    final days = plan['days'];
    if (days is! List) return const [];
    return [
      for (final d in days)
        if (d is Map) Map<String, dynamic>.from(d),
    ];
  }

  int? _dayNumber(Map<String, dynamic> day) {
    final n = day['day'];
    return n is num ? n.toInt() : null;
  }

  List<Map<String, dynamic>> _mealsOf(Map<String, dynamic> day) {
    final meals = day['meals'];
    if (meals is! List) return const [];
    return [
      for (final m in meals)
        if (m is Map) Map<String, dynamic>.from(m),
    ];
  }

  String _mealTypeLabel(AppLocalizations l10n, dynamic type) {
    switch (type) {
      case 'breakfast':
        return l10n.dpMealBreakfast;
      case 'lunch':
        return l10n.dpMealLunch;
      case 'dinner':
        return l10n.dpMealDinner;
      case 'snack':
        return l10n.dpMealSnack;
      default:
        return l10n.dpMealDefault;
    }
  }

  IconData _mealTypeIcon(dynamic type) {
    switch (type) {
      case 'breakfast':
        return Icons.free_breakfast;
      case 'lunch':
        return Icons.lunch_dining;
      case 'dinner':
        return Icons.dinner_dining;
      case 'snack':
        return Icons.cookie;
      default:
        return Icons.restaurant;
    }
  }

  String _dayShort(AppLocalizations l10n, int day) {
    switch (day) {
      case 1:
        return l10n.dayShortMon;
      case 2:
        return l10n.dayShortTue;
      case 3:
        return l10n.dayShortWed;
      case 4:
        return l10n.dayShortThu;
      case 5:
        return l10n.dayShortFri;
      case 6:
        return l10n.dayShortSat;
      case 7:
        return l10n.dayShortSun;
      default:
        return '$day';
    }
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
            PageHeader(
              // Bağlam satırı: bugünün tarihi, locale'e duyarlı.
              eyebrow: DateFormat('EEEE, d MMMM', l10n.localeName)
                  .format(DateTime.now()),
              title: l10n.dietPlanTitle,
              actions: [if (_plan != null) _buildHeaderAction(l10n)],
              profileName: widget.profileName,
            ),
            Expanded(child: _buildBody(l10n)),
          ],
        ),
      ),
    );
  }

  // Yükleme sürerken menü ikonunun yerinde küçük spinner gösterilir.
  Widget _buildHeaderAction(AppLocalizations l10n) {
    if (_isLoading) {
      return Container(
        width: 44,
        height: 44,
        padding: const EdgeInsets.all(12),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          shape: BoxShape.circle,
        ),
        child: const CircularProgressIndicator(strokeWidth: 2),
      );
    }
    return Material(
      color: AppColors.surface,
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: IconButton(
        tooltip: l10n.dpMenuTooltip,
        onPressed: _openMenu,
        icon: const Icon(Icons.tune, color: AppColors.text),
      ),
    );
  }

  Widget _buildBody(AppLocalizations l10n) {
    if (_isLoading && _plan == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return _ErrorView(
        message: _error!,
        onRetry: () => _loadPlan(forceRegenerate: false),
      );
    }
    final plan = _plan;
    if (plan == null) {
      return _buildEmptyState(l10n);
    }
    return _buildPlan(l10n, plan);
  }

  Widget _buildEmptyState(AppLocalizations l10n) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.restaurant_menu,
              size: 56,
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: 16),
            Text(
              l10n.dpEmptyMessage,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 24),
            FilledButton(
              // İlk planda değiştirilecek bir şey olmadığından onay sorulmaz.
              onPressed:
                  _isLoading ? null : () => _loadPlan(forceRegenerate: true),
              child: Text(l10n.dpCreateFirstPlan),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlan(AppLocalizations l10n, Map<String, dynamic> plan) {
    final healthNote = plan['health_note'];
    final days = _daysOf(plan);
    Map<String, dynamic>? selectedDay;
    for (final d in days) {
      if (_dayNumber(d) == _selectedDay) {
        selectedDay = d;
        break;
      }
    }
    final meals = selectedDay == null
        ? const <Map<String, dynamic>>[]
        : _mealsOf(selectedDay);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildSummaryCard(l10n, plan),
          if (healthNote is String && healthNote.trim().isNotEmpty) ...[
            const SizedBox(height: 12),
            _buildHealthNoteCard(healthNote),
          ],
          const SizedBox(height: 16),
          _buildDaySelector(l10n),
          const SizedBox(height: 12),
          Expanded(
            child: meals.isEmpty
                ? Center(
                    child: Text(
                      l10n.dpNoMealsForDay,
                      style: const TextStyle(
                        fontSize: 16,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.only(bottom: 16),
                    itemCount: meals.length,
                    itemBuilder: (context, i) => _buildMealCard(l10n, meals[i]),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(AppLocalizations l10n, Map<String, dynamic> plan) {
    final title = plan['title'];
    final dailyKcal = plan['daily_kcal'];
    final macros = plan['macros'];
    final textTheme = Theme.of(context).textTheme;

    String macroValue(String key) {
      if (macros is! Map) return '-';
      final v = macros[key];
      return v is num ? '${v.toInt()} g' : '-';
    }

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title is String && title.isNotEmpty ? title : l10n.dietPlanTitle,
              style: textTheme.titleSmall
                  ?.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 6),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  dailyKcal is num ? '${dailyKcal.toInt()}' : '-',
                  // Apricot vurgusu: paletteki tek vurgu kullanımı,
                  // motivasyon öğesi (F-4b kararı).
                  style: textTheme.displaySmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppColors.secondary,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  l10n.dpKcalPerDay,
                  style: textTheme.bodyMedium
                      ?.copyWith(color: AppColors.textSecondary),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                _MacroStat(
                  value: macroValue('carb_g'),
                  label: l10n.dpMacroCarb,
                ),
                _MacroStat(
                  value: macroValue('protein_g'),
                  label: l10n.dpMacroProtein,
                ),
                _MacroStat(
                  value: macroValue('fat_g'),
                  label: l10n.dpMacroFat,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHealthNoteCard(String note) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      margin: EdgeInsets.zero,
      color: colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.info_outline, color: colorScheme.onPrimaryContainer),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                note,
                style: TextStyle(color: colorScheme.onPrimaryContainer),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDaySelector(AppLocalizations l10n) {
    return Row(
      children: [
        for (var d = 1; d <= 7; d++) ...[
          if (d > 1) const SizedBox(width: 6),
          Expanded(
            child: _DayButton(
              label: _dayShort(l10n, d),
              selected: _selectedDay == d,
              onTap: () => setState(() => _selectedDay = d),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildMealCard(AppLocalizations l10n, Map<String, dynamic> meal) {
    final type = meal['type'];
    final time = meal['time'];
    final name = meal['name'];
    final kcal = meal['kcal'];
    final label = _mealTypeLabel(l10n, type);

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        leading: Container(
          width: 44,
          height: 44,
          decoration: const BoxDecoration(
            color: AppColors.fieldFill,
            shape: BoxShape.circle,
          ),
          child: Icon(_mealTypeIcon(type), color: AppColors.primary, size: 22),
        ),
        title: Text(
          name is String && name.isNotEmpty ? name : label,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          [
            if (time is String && time.isNotEmpty) time,
            label,
          ].join(' • '),
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        trailing: kcal is num
            ? Text(
                '${kcal.toInt()} kcal',
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: AppColors.text,
                ),
              )
            : null,
      ),
    );
  }
}

/// Hero kartındaki tek makro sütunu: değer bold, altında etiket.
class _MacroStat extends StatelessWidget {
  const _MacroStat({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 16,
              color: AppColors.text,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

/// Pzt–Paz seçicideki tek gün hapı.
class _DayButton extends StatelessWidget {
  const _DayButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      customBorder: const StadiumBorder(),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        height: 40,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.fieldFill,
          borderRadius: BorderRadius.circular(20),
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: selected ? AppColors.onPrimary : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}

/// Revize sheet'inden dönen kullanıcı girdisi.
class _ReviseInput {
  final List<String> reasons;
  final String? note;

  const _ReviseInput(this.reasons, this.note);
}

class _ReviseSheet extends StatefulWidget {
  const _ReviseSheet();

  @override
  State<_ReviseSheet> createState() => _ReviseSheetState();
}

class _ReviseSheetState extends State<_ReviseSheet> {
  final Set<int> _selected = {};
  final TextEditingController _noteController = TextEditingController();
  String? _validationError;

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  // Backend serbest metin beklediği için değerler seçili dildeki etiketin
  // aynısı (Gemini iki dili de anlar).
  List<String> _reasonOptions(AppLocalizations l10n) => [
        l10n.dpReasonDisliked,
        l10n.dpReasonHardToPrepare,
        l10n.dpReasonIngredientsUnavailable,
      ];

  void _submit() {
    final l10n = AppLocalizations.of(context)!;
    final note = _noteController.text.trim();
    if (_selected.isEmpty && note.isEmpty) {
      setState(() => _validationError = l10n.dpReviseValidation);
      return;
    }
    final options = _reasonOptions(l10n);
    Navigator.of(context).pop(_ReviseInput(
      [for (final i in _selected.toList()..sort()) options[i]],
      note.isEmpty ? null : note,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final options = _reasonOptions(l10n);

    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SafeArea(
        top: false,
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
              const SizedBox(height: 16),
              Text(
                l10n.dpMenuRevise,
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              Text(l10n.dpRevisePrompt),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  for (var i = 0; i < options.length; i++)
                    FilterChip(
                      label: Text(options[i]),
                      selected: _selected.contains(i),
                      onSelected: (selected) {
                        setState(() {
                          if (selected) {
                            _selected.add(i);
                          } else {
                            _selected.remove(i);
                          }
                          _validationError = null;
                        });
                      },
                    ),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _noteController,
                maxLines: 3,
                onChanged: (_) {
                  if (_validationError != null) {
                    setState(() => _validationError = null);
                  }
                },
                decoration: InputDecoration(
                  labelText: l10n.dpReviseNoteLabel,
                  hintText: l10n.dpReviseNoteHint,
                  errorText: _validationError,
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _submit,
                  child: Text(l10n.dpReviseSubmit),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              color: Theme.of(context).colorScheme.error,
              size: 40,
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            FilledButton(onPressed: onRetry, child: Text(l10n.commonRetry)),
          ],
        ),
      ),
    );
  }
}
