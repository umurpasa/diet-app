import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/app_theme.dart';
import '../l10n/app_localizations.dart';
import '../utils/error_messages.dart';
import '../widgets/page_header.dart';

/// Kullanıcı ↔ diyetisyen mesajlaşması (Supabase Realtime).
///
/// Sayfa role göre çift yönlü çalışır: `profiles.role` okunur; kullanıcıysa
/// aktif atamasındaki diyetisyen, diyetisyense ilk aktif danışanı karşı taraf
/// olur. Mesajlar `messages` tablosunda (RLS: yalnızca katılımcılar okur,
/// gönderen yazar, alıcı okundu işaretler); yeni mesajlar `postgres_changes`
/// INSERT aboneliğiyle anında düşer. Okundu tiki sayfa yükleme anındaki
/// `read_at` değerini gösterir — canlı güncellenmez (UPDATE aboneliği
/// bilinçli ertelendi, BACKLOG'da). Demo kurulumu: docs/DEMO_DIETITIAN.md.
class DietitianChatPage extends StatefulWidget {
  const DietitianChatPage({super.key, this.onOpenAiChat, this.profileName});

  /// Atamasız boş durumdaki "Şimdilik Danışman'a sor" butonu — AI Sohbet
  /// sekmesine geçirir. Null ise buton gizlenir.
  final VoidCallback? onOpenAiChat;

  /// Başlıktaki avatar için `profiles.full_name` (HomeScreen çeker).
  final ValueListenable<String?>? profileName;

  @override
  State<DietitianChatPage> createState() => _DietitianChatPageState();
}

class _DietitianChatPageState extends State<DietitianChatPage> {
  final _supabase = Supabase.instance.client;
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();

