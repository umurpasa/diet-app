import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../config/app_theme.dart';
import '../l10n/app_localizations.dart';
import '../pages/profile_page.dart';

/// Ana sayfaların ortak başlık bloğu (F-6 "C seçeneği"):
/// üstte küçük bağlam satırı (eyebrow), altında karakterli serif başlık,
/// sağda sayfanın aksiyon ikonları + profil avatarı.
///
/// Serif YALNIZ burada — gövde/buton tipografisi tema fontunda kalır.
/// Sekme değişince (widget yeniden mount olduğunda) blok yumuşak fade +
/// hafif yukarı kaymayla girer.
class PageHeader extends StatefulWidget {
  const PageHeader({
    super.key,
    this.eyebrow,
    required this.title,
    this.actions = const [],
    this.showAvatar = true,
    this.profileName,
    this.padding = const EdgeInsets.fromLTRB(20, 20, 20, 12),
  });

  /// Bağlam satırı — sayfaya özgü canlı içerik (tarih, seçili gün, rol...).
  /// Null ise satır hiç çizilmez (ör. Diyetisyen'de atama yokken).
  final String? eyebrow;

  final String title;

  /// Avatarın SOLUNA dizilen sayfa aksiyonları (tune/takvim/more_horiz).
  final List<Widget> actions;

  /// Sağ üstteki profil avatarı (dokununca [ProfilePage] push edilir).
  /// Profil sayfasının kendisinde kapatılır.
  final bool showAvatar;

  /// `profiles.full_name` — HomeScreen açılışta bir kez çeker, tüm
  /// sekmelere aynı notifier'ı geçirir; değer gelince baş harf belirir
  /// (null/boşta kişi ikonu).
  final ValueListenable<String?>? profileName;

  final EdgeInsetsGeometry padding;

  @override
  State<PageHeader> createState() => _PageHeaderState();
}

class _PageHeaderState extends State<PageHeader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _enter = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 250),
  )..forward();

  late final CurvedAnimation _curve =
      CurvedAnimation(parent: _enter, curve: Curves.easeOutCubic);

  @override
  void dispose() {
    _curve.dispose();
    _enter.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final eyebrow = widget.eyebrow;

    return Padding(
      padding: widget.padding,
      child: FadeTransition(
        opacity: _curve,
        child: SlideTransition(
          position: Tween(
            begin: const Offset(0, 0.12),
            end: Offset.zero,
          ).animate(_curve),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (eyebrow != null && eyebrow.isNotEmpty) ...[
                      Text(
                        eyebrow,
                        style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.8,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 4),
                    ],
                    Text(
                      widget.title,
                      style: GoogleFonts.fraunces(
                        fontSize: 30,
                        fontWeight: FontWeight.w600,
                        height: 1.15,
                        color: AppColors.text,
                      ),
                    ),
                  ],
                ),
              ),
              for (final action in widget.actions) ...[
                const SizedBox(width: 8),
                action,
              ],
              if (widget.showAvatar) ...[
                const SizedBox(width: 8),
                _ProfileAvatar(name: widget.profileName),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// 36px daire avatar: `full_name` baş harfi, yoksa kişi ikonu.
/// Dokununca Profil sayfası push edilir (Profil artık nav sekmesi değil).
class _ProfileAvatar extends StatelessWidget {
  const _ProfileAvatar({this.name});

  final ValueListenable<String?>? name;

  Widget _content(String? value) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) {
      return const Icon(Icons.person,
          size: 20, color: AppColors.onPrimaryContainer);
    }
    return Text(
      trimmed[0].toUpperCase(),
      style: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w700,
        color: AppColors.onPrimaryContainer,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final listenable = name;

    return Tooltip(
      message: l10n.profTitle,
      child: Material(
        color: AppColors.primaryContainer,
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const ProfilePage()),
          ),
          child: SizedBox(
            width: 36,
            height: 36,
            child: Center(
              child: listenable == null
                  ? _content(null)
                  : ValueListenableBuilder<String?>(
                      valueListenable: listenable,
                      builder: (context, value, _) => _content(value),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
