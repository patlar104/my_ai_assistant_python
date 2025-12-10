/// Base exception for all Gemini-related errors
class GeminiException implements Exception {
  final String message;
  final String? code;
  final dynamic originalError;

  GeminiException(this.message, {this.code, this.originalError});

  @override
  String toString() => message;
}

/// Exception for API-specific errors (400, 401, 403, 429, 500, etc.)
class GeminiApiException extends GeminiException {
  final int statusCode;

  GeminiApiException(
    String message,
    this.statusCode, {
    String? code,
    dynamic originalError,
  }) : super(message, code: code, originalError: originalError);

  @override
  String toString() {
    if (code != null) {
      return '$message (Code: $code, Status: $statusCode)';
    }
    return '$message (Status: $statusCode)';
  }
}

/// Exception for network/timeout errors
class GeminiNetworkException extends GeminiException {
  GeminiNetworkException(String message, {dynamic originalError})
      : super(message, originalError: originalError);
}

/// Exception when no text is returned from the API
class GeminiEmptyResponseException extends GeminiException {
  GeminiEmptyResponseException(String message) : super(message);
}

/// Base exception for conversation storage errors
class ConversationStorageException implements Exception {
  final String message;
  final String? conversationId;
  final dynamic originalError;

  ConversationStorageException(
    this.message, {
    this.conversationId,
    this.originalError,
  });

  @override
  String toString() {
    if (conversationId != null) {
      return '$message (Conversation: $conversationId)';
    }
    return message;
  }
}

/// Exception when a conversation is not found
class ConversationNotFoundException extends ConversationStorageException {
  ConversationNotFoundException(String conversationId)
      : super(
          'Conversation not found',
          conversationId: conversationId,
        );
}

/// Exception for file permission errors
class ConversationPermissionException extends ConversationStorageException {
  ConversationPermissionException(
    String message, {
    String? conversationId,
    dynamic originalError,
  }) : super(
          message,
          conversationId: conversationId,
          originalError: originalError,
        );
}

/// Exception for corrupted or invalid JSON files
class ConversationCorruptedException extends ConversationStorageException {
  ConversationCorruptedException(
    String conversationId, {
    dynamic originalError,
  }) : super(
          'Conversation file is corrupted or invalid',
          conversationId: conversationId,
          originalError: originalError,
        );
}

