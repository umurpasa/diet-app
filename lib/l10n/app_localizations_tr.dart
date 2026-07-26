// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Turkish (`tr`).
class AppLocalizationsTr extends AppLocalizations {
  AppLocalizationsTr([String locale = 'tr']) : super(locale);

  @override
  String get appTitle => 'Diet App';

  @override
  String get tabDietPlan => 'Diyet Plan';

  @override
  String get tabFoodTracking => 'Yemek Takibi';

  @override
  String get tabProgress => 'İlerleme';

  @override
  String get tabAiChat => 'AI Sohbet';

  @override
  String get tabDietitian => 'Diyetisyen';

  @override
  String get navEmergency => 'Acil Destek';

  @override
  String get pgHeaderEyebrow => 'Yolculuğun';

  @override
  String get chatHeaderEyebrow => 'Her zaman burada';

  @override
  String get profileHeaderEyebrow => 'Hesabın';

  @override
  String get authWelcomeBack => 'Tekrar hoş geldin';

  @override
  String get authCreateAccount => 'Hesap oluştur';

  @override
  String get authLoginSubtitle => 'Devam etmek için giriş yap.';

  @override
  String get authSignupSubtitle => 'Başlamak için birkaç saniye yeter.';

  @override
  String get authEmailLabel => 'E-posta';

  @override
  String get authPasswordLabel => 'Şifre';

  @override
  String get authEmailRequired => 'E-posta gerekli';

  @override
  String get authEmailInvalid => 'Geçerli bir e-posta gir';

  @override
  String get authPasswordRequired => 'Şifre gerekli';

  @override
  String get authPasswordTooShort => 'Şifre en az 6 karakter olmalı';

  @override
  String get authPasswordHelper => 'En az 6 karakter';

  @override
  String get authLoginButton => 'Giriş yap';

  @override
  String get authSignupButton => 'Kayıt ol';

  @override
  String get authToggleToSignup => 'Hesabın yok mu? Kayıt ol';

  @override
  String get authToggleToLogin => 'Zaten hesabın var mı? Giriş yap';

  @override
  String get authSignupSuccess =>
      'Kayıt başarılı. E-postana gönderilen doğrulama bağlantısına tıkladıktan sonra giriş yapabilirsin.';

  @override
  String get connectionError =>
      'Bağlantı hatası. İnternet bağlantını kontrol edip tekrar dene.';

  @override
  String unexpectedError(String error) {
    return 'Beklenmeyen bir hata oluştu: $error';
  }

  @override
  String get commonSave => 'Kaydet';

  @override
  String get commonCancel => 'İptal';

  @override
  String get commonClose => 'Kapat';

  @override
  String get commonRetry => 'Tekrar dene';

  @override
  String get commonLoading => 'Yükleniyor...';

  @override
  String get commonDelete => 'Sil';

  @override
  String get commonNext => 'Devam';

  @override
  String get commonSkip => 'Geç';

  @override
  String get languageTooltip => 'Dil / Language';

  @override
  String get languageTurkish => 'Türkçe';

  @override
  String get languageEnglish => 'English';

  @override
  String onbStepCounter(int step) {
    return 'Adım $step/8';
  }

  @override
  String get onbNext => 'Devam et';

  @override
  String get onbBackTooltip => 'Geri';

  @override
  String get onbExitTooltip => 'Çık';

  @override
  String get onbResumeToast => 'Kaldığın yerden devam ediyoruz 👋';

  @override
  String get onbSessionLost => 'Oturum bulunamadı. Lütfen tekrar giriş yap.';

  @override
  String onbSaveFailed(String message) {
    return 'Kaydedilemedi: $message';
  }

  @override
  String get onbWelcomeStart => 'Başla';

  @override
  String get introLine1 => 'Merhaba.';

  @override
  String get introLine2 => 'Bundan böyle bu yolculukta yanındayım.';

  @override
  String get introLine3 =>
      'Önce seni tanımak istiyorum — sadece 2 dakika. Hazırsan başlayalım.';

  @override
  String get introTapHint => 'devam etmek için dokun';

  @override
  String get onbIdentityTitle => 'Kendini tanıtır mısın?';

