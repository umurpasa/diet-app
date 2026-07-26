/// Onboarding cevap modeli + Supabase eşlemeleri (docs/BACKLOG.md F madde 2).
///
/// `health_profiles.preferences` jsonb anahtar/değerleri İngilizce
/// snake_case; zayıf an değerleri `emergency_page.dart`'taki trigger_type
/// değerleriyle birebir aynı. `goal` / `health_history` / `allergies` text
/// kolonlarındaki okunur özetler Edge Function prompt'unu beslediği için
/// UI dilinden bağımsız her zaman TÜRKÇE yazılır (veri, arayüz metni değil).
class OnboardingData {
  String name = '';
  int? age;

  /// female | male | unspecified
  String? sex;

  num? heightCm;
  num? weightKg;
  num? waistCm;
  num? hipCm;

  /// lose | gain | maintain | healthy
  String? goalType;
  num? targetWeightKg;

  /// slow | balanced | fast
  String? pace;

  /// diabetes, insulin_resistance, hypertension, thyroid, cholesterol,
  /// other, none ("none" tek başına).
  Set<String> conditions = {};
  String conditionsOther = '';
  String medications = '';

  /// gluten, lactose, nuts, seafood, egg, other, none ("none" tek başına).
  Set<String> allergies = {};
  String allergiesOther = '';

  /// sedentary | light | moderate | active | very_active
  String? activityLevel;

  /// 0-2 | 3-5 | 6-8 | 8+
  String? waterGlasses;

  /// <5 | 5-6 | 7-8 | 8+
  String? sleepHours;

  /// none | occasional | regular
  String? smoking;
  String? alcohol;

  /// 2 | 3 | 4+
  String? mealsPerDay;

  /// never | sometimes | often
  String? skipsBreakfast;

  /// rarely | 1-2_per_week | 3+_per_week | daily
  String? eatingOut;

  /// night_snacking, sweet_craving, hunger_between_meals, stress_eating,
  /// none — Acil Buton trigger_type değerleriyle aynı.
  Set<String> weakMoments = {};

  /// omnivore | vegetarian | vegan
  String? dietStyle;
  String dislikedFoods = '';

  OnboardingData();

  /// Hedef kilo ve tempo yalnızca ver/al hedeflerinde sorulur.
  bool get goalNeedsDetails => goalType == 'lose' || goalType == 'gain';

  /// Kısmi kayıttan devam: daha önce kaydedilmiş kolonlar + preferences
  /// jsonb'den cevapları geri yükler (bel/kalça `progress`'te olduğu için
  /// geri yüklenmez; zaten opsiyonel).
  factory OnboardingData.restore({
    required Map<String, dynamic> preferences,
    Map<String, dynamic>? row,
    String? fullName,
  }) {
    final data = OnboardingData();
    data.name = fullName ?? '';
    data.age = (row?['age'] as num?)?.toInt();
    data.heightCm = row?['height_cm'] as num?;
    data.weightKg = row?['weight_kg'] as num?;

    String? str(String key) => preferences[key] as String?;
    Set<String> set(String key) => Set<String>.from(
        (preferences[key] as List?)?.whereType<String>() ?? const <String>[]);

    data.sex = str('sex');

    final goal = preferences['goal'];
    if (goal is Map) {
      data.goalType = goal['type'] as String?;
      data.targetWeightKg = goal['target_weight_kg'] as num?;
      data.pace = goal['pace'] as String?;
    }

    data.conditions = set('conditions');
    data.conditionsOther = str('conditions_other') ?? '';
    data.medications = str('medications') ?? '';
    data.allergies = set('allergies');
    data.allergiesOther = str('allergies_other') ?? '';
    data.activityLevel = str('activity_level');
    data.waterGlasses = str('water_glasses');
    data.sleepHours = str('sleep_hours');
    data.smoking = str('smoking');
    data.alcohol = str('alcohol');
    data.mealsPerDay = str('meals_per_day');
    data.skipsBreakfast = str('skips_breakfast');
    data.eatingOut = str('eating_out');
    data.weakMoments = set('weak_moments');
    data.dietStyle = str('diet_style');
    data.dislikedFoods = str('disliked_foods') ?? '';
    return data;
  }

  /// Bağımsız kopya — profil sayfasının düzenleme sheet'leri kopya üzerinde
  /// çalışır ki iptal edilince orijinal cevaplar bozulmasın.
  OnboardingData clone() {
    return OnboardingData()
      ..name = name
      ..age = age
      ..sex = sex
      ..heightCm = heightCm
      ..weightKg = weightKg
      ..waistCm = waistCm
      ..hipCm = hipCm
      ..goalType = goalType
      ..targetWeightKg = targetWeightKg
      ..pace = pace
      ..conditions = Set.of(conditions)
      ..conditionsOther = conditionsOther
      ..medications = medications
      ..allergies = Set.of(allergies)
      ..allergiesOther = allergiesOther
      ..activityLevel = activityLevel
      ..waterGlasses = waterGlasses
      ..sleepHours = sleepHours
      ..smoking = smoking
      ..alcohol = alcohol
      ..mealsPerDay = mealsPerDay
      ..skipsBreakfast = skipsBreakfast
      ..eatingOut = eatingOut
      ..weakMoments = Set.of(weakMoments)
      ..dietStyle = dietStyle
      ..dislikedFoods = dislikedFoods;
  }

