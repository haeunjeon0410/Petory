import 'package:flutter/material.dart';
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
  bool isEmojiPickerVisible = false;

  @override
  void initState() {
    super.initState();
    if (widget.existingItem != null) {
      titleController.text = widget.existingItem!['title'];
      timeController.text = widget.existingItem!['time'];
      memoController.text = widget.existingItem!['memo'] ?? "";
      if (widget.existingItem!['icon'] is String) {
        selectedEmoji = widget.existingItem!['icon'];
      }
    }
  }

  // [수정된 부분] 시간 선택 시 키보드 입력 모드로 열기
  Future<void> _selectTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      // [핵심] 이 옵션을 추가하면 키보드 입력창이 기본으로 뜹니다.
      initialEntryMode: TimePickerEntryMode.input,
    );

    if (picked != null && mounted) {
      final localizations = MaterialLocalizations.of(context);
      // "오전 8:00" 같은 형식으로 변환
      String formattedTime = localizations.formatTimeOfDay(
        picked,
        alwaysUse24HourFormat: false,
      );
      timeController.text = formattedTime;
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

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        children: [
          // 1. 헤더
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFE040FB), Color(0xFF9C27B0)],
              ),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
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
                  child: const Icon(Icons.close, color: Colors.white, size: 28),
                ),
              ],
            ),
          ),

          // 2. 입력 폼
          Expanded(
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
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
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildLabel("아이콘"),
                                  GestureDetector(
                                    onTap: _toggleEmojiPicker,
                                    child: Container(
                                      height: 56,
                                      alignment: Alignment.center,
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: isEmojiPickerVisible
                                              ? const Color(0xFF9C27B0)
                                              : const Color(0xFFE1BEE7),
                                          width: isEmojiPickerVisible
                                              ? 2.0
                                              : 1.0,
                                        ),
                                      ),
                                      child: Text(
                                        selectedEmoji,
                                        style: const TextStyle(fontSize: 28),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            // 제목 입력
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
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

                        _buildLabel("시간 *"),
                        GestureDetector(
                          onTap: () {
                            _hideEmojiPicker();
                            _selectTime();
                          },
                          child: AbsorbPointer(
                            child: _buildTextField(
                              timeController,
                              "--:--",
                              suffixIcon: const Icon(
                                Icons.access_time,
                                color: Color(0xFFAB47BC),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        _buildLabel("메모"),
                        _buildTextField(
                          memoController,
                          "추가 메모 (선택)",
                          maxLines: 4,
                          onTap: _hideEmojiPicker,
                        ),
                        const SizedBox(height: 40),

                        // 저장/추가 버튼
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
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFFE040FB),
                                    Color(0xFF9C27B0),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Container(
                                alignment: Alignment.center,
                                child: Text(
                                  widget.existingItem != null ? "수정하기" : "추가하기",
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
                style: TextStyle(color: Colors.deepPurple),
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
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFE1BEE7)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF9C27B0), width: 1.5),
          ),
          fillColor: const Color(0xFFFDF7FF),
          filled: true,
          suffixIcon: suffixIcon,
        ),
      ),
    );
  }
}
