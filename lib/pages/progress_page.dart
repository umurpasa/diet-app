import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/app_theme.dart';
import '../l10n/app_localizations.dart';
import '../utils/error_messages.dart';
import '../widgets/page_header.dart';

/// İlerleme: kilo yolculuğu hero kartı, bel/kalça ölçü kartı ve grafikler
/// (kilo son 30 gün, kalori/su son 7 gün).
///
/// Kilo ve ölçüler Supabase `progress` tablosunda (RLS: sahibi + atanan
/// diyetisyen). Tabloda (user_id, log_date) unique DEĞİL; aynı güne ikinci
/// giriş app tarafında kontrol edilip mevcut satır güncellenir. Bel/kalça
/// `measurements` jsonb'de (`waist_cm`/`hip_cm`, onboarding ile aynı
/// anahtarlar; girilmeyen anahtarlar merge ile korunur). Hedef kilo
/// `health_profiles.preferences.goal`'dan yalnızca OKUNUR. Kalori ve su
/// grafikleri `food_logs` / `water_logs`'tan türetilir.
class ProgressPage extends StatefulWidget {
  const ProgressPage({super.key, this.profileName});

  /// Başlıktaki avatar için `profiles.full_name` (HomeScreen çeker).
  final ValueListenable<String?>? profileName;

  @override
  State<ProgressPage> createState() => _ProgressPageState();
}

class _ProgressPageState extends State<ProgressPage> {
  final _supabase = Supabase.instance.client;
  final _dayFormat = DateFormat('d/M');

  static const int _weightDays = 30;
  static const int _barDays = 7;

  static const TextStyle _axisLabelStyle =
      TextStyle(fontSize: 10, color: AppColors.textSecondary);

  bool _isLoading = true;

  /// Gün → kilo (son 30 gün, gün başına tek değer, tarihe göre sıralı).
  List<MapEntry<DateTime, double>> _weightEntries = [];

  /// Son 7 gün (eski → bugün): günlük toplam kalori ve bardak sayısı.
  List<int> _dailyCalories = List.filled(_barDays, 0);
  List<int> _dailyGlasses = List.filled(_barDays, 0);

  /// Hero: tüm zamanların ilk/son kilosu (yoksa health_profiles.weight_kg)
  /// ve hedef kilo (yalnızca lose/gain hedefinde).
  double? _startWeight;
  double? _currentWeight;
  double? _targetWeight;

  /// Ölçü kartı: `measurements` dolu en eski/en yeni satır.
  String? _earliestMeasId;
  String? _latestMeasId;
  Map<String, dynamic>? _earliestMeas;
  Map<String, dynamic>? _latestMeas;

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  String? get _userId => _supabase.auth.currentUser?.id;

