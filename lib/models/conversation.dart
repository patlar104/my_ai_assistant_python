class Conversation {
  final String id;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<Message> messages;

  Conversation({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    required this.messages,
  });

  int get userMessageCount {
    return messages.where((msg) => msg.role == 'user').length;
  }

  factory Conversation.fromJson(Map<String, dynamic> json) {
    return Conversation(
      id: json['id'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      messages: (json['messages'] as List<dynamic>?)
              ?.map((msg) => Message.fromJson(msg as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'messages': messages.map((msg) => msg.toJson()).toList(),
    };
  }

  Conversation copyWith({
    String? id,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<Message>? messages,
  }) {
    return Conversation(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      messages: messages ?? this.messages,
    );
  }
}

class Message {
  final String role;
  final String content;
  final DateTime? timestamp;

  Message({
    required this.role,
    required this.content,
    this.timestamp,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      role: json['role'] as String,
      content: json['content'] as String,
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'role': role,
      'content': content,
      'timestamp': timestamp?.toIso8601String(),
    };
  }
}

class ConversationMetadata {
  final String id;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int messageCount;

  ConversationMetadata({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    required this.messageCount,
  });

  factory ConversationMetadata.fromJson(Map<String, dynamic> json) {
    return ConversationMetadata(
      id: json['id'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      messageCount: json['message_count'] as int,
    );
  }
}
