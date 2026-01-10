import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'schedule/schedule_detail_page.dart';
import 'record_data.dart' as record;
import 'photo_grid_section.dart';

class RecordPage extends StatefulWidget {
  const RecordPage({super.key});

  @override
  State<RecordPage> createState() => _RecordPageState();
}

class _RecordPageState extends State<RecordPage> {
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      setState(() {
        final key = record.normalizeDate(_selectedDay);
        record.photos.putIfAbsent(key, () => []);
        record.photos[key]!.add(image.path);
      });
    }
  }

  Widget _buildDayCell(DateTime day, {Color? textColor}) {
    Color dayColor = Colors.black;
    if (day.weekday == DateTime.sunday) dayColor = Colors.red;
    if (day.weekday == DateTime.saturday) dayColor = Colors.blue;
    if (textColor != null) dayColor = textColor;

    bool isToday = isSameDay(day, DateTime.now());
    final key = record.normalizeDate(day);
    final daySchedules = record.schedules[key] ?? [];

    return Container(
      alignment: Alignment.topCenter,
      child: Column(
        children: [
          const SizedBox(height: 4),
          Container(
            height: 28, width: 28, alignment: Alignment.center,
            decoration: isToday ? BoxDecoration(shape: BoxShape.circle, border: Border.all(color: const Color(0xFFF1F2ED), width: 4.0)) : null,
            child: Text('${day.day}', style: TextStyle(fontSize: 15, color: dayColor)),
          ),
          const SizedBox(height: 2),
          ...daySchedules.take(2).map((s) => Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Container(width: 6, height: 6, decoration: BoxDecoration(color: s.color, shape: BoxShape.circle)),
            const SizedBox(width: 3),
            Flexible(child: Text(s.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 10, color: Color(0xFF44403B)))),
          ])),
        ],
      ),
    );
  }

  void _showScheduleListDialog(BuildContext context, DateTime day) {
    final key = record.normalizeDate(day);
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          final daySchedules = record.schedules[key] ?? [];
          return Dialog(
            backgroundColor: const Color(0xFFF1F2ED),
            insetPadding: const EdgeInsets.symmetric(horizontal: 40),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            child: Container(
              height: 480, padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text('${day.day} ${DateFormat('EEEE', 'ko_KR').format(day)}',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF44403B))),
                      const Spacer(),
                      IconButton(icon: const Icon(Icons.close, size: 20), onPressed: () => Navigator.pop(context)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: daySchedules.isEmpty
                        ? const Center(child: Text('등록된 일정이 없습니다.'))
                        : ListView.builder(
                      itemCount: daySchedules.length,
                      itemBuilder: (context, index) {
                        final s = daySchedules[index];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                          child: Row(
                            children: [
                              Container(width: 4, height: 32, decoration: BoxDecoration(color: s.color, borderRadius: BorderRadius.circular(2))),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(s.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                                    if (s.content.isNotEmpty) Text(s.content, style: const TextStyle(fontSize: 13, color: Color(0xFF605A55))),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                                onPressed: () {
                                  setModalState(() => record.schedules[key]!.removeAt(index));
                                  setState(() {});
                                },
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF44403B), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)), padding: const EdgeInsets.symmetric(vertical: 14)),
                      onPressed: () async {
                        final result = await showDialog<record.Schedule>(context: context, barrierDismissible: false, builder: (_) => ScheduleDetailPage(date: day));
                        if (result != null) {
                          setModalState(() {
                            record.schedules.putIfAbsent(key, () => []);
                            record.schedules[key]!.add(result);
                          });
                          setState(() {});
                        }
                      },
                      child: const Text('일정 추가', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F2ED),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
          child: Column(
            children: [
              const SizedBox(height: 16),
              _buildCalendar(),
              const SizedBox(height: 24),
              PhotoGridSection(focusedDay: _focusedDay),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _pickImage,
        backgroundColor: const Color(0xFF44403B),
        child: const Icon(Icons.camera_alt, color: Colors.white),
      ),
    );
  }

  Widget _buildCalendar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left, color: Color(0xFF44403B)),
                onPressed: () => setState(() => _focusedDay = DateTime(_focusedDay.year, _focusedDay.month - 1)),
              ),
              Text(
                DateFormat('yyyy년 M월').format(_focusedDay),
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF44403B)),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right, color: Color(0xFF44403B)),
                onPressed: () => setState(() => _focusedDay = DateTime(_focusedDay.year, _focusedDay.month + 1)),
              ),
            ],
          ),
          TableCalendar(
            locale: 'ko_KR', firstDay: DateTime.utc(2020, 1, 1), lastDay: DateTime.utc(2035, 12, 31),
            focusedDay: _focusedDay, rowHeight: 72, daysOfWeekHeight: 32,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            onPageChanged: (focusedDay) {
              setState(() {
                _focusedDay = focusedDay;
              });
            },
            onDaySelected: (selectedDay, focusedDay) {
              setState(() { _selectedDay = selectedDay; _focusedDay = focusedDay; });
              _showScheduleListDialog(context, selectedDay);
            },
            headerVisible: false,
            calendarBuilders: CalendarBuilders(
              defaultBuilder: (context, day, _) => _buildDayCell(day),
              todayBuilder: (context, day, _) => _buildDayCell(day),
              selectedBuilder: (context, day, _) => _buildDayCell(day, textColor: const Color(0xFF44403B)),
              outsideBuilder: (context, day, _) => _buildDayCell(day, textColor: Colors.grey.withOpacity(0.5)),
            ),
          ),
        ],
      ),
    );
  }
}