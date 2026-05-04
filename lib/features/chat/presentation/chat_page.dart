import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:flutter/foundation.dart' as foundation;
import '../../auth/presentation/auth_controller.dart';
import '../data/chat_repository.dart';
import 'package:intl/intl.dart';

class ChatPage extends ConsumerStatefulWidget {
  const ChatPage({super.key});

  @override
  ConsumerState<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends ConsumerState<ChatPage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();
  bool _showEmoji = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      if (_focusNode.hasFocus) {
        setState(() {
          _showEmoji = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _sendMessage({String? attachmentUrl, String? attachmentType}) async {
    final text = _messageController.text.trim();
    if (text.isEmpty && attachmentUrl == null) return;

    final auth = ref.read(authControllerProvider);
    final userId = auth.userId;
    if (userId == null) return;

    _messageController.clear();

    try {
      await ref
          .read(chatRepositoryProvider)
          .sendMessage(
            message: text,
            senderId: userId,
            senderName: auth.fullName ?? auth.username ?? 'Ispettore',
            inspectorId: userId,
            isAdmin: false,
            attachmentUrl: attachmentUrl,
            attachmentType: attachmentType,
          );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Errore nell\'invio: $e'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider);
    final userId = auth.userId;

    if (userId == null) {
      return const Scaffold(
        body: Center(child: Text('Effettua il login per chattare')),
      );
    }

    final messagesAsync = ref.watch(chatMessagesProvider(userId));
    final isAdminOnline = ref.watch(adminPresenceProvider).value ?? false;

    return PopScope(
      canPop: !_showEmoji,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && _showEmoji) {
          setState(() {
            _showEmoji = false;
          });
        }
      },
      child: Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          elevation: 0,
          backgroundColor: Colors.white.withValues(alpha: 0.8),
          flexibleSpace: ClipRRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(color: Colors.transparent),
            ),
          ),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Assistenza Live',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
              ),
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: isAdminOnline
                          ? Colors.green
                          : Colors.grey.shade400,
                      shape: BoxShape.circle,
                      boxShadow: isAdminOnline
                          ? [
                              BoxShadow(
                                color: Colors.green.withValues(alpha: 0.5),
                                blurRadius: 4,
                                spreadRadius: 1,
                              ),
                            ]
                          : null,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    isAdminOnline
                        ? 'Amministratori online'
                        : 'Amministratori offline',
                    style: const TextStyle(
                      fontSize: 11,
                      color: Colors.grey,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        body: Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            image: DecorationImage(
              image: const NetworkImage(
                'https://www.transparenttextures.com/patterns/cubes.png',
              ),
              opacity: 0.05,
              repeat: ImageRepeat.repeat,
            ),
          ),
          child: Column(
            children: [
              Expanded(
                child: messagesAsync.when(
                  data: (messages) {
                    if (messages.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.05),
                                    blurRadius: 20,
                                  ),
                                ],
                              ),
                              child: Icon(
                                Icons.chat_bubble_outline_rounded,
                                size: 48,
                                color: Theme.of(context).primaryColor,
                              ),
                            ),
                            const SizedBox(height: 24),
                            const Text(
                              'Come possiamo aiutarti?',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1E293B),
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Invia un messaggio per iniziare\nuna conversazione con il supporto.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.blueGrey),
                            ),
                          ],
                        ),
                      );
                    }

                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (_scrollController.hasClients) {
                        _scrollController.jumpTo(
                          _scrollController.position.maxScrollExtent,
                        );
                      }
                    });

                    return ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.fromLTRB(16, 100, 16, 16),
                      itemCount: messages.length,
                      itemBuilder: (context, index) {
                        final msg = messages[index];
                        final isMe = msg.senderId == userId;
                        final showDate =
                            index == 0 ||
                            DateFormat(
                                  'dd/MM',
                                ).format(messages[index - 1].createdAt) !=
                                DateFormat('dd/MM').format(msg.createdAt);

                        return Column(
                          children: [
                            if (showDate) _DateHeader(date: msg.createdAt),
                            _ChatBubble(
                              message: msg.message,
                              isMe: isMe,
                              senderName: msg.senderName,
                              timestamp: msg.createdAt,
                              attachmentUrl: msg.attachmentUrl,
                              attachmentType: msg.attachmentType,
                            ),
                          ],
                        );
                      },
                    );
                  },
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (e, st) {
                    final error = e.toString();
                    final isTokenExpired =
                        error.contains('JWTToken') || error.contains('expired');

                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isTokenExpired
                                  ? Icons.lock_clock_rounded
                                  : Icons.cloud_off_rounded,
                              size: 64,
                              color: isTokenExpired
                                  ? Colors.orange
                                  : Colors.redAccent,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              isTokenExpired
                                  ? 'Sessione Scaduta'
                                  : 'Errore di Caricamento',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1E293B),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              isTokenExpired
                                  ? 'La tua sessione di sicurezza è terminata.\nEffettua il login per continuare.'
                                  : 'Non è stato possibile caricare i messaggi.\nControlla la tua connessione.',
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: Colors.blueGrey),
                            ),
                            const SizedBox(height: 24),
                            if (isTokenExpired)
                              ElevatedButton.icon(
                                onPressed: () => ref
                                    .read(authControllerProvider.notifier)
                                    .logout(),
                                icon: const Icon(Icons.login_rounded),
                                label: const Text('Ritorna al Login'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Theme.of(
                                    context,
                                  ).primaryColor,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 24,
                                    vertical: 12,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              )
                            else
                              TextButton.icon(
                                onPressed: () => ref.invalidate(
                                  chatMessagesProvider(userId),
                                ),
                                icon: const Icon(Icons.refresh_rounded),
                                label: const Text('Riprova'),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

              _buildInput(),
              if (_showEmoji)
                SizedBox(
                  height: 250,
                  child: EmojiPicker(
                    onEmojiSelected: (category, emoji) {
                      _messageController.text += emoji.emoji;
                    },
                    config: Config(
                      height: 256,
                      checkPlatformCompatibility: true,
                      emojiViewConfig: EmojiViewConfig(
                        backgroundColor: const Color(0xFFF1F5F9),
                        columns: 7,
                        emojiSizeMax:
                            32 *
                            (foundation.defaultTargetPlatform ==
                                    TargetPlatform.iOS
                                ? 1.30
                                : 1.0),
                      ),
                      categoryViewConfig: CategoryViewConfig(
                        backgroundColor: const Color(0xFFF1F5F9),
                        indicatorColor: Colors.teal,
                        iconColorSelected: Colors.teal,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInput() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            offset: const Offset(0, -4),
            blurRadius: 15,
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(
                      _showEmoji
                          ? Icons.keyboard_rounded
                          : Icons.emoji_emotions_outlined,
                      color: Colors.blueGrey.shade300,
                    ),
                    onPressed: () {
                      setState(() {
                        _showEmoji = !_showEmoji;
                        if (_showEmoji) {
                          _focusNode.unfocus();
                        } else {
                          _focusNode.requestFocus();
                        }
                      });
                    },
                  ),

                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      focusNode: _focusNode,
                      decoration: const InputDecoration(
                        hintText: 'Scrivi un messaggio...',
                        hintStyle: TextStyle(color: Color(0xFF94A3B8)),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(vertical: 14),
                      ),
                      maxLines: 4,
                      minLines: 1,
                      textCapitalization: TextCapitalization.sentences,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: () => _sendMessage(),
            child: Container(
              height: 48,
              width: 48,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Theme.of(context).primaryColor,
                    Theme.of(context).primaryColor.withValues(alpha: 0.8),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(
                      context,
                    ).primaryColor.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(
                Icons.send_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DateHeader extends StatelessWidget {
  final DateTime date;
  const _DateHeader({required this.date});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 20),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          DateFormat('EEEE d MMMM', 'it_IT').format(date).toUpperCase(),
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w800,
            color: Color(0xFF64748B),
            letterSpacing: 1,
          ),
        ),
      ),
    );
  }
}

class _ChatBubble extends StatelessWidget {
  final String message;
  final bool isMe;
  final String senderName;
  final DateTime timestamp;
  final String? attachmentUrl;
  final String? attachmentType;

  const _ChatBubble({
    required this.message,
    required this.isMe,
    required this.senderName,
    required this.timestamp,
    this.attachmentUrl,
    this.attachmentType,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: isMe
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) ...[
            CircleAvatar(
              radius: 14,
              backgroundColor: const Color(0xFF1E293B),
              child: Text(
                senderName.substring(0, 1).toUpperCase(),
                style: const TextStyle(
                  fontSize: 10,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: isMe
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                if (!isMe)
                  Padding(
                    padding: const EdgeInsets.only(left: 4, bottom: 4),
                    child: Text(
                      senderName,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: isMe ? Theme.of(context).primaryColor : Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(20),
                      topRight: const Radius.circular(20),
                      bottomLeft: Radius.circular(isMe ? 20 : 0),
                      bottomRight: Radius.circular(isMe ? 0 : 20),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 5,
                        offset: const Offset(0, 2),
                      ),
                    ],
                    gradient: isMe
                        ? LinearGradient(
                            colors: [
                              Theme.of(context).primaryColor,
                              Theme.of(
                                context,
                              ).primaryColor.withValues(alpha: 0.9),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          )
                        : null,
                  ),
                  child: Column(
                    crossAxisAlignment: isMe
                        ? CrossAxisAlignment.end
                        : CrossAxisAlignment.start,
                    children: [
                      if (attachmentUrl != null) ...[
                        if (attachmentType == 'image')
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(
                              attachmentUrl!,
                              fit: BoxFit.cover,
                              loadingBuilder:
                                  (context, child, loadingProgress) {
                                    if (loadingProgress == null) return child;
                                    return Container(
                                      height: 200,
                                      width: 200,
                                      color: Colors.grey.shade200,
                                      child: const Center(
                                        child: CircularProgressIndicator(),
                                      ),
                                    );
                                  },
                            ),
                          )
                        else
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.insert_drive_file_rounded,
                                color: isMe ? Colors.white : Colors.grey,
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'Documento allegato',
                                style: TextStyle(fontStyle: FontStyle.italic),
                              ),
                            ],
                          ),
                        const SizedBox(height: 8),
                      ],
                      if (message.isNotEmpty)
                        Text(
                          message,
                          style: TextStyle(
                            color: isMe
                                ? Colors.white
                                : const Color(0xFF1E293B),
                            fontSize: 15,
                            height: 1.3,
                          ),
                        ),
                      const SizedBox(height: 4),
                      Text(
                        DateFormat('HH:mm').format(timestamp),
                        style: TextStyle(
                          fontSize: 9,
                          color: isMe
                              ? Colors.white.withValues(alpha: 0.7)
                              : Colors.grey,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (isMe) const SizedBox(width: 8),
        ],
      ),
    );
  }
}