  @override
  String get onbIdentityWhy =>
      'Yaşın ve cinsiyetin, günlük enerji ihtiyacını doğru hesaplayabilmemiz için gerekli.';

  @override
  String get onbNameLabel => 'Adın';

  @override
  String get onbAgeLabel => 'Yaşın';

  @override
  String get onbSexLabel => 'Cinsiyetin';

  @override
  String get onbSexFemale => 'Kadın';

  @override
  String get onbSexMale => 'Erkek';

  @override
  String get onbSexUnspecified => 'Belirtmek istemiyorum';

  @override
  String get onbBodyTitle => 'Vücut ölçülerin';

  @override
  String get onbBodyWhy =>
      'Boy ve kilon, sana uygun kalori hedefini belirlememizin temeli.';

  @override
  String get onbHeightLabel => 'Boy (cm)';

  @override
  String get onbWeightLabel => 'Kilo (kg)';

  @override
  String get onbMeasurementsLabel => 'Bel ve kalça çevresi (opsiyonel)';

  @override
  String get onbMeasurementsHint =>
      'Mezuran yoksa geçebilirsin — girersen ilerlemeni takip etmek için güzel bir başlangıç olur.';

  @override
  String get onbWaistLabel => 'Bel (cm)';

  @override
  String get onbHipLabel => 'Kalça (cm)';

  @override
  String get onbGoalTitle => 'Hedefin ne?';

  @override
  String get onbGoalWhy =>
      'Planını ve önerilerimizi tamamen bu hedefe göre şekillendireceğiz.';

  @override
  String get onbGoalLose => 'Kilo vermek';

  @override
  String get onbGoalGain => 'Kilo almak';

  @override
  String get onbGoalMaintain => 'Kilomu korumak';

  @override
  String get onbGoalHealthy => 'Sadece sağlıklı beslenmek';

  @override
  String get onbTargetWeightLabel => 'Hedef kilo (kg, opsiyonel)';

  @override
  String get onbPaceLabel => 'Nasıl bir tempo istersin?';

  @override
  String get onbPaceSlow => 'Yavaş ve sürdürülebilir';

  @override
  String get onbPaceBalanced => 'Dengeli';

  @override
  String get onbPaceFast => 'Hızlı';

  @override
  String get onbHealthTitle => 'Sağlık durumun';

  @override
  String get onbHealthWhy =>
      'Kronik durumlar ve alerjiler, planının senin için güvenli olmasını sağlayan en önemli bilgiler.';

  @override
  String get onbConditionsLabel => 'Kronik bir durumun var mı?';

  @override
  String get onbConditionDiabetes => 'Diyabet';

  @override
  String get onbConditionInsulinResistance => 'İnsülin direnci';

  @override
  String get onbConditionHypertension => 'Yüksek tansiyon';

  @override
  String get onbConditionThyroid => 'Tiroid';

  @override
  String get onbConditionCholesterol => 'Kolesterol';

  @override
  String get onbOptionOther => 'Diğer';

  @override
  String get onbOptionNone => 'Yok';

  @override
  String get onbConditionsOtherLabel => 'Diğer durumunu yazar mısın?';

  @override
  String get onbMedicationsLabel => 'Düzenli kullandığın ilaç (opsiyonel)';

  @override
  String get onbAllergiesLabel => 'Alerjin veya intoleransın var mı?';

  @override
  String get onbAllergyGluten => 'Gluten';

  @override
  String get onbAllergyLactose => 'Laktoz';

  @override
  String get onbAllergyNuts => 'Fındık / fıstık';

  @override
  String get onbAllergySeafood => 'Deniz ürünleri';

  @override
  String get onbAllergyEgg => 'Yumurta';

  @override
  String get onbAllergiesOtherLabel => 'Diğer alerjini yazar mısın?';

  @override
  String get onbLifestyleTitle => 'Yaşam tarzın';

  @override
  String get onbLifestyleWhy =>
      'Gün içindeki hareketin ve alışkanlıkların, kalori ihtiyacını doğrudan etkiler.';

  @override
  String get onbActivityLabel => 'Hareket düzeyin';

