// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Diet App';

  @override
  String get tabDietPlan => 'Diet Plan';

  @override
  String get tabFoodTracking => 'Food Tracking';

  @override
  String get tabProgress => 'Progress';

  @override
  String get tabAiChat => 'AI Chat';

  @override
  String get tabDietitian => 'Dietitian';

  @override
  String get navEmergency => 'Emergency Support';

  @override
  String get pgHeaderEyebrow => 'Your journey';

  @override
  String get chatHeaderEyebrow => 'Always here';

  @override
  String get profileHeaderEyebrow => 'Your account';

  @override
  String get authWelcomeBack => 'Welcome back';

  @override
  String get authCreateAccount => 'Create an account';

  @override
  String get authLoginSubtitle => 'Sign in to continue.';

  @override
  String get authSignupSubtitle =>
      'It only takes a few seconds to get started.';

  @override
  String get authEmailLabel => 'Email';

  @override
  String get authPasswordLabel => 'Password';

  @override
  String get authEmailRequired => 'Email is required';

  @override
  String get authEmailInvalid => 'Enter a valid email';

  @override
  String get authPasswordRequired => 'Password is required';

  @override
  String get authPasswordTooShort => 'Password must be at least 6 characters';

  @override
  String get authPasswordHelper => 'At least 6 characters';

  @override
  String get authLoginButton => 'Sign in';

  @override
  String get authSignupButton => 'Sign up';

  @override
  String get authToggleToSignup => 'Don\'t have an account? Sign up';

  @override
  String get authToggleToLogin => 'Already have an account? Sign in';

  @override
  String get authSignupSuccess =>
      'Registration successful. Click the verification link sent to your email, then sign in.';

  @override
  String get connectionError =>
      'Connection error. Check your internet connection and try again.';

  @override
  String unexpectedError(String error) {
    return 'An unexpected error occurred: $error';
  }

  @override
  String get commonSave => 'Save';

  @override
  String get commonCancel => 'Cancel';

  @override
  String get commonClose => 'Close';

  @override
  String get commonRetry => 'Try again';

  @override
  String get commonLoading => 'Loading...';

  @override
  String get commonDelete => 'Delete';

  @override
  String get commonNext => 'Continue';

  @override
  String get commonSkip => 'Skip';

  @override
  String get languageTooltip => 'Language';

  @override
  String get languageTurkish => 'Türkçe';

  @override
  String get languageEnglish => 'English';

  @override
  String onbStepCounter(int step) {
    return 'Step $step/8';
  }

  @override
  String get onbNext => 'Continue';

  @override
  String get onbBackTooltip => 'Back';

  @override
  String get onbExitTooltip => 'Exit';

  @override
  String get onbResumeToast => 'Picking up where you left off 👋';

  @override
  String get onbSessionLost => 'Session not found. Please sign in again.';

  @override
  String onbSaveFailed(String message) {
    return 'Couldn\'t save: $message';
  }

  @override
  String get onbWelcomeStart => 'Start';

  @override
  String get introLine1 => 'Hello.';

  @override
  String get introLine2 => 'From now on, I\'m with you on this journey.';

  @override
  String get introLine3 =>
      'First, I\'d like to get to know you — just 2 minutes. Ready when you are.';

  @override
  String get introTapHint => 'tap to continue';

  @override
  String get onbIdentityTitle => 'Tell us about yourself';

  @override
  String get onbIdentityWhy =>
      'Your age and sex help us calculate your daily energy needs accurately.';

  @override
  String get onbNameLabel => 'Your name';

  @override
  String get onbAgeLabel => 'Your age';

  @override
  String get onbSexLabel => 'Sex';

  @override
  String get onbSexFemale => 'Female';

  @override
  String get onbSexMale => 'Male';

  @override
  String get onbSexUnspecified => 'Prefer not to say';

  @override
  String get onbBodyTitle => 'Your body measurements';

  @override
  String get onbBodyWhy =>
      'Your height and weight are the foundation for setting the right calorie target.';

  @override
  String get onbHeightLabel => 'Height (cm)';

  @override
  String get onbWeightLabel => 'Weight (kg)';

  @override
  String get onbMeasurementsLabel => 'Waist and hip (optional)';

  @override
  String get onbMeasurementsHint =>
      'No tape measure? You can skip these — if you add them, they make a great starting point for tracking progress.';

  @override
  String get onbWaistLabel => 'Waist (cm)';

  @override
  String get onbHipLabel => 'Hip (cm)';

  @override
  String get onbGoalTitle => 'What\'s your goal?';

  @override
  String get onbGoalWhy =>
      'We\'ll shape your plan and suggestions entirely around this goal.';

  @override
  String get onbGoalLose => 'Lose weight';

  @override
  String get onbGoalGain => 'Gain weight';

  @override
  String get onbGoalMaintain => 'Maintain my weight';

  @override
  String get onbGoalHealthy => 'Just eat healthy';

  @override
  String get onbTargetWeightLabel => 'Target weight (kg, optional)';

  @override
  String get onbPaceLabel => 'What pace would you like?';

  @override
  String get onbPaceSlow => 'Slow and sustainable';

  @override
  String get onbPaceBalanced => 'Balanced';

  @override
  String get onbPaceFast => 'Fast';

  @override
  String get onbHealthTitle => 'Your health';

  @override
  String get onbHealthWhy =>
      'Chronic conditions and allergies are the most important details for keeping your plan safe.';

  @override
  String get onbConditionsLabel => 'Do you have any chronic conditions?';

  @override
  String get onbConditionDiabetes => 'Diabetes';

  @override
  String get onbConditionInsulinResistance => 'Insulin resistance';

  @override
  String get onbConditionHypertension => 'High blood pressure';

  @override
  String get onbConditionThyroid => 'Thyroid';

  @override
  String get onbConditionCholesterol => 'Cholesterol';

  @override
  String get onbOptionOther => 'Other';

  @override
  String get onbOptionNone => 'None';

  @override
  String get onbConditionsOtherLabel => 'Could you describe it?';

  @override
  String get onbMedicationsLabel => 'Regular medication (optional)';

  @override
  String get onbAllergiesLabel => 'Any allergies or intolerances?';

  @override
  String get onbAllergyGluten => 'Gluten';

  @override
  String get onbAllergyLactose => 'Lactose';

  @override
  String get onbAllergyNuts => 'Nuts / peanuts';

  @override
  String get onbAllergySeafood => 'Seafood';

  @override
  String get onbAllergyEgg => 'Egg';

  @override
  String get onbAllergiesOtherLabel => 'Could you list them?';

  @override
  String get onbLifestyleTitle => 'Your lifestyle';

  @override
  String get onbLifestyleWhy =>
      'How much you move and your daily habits directly affect your calorie needs.';

  @override
  String get onbActivityLabel => 'Activity level';

  @override
  String get onbActivitySedentary => 'Desk job — sedentary';

  @override
  String get onbActivityLight => 'Lightly active';

  @override
  String get onbActivityModerate => 'Moderate';

  @override
  String get onbActivityActive => 'Active';

  @override
  String get onbActivityVeryActive => 'Very active';

  @override
  String get onbWaterLabel => 'How many glasses of water per day?';

  @override
  String get onbSleepLabel => 'Sleep (optional)';

  @override
  String get onbSleepLt5 => 'Less than 5 hours';

  @override
  String get onbSleep5to6 => '5-6 hours';

  @override
  String get onbSleep7to8 => '7-8 hours';

  @override
  String get onbSleep8plus => 'More than 8 hours';

  @override
  String get onbSmokingLabel => 'Smoking (optional)';

  @override
  String get onbAlcoholLabel => 'Alcohol (optional)';

  @override
  String get onbHabitOccasional => 'Occasionally';

  @override
  String get onbHabitRegular => 'Regularly';

  @override
  String get onbHabitsTitle => 'Your eating habits';

  @override
  String get onbHabitsWhy =>
      'Knowing your real routine helps the plan fit your life much more easily.';

  @override
  String get onbMealsLabel => 'How many meals a day?';

  @override
  String get onbBreakfastLabel => 'Do you skip breakfast?';

  @override
  String get onbBreakfastNever => 'Never';

  @override
  String get onbBreakfastSometimes => 'Sometimes';

  @override
  String get onbBreakfastOften => 'Most days';

  @override
  String get onbEatingOutLabel => 'How often do you eat out or order in?';

  @override
  String get onbEatingOutRarely => 'Rarely';

  @override
  String get onbEatingOutWeekly12 => '1-2 times a week';

  @override
  String get onbEatingOutWeekly3plus => '3+ times a week';

  @override
  String get onbEatingOutDaily => 'Every day';

  @override
  String get onbWeakMomentsLabel => 'What are your weak moments?';

  @override
  String get onbWeakNightSnacking => 'Night snacking';

  @override
  String get onbWeakSweetCraving => 'Sweet cravings';

  @override
  String get onbWeakHungerBetweenMeals => 'Hunger between meals';

  @override
  String get onbWeakStressEating => 'Stress eating';

  @override
  String get onbPrefsTitle => 'Your food preferences';

  @override
  String get onbPrefsWhy =>
      'Let\'s keep foods you dislike out of your plan — that\'s where sustainability starts.';

  @override
  String get onbDietStyleLabel => 'Diet style';

  @override
  String get onbDietOmnivore => 'Omnivore';

  @override
  String get onbDietVegetarian => 'Vegetarian';

  @override
  String get onbDietVegan => 'Vegan';

  @override
  String get onbDislikedLabel => 'Foods you dislike (optional)';

  @override
  String get onbDislikedFieldLabel => 'Foods you\'d rather avoid';

  @override
  String get onbDislikedHint => 'E.g. broccoli, offal, mushrooms...';

  @override
  String get onbSummaryTitle => 'Your profile is ready 🎉';

  @override
  String get onbSummarySubtitle =>
      'Here\'s what you told us. You can update these anytime from your profile.';

  @override
  String get onbSummaryName => 'Name';

  @override
  String get onbSummaryAge => 'Age';

  @override
  String get onbSummaryBody => 'Height / Weight';

  @override
  String get onbSummaryGoal => 'Goal';

  @override
  String get onbSummaryAllergies => 'Allergies / intolerances';

  @override
  String get onbSummaryStart => 'Let\'s begin';

  @override
  String get onbSummaryCreatePlan => 'Create my first plan';

  @override
  String get profTitle => 'Profile';

  @override
  String get profNotFilled => 'Not filled in yet';

  @override
  String get profSaved => 'Saved ✓';

  @override
  String profLoadFailed(String message) {
    return 'Couldn\'t load profile: $message';
  }

  @override
  String profAgeValue(int age) {
    return 'age $age';
  }

  @override
  String get profSectionIdentity => 'Personal info';

  @override
  String get profSectionBody => 'Body';

  @override
  String get profSectionGoal => 'Goal';

  @override
  String get profSectionHealth => 'Health';

  @override
  String get profSectionLifestyle => 'Lifestyle';

  @override
  String get profSectionHabits => 'Habits';

  @override
  String get profSectionPrefs => 'Preferences';

  @override
  String get profSectionAccount => 'Account';

  @override
  String get profConditionsShort => 'Conditions';

  @override
  String get profAllergiesShort => 'Allergies';

  @override
  String get profMedicationsShort => 'Medication';

  @override
  String get profWaterShort => 'Water';

  @override
  String get profSleepShort => 'Sleep';

  @override
  String get profSmokingShort => 'Smoking';

  @override
  String get profAlcoholShort => 'Alcohol';

  @override
  String get profMealsShort => 'Meals';

  @override
  String get profBreakfastShort => 'Skipping breakfast';

  @override
  String get profEatingOutShort => 'Eating out';

  @override
  String get profWeakShort => 'Weak moments';

  @override
  String get profDislikedShort => 'Dislikes';

  @override
  String get profBodyNote =>
      'Weight tracking lives on the Progress page — enter your current weight here. Waist/hip measurements will be updated there too.';

  @override
  String get profEmailLabel => 'Email';

  @override
  String get profChangePassword => 'Change password';

  @override
  String get profNewPasswordLabel => 'New password';

  @override
  String get profNewPasswordRepeatLabel => 'New password (repeat)';

  @override
  String get profPasswordMismatch => 'Passwords don\'t match';

  @override
  String get profPasswordChanged => 'Password updated ✓';

  @override
  String get profLanguageLabel => 'Language';

  @override
  String get profSignOut => 'Sign out';

  @override
  String get profSignOutConfirm => 'Are you sure you want to sign out?';

  @override
  String get dietPlanTitle => 'Diet Plan';

  @override
  String get dpMenuTooltip => 'Plan options';

  @override
  String get dpMenuRevise => 'Revise plan';

  @override
  String get dpMenuRegenerate => 'New plan from scratch';

  @override
  String get dpRegenerateConfirm =>
      'Your current plan will be completely replaced with a new one and 1 of your daily AI credits will be used. Do you want to continue?';

  @override
  String get dpRegenerateContinue => 'Continue';

  @override
  String get dpKcalPerDay => 'kcal/day';

  @override
  String get dpMacroCarb => 'Carbs';

  @override
  String get dpMacroProtein => 'Protein';

  @override
  String get dpMacroFat => 'Fat';

  @override
  String get dayShortMon => 'Mon';

  @override
  String get dayShortTue => 'Tue';

  @override
  String get dayShortWed => 'Wed';

  @override
  String get dayShortThu => 'Thu';

  @override
  String get dayShortFri => 'Fri';

  @override
  String get dayShortSat => 'Sat';

  @override
  String get dayShortSun => 'Sun';

  @override
  String get dpMealBreakfast => 'Breakfast';

  @override
  String get dpMealLunch => 'Lunch';

  @override
  String get dpMealDinner => 'Dinner';

  @override
  String get dpMealSnack => 'Snack';

  @override
  String get dpMealDefault => 'Meal';

  @override
  String get dpEmptyMessage =>
      'You don\'t have a diet plan yet.\nLet\'s create your first personalized plan.';

  @override
  String get dpCreateFirstPlan => 'Create my first plan';

  @override
  String get dpNoMealsForDay => 'No meals found for this day.';

  @override
  String get dpRevisePrompt => 'Select what you\'re not happy with:';

  @override
  String get dpReasonDisliked => 'I didn\'t like it';

  @override
  String get dpReasonHardToPrepare => 'Hard to prepare';

  @override
  String get dpReasonIngredientsUnavailable => 'I can\'t find the ingredients';

  @override
  String get dpReviseNoteLabel => 'Note (optional)';

  @override
  String get dpReviseNoteHint => 'E.g. I don\'t want fish in the evenings';

  @override
  String get dpReviseValidation =>
      'Select at least one reason or write a note.';

  @override
  String get dpReviseSubmit => 'Send';

  @override
  String get ftTitle => 'Food Tracking';

  @override
  String get ftToday => 'Today';

  @override
  String get ftYesterday => 'Yesterday';

  @override
  String get ftWaterTitle => 'Water Tracking';

  @override
  String ftGlasses(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count glasses',
      one: '1 glass',
    );
    return '$_temp0';
  }

  @override
  String get ftMealBreakfast => 'Breakfast';

  @override
  String get ftMealLunch => 'Lunch';

  @override
  String get ftMealDinner => 'Dinner';

  @override
  String get ftMealSnack => 'Snack';

  @override
  String get ftEmptyDay => 'No food logged for this day yet.';

  @override
  String get ftEmptyCta => 'Add your first meal';

  @override
  String get ftAddTooltip => 'Add food';

  @override
  String get ftAddSheetTitle => 'Add Food';

  @override
  String get ftRecentLabel => 'Recently added';

  @override
  String get ftFoodName => 'Food name';

  @override
  String get ftCalories => 'Calories (kcal)';

  @override
  String get ftNameRequired => 'Food name is required';

  @override
  String get ftCaloriesRequired => 'Calories are required';

  @override
  String get ftCaloriesInvalid => 'Enter a valid calorie value';

  @override
  String get ftAdd => 'Add';

  @override
  String ftLoadError(String message) {
    return 'Couldn\'t load entries: $message';
  }

  @override
  String ftAddError(String message) {
    return 'Couldn\'t add: $message';
  }

  @override
  String ftDeleteError(String message) {
    return 'Couldn\'t delete: $message';
  }

  @override
  String ftWaterError(String message) {
    return 'Couldn\'t update water log: $message';
  }

  @override
  String get pgTitle => 'Progress';

  @override
  String get pgToday => 'Today';

  @override
  String get pgYesterday => 'Yesterday';

  @override
  String get pgHeroEmpty =>
      'No weight entries yet.\nStart your journey with a first measurement.';

  @override
  String get pgAddFirst => 'Add your first measurement';

  @override
  String pgJourneyRange(String start, String target) {
    return 'Start $start kg → goal $target kg';
  }

  @override
  String pgToGoal(String kg) {
    return '$kg kg to your goal';
  }

  @override
  String get pgGoalReached => 'You reached your goal 🎉';

  @override
  String pgTotalChange(String change) {
    return '$change since you started';
  }

  @override
  String get pgMeasurementsTitle => 'Body Measurements';

  @override
  String get pgWaist => 'Waist';

  @override
  String get pgHip => 'Hip';

  @override
  String get pgMeasurementsEmpty => 'No waist/hip measurements yet.';

  @override
  String get pgMeasurementsCta => 'Add measurement';

  @override
  String get pgWeightChart => 'Weight';

  @override
  String get pgCaloriesChart => 'Calories';

  @override
  String get pgWaterChart => 'Water (glasses)';

  @override
  String get pgLast30Days => 'Last 30 days';

  @override
  String get pgLast7Days => 'Last 7 days';

  @override
  String get pgWeightEmpty =>
      'At least 2 weight entries are needed for the chart.\nAdd a measurement with the + button below.';

  @override
  String get pgCaloriesEmpty =>
      'No food logged in the last 7 days.\nYou can add some from the Food Tracking tab.';

  @override
  String get pgWaterEmpty =>
      'No water logged in the last 7 days.\nYou can add some from the Food Tracking tab.';

  @override
  String get pgAddTooltip => 'Add measurement';

  @override
  String get pgSheetTitle => 'Add Measurement';

  @override
  String get pgWeightField => 'Weight (kg)';

  @override
  String get pgWaistField => 'Waist (cm)';

  @override
  String get pgHipField => 'Hip (cm)';

  @override
  String get pgAtLeastOne => 'Fill in at least one field.';

  @override
  String get pgInvalidValue => 'Enter a valid value';

  @override
  String get pgDateLabel => 'Date';

  @override
  String get pgSaved => 'Saved ✓';

  @override
  String pgLoadError(String message) {
    return 'Couldn\'t load data: $message';
  }

  @override
  String pgSaveError(String message) {
    return 'Couldn\'t save: $message';
  }

  @override
  String get chatTitle => 'Advisor';

  @override
  String get chatWelcome =>
      'Hi! I\'m your nutrition and diet advisor. I can answer your questions about nutrition, diet, or healthy living.';

  @override
  String get chatHint => 'Ask a question...';

  @override
  String get chatSendTooltip => 'Send';

  @override
  String get chatMenuTooltip => 'Chat options';

  @override
  String get chatMenuClear => 'Clear chat';

  @override
  String get chatClearConfirmTitle => 'Clear chat';

  @override
  String get chatClearConfirmBody =>
      'Your entire chat history will be deleted and the advisor won\'t remember the previous conversation.';

  @override
  String get chatToday => 'Today';

  @override
  String get chatYesterday => 'Yesterday';

  @override
  String get chatTyping => 'Typing';

  @override
  String get chatLoadError => 'Couldn\'t load chat history.';

  @override
  String get chatErrorReply =>
      'Sorry, something went wrong while generating a response. Please try again.';

  @override
  String get dcTitle => 'Dietitian';

  @override
  String get dcTitleDietitian => 'Client';

  @override
  String get dcSubtitleUser => 'Your dietitian';

  @override
  String get dcSubtitleDietitian => 'Your client';

  @override
  String get dcToday => 'Today';

  @override
  String get dcYesterday => 'Yesterday';

  @override
  String get dcNoAssignTitle => 'No dietitian assigned yet';

  @override
  String get dcNoAssignBody =>
      'Once a dietitian is assigned to you, your conversation will start here.';

  @override
  String get dcNoClientTitle => 'No client assigned yet';

  @override
  String get dcNoClientBody =>
      'Once a client is assigned to you, your conversation will start here.';

  @override
  String get dcAskAi => 'Ask the Advisor for now';

  @override
  String get dcNoMessages => 'No messages yet.\nSend the first one!';

  @override
  String get dcHint => 'Type a message...';

  @override
  String get dcSendTooltip => 'Send';

  @override
  String dcLoadError(String message) {
    return 'Couldn\'t load: $message';
  }

  @override
  String dcSendError(String message) {
    return 'Couldn\'t send: $message';
  }

  @override
  String get emIntroLine1 => 'Okay. I\'m here.';

  @override
  String get emIntroLine2 => 'We\'ll get through this together.';

  @override
  String get emTriggerTitle => 'What happened?';

  @override
  String get emTriggerSubtitle =>
      'No judgment. Just pick what you\'re feeling right now — we\'ll ride it out together.';

  @override
  String get emTriggerNightSnacking => 'Late-night snacking urge';

  @override
  String get emTriggerSweetCraving => 'Sweet craving';

  @override
  String get emTriggerHungerBetweenMeals => 'Hunger between meals';

  @override
  String get emTriggerStressEating => 'Stress eating';

  @override
  String get emBreathTitle => 'First, take a breath';

  @override
  String get emBreathSubtitle =>
      'A craving is like a wave: it rises, and it passes. For 30 seconds, focus only on your breath.';

  @override
  String get emBreathInhale => 'Breathe in...';

  @override
  String get emBreathExhale => 'Breathe out...';

  @override
  String get emBreathDone => 'Wonderful. The wave is already getting smaller.';

  @override
  String get emWaterTitle => 'Drink a glass of water';

  @override
  String get emWaterSubtitle =>
      'Thirst often feels like hunger. Drink a glass of water and, if you like, try waiting 5 minutes — cravings usually ease in that time.';

  @override
  String get emWaterStartTimer => 'Start a 5-min timer';

  @override
  String get emWaterTimerDone =>
      'Time\'s up — if you\'re still here, you\'re doing great 👏';

  @override
  String get emAlternativesTitle => 'Want to try one of these?';

  @override
  String get emAlternativesSubtitle =>
      'Even a small change is enough to redirect a craving.';

  @override
  String get emAltNightSnacking1 =>
      'Brew a cup of herbal tea (chamomile or linden).';

  @override
  String get emAltNightSnacking2 =>
      'Brush your teeth — it cuts snacking urges surprisingly well.';

  @override
  String get emAltNightSnacking3 =>
      'Dim the lights and put the phone down; tell your body the day is over.';

  @override
  String get emAltSweetCraving1 =>
      'A handful of strawberries, blueberries, or a few apple slices.';

  @override
  String get emAltSweetCraving2 =>
      'One square of dark chocolate (70%+) — slowly, savoring it.';

  @override
  String get emAltSweetCraving3 =>
      'Yogurt with a sprinkle of cinnamon: feels sweet without feeding the craving.';

  @override
  String get emAltHungerBetweenMeals1 => 'A handful of raw almonds or walnuts.';

  @override
  String get emAltHungerBetweenMeals2 =>
      'Carrot or cucumber sticks — crunchy but light.';

  @override
  String get emAltHungerBetweenMeals3 =>
      'A glass of ayran or a small bowl of yogurt.';

  @override
  String get emAltStressEating1 =>
      'A short 5-minute walk — even just to the door counts.';

  @override
  String get emAltStressEating2 =>
      'Text someone you love a couple of lines; let the feeling out in words, not food.';

  @override
  String get emAltStressEating3 =>
      'Keep your hands busy: tidy a drawer, do the dishes, stretch.';

  @override
  String get emClosingTitle => 'It\'s your call';

  @override
  String get emClosingBody =>
      'If you still want it, that\'s okay — this isn\'t a battle of willpower. Just keep the portion small, sit down, and eat slowly. One moment won\'t erase all your effort.';

  @override
  String get emOutcomeTitle => 'How did it go?';

  @override
  String get emOutcomeSubtitle => 'Either way, showing up here matters.';

  @override
  String get emOutcomeOvercame => 'I got through it 💪';

  @override
  String get emOutcomeAteAnyway => 'I ate anyway — that\'s okay';

  @override
  String get emThanksTitle => 'Thank you 💚';

  @override
  String get emThanksBody =>
      'Pausing in a moment of crisis and coming here is a win in itself. Keep being kind to yourself — tomorrow is a new day.';
}
