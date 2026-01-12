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

  String _getPetProfileContext() {
    final petId = record.selectedPetId;
    final profile = record.petProfiles[petId];

    // 선택된 펫이 없거나 데이터가 비어있을 경우
    if (petId.isEmpty || profile == null) {
      return "반려동물 정보가 없습니다.";
    }

    // 데이터 안전하게 가져오기 (null 처리)
    String name = profile['name'] ?? '이름 모름';
    String type = profile['type'] ?? '반려동물'; // 강아지/고양이
    String species = profile['species'] ?? '품종 모름';
    String age = profile['age'] ?? '?';
    String height = profile['height'] ?? '?';
    String weight = profile['weight'] ?? '?';
    String gender = (profile['gender'] == 'male') ? '수컷' : '암컷';
    String neutered = (profile['isNeutered'] == true) ? '중성화 완료' : '중성화 안 함';

    // AI에게 전달할 상세 정보 텍스트 생성
    return """
    - 이름: $name
    - 종류: $type ($species)
    - 나이: ${age}살
    - 신체 정보: 키 ${height}cm, 몸무게 ${weight}kg
    - 성별: $gender ($neutered)
    """;
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
    String petContext = _getPetProfileContext();

    _model = GenerativeModel(
      model: 'gemini-2.5-flash-lite',
      apiKey: apiKey,
      systemInstruction: Content.system(
        "당신은 `$petName`의 전담 건강 매니저 '펫토리 닥터'입니다. "
        "다음 원칙을 지켜 답변하세요. "
        "1. 호칭: 사용자를 반드시 `보호자님`이라고 부르세요. "
        "2. 요약 중심: 서론은 생략하고 가장 중요한 핵심 결론부터 바로 말하세요. "
        "3. 구조화: 불렛 포인트(-)를 사용하여 행동 요령을 최대 3까지만 제시하세요. "
        "4. 길이 제한: 전체 답변은 150자 이내, 3~4줄 정도로 짧게 유지하세요. "
        "5. 응급 안내: 위급 상황 시 맨 앞에 [🚨] 표시를 붙이고 즉시 병원 방문을 권고하세요. "
        "6. 금지 사항: 텍스트에 ** 기호(마크다운 굵기)를 절대 적지 마세요. "
        "7. 센스 있는 마무리: 답변 끝에 보호자님이 대답할 수 있는 짧은 질문이나 관련 제안을 한 줄 추가하세요."
        "8. 말투 : 이모티콘을 적절히 사용해 친절하게 한국어로 답변하세요."
        "9. 반려동물 상세정보: $petContext",
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
