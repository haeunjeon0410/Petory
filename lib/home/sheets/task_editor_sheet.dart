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
      _titleController.text = task.title;
      _timeController.text = task.time;
      _memoController.text = task.memo ?? "";
      _selectedEmoji = task.icon ?? "🐾";
    }
  }

  void _initTime() {
    DateTime now = DateTime.now();
    if (now.timeZoneOffset.inHours == 0) {
      now = now.add(const Duration(hours: 9)); // KST 보정 (필요시)
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
              color: const Color(0xFF44403B),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    widget.existingTask != null ? "일정 수정" : "새 일정 추가",
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
                                        height: 56,
                                        alignment: Alignment.center,
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFF1F2ED),
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          border: Border.all(
                                            color: _isEmojiPickerVisible
                                                ? const Color(0xFF44403B)
                                                : const Color(0xFFF1F2ED),
                                            width: _isEmojiPickerVisible
                                                ? 2.0
                                                : 1.0,
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
                            height: 100,
                            margin: const EdgeInsets.only(top: 10),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F2ED),
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

                          _buildLabel("메모"),
                          CommonTextField(
                            controller: _memoController,
                            hint: "추가 메모 (선택)",
                            maxLines: 4,
                            onTap: () =>
                                setState(() => _isEmojiPickerVisible = false),
                            maxLength: 95,
                          ),
                          const SizedBox(height: 40),

                          // 저장 버튼
                          SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: ElevatedButton(
                              onPressed: _saveTask,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF44403B),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
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

    // 시간 값이 비어있으면 현재 설정된 시간으로 채움
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
    return timeOfDay.format(context); // "오전 8:00" 형식 자동 변환
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
}
