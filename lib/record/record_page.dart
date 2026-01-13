import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'record_data.dart' as record;
import 'photo_grid_section.dart';
import 'calendar_section.dart';
import '../home/models/task_model.dart';
import '../home/utils/time_helper.dart';
import '../home/widgets/checklist_tile.dart';
import '../home/sheets/task_editor_sheet.dart';
import '../home/sheets/task_detail_dialog.dart';

class RecordPage extends StatefulWidget {
  final VoidCallback? onRefresh;
  const RecordPage({super.key, this.onRefresh});

  @override
  State<RecordPage> createState() => _RecordPageState();
}

class _RecordPageState extends State<RecordPage> {
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();

  final int _initialDatePage = 10000;
  late PageController _dateController;
  DateTime _selectedDate = DateTime.now();

  // 하은이가 픽한 메인 배경색
  final Color _bgColor = const Color(0xFFF2A783);
  // 토글바에 다시 적용할 진한 오렌지색
  final Color _toggleColor = const Color(0xFFDA6330);

  @override
  void initState() {
    super.initState();
    _dateController = PageController(
      initialPage: _initialDatePage,
      viewportFraction: 0.35,
    );
  }

  @override
  void dispose() {
    _dateController.dispose();
    super.dispose();
  }

  DateTime _dateForPage(int page) =>
      DateTime.now().add(Duration(days: page - _initialDatePage));

