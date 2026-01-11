import 'package:flutter/material.dart';
import 'dart:io';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart'; // ⭐ 일관성을 위해 TableCalendar 사용
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

  // ⭐ 하은아, 여기 디자인을 완전히 바꾼 컴팩트한 날짜 선택 창이야!
  void _showDatePicker(BuildContext context, DateTime oldDate, String path) {
    DateTime tempPickedDate = oldDate;
    final pointColor = const Color(0xFF44403B);
    final backgroundColor = const Color(0xFFF1F2ED);

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              backgroundColor: backgroundColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              child: Container(
                width: MediaQuery.of(context).size.width * 0.85, // 너비 조절
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. 헤더: 제목 왼쪽 정렬
                    Text(
                      '날짜 수정',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: pointColor,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // 2. 컴팩트 캘린더 (기존 미감 유지)
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      padding: const EdgeInsets.only(bottom: 8),
                      child: TableCalendar(
                        locale: 'ko_KR',
                        firstDay: DateTime.utc(2020, 1, 1),
                        lastDay: DateTime.utc(2035, 12, 31),
                        focusedDay: tempPickedDate,
                        currentDay: DateTime.now(),
                        selectedDayPredicate: (day) => isSameDay(tempPickedDate, day),
                        headerStyle: HeaderStyle(
                          formatButtonVisible: false,
                          titleCentered: true,
                          titleTextStyle: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: pointColor),
                          leftChevronIcon: Icon(Icons.chevron_left, size: 20, color: pointColor),
                          rightChevronIcon: Icon(Icons.chevron_right, size: 20, color: pointColor),
                          headerPadding: const EdgeInsets.symmetric(vertical: 8),
                        ),
                        // ⭐ 사이즈를 줄이기 위해 높이 조절
                        rowHeight: 40,
                        daysOfWeekHeight: 25,
                        calendarStyle: CalendarStyle(
                          todayDecoration: BoxDecoration(color: pointColor.withOpacity(0.1), shape: BoxShape.circle),
                          todayTextStyle: TextStyle(color: pointColor, fontWeight: FontWeight.bold),
                          selectedDecoration: BoxDecoration(color: pointColor, shape: BoxShape.circle),
                          defaultTextStyle: const TextStyle(fontSize: 13),
                          weekendTextStyle: const TextStyle(fontSize: 13, color: Colors.red),
                        ),
                        onDaySelected: (selectedDay, focusedDay) {
                          setDialogState(() => tempPickedDate = selectedDay);
                        },
                      ),
                    ),
                    const SizedBox(height: 24),

                    // 3. 하단 버튼 영역 (우측 정렬)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        // 취소 버튼
                        ElevatedButton(
                          onPressed: () => Navigator.pop(context),
                          style: ElevatedButton.styleFrom(
                            elevation: 0,
                            backgroundColor: Colors.white,
                            foregroundColor: pointColor,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(color: pointColor.withOpacity(0.1)),
                            ),
                          ),
                          child: const Text('취소', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                        const SizedBox(width: 8),
                        // 변경 버튼
                        ElevatedButton(
                          onPressed: () {
                            final newDate = record.normalizeDate(tempPickedDate);
                            if (newDate != oldDate) {
                              record.photos[selectedPetName]?[oldDate]?.remove(path);
                              record.photos[selectedPetName]?.putIfAbsent(newDate, () => []).add(path);
                              onRefresh();
                            }
                            Navigator.pop(context);
                          },
                          style: ElevatedButton.styleFrom(
                            elevation: 0,
                            backgroundColor: pointColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text('변경', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ],
                    )
                  ],
                ),
              ),
            );
          }
      ),
    );
  }

  // 삭제 다이얼로그 (이전과 동일한 스타일 유지)
  void _showDeleteDialog(BuildContext context, DateTime date, String path) {
    final pointColor = const Color(0xFF44403B);
    final backgroundColor = const Color(0xFFF1F2ED);

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: backgroundColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Container(
          width: MediaQuery.of(context).size.width * 0.8,
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('사진 삭제', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: pointColor)),
              const SizedBox(height: 20),
              const Text('정말 이 사진을 삭제할까요?', style: TextStyle(fontSize: 15, color: Color(0xFF605A55))),
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      elevation: 0, shadowColor: Colors.transparent,
                      backgroundColor: Colors.white, foregroundColor: pointColor,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: pointColor.withOpacity(0.1))),
                    ),
                    child: const Text('취소', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () {
                      record.photos[selectedPetName]?[date]?.remove(path);
                      onRefresh();
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      elevation: 0, shadowColor: Colors.transparent,
                      backgroundColor: pointColor, foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('삭제', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ],
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