  @override
  String get onbActivitySedentary => 'Masa başı — hareketsiz';

  @override
  String get onbActivityLight => 'Az hareketli';

  @override
  String get onbActivityModerate => 'Orta';

  @override
  String get onbActivityActive => 'Aktif';

  @override
  String get onbActivityVeryActive => 'Çok aktif';

  @override
  String get onbWaterLabel => 'Günde kaç bardak su içersin?';

  @override
  String get onbSleepLabel => 'Uykun (opsiyonel)';

  @override
  String get onbSleepLt5 => '5 saatten az';

  @override
  String get onbSleep5to6 => '5-6 saat';

  @override
  String get onbSleep7to8 => '7-8 saat';

  @override
  String get onbSleep8plus => '8 saatten çok';

  @override
  String get onbSmokingLabel => 'Sigara (opsiyonel)';

  @override
  String get onbAlcoholLabel => 'Alkol (opsiyonel)';

  @override
  String get onbHabitOccasional => 'Ara sıra';

  @override
  String get onbHabitRegular => 'Düzenli';

  @override
  String get onbHabitsTitle => 'Beslenme alışkanlıkların';

  @override
  String get onbHabitsWhy =>
      'Gerçek düzenini bilirsek, plan hayatına çok daha kolay oturur.';

  @override
  String get onbMealsLabel => 'Günde kaç öğün yersin?';

  @override
  String get onbBreakfastLabel => 'Kahvaltıyı atlar mısın?';

  @override
  String get onbBreakfastNever => 'Hiç atlamam';

  @override
  String get onbBreakfastSometimes => 'Bazen';

  @override
  String get onbBreakfastOften => 'Çoğu gün';

  @override
  String get onbEatingOutLabel =>
      'Ne sıklıkla dışarıda yer veya sipariş verirsin?';

  @override
  String get onbEatingOutRarely => 'Nadiren';

  @override
  String get onbEatingOutWeekly12 => 'Haftada 1-2';

  @override
  String get onbEatingOutWeekly3plus => 'Haftada 3+';

  @override
  String get onbEatingOutDaily => 'Her gün';

  @override
  String get onbWeakMomentsLabel => 'Zayıf anların hangileri?';

  @override
  String get onbWeakNightSnacking => 'Gece atıştırması';

  @override
  String get onbWeakSweetCraving => 'Tatlı krizi';

  @override
  String get onbWeakHungerBetweenMeals => 'Öğün dışı açlık';

  @override
  String get onbWeakStressEating => 'Stres yemesi';

  @override
  String get onbPrefsTitle => 'Beslenme tercihlerin';

  @override
  String get onbPrefsWhy =>
      'Sevmediğin yiyecekleri plana hiç koymayalım — sürdürülebilirlik böyle başlar.';

  @override
  String get onbDietStyleLabel => 'Beslenme tarzın';

  @override
  String get onbDietOmnivore => 'Hepçil';

  @override
  String get onbDietVegetarian => 'Vejetaryen';

  @override
  String get onbDietVegan => 'Vegan';

  @override
  String get onbDislikedLabel => 'Sevmediğin yiyecekler (opsiyonel)';

  @override
  String get onbDislikedFieldLabel => 'Yemek istemediklerin';

  @override
  String get onbDislikedHint => 'Örn. brokoli, sakatat, mantar...';

  @override
  String get onbSummaryTitle => 'Profilin hazır 🎉';

  @override
  String get onbSummarySubtitle =>
      'İşte anlattıkların. Bunları istediğin zaman profilinden güncelleyebilirsin.';

  @override
  String get onbSummaryName => 'İsim';

  @override
  String get onbSummaryAge => 'Yaş';

  @override
  String get onbSummaryBody => 'Boy / Kilo';

  @override
  String get onbSummaryGoal => 'Hedef';

  @override
  String get onbSummaryAllergies => 'Alerji / intolerans';

  @override
  String get onbSummaryStart => 'Başlayalım';

  @override
  String get onbSummaryCreatePlan => 'İlk planımı oluştur';

  @override
  String get profTitle => 'Profil';

  @override
  String get profNotFilled => 'Henüz doldurulmadı';

  @override
  String get profSaved => 'Kaydedildi ✓';