  /// Cevaplanmış her alanı [prefs]'e yazar; boş/atlanmış alanların anahtarı
  /// yazılmaz (varsa silinir). `onboarding_step` / `onboarding_completed`
  /// akış tarafından yönetilir.
  void applyToPreferences(Map<String, dynamic> prefs) {
    void put(String key, Object? value) {
      final isEmpty = value == null ||
          (value is String && value.isEmpty) ||
          (value is List && value.isEmpty);
      if (isEmpty) {
        prefs.remove(key);
      } else {
        prefs[key] = value;
      }
    }

    put('sex', sex);

    if (goalType == null) {
      prefs.remove('goal');
    } else {
      prefs['goal'] = <String, dynamic>{
        'type': goalType,
        if (goalNeedsDetails && targetWeightKg != null)
          'target_weight_kg': targetWeightKg,
        if (goalNeedsDetails && pace != null) 'pace': pace,
      };
    }

    put('conditions', conditions.toList());
    put('conditions_other',
        conditions.contains('other') ? conditionsOther.trim() : '');
    put('medications', medications.trim());
    put('allergies', allergies.toList());
    put('allergies_other',
        allergies.contains('other') ? allergiesOther.trim() : '');
    put('activity_level', activityLevel);
    put('water_glasses', waterGlasses);
    put('sleep_hours', sleepHours);
    put('smoking', smoking);
    put('alcohol', alcohol);
    put('meals_per_day', mealsPerDay);
    put('skips_breakfast', skipsBreakfast);
    put('eating_out', eatingOut);
    put('weak_moments', weakMoments.toList());
    put('diet_style', dietStyle);
    put('disliked_foods', dislikedFoods.trim());
  }

  // ---- DB'deki okunur TR özetler (Edge Function bağlamı) ----

  static const Map<String, String> _conditionsTr = {
    'diabetes': 'diyabet',
    'insulin_resistance': 'insülin direnci',
    'hypertension': 'yüksek tansiyon',
    'thyroid': 'tiroid',
    'cholesterol': 'kolesterol',
  };

  static const Map<String, String> _allergiesTr = {
    'gluten': 'gluten',
    'lactose': 'laktoz',
    'nuts': 'fındık/fıstık',
    'seafood': 'deniz ürünleri',
    'egg': 'yumurta',
  };

  static const Map<String, String> _goalTr = {
    'lose': 'kilo vermek',
    'gain': 'kilo almak',
    'maintain': 'kilomu korumak',
    'healthy': 'sadece sağlıklı beslenmek',
  };

  static const Map<String, String> _paceTr = {
    'slow': 'yavaş ve sürdürülebilir',
    'balanced': 'dengeli',
    'fast': 'hızlı',
  };

  static String _trimNum(num v) =>
      v % 1 == 0 ? v.toInt().toString() : v.toString();

  /// Örn. "kilo vermek — hedef 70 kg, dengeli tempo".
  String? goalSummaryTr() {
    final type = goalType;
    if (type == null) return null;
    final buffer = StringBuffer(_goalTr[type] ?? type);
    if (goalNeedsDetails) {
      final parts = <String>[
        if (targetWeightKg != null) 'hedef ${_trimNum(targetWeightKg!)} kg',
        if (pace != null) '${_paceTr[pace] ?? pace} tempo',
      ];
      if (parts.isNotEmpty) buffer.write(' — ${parts.join(', ')}');
    }
    return buffer.toString();
  }

  /// Örn. "Kronik durumlar: diyabet, tiroid. Düzenli ilaç: metformin."
  String healthSummaryTr() {
    final parts = <String>[];
    if (conditions.contains('none') || conditions.isEmpty) {
      parts.add('Kronik rahatsızlık yok');
    } else {
      final names = [
        for (final c in conditions)
          if (_conditionsTr.containsKey(c)) _conditionsTr[c]!,
        if (conditions.contains('other') && conditionsOther.trim().isNotEmpty)
          conditionsOther.trim(),
      ];
      parts.add('Kronik durumlar: ${names.join(', ')}');
    }
    final meds = medications.trim();
    parts.add(
        meds.isEmpty ? 'Düzenli ilaç belirtilmedi' : 'Düzenli ilaç: $meds');
    return '${parts.join('. ')}.';
  }

  /// Örn. "Alerji/intolerans: gluten, laktoz." — "yok" cevabı da yazılır.
  String allergySummaryTr() {
    if (allergies.contains('none')) return 'Bilinen alerji/intolerans yok.';
    final names = [
      for (final a in allergies)
        if (_allergiesTr.containsKey(a)) _allergiesTr[a]!,
      if (allergies.contains('other') && allergiesOther.trim().isNotEmpty)
        allergiesOther.trim(),
    ];
    if (names.isEmpty) return 'Bilinen alerji/intolerans yok.';
    return 'Alerji/intolerans: ${names.join(', ')}.';
  }
}
