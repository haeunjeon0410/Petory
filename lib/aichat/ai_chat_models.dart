class ChatMessage {
  final String text;
  final bool isMe;
  final String? petName;
  final DateTime timestamp;
  // ⭐ 애니메이션을 켤지 끌지 결정하는 필드 추가!
  final bool shouldAnimate;

  ChatMessage({
    required this.text,
    required this.isMe,
    this.petName,
    required this.timestamp,
    // ⭐ 기본값은 true로 설정해서 일반적인 AI 답변은 타이핑 효과가 나오게 해!
    this.shouldAnimate = true,
  });
}