  @override
  String profLoadFailed(String message) {
    return 'Profil yüklenemedi: $message';
  }

  @override
  String profAgeValue(int age) {
    return '$age yaş';
  }

  @override
  String get profSectionIdentity => 'Kişisel bilgiler';

  @override
  String get profSectionBody => 'Vücut';

  @override
  String get profSectionGoal => 'Hedef';

  @override
  String get profSectionHealth => 'Sağlık';

  @override
  String get profSectionLifestyle => 'Yaşam tarzı';

  @override
  String get profSectionHabits => 'Alışkanlıklar';

  @override
  String get profSectionPrefs => 'Tercihler';

  @override
  String get profSectionAccount => 'Hesap';

  @override
  String get profConditionsShort => 'Kronik';

  @override
  String get profAllergiesShort => 'Alerji';

  @override
  String get profMedicationsShort => 'İlaç';

  @override
  String get profWaterShort => 'Su';

  @override
  String get profSleepShort => 'Uyku';

  @override
  String get profSmokingShort => 'Sigara';

  @override
  String get profAlcoholShort => 'Alkol';

  @override
  String get profMealsShort => 'Öğün';

  @override
  String get profBreakfastShort => 'Kahvaltı atlama';

  @override
  String get profEatingOutShort => 'Dışarıda yeme';

  @override
  String get profWeakShort => 'Zayıf anlar';

  @override
  String get profDislikedShort => 'Sevmedikleri';

  @override
  String get profBodyNote =>
      'Kilo takibin İlerleme sayfasında — buraya güncel kilonu yaz. Bel/kalça ölçüleri de orada güncellenecek.';

  @override
  String get profEmailLabel => 'E-posta';

  @override
  String get profChangePassword => 'Şifre değiştir';

  @override
  String get profNewPasswordLabel => 'Yeni şifre';

  @override
  String get profNewPasswordRepeatLabel => 'Yeni şifre (tekrar)';

  @override
  String get profPasswordMismatch => 'Şifreler eşleşmiyor';

  @override
  String get profPasswordChanged => 'Şifren güncellendi ✓';

  @override
  String get profLanguageLabel => 'Dil';

  @override
  String get profSignOut => 'Çıkış yap';

  @override
  String get profSignOutConfirm => 'Oturumu kapatmak istediğine emin misin?';

  @override
  String get dietPlanTitle => 'Diyet Planı';

  @override
  String get dpMenuTooltip => 'Plan seçenekleri';

  @override
  String get dpMenuRevise => 'Planı revize et';

  @override
  String get dpMenuRegenerate => 'Sıfırdan yeni plan';

  @override
  String get dpRegenerateConfirm =>
      'Mevcut plan tamamen yenisiyle değiştirilecek ve günlük AI hakkından 1 kullanılacak. Devam etmek istiyor musun?';

  @override
  String get dpRegenerateContinue => 'Devam';

  @override
  String get dpKcalPerDay => 'kcal/gün';

  @override
  String get dpMacroCarb => 'Karb';

  @override
  String get dpMacroProtein => 'Protein';

  @override
  String get dpMacroFat => 'Yağ';

  @override
  String get dayShortMon => 'Pzt';

  @override
  String get dayShortTue => 'Sal';

  @override
  String get dayShortWed => 'Çar';

  @override
  String get dayShortThu => 'Per';

  @override
  String get dayShortFri => 'Cum';

  @override
  String get dayShortSat => 'Cmt';

  @override
  String get dayShortSun => 'Paz';

  @override
  String get dpMealBreakfast => 'Kahvaltı';

  @override
  String get dpMealLunch => 'Öğle Yemeği';

  @override
  String get dpMealDinner => 'Akşam Yemeği';

  @override
  String get dpMealSnack => 'Ara Öğün';

  @override
  String get dpMealDefault => 'Öğün';

  @override
  String get dpEmptyMessage =>
      'Henüz bir diyet planın yok.\nSana özel ilk planını hemen oluşturalım.';

  @override
  String get dpCreateFirstPlan => 'İlk planımı oluştur';

  @override
  String get dpNoMealsForDay => 'Bu gün için öğün bulunamadı.';

