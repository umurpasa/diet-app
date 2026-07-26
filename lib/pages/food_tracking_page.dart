import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/app_theme.dart';
import '../l10n/app_localizations.dart';
import '../utils/error_messages.dart';
import '../widgets/page_header.dart';

/// Kanonik öğün türleri — `food_logs.meal_type` yazma değerleri ve grup
/// sırası (diet plan PLAN_SCHEMA enum'uyla aynı).
const List<String> _kMealTypes = ['breakfast', 'lunch', 'dinner', 'snack'];

/// DB'deki `meal_type` değerini kanonik İngilizce değere çevirir.
///
/// Eski kayıtlar Türkçe değer tutuyor olabilir (SQL migrasyonu manuel adım);
/// iki dili de tanır, bilinmeyen/null ara öğüne düşer.
String _normalizeMealType(String? raw) {
  switch (raw) {
    case 'breakfast':
    case 'kahvaltı':
      return 'breakfast';
    case 'lunch':
    case 'öğle':
      return 'lunch';
    case 'dinner':
    case 'akşam':
      return 'dinner';
    default:
      return 'snack';
  }
}

String _mealTypeLabel(AppLocalizations l10n, String type) {
  switch (type) {
    case 'breakfast':
      return l10n.ftMealBreakfast;
    case 'lunch':
      return l10n.ftMealLunch;
    case 'dinner':
      return l10n.ftMealDinner;
    default:
      return l10n.ftMealSnack;
  }
}

IconData _mealTypeIcon(String type) {
  switch (type) {
    case 'breakfast':
      return Icons.free_breakfast;
    case 'lunch':
      return Icons.lunch_dining;
    case 'dinner':
      return Icons.dinner_dining;
    default:
      return Icons.cookie;
  }
}

/// Ekleme sheet'inde saate göre akıllı öğün ön seçimi.
String _smartMealType() {
  final hour = DateTime.now().hour;
  if (hour < 11) return 'breakfast';
  if (hour <= 15) return 'lunch';
  if (hour >= 17 && hour <= 21) return 'dinner';
  return 'snack';
}

/// Öğün ve su takibi.
///
/// Veriler Supabase'deki `food_logs` ve `water_logs` tablolarında tutulur
/// (RLS: yalnızca sahibi + atanan diyetisyen erişir). Gün değişince o günün
/// kayıtları çekilir; su takibi optimistic UI + upsert ile çalışır. Günün
/// toplamı, aktif planın `daily_kcal` hedefiyle hero kartında karşılaştırılır
/// (plan yoksa hedefsiz mod). Yeni kayıtlar İngilizce `meal_type` yazar,
/// okuma eski Türkçe değerleri de tanır.
class FoodTrackingPage extends StatefulWidget {
  const FoodTrackingPage({super.key, this.profileName});

  /// Başlıktaki avatar için `profiles.full_name` (HomeScreen çeker).
  final ValueListenable<String?>? profileName;

  @override
  State<FoodTrackingPage> createState() => _FoodTrackingPageState();
}

class _FoodTrackingPageState extends State<FoodTrackingPage> {
  final _supabase = Supabase.instance.client;

  List<FoodLog> _entries = [];
  DateTime _selectedDate = DateTime.now();
  int _waterGlasses = 0;
  bool _isLoading = true;

  /// Aktif planın günlük kalori hedefi; plan yoksa hedefsiz mod.
  int? _targetKcal;

  @override
  void initState() {
    super.initState();
    _loadDay();
    _loadTargetKcal();
  }

  String? get _userId => _supabase.auth.currentUser?.id;

  /// `log_date` sütunu için yyyy-MM-dd formatı.
  String _dateString(DateTime date) {
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '${date.year}-$m-$d';
  }

