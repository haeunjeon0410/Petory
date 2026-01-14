import 'package:flutter/material.dart';
import 'dart:io';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import 'record_data.dart' as record;
import '../shared/app_dialog_style.dart';

class PhotoGridSection extends StatelessWidget {
  final String selectedPetName; // record.photos의 Key로 사용되는 ID/이름
  final DateTime focusedDay;
  final DateTime selectedDay;
  final VoidCallback onRefresh;

  const PhotoGridSection({
    super.key,
    required this.selectedPetName,
    required this.focusedDay,
    required this.selectedDay,
    required this.onRefresh,
  });

  // [수정] 날짜 수정 로직: 이전 날짜 리스트에서 제거 후 새로운 날짜 리스트에 추가
  void _showDatePicker(BuildContext context, DateTime oldDate, String path) {
    DateTime tempPickedDate = oldDate;
    final pointColor = AppDialogStyle.text;
    final backgroundColor = AppDialogStyle.background;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: backgroundColor,
          shape: AppDialogStyle.shape(),
          insetPadding: AppDialogStyle.insetPadding,
          titlePadding: AppDialogStyle.titlePadding,
          title: Text(
            '날짜 수정',
            style: TextStyle(
              color: pointColor,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: SizedBox(
            width: MediaQuery.of(context).size.width * 0.85,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 16),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  padding: const EdgeInsets.only(bottom: 8),
                  child: TableCalendar(
                    locale: 'ko_KR',
                    firstDay: DateTime.utc(2020, 1, 1),
                    lastDay: DateTime.now(),
                    focusedDay: tempPickedDate,
                    selectedDayPredicate: (day) =>
                        isSameDay(tempPickedDate, day),
                    sixWeekMonthsEnforced: true,
                    headerStyle: HeaderStyle(
                      formatButtonVisible: false,
                      titleCentered: true,
                      titleTextStyle: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: pointColor,
                      ),
                      leftChevronIcon: Icon(
                        Icons.chevron_left,
                        size: 20,
                        color: pointColor,
                      ),
                      rightChevronIcon: Icon(
                        Icons.chevron_right,
                        size: 20,
                        color: pointColor,
                      ),
                    ),
                    calendarStyle: CalendarStyle(
                      selectedDecoration: BoxDecoration(
                        color: pointColor,
                        shape: BoxShape.circle,
                      ),
                      todayDecoration: BoxDecoration(
                        color: pointColor.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      defaultTextStyle: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF44403B),
                      ),
                    ),
                    onDaySelected: (selectedDay, focusedDay) {
                      setDialogState(() => tempPickedDate = selectedDay);
                    },
                  ),
                ),
              ],
            ),
          ),
          actionsPadding: AppDialogStyle.actionsPadding,
          actions: [
            _buildSmallButton(
              label: "취소",
              isPrimary: false,
              onTap: () => Navigator.pop(context),
            ),
            _buildSmallButton(
              label: "변경",
              isPrimary: true,
              onTap: () {
                final newDate = record.normalizeDate(tempPickedDate);
                final normalizedOldDate = record.normalizeDate(oldDate);

                if (newDate != normalizedOldDate) {
                  // 1. 기존 날짜에서 제거
                  record.photos[selectedPetName]?[normalizedOldDate]?.remove(
                    path,
                  );
                  // 2. 새 날짜에 추가
                  record.photos[selectedPetName] ??= {};
                  record.photos[selectedPetName]!
                      .putIfAbsent(newDate, () => [])
                      .add(path);

                  record.saveToStorage(); // 데이터 영구 저장
                  onRefresh(); // 메인 UI 갱신
                }
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  // [수정] 사진 삭제 로직
  void _showDeleteDialog(BuildContext context, DateTime date, String path) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppDialogStyle.background,
        shape: AppDialogStyle.shape(),
        title: const Text(
          '사진 삭제',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        content: const Text('정말 이 사진을 삭제할까요?'),
        actions: [
          _buildSmallButton(
            label: "취소",
            isPrimary: false,
            onTap: () => Navigator.pop(context),
          ),
          _buildSmallButton(
            label: "삭제",
            isPrimary: true,
            onTap: () {
              final normalizedDate = record.normalizeDate(date);
              record.photos[selectedPetName]?[normalizedDate]?.remove(path);

              record.saveToStorage(); // 저장
              onRefresh(); // 갱신
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  void _showPhotoPreview(BuildContext context, String path) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.85),
      builder: (context) => GestureDetector(
        onTap: () => Navigator.pop(context),
        child: Dialog(
          backgroundColor: Colors.transparent,
          child: InteractiveViewer(
            child: Image.file(File(path), fit: BoxFit.contain),
          ),
        ),
      ),
    );
  }

  Widget _buildSmallButton({
    required String label,
    required VoidCallback onTap,
    required bool isPrimary,
  }) {
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
            color: isPrimary ? Colors.white : Colors.black,
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
        if (date.year == localFocusedDay.year &&
            date.month == localFocusedDay.month) {
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
          child: Text('이번 달 사진이 없습니다.'),
        ),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: monthPhotos.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
      ),
      itemBuilder: (context, index) {
        final entry = monthPhotos[index];
        return ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            children: [
              Positioned.fill(
                child: GestureDetector(
                  onTap: () => _showPhotoPreview(context, entry.value),
                  child: Image.file(File(entry.value), fit: BoxFit.cover),
                ),
              ),
              // 상단 그라데이션 (텍스트 가독성)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: 40,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withOpacity(0.5),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
              // 날짜 클릭 시 수정
              Positioned(
                top: 8,
                left: 10,
                child: GestureDetector(
                  onTap: () => _showDatePicker(context, entry.key, entry.value),
                  child: Text(
                    DateFormat('MM.dd').format(entry.key),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              // X 버튼 클릭 시 삭제
              Positioned(
                top: 5,
                right: 5,
                child: GestureDetector(
                  onTap: () =>
                      _showDeleteDialog(context, entry.key, entry.value),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.3),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 14,
                    ),
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
