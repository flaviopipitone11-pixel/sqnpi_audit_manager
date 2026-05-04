class ChatMessage {
  final String id;
  final DateTime createdAt;
  final String senderId;
  final String senderName;
  final String message;
  final bool isAdmin;
  final String inspectorId;
  final String? attachmentUrl;
  final String? attachmentType;

  ChatMessage({
    required this.id,
    required this.createdAt,
    required this.senderId,
    required this.senderName,
    required this.message,
    required this.isAdmin,
    required this.inspectorId,
    this.attachmentUrl,
    this.attachmentType,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'] as String? ?? '',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      senderId: json['sender_id'] as String? ?? '',
      senderName: json['sender_name'] as String? ?? 'Anonimo',
      message: json['message'] as String? ?? '',
      isAdmin: json['is_admin'] as bool? ?? false,
      inspectorId: json['inspector_id'] as String? ?? '',
      attachmentUrl: json['attachment_url'] as String?,
      attachmentType: json['attachment_type'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'created_at': createdAt.toIso8601String(),
      'sender_id': senderId,
      'sender_name': senderName,
      'message': message,
      'is_admin': isAdmin,
      'inspector_id': inspectorId,
      'attachment_url': attachmentUrl,
      'attachment_type': attachmentType,
    };
  }
}
