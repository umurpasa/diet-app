import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_tr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('tr')
  ];

  /// No description provided for @appTitle.
  ///
  /// In tr, this message translates to:
  /// **'Diet App'**
  String get appTitle;

  /// No description provided for @tabDietPlan.
  ///
  /// In tr, this message translates to:
  /// **'Diyet Plan'**
  String get tabDietPlan;

  /// No description provided for @tabFoodTracking.
  ///
  /// In tr, this message translates to:
  /// **'Yemek Takibi'**
  String get tabFoodTracking;

  /// No description provided for @tabProgress.
  ///
  /// In tr, this message translates to:
  /// **'İlerleme'**
  String get tabProgress;

  /// No description provided for @tabAiChat.
  ///
  /// In tr, this message translates to:
  /// **'AI Sohbet'**
  String get tabAiChat;

  /// No description provided for @tabDietitian.
  ///
  /// In tr, this message translates to:
  /// **'Diyetisyen'**
  String get tabDietitian;

  /// No description provided for @navEmergency.
  ///
  /// In tr, this message translates to:
  /// **'Acil Destek'**
  String get navEmergency;

  /// No description provided for @pgHeaderEyebrow.
  ///
  /// In tr, this message translates to:
  /// **'Yolculuğun'**
  String get pgHeaderEyebrow;

  /// No description provided for @chatHeaderEyebrow.
  ///
  /// In tr, this message translates to:
  /// **'Her zaman burada'**
  String get chatHeaderEyebrow;

  /// No description provided for @profileHeaderEyebrow.
  ///
  /// In tr, this message translates to:
  /// **'Hesabın'**
  String get profileHeaderEyebrow;

  /// No description provided for @authWelcomeBack.
  ///
  /// In tr, this message translates to:
  /// **'Tekrar hoş geldin'**
  String get authWelcomeBack;

  /// No description provided for @authCreateAccount.
  ///
  /// In tr, this message translates to:
  /// **'Hesap oluştur'**
  String get authCreateAccount;

  /// No description provided for @authLoginSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Devam etmek için giriş yap.'**
  String get authLoginSubtitle;

  /// No description provided for @authSignupSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Başlamak için birkaç saniye yeter.'**
  String get authSignupSubtitle;

  /// No description provided for @authEmailLabel.
  ///
  /// In tr, this message translates to:
  /// **'E-posta'**
  String get authEmailLabel;

  /// No description provided for @authPasswordLabel.
  ///
  /// In tr, this message translates to:
  /// **'Şifre'**
  String get authPasswordLabel;

  /// No description provided for @authEmailRequired.
  ///
  /// In tr, this message translates to:
  /// **'E-posta gerekli'**
  String get authEmailRequired;

  /// No description provided for @authEmailInvalid.
  ///
  /// In tr, this message translates to:
  /// **'Geçerli bir e-posta gir'**
  String get authEmailInvalid;

  /// No description provided for @authPasswordRequired.
  ///
  /// In tr, this message translates to:
  /// **'Şifre gerekli'**
  String get authPasswordRequired;

  /// No description provided for @authPasswordTooShort.
  ///
  /// In tr, this message translates to:
  /// **'Şifre en az 6 karakter olmalı'**
  String get authPasswordTooShort;

  /// No description provided for @authPasswordHelper.
  ///
  /// In tr, this message translates to:
  /// **'En az 6 karakter'**
  String get authPasswordHelper;

  /// No description provided for @authLoginButton.
  ///
  /// In tr, this message translates to:
  /// **'Giriş yap'**
  String get authLoginButton;

  /// No description provided for @authSignupButton.
  ///
  /// In tr, this message translates to:
  /// **'Kayıt ol'**
  String get authSignupButton;

  /// No description provided for @authToggleToSignup.
  ///
  /// In tr, this message translates to:
  /// **'Hesabın yok mu? Kayıt ol'**
  String get authToggleToSignup;

  /// No description provided for @authToggleToLogin.
  ///
  /// In tr, this message translates to:
  /// **'Zaten hesabın var mı? Giriş yap'**
  String get authToggleToLogin;

  /// No description provided for @authSignupSuccess.
  ///
  /// In tr, this message translates to:
  /// **'Kayıt başarılı. E-postana gönderilen doğrulama bağlantısına tıkladıktan sonra giriş yapabilirsin.'**
  String get authSignupSuccess;

  /// No description provided for @connectionError.
  ///
  /// In tr, this message translates to:
  /// **'Bağlantı hatası. İnternet bağlantını kontrol edip tekrar dene.'**
  String get connectionError;

  /// No description provided for @unexpectedError.
  ///
  /// In tr, this message translates to:
  /// **'Beklenmeyen bir hata oluştu: {error}'**
  String unexpectedError(String error);

  /// No description provided for @commonSave.
  ///
  /// In tr, this message translates to:
  /// **'Kaydet'**
  String get commonSave;

  /// No description provided for @commonCancel.
  ///
  /// In tr, this message translates to:
  /// **'İptal'**
  String get commonCancel;

  /// No description provided for @commonClose.
  ///
  /// In tr, this message translates to:
  /// **'Kapat'**
  String get commonClose;

  /// No description provided for @commonRetry.
  ///
  /// In tr, this message translates to:
  /// **'Tekrar dene'**
  String get commonRetry;

  /// No description provided for @commonLoading.
  ///
  /// In tr, this message translates to:
  /// **'Yükleniyor...'**
  String get commonLoading;

  /// No description provided for @commonDelete.
  ///
  /// In tr, this message translates to:
  /// **'Sil'**
  String get commonDelete;

  /// No description provided for @commonNext.
  ///
  /// In tr, this message translates to:
  /// **'Devam'**
  String get commonNext;

  /// No description provided for @commonSkip.
  ///
  /// In tr, this message translates to:
  /// **'Geç'**
  String get commonSkip;

  /// No description provided for @languageTooltip.
  ///
  /// In tr, this message translates to:
  /// **'Dil / Language'**
  String get languageTooltip;

  /// No description provided for @languageTurkish.
  ///
  /// In tr, this message translates to:
  /// **'Türkçe'**
  String get languageTurkish;

  /// No description provided for @languageEnglish.
  ///
  /// In tr, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @onbStepCounter.
  ///
  /// In tr, this message translates to:
  /// **'Adım {step}/8'**
  String onbStepCounter(int step);

  /// No description provided for @onbNext.
  ///
  /// In tr, this message translates to:
  /// **'Devam et'**
  String get onbNext;

  /// No description provided for @onbBackTooltip.
  ///
  /// In tr, this message translates to:
  /// **'Geri'**
  String get onbBackTooltip;

  /// No description provided for @onbExitTooltip.
  ///
  /// In tr, this message translates to:
  /// **'Çık'**
  String get onbExitTooltip;

  /// No description provided for @onbResumeToast.
  ///
  /// In tr, this message translates to:
  /// **'Kaldığın yerden devam ediyoruz 👋'**
  String get onbResumeToast;

  /// No description provided for @onbSessionLost.
  ///
  /// In tr, this message translates to:
  /// **'Oturum bulunamadı. Lütfen tekrar giriş yap.'**
  String get onbSessionLost;

  /// No description provided for @onbSaveFailed.
  ///
  /// In tr, this message translates to:
  /// **'Kaydedilemedi: {message}'**
  String onbSaveFailed(String message);

  /// No description provided for @onbWelcomeStart.
  ///
  /// In tr, this message translates to:
  /// **'Başla'**
  String get onbWelcomeStart;

  /// No description provided for @introLine1.
  ///
  /// In tr, this message translates to:
  /// **'Merhaba.'**
  String get introLine1;

  /// No description provided for @introLine2.
  ///
  /// In tr, this message translates to:
  /// **'Bundan böyle bu yolculukta yanındayım.'**
  String get introLine2;

  /// No description provided for @introLine3.
  ///
  /// In tr, this message translates to:
  /// **'Önce seni tanımak istiyorum — sadece 2 dakika. Hazırsan başlayalım.'**
  String get introLine3;

  /// No description provided for @introTapHint.
  ///
  /// In tr, this message translates to:
  /// **'devam etmek için dokun'**
  String get introTapHint;

  /// No description provided for @onbIdentityTitle.
  ///
  /// In tr, this message translates to:
  /// **'Kendini tanıtır mısın?'**
  String get onbIdentityTitle;

  /// No description provided for @onbIdentityWhy.
  ///
  /// In tr, this message translates to:
  /// **'Yaşın ve cinsiyetin, günlük enerji ihtiyacını doğru hesaplayabilmemiz için gerekli.'**
  String get onbIdentityWhy;

  /// No description provided for @onbNameLabel.
  ///
  /// In tr, this message translates to:
  /// **'Adın'**
  String get onbNameLabel;

  /// No description provided for @onbAgeLabel.
  ///
  /// In tr, this message translates to:
  /// **'Yaşın'**
  String get onbAgeLabel;

  /// No description provided for @onbSexLabel.
  ///
  /// In tr, this message translates to:
  /// **'Cinsiyetin'**
  String get onbSexLabel;

  /// No description provided for @onbSexFemale.
  ///
  /// In tr, this message translates to:
  /// **'Kadın'**
  String get onbSexFemale;

  /// No description provided for @onbSexMale.
  ///
  /// In tr, this message translates to:
  /// **'Erkek'**
  String get onbSexMale;

  /// No description provided for @onbSexUnspecified.
  ///
  /// In tr, this message translates to:
  /// **'Belirtmek istemiyorum'**
  String get onbSexUnspecified;

  /// No description provided for @onbBodyTitle.
  ///
  /// In tr, this message translates to:
  /// **'Vücut ölçülerin'**
  String get onbBodyTitle;

  /// No description provided for @onbBodyWhy.
  ///
  /// In tr, this message translates to:
  /// **'Boy ve kilon, sana uygun kalori hedefini belirlememizin temeli.'**
  String get onbBodyWhy;

  /// No description provided for @onbHeightLabel.
  ///
  /// In tr, this message translates to:
  /// **'Boy (cm)'**
  String get onbHeightLabel;

  /// No description provided for @onbWeightLabel.
  ///
  /// In tr, this message translates to:
  /// **'Kilo (kg)'**
  String get onbWeightLabel;

  /// No description provided for @onbMeasurementsLabel.
  ///
  /// In tr, this message translates to:
  /// **'Bel ve kalça çevresi (opsiyonel)'**
  String get onbMeasurementsLabel;

  /// No description provided for @onbMeasurementsHint.
  ///
  /// In tr, this message translates to:
  /// **'Mezuran yoksa geçebilirsin — girersen ilerlemeni takip etmek için güzel bir başlangıç olur.'**
  String get onbMeasurementsHint;

  /// No description provided for @onbWaistLabel.
  ///
  /// In tr, this message translates to:
  /// **'Bel (cm)'**
  String get onbWaistLabel;

  /// No description provided for @onbHipLabel.
  ///
  /// In tr, this message translates to:
  /// **'Kalça (cm)'**
  String get onbHipLabel;

  /// No description provided for @onbGoalTitle.
  ///
  /// In tr, this message translates to:
  /// **'Hedefin ne?'**
  String get onbGoalTitle;

  /// No description provided for @onbGoalWhy.
  ///
  /// In tr, this message translates to:
  /// **'Planını ve önerilerimizi tamamen bu hedefe göre şekillendireceğiz.'**
  String get onbGoalWhy;

  /// No description provided for @onbGoalLose.
  ///
  /// In tr, this message translates to:
  /// **'Kilo vermek'**
  String get onbGoalLose;

  /// No description provided for @onbGoalGain.
  ///
  /// In tr, this message translates to:
  /// **'Kilo almak'**
  String get onbGoalGain;

  /// No description provided for @onbGoalMaintain.
  ///
  /// In tr, this message translates to:
  /// **'Kilomu korumak'**
  String get onbGoalMaintain;

  /// No description provided for @onbGoalHealthy.
  ///
  /// In tr, this message translates to:
  /// **'Sadece sağlıklı beslenmek'**
  String get onbGoalHealthy;

  /// No description provided for @onbTargetWeightLabel.
  ///
  /// In tr, this message translates to:
  /// **'Hedef kilo (kg, opsiyonel)'**
  String get onbTargetWeightLabel;

  /// No description provided for @onbPaceLabel.
  ///
  /// In tr, this message translates to:
  /// **'Nasıl bir tempo istersin?'**
  String get onbPaceLabel;

  /// No description provided for @onbPaceSlow.
  ///
  /// In tr, this message translates to:
  /// **'Yavaş ve sürdürülebilir'**
  String get onbPaceSlow;

  /// No description provided for @onbPaceBalanced.
  ///
  /// In tr, this message translates to:
  /// **'Dengeli'**
  String get onbPaceBalanced;

  /// No description provided for @onbPaceFast.
  ///
  /// In tr, this message translates to:
  /// **'Hızlı'**
  String get onbPaceFast;

  /// No description provided for @onbHealthTitle.
  ///
  /// In tr, this message translates to:
  /// **'Sağlık durumun'**
  String get onbHealthTitle;

  /// No description provided for @onbHealthWhy.
  ///
  /// In tr, this message translates to:
  /// **'Kronik durumlar ve alerjiler, planının senin için güvenli olmasını sağlayan en önemli bilgiler.'**
  String get onbHealthWhy;

  /// No description provided for @onbConditionsLabel.
  ///
  /// In tr, this message translates to:
  /// **'Kronik bir durumun var mı?'**
  String get onbConditionsLabel;

  /// No description provided for @onbConditionDiabetes.
  ///
  /// In tr, this message translates to:
  /// **'Diyabet'**
  String get onbConditionDiabetes;

  /// No description provided for @onbConditionInsulinResistance.
  ///
  /// In tr, this message translates to:
  /// **'İnsülin direnci'**
  String get onbConditionInsulinResistance;

  /// No description provided for @onbConditionHypertension.
  ///
  /// In tr, this message translates to:
  /// **'Yüksek tansiyon'**
  String get onbConditionHypertension;

  /// No description provided for @onbConditionThyroid.
  ///
  /// In tr, this message translates to:
  /// **'Tiroid'**
  String get onbConditionThyroid;

  /// No description provided for @onbConditionCholesterol.
  ///
  /// In tr, this message translates to:
  /// **'Kolesterol'**
  String get onbConditionCholesterol;

  /// No description provided for @onbOptionOther.
  ///
  /// In tr, this message translates to:
  /// **'Diğer'**
  String get onbOptionOther;

  /// No description provided for @onbOptionNone.
  ///
  /// In tr, this message translates to:
  /// **'Yok'**
  String get onbOptionNone;

  /// No description provided for @onbConditionsOtherLabel.
  ///
  /// In tr, this message translates to:
  /// **'Diğer durumunu yazar mısın?'**
  String get onbConditionsOtherLabel;

  /// No description provided for @onbMedicationsLabel.
  ///
  /// In tr, this message translates to:
  /// **'Düzenli kullandığın ilaç (opsiyonel)'**
  String get onbMedicationsLabel;

  /// No description provided for @onbAllergiesLabel.
  ///
  /// In tr, this message translates to:
  /// **'Alerjin veya intoleransın var mı?'**
  String get onbAllergiesLabel;

  /// No description provided for @onbAllergyGluten.
  ///
  /// In tr, this message translates to:
  /// **'Gluten'**
  String get onbAllergyGluten;

  /// No description provided for @onbAllergyLactose.
  ///
  /// In tr, this message translates to:
  /// **'Laktoz'**
  String get onbAllergyLactose;

  /// No description provided for @onbAllergyNuts.
  ///
  /// In tr, this message translates to:
  /// **'Fındık / fıstık'**
  String get onbAllergyNuts;

  /// No description provided for @onbAllergySeafood.
  ///
  /// In tr, this message translates to:
  /// **'Deniz ürünleri'**
  String get onbAllergySeafood;

  /// No description provided for @onbAllergyEgg.
  ///
  /// In tr, this message translates to:
  /// **'Yumurta'**
  String get onbAllergyEgg;

  /// No description provided for @onbAllergiesOtherLabel.
  ///
  /// In tr, this message translates to:
  /// **'Diğer alerjini yazar mısın?'**
  String get onbAllergiesOtherLabel;

  /// No description provided for @onbLifestyleTitle.
  ///
  /// In tr, this message translates to:
  /// **'Yaşam tarzın'**
  String get onbLifestyleTitle;

  /// No description provided for @onbLifestyleWhy.
  ///
  /// In tr, this message translates to:
  /// **'Gün içindeki hareketin ve alışkanlıkların, kalori ihtiyacını doğrudan etkiler.'**
  String get onbLifestyleWhy;

  /// No description provided for @onbActivityLabel.
  ///
  /// In tr, this message translates to:
  /// **'Hareket düzeyin'**
  String get onbActivityLabel;

  /// No description provided for @onbActivitySedentary.
  ///
  /// In tr, this message translates to:
  /// **'Masa başı — hareketsiz'**
  String get onbActivitySedentary;

  /// No description provided for @onbActivityLight.
  ///
  /// In tr, this message translates to:
  /// **'Az hareketli'**
  String get onbActivityLight;

  /// No description provided for @onbActivityModerate.
  ///
  /// In tr, this message translates to:
  /// **'Orta'**
  String get onbActivityModerate;

  /// No description provided for @onbActivityActive.
  ///
  /// In tr, this message translates to:
  /// **'Aktif'**
  String get onbActivityActive;

  /// No description provided for @onbActivityVeryActive.
  ///
  /// In tr, this message translates to:
  /// **'Çok aktif'**
  String get onbActivityVeryActive;

  /// No description provided for @onbWaterLabel.
  ///
  /// In tr, this message translates to:
  /// **'Günde kaç bardak su içersin?'**
  String get onbWaterLabel;

  /// No description provided for @onbSleepLabel.
  ///
  /// In tr, this message translates to:
  /// **'Uykun (opsiyonel)'**
  String get onbSleepLabel;

  /// No description provided for @onbSleepLt5.
  ///
  /// In tr, this message translates to:
  /// **'5 saatten az'**
  String get onbSleepLt5;

  /// No description provided for @onbSleep5to6.
  ///
  /// In tr, this message translates to:
  /// **'5-6 saat'**
  String get onbSleep5to6;

  /// No description provided for @onbSleep7to8.
  ///
  /// In tr, this message translates to:
  /// **'7-8 saat'**
  String get onbSleep7to8;

  /// No description provided for @onbSleep8plus.
  ///
  /// In tr, this message translates to:
  /// **'8 saatten çok'**
  String get onbSleep8plus;

  /// No description provided for @onbSmokingLabel.
  ///
  /// In tr, this message translates to:
  /// **'Sigara (opsiyonel)'**
  String get onbSmokingLabel;

  /// No description provided for @onbAlcoholLabel.
  ///
  /// In tr, this message translates to:
  /// **'Alkol (opsiyonel)'**
  String get onbAlcoholLabel;

  /// No description provided for @onbHabitOccasional.
  ///
  /// In tr, this message translates to:
  /// **'Ara sıra'**
  String get onbHabitOccasional;

  /// No description provided for @onbHabitRegular.
  ///
  /// In tr, this message translates to:
  /// **'Düzenli'**
  String get onbHabitRegular;

  /// No description provided for @onbHabitsTitle.
  ///
  /// In tr, this message translates to:
  /// **'Beslenme alışkanlıkların'**
  String get onbHabitsTitle;

  /// No description provided for @onbHabitsWhy.
  ///
  /// In tr, this message translates to:
  /// **'Gerçek düzenini bilirsek, plan hayatına çok daha kolay oturur.'**
  String get onbHabitsWhy;

  /// No description provided for @onbMealsLabel.
  ///
  /// In tr, this message translates to:
  /// **'Günde kaç öğün yersin?'**
  String get onbMealsLabel;

  /// No description provided for @onbBreakfastLabel.
  ///
  /// In tr, this message translates to:
  /// **'Kahvaltıyı atlar mısın?'**
  String get onbBreakfastLabel;

  /// No description provided for @onbBreakfastNever.
  ///
  /// In tr, this message translates to:
  /// **'Hiç atlamam'**
  String get onbBreakfastNever;

  /// No description provided for @onbBreakfastSometimes.
  ///
  /// In tr, this message translates to:
  /// **'Bazen'**
  String get onbBreakfastSometimes;

  /// No description provided for @onbBreakfastOften.
  ///
  /// In tr, this message translates to:
  /// **'Çoğu gün'**
  String get onbBreakfastOften;

  /// No description provided for @onbEatingOutLabel.
  ///
  /// In tr, this message translates to:
  /// **'Ne sıklıkla dışarıda yer veya sipariş verirsin?'**
  String get onbEatingOutLabel;

  /// No description provided for @onbEatingOutRarely.
  ///
  /// In tr, this message translates to:
  /// **'Nadiren'**
  String get onbEatingOutRarely;

  /// No description provided for @onbEatingOutWeekly12.
  ///
  /// In tr, this message translates to:
  /// **'Haftada 1-2'**
  String get onbEatingOutWeekly12;

  /// No description provided for @onbEatingOutWeekly3plus.
  ///
  /// In tr, this message translates to:
  /// **'Haftada 3+'**
  String get onbEatingOutWeekly3plus;

  /// No description provided for @onbEatingOutDaily.
  ///
  /// In tr, this message translates to:
  /// **'Her gün'**
  String get onbEatingOutDaily;

  /// No description provided for @onbWeakMomentsLabel.
  ///
  /// In tr, this message translates to:
  /// **'Zayıf anların hangileri?'**
  String get onbWeakMomentsLabel;

  /// No description provided for @onbWeakNightSnacking.
  ///
  /// In tr, this message translates to:
  /// **'Gece atıştırması'**
  String get onbWeakNightSnacking;

  /// No description provided for @onbWeakSweetCraving.
  ///
  /// In tr, this message translates to:
  /// **'Tatlı krizi'**
  String get onbWeakSweetCraving;

  /// No description provided for @onbWeakHungerBetweenMeals.
  ///
  /// In tr, this message translates to:
  /// **'Öğün dışı açlık'**
  String get onbWeakHungerBetweenMeals;

  /// No description provided for @onbWeakStressEating.
  ///
  /// In tr, this message translates to:
  /// **'Stres yemesi'**
  String get onbWeakStressEating;

  /// No description provided for @onbPrefsTitle.
  ///
  /// In tr, this message translates to:
  /// **'Beslenme tercihlerin'**
  String get onbPrefsTitle;

  /// No description provided for @onbPrefsWhy.
  ///
  /// In tr, this message translates to:
  /// **'Sevmediğin yiyecekleri plana hiç koymayalım — sürdürülebilirlik böyle başlar.'**
  String get onbPrefsWhy;

  /// No description provided for @onbDietStyleLabel.
  ///
  /// In tr, this message translates to:
  /// **'Beslenme tarzın'**
  String get onbDietStyleLabel;

  /// No description provided for @onbDietOmnivore.
  ///
  /// In tr, this message translates to:
  /// **'Hepçil'**
  String get onbDietOmnivore;

  /// No description provided for @onbDietVegetarian.
  ///
  /// In tr, this message translates to:
  /// **'Vejetaryen'**
  String get onbDietVegetarian;

  /// No description provided for @onbDietVegan.
  ///
  /// In tr, this message translates to:
  /// **'Vegan'**
  String get onbDietVegan;

  /// No description provided for @onbDislikedLabel.
  ///
  /// In tr, this message translates to:
  /// **'Sevmediğin yiyecekler (opsiyonel)'**
  String get onbDislikedLabel;

  /// No description provided for @onbDislikedFieldLabel.
  ///
  /// In tr, this message translates to:
  /// **'Yemek istemediklerin'**
  String get onbDislikedFieldLabel;

  /// No description provided for @onbDislikedHint.
  ///
  /// In tr, this message translates to:
  /// **'Örn. brokoli, sakatat, mantar...'**
  String get onbDislikedHint;

  /// No description provided for @onbSummaryTitle.
  ///
  /// In tr, this message translates to:
  /// **'Profilin hazır 🎉'**
  String get onbSummaryTitle;

  /// No description provided for @onbSummarySubtitle.
  ///
  /// In tr, this message translates to:
  /// **'İşte anlattıkların. Bunları istediğin zaman profilinden güncelleyebilirsin.'**
  String get onbSummarySubtitle;

  /// No description provided for @onbSummaryName.
  ///
  /// In tr, this message translates to:
  /// **'İsim'**
  String get onbSummaryName;

  /// No description provided for @onbSummaryAge.
  ///
  /// In tr, this message translates to:
  /// **'Yaş'**
  String get onbSummaryAge;

  /// No description provided for @onbSummaryBody.
  ///
  /// In tr, this message translates to:
  /// **'Boy / Kilo'**
  String get onbSummaryBody;

  /// No description provided for @onbSummaryGoal.
  ///
  /// In tr, this message translates to:
  /// **'Hedef'**
  String get onbSummaryGoal;

  /// No description provided for @onbSummaryAllergies.
  ///
  /// In tr, this message translates to:
  /// **'Alerji / intolerans'**
  String get onbSummaryAllergies;

  /// No description provided for @onbSummaryStart.
  ///
  /// In tr, this message translates to:
  /// **'Başlayalım'**
  String get onbSummaryStart;

  /// No description provided for @onbSummaryCreatePlan.
  ///
  /// In tr, this message translates to:
  /// **'İlk planımı oluştur'**
  String get onbSummaryCreatePlan;

  /// No description provided for @profTitle.
  ///
  /// In tr, this message translates to:
  /// **'Profil'**
  String get profTitle;

  /// No description provided for @profNotFilled.
  ///
  /// In tr, this message translates to:
  /// **'Henüz doldurulmadı'**
  String get profNotFilled;

  /// No description provided for @profSaved.
  ///
  /// In tr, this message translates to:
  /// **'Kaydedildi ✓'**
  String get profSaved;

  /// No description provided for @profLoadFailed.
  ///
  /// In tr, this message translates to:
  /// **'Profil yüklenemedi: {message}'**
  String profLoadFailed(String message);

  /// No description provided for @profAgeValue.
  ///
  /// In tr, this message translates to:
  /// **'{age} yaş'**
  String profAgeValue(int age);

  /// No description provided for @profSectionIdentity.
  ///
  /// In tr, this message translates to:
  /// **'Kişisel bilgiler'**
  String get profSectionIdentity;

  /// No description provided for @profSectionBody.
  ///
  /// In tr, this message translates to:
  /// **'Vücut'**
  String get profSectionBody;

  /// No description provided for @profSectionGoal.
  ///
  /// In tr, this message translates to:
  /// **'Hedef'**
  String get profSectionGoal;

  /// No description provided for @profSectionHealth.
  ///
  /// In tr, this message translates to:
  /// **'Sağlık'**
  String get profSectionHealth;

  /// No description provided for @profSectionLifestyle.
  ///
  /// In tr, this message translates to:
  /// **'Yaşam tarzı'**
  String get profSectionLifestyle;

  /// No description provided for @profSectionHabits.
  ///
  /// In tr, this message translates to:
  /// **'Alışkanlıklar'**
  String get profSectionHabits;

  /// No description provided for @profSectionPrefs.
  ///
  /// In tr, this message translates to:
  /// **'Tercihler'**
  String get profSectionPrefs;

  /// No description provided for @profSectionAccount.
  ///
  /// In tr, this message translates to:
  /// **'Hesap'**
  String get profSectionAccount;

  /// No description provided for @profConditionsShort.
  ///
  /// In tr, this message translates to:
  /// **'Kronik'**
  String get profConditionsShort;

  /// No description provided for @profAllergiesShort.
  ///
  /// In tr, this message translates to:
  /// **'Alerji'**
  String get profAllergiesShort;

  /// No description provided for @profMedicationsShort.
  ///
  /// In tr, this message translates to:
  /// **'İlaç'**
  String get profMedicationsShort;

  /// No description provided for @profWaterShort.
  ///
  /// In tr, this message translates to:
  /// **'Su'**
  String get profWaterShort;

  /// No description provided for @profSleepShort.
  ///
  /// In tr, this message translates to:
  /// **'Uyku'**
  String get profSleepShort;

  /// No description provided for @profSmokingShort.
  ///
  /// In tr, this message translates to:
  /// **'Sigara'**
  String get profSmokingShort;

  /// No description provided for @profAlcoholShort.
  ///
  /// In tr, this message translates to:
  /// **'Alkol'**
  String get profAlcoholShort;

  /// No description provided for @profMealsShort.
  ///
  /// In tr, this message translates to:
  /// **'Öğün'**
  String get profMealsShort;

  /// No description provided for @profBreakfastShort.
  ///
  /// In tr, this message translates to:
  /// **'Kahvaltı atlama'**
  String get profBreakfastShort;

  /// No description provided for @profEatingOutShort.
  ///
  /// In tr, this message translates to:
  /// **'Dışarıda yeme'**
  String get profEatingOutShort;

  /// No description provided for @profWeakShort.
  ///
  /// In tr, this message translates to:
  /// **'Zayıf anlar'**
  String get profWeakShort;

  /// No description provided for @profDislikedShort.
  ///
  /// In tr, this message translates to:
  /// **'Sevmedikleri'**
  String get profDislikedShort;

  /// No description provided for @profBodyNote.
  ///
  /// In tr, this message translates to:
  /// **'Kilo takibin İlerleme sayfasında — buraya güncel kilonu yaz. Bel/kalça ölçüleri de orada güncellenecek.'**
  String get profBodyNote;

  /// No description provided for @profEmailLabel.
  ///
  /// In tr, this message translates to:
  /// **'E-posta'**
  String get profEmailLabel;

  /// No description provided for @profChangePassword.
  ///
  /// In tr, this message translates to:
  /// **'Şifre değiştir'**
  String get profChangePassword;

  /// No description provided for @profNewPasswordLabel.
  ///
  /// In tr, this message translates to:
  /// **'Yeni şifre'**
  String get profNewPasswordLabel;

  /// No description provided for @profNewPasswordRepeatLabel.
  ///
  /// In tr, this message translates to:
  /// **'Yeni şifre (tekrar)'**
  String get profNewPasswordRepeatLabel;

  /// No description provided for @profPasswordMismatch.
  ///
  /// In tr, this message translates to:
  /// **'Şifreler eşleşmiyor'**
  String get profPasswordMismatch;

  /// No description provided for @profPasswordChanged.
  ///
  /// In tr, this message translates to:
  /// **'Şifren güncellendi ✓'**
  String get profPasswordChanged;

  /// No description provided for @profLanguageLabel.
  ///
  /// In tr, this message translates to:
  /// **'Dil'**
  String get profLanguageLabel;

  /// No description provided for @profSignOut.
  ///
  /// In tr, this message translates to:
  /// **'Çıkış yap'**
  String get profSignOut;

  /// No description provided for @profSignOutConfirm.
  ///
  /// In tr, this message translates to:
  /// **'Oturumu kapatmak istediğine emin misin?'**
  String get profSignOutConfirm;

  /// No description provided for @dietPlanTitle.
  ///
  /// In tr, this message translates to:
  /// **'Diyet Planı'**
  String get dietPlanTitle;

  /// No description provided for @dpMenuTooltip.
  ///
  /// In tr, this message translates to:
  /// **'Plan seçenekleri'**
  String get dpMenuTooltip;

  /// No description provided for @dpMenuRevise.
  ///
  /// In tr, this message translates to:
  /// **'Planı revize et'**
  String get dpMenuRevise;

  /// No description provided for @dpMenuRegenerate.
  ///
  /// In tr, this message translates to:
  /// **'Sıfırdan yeni plan'**
  String get dpMenuRegenerate;

  /// No description provided for @dpRegenerateConfirm.
  ///
  /// In tr, this message translates to:
  /// **'Mevcut plan tamamen yenisiyle değiştirilecek ve günlük AI hakkından 1 kullanılacak. Devam etmek istiyor musun?'**
  String get dpRegenerateConfirm;

  /// No description provided for @dpRegenerateContinue.
  ///
  /// In tr, this message translates to:
  /// **'Devam'**
  String get dpRegenerateContinue;

  /// No description provided for @dpKcalPerDay.
  ///
  /// In tr, this message translates to:
  /// **'kcal/gün'**
  String get dpKcalPerDay;

  /// No description provided for @dpMacroCarb.
  ///
  /// In tr, this message translates to:
  /// **'Karb'**
  String get dpMacroCarb;

  /// No description provided for @dpMacroProtein.
  ///
  /// In tr, this message translates to:
  /// **'Protein'**
  String get dpMacroProtein;

  /// No description provided for @dpMacroFat.
  ///
  /// In tr, this message translates to:
  /// **'Yağ'**
  String get dpMacroFat;

  /// No description provided for @dayShortMon.
  ///
  /// In tr, this message translates to:
  /// **'Pzt'**
  String get dayShortMon;

  /// No description provided for @dayShortTue.
  ///
  /// In tr, this message translates to:
  /// **'Sal'**
  String get dayShortTue;

  /// No description provided for @dayShortWed.
  ///
  /// In tr, this message translates to:
  /// **'Çar'**
  String get dayShortWed;

  /// No description provided for @dayShortThu.
  ///
  /// In tr, this message translates to:
  /// **'Per'**
  String get dayShortThu;

  /// No description provided for @dayShortFri.
  ///
  /// In tr, this message translates to:
  /// **'Cum'**
  String get dayShortFri;

  /// No description provided for @dayShortSat.
  ///
  /// In tr, this message translates to:
  /// **'Cmt'**
  String get dayShortSat;

  /// No description provided for @dayShortSun.
  ///
  /// In tr, this message translates to:
  /// **'Paz'**
  String get dayShortSun;

  /// No description provided for @dpMealBreakfast.
  ///
  /// In tr, this message translates to:
  /// **'Kahvaltı'**
  String get dpMealBreakfast;

  /// No description provided for @dpMealLunch.
  ///
  /// In tr, this message translates to:
  /// **'Öğle Yemeği'**
  String get dpMealLunch;

  /// No description provided for @dpMealDinner.
  ///
  /// In tr, this message translates to:
  /// **'Akşam Yemeği'**
  String get dpMealDinner;

  /// No description provided for @dpMealSnack.
  ///
  /// In tr, this message translates to:
  /// **'Ara Öğün'**
  String get dpMealSnack;

  /// No description provided for @dpMealDefault.
  ///
  /// In tr, this message translates to:
  /// **'Öğün'**
  String get dpMealDefault;

  /// No description provided for @dpEmptyMessage.
  ///
  /// In tr, this message translates to:
  /// **'Henüz bir diyet planın yok.\nSana özel ilk planını hemen oluşturalım.'**
  String get dpEmptyMessage;

  /// No description provided for @dpCreateFirstPlan.
  ///
  /// In tr, this message translates to:
  /// **'İlk planımı oluştur'**
  String get dpCreateFirstPlan;

  /// No description provided for @dpNoMealsForDay.
  ///
  /// In tr, this message translates to:
  /// **'Bu gün için öğün bulunamadı.'**
  String get dpNoMealsForDay;

  /// No description provided for @dpRevisePrompt.
  ///
  /// In tr, this message translates to:
  /// **'Plandan memnun olmadığın noktaları seç:'**
  String get dpRevisePrompt;

  /// No description provided for @dpReasonDisliked.
  ///
  /// In tr, this message translates to:
  /// **'Sevmedim'**
  String get dpReasonDisliked;

  /// No description provided for @dpReasonHardToPrepare.
  ///
  /// In tr, this message translates to:
  /// **'Hazırlaması zor'**
  String get dpReasonHardToPrepare;

  /// No description provided for @dpReasonIngredientsUnavailable.
  ///
  /// In tr, this message translates to:
  /// **'Malzemeleri bulamıyorum'**
  String get dpReasonIngredientsUnavailable;

  /// No description provided for @dpReviseNoteLabel.
  ///
  /// In tr, this message translates to:
  /// **'Not (isteğe bağlı)'**
  String get dpReviseNoteLabel;

  /// No description provided for @dpReviseNoteHint.
  ///
  /// In tr, this message translates to:
  /// **'Örn. akşamları balık istemiyorum'**
  String get dpReviseNoteHint;

  /// No description provided for @dpReviseValidation.
  ///
  /// In tr, this message translates to:
  /// **'En az bir neden seç veya bir not yaz.'**
  String get dpReviseValidation;

  /// No description provided for @dpReviseSubmit.
  ///
  /// In tr, this message translates to:
  /// **'Gönder'**
  String get dpReviseSubmit;

  /// No description provided for @ftTitle.
  ///
  /// In tr, this message translates to:
  /// **'Yemek Takibi'**
  String get ftTitle;

  /// No description provided for @ftToday.
  ///
  /// In tr, this message translates to:
  /// **'Bugün'**
  String get ftToday;

  /// No description provided for @ftYesterday.
  ///
  /// In tr, this message translates to:
  /// **'Dün'**
  String get ftYesterday;

  /// No description provided for @ftWaterTitle.
  ///
  /// In tr, this message translates to:
  /// **'Su Takibi'**
  String get ftWaterTitle;

  /// No description provided for @ftGlasses.
  ///
  /// In tr, this message translates to:
  /// **'{count} bardak'**
  String ftGlasses(int count);

  /// No description provided for @ftMealBreakfast.
  ///
  /// In tr, this message translates to:
  /// **'Kahvaltı'**
  String get ftMealBreakfast;

  /// No description provided for @ftMealLunch.
  ///
  /// In tr, this message translates to:
  /// **'Öğle Yemeği'**
  String get ftMealLunch;

  /// No description provided for @ftMealDinner.
  ///
  /// In tr, this message translates to:
  /// **'Akşam Yemeği'**
  String get ftMealDinner;

  /// No description provided for @ftMealSnack.
  ///
  /// In tr, this message translates to:
  /// **'Ara Öğün'**
  String get ftMealSnack;

  /// No description provided for @ftEmptyDay.
  ///
  /// In tr, this message translates to:
  /// **'Bu gün için henüz yemek kaydı yok.'**
  String get ftEmptyDay;

  /// No description provided for @ftEmptyCta.
  ///
  /// In tr, this message translates to:
  /// **'İlk öğününü ekle'**
  String get ftEmptyCta;

  /// No description provided for @ftAddTooltip.
  ///
  /// In tr, this message translates to:
  /// **'Yemek ekle'**
  String get ftAddTooltip;

  /// No description provided for @ftAddSheetTitle.
  ///
  /// In tr, this message translates to:
  /// **'Yemek Ekle'**
  String get ftAddSheetTitle;

  /// No description provided for @ftRecentLabel.
  ///
  /// In tr, this message translates to:
  /// **'Son eklenenler'**
  String get ftRecentLabel;

  /// No description provided for @ftFoodName.
  ///
  /// In tr, this message translates to:
  /// **'Yiyecek adı'**
  String get ftFoodName;

  /// No description provided for @ftCalories.
  ///
  /// In tr, this message translates to:
  /// **'Kalori (kcal)'**
  String get ftCalories;

  /// No description provided for @ftNameRequired.
  ///
  /// In tr, this message translates to:
  /// **'Yiyecek adı gerekli'**
  String get ftNameRequired;

  /// No description provided for @ftCaloriesRequired.
  ///
  /// In tr, this message translates to:
  /// **'Kalori gerekli'**
  String get ftCaloriesRequired;

  /// No description provided for @ftCaloriesInvalid.
  ///
  /// In tr, this message translates to:
  /// **'Geçerli bir kalori değeri gir'**
  String get ftCaloriesInvalid;

  /// No description provided for @ftAdd.
  ///
  /// In tr, this message translates to:
  /// **'Ekle'**
  String get ftAdd;

  /// No description provided for @ftLoadError.
  ///
  /// In tr, this message translates to:
  /// **'Kayıtlar yüklenemedi: {message}'**
  String ftLoadError(String message);

  /// No description provided for @ftAddError.
  ///
  /// In tr, this message translates to:
  /// **'Eklenemedi: {message}'**
  String ftAddError(String message);

  /// No description provided for @ftDeleteError.
  ///
  /// In tr, this message translates to:
  /// **'Silinemedi: {message}'**
  String ftDeleteError(String message);

  /// No description provided for @ftWaterError.
  ///
  /// In tr, this message translates to:
  /// **'Su kaydı güncellenemedi: {message}'**
  String ftWaterError(String message);

  /// No description provided for @pgTitle.
  ///
  /// In tr, this message translates to:
  /// **'İlerleme'**
  String get pgTitle;

  /// No description provided for @pgToday.
  ///
  /// In tr, this message translates to:
  /// **'Bugün'**
  String get pgToday;

  /// No description provided for @pgYesterday.
  ///
  /// In tr, this message translates to:
  /// **'Dün'**
  String get pgYesterday;

  /// No description provided for @pgHeroEmpty.
  ///
  /// In tr, this message translates to:
  /// **'Henüz kilo kaydın yok.\nİlk ölçümünle yolculuğun başlasın.'**
  String get pgHeroEmpty;

  /// No description provided for @pgAddFirst.
  ///
  /// In tr, this message translates to:
  /// **'İlk ölçümünü ekle'**
  String get pgAddFirst;

  /// No description provided for @pgJourneyRange.
  ///
  /// In tr, this message translates to:
  /// **'Başlangıç {start} kg → hedef {target} kg'**
  String pgJourneyRange(String start, String target);

  /// No description provided for @pgToGoal.
  ///
  /// In tr, this message translates to:
  /// **'Hedefe {kg} kg kaldı'**
  String pgToGoal(String kg);

  /// No description provided for @pgGoalReached.
  ///
  /// In tr, this message translates to:
  /// **'Hedefine ulaştın 🎉'**
  String get pgGoalReached;

  /// No description provided for @pgTotalChange.
  ///
  /// In tr, this message translates to:
  /// **'Başlangıçtan bu yana {change}'**
  String pgTotalChange(String change);

  /// No description provided for @pgMeasurementsTitle.
  ///
  /// In tr, this message translates to:
  /// **'Vücut Ölçüleri'**
  String get pgMeasurementsTitle;

  /// No description provided for @pgWaist.
  ///
  /// In tr, this message translates to:
  /// **'Bel'**
  String get pgWaist;

  /// No description provided for @pgHip.
  ///
  /// In tr, this message translates to:
  /// **'Kalça'**
  String get pgHip;

  /// No description provided for @pgMeasurementsEmpty.
  ///
  /// In tr, this message translates to:
  /// **'Henüz bel/kalça ölçüsü yok.'**
  String get pgMeasurementsEmpty;

  /// No description provided for @pgMeasurementsCta.
  ///
  /// In tr, this message translates to:
  /// **'Ölçüm ekle'**
  String get pgMeasurementsCta;

  /// No description provided for @pgWeightChart.
  ///
  /// In tr, this message translates to:
  /// **'Kilo'**
  String get pgWeightChart;

  /// No description provided for @pgCaloriesChart.
  ///
  /// In tr, this message translates to:
  /// **'Kalori'**
  String get pgCaloriesChart;

  /// No description provided for @pgWaterChart.
  ///
  /// In tr, this message translates to:
  /// **'Su (bardak)'**
  String get pgWaterChart;

  /// No description provided for @pgLast30Days.
  ///
  /// In tr, this message translates to:
  /// **'Son 30 gün'**
  String get pgLast30Days;

  /// No description provided for @pgLast7Days.
  ///
  /// In tr, this message translates to:
  /// **'Son 7 gün'**
  String get pgLast7Days;

  /// No description provided for @pgWeightEmpty.
  ///
  /// In tr, this message translates to:
  /// **'Grafik için en az 2 kilo girişi gerekli.\nSağ alttaki + ile ölçüm ekle.'**
  String get pgWeightEmpty;

  /// No description provided for @pgCaloriesEmpty.
  ///
  /// In tr, this message translates to:
  /// **'Son 7 günde yemek kaydı yok.\nYemek Takibi sekmesinden ekleyebilirsin.'**
  String get pgCaloriesEmpty;

  /// No description provided for @pgWaterEmpty.
  ///
  /// In tr, this message translates to:
  /// **'Son 7 günde su kaydı yok.\nYemek Takibi sekmesinden ekleyebilirsin.'**
  String get pgWaterEmpty;

  /// No description provided for @pgAddTooltip.
  ///
  /// In tr, this message translates to:
  /// **'Ölçüm ekle'**
  String get pgAddTooltip;

  /// No description provided for @pgSheetTitle.
  ///
  /// In tr, this message translates to:
  /// **'Ölçüm Ekle'**
  String get pgSheetTitle;

  /// No description provided for @pgWeightField.
  ///
  /// In tr, this message translates to:
  /// **'Kilo (kg)'**
  String get pgWeightField;

  /// No description provided for @pgWaistField.
  ///
  /// In tr, this message translates to:
  /// **'Bel (cm)'**
  String get pgWaistField;

  /// No description provided for @pgHipField.
  ///
  /// In tr, this message translates to:
  /// **'Kalça (cm)'**
  String get pgHipField;

  /// No description provided for @pgAtLeastOne.
  ///
  /// In tr, this message translates to:
  /// **'En az bir alanı doldurmalısın.'**
  String get pgAtLeastOne;

  /// No description provided for @pgInvalidValue.
  ///
  /// In tr, this message translates to:
  /// **'Geçerli bir değer gir'**
  String get pgInvalidValue;

  /// No description provided for @pgDateLabel.
  ///
  /// In tr, this message translates to:
  /// **'Tarih'**
  String get pgDateLabel;

  /// No description provided for @pgSaved.
  ///
  /// In tr, this message translates to:
  /// **'Kaydedildi ✓'**
  String get pgSaved;

  /// No description provided for @pgLoadError.
  ///
  /// In tr, this message translates to:
  /// **'Veriler yüklenemedi: {message}'**
  String pgLoadError(String message);

  /// No description provided for @pgSaveError.
  ///
  /// In tr, this message translates to:
  /// **'Kaydedilemedi: {message}'**
  String pgSaveError(String message);

  /// No description provided for @chatTitle.
  ///
  /// In tr, this message translates to:
  /// **'Danışman'**
  String get chatTitle;

  /// No description provided for @chatWelcome.
  ///
  /// In tr, this message translates to:
  /// **'Merhaba! Ben senin beslenme ve diyet danışmanınım. Beslenme, diyet veya sağlıklı yaşam hakkında sorularını yanıtlayabilirim.'**
  String get chatWelcome;

  /// No description provided for @chatHint.
  ///
  /// In tr, this message translates to:
  /// **'Bir soru sor...'**
  String get chatHint;

  /// No description provided for @chatSendTooltip.
  ///
  /// In tr, this message translates to:
  /// **'Gönder'**
  String get chatSendTooltip;

  /// No description provided for @chatMenuTooltip.
  ///
  /// In tr, this message translates to:
  /// **'Sohbet seçenekleri'**
  String get chatMenuTooltip;

  /// No description provided for @chatMenuClear.
  ///
  /// In tr, this message translates to:
  /// **'Sohbeti temizle'**
  String get chatMenuClear;

  /// No description provided for @chatClearConfirmTitle.
  ///
  /// In tr, this message translates to:
  /// **'Sohbeti temizle'**
  String get chatClearConfirmTitle;

  /// No description provided for @chatClearConfirmBody.
  ///
  /// In tr, this message translates to:
  /// **'Tüm sohbet geçmişin silinecek ve danışman önceki konuşmayı hatırlamaz.'**
  String get chatClearConfirmBody;

  /// No description provided for @chatToday.
  ///
  /// In tr, this message translates to:
  /// **'Bugün'**
  String get chatToday;

  /// No description provided for @chatYesterday.
  ///
  /// In tr, this message translates to:
  /// **'Dün'**
  String get chatYesterday;

  /// No description provided for @chatTyping.
  ///
  /// In tr, this message translates to:
  /// **'Yazıyor'**
  String get chatTyping;

  /// No description provided for @chatLoadError.
  ///
  /// In tr, this message translates to:
  /// **'Sohbet geçmişi yüklenemedi.'**
  String get chatLoadError;

  /// No description provided for @chatErrorReply.
  ///
  /// In tr, this message translates to:
  /// **'Üzgünüm, yanıt oluşturulurken bir hata oluştu. Lütfen tekrar deneyin.'**
  String get chatErrorReply;

  /// No description provided for @dcTitle.
  ///
  /// In tr, this message translates to:
  /// **'Diyetisyen'**
  String get dcTitle;

  /// No description provided for @dcTitleDietitian.
  ///
  /// In tr, this message translates to:
  /// **'Danışan'**
  String get dcTitleDietitian;

  /// No description provided for @dcSubtitleUser.
  ///
  /// In tr, this message translates to:
  /// **'Diyetisyenin'**
  String get dcSubtitleUser;

  /// No description provided for @dcSubtitleDietitian.
  ///
  /// In tr, this message translates to:
  /// **'Danışanın'**
  String get dcSubtitleDietitian;

  /// No description provided for @dcToday.
  ///
  /// In tr, this message translates to:
  /// **'Bugün'**
  String get dcToday;

  /// No description provided for @dcYesterday.
  ///
  /// In tr, this message translates to:
  /// **'Dün'**
  String get dcYesterday;

  /// No description provided for @dcNoAssignTitle.
  ///
  /// In tr, this message translates to:
  /// **'Henüz diyetisyen atanmadı'**
  String get dcNoAssignTitle;

  /// No description provided for @dcNoAssignBody.
  ///
  /// In tr, this message translates to:
  /// **'Sana bir diyetisyen atandığında konuşmanız burada başlayacak.'**
  String get dcNoAssignBody;

  /// No description provided for @dcNoClientTitle.
  ///
  /// In tr, this message translates to:
  /// **'Henüz danışan atanmadı'**
  String get dcNoClientTitle;

  /// No description provided for @dcNoClientBody.
  ///
  /// In tr, this message translates to:
  /// **'Sana bir danışan atandığında konuşmanız burada başlayacak.'**
  String get dcNoClientBody;

  /// No description provided for @dcAskAi.
  ///
  /// In tr, this message translates to:
  /// **'Şimdilik Danışman\'a sor'**
  String get dcAskAi;

  /// No description provided for @dcNoMessages.
  ///
  /// In tr, this message translates to:
  /// **'Henüz mesaj yok.\nİlk mesajı sen gönder!'**
  String get dcNoMessages;

  /// No description provided for @dcHint.
  ///
  /// In tr, this message translates to:
  /// **'Mesaj yaz...'**
  String get dcHint;

  /// No description provided for @dcSendTooltip.
  ///
  /// In tr, this message translates to:
  /// **'Gönder'**
  String get dcSendTooltip;

  /// No description provided for @dcLoadError.
  ///
  /// In tr, this message translates to:
  /// **'Yüklenemedi: {message}'**
  String dcLoadError(String message);

  /// No description provided for @dcSendError.
  ///
  /// In tr, this message translates to:
  /// **'Gönderilemedi: {message}'**
  String dcSendError(String message);

  /// No description provided for @emIntroLine1.
  ///
  /// In tr, this message translates to:
  /// **'Tamam. Buradayım.'**
  String get emIntroLine1;

  /// No description provided for @emIntroLine2.
  ///
  /// In tr, this message translates to:
  /// **'Bunu birlikte atlatacağız.'**
  String get emIntroLine2;

  /// No description provided for @emTriggerTitle.
  ///
  /// In tr, this message translates to:
  /// **'Ne oldu?'**
  String get emTriggerTitle;

  /// No description provided for @emTriggerSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Yargılamak yok. Sadece şu an ne hissettiğini seç, birlikte geçirelim.'**
  String get emTriggerSubtitle;

  /// No description provided for @emTriggerNightSnacking.
  ///
  /// In tr, this message translates to:
  /// **'Gece atıştırma isteği'**
  String get emTriggerNightSnacking;

  /// No description provided for @emTriggerSweetCraving.
  ///
  /// In tr, this message translates to:
  /// **'Tatlı krizi'**
  String get emTriggerSweetCraving;

  /// No description provided for @emTriggerHungerBetweenMeals.
  ///
  /// In tr, this message translates to:
  /// **'Öğün dışı açlık'**
  String get emTriggerHungerBetweenMeals;

  /// No description provided for @emTriggerStressEating.
  ///
  /// In tr, this message translates to:
  /// **'Stres yemesi'**
  String get emTriggerStressEating;

  /// No description provided for @emBreathTitle.
  ///
  /// In tr, this message translates to:
  /// **'Önce bir nefes al'**
  String get emBreathTitle;

  /// No description provided for @emBreathSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'İstek bir dalga gibidir: yükselir ve geçer. 30 saniye boyunca sadece nefesine odaklan.'**
  String get emBreathSubtitle;

  /// No description provided for @emBreathInhale.
  ///
  /// In tr, this message translates to:
  /// **'Nefes al...'**
  String get emBreathInhale;

  /// No description provided for @emBreathExhale.
  ///
  /// In tr, this message translates to:
  /// **'Nefes ver...'**
  String get emBreathExhale;

  /// No description provided for @emBreathDone.
  ///
  /// In tr, this message translates to:
  /// **'Harika. Dalga şimdiden küçülüyor.'**
  String get emBreathDone;

  /// No description provided for @emWaterTitle.
  ///
  /// In tr, this message translates to:
  /// **'Bir bardak su iç'**
  String get emWaterTitle;

  /// No description provided for @emWaterSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Susuzluk çoğu zaman açlık gibi hissettirir. Bir bardak su iç ve istersen 5 dakika beklemeyi dene — istek genellikle bu sürede hafifler.'**
  String get emWaterSubtitle;

  /// No description provided for @emWaterStartTimer.
  ///
  /// In tr, this message translates to:
  /// **'5 dk zamanlayıcı başlat'**
  String get emWaterStartTimer;

  /// No description provided for @emWaterTimerDone.
  ///
  /// In tr, this message translates to:
  /// **'Süre doldu — hâlâ buradaysan çok iyi gidiyorsun 👏'**
  String get emWaterTimerDone;

  /// No description provided for @emAlternativesTitle.
  ///
  /// In tr, this message translates to:
  /// **'Bunlardan birini denemek ister misin?'**
  String get emAlternativesTitle;

  /// No description provided for @emAlternativesSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Küçük bir değişiklik bile isteği yönlendirmeye yeter.'**
  String get emAlternativesSubtitle;

  /// No description provided for @emAltNightSnacking1.
  ///
  /// In tr, this message translates to:
  /// **'Bir fincan bitki çayı demle (papatya veya ıhlamur).'**
  String get emAltNightSnacking1;

  /// No description provided for @emAltNightSnacking2.
  ///
  /// In tr, this message translates to:
  /// **'Dişlerini fırçala — atıştırma isteğini şaşırtıcı biçimde keser.'**
  String get emAltNightSnacking2;

  /// No description provided for @emAltNightSnacking3.
  ///
  /// In tr, this message translates to:
  /// **'Işıkları kıs, telefonu bırak; vücuduna \"gün bitti\" sinyali ver.'**
  String get emAltNightSnacking3;

  /// No description provided for @emAltSweetCraving1.
  ///
  /// In tr, this message translates to:
  /// **'Bir avuç çilek, yaban mersini veya birkaç dilim elma.'**
  String get emAltSweetCraving1;

  /// No description provided for @emAltSweetCraving2.
  ///
  /// In tr, this message translates to:
  /// **'Bir küp bitter çikolata (%70+) — acele etmeden, tadını çıkararak.'**
  String get emAltSweetCraving2;

  /// No description provided for @emAltSweetCraving3.
  ///
  /// In tr, this message translates to:
  /// **'Tarçın serpilmiş yoğurt: tatlı hissi verir, krizi büyütmez.'**
  String get emAltSweetCraving3;

  /// No description provided for @emAltHungerBetweenMeals1.
  ///
  /// In tr, this message translates to:
  /// **'Bir avuç çiğ badem veya ceviz.'**
  String get emAltHungerBetweenMeals1;

  /// No description provided for @emAltHungerBetweenMeals2.
  ///
  /// In tr, this message translates to:
  /// **'Havuç ya da salatalık çubukları — çıtır ama hafif.'**
  String get emAltHungerBetweenMeals2;

  /// No description provided for @emAltHungerBetweenMeals3.
  ///
  /// In tr, this message translates to:
  /// **'Bir bardak ayran veya küçük bir kase yoğurt.'**
  String get emAltHungerBetweenMeals3;

  /// No description provided for @emAltStressEating1.
  ///
  /// In tr, this message translates to:
  /// **'5 dakikalık kısa bir yürüyüş — sadece kapıya kadar bile olur.'**
  String get emAltStressEating1;

  /// No description provided for @emAltStressEating2.
  ///
  /// In tr, this message translates to:
  /// **'Sevdiğin birine iki satır mesaj at; duyguyu yemekle değil sözle boşalt.'**
  String get emAltStressEating2;

  /// No description provided for @emAltStressEating3.
  ///
  /// In tr, this message translates to:
  /// **'Ellerini meşgul et: bir çekmece topla, bulaşığı hallet, esneme yap.'**
  String get emAltStressEating3;

  /// No description provided for @emClosingTitle.
  ///
  /// In tr, this message translates to:
  /// **'Karar senin'**
  String get emClosingTitle;

  /// No description provided for @emClosingBody.
  ///
  /// In tr, this message translates to:
  /// **'Hâlâ istiyorsan sorun değil — bu bir irade savaşı değil. Sadece porsiyonu küçük tut, otur ve acele etmeden ye. Tek bir an, tüm emeğini silmez.'**
  String get emClosingBody;

  /// No description provided for @emOutcomeTitle.
  ///
  /// In tr, this message translates to:
  /// **'Nasıl geçti?'**
  String get emOutcomeTitle;

  /// No description provided for @emOutcomeSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Hangisi olursa olsun, buraya gelmen değerli.'**
  String get emOutcomeSubtitle;

  /// No description provided for @emOutcomeOvercame.
  ///
  /// In tr, this message translates to:
  /// **'Krizi atlattım 💪'**
  String get emOutcomeOvercame;

  /// No description provided for @emOutcomeAteAnyway.
  ///
  /// In tr, this message translates to:
  /// **'Yine de yedim, sorun değil'**
  String get emOutcomeAteAnyway;

  /// No description provided for @emThanksTitle.
  ///
  /// In tr, this message translates to:
  /// **'Teşekkürler 💚'**
  String get emThanksTitle;

  /// No description provided for @emThanksBody.
  ///
  /// In tr, this message translates to:
  /// **'Kriz anında durup buraya gelmek başlı başına bir kazanım. Kendine iyi davranmaya devam et — yarın yeni bir gün.'**
  String get emThanksBody;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'tr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'tr':
      return AppLocalizationsTr();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
