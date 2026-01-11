class ChatMessage {
  final String message;
  final String? answer;
  final String? confidence;
  final bool isUser;
  final DateTime timestamp;

  ChatMessage({
    required this.message,
    this.answer,
    this.confidence,
    required this.isUser,
    required this.timestamp,
  });

  factory ChatMessage.user(String message) {
    return ChatMessage(
      message: message,
      isUser: true,
      timestamp: DateTime.now(),
    );
  }

  factory ChatMessage.agent(String message, String answer, String confidence) {
    return ChatMessage(
      message: message,
      answer: answer,
      confidence: confidence,
      isUser: false,
      timestamp: DateTime.now(),
    );
  }
}

class ChatResponse {
  final String answer;
  final String confidence;

  ChatResponse({
    required this.answer,
    required this.confidence,
  });

  factory ChatResponse.fromJson(Map<String, dynamic> json) {
    return ChatResponse(
      answer: json['answer'] as String,
      confidence: json['confidence'] as String,
    );
  }
}