  @override
  String get dpRevisePrompt => 'Plandan memnun olmadığın noktaları seç:';

  @override
  String get dpReasonDisliked => 'Sevmedim';

  @override
  String get dpReasonHardToPrepare => 'Hazırlaması zor';

  @override
  String get dpReasonIngredientsUnavailable => 'Malzemeleri bulamıyorum';

  @override
  String get dpReviseNoteLabel => 'Not (isteğe bağlı)';

  @override
  String get dpReviseNoteHint => 'Örn. akşamları balık istemiyorum';

  @override
  String get dpReviseValidation => 'En az bir neden seç veya bir not yaz.';

  @override
  String get dpReviseSubmit => 'Gönder';

  @override
  String get ftTitle => 'Yemek Takibi';

  @override
  String get ftToday => 'Bugün';

  @override
  String get ftYesterday => 'Dün';

  @override
  String get ftWaterTitle => 'Su Takibi';

  @override
  String ftGlasses(int count) {
    return '$count bardak';
  }

  @override
  String get ftMealBreakfast => 'Kahvaltı';

  @override
  String get ftMealLunch => 'Öğle Yemeği';

  @override
  String get ftMealDinner => 'Akşam Yemeği';

  @override
  String get ftMealSnack => 'Ara Öğün';

  @override
  String get ftEmptyDay => 'Bu gün için henüz yemek kaydı yok.';

  @override
  String get ftEmptyCta => 'İlk öğününü ekle';

  @override
  String get ftAddTooltip => 'Yemek ekle';

  @override
  String get ftAddSheetTitle => 'Yemek Ekle';

  @override
  String get ftRecentLabel => 'Son eklenenler';

  @override
  String get ftFoodName => 'Yiyecek adı';

  @override
  String get ftCalories => 'Kalori (kcal)';

  @override
  String get ftNameRequired => 'Yiyecek adı gerekli';

  @override
  String get ftCaloriesRequired => 'Kalori gerekli';

  @override
  String get ftCaloriesInvalid => 'Geçerli bir kalori değeri gir';

  @override
  String get ftAdd => 'Ekle';

  @override
  String ftLoadError(String message) {
    return 'Kayıtlar yüklenemedi: $message';
  }

  @override
  String ftAddError(String message) {
    return 'Eklenemedi: $message';
  }

  @override
  String ftDeleteError(String message) {
    return 'Silinemedi: $message';
  }

  @override
  String ftWaterError(String message) {
    return 'Su kaydı güncellenemedi: $message';
  }

  @override
  String get pgTitle => 'İlerleme';

  @override
  String get pgToday => 'Bugün';

  @override
  String get pgYesterday => 'Dün';

  @override
  String get pgHeroEmpty =>
      'Henüz kilo kaydın yok.\nİlk ölçümünle yolculuğun başlasın.';

  @override
  String get pgAddFirst => 'İlk ölçümünü ekle';

  @override
  String pgJourneyRange(String start, String target) {
    return 'Başlangıç $start kg → hedef $target kg';
  }

  @override
  String pgToGoal(String kg) {
    return 'Hedefe $kg kg kaldı';
  }

  @override
  String get pgGoalReached => 'Hedefine ulaştın 🎉';

  @override
  String pgTotalChange(String change) {
    return 'Başlangıçtan bu yana $change';
  }

  @override
  String get pgMeasurementsTitle => 'Vücut Ölçüleri';

  @override
  String get pgWaist => 'Bel';

  @override
  String get pgHip => 'Kalça';

  @override
  String get pgMeasurementsEmpty => 'Henüz bel/kalça ölçüsü yok.';

  @override
  String get pgMeasurementsCta => 'Ölçüm ekle';

  @override
  String get pgWeightChart => 'Kilo';

  @override
  String get pgCaloriesChart => 'Kalori';

  @override
  String get pgWaterChart => 'Su (bardak)';

  @override
  String get pgLast30Days => 'Son 30 gün';

  @override
  String get pgLast7Days => 'Son 7 gün';

  @override
  String get pgWeightEmpty =>
      'Grafik için en az 2 kilo girişi gerekli.\nSağ alttaki + ile ölçüm ekle.';

