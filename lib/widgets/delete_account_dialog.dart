import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/app_theme.dart';
import '../l10n/app_localizations.dart';
import '../utils/error_messages.dart';

/// Hesabı silen asenkron işlem; hata durumunda exception fırlatır.
/// Testlerde sahte bir uygulama enjekte edilebilsin diye parametre.
typedef AccountDeleter = Future<void> Function();

/// `delete-account` Edge Function'ını çağırır.
///
/// Kimlik sunucuda JWT'den alınır; gövdeye kullanıcı id'si KONMAZ.
/// `confirm: 'DELETE'` sunucunun beklediği sabit protokol değeridir —
/// kullanıcının yazdığı (yerelleştirilmiş) onay kelimesiyle ilgisi yoktur.
/// `Features` flag'lerinden bağımsızdır; her zaman açıktır.
Future<void> invokeDeleteAccount() async {
  final res = await Supabase.instance.client.functions.invoke(
    'delete-account',
    body: const {'confirm': 'DELETE'},
  );
  final data = res.data;
  if (res.status != 200 || data is! Map || data['deleted'] != true) {
    throw FunctionException(status: res.status, details: data);
  }
}

/// Onay kelimesi eşleşmesi: yalnızca baştaki/sondaki boşluk kırpılır,
/// birebir karşılaştırılır. Büyük harfe dönüştürme bilerek YAPILMAZ —
/// Dart'ın `toUpperCase`'i locale'den bağımsızdır ('i' → 'I', 'İ' değil),
/// TR'de `SİL` kelimesini bozardı.
bool deleteConfirmMatches(String input, String word) => input.trim() == word;

/// İki adımlı hesap silme akışı. Hesap silindiyse `true` döner; çağıran
/// taraf oturumu kapatıp giriş ekranına dönmekten sorumludur.
Future<bool> showDeleteAccountFlow(
  BuildContext context, {
  AccountDeleter deleter = invokeDeleteAccount,
}) async {
  final proceed = await showDialog<bool>(
    context: context,
    builder: (_) => const DeleteAccountWarningDialog(),
  );
  if (proceed != true || !context.mounted) return false;

  final deleted = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (_) => DeleteAccountConfirmDialog(deleter: deleter),
  );
  return deleted == true;
}

/// Adım 1: ne olacağını açıkça anlatır.
class DeleteAccountWarningDialog extends StatelessWidget {
  const DeleteAccountWarningDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AlertDialog(
      icon: const Icon(Icons.warning_amber_rounded, color: AppColors.sos),
      title: Text(l10n.delAccTitle),
      content: SingleChildScrollView(child: Text(l10n.delAccBody)),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(l10n.delAccCancel),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          style: TextButton.styleFrom(foregroundColor: AppColors.sos),
          child: Text(l10n.delAccContinue),
        ),
      ],
    );
  }
}

/// Adım 2: onay kelimesi yazılmadan silme butonu pasif. Silme sırasında
/// butonlar kilitli, geri tuşu kapalı; hatada dialog açık kalır.
class DeleteAccountConfirmDialog extends StatefulWidget {
  const DeleteAccountConfirmDialog({super.key, required this.deleter});

  final AccountDeleter deleter;

  @override
  State<DeleteAccountConfirmDialog> createState() =>
      _DeleteAccountConfirmDialogState();
}

class _DeleteAccountConfirmDialogState
    extends State<DeleteAccountConfirmDialog> {
  final _controller = TextEditingController();
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _delete() async {
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _busy = true);
    try {
      await widget.deleter();
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            isNetworkError(e) ? l10n.connectionError : l10n.delAccFailed,
          ),
          backgroundColor: AppColors.sos,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final word = l10n.delAccConfirmWord;
    final matches = deleteConfirmMatches(_controller.text, word);

    return PopScope(
      canPop: !_busy,
      child: AlertDialog(
        title: Text(l10n.delAccConfirmTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.delAccConfirmPrompt(word)),
            const SizedBox(height: 14),
            TextField(
              key: const ValueKey('deleteConfirmField'),
              controller: _controller,
              enabled: !_busy,
              autofocus: true,
              autocorrect: false,
              enableSuggestions: false,
              textCapitalization: TextCapitalization.characters,
              decoration: InputDecoration(hintText: word),
            ),
            if (_busy) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.sos,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: Text(l10n.delAccDeleting)),
                ],
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: _busy ? null : () => Navigator.pop(context, false),
            child: Text(l10n.delAccCancel),
          ),
          FilledButton(
            key: const ValueKey('deleteConfirmButton'),
            onPressed: matches && !_busy ? _delete : null,
            style: FilledButton.styleFrom(backgroundColor: AppColors.sos),
            child: Text(l10n.delAccConfirmButton),
          ),
        ],
      ),
    );
  }
}
