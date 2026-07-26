import 'package:flutter/material.dart';
import '../../config/app_theme.dart';
import '../../l10n/app_localizations.dart';
import 'onboarding_data.dart';
import 'onboarding_widgets.dart';

/// Adım İÇERİKLERİ (soru + inputlar). Sayfa iskeleti — üst bar, ilerleme
/// çubuğu, alt buton, kaydetme — `onboarding_flow.dart`'ta. Text
/// controller'lar da akışta yaşar; buradaki widget'lar durumsuzdur, seçim
/// değişikliklerini [OnboardingData]'ya yazıp `onChanged` ile akışa bildirir.

// ---- 0) Karanlık giriş sekansı: onboarding_intro.dart (F-5b) ----

// ---- 1) Kimlik ----

class OnbIdentityContent extends StatelessWidget {
  const OnbIdentityContent({
    super.key,
    required this.data,
    required this.nameController,
    required this.ageController,
    required this.onChanged,
  });

  final OnboardingData data;
  final TextEditingController nameController;
  final TextEditingController ageController;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        OnbStepHeader(title: l10n.onbIdentityTitle, why: l10n.onbIdentityWhy),
        const SizedBox(height: 28),
        OnbTextField(
          controller: nameController,
          label: l10n.onbNameLabel,
          textCapitalization: TextCapitalization.words,
        ),
        const SizedBox(height: 12),
        OnbTextField(
          controller: ageController,
          label: l10n.onbAgeLabel,
          keyboardType: TextInputType.number,
        ),
        OnbSectionLabel(label: l10n.onbSexLabel),
        OnbChipGroup(
          options: [
            ('female', l10n.onbSexFemale),
            ('male', l10n.onbSexMale),
            ('unspecified', l10n.onbSexUnspecified),
          ],
          selected: data.sex,
          onSelected: (v) {
            data.sex = v;
            onChanged();
          },
        ),
      ],
    );
  }
}

// ---- 2) Vücut ----

class OnbBodyContent extends StatelessWidget {
  const OnbBodyContent({
    super.key,
    required this.heightController,
    required this.weightController,
    this.waistController,
    this.hipController,
  });

  final TextEditingController heightController;
  final TextEditingController weightController;

