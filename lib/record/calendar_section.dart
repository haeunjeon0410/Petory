import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'schedule/schedule_detail_page.dart';
import 'record_data.dart' as record;

class CalendarSection extends StatefulWidget {
  const CalendarSection({super.key});

  @override
  State<CalendarSection> createState() => _CalendarSectionState();
}

class _CalendarSectionState extends State<CalendarSection> {
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();

  Widget _buildDayCell(DateTime day, {Color? textColor}) {
    final key = record.normalizeDate(day);
    final schedules = record.schedules[key] ?? [];

    Color dayColor = Colors.black;
    if (day.weekday == DateTime.sunday) dayColor = Colors.red;
    if (day.weekday == DateTime.saturday) dayColor = Colors.blue;
    if (textColor != null) dayColor = textColor;

    bool isToday = isSameDay(day, DateTime.now());

    return Container(
      alignment: Alignment.topCenter,
      child: Column(
        children: [
          const SizedBox(height: 4),
          Container(
            height: 28,
            width: 28,
            alignment: Alignment.center,
            decoration: isToday
                ? BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFF1F2ED), width: 4.0),
            )
                : null,
            child: Text(
              '${day.day}',
              style: TextStyle(
                fontSize: 15,
                color: dayColor,
                fontWeight: FontWeight.normal,
              ),
            ),
          ),
          const SizedBox(height: 2),
          ...schedules.take(2).map((s) => Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(color: s.color, shape: BoxShape.circle),
                ),
                const SizedBox(width: 3),
                Flexible(
                  child: Text(
                    s.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 10, color: Color(0xFF44403B)),
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  void _showScheduleListDialog(BuildContext context, DateTime day) {
    final key = record.normalizeDate(day);

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final daySchedules = record.schedules[key] ?? [];

            return Dialog(
              backgroundColor: const Color(0xFFF1F2ED),
              insetPadding: const EdgeInsets.symmetric(horizontal: 40),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              child: Container(
                height: 480,
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          '${day.day} ${DateFormat('EEEE', 'ko_KR').format(day)}',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF44403B)),
                        ),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.close, size: 20, color: Color(0xFF605A55)),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: daySchedules.isEmpty
                          ? const Center(child: Text('등록된 일정이 없습니다.', style: TextStyle(color: Colors.grey)))
                          : ListView.builder(
                        itemCount: daySchedules.length,
                        itemBuilder: (context, index) {
                          final s = daySchedules[index];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  margin: const EdgeInsets.only(top: 4),
                                  width: 4, height: 32,
                                  decoration: BoxDecoration(color: s.color, borderRadius: BorderRadius.circular(2)),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(s.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF44403B))),
                                      if (s.content.isNotEmpty) ...[
                                        const SizedBox(height: 4),
                                        Text(s.content, style: const TextStyle(fontSize: 13, color: Color(0xFF605A55))),
                                      ],
                                      if (s.time != null) ...[
                                        const SizedBox(height: 4),
                                        Text(s.time!.format(context), style: const TextStyle(fontSize: 11, color: Colors.grey)),
                                      ],
                                    ],
                                  ),
                                ),
                                // 수정 버튼 추가
                                IconButton(
                                  icon: const Icon(Icons.edit_outlined, color: Color(0xFF605A55), size: 20),
                                  onPressed: () async {
                                    final editedResult = await showDialog<record.Schedule>(
                                      context: context,
                                      barrierDismissible: false,
                                      builder: (_) => ScheduleDetailPage(date: day, schedule: s),
                                    );
                                    if (editedResult != null) {
                                      setModalState(() {
                                        record.schedules[key]![index] = editedResult;
                                      });
                                      setState(() {});
                                    }
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
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
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF44403B),
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        onPressed: () async {
                          final result = await showDialog<record.Schedule>(
                            context: context,
                            barrierDismissible: false,
                            builder: (_) => ScheduleDetailPage(date: day),
                          );
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
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 14, offset: const Offset(0, 6))],
      ),
      child: Column(
        children: [
          _buildHeader(),
          TableCalendar(
            locale: 'ko_KR',
            firstDay: DateTime.utc(2020, 1, 1),
            lastDay: DateTime.utc(2035, 12, 31),
            focusedDay: _focusedDay,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            rowHeight: 72,
            daysOfWeekHeight: 32,
            onPageChanged: (focusedDay) {
              setState(() {
                _focusedDay = focusedDay;
              });
            },
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
              });
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

  Widget _buildHeader() {
    return Row(
      children: [
        IconButton(icon: const Icon(Icons.chevron_left, color: Color(0xFF44403B)), onPressed: () => setState(() => _focusedDay = DateTime(_focusedDay.year, _focusedDay.month - 1))),
        Expanded(child: Center(child: Text(DateFormat('yyyy년 M월').format(_focusedDay), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF44403B))))),
        IconButton(icon: const Icon(Icons.chevron_right, color: Color(0xFF44403B)), onPressed: () => setState(() => _focusedDay = DateTime(_focusedDay.year, _focusedDay.month + 1))),
      ],
    );
  }
}