  @override
  String get pgCaloriesEmpty =>
      'Son 7 günde yemek kaydı yok.\nYemek Takibi sekmesinden ekleyebilirsin.';

  @override
  String get pgWaterEmpty =>
      'Son 7 günde su kaydı yok.\nYemek Takibi sekmesinden ekleyebilirsin.';

  @override
  String get pgAddTooltip => 'Ölçüm ekle';

  @override
  String get pgSheetTitle => 'Ölçüm Ekle';

  @override
  String get pgWeightField => 'Kilo (kg)';

  @override
  String get pgWaistField => 'Bel (cm)';

  @override
  String get pgHipField => 'Kalça (cm)';

  @override
  String get pgAtLeastOne => 'En az bir alanı doldurmalısın.';

  @override
  String get pgInvalidValue => 'Geçerli bir değer gir';

  @override
  String get pgDateLabel => 'Tarih';

  @override
  String get pgSaved => 'Kaydedildi ✓';

  @override
  String pgLoadError(String message) {
    return 'Veriler yüklenemedi: $message';
  }

  @override
  String pgSaveError(String message) {
    return 'Kaydedilemedi: $message';
  }

  @override
  String get chatTitle => 'Danışman';

  @override
  String get chatWelcome =>
      'Merhaba! Ben senin beslenme ve diyet danışmanınım. Beslenme, diyet veya sağlıklı yaşam hakkında sorularını yanıtlayabilirim.';

  @override
  String get chatHint => 'Bir soru sor...';

  @override
  String get chatSendTooltip => 'Gönder';

  @override
  String get chatMenuTooltip => 'Sohbet seçenekleri';

  @override
  String get chatMenuClear => 'Sohbeti temizle';

  @override
  String get chatClearConfirmTitle => 'Sohbeti temizle';

  @override
  String get chatClearConfirmBody =>
      'Tüm sohbet geçmişin silinecek ve danışman önceki konuşmayı hatırlamaz.';

  @override
  String get chatToday => 'Bugün';

  @override
  String get chatYesterday => 'Dün';

  @override
  String get chatTyping => 'Yazıyor';

  @override
  String get chatLoadError => 'Sohbet geçmişi yüklenemedi.';

  @override
  String get chatErrorReply =>
      'Üzgünüm, yanıt oluşturulurken bir hata oluştu. Lütfen tekrar deneyin.';

  @override
  String get dcTitle => 'Diyetisyen';

  @override
  String get dcTitleDietitian => 'Danışan';

  @override
  String get dcSubtitleUser => 'Diyetisyenin';

  @override
  String get dcSubtitleDietitian => 'Danışanın';

  @override
  String get dcToday => 'Bugün';

  @override
  String get dcYesterday => 'Dün';

  @override
  String get dcNoAssignTitle => 'Henüz diyetisyen atanmadı';

  @override
  String get dcNoAssignBody =>
      'Sana bir diyetisyen atandığında konuşmanız burada başlayacak.';

  @override
  String get dcNoClientTitle => 'Henüz danışan atanmadı';

  @override
  String get dcNoClientBody =>
      'Sana bir danışan atandığında konuşmanız burada başlayacak.';

  @override
  String get dcAskAi => 'Şimdilik Danışman\'a sor';

  @override
  String get dcNoMessages => 'Henüz mesaj yok.\nİlk mesajı sen gönder!';

  @override
  String get dcHint => 'Mesaj yaz...';

  @override
  String get dcSendTooltip => 'Gönder';

  @override
  String dcLoadError(String message) {
    return 'Yüklenemedi: $message';
  }

  @override
  String dcSendError(String message) {
    return 'Gönderilemedi: $message';
  }

  @override
  String get emIntroLine1 => 'Tamam. Buradayım.';

  @override
  String get emIntroLine2 => 'Bunu birlikte atlatacağız.';

  @override
  String get emTriggerTitle => 'Ne oldu?';

  @override
  String get emTriggerSubtitle =>
      'Yargılamak yok. Sadece şu an ne hissettiğini seç, birlikte geçirelim.';

  @override
  String get emTriggerNightSnacking => 'Gece atıştırma isteği';

