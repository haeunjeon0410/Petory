import 'dart:io';
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'schedule/schedule_detail_page.dart'; // 경로 확인 필요
import 'record_data.dart' as record;
import '../shared/app_dialog_style.dart';

class CalendarSection extends StatefulWidget {
  final String selectedPetName;
  final VoidCallback? onRefresh; // ⭐ 추가: 상위 위젯을 새로고침하기 위한 콜백
  final Function(DateTime selectedDay, DateTime focusedDay)? onDayChanged;
  final DateTime? selectedDay;
  final DateTime? focusedDay;

  const CalendarSection({
    super.key,
    required this.selectedPetName,
    this.onRefresh, // ⭐ 추가
    this.onDayChanged,
    this.selectedDay,
    this.focusedDay,
  });

  @override
  State<CalendarSection> createState() => _CalendarSectionState();
}

class _CalendarSectionState extends State<CalendarSection> {
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();

  @override
  void initState() {
    super.initState();
    if (widget.selectedDay != null) _selectedDay = widget.selectedDay!;
    if (widget.focusedDay != null) _focusedDay = widget.focusedDay!;
  }

  @override
  void didUpdateWidget(covariant CalendarSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    bool shouldUpdate = false;
    if (widget.selectedDay != null &&
        !isSameDay(_selectedDay, widget.selectedDay)) {
      _selectedDay = widget.selectedDay!;
      shouldUpdate = true;
    }
    if (widget.focusedDay != null &&
        !isSameDay(_focusedDay, widget.focusedDay)) {
      _focusedDay = widget.focusedDay!;
      shouldUpdate = true;
    }
    if (shouldUpdate) setState(() {});
  }

  List<record.Schedule> _getSortedSchedules(DateTime day) {
    if (widget.selectedPetName.isEmpty) return [];

    final key = record.normalizeDate(day);
    final petMap = record.petSchedules[widget.selectedPetName];
    if (petMap == null || petMap[key] == null) return [];

    final List<record.Schedule> list = List<record.Schedule>.from(petMap[key]!);
    list.sort((a, b) {
      if (a.time == null && b.time == null) return 0;
      if (a.time == null) return 1;
      if (b.time == null) return -1;
      return (a.time!.hour * 60 + a.time!.minute).compareTo(
        b.time!.hour * 60 + b.time!.minute,
      );
    });
    return list;
  }

