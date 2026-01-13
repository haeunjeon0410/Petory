import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../record_data.dart';
import 'color_picker_dialog.dart'; // 색상 선택 다이얼로그가 있는 경로에 맞춰 확인해주세요
import '../../shared/app_dialog_style.dart';

class ScheduleDetailPage extends StatefulWidget {
  final DateTime date;
  final Schedule? schedule; // 수정 모드일 때 기존 데이터를 받음

  const ScheduleDetailPage({super.key, required this.date, this.schedule});

  @override
  State<ScheduleDetailPage> createState() => _ScheduleDetailPageState();
}

class _ScheduleDetailPageState extends State<ScheduleDetailPage> {
  late Color _color;
  late TextEditingController _titleController;
  late TextEditingController _contentController;
  bool _alarmOn = false;
  late DateTime _time;

  @override
  void initState() {
    super.initState();
    // 1. 초기값 설정: 수정 모드면 기존 데이터를, 아니면 기본값을 사용해요.
    _color = widget.schedule?.color ?? const Color(0xFF605A55);
    _titleController = TextEditingController(
      text: widget.schedule?.title ?? '',
    ); // 'text' 대신 'title' 사용
    _contentController = TextEditingController(
      text: widget.schedule?.content ?? '',
    );
    _alarmOn = widget.schedule?.alarm ?? false;

    // 2. 시간 설정
    if (widget.schedule?.time != null) {
      final now = DateTime.now();
      _time = DateTime(
        now.year,
        now.month,
        now.day,
        widget.schedule!.time!.hour,
        widget.schedule!.time!.minute,
      );
    } else {
      _time = DateTime.now();
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppDialogStyle.background,
      shape: AppDialogStyle.shape(),
      insetPadding: AppDialogStyle.insetPadding,
      child: Container(
        height: 500, // 레이아웃에 맞춰 적절히 조정했어요
        padding: AppDialogStyle.contentPadding,
        child: Column(
          children: [
            // 상단 헤더 영역
            Row(
              children: [
                Text(
                  widget.schedule == null ? '일정 추가' : '일정 수정',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    color: Color(0xFF44403B),
                  ),
                ),
                const Spacer(),

                // [하은님 요청] 알람 아이콘 토글 (작대기 아이콘 적용)
                IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () => setState(() => _alarmOn = !_alarmOn),
                  icon: Icon(
                    _alarmOn
                        ? Icons.notifications
                        : Icons.notifications_off_outlined,
                    color: const Color(0xFF44403B),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),

                // 색상 선택 버튼
                GestureDetector(
                  onTap: () async {
                    final picked = await showDialog<Color>(
                      context: context,
                      builder: (_) => ColorPickerDialog(initialColor: _color),
                    );
                    if (picked != null) setState(() => _color = picked);
                  },
                  child: CircleAvatar(radius: 10, backgroundColor: _color),
                ),
                const SizedBox(width: 8),

                // 닫기 버튼
                IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  icon: const Icon(
                    Icons.close_rounded,
                    color: Color(0xFF605A55),
                    size: 22,
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 입력 영역
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    TextField(
                      controller: _titleController,
                      maxLength: 11,
                      decoration: InputDecoration(
                        hintText: '제목',
                        counterText: "",
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _contentController,
                      maxLines: 3,
                      maxLength: 36,
                      decoration: InputDecoration(
                        hintText: '내용',
                        counterText: "",
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      height: 120,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: CupertinoDatePicker(
                        mode: CupertinoDatePickerMode.time,
                        initialDateTime: _time,
                        onDateTimeChanged: (v) => setState(() => _time = v),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // 저장/수정 완료 버튼
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF44403B),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  elevation: 0,
                ),
                onPressed: () {
                  if (_titleController.text.isEmpty) return;

                  // 결과를 반환하며 팝업을 닫아요
                  Navigator.pop(
                    context,
                    Schedule(
                      date: widget.date,
                      title: _titleController.text,
                      content: _contentController.text,
                      color: _color,
                      time: TimeOfDay.fromDateTime(_time),
                      alarm: _alarmOn,
                    ),
                  );
                },
                child: Text(
                  widget.schedule == null ? '저장하기' : '수정 완료',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