  /// Seçili günün yemek ve su kayıtlarını sunucudan çeker.
  Future<void> _loadDay() async {
    final userId = _userId;
    if (userId == null) {
      setState(() => _isLoading = false);
      return;
    }

    setState(() => _isLoading = true);
    try {
      final dateStr = _dateString(_selectedDate);

      final foodRows = await _supabase
          .from('food_logs')
          .select()
          .eq('user_id', userId)
          .eq('log_date', dateStr)
          .order('created_at', ascending: true);

      final waterRow = await _supabase
          .from('water_logs')
          .select('glasses')
          .eq('user_id', userId)
          .eq('log_date', dateStr)
          .maybeSingle();

      if (mounted) {
        setState(() {
          _entries =
              (foodRows as List).map((row) => FoodLog.fromRow(row)).toList();
          _waterGlasses = (waterRow?['glasses'] as int?) ?? 0;
        });
      }
    } on PostgrestException catch (e) {
      if (mounted) {
        _showError(AppLocalizations.of(context)!.ftLoadError(e.message));
      }
    } catch (e) {
      if (mounted) _showError(friendlyErrorMessage(e));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// Aktif planın `daily_kcal` hedefini bir kez okur.
  ///
  /// İkincil bilgi: hata olursa sessizce hedefsiz moda düşer (SnackBar yok).
  Future<void> _loadTargetKcal() async {
    final userId = _userId;
    if (userId == null) return;

    try {
      final row = await _supabase
          .from('diet_plans')
          .select('plan_json')
          .eq('user_id', userId)
          .eq('is_active', true)
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();

      final planJson = row?['plan_json'];
      final kcal = planJson is Map ? planJson['daily_kcal'] : null;
      if (mounted && kcal is num && kcal > 0) {
        setState(() => _targetKcal = kcal.toInt());
      }
    } catch (_) {
      // Hedef okunamadıysa sadece toplam gösterilir.
    }
  }

  /// Yeni öğün kaydını `food_logs`'a ekler; başarıda satırı döndürür,
  /// hatada SnackBar gösterip null döndürür (sheet açık kalır).
  Future<FoodLog?> _addFoodEntry(
      String name, int calories, String mealType) async {
    final l10n = AppLocalizations.of(context)!;
    final userId = _userId;
    if (userId == null) {
      _showError(l10n.onbSessionLost);
      return null;
    }

    try {
      final row = await _supabase
          .from('food_logs')
          .insert({
            'user_id': userId,
            'log_date': _dateString(_selectedDate),
            'name': name,
            'calories': calories,
            'meal_type': mealType,
          })
          .select()
          .single();

      return FoodLog.fromRow(row);
    } on PostgrestException catch (e) {
      if (mounted) _showError(l10n.ftAddError(e.message));
    } catch (e) {
      if (mounted) _showError(friendlyErrorMessage(e));
    }
    return null;
  }

  /// Kaydı `food_logs`'tan siler.
  Future<void> _deleteFoodEntry(FoodLog entry) async {
    try {
      await _supabase.from('food_logs').delete().eq('id', entry.id);
      if (mounted) {
        setState(() => _entries.removeWhere((e) => e.id == entry.id));
      }
    } on PostgrestException catch (e) {
      if (mounted) {
        _showError(AppLocalizations.of(context)!.ftDeleteError(e.message));
      }
    } catch (e) {
      if (mounted) _showError(friendlyErrorMessage(e));
    }
  }

  /// Su sayacını optimistic günceller; upsert başarısız olursa geri alır.
  Future<void> _changeWater(int delta) async {
    final l10n = AppLocalizations.of(context)!;
    final userId = _userId;
    if (userId == null) {
      _showError(l10n.onbSessionLost);
      return;
    }

    final previous = _waterGlasses;
    final next = previous + delta;
    if (next < 0) return;

    setState(() => _waterGlasses = next);

    try {
      await _supabase.from('water_logs').upsert(
        {
          'user_id': userId,
          'log_date': _dateString(_selectedDate),
          'glasses': next,
        },
        onConflict: 'user_id,log_date',
      );
    } on PostgrestException catch (e) {
      if (mounted) {
        setState(() => _waterGlasses = previous);
        _showError(l10n.ftWaterError(e.message));
      }
    } catch (e) {
      if (mounted) {
        setState(() => _waterGlasses = previous);
        _showError(friendlyErrorMessage(e));
      }
    }
  }

  /// Son kayıtlardan benzersiz (isim, kalori) 10 öğe türetir.
  Future<List<FoodLog>> _fetchRecentFoods() async {
    final userId = _userId;
    if (userId == null) return [];

    final rows = await _supabase
        .from('food_logs')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .limit(50);

    final unique = <FoodLog>[];
    for (final row in rows as List) {
      final food = FoodLog.fromRow(row);
      final exists =
          unique.any((f) => f.name == food.name && f.calories == food.calories);
      if (!exists) {
        unique.add(food);
        if (unique.length >= 10) break;
      }
    }
    return unique;
  }

  Future<void> _openAddSheet() async {
    final added = await showModalBottomSheet<FoodLog>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _AddFoodSheet(
        // Sheet her açılışta taze liste çeker.
        recentFuture: _fetchRecentFoods(),
        onSubmit: _addFoodEntry,
      ),
    );
    if (added != null && mounted) {
      setState(() => _entries.add(added));
    }
  }

  /// 7 günlük şeridin dışındaki tarihler için takvim.
  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (picked != null && !_isSameDay(picked, _selectedDate)) {
      setState(() => _selectedDate = picked);
      _loadDay();
    }
  }