  /// Bel/kalça alanları yalnızca ikisi de verilirse gösterilir (onboarding).
  /// Profil sayfası vermez — bu ölçülerin düzenlenmesi İlerleme sayfasının
  /// işi olacak.
  final TextEditingController? waistController;
  final TextEditingController? hipController;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    const decimal = TextInputType.numberWithOptions(decimal: true);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        OnbStepHeader(title: l10n.onbBodyTitle, why: l10n.onbBodyWhy),
        const SizedBox(height: 28),
        Row(
          children: [
            Expanded(
              child: OnbTextField(
                controller: heightController,
                label: l10n.onbHeightLabel,
                keyboardType: decimal,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OnbTextField(
                controller: weightController,
                label: l10n.onbWeightLabel,
                keyboardType: decimal,
              ),
            ),
          ],
        ),
        if (waistController != null && hipController != null) ...[
          OnbSectionLabel(label: l10n.onbMeasurementsLabel),
          Text(
            l10n.onbMeasurementsHint,
            style: const TextStyle(
              fontSize: 13.5,
              height: 1.4,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OnbTextField(
                  controller: waistController!,
                  label: l10n.onbWaistLabel,
                  keyboardType: decimal,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OnbTextField(
                  controller: hipController!,
                  label: l10n.onbHipLabel,
                  keyboardType: decimal,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

// ---- 3) Hedef ----

class OnbGoalContent extends StatelessWidget {
  const OnbGoalContent({
    super.key,
    required this.data,
    required this.targetWeightController,
    required this.onChanged,
  });

  final OnboardingData data;
  final TextEditingController targetWeightController;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final goals = [
      ('lose', '📉', l10n.onbGoalLose),
      ('gain', '📈', l10n.onbGoalGain),
      ('maintain', '⚖️', l10n.onbGoalMaintain),
      ('healthy', '🥗', l10n.onbGoalHealthy),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        OnbStepHeader(title: l10n.onbGoalTitle, why: l10n.onbGoalWhy),
        const SizedBox(height: 28),
        for (final (value, emoji, label) in goals)
          OnbSelectCard(
            label: label,
            emoji: emoji,
            selected: data.goalType == value,
            onTap: () {
              data.goalType = value;
              onChanged();
            },
          ),
        if (data.goalNeedsDetails) ...[
          const SizedBox(height: 6),
          OnbTextField(
            controller: targetWeightController,
            label: l10n.onbTargetWeightLabel,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
          ),
          OnbSectionLabel(label: l10n.onbPaceLabel),
          OnbChipGroup(
            options: [
              ('slow', l10n.onbPaceSlow),
              ('balanced', l10n.onbPaceBalanced),
              ('fast', l10n.onbPaceFast),
            ],
            selected: data.pace,
            onSelected: (v) {
              data.pace = v;
              onChanged();
            },
          ),
        ],
      ],
    );
  }
}

// ---- 4) Sağlık ----

class OnbHealthContent extends StatelessWidget {
  const OnbHealthContent({
    super.key,
    required this.data,
    required this.conditionsOtherController,
    required this.medicationsController,
    required this.allergiesOtherController,
    required this.onChanged,
  });

  final OnboardingData data;
  final TextEditingController conditionsOtherController;
  final TextEditingController medicationsController;
  final TextEditingController allergiesOtherController;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        OnbStepHeader(title: l10n.onbHealthTitle, why: l10n.onbHealthWhy),
        OnbSectionLabel(label: l10n.onbConditionsLabel),
        OnbMultiChipGroup(
          options: [
            ('diabetes', l10n.onbConditionDiabetes),
            ('insulin_resistance', l10n.onbConditionInsulinResistance),
            ('hypertension', l10n.onbConditionHypertension),
            ('thyroid', l10n.onbConditionThyroid),
            ('cholesterol', l10n.onbConditionCholesterol),
            ('other', l10n.onbOptionOther),
            ('none', l10n.onbOptionNone),
          ],
          values: data.conditions,
          exclusiveValue: 'none',
          onChanged: (values) {
            data.conditions = values;
            onChanged();
          },
        ),
        if (data.conditions.contains('other')) ...[
          const SizedBox(height: 12),
          OnbTextField(
            controller: conditionsOtherController,
            label: l10n.onbConditionsOtherLabel,
          ),
        ],
        const SizedBox(height: 16),
        OnbTextField(
          controller: medicationsController,
          label: l10n.onbMedicationsLabel,
        ),
        OnbSectionLabel(label: l10n.onbAllergiesLabel),
        OnbMultiChipGroup(
          options: [
            ('gluten', l10n.onbAllergyGluten),
            ('lactose', l10n.onbAllergyLactose),
            ('nuts', l10n.onbAllergyNuts),
            ('seafood', l10n.onbAllergySeafood),
            ('egg', l10n.onbAllergyEgg),
            ('other', l10n.onbOptionOther),
            ('none', l10n.onbOptionNone),
          ],
          values: data.allergies,
          exclusiveValue: 'none',
          onChanged: (values) {
            data.allergies = values;
            onChanged();
          },
        ),
        if (data.allergies.contains('other')) ...[
          const SizedBox(height: 12),
          OnbTextField(
            controller: allergiesOtherController,
            label: l10n.onbAllergiesOtherLabel,
          ),
        ],
      ],
    );
  }
}

// ---- 5) Yaşam tarzı ----

class OnbLifestyleContent extends StatelessWidget {
  const OnbLifestyleContent({
    super.key,
    required this.data,
    required this.onChanged,
  });

  final OnboardingData data;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final activities = [
      ('sedentary', l10n.onbActivitySedentary),
      ('light', l10n.onbActivityLight),
      ('moderate', l10n.onbActivityModerate),
      ('active', l10n.onbActivityActive),
      ('very_active', l10n.onbActivityVeryActive),
    ];
    final habitOptions = [
      ('none', l10n.onbOptionNone),
      ('occasional', l10n.onbHabitOccasional),
      ('regular', l10n.onbHabitRegular),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        OnbStepHeader(title: l10n.onbLifestyleTitle, why: l10n.onbLifestyleWhy),
        OnbSectionLabel(label: l10n.onbActivityLabel),
        for (final (value, label) in activities)
          OnbSelectCard(
            label: label,
            dense: true,
            selected: data.activityLevel == value,
            onTap: () {
              data.activityLevel = value;
              onChanged();
            },
          ),
        OnbSectionLabel(label: l10n.onbWaterLabel),
        OnbChipGroup(
          options: const [
            ('0-2', '0-2'),
            ('3-5', '3-5'),
            ('6-8', '6-8'),
            ('8+', '8+'),
          ],
          selected: data.waterGlasses,
          onSelected: (v) {
            data.waterGlasses = v;
            onChanged();
          },
        ),
        OnbSectionLabel(label: l10n.onbSleepLabel),
        OnbChipGroup(
          options: [
            ('<5', l10n.onbSleepLt5),
            ('5-6', l10n.onbSleep5to6),
            ('7-8', l10n.onbSleep7to8),
            ('8+', l10n.onbSleep8plus),
          ],
          selected: data.sleepHours,
          onSelected: (v) {
            data.sleepHours = v;
            onChanged();
          },
        ),
        OnbSectionLabel(label: l10n.onbSmokingLabel),
        OnbChipGroup(
          options: habitOptions,
          selected: data.smoking,
          onSelected: (v) {
            data.smoking = v;
            onChanged();
          },
        ),
        OnbSectionLabel(label: l10n.onbAlcoholLabel),
        OnbChipGroup(
          options: habitOptions,
          selected: data.alcohol,
          onSelected: (v) {
            data.alcohol = v;
            onChanged();
          },
        ),
      ],
    );
  }
}

