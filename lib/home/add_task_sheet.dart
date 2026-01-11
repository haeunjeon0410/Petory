import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';

class AddTaskSheet extends StatefulWidget {
  final Map<String, dynamic>? existingItem;

  const AddTaskSheet({super.key, this.existingItem});

  @override
  State<AddTaskSheet> createState() => _AddTaskSheetState();
}

class _AddTaskSheetState extends State<AddTaskSheet> {
  final TextEditingController titleController = TextEditingController();
  final TextEditingController timeController = TextEditingController();
  final TextEditingController memoController = TextEditingController();

  String selectedEmoji = "🐾";

  // [수정] 시간 선택창은 항상 보이므로 관련 상태 변수 삭제
  bool isEmojiPickerVisible = false;
  DateTime _selectedTime = DateTime.now();

  @override
  void initState() {
    super.initState();

    // [수정] 한국 시간(KST) 보정 로직
    DateTime now = DateTime.now();

    if (now.timeZoneOffset.inHours == 0) {
      now = now.add(const Duration(hours: 9));
    }

    _selectedTime = now;

    if (widget.existingItem != null) {
      // (기존 데이터 불러오는 부분은 그대로 유지)
      titleController.text = widget.existingItem!['title'];
      timeController.text = widget.existingItem!['time'];
      memoController.text = widget.existingItem!['memo'] ?? "";
      if (widget.existingItem!['icon'] is String) {
        selectedEmoji = widget.existingItem!['icon'];
      }
    }
  }

  void _toggleEmojiPicker() {
    FocusScope.of(context).unfocus();
    setState(() {
      isEmojiPickerVisible = !isEmojiPickerVisible;
    });
  }

  void _hideEmojiPicker() {
    if (isEmojiPickerVisible) {
      setState(() {
        isEmojiPickerVisible = false;
      });
    }
  }

