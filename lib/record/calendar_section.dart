import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'schedule/schedule_detail_page.dart';
import 'record_data.dart' as record;

class CalendarSection extends StatefulWidget {
  final Function(DateTime selectedDay, DateTime focusedDay)? onDayChanged;

  const CalendarSection({super.key, this.onDayChanged});

  @override
  State<CalendarSection> createState() => _CalendarSectionState();
}

class _CalendarSectionState extends State<CalendarSection> {
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();

  List<record.Schedule> _getSortedSchedules(DateTime day) {
    final key = record.normalizeDate(day);
    final List<record.Schedule> list = record.schedules[key] != null
        ? List<record.Schedule>.from(record.schedules[key]!)
        : <record.Schedule>[];

    list.sort((a, b) {
      if (a.time == null && b.time == null) return 0;
      if (a.time == null) return 1;
      if (b.time == null) return -1;
      return (a.time!.hour * 60 + a.time!.minute).compareTo(b.time!.hour * 60 + b.time!.minute);
    });
    return list;
  }

  Widget _buildDayCell(DateTime day, {bool isSelected = false, Color? textColor}) {
    final schedules = _getSortedSchedules(day);
    Color dayColor = day.weekday == DateTime.sunday ? Colors.red : (day.weekday == DateTime.saturday ? Colors.blue : Colors.black);
    if (textColor != null) dayColor = textColor;

    bool isToday = isSameDay(day, DateTime.now());

    return Container(
      alignment: Alignment.topCenter,
      child: Column(
        children: [
          const SizedBox(height: 10),
          Container(
            height: 28, width: 28, alignment: Alignment.center,
            decoration: isSelected
                ? const BoxDecoration(color: Color(0xFF44403B), shape: BoxShape.circle)
                : isToday
                ? BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFF1F2ED), width: 4.0),
            )
                : null,
            child: Text(
                '${day.day}',
                style: TextStyle(
                  fontSize: 15,
                  color: isSelected ? Colors.white : dayColor,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                )
            ),
          ),
          const SizedBox(height: 2),
          ...schedules.take(2).map((s) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
              child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(width: 6, height: 6, decoration: BoxDecoration(color: s.color, shape: BoxShape.circle)),
                    const SizedBox(width: 3),
                    Flexible(
                        child: Text(
                            s.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 10, color: Color(0xFF44403B))
                        )
                    ),
                  ])),
          ),
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
          final daySchedules = _getSortedSchedules(day);
          return Dialog(
            backgroundColor: const Color(0xFFF1F2ED),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            child: Container(
              height: 500, padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Text(
                        '${day.day}일 ${DateFormat('EEEE', 'ko_KR').format(day)}',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF44403B))
                    ),
                    IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
                  ]),
                  const SizedBox(height: 8),
                  Expanded(
                    child: daySchedules.isEmpty
                        ? const Center(child: Text('등록된 일정이 없습니다.', style: TextStyle(color: Colors.grey)))
                        : ListView.builder(
                      itemCount: daySchedules.length,
                      itemBuilder: (context, index) {
                        final s = daySchedules[index];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12), padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                          child: Row(children: [
                            Container(width: 4, height: 32, decoration: BoxDecoration(color: s.color, borderRadius: BorderRadius.circular(2))),
                            const SizedBox(width: 12),
                            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text(s.title, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF44403B))),
                              if (s.content.isNotEmpty)
                                Text(s.content, style: const TextStyle(fontSize: 13, color: Color(0xFF605A55))),
                              if (s.time != null) Text(s.time!.format(context), style: const TextStyle(fontSize: 11, color: Colors.grey)),
                            ])),
                            IconButton(icon: const Icon(Icons.edit_outlined, size: 20), onPressed: () async {
                              final result = await showDialog<record.Schedule>(
                                  context: context,
                                  builder: (_) => ScheduleDetailPage(date: day, schedule: s)
                              );
                              if (result != null) {
                                setModalState(() {
                                  final list = record.schedules[key]!;
                                  list[list.indexOf(s)] = result;
                                });
                                setState(() {});
                                if (widget.onDayChanged != null) widget.onDayChanged!(_selectedDay, _focusedDay);
                              }
                            }),
                            IconButton(icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20), onPressed: () {
                              setModalState(() {
                                record.schedules[key]!.remove(s);
                              });
                              setState(() {});
                              if (widget.onDayChanged != null) widget.onDayChanged!(_selectedDay, _focusedDay);
                            }),
                          ]),
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
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          padding: const EdgeInsets.symmetric(vertical: 14)
                      ),
                      onPressed: () async {
                        final result = await showDialog<record.Schedule>(context: context, builder: (_) => ScheduleDetailPage(date: day));
                        if (result != null) {
                          setModalState(() {
                            record.schedules.putIfAbsent(key, () => []).add(result);
                          });
                          setState(() {});
                          if (widget.onDayChanged != null) widget.onDayChanged!(_selectedDay, _focusedDay);
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
    return Container(
      padding: const EdgeInsets.all(16),
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
            headerVisible: false,
            rowHeight: 72,
            daysOfWeekHeight: 40,
            onPageChanged: (focusedDay) {
              setState(() => _focusedDay = focusedDay);
              if (widget.onDayChanged != null) widget.onDayChanged!(_selectedDay, _focusedDay);
            },
            onDaySelected: (selectedDay, focusedDay) {
              setState(() { _selectedDay = selectedDay; _focusedDay = focusedDay; });
              if (widget.onDayChanged != null) widget.onDayChanged!(_selectedDay, _focusedDay);
              _showScheduleListDialog(context, selectedDay);
            },
            calendarBuilders: CalendarBuilders(
              defaultBuilder: (context, day, _) => _buildDayCell(day),
              todayBuilder: (context, day, _) => _buildDayCell(day),
              selectedBuilder: (context, day, _) => _buildDayCell(day, isSelected: true),
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
        IconButton(
            icon: const Icon(Icons.chevron_left, color: Color(0xFF44403B)),
            onPressed: () => setState(() => _focusedDay = DateTime(_focusedDay.year, _focusedDay.month - 1))
        ),
        Expanded(
            child: Center(
                child: Text(
                    DateFormat('yyyy년 M월').format(_focusedDay),
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF44403B))
                )
            )
        ),
        IconButton(
            icon: const Icon(Icons.chevron_right, color: Color(0xFF44403B)),
            onPressed: () => setState(() => _focusedDay = DateTime(_focusedDay.year, _focusedDay.month + 1))
        ),
      ],
    );
  }
}