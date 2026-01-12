import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
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
  late GenerativeModel _model;
  late ChatSession _chatSession;
  bool _isLoading = false;

  // 1. 자동 스크롤을 위한 컨트롤러
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _resetChat();
    _initGemini();
  }

  @override
  void dispose() {
    _scrollController.dispose(); // 메모리 해제
    super.dispose();
  }

  void _initGemini() {
    const String apiKey = 'AIzaSyAst0clfoDv3fJgAyXs5oIS0KtQyD3CvF4';

    _model = GenerativeModel(
      model: 'gemini-2.5-flash',
      apiKey: apiKey,
      // 하은님 스타일의 알잘딱깔센 프롬프트
      systemInstruction: Content.system(
            "당신은 `${record.selectedPetName}`의 전담 건강 매니저 '펫토리 닥터'입니다. "
                "다음 원칙을 지켜 답변하세요. "
                "1. 호칭: 사용자를 반드시 `${record.selectedPetName} 보호자님`이라고 부르세요. "
                "2. 요약 중심: 서론은 생략하고 가장 중요한 핵심 결론부터 바로 말하세요. "
                "3. 구조화: 불렛 포인트(-)를 사용하여 행동 요령을 최대 3까지만 제시하세요. "
                "4. 길이 제한: 전체 답변은 150자 이내, 3~4줄 정도로 짧게 유지하세요. "
                "5. 응급 안내: 위급 상황 시 맨 앞에 [🚨 응급] 표시를 붙이고 즉시 병원 방문을 권고하세요. "
                "6. 금지 사항: 텍스트에 ** 기호(마크다운 굵기)를 절대 적지 마세요. "
                "7. 센스 있는 마무리: 답변 끝에 보호자님이 대답할 수 있는 짧은 질문이나 관련 제안을 한 줄 추가하세요."
        ),
    );

    _chatSession = _model.startChat();
  }

  // 2. 화면 맨 아래로 부드럽게 스크롤하는 함수
  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _resetChat() {
    setState(() {
      _messages = [
        ChatMessage(
          text: "안녕하세요! 펫토리 닥터입니다. 어떻게 도와드릴까요?",
          isMe: false,
          petName: record.selectedPetName,
          timestamp: DateTime.now(),
        ),
      ];
    });
  }

  Future<void> _handleSendMessage(String text) async {
    setState(() {
      _messages.add(ChatMessage(text: text, isMe: true, timestamp: DateTime.now()));
      _isLoading = true;
    });
    _scrollToBottom(); // 내 메시지 전송 후 스크롤

    try {
      final response = await _chatSession.sendMessage(Content.text(text));

      setState(() {
        _messages.add(ChatMessage(
          text: response.text ?? "죄송해요, 답변을 생성하지 못했어요.",
          isMe: false,
          petName: record.selectedPetName,
          timestamp: DateTime.now(),
        ));
      });
      _scrollToBottom(); // AI 답변 후 스크롤
    } catch (e) {
      setState(() {
        _messages.add(ChatMessage(
          text: "서버 연결에 문제가 생겼어요. 다시 시도해주세요.",
          isMe: false,
          timestamp: DateTime.now(),
        ));
      });
      _scrollToBottom();
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
              controller: _scrollController, // 컨트롤러 연결
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                // 각 메시지에 고유 키를 주어 타이핑 효과가 올바르게 작동하게 함
                return ChatBubble(
                    key: ValueKey(_messages[index].timestamp),
                    message: _messages[index]
                );
              },
            ),
          ),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Center(
                child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF44403B))),
              ),
            ),
          ChatInputField(onSendMessage: _handleSendMessage),
        ],
      ),
    );
  }
}