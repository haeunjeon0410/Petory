import 'dart:async';
import 'package:flutter/material.dart';
import 'ai_chat_models.dart';

class ChatBubble extends StatefulWidget {
  final ChatMessage message;
  const ChatBubble({super.key, required this.message});

  @override
  State<ChatBubble> createState() => _ChatBubbleState();
}

class _ChatBubbleState extends State<ChatBubble> {
  String _displayedText = "";
  Timer? _timer;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    // 3. 내 메시지는 즉시 보여주고, AI 답변만 타이핑 효과 시작
    if (widget.message.isMe) {
      _displayedText = widget.message.text;
    } else {
      _startTyping();
    }
  }

  @override
  void dispose() {
    _timer?.cancel(); // 타이머 해제
    super.dispose();
  }

  void _startTyping() {
    // 4. 30ms 간격으로 글자를 하나씩 추가
    _timer = Timer.periodic(const Duration(milliseconds: 30), (timer) {
      if (_currentIndex < widget.message.text.length) {
        setState(() {
          _displayedText += widget.message.text[_currentIndex];
          _currentIndex++;
        });
      } else {
        _timer?.cancel();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: widget.message.isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!widget.message.isMe) ...[
            const CircleAvatar(
                radius: 18,
                backgroundColor: Color(0xFF44403B),
                child: Icon(Icons.pets, size: 18, color: Colors.white)
            ),
            const SizedBox(width: 8),
          ],
          Column(
            crossAxisAlignment: widget.message.isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              if (!widget.message.isMe)
                Text(
                    widget.message.petName ?? 'AI 도우미',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF44403B))
                ),
              Container(
                margin: const EdgeInsets.only(top: 4),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.7),
                decoration: BoxDecoration(
                  color: widget.message.isMe ? const Color(0xFF44403B) : Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(16),
                    topRight: const Radius.circular(16),
                    bottomLeft: Radius.circular(widget.message.isMe ? 16 : 0),
                    bottomRight: Radius.circular(widget.message.isMe ? 0 : 16),
                  ),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5, offset: const Offset(0, 2))
                  ],
                ),
                // 5. 색상 하이라이트 없이 깔끔하게 텍스트 출력
                child: Text(
                  _displayedText,
                  style: TextStyle(
                    color: widget.message.isMe ? Colors.white : Colors.black87,
                    height: 1.4,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class ChatInputField extends StatefulWidget {
  final Function(String) onSendMessage;
  const ChatInputField({super.key, required this.onSendMessage});

  @override
  State<ChatInputField> createState() => _ChatInputFieldState();
}

class _ChatInputFieldState extends State<ChatInputField> {
  final TextEditingController _textController = TextEditingController();

  void _handleSend() {
    final text = _textController.text.trim();
    if (text.isNotEmpty) {
      widget.onSendMessage(text);
      _textController.clear();
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

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
                child: TextField(
                  controller: _textController,
                  onSubmitted: (_) => _handleSend(),
                  decoration: const InputDecoration(hintText: "증상을 설명하거나 질문해 주세요..", border: InputBorder.none, hintStyle: TextStyle(fontSize: 14, color: Colors.grey)),
                ),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: _handleSend,
              child: const CircleAvatar(backgroundColor: Color(0xFF44403B), child: Icon(Icons.send, color: Colors.white, size: 18)),
            ),
          ],
        ),
      ),
    );
  }
}