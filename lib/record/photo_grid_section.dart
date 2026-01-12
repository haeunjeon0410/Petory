import 'package:flutter/material.dart';
import 'dart:io';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import 'record_data.dart' as record;

class PhotoGridSection extends StatelessWidget {
  final String selectedPetName;
  final DateTime focusedDay;
  final VoidCallback onRefresh;

  const PhotoGridSection({
    super.key,
    required this.selectedPetName,
    required this.focusedDay,
    required this.onRefresh,
  });

  void _showDatePicker(BuildContext context, DateTime oldDate, String path) {
    DateTime tempPickedDate = oldDate;
    final pointColor = const Color(0xFF44403B);
    final backgroundColor = const Color(0xFFF1F2ED);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: backgroundColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
          titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
          title: Text('날짜 수정',
              style: TextStyle(color: pointColor, fontSize: 16, fontWeight: FontWeight.bold)),
          content: SizedBox(
            width: MediaQuery.of(context).size.width * 0.85,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 16),
                Container(
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
                  padding: const EdgeInsets.only(bottom: 8),
                  child: TableCalendar(
                    locale: 'ko_KR',
                    firstDay: DateTime.utc(2020, 1, 1),
                    lastDay: DateTime.utc(2035, 12, 31),
                    focusedDay: tempPickedDate,
                    selectedDayPredicate: (day) => isSameDay(tempPickedDate, day),
                    sixWeekMonthsEnforced: true, // ⭐ 높이 고정 설정 추가
                    headerStyle: HeaderStyle(
                      formatButtonVisible: false,
                      titleCentered: true,
                      titleTextStyle: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: pointColor),
                      leftChevronIcon: Icon(Icons.chevron_left, size: 20, color: pointColor),
                      rightChevronIcon: Icon(Icons.chevron_right, size: 20, color: pointColor),
                    ),
                    rowHeight: 48,
                    daysOfWeekHeight: 35,
                    calendarStyle: CalendarStyle(
                      selectedDecoration: BoxDecoration(color: pointColor, shape: BoxShape.circle),
                      cellMargin: const EdgeInsets.all(6),
                      selectedTextStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                      todayDecoration: BoxDecoration(color: pointColor.withOpacity(0.1), shape: BoxShape.circle),
                      todayTextStyle: TextStyle(color: pointColor, fontWeight: FontWeight.bold, fontSize: 13),
                      defaultTextStyle: const TextStyle(fontSize: 13, color: Color(0xFF44403B)),
                      weekendTextStyle: const TextStyle(fontSize: 13),
                      outsideDaysVisible: false,
                    ),
                    calendarBuilders: CalendarBuilders(
                      dowBuilder: (context, day) {
                        if (day.weekday == DateTime.sunday) return const Center(child: Text('일', style: TextStyle(color: Colors.red, fontSize: 13, fontWeight: FontWeight.w500)));
                        if (day.weekday == DateTime.saturday) return const Center(child: Text('토', style: TextStyle(color: Colors.blue, fontSize: 13, fontWeight: FontWeight.w500)));
                        return null;
                      },
                      defaultBuilder: (context, day, focusedDay) {
                        if (day.weekday == DateTime.sunday) return Center(child: Text('${day.day}', style: const TextStyle(color: Colors.red, fontSize: 13)));
                        if (day.weekday == DateTime.saturday) return Center(child: Text('${day.day}', style: const TextStyle(color: Colors.blue, fontSize: 13)));
                        return null;
                      },
                    ),
                    onDaySelected: (selectedDay, focusedDay) {
                      setDialogState(() => tempPickedDate = selectedDay);
                    },
                  ),
                ),
              ],
            ),
          ),
          actionsPadding: const EdgeInsets.fromLTRB(0, 0, 16, 16),
          actions: [
            _buildSmallButton(label: "취소", isPrimary: false, onTap: () => Navigator.pop(context)),
            _buildSmallButton(label: "변경", isPrimary: true, onTap: () {
              final newDate = record.normalizeDate(tempPickedDate);
              if (newDate != oldDate) {
                record.photos[selectedPetName]?[oldDate]?.remove(path);
                record.photos[selectedPetName]?.putIfAbsent(newDate, () => []).add(path);
                onRefresh();
              }
              Navigator.pop(context);
            }),
          ],
        ),
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, DateTime date, String path) {
    final pointColor = const Color(0xFF44403B);
    final backgroundColor = const Color(0xFFF1F2ED);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: backgroundColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
        titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
        title: Text('사진 삭제', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: pointColor)),
        content: const Text('정말 이 사진을 삭제할까요?', style: TextStyle(fontSize: 13, color: Color(0xFF605A55))),
        actionsPadding: const EdgeInsets.fromLTRB(0, 0, 16, 16),
        actions: [
          _buildSmallButton(label: "취소", isPrimary: false, onTap: () => Navigator.pop(context)),
          _buildSmallButton(label: "삭제", isPrimary: true, onTap: () {
            record.photos[selectedPetName]?[date]?.remove(path);
            onRefresh();
            Navigator.pop(context);
          }),
        ],
      ),
    );
  }

  Widget _buildSmallButton({required String label, required VoidCallback onTap, required bool isPrimary}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isPrimary ? const Color(0xFF44403B) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: isPrimary ? null : Border.all(color: const Color(0xFFE7E5E4)),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isPrimary ? Colors.white : const Color(0xFF605A55),
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (selectedPetName.isEmpty) return const SizedBox.shrink();

    List<MapEntry<DateTime, String>> monthPhotos = [];
    final petPhotos = record.photos[selectedPetName];
    final localFocusedDay = focusedDay.toLocal();

    if (petPhotos != null) {
      petPhotos.forEach((date, paths) {
        final localDate = date.toLocal();
        if (localDate.year == localFocusedDay.year && localDate.month == localFocusedDay.month) {
          for (var path in paths) {
            monthPhotos.add(MapEntry(date, path));
          }
        }
      });
    }

    monthPhotos.sort((a, b) => a.key.compareTo(b.key));

    if (monthPhotos.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 40),
          child: Text('이번 달에 등록된 사진이 없습니다.', style: TextStyle(color: Colors.grey, fontSize: 14)),
        ),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: monthPhotos.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 20,
        crossAxisSpacing: 20,
        childAspectRatio: 0.82,
      ),
      itemBuilder: (context, index) {
        final entry = monthPhotos[index];
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 12, offset: const Offset(0, 6))],
          ),
          child: Column(
            children: [
              Expanded(
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
                      child: Image.file(
                        File(entry.value), fit: BoxFit.cover, width: double.infinity, height: double.infinity,
                        errorBuilder: (context, error, stackTrace) => const Center(child: Icon(Icons.error_outline, color: Colors.red)),
                      ),
                    ),
                    Positioned(
                      top: 8, right: 8,
                      child: GestureDetector(
                        onTap: () => _showDeleteDialog(context, entry.key, entry.value),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(color: Colors.black.withOpacity(0.4), shape: BoxShape.circle),
                          child: const Icon(Icons.close, color: Colors.white, size: 16),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: GestureDetector(
                  onTap: () => _showDatePicker(context, entry.key, entry.value),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.calendar_today, size: 14, color: Color(0xFF44403B)),
                      const SizedBox(width: 6),
                      Text(
                        DateFormat('yyyy년 M월 d일').format(entry.key),
                        style: const TextStyle(fontSize: 12, color: Color(0xFF44403B), fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}