// ---- 6) Alışkanlıklar ----

class OnbHabitsContent extends StatelessWidget {
  const OnbHabitsContent({
    super.key,
    required this.data,
    required this.onChanged,
  });

  final OnboardingData data;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        OnbStepHeader(title: l10n.onbHabitsTitle, why: l10n.onbHabitsWhy),
        OnbSectionLabel(label: l10n.onbMealsLabel),
        OnbChipGroup(
          options: const [('2', '2'), ('3', '3'), ('4+', '4+')],
          selected: data.mealsPerDay,
          onSelected: (v) {
            data.mealsPerDay = v;
            onChanged();
          },
        ),
        OnbSectionLabel(label: l10n.onbBreakfastLabel),
        OnbChipGroup(
          options: [
            ('never', l10n.onbBreakfastNever),
            ('sometimes', l10n.onbBreakfastSometimes),
            ('often', l10n.onbBreakfastOften),
          ],
          selected: data.skipsBreakfast,
          onSelected: (v) {
            data.skipsBreakfast = v;
            onChanged();
          },
        ),
        OnbSectionLabel(label: l10n.onbEatingOutLabel),
        OnbChipGroup(
          options: [
            ('rarely', l10n.onbEatingOutRarely),
            ('1-2_per_week', l10n.onbEatingOutWeekly12),
            ('3+_per_week', l10n.onbEatingOutWeekly3plus),
            ('daily', l10n.onbEatingOutDaily),
          ],
          selected: data.eatingOut,
          onSelected: (v) {
            data.eatingOut = v;
            onChanged();
          },
        ),
        OnbSectionLabel(label: l10n.onbWeakMomentsLabel),
        OnbMultiChipGroup(
          // Değerler emergency_page.dart'taki trigger_type ile birebir aynı.
          options: [
            ('night_snacking', l10n.onbWeakNightSnacking),
            ('sweet_craving', l10n.onbWeakSweetCraving),
            ('hunger_between_meals', l10n.onbWeakHungerBetweenMeals),
            ('stress_eating', l10n.onbWeakStressEating),
            ('none', l10n.onbOptionNone),
          ],
          values: data.weakMoments,
          exclusiveValue: 'none',
          onChanged: (values) {
            data.weakMoments = values;
            onChanged();
          },
        ),
      ],
    );
  }
}

