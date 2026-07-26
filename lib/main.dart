import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'config/app_theme.dart';
import 'config/locale_controller.dart';
import 'config/supabase_config.dart';
import 'l10n/app_localizations.dart';
import 'pages/auth_page.dart';
import 'pages/diet_plan_page.dart';
import 'pages/ai_chat_page.dart';
import 'pages/food_tracking_page.dart';
import 'pages/progress_page.dart';
import 'pages/dietitian_chat_page.dart';
import 'pages/emergency_page.dart';
import 'pages/onboarding/onboarding_data.dart';
import 'pages/onboarding/onboarding_flow.dart';
import 'widgets/mesh_blob.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: SupabaseConfig.url,
    anonKey: SupabaseConfig.anonKey,
  );

  // Kaydedilmiş dil tercihi (varsa) ilk frame'den önce yüklensin ki
  // uygulama yanlış dilde açılıp sonra değişmesin.
  await LocaleController.load();

  runApp(MyApp());
}

/// Uygulama genelinde kısayol.
final supabase = Supabase.instance.client;

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Dil tercihi değişince (LocaleController.set) tüm uygulama yeniden
    // çizilir; tercih yoksa locale null → sistem dili (resolve TR/EN
    // dışında EN'e düşer).
    return ValueListenableBuilder<Locale?>(
      valueListenable: LocaleController.notifier,
      builder: (context, locale, _) {
        return MaterialApp(
          onGenerateTitle: (context) => AppLocalizations.of(context)!.appTitle,
          locale: locale,
          supportedLocales: LocaleController.supported,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          localeResolutionCallback: LocaleController.resolve,
          theme: buildAppTheme(),
          home: const AuthGate(),
          debugShowCheckedModeBanner: false,
        );
      },
    );
  }
}

/// Oturum durumuna göre yönlendirme yapan kapı.
///
/// Supabase'in `onAuthStateChange` akışını dinler: aktif oturum varsa
/// [HomeScreen], yoksa [AuthPage] gösterilir. Giriş/çıkış olduğunda
/// otomatik güncellenir; ekranların manuel navigasyona ihtiyacı olmaz.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: supabase.auth.onAuthStateChange,
      builder: (context, snapshot) {
        // İlk frame'de akış henüz veri üretmemiş olabilir; mevcut oturumu
        // doğrudan istemciden okuyarak yanıp sönmeyi (flicker) önlüyoruz.
        final session = snapshot.data?.session ?? supabase.auth.currentSession;

        if (session != null) {
          // Kullanıcı id'siyle key'lenir: token yenileme gibi auth state
          // değişimlerinde state korunur, onboarding kontrolü tekrarlanmaz.
          return OnboardingGate(
            key: ValueKey(session.user.id),
            userId: session.user.id,
          );
        }
        return const AuthPage();
      },
    );
  }
}

/// Oturum açıldığında bir kez `health_profiles.preferences`'ı okuyup karar
/// verir: `onboarding_completed == true` ise [HomeScreen], değilse (kayıt
/// yok dahil) [OnboardingFlow] — kısmi kayıt varsa kaldığı adımdan. Okuma
/// hatasında (offline vb.) HomeScreen'e düşer, kullanıcı onboarding'e
/// hapsedilmez.
class OnboardingGate extends StatefulWidget {
  const OnboardingGate({super.key, required this.userId});

  final String userId;

  @override
  State<OnboardingGate> createState() => _OnboardingGateState();
}

class _OnboardingGateState extends State<OnboardingGate> {
  bool _loading = true;
  bool _showOnboarding = false;
  int _initialPage = 0;
  int _homeTab = 0;
  OnboardingData _data = OnboardingData();
  Map<String, dynamic> _preferences = {};

  @override
  void initState() {
    super.initState();
    _check();
  }