  bool _isLoading = true;
  bool _isSending = false;
  bool _isDietitian = false;
  String? _partnerId;
  String? _partnerName;
  List<ChatMessage> _messages = [];
  RealtimeChannel? _channel;

  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  void dispose() {
    final channel = _channel;
    if (channel != null) _supabase.removeChannel(channel);
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  String? get _userId => _supabase.auth.currentUser?.id;

  /// Rolü okur, karşı tarafı bulur, mesajları yükler ve Realtime'a abone olur.
  Future<void> _init() async {
    final userId = _userId;
    if (userId == null) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      final profile = await _supabase
          .from('profiles')
          .select('role')
          .eq('id', userId)
          .single();
      final isDietitian = profile['role'] == 'dietitian';

      // Aktif atamadan karşı tarafı bul (demo: ilk kayıt).
      final assignment = await _supabase
          .from('assignments')
          .select('user_id, dietitian_id')
          .eq(isDietitian ? 'dietitian_id' : 'user_id', userId)
          .eq('active', true)
          .order('started_at', ascending: true)
          .limit(1)
          .maybeSingle();

      final partnerId = assignment == null
          ? null
          : (isDietitian
              ? assignment['user_id'] as String
              : assignment['dietitian_id'] as String);

      // Ad boşsa null bırakılır; başlık/avatar fallback'i build'de l10n ile.
      String? partnerName;
      if (partnerId != null) {
        final partnerProfile = await _supabase
            .from('profiles')
            .select('full_name')
            .eq('id', partnerId)
            .maybeSingle();
        final name = (partnerProfile?['full_name'] as String?)?.trim();
        partnerName = (name == null || name.isEmpty) ? null : name;
      }

      if (!mounted) return;
      setState(() {
        _isDietitian = isDietitian;
        _partnerId = partnerId;
        _partnerName = partnerName;
      });

      if (partnerId != null) {
        await _loadMessages();
        await _markIncomingRead();
        _subscribe(userId, partnerId);
      }
    } on PostgrestException catch (e) {
      if (mounted) {
        _showMessage(AppLocalizations.of(context)!.dcLoadError(e.message),
            isError: true);
      }
    } catch (e) {
      if (mounted) _showMessage(friendlyErrorMessage(e), isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// İki taraf arasındaki son 50 mesajı (eski → yeni) çeker.
  Future<void> _loadMessages() async {
    final userId = _userId;
    final partnerId = _partnerId;
    if (userId == null || partnerId == null) return;

    final rows = await _supabase
        .from('messages')
        .select()
        .or('and(sender_id.eq.$userId,receiver_id.eq.$partnerId),'
            'and(sender_id.eq.$partnerId,receiver_id.eq.$userId)')
        .order('created_at', ascending: false)
        .limit(50);

    final messages = (rows as List)
        .map((row) => ChatMessage.fromRow(row))
        .toList()
        .reversed
        .toList();

    if (mounted) {
      setState(() => _messages = messages);
      _scrollToBottom();
    }
  }

  /// Karşı taraftan gelen okunmamış mesajları okundu işaretler
  /// (RLS: yalnızca alıcı güncelleyebilir).
  Future<void> _markIncomingRead() async {
    final userId = _userId;
    final partnerId = _partnerId;
    if (userId == null || partnerId == null) return;

    try {
      await _supabase
          .from('messages')
          .update({'read_at': DateTime.now().toUtc().toIso8601String()})
          .eq('sender_id', partnerId)
          .eq('receiver_id', userId)
          .isFilter('read_at', null);
    } catch (_) {
      // Okundu işareti kritik değil; sessizce geç.
    }
  }

  /// Bana gelen INSERT'lere abone olur; karşı taraftan yeni mesaj
  /// düşünce listeye ekler.
  void _subscribe(String userId, String partnerId) {
    _channel = _supabase
        .channel('dietitian-chat-$userId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'messages',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'receiver_id',
            value: userId,
          ),
          callback: (payload) {
            final row = payload.newRecord;
            if (row['sender_id'] != partnerId || !mounted) return;
            setState(() => _messages.add(ChatMessage.fromRow(row)));
            _scrollToBottom();
            _markIncomingRead();
          },
        )
        .subscribe();
  }

  Future<void> _sendMessage() async {
    final userId = _userId;
    final partnerId = _partnerId;
    final body = _messageController.text.trim();
    if (userId == null || partnerId == null || body.isEmpty) return;

    setState(() => _isSending = true);
    try {
      final row = await _supabase
          .from('messages')
          .insert({
            'sender_id': userId,
            'receiver_id': partnerId,
            'body': body,
          })
          .select()
          .single();

      if (mounted) {
        _messageController.clear();
        setState(() => _messages.add(ChatMessage.fromRow(row)));
        _scrollToBottom();
      }
    } on PostgrestException catch (e) {
      if (mounted) {
        _showMessage(AppLocalizations.of(context)!.dcSendError(e.message),
            isError: true);
      }
    } catch (e) {
      if (mounted) _showMessage(friendlyErrorMessage(e), isError: true);
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _showMessage(String text, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(text),
        backgroundColor: isError ? AppColors.sos : null,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ---- UI ----

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final title =
        _partnerName ?? (_isDietitian ? l10n.dcTitleDietitian : l10n.dcTitle);

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            PageHeader(
              // Rol alt-etiketi eyebrow'a taşındı, isim başlık oldu (F-6);
              // atama yokken bağlam satırı çizilmez.
              eyebrow: _partnerId != null
                  ? (_isDietitian
                      ? l10n.dcSubtitleDietitian
                      : l10n.dcSubtitleUser)
                  : null,
              title: title,
              profileName: widget.profileName,
            ),
            Expanded(child: _buildBody(l10n)),
            if (!_isLoading && _partnerId != null) _buildInputBar(l10n),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(AppLocalizations l10n) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_partnerId == null) {
      return _buildNoPartnerState(l10n);
    }
    if (_messages.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Text(
            l10n.dcNoMessages,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 16,
              height: 1.4,
              color: AppColors.textSecondary,
            ),
          ),
        ),
      );
    }
    return ListView(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      children: _buildChatChildren(l10n),
    );
  }

