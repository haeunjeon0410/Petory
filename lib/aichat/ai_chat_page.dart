import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../record/record_data.dart' as record;
import 'ai_chat_models.dart';
import 'ai_chat_widgets.dart';

class AiChatPage extends StatefulWidget {
  final VoidCallback? onRefresh;
  const AiChatPage({super.key, this.onRefresh});

  @override
  State<AiChatPage> createState() => _AiChatPageState();
}

class _AiChatPageState extends State<AiChatPage> {
  late List<ChatMessage> _messages;
  late GenerativeModel _model;
  late ChatSession _chatSession;

  // 로딩 상태 변수는 이제 UI 표시용으로는 쓰지 않지만, 중복 전송 방지용으로 남겨둡니다.
  bool _isSending = false;
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

    if (petId.isEmpty || profile == null) {
      return "반려동물 정보가 없습니다.";
    }

    String name = profile['name'] ?? '이름 모름';
    String type = profile['type'] ?? '반려동물';
    String species = profile['species'] ?? '품종 모름';
    String age = profile['age'] ?? '?';
    String height = profile['height'] ?? '?';
    String weight = profile['weight'] ?? '?';
    String gender = (profile['gender'] == 'male') ? '수컷' : '암컷';
    String neutered = (profile['isNeutered'] == true) ? '중성화 완료' : '중성화 안 함';

    return """
    - 이름: $name
    - 종류: $type ($species)
    - 나이: $age살
    - 신체 정보: 키 ${height}cm, 몸무게 ${weight}kg
    - 성별: $gender ($neutered)
    """;
  }

  String _getCurrentPetName() {
    final petId = record.selectedPetId;
    if (petId.isEmpty || record.petProfiles[petId] == null) {
      return "반려동물";
    }
    return record.petProfiles[petId]!['name']?.toString() ?? "반려동물";
  }

  void _changePetProfile(String petId) {
    setState(() {
      record.selectedPetId = petId;
      _resetChat();
      _initGemini();
    });
  }

  void _initGemini() {
    const String apiKey = 'AIzaSyAst0clfoDv3fJgAyXs5oIS0KtQyD3CvF4';

    String petName = _getCurrentPetName();
    String petContext = _getPetProfileContext();

    _model = GenerativeModel(
      model: 'gemini-1.5-flash-lite',
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

  // 스크롤 함수 (역순 리스트이므로 0.0이 맨 아래)
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
          text: "안녕하세요! 닥터 펫토리입니다.😊 어떻게 도와드릴까요?",
          isMe: false,
          petName: "dr.펫토리",
          timestamp: DateTime.now(),
          shouldAnimate: false,
        ),
      ];
    });
  }

  // [핵심 변경] 메시지 전송 로직: 로딩바 없이 말풍선 즉시 추가
  Future<void> _handleSendMessage(String text) async {
    if (_isSending) return; // 중복 전송 방지

    setState(() {
      _isSending = true;
      // 1. 내 메시지 추가
      _messages.add(
        ChatMessage(text: text, isMe: true, timestamp: DateTime.now()),
      );

      // 2. [핵심] AI의 "생각 중..." 말풍선을 미리 추가 (UI상 바로 뜸)
      _messages.add(
        ChatMessage(
          text: "...", // 점 세 개로 타이핑 중임을 표시
          isMe: false,
          petName: "dr.펫토리",
          timestamp: DateTime.now(),
          shouldAnimate: false, // 점 세 개는 타이핑 효과 X
        ),
      );
    });

    // 스크롤을 맨 아래로 이동
    _scrollToBottom();

    try {
      final response = await _chatSession.sendMessage(Content.text(text));

      setState(() {
        // 3. 응답이 오면 마지막 메시지(점 세 개)를 제거하고 진짜 답변으로 교체
        _messages.removeLast();

        _messages.add(
          ChatMessage(
            text: response.text ?? "죄송합니다. 답변을 생성하지 못했어요.",
            isMe: false,
            petName: "dr.펫토리",
            timestamp: DateTime.now(),
            shouldAnimate: true, // 진짜 답변은 타이핑 효과 O
          ),
        );
      });

      // 답변 길이만큼 늘어난 화면을 위해 스크롤 보정
      _scrollToBottom();
    } catch (e) {
      setState(() {
        _messages.removeLast(); // 에러 시에도 점 세 개 제거
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
      setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    String currentPetId = record.selectedPetId;
    if ((currentPetId.isEmpty || !record.myPetIds.contains(currentPetId)) &&
        record.myPetIds.isNotEmpty) {
      currentPetId = record.myPetIds[0];
      record.selectedPetId = currentPetId;
    }

    return Scaffold(
      backgroundColor: const Color(0xFFA7BD7F),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                return ChatBubble(
                  key: ValueKey(message.timestamp),
                  message: message,
                  onTyping: null,
                );
              },
            ),
          ),

          // [삭제됨] 로딩 인디케이터(CircularProgressIndicator) 코드 제거 완료
          ChatInputField(onSendMessage: _handleSendMessage),
        ],
      ),
    );
  }
}