  @override
  String get emTriggerSweetCraving => 'Tatlı krizi';

  @override
  String get emTriggerHungerBetweenMeals => 'Öğün dışı açlık';

  @override
  String get emTriggerStressEating => 'Stres yemesi';

  @override
  String get emBreathTitle => 'Önce bir nefes al';

  @override
  String get emBreathSubtitle =>
      'İstek bir dalga gibidir: yükselir ve geçer. 30 saniye boyunca sadece nefesine odaklan.';

  @override
  String get emBreathInhale => 'Nefes al...';

  @override
  String get emBreathExhale => 'Nefes ver...';

  @override
  String get emBreathDone => 'Harika. Dalga şimdiden küçülüyor.';

  @override
  String get emWaterTitle => 'Bir bardak su iç';

  @override
  String get emWaterSubtitle =>
      'Susuzluk çoğu zaman açlık gibi hissettirir. Bir bardak su iç ve istersen 5 dakika beklemeyi dene — istek genellikle bu sürede hafifler.';

  @override
  String get emWaterStartTimer => '5 dk zamanlayıcı başlat';

  @override
  String get emWaterTimerDone =>
      'Süre doldu — hâlâ buradaysan çok iyi gidiyorsun 👏';

  @override
  String get emAlternativesTitle => 'Bunlardan birini denemek ister misin?';

  @override
  String get emAlternativesSubtitle =>
      'Küçük bir değişiklik bile isteği yönlendirmeye yeter.';

  @override
  String get emAltNightSnacking1 =>
      'Bir fincan bitki çayı demle (papatya veya ıhlamur).';

  @override
  String get emAltNightSnacking2 =>
      'Dişlerini fırçala — atıştırma isteğini şaşırtıcı biçimde keser.';

  @override
  String get emAltNightSnacking3 =>
      'Işıkları kıs, telefonu bırak; vücuduna \"gün bitti\" sinyali ver.';

  @override
  String get emAltSweetCraving1 =>
      'Bir avuç çilek, yaban mersini veya birkaç dilim elma.';

  @override
  String get emAltSweetCraving2 =>
      'Bir küp bitter çikolata (%70+) — acele etmeden, tadını çıkararak.';

  @override
  String get emAltSweetCraving3 =>
      'Tarçın serpilmiş yoğurt: tatlı hissi verir, krizi büyütmez.';

  @override
  String get emAltHungerBetweenMeals1 => 'Bir avuç çiğ badem veya ceviz.';

  @override
  String get emAltHungerBetweenMeals2 =>
      'Havuç ya da salatalık çubukları — çıtır ama hafif.';

  @override
  String get emAltHungerBetweenMeals3 =>
      'Bir bardak ayran veya küçük bir kase yoğurt.';

  @override
  String get emAltStressEating1 =>
      '5 dakikalık kısa bir yürüyüş — sadece kapıya kadar bile olur.';

  @override
  String get emAltStressEating2 =>
      'Sevdiğin birine iki satır mesaj at; duyguyu yemekle değil sözle boşalt.';

  @override
  String get emAltStressEating3 =>
      'Ellerini meşgul et: bir çekmece topla, bulaşığı hallet, esneme yap.';

  @override
  String get emClosingTitle => 'Karar senin';

  @override
  String get emClosingBody =>
      'Hâlâ istiyorsan sorun değil — bu bir irade savaşı değil. Sadece porsiyonu küçük tut, otur ve acele etmeden ye. Tek bir an, tüm emeğini silmez.';

  @override
  String get emOutcomeTitle => 'Nasıl geçti?';

  @override
  String get emOutcomeSubtitle =>
      'Hangisi olursa olsun, buraya gelmen değerli.';

  @override
  String get emOutcomeOvercame => 'Krizi atlattım 💪';

  @override
  String get emOutcomeAteAnyway => 'Yine de yedim, sorun değil';

  @override
  String get emThanksTitle => 'Teşekkürler 💚';

  @override
  String get emThanksBody =>
      'Kriz anında durup buraya gelmek başlı başına bir kazanım. Kendine iyi davranmaya devam et — yarın yeni bir gün.';
}
