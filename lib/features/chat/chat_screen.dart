import 'dart:async';
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/message_model.dart';
import '../../providers/app_providers.dart';
import '../../theme/app_colors.dart';
import '../../utils/notification_chime.dart';

class _ChatHeaderData {
  const _ChatHeaderData({
    required this.requestTitle,
    required this.counterpartyName,
    this.counterpartyPhone,
    this.selfName,
    this.selfPhone,
  });

  final String requestTitle;
  final String counterpartyName;
  final String? counterpartyPhone;
  final String? selfName;
  final String? selfPhone;
}

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({
    super.key,
    required this.chatId,
    this.requestId,
  });

  final String chatId;
  final String? requestId;

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen>
    with WidgetsBindingObserver {
  final _text = TextEditingController();
  final _scroll = ScrollController();
  final _messages = <MessageModel>[];
  RealtimeChannel? _channel;
  bool _loading = true;
  _ChatHeaderData? _header;
  Timer? _activeChatHeartbeat;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _bootstrap();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _stopActiveChatHeartbeat();
      unawaited(_clearActiveChatPresence());
    } else if (state == AppLifecycleState.resumed && mounted) {
      unawaited(_touchActiveChatPresence());
      _startActiveChatHeartbeat();
      unawaited(_reloadMessagesFromServer());
    }
  }

  /// Catches messages received while backgrounded (Realtime may miss inserts).
  Future<void> _reloadMessagesFromServer() async {
    if (!mounted) return;
    try {
      final list =
          await ref.read(messagesRepositoryProvider).listForChat(widget.chatId);
      if (!mounted) return;
      setState(() {
        _messages
          ..clear()
          ..addAll(list);
      });
      _scrollToEnd();
    } catch (_) {}
  }

  void _addMessageIfNew(MessageModel m) {
    if (_messages.any((x) => x.id == m.id)) return;
    setState(() => _messages.add(m));
    _scrollToEnd();
  }

  Future<void> _touchActiveChatPresence() async {
    final uid = ref.read(supabaseClientProvider).auth.currentUser?.id;
    if (uid == null || !mounted) return;
    try {
      await ref.read(supabaseClientProvider).from('profiles').update({
        'active_chat_id': widget.chatId,
        'active_chat_at': DateTime.now().toUtc().toIso8601String(),
      }).eq('id', uid);
    } catch (_) {}
  }

  Future<void> _clearActiveChatPresence() async {
    final uid = ref.read(supabaseClientProvider).auth.currentUser?.id;
    if (uid == null) return;
    try {
      await ref.read(supabaseClientProvider).from('profiles').update({
        'active_chat_id': null,
        'active_chat_at': null,
      }).eq('id', uid).eq('active_chat_id', widget.chatId);
    } catch (_) {}
  }

  void _startActiveChatHeartbeat() {
    _activeChatHeartbeat?.cancel();
    _activeChatHeartbeat = Timer.periodic(const Duration(seconds: 45), (_) {
      if (!mounted) return;
      unawaited(_pulseActiveChatAt());
    });
  }

  void _stopActiveChatHeartbeat() {
    _activeChatHeartbeat?.cancel();
    _activeChatHeartbeat = null;
  }

  Future<void> _pulseActiveChatAt() async {
    final uid = ref.read(supabaseClientProvider).auth.currentUser?.id;
    if (uid == null || !mounted) return;
    try {
      await ref.read(supabaseClientProvider).from('profiles').update({
        'active_chat_at': DateTime.now().toUtc().toIso8601String(),
      }).eq('id', uid).eq('active_chat_id', widget.chatId);
    } catch (_) {}
  }

  Future<void> _bootstrap() async {
    final repo = ref.read(messagesRepositoryProvider);
    final list = await repo.listForChat(widget.chatId);
    if (!mounted) return;
    setState(() {
      _messages
        ..clear()
        ..addAll(list);
      _loading = false;
    });
    _scrollToEnd();
    await _markOthersRead(list);
    unawaited(_loadHeader());
    if (mounted) {
      unawaited(_touchActiveChatPresence());
      _startActiveChatHeartbeat();
    }

    final client = ref.read(supabaseClientProvider);
    _channel = client.channel('chat_${widget.chatId}');
    _channel!
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'messages',
          callback: (payload) {
            final row = payload.newRecord;
            if (row['chat_id']?.toString() != widget.chatId) return;
            final uid = ref.read(supabaseClientProvider).auth.currentUser?.id;
            final sender = row['sender_id']?.toString();
            if (uid != null && sender != null && sender != uid) {
              unawaited(playNotificationChime());
            }
            final m = MessageModel.fromMap(Map<String, dynamic>.from(row));
            _addMessageIfNew(m);
          },
        )
        .subscribe();
  }

  Future<void> _loadHeader() async {
    try {
      final client = ref.read(supabaseClientProvider);
      final uid = client.auth.currentUser?.id;
      if (uid == null || !mounted) return;

      var requestId = widget.requestId;
      if (requestId == null || requestId.isEmpty) {
        final ch = await client.from('chats').select('request_id').eq('id', widget.chatId).maybeSingle();
        requestId = ch?['request_id'] as String?;
      }
      if (requestId == null || !mounted) return;

      final req = await client.from('requests').select('title, user_id').eq('id', requestId).maybeSingle();
      if (req == null || !mounted) return;
      final requesterId = req['user_id'] as String;
      final title = ((req['title'] as String?) ?? '').trim();

      final rr = await client
          .from('request_responses')
          .select('driver_id')
          .eq('request_id', requestId)
          .eq('status', 'accepted')
          .maybeSingle();
      if (!mounted) return;

      if (rr == null) {
        setState(() {
          _header = _ChatHeaderData(
            requestTitle: title.isEmpty ? 'Help request' : title,
            counterpartyName: 'Chat',
            counterpartyPhone: null,
            selfName: null,
            selfPhone: null,
          );
        });
        return;
      }

      final driverId = rr['driver_id'] as String;
      final otherId = uid == requesterId ? driverId : requesterId;

      final profRepo = ref.read(profileRepositoryProvider);
      final mine = await profRepo.fetchProfile(uid);
      final other = await profRepo.fetchProfile(otherId);
      if (!mounted) return;

      final otherName = (other?.name ?? '').trim();
      final cpName = otherName.isEmpty
          ? (uid == requesterId ? 'Driver' : 'Requester')
          : otherName;

      setState(() {
        _header = _ChatHeaderData(
          requestTitle: title.isEmpty ? 'Help request' : title,
          counterpartyName: cpName,
          counterpartyPhone: other?.phone,
          selfName: mine?.name,
          selfPhone: mine?.phone,
        );
      });
    } catch (_) {
      // Header is optional; chat still works.
    }
  }

  Future<void> _markOthersRead(List<MessageModel> list) async {
    final uid = ref.read(supabaseClientProvider).auth.currentUser?.id;
    if (uid == null) return;
    final repo = ref.read(messagesRepositoryProvider);
    for (final m in list) {
      if (m.senderId != uid && m.readAt == null) {
        await repo.markRead(m.id);
      }
    }
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent + 80,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _launchTel(String? raw) async {
    if (raw == null || raw.trim().isEmpty) return;
    final cleaned = raw.replaceAll(RegExp(r'[^\d+]'), '');
    if (cleaned.isEmpty) return;
    final uri = Uri.parse('tel:$cleaned');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _stopActiveChatHeartbeat();
    unawaited(_clearActiveChatPresence());
    _channel?.unsubscribe();
    _text.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _showError(Object e) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Could not send: $e')),
    );
  }

  Future<void> _send() async {
    final t = _text.text.trim();
    if (t.isEmpty) return;
    final uid = ref.read(supabaseClientProvider).auth.currentUser?.id;
    if (uid == null) return;
    final backup = t;
    _text.clear();
    try {
      final m = await ref.read(messagesRepositoryProvider).sendText(
            chatId: widget.chatId,
            senderId: uid,
            text: backup,
          );
      if (!mounted) return;
      _addMessageIfNew(m);
      unawaited(
        ref.read(chatPushServiceProvider).notifyParticipants(
          chatId: widget.chatId,
          messageId: m.id,
        ),
      );
    } catch (e) {
      if (mounted) _text.text = backup;
      _showError(e);
    }
  }

  Future<void> _sendImage() async {
    final uid = ref.read(supabaseClientProvider).auth.currentUser?.id;
    if (uid == null) return;
    final x = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (x == null) return;
    final file = File(x.path);
    try {
      final url =
          await ref.read(storageServiceProvider).uploadChatImage(uid, file);
      final m = await ref.read(messagesRepositoryProvider).sendImage(
            chatId: widget.chatId,
            senderId: uid,
            imageUrl: url,
          );
      if (!mounted) return;
      _addMessageIfNew(m);
      unawaited(
        ref.read(chatPushServiceProvider).notifyParticipants(
          chatId: widget.chatId,
          messageId: m.id,
        ),
      );
    } catch (e) {
      _showError(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final uid = ref.watch(supabaseClientProvider).auth.currentUser?.id;
    final scheme = Theme.of(context).colorScheme;
    final h = _header;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          tooltip: 'Back',
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/home');
            }
          },
        ),
        toolbarHeight: h == null ? null : 76,
        title: h == null
            ? const Text('Chat')
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    h.counterpartyName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.2,
                        ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    h.requestTitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: scheme.onSurface.withValues(alpha: 0.62),
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                ],
              ),
        actions: [
          if (h != null &&
              h.counterpartyPhone != null &&
              h.counterpartyPhone!.trim().isNotEmpty)
            IconButton(
              tooltip: 'Call ${h.counterpartyName}',
              onPressed: () => _launchTel(h.counterpartyPhone),
              icon: const Icon(Icons.phone_rounded),
            ),
        ],
      ),
      body: Column(
        children: [
          if (h != null)
            Material(
              color: scheme.surfaceContainerLow.withValues(alpha: 0.92),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _ContactMini(
                        label: 'You',
                        name: (h.selfName ?? '').trim().isEmpty ? '—' : h.selfName!.trim(),
                        phone: h.selfPhone,
                        onCall: () => _launchTel(h.selfPhone),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: SizedBox(
                        height: 52,
                        child: VerticalDivider(
                          width: 1,
                          color: scheme.outline.withValues(alpha: 0.25),
                        ),
                      ),
                    ),
                    Expanded(
                      child: _ContactMini(
                        label: 'Partner',
                        name: h.counterpartyName,
                        phone: h.counterpartyPhone,
                        onCall: () => _launchTel(h.counterpartyPhone),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          if (_loading)
            const LinearProgressIndicator(minHeight: 2)
          else
            Expanded(
              child: _messages.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          'No messages yet.\nSay hello to start the conversation.',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurface
                                    .withValues(alpha: 0.55),
                              ),
                        ),
                      ),
                    )
                  : ListView.builder(
                      controller: _scroll,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                      itemCount: _messages.length,
                      itemBuilder: (context, i) {
                        final m = _messages[i];
                        final mine = m.senderId == uid;
                        final time = m.createdAt != null
                            ? DateFormat.jm().format(m.createdAt!.toLocal())
                            : '';
                        return Align(
                          alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            constraints: BoxConstraints(
                              maxWidth: MediaQuery.sizeOf(context).width * 0.78,
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              color: mine
                                  ? AppColors.primary.withValues(alpha: 0.9)
                                  : Theme.of(context).colorScheme.surfaceContainerHighest,
                              borderRadius: BorderRadius.only(
                                topLeft: const Radius.circular(18),
                                topRight: const Radius.circular(18),
                                bottomLeft: Radius.circular(mine ? 18 : 4),
                                bottomRight: Radius.circular(mine ? 4 : 18),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (m.imageUrl != null && m.imageUrl!.isNotEmpty)
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: CachedNetworkImage(
                                      imageUrl: m.imageUrl!,
                                      height: 160,
                                      width: double.infinity,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                if (m.message != null && m.message!.isNotEmpty)
                                  Text(
                                    m.message!,
                                    style: TextStyle(
                                      color: mine ? Colors.white : null,
                                    ),
                                  ),
                                const SizedBox(height: 4),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      time,
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: mine
                                            ? Colors.white70
                                            : Theme.of(context)
                                                .colorScheme
                                                .onSurface
                                                .withValues(alpha: 0.5),
                                      ),
                                    ),
                                    if (mine && m.readAt != null) ...[
                                      const SizedBox(width: 4),
                                      Icon(
                                        Icons.done_all,
                                        size: 14,
                                        color: Colors.white.withValues(alpha: 0.85),
                                      ),
                                    ],
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              child: Row(
                children: [
                  IconButton.filledTonal(
                    onPressed: _sendImage,
                    icon: const Icon(Icons.image_outlined),
                  ),
                  Expanded(
                    child: TextField(
                      controller: _text,
                      decoration: InputDecoration(
                        hintText: 'Message…',
                        filled: true,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                      ),
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _send(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: _send,
                    style: FilledButton.styleFrom(
                      shape: const CircleBorder(),
                      padding: const EdgeInsets.all(14),
                    ),
                    child: const Icon(Icons.send_rounded, size: 20),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ContactMini extends StatelessWidget {
  const _ContactMini({
    required this.label,
    required this.name,
    this.phone,
    required this.onCall,
  });

  final String label;
  final String name;
  final String? phone;
  final VoidCallback onCall;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final hasPhone = phone != null && phone!.trim().isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: scheme.onSurface.withValues(alpha: 0.5),
                fontWeight: FontWeight.w700,
                letterSpacing: 0.4,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 2),
        if (hasPhone)
          TextButton.icon(
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              foregroundColor: AppColors.primary,
            ),
            onPressed: onCall,
            icon: const Icon(Icons.phone_in_talk_rounded, size: 16),
            label: Text(
              phone!.trim(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
          )
        else
          Text(
            'No phone',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: scheme.onSurface.withValues(alpha: 0.45),
                ),
          ),
      ],
    );
  }
}
