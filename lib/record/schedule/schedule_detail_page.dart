import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../record_data.dart';
import 'color_picker_dialog.dart';

class ScheduleDetailPage extends StatefulWidget {
  final DateTime date;
  const ScheduleDetailPage({super.key, required this.date});

  @override
  State<ScheduleDetailPage> createState() => _ScheduleDetailPageState();
}

class _ScheduleDetailPageState extends State<ScheduleDetailPage> {
  Color _color = const Color(0xFF605A55);
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  bool _alarmOn = false;
  DateTime _time = DateTime.now();

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFFF1F2ED),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Container(
        height: 480,
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              children: [
                const Text('일정 추가', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: Color(0xFF44403B))),
                const Spacer(),
                GestureDetector(
                  onTap: () async {
                    final picked = await showDialog<Color>(context: context, builder: (_) => ColorPickerDialog(initialColor: _color));
                    if (picked != null) setState(() => _color = picked);
                  },
                  child: CircleAvatar(radius: 10, backgroundColor: _color),
                ),
                const SizedBox(width: 16),
                IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    TextField(controller: _titleController, decoration: InputDecoration(hintText: '제목', filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none))),
                    const SizedBox(height: 12),
                    TextField(controller: _contentController, maxLines: 3, decoration: InputDecoration(hintText: '내용', filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none))),
                    const SizedBox(height: 16),
                    Container(height: 120, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                        child: CupertinoDatePicker(mode: CupertinoDatePickerMode.time, initialDateTime: _time, onDateTimeChanged: (v) => setState(() => _time = v))),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF44403B), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)), padding: const EdgeInsets.symmetric(vertical: 14)),
                onPressed: () {
                  if (_titleController.text.isEmpty) return;
                  Navigator.pop(context, Schedule(date: widget.date, title: _titleController.text, content: _contentController.text, color: _color, time: TimeOfDay.fromDateTime(_time), alarm: _alarmOn));
                },
                child: const Text('저장', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}