  void _showError(String text) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(text),
        backgroundColor: AppColors.sos,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  int get _totalCalories =>
      _entries.fold(0, (sum, entry) => sum + (entry.calories ?? 0));

  /// Hero kartındaki tarih etiketi: Bugün / Dün / "9 Temmuz".
  String _dayLabel(AppLocalizations l10n, String locale, DateTime day) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final diff =
        today.difference(DateTime(day.year, day.month, day.day)).inDays;
    if (diff == 0) return l10n.ftToday;
    if (diff == 1) return l10n.ftYesterday;
    return DateFormat.MMMMd(locale).format(day);
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
              // Bağlam satırı: seçili gün — sayfadaki seçimle senkron.
              eyebrow: _dayLabel(l10n, l10n.localeName, _selectedDate),
              title: l10n.ftTitle,
              actions: [
                Material(
                  color: AppColors.surface,
                  shape: const CircleBorder(),
                  clipBehavior: Clip.antiAlias,
                  child: IconButton(
                    tooltip:
                        MaterialLocalizations.of(context).datePickerHelpText,
                    onPressed: _selectDate,
                    icon: const Icon(Icons.calendar_today,
                        color: AppColors.text, size: 20),
                  ),
                ),
              ],
              profileName: widget.profileName,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _buildDateStrip(l10n),
            ),
            const SizedBox(height: 12),
            Expanded(child: _buildBody(l10n)),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openAddSheet,
        tooltip: l10n.ftAddTooltip,
        child: const Icon(Icons.add),
      ),
    );
  }

  /// Son 7 günün hapları; en sağda bugün. Takvimden şerit dışı bir tarih
  /// seçildiyse hiçbir hap seçili görünmez.
  Widget _buildDateStrip(AppLocalizations l10n) {
    final locale = l10n.localeName;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    return Row(
      children: [
        for (var i = 6; i >= 0; i--) ...[
          if (i < 6) const SizedBox(width: 6),
          Expanded(
            child: _buildDayPill(
              date: today.subtract(Duration(days: i)),
              isToday: i == 0,
              l10n: l10n,
              locale: locale,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildDayPill({
    required DateTime date,
    required bool isToday,
    required AppLocalizations l10n,
    required String locale,
  }) {
    final selected = _isSameDay(date, _selectedDate);
    final dayName = isToday ? l10n.ftToday : DateFormat.E(locale).format(date);

    return InkWell(
      onTap: () {
        if (_isSameDay(date, _selectedDate)) return;
        setState(() => _selectedDate = date);
        _loadDay();
      },
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        height: 56,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? AppColors.primaryContainer : AppColors.fieldFill,
          borderRadius: BorderRadius.circular(16),
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                dayName,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: selected
                      ? AppColors.onPrimaryContainer
                      : AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '${date.day}',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color:
                      selected ? AppColors.onPrimaryContainer : AppColors.text,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody(AppLocalizations l10n) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_entries.isEmpty) {
      // Boş gün: hero + su sabit, boş durum kalan alanda ortalanır.
      return Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: _buildHeroCard(l10n),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: _buildWaterCard(l10n),
          ),
          Expanded(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(32, 16, 32, 16),
                child: _buildEmptyState(l10n),
              ),
            ),
          ),
        ],
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 88),
      children: [
        _buildHeroCard(l10n),
        const SizedBox(height: 12),
        _buildWaterCard(l10n),
        const SizedBox(height: 8),
        ..._buildMealSections(l10n),
      ],
    );
  }

  /// Günün toplamı + plan hedefi. Hedef aşılsa da renk değişmez (vaaz yok),
  /// çubuk sadece dolu kalır.
  Widget _buildHeroCard(AppLocalizations l10n) {
    final textTheme = Theme.of(context).textTheme;
    final locale = l10n.localeName;
    final numberFormat = NumberFormat.decimalPattern(locale);
    final target = _targetKcal;
    final total = _totalCalories;

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _dayLabel(l10n, locale, _selectedDate),
              style: textTheme.titleSmall
                  ?.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 6),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  numberFormat.format(total),
                  // Apricot vurgusu: motivasyon öğesi (F-4b deseni).
                  style: textTheme.displaySmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppColors.secondary,
                  ),
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    target == null
                        ? 'kcal'
                        : '/ ${numberFormat.format(target)} kcal',
                    style: textTheme.bodyMedium
                        ?.copyWith(color: AppColors.textSecondary),
                  ),
                ),
              ],
            ),
            if (target != null) ...[
              const SizedBox(height: 14),
              LinearProgressIndicator(
                value: (total / target).clamp(0.0, 1.0),
                minHeight: 8,
                backgroundColor: AppColors.fieldFill,
                color: AppColors.secondary,
                borderRadius: BorderRadius.circular(4),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildWaterCard(AppLocalizations l10n) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
        child: Column(
          children: [
            Text(
              l10n.ftWaterTitle,
              style: Theme.of(context)
                  .textTheme
                  .titleSmall
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _WaterButton(
                  icon: Icons.remove,
                  onPressed: () => _changeWater(-1),
                ),
                const SizedBox(width: 10),
                // Bardak ikonları dar ekranda taşmasın diye gerekirse
                // topluca küçülür.
                Expanded(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: List.generate(
                        8,
                        (index) => Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4.0),
                          child: Icon(
                            Icons.water_drop,
                            color: index < _waterGlasses
                                ? AppColors.primary
                                : AppColors.fieldFill,
                            size: 26,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                _WaterButton(
                  icon: Icons.add,
                  onPressed: () => _changeWater(1),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              l10n.ftGlasses(_waterGlasses),
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  /// Kayıtları öğün türüne göre gruplar; boş grup hiç gösterilmez.
  List<Widget> _buildMealSections(AppLocalizations l10n) {
    final groups = <String, List<FoodLog>>{};
    for (final entry in _entries) {
      groups
          .putIfAbsent(_normalizeMealType(entry.mealType), () => [])
          .add(entry);
    }

    final widgets = <Widget>[];
    for (final type in _kMealTypes) {
      final items = groups[type];
      if (items == null || items.isEmpty) continue;
      final sectionKcal =
          items.fold<int>(0, (sum, e) => sum + (e.calories ?? 0));

      widgets.add(
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 14, 4, 8),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  _mealTypeLabel(l10n, type),
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.text,
                  ),
                ),
              ),
              Text(
                '$sectionKcal kcal',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      );
      widgets.addAll(items.map((e) => _buildEntryCard(type, e)));
    }
    return widgets;
  }

  Widget _buildEntryCard(String type, FoodLog entry) {
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
          entry.name,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: entry.timeLabel.isEmpty
            ? null
            : Text(
                entry.timeLabel,
                style: const TextStyle(color: AppColors.textSecondary),
              ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${entry.calories ?? 0} kcal',
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                color: AppColors.text,
              ),
            ),
            const SizedBox(width: 4),
            IconButton(
              icon: const Icon(Icons.delete_outline,
                  size: 20, color: AppColors.textSecondary),
              visualDensity: VisualDensity.compact,
              onPressed: () => _deleteFoodEntry(entry),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(AppLocalizations l10n) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(
          Icons.restaurant,
          size: 56,
          color: AppColors.textSecondary,
        ),
        const SizedBox(height: 16),
        Text(
          l10n.ftEmptyDay,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 16,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 24),
        FilledButton(
          onPressed: _openAddSheet,
          child: Text(l10n.ftEmptyCta),
        ),
      ],
    );
  }
}

/// Su kartındaki yuvarlak tonal +/- butonu.
class _WaterButton extends StatelessWidget {
  const _WaterButton({required this.icon, required this.onPressed});

  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton.filledTonal(
      onPressed: onPressed,
      icon: Icon(icon),
      style: IconButton.styleFrom(
        backgroundColor: AppColors.primaryContainer,
        foregroundColor: AppColors.onPrimaryContainer,
      ),
    );
  }
}

/// Birleşik ekleme sheet'i: son eklenen çipleri + isim/kalori inputları +
/// öğün çipleri + Ekle. Çipe tıklamak alanları doldurur (doğrudan eklemez).
class _AddFoodSheet extends StatefulWidget {
  const _AddFoodSheet({required this.recentFuture, required this.onSubmit});

  final Future<List<FoodLog>> recentFuture;

  /// Başarıda eklenen kaydı, hatada null döndürür (sheet açık kalır).
  final Future<FoodLog?> Function(String name, int calories, String mealType)
      onSubmit;

  @override
  State<_AddFoodSheet> createState() => _AddFoodSheetState();
}

class _AddFoodSheetState extends State<_AddFoodSheet> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _caloriesController = TextEditingController();

  String _selectedMeal = _smartMealType();
  String? _nameError;
  String? _caloriesError;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    _caloriesController.dispose();
    super.dispose();
  }

  void _applyRecent(FoodLog food) {
    _nameController.text = food.name;
    _caloriesController.text = '${food.calories ?? 0}';
    setState(() {
      _selectedMeal = _normalizeMealType(food.mealType);
      _nameError = null;
      _caloriesError = null;
    });
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context)!;
    final name = _nameController.text.trim();
    final caloriesText = _caloriesController.text.trim();
    final calories = int.tryParse(caloriesText);

    setState(() {
      _nameError = name.isEmpty ? l10n.ftNameRequired : null;
      _caloriesError = caloriesText.isEmpty
          ? l10n.ftCaloriesRequired
          : calories == null
              ? l10n.ftCaloriesInvalid
              : null;
    });
    if (name.isEmpty || calories == null) return;

    setState(() => _isSubmitting = true);
    final added = await widget.onSubmit(name, calories, _selectedMeal);
    if (!mounted) return;
    if (added != null) {
      Navigator.of(context).pop(added);
    } else {
      setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

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
                l10n.ftAddSheetTitle,
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
              _buildRecentSection(l10n),
              const SizedBox(height: 16),
              TextField(
                controller: _nameController,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  labelText: l10n.ftFoodName,
                  errorText: _nameError,
                ),
                onChanged: (_) {
                  if (_nameError != null) {
                    setState(() => _nameError = null);
                  }
                },
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _caloriesController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: l10n.ftCalories,
                  errorText: _caloriesError,
                ),
                onChanged: (_) {
                  if (_caloriesError != null) {
                    setState(() => _caloriesError = null);
                  }
                },
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                children: [
                  for (final type in _kMealTypes)
                    ChoiceChip(
                      label: Text(_mealTypeLabel(l10n, type)),
                      selected: _selectedMeal == type,
                      onSelected: (selected) {
                        if (selected) {
                          setState(() => _selectedMeal = type);
                        }
                      },
                    ),
                ],
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _isSubmitting ? null : _submit,
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(l10n.ftAdd),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Son eklenenler: yüklenirken mini spinner, boşsa/hatalıysa bölüm gizli.
  Widget _buildRecentSection(AppLocalizations l10n) {
    return FutureBuilder<List<FoodLog>>(
      future: widget.recentFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Padding(
            padding: EdgeInsets.only(top: 16),
            child: Center(
              child: SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          );
        }
        final foods = snapshot.data ?? [];
        if (snapshot.hasError || foods.isEmpty) {
          return const SizedBox.shrink();
        }
        return Padding(
          padding: const EdgeInsets.only(top: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.ftRecentLabel,
                style: Theme.of(context)
                    .textTheme
                    .titleSmall
                    ?.copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final food in foods)
                    ActionChip(
                      label: Text('${food.name} · ${food.calories ?? 0} kcal'),
                      onPressed: () => _applyRecent(food),
                    ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

/// `food_logs` tablosundaki bir satır.
class FoodLog {
  final String id;
  final String name;
  final int? calories;
  final String? mealType;
  final DateTime? createdAt;

  FoodLog({
    required this.id,
    required this.name,
    this.calories,
    this.mealType,
    this.createdAt,
  });

  factory FoodLog.fromRow(Map<String, dynamic> row) {
    return FoodLog(
      id: row['id'] as String,
      name: row['name'] as String,
      calories: row['calories'] as int?,
      mealType: row['meal_type'] as String?,
      createdAt: row['created_at'] == null
          ? null
          : DateTime.tryParse(row['created_at'] as String),
    );
  }

  /// Kayıt saati, yerel saatle HH:mm.
  String get timeLabel {
    final local = createdAt?.toLocal();
    if (local == null) return '';
    final h = local.hour.toString().padLeft(2, '0');
    final m = local.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}