  void _onTimeChanged(DateTime newDate) {
    setState(() {
      _selectedTime = newDate;
      final timeOfDay = TimeOfDay.fromDateTime(newDate);
      final localizations = MaterialLocalizations.of(context);
      final formattedTime = localizations.formatTimeOfDay(
        timeOfDay,
        alwaysUse24HourFormat: false,
      );
      timeController.text = formattedTime;
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
        _hideEmojiPicker();
      },
      child: Container(
        // 팝업 높이를 조금 더 넉넉하게 70%로 설정
        height: MediaQuery.of(context).size.height * 0.70,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        clipBehavior: Clip.hardEdge,
        child: Column(
          children: [
            // 1. 헤더
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              decoration: const BoxDecoration(
                color: Color(0xFF44403B), // 짙은 갈색 헤더
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    widget.existingItem != null ? "일정 수정" : "새 일정 추가",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                ],
              ),
            ),

            // 2. 입력 폼
            Expanded(
              child: Column(
                children: [
                  Expanded(
                    child:
                        NotificationListener<OverscrollIndicatorNotification>(
                          onNotification:
                              (OverscrollIndicatorNotification overscroll) {
                                overscroll.disallowIndicator();
                                return true;
                              },
                          child: SingleChildScrollView(
                            physics: const ClampingScrollPhysics(),
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    // 아이콘 선택
                                    SizedBox(
                                      width: 60,
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          _buildLabel("아이콘"),
                                          GestureDetector(
                                            onTap: _toggleEmojiPicker,
                                            child: Container(
                                              height: 56,
                                              alignment: Alignment.center,
                                              decoration: BoxDecoration(
                                                color: Color(0xFFF1F2ED),
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                                border: Border.all(
                                                  color: isEmojiPickerVisible
                                                      ? const Color(0xFF44403B)
                                                      : const Color(0xFFF1F2ED),
                                                  width: isEmojiPickerVisible
                                                      ? 2.0
                                                      : 1.0,
                                                ),
                                              ),
                                              child: Text(
                                                selectedEmoji,
                                                style: const TextStyle(
                                                  fontSize: 28,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    // 일정 이름
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          _buildLabel("일정 이름 *"),
                                          _buildTextField(
                                            titleController,
                                            "예: 아침 산책",
                                            onTap: _hideEmojiPicker,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 24),

                                // [시간 입력 섹션]
                                _buildLabel("시간 *"),

                                // [핵심] 시간 선택기 (항상 보임)
                                Container(
                                  height: 100,
                                  margin: const EdgeInsets.only(top: 10),
                                  decoration: BoxDecoration(
                                    color: const Color(
                                      0xFFF1F2ED,
                                    ), // [수정] 크림색 배경
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: const Color(0xFFF1F2ED),
                                    ),
                                  ),
                                  // CupertinoDatePicker는 기본적으로 투명 배경이므로
                                  // Container 색상을 따라갑니다.
                                  child: CupertinoDatePicker(
                                    mode: CupertinoDatePickerMode.time,
                                    initialDateTime: _selectedTime,
                                    onDateTimeChanged: _onTimeChanged,
                                    use24hFormat: false,
                                  ),
                                ),

                                const SizedBox(height: 24),

                                _buildLabel("메모"),
                                _buildTextField(
                                  memoController,
                                  "추가 메모 (선택)",
                                  maxLines: 4,
                                  maxLength: 95,
                                  onTap: _hideEmojiPicker,
                                ),
                                const SizedBox(height: 40),

                                // 저장 버튼
                                SizedBox(
                                  width: double.infinity,
                                  height: 56,
                                  child: ElevatedButton(
                                    onPressed: () {
                                      if (titleController.text.isNotEmpty &&
                                          timeController.text.isNotEmpty) {
                                        Navigator.pop(context, {
                                          "title": titleController.text,
                                          "time": timeController.text,
                                          "memo": memoController.text,
                                          "icon": selectedEmoji,
                                          "isDone": widget.existingItem != null
                                              ? widget.existingItem!['isDone']
                                              : false,
                                        });
                                      }
                                    },
                                    style: ElevatedButton.styleFrom(
                                      padding: EdgeInsets.zero,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      backgroundColor: Colors.transparent,
                                    ),
                                    child: Ink(
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF44403B), // 갈색 버튼
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      child: Container(
                                        alignment: Alignment.center,
                                        child: Text(
                                          widget.existingItem != null
                                              ? "수정하기"
                                              : "추가하기",
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                  ),

                  // 이모지 피커
                  if (isEmojiPickerVisible)
                    SizedBox(
                      height: 250,
                      child: EmojiPicker(
                        onEmojiSelected: (category, emoji) {
                          setState(() {
                            selectedEmoji = emoji.emoji;
                          });
                        },
                        config: const Config(
                          height: 250,
                          checkPlatformCompatibility: true,
                          viewOrderConfig: ViewOrderConfig(
                            top: EmojiPickerItem.categoryBar,
                            middle: EmojiPickerItem.emojiView,
                            bottom: EmojiPickerItem.searchBar,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: RichText(
        text: TextSpan(
          text: text.replaceAll('*', ''),
          style: const TextStyle(
            color: Colors.black87,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
          children: [
            if (text.contains('*'))
              const TextSpan(
                text: ' *',
                style: TextStyle(color: Colors.red),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String hint, {
    int maxLines = 1,
    Widget? suffixIcon,
    VoidCallback? onTap,
    int? maxLength,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        onTap: onTap,
        maxLines: maxLines,
        maxLength: maxLength,
        // 읽기 전용으로 설정하면 키보드가 뜨지 않습니다 (시간 필드 등에 유용)
        readOnly: onTap == null ? true : false,
        decoration: InputDecoration(
          hintText: hint,
          counterText: "",
          hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFF1F2ED)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF44403B), width: 1.5),
          ),

          // [수정] 입력칸 배경색: 크림색(#F1F2ED) 적용
          fillColor: const Color(0xFFF1F2ED),

          filled: true,
          suffixIcon: suffixIcon,
        ),
      ),
    );
  }
}