  /// Atama yok: sıcak boş durum. Kullanıcı rolünde AI Sohbet'e yönlendiren
  /// ikincil CTA gösterilir (diyetisyen rolünde gösterilmez).
  Widget _buildNoPartnerState(AppLocalizations l10n) {
    final showAiCta = !_isDietitian && widget.onOpenAiChat != null;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: const BoxDecoration(
                color: AppColors.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.support_agent,
                  color: AppColors.primary, size: 36),
            ),
            const SizedBox(height: 20),
            Text(
              _isDietitian ? l10n.dcNoClientTitle : l10n.dcNoAssignTitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.text,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _isDietitian ? l10n.dcNoClientBody : l10n.dcNoAssignBody,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                height: 1.4,
                color: AppColors.textSecondary,
              ),
            ),
            if (showAiCta) ...[
              const SizedBox(height: 20),
              OutlinedButton(
                onPressed: widget.onOpenAiChat,
                child: Text(l10n.dcAskAi),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Mesajları, gün değişimlerinde (yerel tarih) ayraç ekleyerek widget
  /// listesine çevirir (F-4c deseni).
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
      children.add(_bubble(m));
    }
    return children;
  }

  String _dayLabel(AppLocalizations l10n, String locale, DateTime day) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final diff = today.difference(day).inDays;
    if (diff == 0) return l10n.dcToday;
    if (diff == 1) return l10n.dcYesterday;
    return DateFormat.MMMMd(locale).format(day);
  }

  Widget _bubble(ChatMessage message) {
    final isMine = message.senderId == _userId;
    final maxWidth = MediaQuery.of(context).size.width * 0.75;

    final bubble = Container(
      constraints: BoxConstraints(maxWidth: maxWidth),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isMine ? AppColors.primaryContainer : AppColors.fieldFill,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Text(
        message.body,
        style: TextStyle(
          fontSize: 16,
          height: 1.35,
          color: isMine ? AppColors.onPrimaryContainer : AppColors.text,
        ),
      ),
    );

    // Baloncuk altı mini satır: saat (+ benimkinde okundu tiki). Tik sayfa
    // yükleme anındaki read_at değerini gösterir, canlı güncellenmez.
    final meta = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          message.timeLabel,
          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
        ),
        if (isMine) ...[
          const SizedBox(width: 4),
          Icon(
            message.readAt != null ? Icons.done_all : Icons.done,
            size: 14,
            color: message.readAt != null
                ? AppColors.primary
                : AppColors.textSecondary,
          ),
        ],
      ],
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment:
            isMine ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isMine) ...[
            _PartnerAvatar(name: _partnerName),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment:
                  isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                bubble,
                const SizedBox(height: 3),
                meta,
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputBar(AppLocalizations l10n) {
    return Padding(
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
              onSubmitted: (_) => _isSending ? null : _sendMessage(),
              decoration: InputDecoration(
                hintText: l10n.dcHint,
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
          Material(
            color: _isSending ? AppColors.primaryContainer : AppColors.primary,
            shape: const CircleBorder(),
            clipBehavior: Clip.antiAlias,
            child: IconButton(
              tooltip: l10n.dcSendTooltip,
              onPressed: _isSending ? null : _sendMessage,
              icon: _isSending
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.onPrimaryContainer,
                      ),
                    )
                  : const Icon(Icons.arrow_upward, color: AppColors.onPrimary),
            ),
          ),
        ],
      ),
    );
  }
}

/// Karşı tarafın baloncuklarının solundaki baş harf avatarı (profil sayfası
/// deseni) — AI sohbetin spa ikonundan bilinçli farklı: insan kimliği.
class _PartnerAvatar extends StatelessWidget {
  const _PartnerAvatar({required this.name});

  final String? name;

  @override
  Widget build(BuildContext context) {
    final trimmed = name?.trim() ?? '';

    return Container(
      width: 36,
      height: 36,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        color: AppColors.primaryContainer,
        shape: BoxShape.circle,
      ),
      child: trimmed.isEmpty
          ? const Icon(Icons.person,
              color: AppColors.onPrimaryContainer, size: 20)
          : Text(
              trimmed[0].toUpperCase(),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.onPrimaryContainer,
              ),
            ),
    );
  }
}

/// Ortalanmış küçük tarih ayracı çipi (Bugün / Dün / d MMM) — F-4c deseni.
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

/// `messages` tablosundaki bir satır.
class ChatMessage {
  final String id;
  final String senderId;
  final String body;
  final DateTime? createdAt;

  /// Alıcının okuma anı; UI'da okundu tiki için (yükleme anındaki değer).
  final DateTime? readAt;

  ChatMessage({
    required this.id,
    required this.senderId,
    required this.body,
    this.createdAt,
    this.readAt,
  });

  factory ChatMessage.fromRow(Map<String, dynamic> row) {
    return ChatMessage(
      id: row['id'] as String,
      senderId: row['sender_id'] as String,
      body: row['body'] as String,
      createdAt: row['created_at'] == null
          ? null
          : DateTime.tryParse(row['created_at'] as String),
      readAt: row['read_at'] == null
          ? null
          : DateTime.tryParse(row['read_at'] as String),
    );
  }

  /// Gönderim saati, yerel saatle HH:mm.
  String get timeLabel {
    final local = createdAt?.toLocal();
    if (local == null) return '';
    final h = local.hour.toString().padLeft(2, '0');
    final m = local.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}