  bool _isSameDate(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  void _syncSelectedDate(DateTime date) {
    setState(() {
      _selectedDate = date;
      _selectedDay = date;
      _focusedDay = date;
    });
  }

  void _showCalendarDialog(String petId) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.white,
        insetPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 340),
          child: SingleChildScrollView(
            child: CalendarSection(
              selectedPetName: petId,
              onRefresh: widget.onRefresh,
              onDayChanged: (selectedDay, focusedDay) {
                setState(() {
                  _selectedDay = selectedDay;
                  _focusedDay = focusedDay;
                });
              },
            ),
          ),
        ),
      ),
    );
  }

  void _showAlbumDialog(String petId) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: const Color(0xFFF1F2ED),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Container(
          height: MediaQuery.of(context).size.height * 0.7,
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "앨범",
                    style: TextStyle(
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
              const SizedBox(height: 10),
              Expanded(
                child: SingleChildScrollView(
                  child: PhotoGridSection(
                    selectedPetName: petId,
                    focusedDay: _selectedDate,
                    onRefresh: () => setState(() {}),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openTaskSheet(
    String petId, {
    int? editIndex,
    Task? existingTask,
  }) async {
    final Task? result = await showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: TaskEditorSheet(existingTask: existingTask),
      ),
    );

    if (result != null) {
      setState(() {
        Map<String, dynamic> taskMap = {
          "title": result.title,
          "time": result.time,
          "icon": result.icon,
          "isDone": result.isDone,
        };
        if (record.petChecklists[petId] == null)
          record.petChecklists[petId] = [];
        if (editIndex != null) {
          record.petChecklists[petId]![editIndex] = taskMap;
        } else {
          record.petChecklists[petId]!.add(taskMap);
        }
      });
      if (widget.onRefresh != null) widget.onRefresh!();
    }
  }

  // 흰색 박스 느낌을 줄이기 위해 다시 색상을 진하게 바꾼 토글 버튼
  Widget _buildToggleButtons(String petId) {
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 20),
        height: 44,
        width: MediaQuery.of(context).size.width * 0.8,
        decoration: BoxDecoration(
          color: _toggleColor, // 진한 오렌지색으로 복구
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () => _showCalendarDialog(petId),
                behavior: HitTestBehavior.opaque,
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text("🍎", style: TextStyle(fontSize: 14)),
                    SizedBox(width: 8),
                    Text(
                      "캘린더",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Container(width: 1, height: 16, color: Colors.white38),
            Expanded(
              child: GestureDetector(
                onTap: () => _showAlbumDialog(petId),
                behavior: HitTestBehavior.opaque,
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text("🖼️", style: TextStyle(fontSize: 14)),
                    SizedBox(width: 8),
                    Text(
                      "앨범",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 원래 위치와 스타일로 복구된 날짜 선택 바
  Widget _buildDatePicker() {
    final List<String> weekdays = ["", "월", "화", "수", "목", "금", "토", "일"];
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: SizedBox(
        height: 30,
        child: PageView.builder(
          controller: _dateController,
          onPageChanged: (idx) {
            _syncSelectedDate(_dateForPage(idx));
          },
          itemBuilder: (context, index) {
            final date = _dateForPage(index);
            final isSelected = _isSameDate(date, _selectedDate);
            final isToday = _isSameDate(date, DateTime.now());
            return Center(
              child: GestureDetector(
                onTap: () => _dateController.animateToPage(
                  index,
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeInOut,
                ),
                child: Opacity(
                  opacity: isSelected ? 1.0 : 0.4,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        "${date.month}.${date.day}",
                        style: TextStyle(
                          fontSize: isSelected ? 22 : 18,
                          fontWeight: isSelected
                              ? FontWeight.w900
                              : FontWeight.w500,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(width: 4),
                      if (isSelected)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black,
                            borderRadius: BorderRadius.circular(
                              isToday ? 20 : 50,
                            ),
                          ),
                          child: Text(
                            isToday ? "오늘" : weekdays[date.weekday],
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        )
                      else
                        Text(
                          weekdays[date.weekday],
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.black,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    String currentPetId = record.selectedPetId;
    if ((currentPetId.isEmpty || !record.myPetIds.contains(currentPetId)) &&
        record.myPetIds.isNotEmpty) {
      currentPetId = record.myPetIds[0];
      record.selectedPetId = currentPetId;
    }

    List<Task> currentTasks = [];
    if (currentPetId.isNotEmpty) {
      var cList = record.petChecklists[currentPetId];
      if (cList != null) {
        currentTasks = cList
            .map(
              (t) => Task(
                title: t['title'],
                time: t['time'],
                icon: t['icon'].toString(),
                isDone: t['isDone'],
              ),
            )
            .toList();
      }
      currentTasks.sort(
        (a, b) => TimeHelper.parseTimeToMinutes(
          a.time,
        ).compareTo(TimeHelper.parseTimeToMinutes(b.time)),
      );
    }

    return Scaffold(
      backgroundColor: _bgColor, // 하은이가 원한 배경색
      body: Column(
        children: [
          _buildDatePicker(), // 위치 복구됨!
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildToggleButtons(currentPetId),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "??",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF44403B),
                        ),
                      ),
                      GestureDetector(
                        onTap: () => currentPetId.isNotEmpty
                            ? _openTaskSheet(currentPetId)
                            : null,
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: const Color(0xFF44403B),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(
                            Icons.add,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),
                  currentTasks.isEmpty
                      ? _buildEmptyState()
                      : ListView.separated(
                          physics: const NeverScrollableScrollPhysics(),
                          shrinkWrap: true,
                          itemCount: currentTasks.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final task = currentTasks[index];
                            return CheckListTile(
                              task: task,
                              onToggle: () => setState(
                                () =>
                                    record.petChecklists[currentPetId]![index]['isDone'] =
                                        !task.isDone,
                              ),
                              onTap: () => showDialog(
                                context: context,
                                builder: (context) =>
                                    TaskDetailDialog(task: task),
                              ),
                              onEdit: () => _openTaskSheet(
                                currentPetId,
                                editIndex: index,
                                existingTask: task,
                              ),
                              onDelete: () => setState(
                                () => record.petChecklists[currentPetId]!
                                    .removeAt(index),
                              ),
                            );
                          },
                        ),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final ImagePicker picker = ImagePicker();
          final XFile? image = await picker.pickImage(
            source: ImageSource.gallery,
          );
          if (image != null) {
            final key = record.normalizeDate(_selectedDate);
            setState(() {
              record.photos.putIfAbsent(currentPetId, () => {});
              record.photos[currentPetId]!
                  .putIfAbsent(key, () => [])
                  .add(image.path);
            });
          }
        },
        backgroundColor: const Color(0xFF44403B),
        child: const Icon(Icons.camera_alt, color: Colors.white),
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 20),
        child: Text(
          "아직 일정이 없어요.\n(+)를 눌러 추가해보세요!",
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white,
            fontSize: 14,
          ), // 가독성을 위해 흰색으로 수정
        ),
      ),
    );
  }
}
