import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/chat_message.dart';

final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  return ChatRepository();
});

final chatMessagesProvider = StreamProvider.family<List<ChatMessage>, String>((
  ref,
  inspectorId,
) {
  final repo = ref.watch(chatRepositoryProvider);
  return repo.watchMessages(inspectorId);
});

final adminPresenceProvider = StreamProvider<bool>((ref) {
  final repo = ref.watch(chatRepositoryProvider);
  return repo.watchAdminPresence();
});

class ChatRepository {
  final _supabase = Supabase.instance.client;
  RealtimeChannel? _presenceChannel;

  Stream<List<ChatMessage>> watchMessages(String inspectorId) {
    return _supabase
        .from('support_messages')
        .stream(primaryKey: ['id'])
        .eq('inspector_id', inspectorId)
        .order('created_at', ascending: true)
        .map((data) => data.map((json) => ChatMessage.fromJson(json)).toList());
  }

  Future<void> sendMessage({
    required String message,
    required String senderId,
    required String senderName,
    required String inspectorId,
    required bool isAdmin,
  }) async {
    await _supabase.from('support_messages').insert({
      'sender_id': senderId,
      'sender_name': senderName,
      'message': message,
      'inspector_id': inspectorId,
      'is_admin': isAdmin,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  /// Per l'admin: carica la lista di ispettori che hanno chat attive
  Stream<List<Map<String, dynamic>>> watchActiveChats() {
    return _supabase
        .from('support_messages')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .map((data) {
          final Map<String, Map<String, dynamic>> groups = {};
          for (final json in data) {
            final inspectorId = json['inspector_id'] as String;
            if (!groups.containsKey(inspectorId)) {
              groups[inspectorId] = {
                'inspector_id': inspectorId,
                'last_message': json['message'],
                'sender_name': json['sender_name'],
                'created_at': json['created_at'],
              };
            }
          }
          return groups.values.toList();
        });
  }

  /// Unisciti al canale di presenza come admin
  void joinAsAdmin() {
    _presenceChannel = _supabase.channel('admin_presence');
    _presenceChannel?.subscribe((status, error) {
      if (status == RealtimeSubscribeStatus.subscribed) {
        _presenceChannel?.track({'role': 'admin', 'status': 'online'});
      }
    });
  }

  /// Lascia il canale di presenza
  void leavePresence() {
    _presenceChannel?.unsubscribe();
    _presenceChannel = null;
  }

  /// Ascolta se ci sono admin online
  Stream<bool> watchAdminPresence() {
    final controller = StreamController<bool>();
    final channel = _supabase.channel('admin_presence');

    channel.onPresenceSync((payload) {
      final presenceState = channel.presenceState();
      bool adminOnline = false;

      for (final state in presenceState) {
        for (final presence in state.presences) {
          if (presence.payload['role'] == 'admin') {
            adminOnline = true;
            break;
          }
        }
        if (adminOnline) break;
      }

      if (!controller.isClosed) {
        controller.add(adminOnline);
      }
    }).subscribe();

    controller.onCancel = () {
      channel.unsubscribe();
      controller.close();
    };

    return controller.stream;
  }
}
