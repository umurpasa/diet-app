import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/app_theme.dart';
import '../l10n/app_localizations.dart';
import '../services/ai_service.dart';
import '../utils/error_messages.dart';
import '../widgets/mesh_blob.dart';
import '../widgets/page_header.dart';

/// "Yazıyor" blob'unun mesh renkleri (shader tam 4 renk ister) — teal
/// ailesi + sıcak ışıltı; açık fieldFill balonunda okunur kalsın diye
/// koyu darkStage yerine primaryContainer.
const List<Color> _typingMeshColors = [
  AppColors.meshA,
  AppColors.meshB,
  AppColors.meshC,
  AppColors.primaryContainer,
];

/// AI beslenme danışmanı sohbeti.
///
/// Mesajlar sunucuda `ai_chats` tablosuna Edge Function ("ai") tarafından
/// yazılır; bu ekran geçmişi doğrudan `ai_chats`'ten (RLS ile) okur ve
/// gönderimde yalnızca [AIService.sendChatMessage] çağırır — istemci
/// `ai_chats`'e yazmaz (çift kayıt olmasın). Profil + son mesaj bağlamı
/// sunucuda eklenir. "Sohbeti temizle" kullanıcının satırlarını siler.
class AIChatPage extends StatefulWidget {
  const AIChatPage({super.key, this.profileName});

  /// Başlıktaki avatar için `profiles.full_name` (HomeScreen çeker).
  final ValueListenable<String?>? profileName;

  @override
  State<AIChatPage> createState() => _AIChatPageState();
}

class _AIChatPageState extends State<AIChatPage> {
  final _supabase = Supabase.instance.client;
  final AIService _aiService = AIService();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  final List<_ChatEntry> _messages = [];
  bool _isLoadingHistory = true;
  bool _isTyping = false;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  String? get _userId => _supabase.auth.currentUser?.id;

  /// Kullanıcının sohbet geçmişini (eskiden yeniye) çeker.
  Future<void> _loadHistory() async {
    final userId = _userId;
    if (userId == null) {
      if (mounted) setState(() => _isLoadingHistory = false);
      return;
    }

    try {
      final rows = await _supabase
          .from('ai_chats')
          .select('role, content, created_at')
          .eq('user_id', userId)
          .order('created_at', ascending: true)
          .limit(200);

      if (!mounted) return;
      setState(() {
        _messages
          ..clear()
          ..addAll((rows as List).map((r) => _ChatEntry.fromRow(r)));
        _isLoadingHistory = false;
      });
      _scrollToBottom();
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoadingHistory = false);
      _showError(AppLocalizations.of(context)!.chatLoadError);
    }
  }

  Future<void> _sendMessage() async {
    final message = _messageController.text.trim();
    if (message.isEmpty || _isTyping) return;

    _messageController.clear();
    setState(() {
      _messages.add(
          _ChatEntry(text: message, isUser: true, createdAt: DateTime.now()));
      _isTyping = true;
    });
    _scrollToBottom();

    try {
      // Profil + geçmiş bağlamı sunucuda eklenir; sadece mesajı gönderiyoruz.
      final response = await _aiService.sendChatMessage(message);
      if (!mounted) return;
      setState(() {
        _messages.add(_ChatEntry(
            text: response, isUser: false, createdAt: DateTime.now()));
        _isTyping = false;
      });
      _scrollToBottom();
    } on AIException catch (e) {
      if (!mounted) return;
      setState(() {
        _messages.add(_ChatEntry(
            text: e.message, isUser: false, createdAt: DateTime.now()));
        _isTyping = false;
      });
      _scrollToBottom();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _messages.add(_ChatEntry(
          text: AppLocalizations.of(context)!.chatErrorReply,
          isUser: false,
          createdAt: DateTime.now(),
        ));
        _isTyping = false;
      });
      _scrollToBottom();
    }
  }

  // ---- Menü / temizle ----

  Future<void> _openMenu() async {
    final l10n = AppLocalizations.of(context)!;
    final clear = await showModalBottomSheet<bool>(
      context: context,
      builder: (context) => SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.primaryContainer,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 8),
            ListTile(
              leading:
                  const Icon(Icons.delete_outline, color: AppColors.primary),
              title: Text(l10n.chatMenuClear),
              onTap: () => Navigator.of(context).pop(true),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (clear == true) await _confirmClear();
  }

  Future<void> _confirmClear() async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.chatClearConfirmTitle),
        content: Text(l10n.chatClearConfirmBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.commonDelete),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) await _clearHistory();
  }

  /// Kullanıcının `ai_chats` satırlarını siler; liste boş duruma döner.
  Future<void> _clearHistory() async {
    final userId = _userId;
    if (userId == null) return;
    try {
      await _supabase.from('ai_chats').delete().eq('user_id', userId);
      if (!mounted) return;
      setState(() => _messages.clear());
    } catch (e) {
      if (mounted) _showError(friendlyErrorMessage(e));
    }
  }

  void _showError(String text) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(text),
        backgroundColor: AppColors.sos,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // ---- UI ----

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final showMenu = !_isLoadingHistory && _messages.isNotEmpty;

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            PageHeader(
              eyebrow: l10n.chatHeaderEyebrow,
              title: l10n.chatTitle,
              actions: [
                if (showMenu)
                  Material(
                    color: AppColors.surface,
                    shape: const CircleBorder(),
                    clipBehavior: Clip.antiAlias,
                    child: IconButton(
                      tooltip: l10n.chatMenuTooltip,
                      onPressed: _openMenu,
                      icon: const Icon(Icons.more_horiz, color: AppColors.text),
                    ),
                  ),
              ],
              profileName: widget.profileName,
            ),
            Expanded(child: _buildBody(l10n)),
            _buildInputBar(l10n),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(AppLocalizations l10n) {
    if (_isLoadingHistory) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_messages.isEmpty && !_isTyping) {
      return _buildWelcome(l10n);
    }
    return ListView(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      children: _buildChatChildren(l10n),
    );
  }

  Widget _buildWelcome(AppLocalizations l10n) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Karşılamada varlık orta boy blob olarak eşlik eder (tek
            // instance — dalgalanma açık, shader'sız).
            const FlatBlob(size: 64),
            const SizedBox(height: 20),
            Text(
              l10n.chatWelcome,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                height: 1.4,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Mesajları, gün değişimlerinde tarih ayracı ekleyerek widget listesine
  /// çevirir; en sona (gönderim sürerken) "yazıyor" balonu eklenir.
  List<Widget> _buildChatChildren(AppLocalizations l10n) {
    final locale = Localizations.localeOf(context).languageCode;
    final children = <Widget>[];
    DateTime? lastDay;
    for (final m in _messages) {
      final local = m.createdAt?.toLocal();
      if (local != null) {
        final day = DateTime(local.year, local.month, local.day);
        if (lastDay == null || day != lastDay) {
          children.add(_DaySeparator(label: _dayLabel(l10n, locale, day)));
          lastDay = day;
        }
      }
      children.add(_MessageBubble(text: m.text, isUser: m.isUser));
    }
    if (_isTyping) children.add(_TypingIndicator(label: l10n.chatTyping));
    return children;
  }

  String _dayLabel(AppLocalizations l10n, String locale, DateTime day) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final diff = today.difference(day).inDays;
    if (diff == 0) return l10n.chatToday;
    if (diff == 1) return l10n.chatYesterday;
    return DateFormat.MMMMd(locale).format(day);
  }

  Widget _buildInputBar(AppLocalizations l10n) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _messageController,
                textCapitalization: TextCapitalization.sentences,
                textInputAction: TextInputAction.send,
                minLines: 1,
                maxLines: 4,
                onSubmitted: (_) => _sendMessage(),
                decoration: InputDecoration(
                  hintText: l10n.chatHint,
                  filled: true,
                  fillColor: AppColors.fieldFill,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            _SendButton(
              enabled: !_isTyping,
              tooltip: l10n.chatSendTooltip,
              onPressed: _sendMessage,
            ),
          ],
        ),
      ),
    );
  }
}

