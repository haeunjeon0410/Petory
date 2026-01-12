import 'package:flutter/material.dart';
import '../record/record_data.dart' as record;
import 'ai_chat_models.dart';
import 'ai_chat_widgets.dart';

class AiChatPage extends StatefulWidget {
  const AiChatPage({super.key});

  @override
  State<AiChatPage> createState() => _AiChatPageState();
}

class _AiChatPageState extends State<AiChatPage> {
  late List<ChatMessage> _messages;

  @override
  void initState() {
    super.initState();
    _resetChat();
  }

  void _resetChat() {
    _messages = [
      ChatMessage(
        text: "안녕하세요! ${record.selectedPetName}의 건강 AI 도우미입니다. 🐾 오늘 어떻게 도와드릴까요?",
        isMe: false,
        petName: record.selectedPetName,
        timestamp: DateTime.now(),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F2ED),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) => ChatBubble(message: _messages[index]),
            ),
          ),
          const ChatInputField(),
        ],
      ),
    );
  }
}