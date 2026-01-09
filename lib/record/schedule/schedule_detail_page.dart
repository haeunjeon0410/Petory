import 'package:flutter/material.dart';
import 'color_picker_dialog.dart';

class ScheduleDetailPage extends StatefulWidget {
  final DateTime date;

  const ScheduleDetailPage({super.key, required this.date});

  @override
  State<ScheduleDetailPage> createState() => _ScheduleDetailPageState();
}

class _ScheduleDetailPageState extends State<ScheduleDetailPage> {
  Color _color = const Color(0xFFB388FF);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const Text(
                  '일정 추가',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () async {
                    final picked = await showDialog<Color>(
                      context: context,
                      builder: (_) =>
                          ColorPickerDialog(initialColor: _color),
                    );
                    if (picked != null) setState(() => _color = picked);
                  },
                  child: CircleAvatar(radius: 10, backgroundColor: _color),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              decoration: InputDecoration(
                hintText: '제목',
                filled: true,
                fillColor: const Color(0xFFF5F5F8),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              maxLines: 4,
              decoration: InputDecoration(
                hintText: '내용을 입력하세요',
                filled: true,
                fillColor: const Color(0xFFF5F5F8),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFB388FF),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: () => Navigator.pop(context),
                child: const Text('저장'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}






