import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../record_data.dart';
import 'color_picker_dialog.dart'; // Color picker dialog.
import '../../shared/app_dialog_style.dart';

class ScheduleDetailPage extends StatefulWidget {
  final DateTime date;
  final Schedule? schedule; // Existing data when editing.

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
    // Initialize fields, prefilling when editing.
    _color = widget.schedule?.color ?? const Color(0xFF605A55);
    _titleController = TextEditingController(
      text: widget.schedule?.title ?? '',
    ); // Use title as initial text.
    _contentController = TextEditingController(
      text: widget.schedule?.content ?? '',
    );
    _alarmOn = widget.schedule?.alarm ?? false;

    // Time setup.
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
        height: 500, // Adjusted height.
        padding: AppDialogStyle.contentPadding,
        child: Column(
          children: [
            // Header
            Row(
              children: [
                Text(
                  widget.schedule == null ? '\uC77C\uC815 \uCD94\uAC00' : '\uC77C\uC815 \uC218\uC815',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    color: Color(0xFF44403B),
                  ),
                ),
                const Spacer(),

                // Alarm toggle
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

                // Color picker
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

                // Close button
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

            // Form fields
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    TextField(
                      controller: _titleController,
                      maxLength: 11,
                      decoration: InputDecoration(
                        hintText: '\uC81C\uBAA9',
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
                        hintText: '\uB0B4\uC6A9',
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

            // Save/update button
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

                  // Return the created/updated schedule.
                  Navigator.pop(
                    context,
                    Schedule(
                      petId: widget.schedule?.petId ?? selectedPetId,
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
                  widget.schedule == null ? '\uCD94\uAC00\uD558\uAE30' : '\uC218\uC815 \uC644\uB8CC',
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