  Future<void> _check() async {
    try {
      final row = await supabase
          .from('health_profiles')
          .select('age, height_cm, weight_kg, preferences')
          .eq('user_id', widget.userId)
          .maybeSingle();

      final prefs =
          Map<String, dynamic>.from(row?['preferences'] as Map? ?? const {});

      if (prefs['onboarding_completed'] == true) {
        if (mounted) setState(() => _loading = false);
        return;
      }

      // Kısmi kayıt: tamamlanan son adım + 1'den devam (hoş geldin atlanır).
      final savedStep = prefs['onboarding_step'];
      final resumePage = (savedStep is int && savedStep >= 1)
          ? (savedStep + 1).clamp(1, 8)
          : 0;

      // Geri dönülürse isim alanı dolu gelsin diye kayıtlı ad da çekilir.
      String? fullName;
      if (resumePage > 0) {
        final profile = await supabase
            .from('profiles')
            .select('full_name')
            .eq('id', widget.userId)
            .maybeSingle();
        fullName = profile?['full_name'] as String?;
      }

      if (mounted) {
        setState(() {
          _data = OnboardingData.restore(
            preferences: prefs,
            row: row,
            fullName: fullName,
          );
          _preferences = prefs;
          _initialPage = resumePage;
          _showOnboarding = true;
          _loading = false;
        });
      }
    } catch (_) {
      // Offline vb. — ana ekrana düş.
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (_showOnboarding) {
      return OnboardingFlow(
        data: _data,
        preferences: _preferences,
        initialPage: _initialPage,
        onCompleted: (tab) => setState(() {
          _homeTab = tab;
          _showOnboarding = false;
        }),
        onExit: () => setState(() {
          _homeTab = 0;
          _showOnboarding = false;
        }),
      );
    }
    return HomeScreen(initialIndex: _homeTab);
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, this.initialIndex = 0});

  /// Açılışta seçili sekme (onboarding "İlk planımı oluştur" → Diyet Planı).
  final int initialIndex;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late int _selectedIndex = widget.initialIndex;

  /// Sayfa başlıklarındaki avatar için `profiles.full_name` — açılışta bir
  /// kez çekilir, tüm sekmelere aynı notifier geçirilir (F-6: Profil
  /// sekmesi kalktı, profil sağ üst avatardan push edilir).
  final ValueNotifier<String?> _profileName = ValueNotifier<String?>(null);

