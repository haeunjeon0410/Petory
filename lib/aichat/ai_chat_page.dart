import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'ai_chat_models.dart';
import 'ai_chat_widgets.dart';

class AiChatPage extends StatefulWidget {
  const AiChatPage({super.key});

  @override
  State<AiChatPage> createState() => _AiChatPageState();
}

class _AiChatPageState extends State<AiChatPage> {
  late List<ChatMessage> _messages;
  late GenerativeModel _model;
  late ChatSession _chatSession;
  bool _isLoading = false;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _resetChat();
    _initGemini();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  String _getCurrentPetName() {
    final petId = record.selectedPetId;
    if (petId.isEmpty || record.petProfiles[petId] == null) {
      return "반려동물"; // 기본값
    }
    return record.petProfiles[petId]!['name']?.toString() ?? "반려동물";
  }

  void _initGemini() {
    const String apiKey = 'AIzaSyAst0clfoDv3fJgAyXs5oIS0KtQyD3CvF4';

    String petName = _getCurrentPetName();

    const String apiKey = 'YOUR_API_KEY_HERE'; // 하은이의 API 키를 넣어줘!
    _model = GenerativeModel(
      model: 'gemini-1.5-flash',
      apiKey: apiKey,
      systemInstruction: Content.system(
        "당신은 전담 건강 매니저 '펫토리 닥터'입니다. 보호자님께 친절하고 짧게 핵심만 답변하세요.",
      ),
    );
    _chatSession = _model.startChat();
  }

  // ⭐ 답변이 길어질 때 자동으로 화면을 끝까지 내리는 함수
  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
    }
  }

  void _resetChat() {
    setState(() {
      _messages = [
        ChatMessage(
          text: "안녕하세요! 닥터 펫토리입니다.😊 어떻게 도와드릴까요?",
          isMe: false,
          petName: "dr.펫토리", // ⭐ 이름을 '펫토리 닥터'로 변경
          timestamp: DateTime.now(),
          shouldAnimate: false, // ⭐ 첫 메시지는 타이핑 없이 고정
        ),
      ];
    });
  }

  Future<void> _handleSendMessage(String text) async {
    setState(() {
      _messages.add(
        ChatMessage(text: text, isMe: true, timestamp: DateTime.now()),
      );
      _isLoading = true;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());

    try {
      final response = await _chatSession.sendMessage(Content.text(text));

      setState(() {
        _messages.add(
          ChatMessage(
            text: response.text ?? "죄송합니다. 답변을 생성하지 못했어요.",
            isMe: false,
            petName: "dr.펫토리",
            timestamp: DateTime.now(),
            shouldAnimate: true,
          ),
        );
      });
    } catch (e) {
      setState(() {
        _messages.add(
          ChatMessage(
            text: "연결 오류가 발생했어요. 잠시 후 다시 시도해주세요.",
            isMe: false,
            petName: "dr.펫토리",
            timestamp: DateTime.now(),
            shouldAnimate: false,
          ),
        );
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F2ED),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                return ChatBubble(
                  key: ValueKey(_messages[index].timestamp),
                  message: _messages[index],
                  key: ValueKey(_messages[index].timestamp),
                  message: _messages[index],
                  onTyping: _scrollToBottom, // ⭐ 타이핑 칠 때마다 스크롤 호출
                );
              },
            ),
          ),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Color(0xFF44403B),
                  ),
                ),
              ),
            ),
          ChatInputField(onSendMessage: _handleSendMessage),
        ],
      ),
    );
  }
}