/// Ekranda tutulan tek sohbet mesajı (yerel state; DB'ye ayrıca yazılmaz).
class _ChatEntry {
  final String text;
  final bool isUser;
  final DateTime? createdAt;

  const _ChatEntry({required this.text, required this.isUser, this.createdAt});

  factory _ChatEntry.fromRow(Map<String, dynamic> row) {
    final created = row['created_at'];
    return _ChatEntry(
      text: (row['content'] as String?) ?? '',
      isUser: row['role'] == 'user',
      createdAt: created is String ? DateTime.tryParse(created) : null,
    );
  }
}

/// Kenarlıksız, tema renginde sohbet balonu. Kullanıcı sağda
/// (primaryContainer), asistan solda (fieldFill) + küçük avatar.
class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.text, required this.isUser});

  final String text;
  final bool isUser;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            const _AssistantAvatar(),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.75,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color:
                    isUser ? AppColors.primaryContainer : AppColors.fieldFill,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Text(
                text,
                style: TextStyle(
                  fontSize: 16,
                  height: 1.35,
                  color: isUser ? AppColors.onPrimaryContainer : AppColors.text,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Asistan balonunun solundaki küçük blob avatar — AI varlığının chat'teki
/// yüzü. Liste boyunca tekrar ettiği için tamamen statik (`wobble: false`,
/// controller bile kurulmaz).
class _AssistantAvatar extends StatelessWidget {
  const _AssistantAvatar();

  @override
  Widget build(BuildContext context) {
    return const FlatBlob(size: 36, wobble: false);
  }
}

/// Ortalanmış küçük tarih ayracı çipi (Bugün / Dün / d MMM).
class _DaySeparator extends StatelessWidget {
  const _DaySeparator({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.fieldFill,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}

/// "Yazıyor" göstergesi — başrol anı: balonda üç nokta yerine küçük gerçek
/// [MeshBlob] + hafif nabız ölçeği ("varlık düşünüyor"). Shader burada
/// serbest: gösterge yalnız yanıt beklenirken mount edilir, geçicidir.
class _TypingIndicator extends StatefulWidget {
  const _TypingIndicator({required this.label});

  final String label;

  @override
  State<_TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<_TypingIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: widget.label,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _AssistantAvatar(),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.fieldFill,
                borderRadius: BorderRadius.circular(18),
              ),
              child: ScaleTransition(
                scale: Tween(begin: 0.92, end: 1.08).animate(
                  CurvedAnimation(parent: _pulse, curve: Curves.easeInOut),
                ),
                child: const MeshBlob(size: 32, colors: _typingMeshColors),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// primary zeminli yuvarlak gönder butonu (gönderim sürerken kilitli).
class _SendButton extends StatelessWidget {
  const _SendButton({
    required this.enabled,
    required this.tooltip,
    required this.onPressed,
  });

  final bool enabled;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: enabled ? AppColors.primary : AppColors.primaryContainer,
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: IconButton(
        tooltip: tooltip,
        onPressed: enabled ? onPressed : null,
        icon: const Icon(Icons.arrow_upward, color: AppColors.onPrimary),
      ),
    );
  }
}
