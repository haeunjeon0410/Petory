import 'dart:async';
import 'package:flutter/material.dart';
import 'ai_chat_models.dart';

class ChatBubble extends StatefulWidget {
  final ChatMessage message;
  final VoidCallback? onTyping;

  const ChatBubble({super.key, required this.message, this.onTyping});

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
    if (widget.message.isMe || !widget.message.shouldAnimate) {
      _displayedText = widget.message.text;
    } else {
      _startTyping();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTyping() {
    _timer = Timer.periodic(const Duration(milliseconds: 30), (timer) {
      if (_currentIndex < widget.message.text.length) {
        if (mounted) {
          setState(() {
            _displayedText += widget.message.text[_currentIndex];
            _currentIndex++;
          });
          widget.onTyping?.call(); // 글자가 추가될 때마다 부모의 스크롤 함수 호출
        }
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
                    widget.message.petName ?? '펫토리 닥터',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Color(0xFF44403B))
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
                ),
                child: Text(
                  _displayedText,
                  style: TextStyle(color: widget.message.isMe ? Colors.white : Colors.black87, height: 1.4, fontSize: 14),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ⭐ 에러 해결: 누락되었던 ChatInputField 클래스 추가
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