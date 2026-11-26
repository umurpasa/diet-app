import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/app_theme.dart';
import '../config/legal.dart';
import '../l10n/app_localizations.dart';
import '../widgets/page_header.dart';
import 'legal_page.dart';
import 'onboarding/onboarding_widgets.dart';

/// Açık rıza ekranı (KVKK m.6/2 — sağlık verisi).
///
/// `OnboardingGate`, `profiles.consent_version != Legal.consentVersion` ise
/// onboarding'den ve ana ekrandan ÖNCE bunu gösterir. Kutu varsayılan
/// işaretsiz; işaretlenmeden "Devam et" pasif. Kabulde istemci yalnızca
/// `consent_version`'ı yazar — `consent_at`'i sunucudaki trigger damgalar.
/// Reddetmek = çıkış. Geri tuşuyla atlanamaz.
class ConsentPage extends StatefulWidget {
  const ConsentPage({
    super.key,
    required this.userId,
    required this.onAccepted,
  });

  final String userId;

  /// Rıza kaydedildi: akış devam eder (onboarding ya da ana ekran).
  final VoidCallback onAccepted;

  @override
  State<ConsentPage> createState() => _ConsentPageState();
}

class _ConsentPageState extends State<ConsentPage> {
  final _supabase = Supabase.instance.client;

  bool _checked = false;
  bool _saving = false;

  void _showError(String text) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(text),
        backgroundColor: AppColors.sos,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _accept() async {
    if (!_checked || _saving) return;
    final l10n = AppLocalizations.of(context)!;
    setState(() => _saving = true);
    try {
      // .select() ile geri okunur: RLS/GRANT satırı sessizce eleseydi
      // (0 satır güncellendi) hata yok gibi görünürdü.
      final row = await _supabase
          .from('profiles')
          .update({'consent_version': Legal.consentVersion})
          .eq('id', widget.userId)
          .select('consent_version')
          .maybeSingle();
      if (row?['consent_version'] != Legal.consentVersion) {
        throw StateError('consent not stored');
      }
      if (mounted) widget.onAccepted();
    } catch (_) {
      if (mounted) {
        _showError(l10n.consentSaveFailed);
        setState(() => _saving = false);
      }
    }
  }

  Future<void> _decline() async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.consentDeclineTitle),
        content: Text(l10n.consentDeclineBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.commonCancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.consentDeclineConfirm),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      // AuthGate oturum kapanınca AuthPage'e döner.
      await _supabase.auth.signOut();
    }
  }

  void _openNotice() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const LegalPage()),
    );
  }

  Widget _point(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: const BoxDecoration(
              color: AppColors.primaryContainer,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 18, color: AppColors.onPrimaryContainer),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                text,
                style: const TextStyle(
                  fontSize: 14.5,
                  height: 1.45,
                  color: AppColors.text,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    // Geri tuşu rızayı atlatmasın (kök ekran — pop uygulamayı kapatırdı).
    return PopScope(
      canPop: false,
      child: Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
                  children: [
                    PageHeader(
                      eyebrow: l10n.consentEyebrow,
                      title: l10n.consentTitle,
                      showAvatar: false,
                      padding: const EdgeInsets.only(bottom: 14),
                    ),
                    Text(
                      l10n.consentIntro,
                      style: const TextStyle(
                        fontSize: 15,
                        height: 1.45,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 18),
                    Container(
                      padding: const EdgeInsets.fromLTRB(16, 18, 16, 4),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: onbSoftShadow,
                      ),
                      child: Column(
                        children: [
                          _point(Icons.monitor_heart_outlined,
                              l10n.consentPointData),
                          _point(Icons.cloud_outlined,
                              l10n.consentPointStorage),
                          _point(Icons.lock_outline,
                              l10n.consentPointNoSharing),
                          _point(Icons.undo, l10n.consentPointWithdraw),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton.icon(
                        onPressed: _openNotice,
                        icon: const Icon(Icons.description_outlined, size: 20),
                        label: Text(l10n.consentReadNotice),
                      ),
                    ),
                    const SizedBox(height: 4),
                    // Varsayılan işaretsiz onay kutusu — metne dokunmak da
                    // kutuyu değiştirir.
                    Material(
                      color: _checked
                          ? AppColors.primaryContainer
                          : AppColors.fieldFill,
                      borderRadius: BorderRadius.circular(16),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: _saving
                            ? null
                            : () => setState(() => _checked = !_checked),
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(6, 10, 16, 12),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Checkbox(
                                value: _checked,
                                onChanged: _saving
                                    ? null
                                    : (v) =>
                                        setState(() => _checked = v ?? false),
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.only(top: 12),
                                  child: Text(
                                    l10n.consentCheckbox,
                                    style: const TextStyle(
                                      fontSize: 14.5,
                                      height: 1.45,
                                      color: AppColors.text,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    OnbPrimaryButton(
                      label: l10n.consentContinue,
                      loading: _saving,
                      onPressed: _checked && !_saving ? _accept : null,
                    ),
                    const SizedBox(height: 6),
                    TextButton(
                      onPressed: _saving ? null : _decline,
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.textSecondary,
                      ),
                      child: Text(l10n.consentDecline),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