// ---- 7) Tercihler ----

class OnbPrefsContent extends StatelessWidget {
  const OnbPrefsContent({
    super.key,
    required this.data,
    required this.dislikedController,
    required this.onChanged,
  });

  final OnboardingData data;
  final TextEditingController dislikedController;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        OnbStepHeader(title: l10n.onbPrefsTitle, why: l10n.onbPrefsWhy),
        OnbSectionLabel(label: l10n.onbDietStyleLabel),
        OnbChipGroup(
          options: [
            ('omnivore', l10n.onbDietOmnivore),
            ('vegetarian', l10n.onbDietVegetarian),
            ('vegan', l10n.onbDietVegan),
          ],
          selected: data.dietStyle,
          onSelected: (v) {
            data.dietStyle = v;
            onChanged();
          },
        ),
        OnbSectionLabel(label: l10n.onbDislikedLabel),
        OnbTextField(
          controller: dislikedController,
          label: l10n.onbDislikedFieldLabel,
          hint: l10n.onbDislikedHint,
          maxLines: 2,
        ),
      ],
    );
  }
}

// ---- 8) Özet ----

class OnbSummaryContent extends StatelessWidget {
  const OnbSummaryContent({super.key, required this.data});

  final OnboardingData data;

  static String _trimNum(num v) =>
      v % 1 == 0 ? v.toInt().toString() : v.toString();

  String _goalText(AppLocalizations l10n) {
    final labels = {
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
    final parts = <String>[
      if (data.goalType != null) labels[data.goalType] ?? data.goalType!,
      if (data.goalNeedsDetails && data.targetWeightKg != null)
        '${_trimNum(data.targetWeightKg!)} kg',
      if (data.goalNeedsDetails && data.pace != null)
        paceLabels[data.pace] ?? data.pace!,
    ];
    return parts.join(' · ');
  }

  String _allergyText(AppLocalizations l10n) {
    if (data.allergies.contains('none')) return l10n.onbOptionNone;
    final labels = {
      'gluten': l10n.onbAllergyGluten,
      'lactose': l10n.onbAllergyLactose,
      'nuts': l10n.onbAllergyNuts,
      'seafood': l10n.onbAllergySeafood,
      'egg': l10n.onbAllergyEgg,
    };
    final parts = <String>[
      for (final a in data.allergies)
        if (labels.containsKey(a)) labels[a]!,
      if (data.allergies.contains('other') &&
          data.allergiesOther.trim().isNotEmpty)
        data.allergiesOther.trim(),
    ];
    return parts.isEmpty ? l10n.onbOptionNone : parts.join(', ');
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.text,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final body = [
      if (data.heightCm != null) '${_trimNum(data.heightCm!)} cm',
      if (data.weightKg != null) '${_trimNum(data.weightKg!)} kg',
    ].join(' · ');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        OnbStepHeader(
            title: l10n.onbSummaryTitle, why: l10n.onbSummarySubtitle),
        const SizedBox(height: 28),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 6),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(20),
            boxShadow: onbSoftShadow,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (data.name.isNotEmpty) _row(l10n.onbSummaryName, data.name),
              if (data.age != null)
                _row(l10n.onbSummaryAge, data.age.toString()),
              if (body.isNotEmpty) _row(l10n.onbSummaryBody, body),
              if (data.goalType != null)
                _row(l10n.onbSummaryGoal, _goalText(l10n)),
            ],
          ),
        ),
        const SizedBox(height: 12),
        // Alerjiler güvenlik açısından kritik — ayrı vurgulu kutu.
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.primaryContainer,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.health_and_safety_outlined,
                size: 22,
                color: AppColors.onPrimaryContainer,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.onbSummaryAllergies,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.onPrimaryContainer,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      _allergyText(l10n),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.onPrimaryContainer,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