  /// Saat bileşeni olmadan bugünün tarihi.
  DateTime get _today {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  /// `log_date` sütunu için yyyy-MM-dd formatı.
  String _dateString(DateTime date) {
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '${date.year}-$m-$d';
  }

  /// Grafik, hero ve ölçü kartlarının verisini sunucudan çeker.
  Future<void> _loadAll() async {
    final userId = _userId;
    if (userId == null) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      final weightStart =
          _dateString(_today.subtract(const Duration(days: _weightDays - 1)));
      final barStart =
          _dateString(_today.subtract(const Duration(days: _barDays - 1)));

      final progressRows = await _supabase
          .from('progress')
          .select('log_date, weight_kg, created_at')
          .eq('user_id', userId)
          .gte('log_date', weightStart)
          .not('weight_kg', 'is', null)
          .order('log_date', ascending: true)
          .order('created_at', ascending: true);

      final foodRows = await _supabase
          .from('food_logs')
          .select('log_date, calories')
          .eq('user_id', userId)
          .gte('log_date', barStart);

      final waterRows = await _supabase
          .from('water_logs')
          .select('log_date, glasses')
          .eq('user_id', userId)
          .gte('log_date', barStart);

      // Hero: tarih filtresi olmadan tüm zamanların ilk ve son kilo kaydı
      // (aynı gün içinde en son created_at geçerli).
      final firstWeightRow = await _supabase
          .from('progress')
          .select('weight_kg')
          .eq('user_id', userId)
          .not('weight_kg', 'is', null)
          .order('log_date', ascending: true)
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();

      final lastWeightRow = await _supabase
          .from('progress')
          .select('weight_kg')
          .eq('user_id', userId)
          .not('weight_kg', 'is', null)
          .order('log_date', ascending: false)
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();

      // Ölçü kartı: measurements dolu ilk ve son satır.
      final firstMeasRow = await _supabase
          .from('progress')
          .select('id, measurements')
          .eq('user_id', userId)
          .not('measurements', 'is', null)
          .order('log_date', ascending: true)
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();

      final lastMeasRow = await _supabase
          .from('progress')
          .select('id, measurements')
          .eq('user_id', userId)
          .not('measurements', 'is', null)
          .order('log_date', ascending: false)
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();

      // İkincil bilgi: profil kilosu/hedef okunamazsa sessizce hedefsiz
      // moda düşülür (SnackBar yok).
      double? profileWeight;
      double? targetWeight;
      try {
        final profileRow = await _supabase
            .from('health_profiles')
            .select('weight_kg, preferences')
            .eq('user_id', userId)
            .maybeSingle();

        profileWeight = (profileRow?['weight_kg'] as num?)?.toDouble();
        final prefs = profileRow?['preferences'];
        final goal = prefs is Map ? prefs['goal'] : null;
        if (goal is Map && (goal['type'] == 'lose' || goal['type'] == 'gain')) {
          targetWeight = (goal['target_weight_kg'] as num?)?.toDouble();
        }
      } catch (_) {
        // Hedefsiz mod.
      }

      // Kilo grafiği: aynı güne birden çok satır varsa en son eklenen geçerli
      // (created_at artan sıralı geldiği için sonuncusu kazanır).
      final weightByDay = <DateTime, double>{};
      for (final row in progressRows as List) {
        final date = DateTime.parse(row['log_date'] as String);
        weightByDay[date] = (row['weight_kg'] as num).toDouble();
      }
      final weightEntries = weightByDay.entries.toList()
        ..sort((a, b) => a.key.compareTo(b.key));

      final calories = List.filled(_barDays, 0);
      for (final row in foodRows as List) {
        final index = _barIndex(row['log_date'] as String);
        if (index != null) calories[index] += (row['calories'] as int?) ?? 0;
      }

      final glasses = List.filled(_barDays, 0);
      for (final row in waterRows as List) {
        final index = _barIndex(row['log_date'] as String);
        if (index != null) glasses[index] = (row['glasses'] as int?) ?? 0;
      }

      if (mounted) {
        setState(() {
          _weightEntries = weightEntries;
          _dailyCalories = calories;
          _dailyGlasses = glasses;
          _startWeight = (firstWeightRow?['weight_kg'] as num?)?.toDouble() ??
              profileWeight;
          _currentWeight = (lastWeightRow?['weight_kg'] as num?)?.toDouble() ??
              profileWeight;
          _targetWeight = targetWeight;
          _earliestMeasId = firstMeasRow?['id'] as String?;
          _latestMeasId = lastMeasRow?['id'] as String?;
          _earliestMeas = firstMeasRow?['measurements'] is Map
              ? Map<String, dynamic>.from(firstMeasRow!['measurements'] as Map)
              : null;
          _latestMeas = lastMeasRow?['measurements'] is Map
              ? Map<String, dynamic>.from(lastMeasRow!['measurements'] as Map)
              : null;
        });
      }
    } on PostgrestException catch (e) {
      if (mounted) {
        _showMessage(AppLocalizations.of(context)!.pgLoadError(e.message),
            isError: true);
      }
    } catch (e) {
      if (mounted) _showMessage(friendlyErrorMessage(e), isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// log_date → son 7 günlük dizideki indeks (0 = en eski, 6 = bugün);
  /// aralık dışıysa null.
  int? _barIndex(String logDate) {
    final date = DateTime.parse(logDate);
    final diff =
        _today.difference(DateTime(date.year, date.month, date.day)).inDays;
    if (diff < 0 || diff >= _barDays) return null;
    return _barDays - 1 - diff;
  }

  /// Bar grafiklerinde i. sütunun tarihi (0 = en eski gün).
  DateTime _barDate(int index) =>
      _today.subtract(Duration(days: _barDays - 1 - index));

  /// Ölçümü kaydeder: aynı (user_id, log_date) satırı varsa yalnızca girilen
  /// alanları günceller (measurements merge — girilmeyen anahtarlar korunur,
  /// onboarding_flow deseni), yoksa yeni satır ekler. Başarıda true.
  Future<bool> _saveMeasurement({
    double? weight,
    double? waist,
    double? hip,
    required DateTime date,
  }) async {
    final l10n = AppLocalizations.of(context)!;
    final userId = _userId;
    if (userId == null) {
      _showMessage(l10n.onbSessionLost, isError: true);
      return false;
    }

    try {
      final dateStr = _dateString(date);
      final existing = await _supabase
          .from('progress')
          .select('id, measurements')
          .eq('user_id', userId)
          .eq('log_date', dateStr)
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();

      Map<String, dynamic>? mergedMeasurements;
      if (waist != null || hip != null) {
        mergedMeasurements = Map<String, dynamic>.from(
            existing?['measurements'] as Map? ?? const {});
        if (waist != null) mergedMeasurements['waist_cm'] = waist;
        if (hip != null) mergedMeasurements['hip_cm'] = hip;
      }

      if (existing != null) {
        await _supabase.from('progress').update({
          if (weight != null) 'weight_kg': weight,
          if (mergedMeasurements != null) 'measurements': mergedMeasurements,
        }).eq('id', existing['id'] as String);
      } else {
        await _supabase.from('progress').insert({
          'user_id': userId,
          'log_date': dateStr,
          if (weight != null) 'weight_kg': weight,
          if (mergedMeasurements != null) 'measurements': mergedMeasurements,
        });
      }
      return true;
    } on PostgrestException catch (e) {
      if (mounted) _showMessage(l10n.pgSaveError(e.message), isError: true);
    } catch (e) {
      if (mounted) _showMessage(friendlyErrorMessage(e), isError: true);
    }
    return false;
  }

  Future<void> _openAddSheet() async {
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _AddMeasurementSheet(onSubmit: _saveMeasurement),
    );
    if (saved == true && mounted) {
      _showMessage(AppLocalizations.of(context)!.pgSaved);
      await _loadAll();
    }
  }

  void _showMessage(String text, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(text),
        backgroundColor: isError ? AppColors.sos : null,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// Kilo/cm değerleri: yerel ondalık ayraç, en çok 1 hane.
  String _formatNum(String locale, num value) {
    final format = NumberFormat.decimalPattern(locale)
      ..maximumFractionDigits = 1;
    return format.format(value);
  }

  /// Nötr değişim etiketi, ör. "↓ 2,5 kg" — yön oku her zaman ikincil
  /// renkte gösterilir, yargı rengi yok (kilo almak da hedef olabilir).
  String _changeLabel(String locale, double diff, String unit) {
    final arrow = diff.abs() < 0.05 ? '' : (diff < 0 ? '↓ ' : '↑ ');
    return '$arrow${_formatNum(locale, diff.abs())} $unit';
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
              eyebrow: l10n.pgHeaderEyebrow,
              title: l10n.pgTitle,
              profileName: widget.profileName,
            ),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : RefreshIndicator(
                      onRefresh: _loadAll,
                      child: ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 88),
                        children: [
                          _buildHeroCard(l10n),
                          const SizedBox(height: 12),
                          _buildMeasurementsCard(l10n),
                          const SizedBox(height: 12),
                          _chartCard(
                            title: l10n.pgWeightChart,
                            period: l10n.pgLast30Days,
                            child: _weightEntries.length < 2
                                ? _emptyChart(l10n.pgWeightEmpty)
                                : _buildWeightChart(),
                          ),
                          _chartCard(
                            title: l10n.pgCaloriesChart,
                            period: l10n.pgLast7Days,
                            child: _dailyCalories.every((c) => c == 0)
                                ? _emptyChart(l10n.pgCaloriesEmpty)
                                : _buildBarChart(
                                    values: _dailyCalories,
                                    color: AppColors.secondary,
                                  ),
                          ),
                          _chartCard(
                            title: l10n.pgWaterChart,
                            period: l10n.pgLast7Days,
                            child: _dailyGlasses.every((g) => g == 0)
                                ? _emptyChart(l10n.pgWaterEmpty)
                                : _buildBarChart(
                                    values: _dailyGlasses,
                                    color: AppColors.primary,
                                  ),
                          ),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openAddSheet,
        tooltip: l10n.pgAddTooltip,
        child: const Icon(Icons.add),
      ),
    );
  }

  /// Kilo yolculuğu: başlangıç → güncel → hedef. Hedef varsa dolgu çubuğu,
  /// yoksa toplam değişim satırı; hiç veri yoksa boş durum + CTA.
  Widget _buildHeroCard(AppLocalizations l10n) {
    final textTheme = Theme.of(context).textTheme;
    final locale = l10n.localeName;
    final current = _currentWeight;

    if (current == null) {
      return Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
          child: Column(
            children: [
              Text(
                l10n.pgHeroEmpty,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 15,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _openAddSheet,
                child: Text(l10n.pgAddFirst),
              ),
            ],
          ),
        ),
      );
    }

