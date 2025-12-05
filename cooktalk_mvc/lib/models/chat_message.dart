enum MessageRole { user, assistant, system }

class ChatMessage {
  final String id;
  final String content;
  final MessageRole role;
  final DateTime timestamp;
  final bool isError;

  const ChatMessage({
    required this.id,
    required this.content,
    required this.role,
    required this.timestamp,
    this.isError = false,
  });

  factory ChatMessage.user(String content) {
    return ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: content,
      role: MessageRole.user,
      timestamp: DateTime.now(),
    );
  }

  factory ChatMessage.assistant(String content, {bool isError = false}) {
    return ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: content,
      role: MessageRole.assistant,
      timestamp: DateTime.now(),
      isError: isError,
    );
  }

  factory ChatMessage.system(String content) {
    return ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: content,
      role: MessageRole.system,
      timestamp: DateTime.now(),
    );
  }

  ChatMessage copyWith({
    String? id,
    String? content,
    MessageRole? role,
    DateTime? timestamp,
    bool? isError,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      content: content ?? this.content,
      role: role ?? this.role,
      timestamp: timestamp ?? this.timestamp,
      isError: isError ?? this.isError,
    );
  }
}
