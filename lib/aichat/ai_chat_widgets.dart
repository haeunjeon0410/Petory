import 'package:flutter/material.dart';
import 'ai_chat_models.dart';

class ChatBubble extends StatelessWidget {
  final ChatMessage message;
  const ChatBubble({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: message.isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!message.isMe) ...[
            const CircleAvatar(radius: 18, child: Icon(Icons.pets, size: 18)),
            const SizedBox(width: 8),
          ],
          Column(
            crossAxisAlignment: message.isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              if (!message.isMe)
                Text(message.petName ?? 'AI', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              Container(
                margin: const EdgeInsets.only(top: 4),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.7),
                decoration: BoxDecoration(
                  color: message.isMe ? const Color(0xFF44403B) : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(message.text, style: TextStyle(color: message.isMe ? Colors.white : Colors.black)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class ChatInputField extends StatelessWidget {
  const ChatInputField({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: const BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: Color(0xFFEEEEEE)))),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(color: const Color(0xFFF1F2ED), borderRadius: BorderRadius.circular(24)),
                child: const TextField(
                  decoration: InputDecoration(hintText: "증상을 설명하거나 질문해 주세요..", border: InputBorder.none),
                ),
              ),
            ),
            const SizedBox(width: 8),
            const CircleAvatar(backgroundColor: Color(0xFF44403B), child: Icon(Icons.send, color: Colors.white, size: 18)),
          ],
        ),
      ),
    );
  }
}