    // current != null ise start da null olamaz (aynı kaynaklardan türer).
    final start = _startWeight ?? current;
    final target = _targetWeight;

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  _formatNum(locale, current),
                  // Apricot vurgusu: motivasyon öğesi (F-4b/F-4d deseni).
                  style: textTheme.displaySmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppColors.secondary,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  'kg',
                  style: textTheme.bodyMedium
                      ?.copyWith(color: AppColors.textSecondary),
                ),
              ],
            ),
            const SizedBox(height: 6),
            if (target != null) ...[
              Text(
                l10n.pgJourneyRange(
                    _formatNum(locale, start), _formatNum(locale, target)),
                style: textTheme.bodySmall
                    ?.copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 14),
              LinearProgressIndicator(
                value: _goalRatio(start, current, target),
                minHeight: 8,
                backgroundColor: AppColors.fieldFill,
                color: AppColors.secondary,
                borderRadius: BorderRadius.circular(4),
              ),
              const SizedBox(height: 10),
              Text(
                _goalRatio(start, current, target) >= 1
                    ? l10n.pgGoalReached
                    : l10n
                        .pgToGoal(_formatNum(locale, (current - target).abs())),
                style: textTheme.bodySmall
                    ?.copyWith(color: AppColors.textSecondary),
              ),
            ] else
              Text(
                l10n.pgTotalChange(_changeLabel(locale, current - start, 'kg')),
                style: textTheme.bodySmall
                    ?.copyWith(color: AppColors.textSecondary),
              ),
          ],
        ),
      ),
    );
  }

  /// Hedefe ilerleme oranı, 0-1. İşaretli hesap: yanlış yöne gidiliyorsa
  /// pay negatif çıkar ve clamp ile çubuk 0'da kalır (uyarı rengi yok).
  double _goalRatio(double start, double current, double target) {
    final total = start - target;
    if (total.abs() < 0.05) {
      return (current - target).abs() < 0.05 ? 1 : 0;
    }
    return ((start - current) / total).clamp(0.0, 1.0);
  }

  /// Bel/kalça: son değer + ilk kayıttan bu yana nötr değişim. Grafik yok
  /// (veri seyrek — bilinçli karar).
  Widget _buildMeasurementsCard(AppLocalizations l10n) {
    final locale = l10n.localeName;
    final latest = _latestMeas;
    final hasAny = latest != null &&
        (latest['waist_cm'] is num || latest['hip_cm'] is num);

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.pgMeasurementsTitle,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.text,
              ),
            ),
            if (!hasAny) ...[
              const SizedBox(height: 8),
              Text(
                l10n.pgMeasurementsEmpty,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 4),
              TextButton(
                onPressed: _openAddSheet,
                child: Text(l10n.pgMeasurementsCta),
              ),
            ] else ...[
              const SizedBox(height: 12),
              _measurementRow(l10n.pgWaist, 'waist_cm', locale),
              const SizedBox(height: 10),
              _measurementRow(l10n.pgHip, 'hip_cm', locale),
            ],
          ],
        ),
      ),
    );
  }

  Widget _measurementRow(String label, String key, String locale) {
    final latestValue = _latestMeas?[key] as num?;
    // Tek kayıt varsa (ilk == son satır) değişim gösterilmez.
    final sameRow = _earliestMeasId != null && _earliestMeasId == _latestMeasId;
    final earliestValue = sameRow ? null : _earliestMeas?[key] as num?;

    String? change;
    if (latestValue != null && earliestValue != null) {
      final diff = latestValue.toDouble() - earliestValue.toDouble();
      if (diff.abs() >= 0.05) change = _changeLabel(locale, diff, 'cm');
    }

    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(fontSize: 14, color: AppColors.text),
          ),
        ),
        if (change != null) ...[
          Text(
            change,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(width: 12),
        ],
        Text(
          latestValue == null ? '—' : '${_formatNum(locale, latestValue)} cm',
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: AppColors.text,
          ),
        ),
      ],
    );
  }

  Widget _chartCard({
    required String title,
    required String period,
    required Widget child,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.text,
                    ),
                  ),
                ),
                Text(
                  period,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(height: 200, child: child),
          ],
        ),
      ),
    );
  }

  Widget _emptyChart(String message) {
    return Center(
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: const TextStyle(color: AppColors.textSecondary),
      ),
    );
  }

  FlGridData get _gridData => FlGridData(
        drawVerticalLine: false,
        getDrawingHorizontalLine: (_) =>
            const FlLine(color: AppColors.fieldFill, strokeWidth: 1),
      );

  AxisTitles get _leftTitles => AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 40,
          getTitlesWidget: (value, meta) => SideTitleWidget(
            axisSide: meta.axisSide,
            child: Text(meta.formattedValue, style: _axisLabelStyle),
          ),
        ),
      );

  Widget _buildWeightChart() {
    final start = _today.subtract(const Duration(days: _weightDays - 1));
    final spots = _weightEntries
        .map((e) => FlSpot(
              e.key.difference(start).inDays.toDouble(),
              e.value,
            ))
        .toList();

    final weights = _weightEntries.map((e) => e.value);
    final minWeight = weights.reduce((a, b) => a < b ? a : b);
    final maxWeight = weights.reduce((a, b) => a > b ? a : b);

    return LineChart(
      LineChartData(
        minX: 0,
        maxX: (_weightDays - 1).toDouble(),
        minY: (minWeight - 2).floorToDouble(),
        maxY: (maxWeight + 2).ceilToDouble(),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: false,
            color: AppColors.primary,
            barWidth: 3,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, bar, index) => FlDotCirclePainter(
                radius: 2.5,
                color: AppColors.primary,
                strokeWidth: 0,
              ),
            ),
          ),
        ],
        gridData: _gridData,
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: _leftTitles,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 7,
              reservedSize: 28,
              getTitlesWidget: (value, meta) {
                final date = start.add(Duration(days: value.toInt()));
                return SideTitleWidget(
                  axisSide: meta.axisSide,
                  child: Text(_dayFormat.format(date), style: _axisLabelStyle),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBarChart({required List<int> values, required Color color}) {
    final maxValue = values.reduce((a, b) => a > b ? a : b).toDouble();

    return BarChart(
      BarChartData(
        maxY: maxValue * 1.2,
        barGroups: List.generate(
          _barDays,
          (i) => BarChartGroupData(
            x: i,
            barRods: [
              BarChartRodData(
                toY: values[i].toDouble(),
                color: color,
                width: 18,
                borderRadius: BorderRadius.circular(6),
              ),
            ],
          ),
        ),
        gridData: _gridData,
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: _leftTitles,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              getTitlesWidget: (value, meta) {
                return SideTitleWidget(
                  axisSide: meta.axisSide,
                  child: Text(
                    _dayFormat.format(_barDate(value.toInt())),
                    style: _axisLabelStyle,
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

/// Birleşik ölçüm sheet'i: kilo / bel / kalça (üçü de opsiyonel ama en az
/// biri dolu ve geçerli olmalı) + tarih seçimi + tam genişlik Kaydet.
class _AddMeasurementSheet extends StatefulWidget {
  const _AddMeasurementSheet({required this.onSubmit});

  /// Başarıda true döndürür; hatada sheet açık kalır.
  final Future<bool> Function({
    double? weight,
    double? waist,
    double? hip,
    required DateTime date,
  }) onSubmit;

  @override
  State<_AddMeasurementSheet> createState() => _AddMeasurementSheetState();
}

class _AddMeasurementSheetState extends State<_AddMeasurementSheet> {
  final _weightController = TextEditingController();
  final _waistController = TextEditingController();
  final _hipController = TextEditingController();

  DateTime _selectedDate = DateTime.now();
  String? _weightError;
  String? _waistError;
  String? _hipError;
  String? _generalError;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _weightController.dispose();
    _waistController.dispose();
    _hipController.dispose();
    super.dispose();
  }

  double? _parse(String text) =>
      double.tryParse(text.trim().replaceAll(',', '.'));

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() =>
          _selectedDate = DateTime(picked.year, picked.month, picked.day));
    }
  }

  /// Tarih etiketi: Bugün / Dün / "9 Temmuz".
  String _dayLabel(AppLocalizations l10n) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final diff = today
        .difference(DateTime(
            _selectedDate.year, _selectedDate.month, _selectedDate.day))
        .inDays;
    if (diff == 0) return l10n.pgToday;
    if (diff == 1) return l10n.pgYesterday;
    return DateFormat.MMMMd(l10n.localeName).format(_selectedDate);
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context)!;
    final weightText = _weightController.text.trim();
    final waistText = _waistController.text.trim();
    final hipText = _hipController.text.trim();

    final weight = weightText.isEmpty ? null : _parse(weightText);
    final waist = waistText.isEmpty ? null : _parse(waistText);
    final hip = hipText.isEmpty ? null : _parse(hipText);

    // Dolu ama geçersiz (>0 değil) alanlar alan bazlı hata alır; üçü de
    // boşsa genel uyarı satırı gösterilir.
    final allEmpty = weightText.isEmpty && waistText.isEmpty && hipText.isEmpty;
    final weightError = weightText.isNotEmpty && (weight == null || weight <= 0)
        ? l10n.pgInvalidValue
        : null;
    final waistError = waistText.isNotEmpty && (waist == null || waist <= 0)
        ? l10n.pgInvalidValue
        : null;
    final hipError = hipText.isNotEmpty && (hip == null || hip <= 0)
        ? l10n.pgInvalidValue
        : null;

    setState(() {
      _weightError = weightError;
      _waistError = waistError;
      _hipError = hipError;
      _generalError = allEmpty ? l10n.pgAtLeastOne : null;
    });
    if (allEmpty ||
        weightError != null ||
        waistError != null ||
        hipError != null) {
      return;
    }

    setState(() => _isSubmitting = true);
    final ok = await widget.onSubmit(
      weight: weight,
      waist: waist,
      hip: hip,
      date: _selectedDate,
    );
    if (!mounted) return;
    if (ok) {
      Navigator.of(context).pop(true);
    } else {
      setState(() => _isSubmitting = false);
    }
  }

  Widget _numberField({
    required TextEditingController controller,
    required String label,
    required String? errorText,
    required VoidCallback onClearError,
  }) {
    return TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(labelText: label, errorText: errorText),
      onChanged: (_) {
        if (errorText != null || _generalError != null) onClearError();
      },
    );
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
                l10n.pgSheetTitle,
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 16),
              _numberField(
                controller: _weightController,
                label: l10n.pgWeightField,
                errorText: _weightError,
                onClearError: () => setState(() {
                  _weightError = null;
                  _generalError = null;
                }),
              ),
              const SizedBox(height: 12),
              _numberField(
                controller: _waistController,
                label: l10n.pgWaistField,
                errorText: _waistError,
                onClearError: () => setState(() {
                  _waistError = null;
                  _generalError = null;
                }),
              ),
              const SizedBox(height: 12),
              _numberField(
                controller: _hipController,
                label: l10n.pgHipField,
                errorText: _hipError,
                onClearError: () => setState(() {
                  _hipError = null;
                  _generalError = null;
                }),
              ),
              if (_generalError != null) ...[
                const SizedBox(height: 10),
                Text(
                  _generalError!,
                  style: const TextStyle(fontSize: 13, color: AppColors.sos),
                ),
              ],
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.calendar_today,
                      size: 18, color: AppColors.textSecondary),
                  const SizedBox(width: 8),
                  Text(
                    l10n.pgDateLabel,
                    style: const TextStyle(color: AppColors.textSecondary),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: _isSubmitting ? null : _pickDate,
                    child: Text(_dayLabel(l10n)),
                  ),
                ],
              ),
              const SizedBox(height: 12),
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
                      : Text(l10n.commonSave),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