  Widget _buildDayCell(
    DateTime day, {
    bool isSelected = false,
    Color? textColor,
  }) {
    final schedules = _getSortedSchedules(day);
    Color dayColor = day.weekday == DateTime.sunday
        ? Colors.red
        : (day.weekday == DateTime.saturday ? Colors.blue : Colors.black);
    if (textColor != null) dayColor = textColor;

    bool isToday = isSameDay(day, DateTime.now());

    return Container(
      alignment: Alignment.topCenter,
      child: Column(
        children: [
          const SizedBox(height: 10),
          Container(
            height: 28,
            width: 28,
            alignment: Alignment.center,
            decoration: isSelected
                ? const BoxDecoration(
                    color: Color(0xFF44403B),
                    shape: BoxShape.circle,
                  )
                : isToday
                ? BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFFF1F2ED),
                      width: 4.0,
                    ),
                  )
                : null,
            child: Text(
              '${day.day}',
              style: TextStyle(
                fontSize: 15,
                color: isSelected ? Colors.white : dayColor,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
          const SizedBox(height: 2),
          ...schedules
              .take(2)
              .map(
                (s) => Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 1,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: s.color,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 3),
                      Flexible(
                        child: Text(
                          s.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 10,
                            color: Color(0xFF44403B),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
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
            backgroundColor: AppDialogStyle.background,
            shape: AppDialogStyle.shape(),
            insetPadding: AppDialogStyle.insetPadding,
            child: Container(
              height: 500,
              padding: AppDialogStyle.contentPadding,
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${day.day}일 ${DateFormat('EEEE', 'ko_KR').format(day)}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF44403B),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: daySchedules.isEmpty
                        ? const Center(
                            child: Text(
                              '등록된 일정이 없습니다.',
                              style: TextStyle(color: Colors.grey),
                            ),
                          )
                        : ListView.builder(
                            itemCount: daySchedules.length,
                            itemBuilder: (context, index) {
                              final s = daySchedules[index];
                              return Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 4,
                                      height: 32,
                                      decoration: BoxDecoration(
                                        color: s.color,
                                        borderRadius: BorderRadius.circular(2),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            s.title,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: Color(0xFF44403B),
                                            ),
                                          ),
                                          if (s.content.isNotEmpty)
                                            Text(
                                              s.content,
                                              style: const TextStyle(
                                                fontSize: 13,
                                                color: Color(0xFF605A55),
                                              ),
                                            ),
                                          if (s.time != null)
                                            Text(
                                              s.time!.format(context),
                                              style: const TextStyle(
                                                fontSize: 11,
                                                color: Colors.grey,
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(
                                        Icons.edit_outlined,
                                        size: 20,
                                      ),
                                      onPressed: () async {
                                        final result =
                                            await showDialog<record.Schedule>(
                                              context: context,
                                              builder: (_) =>
                                                  ScheduleDetailPage(
                                                    date: day,
                                                    schedule: s,
                                                  ),
                                            );
                                        if (result != null) {
                                          setModalState(() {
                                            record.petSchedules[widget
                                                    .selectedPetName]![key]![index] =
                                                result;
                                          });
                                          setState(() {});
                                          // ⭐ 데이터 변경 알림
                                          widget.onRefresh?.call();
                                          if (widget.onDayChanged != null) {
                                            widget.onDayChanged!(
                                              _selectedDay,
                                              _focusedDay,
                                            );
                                          }
                                        }
                                      },
                                    ),
                                    IconButton(
                                      icon: const Icon(
                                        Icons.delete_outline,
                                        color: Colors.redAccent,
                                        size: 20,
                                      ),
                                      onPressed: () {
                                        setModalState(() {
                                          record
                                              .petSchedules[widget
                                                  .selectedPetName]![key]!
                                              .remove(s);
                                        });
                                        setState(() {});
                                        // ⭐ 데이터 변경 알림
                                        widget.onRefresh?.call();
                                        if (widget.onDayChanged != null) {
                                          widget.onDayChanged!(
                                            _selectedDay,
                                            _focusedDay,
                                          );
                                        }
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
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: () async {
                        final result = await showDialog<record.Schedule>(
                          context: context,
                          builder: (_) => ScheduleDetailPage(date: day),
                        );
                        if (result != null) {
                          setModalState(() {
                            record.petSchedules.putIfAbsent(
                              widget.selectedPetName,
                              () => {},
                            );
                            record.petSchedules[widget.selectedPetName]!
                                .putIfAbsent(key, () => [])
                                .add(result);
                          });
                          setState(() {});
                          // ⭐ 데이터 변경 알림 (빨간 점 갱신)
                          widget.onRefresh?.call();
                          if (widget.onDayChanged != null) {
                            widget.onDayChanged!(_selectedDay, _focusedDay);
                          }
                        }
                      },
                      child: const Text(
                        '일정 추가',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
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
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF44403B).withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          const double headerHeight = 36;
          const double daysOfWeekHeight = 32;
          final double availableHeight = constraints.maxHeight - headerHeight;
          final double rowHeight = ((availableHeight - daysOfWeekHeight) / 6)
              .clamp(50.0, 70.0);

          return Column(
            children: [
              SizedBox(height: headerHeight, child: _buildHeader()),
              TableCalendar(
                locale: 'ko_KR',
                firstDay: DateTime.utc(2020, 1, 1),
                lastDay: DateTime.utc(2035, 12, 31),
                focusedDay: _focusedDay,
                selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                headerVisible: false,
                rowHeight: rowHeight,
                daysOfWeekHeight: daysOfWeekHeight,
                sixWeekMonthsEnforced: true,
                availableGestures: AvailableGestures.horizontalSwipe,
                onPageChanged: (focusedDay) {
                  setState(() => _focusedDay = focusedDay);
                  if (widget.onDayChanged != null) {
                    widget.onDayChanged!(_selectedDay, _focusedDay);
                  }
                },
                onDaySelected: (selectedDay, focusedDay) {
                  setState(() {
                    _selectedDay = selectedDay;
                    _focusedDay = focusedDay;
                  });
                  if (widget.onDayChanged != null) {
                    widget.onDayChanged!(_selectedDay, _focusedDay);
                  }
                  _showScheduleListDialog(context, selectedDay);
                },
                calendarBuilders: CalendarBuilders(
                  defaultBuilder: (context, day, _) => _buildDayCell(day),
                  todayBuilder: (context, day, _) => _buildDayCell(day),
                  selectedBuilder: (context, day, _) =>
                      _buildDayCell(day, isSelected: true),
                  outsideBuilder: (context, day, _) => _buildDayCell(
                    day,
                    textColor: Colors.grey.withOpacity(0.5),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHeader() {
    const EdgeInsets iconPadding = EdgeInsets.all(4);
    const BoxConstraints iconConstraints = BoxConstraints.tightFor(
      width: 32,
      height: 32,
    );
    return Row(
      children: [
        IconButton(
          icon: const Icon(Icons.chevron_left, color: Color(0xFF44403B)),
          padding: iconPadding,
          constraints: iconConstraints,
          onPressed: () => setState(
            () =>
                _focusedDay = DateTime(_focusedDay.year, _focusedDay.month - 1),
          ),
        ),
        Expanded(
          child: Center(
            child: Text(
              DateFormat('yyyy년 M월').format(_focusedDay),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF44403B),
              ),
            ),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.chevron_right, color: Color(0xFF44403B)),
          padding: iconPadding,
          constraints: iconConstraints,
          onPressed: () => setState(
            () =>
                _focusedDay = DateTime(_focusedDay.year, _focusedDay.month + 1),
          ),
        ),
      ],
    );
  }
}

class _MonthlyAlbumDialog extends StatefulWidget {
  final String petId;
  final DateTime initialMonth;

  const _MonthlyAlbumDialog({required this.petId, required this.initialMonth});

  @override
  State<_MonthlyAlbumDialog> createState() => _MonthlyAlbumDialogState();
}

class _MonthlyAlbumDialogState extends State<_MonthlyAlbumDialog> {
  late DateTime _currentMonth;

  @override
  void initState() {
    super.initState();
    _currentMonth = DateTime(
      widget.initialMonth.year,
      widget.initialMonth.month,
    );
  }

  List<MapEntry<DateTime, String>> _getMonthPhotos() {
    final List<MapEntry<DateTime, String>> items = [];
    final petPhotos = record.photos[widget.petId];
    if (petPhotos == null) return items;

    petPhotos.forEach((date, paths) {
      if (date.year == _currentMonth.year &&
          date.month == _currentMonth.month) {
        for (final path in paths) {
          items.add(MapEntry(date, path));
        }
      }
    });
    items.sort((a, b) => a.key.compareTo(b.key));
    return items;
  }

  void _showPhotoPreview(String path) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.85),
      builder: (context) => GestureDetector(
        onTap: () => Navigator.pop(context),
        child: Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(12),
          child: Stack(
            children: [
              Center(
                child: InteractiveViewer(
                  child: Image.file(
                    File(path),
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) =>
                        const Icon(Icons.error_outline, color: Colors.white),
                  ),
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.4),
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final photos = _getMonthPhotos();
    const EdgeInsets iconPadding = EdgeInsets.all(4);
    const BoxConstraints iconConstraints = BoxConstraints.tightFor(
      width: 32,
      height: 32,
    );
    return Dialog(
      backgroundColor: AppDialogStyle.background,
      shape: AppDialogStyle.shape(),
      insetPadding: AppDialogStyle.insetPadding,
      child: Padding(
        padding: AppDialogStyle.contentPadding,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                IconButton(
                  icon: const Icon(
                    Icons.chevron_left,
                    color: Color(0xFF44403B),
                  ),
                  padding: iconPadding,
                  constraints: iconConstraints,
                  onPressed: () => setState(
                    () => _currentMonth = DateTime(
                      _currentMonth.year,
                      _currentMonth.month - 1,
                    ),
                  ),
                ),
                Expanded(
                  child: Center(
                    child: Text(
                      DateFormat('yyyy년 M월').format(_currentMonth),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF44403B),
                      ),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.chevron_right,
                    color: Color(0xFF44403B),
                  ),
                  padding: iconPadding,
                  constraints: iconConstraints,
                  onPressed: () => setState(
                    () => _currentMonth = DateTime(
                      _currentMonth.year,
                      _currentMonth.month + 1,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                IconButton(
                  icon: const Icon(Icons.close, color: Color(0xFF44403B)),
                  padding: iconPadding,
                  constraints: iconConstraints,
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (photos.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: Text(
                  '이번 달에 등록된 사진이 없습니다.',
                  style: TextStyle(color: Colors.black, fontSize: 14),
                ),
              )
            else
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.6,
                ),
                child: SingleChildScrollView(
                  child: GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: photos.length,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 18,
                          crossAxisSpacing: 18,
                          childAspectRatio: 1.0,
                        ),
                    itemBuilder: (context, index) {
                      final entry = photos[index];
                      return ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: GestureDetector(
                          onTap: () => _showPhotoPreview(entry.value),
                          child: Image.file(
                            File(entry.value),
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                Container(
                                  color: const Color(0xFFE7E5E4),
                                  alignment: Alignment.center,
                                  child: const Icon(
                                    Icons.error_outline,
                                    color: Colors.redAccent,
                                  ),
                                ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