  // Sayfalar listesi (late: AI CTA callback'i instance metoduna erişir).
  // Sıra = nav sırası: Diyet Planı, Yemek | SOS | İlerleme, Danışman,
  // Diyetisyen. Index değişirse onboarding _finish() hedefi de güncellenmeli.
  late final List<Widget> _pages = [
    DietPlanPage(profileName: _profileName),
    FoodTrackingPage(profileName: _profileName),
    ProgressPage(profileName: _profileName),
    AIChatPage(profileName: _profileName),
    DietitianChatPage(
      profileName: _profileName,
      onOpenAiChat: () => _onItemTapped(3),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _loadProfileName();
  }

  @override
  void dispose() {
    _profileName.dispose();
    super.dispose();
  }

  Future<void> _loadProfileName() async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return;
    try {
      final row = await supabase
          .from('profiles')
          .select('full_name')
          .eq('id', userId)
          .maybeSingle();
      _profileName.value = row?['full_name'] as String?;
    } catch (_) {
      // Offline vb. — avatar kişi ikonuyla kalır.
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _openEmergency() {
    Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => const EmergencyPage(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // extendBody bilinçli false: sayfaların kendi FAB'ları (Yemek Takibi,
    // İlerleme) hapın arkasına girmesin.
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: _PillNavBar(
        selectedIndex: _selectedIndex,
        onTap: _onItemTapped,
        onSosPressed: _openEmergency,
      ),
    );
  }
}

/// Yüzen hap alt navigasyon: 2 sekme + ortada hafif taşan SOS dairesi +
/// 3 sekme (F-6: Profil sekmesi kalktı — profil, başlıklardaki avatardan).
/// Danışman sekmesinin ikonu ikon değil canlı [FlatBlob] — nav'daki AI
/// varlığı. Acil buton tüm sekmelerde buradan erişilir (F-4a, 2026-07-08).
class _PillNavBar extends StatelessWidget {
  const _PillNavBar({
    required this.selectedIndex,
    required this.onTap,
    required this.onSosPressed,
  });

  final int selectedIndex;
  final ValueChanged<int> onTap;
  final VoidCallback onSosPressed;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    // Danışman (index 3) ikonsuz: _NavTab null ikonu FlatBlob olarak çizer.
    final items = <(IconData?, String)>[
      (Icons.restaurant_menu, l10n.tabDietPlan),
      (Icons.food_bank, l10n.tabFoodTracking),
      (Icons.show_chart, l10n.tabProgress),
      (null, l10n.tabAiChat),
      (Icons.support_agent, l10n.tabDietitian),
    ];

    // Seçili sekme etiketiyle birlikte genişler; dar ekranda taşmasın diye
    // seçiliye daha büyük flex verilir.
    Widget tab(int index) {
      final (icon, label) = items[index];
      final selected = index == selectedIndex;
      return Expanded(
        flex: selected ? 2 : 1,
        child: _NavTab(
          icon: icon,
          label: label,
          selected: selected,
          onTap: () => onTap(index),
        ),
      );
    }

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(32),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Material(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(32),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: Row(
                children: [
                  for (var i = 0; i < 2; i++) tab(i),
                  _SosButton(
                    onPressed: onSosPressed,
                    label: l10n.navEmergency,
                  ),
                  for (var i = 2; i < 5; i++) tab(i),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavTab extends StatelessWidget {
  const _NavTab({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  /// Null → sekmenin ikonu canlı [FlatBlob] (AI varlığı); blob seçilmemişken
  /// de renkli kalır — varlık gri "sönmüş" ikona düşmez.
  final IconData? icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  Widget _iconWidget() {
    final icon = this.icon;
    if (icon == null) {
      return FlatBlob(size: selected ? 22 : 26);
    }
    return Icon(
      icon,
      size: selected ? 20 : 24,
      color: selected ? AppColors.onPrimaryContainer : AppColors.textSecondary,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      selected: selected,
      button: true,
      child: Tooltip(
        message: label,
        child: InkWell(
          onTap: onTap,
          customBorder: const StadiumBorder(),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            height: 44,
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color: selected ? AppColors.primaryContainer : Colors.transparent,
              borderRadius: BorderRadius.circular(22),
            ),
            child: selected
                ? Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _iconWidget(),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          label,
                          maxLines: 1,
                          softWrap: false,
                          overflow: TextOverflow.fade,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.onPrimaryContainer,
                          ),
                        ),
                      ),
                    ],
                  )
                : _iconWidget(),
          ),
        ),
      ),
    );
  }
}

class _SosButton extends StatelessWidget {
  const _SosButton({required this.onPressed, required this.label});

  final VoidCallback onPressed;
  final String label;

  @override
  Widget build(BuildContext context) {
    // 48'lik satır yüksekliğinde 56'lık daire: OverflowBox + yukarı kaydırma
    // ile bar'dan bir tık taşar.
    return SizedBox(
      width: 64,
      height: 48,
      child: OverflowBox(
        minWidth: 56,
        maxWidth: 56,
        minHeight: 56,
        maxHeight: 56,
        child: Transform.translate(
          offset: const Offset(0, -8),
          child: Tooltip(
            message: label,
            child: Material(
              color: AppColors.sos,
              shape: const CircleBorder(),
              elevation: 2,
              shadowColor: Colors.black.withValues(alpha: 0.3),
              child: InkWell(
                onTap: onPressed,
                customBorder: const CircleBorder(),
                child: const SizedBox(
                  width: 56,
                  height: 56,
                  child: Icon(Icons.sos, color: Colors.white),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
