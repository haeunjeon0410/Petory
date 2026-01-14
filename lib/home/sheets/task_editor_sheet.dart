import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import '../models/task_model.dart';
import '../widgets/common_text_field.dart';

class TaskEditorSheet extends StatefulWidget {
  final Task? existingTask;

  const TaskEditorSheet({super.key, this.existingTask});

  @override
  State<TaskEditorSheet> createState() => _TaskEditorSheetState();
}

class _TaskEditorSheetState extends State<TaskEditorSheet> {
  final _titleController = TextEditingController();
  final _timeController = TextEditingController();
  final _memoController = TextEditingController();

  String _selectedEmoji = "🐾";
  bool _isEmojiPickerVisible = false;
  DateTime _selectedTime = DateTime.now();

  @override
  void initState() {
    super.initState();
    _initTime();

    if (widget.existingTask != null) {
      final task = widget.existingTask!;
      _titleController.text = widget.existingTask!.title;
      _timeController.text = widget.existingTask!.time;
      _memoController.text = widget.existingTask!.memo ?? "";
      _selectedEmoji = widget.existingTask!.icon ?? "🐾";
    }
  }

  void _initTime() {
    DateTime now = DateTime.now();
    // 필요 시 시간 보정 로직 유지
    if (now.timeZoneOffset.inHours == 0) {
      now = now.add(const Duration(hours: 9));
    }
    _selectedTime = now;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
        setState(() => _isEmojiPickerVisible = false);
      },
      child: Container(
        // [디자인] 높이 및 배경색, 모서리 둥글게 (반려동물 등록창과 통일)
        height: MediaQuery.of(context).size.height * 0.70,
        decoration: BoxDecoration(
          color: const Color(0xFFF1F2ED),
          borderRadius: BorderRadius.circular(24),
        ),
        clipBehavior: Clip.hardEdge,
        child: Column(
          children: [
            // 1. 헤더 (검은색 바 제거하고 깔끔하게 변경)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    widget.existingTask != null ? "일정 수정" : "새 일정 추가",
                    style: const TextStyle(
                      color: Color(0xFF44403B),
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(
                      Icons.close,
                      color: Color(0xFF605A55),
                      size: 22,
                    ),
                  ),
                ],
              ),
            ),

            // 2. 입력 폼 영역
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
                                  children: [
                                    _buildLabel("아이콘"),
                                    GestureDetector(
                                      onTap: () {
                                        FocusScope.of(context).unfocus();
                                        setState(
                                          () => _isEmojiPickerVisible =
                                              !_isEmojiPickerVisible,
                                        );
                                      },
                                      child: Container(
                                        height: 56, // 텍스트 필드 높이와 비슷하게 맞춤
                                        alignment: Alignment.center,
                                        decoration: BoxDecoration(
                                          // [디자인] 배경색 변경
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          border: Border.all(
                                            color: _isEmojiPickerVisible
                                                ? const Color(0xFF44403B)
                                                : const Color(0xFFE7E5E4),
                                            width: _isEmojiPickerVisible
                                                ? 2.0
                                                : 0.0,
                                          ),
                                        ),
                                        child: Text(
                                          _selectedEmoji,
                                          style: const TextStyle(fontSize: 28),
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
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildLabel("일정 이름 *"),
                                    CommonTextField(
                                      controller: _titleController,
                                      hint: "예: 아침 산책",
                                      onTap: () => setState(
                                        () => _isEmojiPickerVisible = false,
                                      ),
                                      maxLength: 13,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),

                          // 시간 선택
                          _buildLabel("시간 *"),
                          Container(
                            height: 120, // 조금 더 여유 있게
                            decoration: BoxDecoration(
                              // [디자인] 배경색 변경
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: CupertinoDatePicker(
                              mode: CupertinoDatePickerMode.time,
                              initialDateTime: _selectedTime,
                              use24hFormat: false,
                              onDateTimeChanged: (newDate) {
                                setState(() {
                                  _selectedTime = newDate;
                                  _timeController.text = _formatTime(newDate);
                                });
                              },
                            ),
                          ),
                          const SizedBox(height: 24),

                          // 메모
                          _buildLabel("메모"),
                          CommonTextField(
                            controller: _memoController,
                            hint: "메모 (선택)",
                            maxLines: 4,
                            onTap: () =>
                                setState(() => _isEmojiPickerVisible = false),
                            maxLength: 95,
                          ),
                          const SizedBox(height: 40),

                          // 저장 버튼 (스타일 통일)
                          SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: ElevatedButton(
                              onPressed: _saveTask,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF44403B),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(18),
                                ),
                                elevation: 0,
                              ),
                              child: Text(
                                widget.existingTask != null ? "수정하기" : "추가하기",
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20), // 하단 여백 확보
                        ],
                      ),
                    ),
                  ),

                  // 이모지 피커 영역
                  if (_isEmojiPickerVisible)
                    SizedBox(
                      height: 250,
                      child: EmojiPicker(
                        onEmojiSelected: (category, emoji) {
                          setState(() => _selectedEmoji = emoji.emoji);
                        },
                        config: const Config(
                          height: 250,
                          viewOrderConfig: ViewOrderConfig(),
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

  void _saveTask() {
    if (_titleController.text.isEmpty) return;

    if (_timeController.text.isEmpty) {
      _timeController.text = _formatTime(_selectedTime);
    }

    final newTask = Task(
      title: _titleController.text,
      time: _timeController.text,
      memo: _memoController.text,
      icon: _selectedEmoji,
      isDone: widget.existingTask?.isDone ?? false,
    );

    Navigator.pop(context, newTask);
  }

  String _formatTime(DateTime date) {
    final timeOfDay = TimeOfDay.fromDateTime(date);
    return timeOfDay.format(context);
  }

  // [디자인] pet_register_sheet와 동일한 라벨 스타일
  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: RichText(
        text: TextSpan(
          text: text.replaceAll('*', ''),
          style: const TextStyle(
            color: Color(0xFF44403B),
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
          children: [
            if (text.contains('*'))
              const TextSpan(
                text: ' *',
                style: TextStyle(color: Colors.redAccent),
              ),
          ],
        ),
      ),
    );
  }
}
