import 'package:flutter/material.dart';
import '../record/record_data.dart' as record;
import 'models/task_model.dart';
import 'utils/time_helper.dart';
import 'widgets/checklist_tile.dart';
import 'sheets/task_editor_sheet.dart';
import 'sheets/task_detail_dialog.dart';

class HomePage extends StatefulWidget {
  final VoidCallback? onRefresh;

  const HomePage({super.key, this.onRefresh});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedPetIndex = 0;
  // 날짜 스와이프용 상태
  final int _initialDatePage = 10000;
  // HomePageState 클래스 상단
  final PageController _dateController = PageController(
    initialPage: 10000,
    viewportFraction: 1 / 3, // 0.33보다 더 정확하게 3등분을 해줍니다!
  );
  DateTime _selectedDate = DateTime.now();
  // helper: page -> date
  DateTime _dateForPage(int page) =>
      DateTime.now().add(Duration(days: page - _initialDatePage));

  bool _isSameDate(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  @override
  void initState() {
    super.initState();
    // 초기화 시 record에 선택된 ID가 있다면 인덱스 동기화
    if (record.myPetIds.isNotEmpty && record.selectedPetId.isNotEmpty) {
      int idx = record.myPetIds.indexOf(record.selectedPetId);
      if (idx != -1) _selectedPetIndex = idx;
    }
  }

  @override
  void dispose() {
    _dateController.dispose();
    super.dispose();
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
        insetPadding: const EdgeInsets.symmetric(horizontal: 20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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

        if (record.petChecklists[petId] == null) {
          record.petChecklists[petId] = [];
        }

        if (editIndex != null) {
          record.petChecklists[petId]![editIndex] = taskMap;
        } else {
          record.petChecklists[petId]!.add(taskMap);
        }
      });
    }
  }

  void _showDetailDialog(Task task) {
    showDialog(
      context: context,
      builder: (context) => TaskDetailDialog(task: task),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool hasPet = record.myPetIds.isNotEmpty;

    if (hasPet && record.selectedPetId.isNotEmpty) {
      int idx = record.myPetIds.indexOf(record.selectedPetId);
      if (idx != -1) {
        _selectedPetIndex = idx;
      }
    }

    String? currentId;
    if (hasPet) {
      if (_selectedPetIndex >= record.myPetIds.length) _selectedPetIndex = 0;
      currentId = record.myPetIds[_selectedPetIndex];
    }

    List<Task> currentTasks = [];

    if (hasPet && currentId != null) {
      var cList = record.petChecklists[currentId];
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
      backgroundColor: const Color(0xFF92C6D1),
      body: SingleChildScrollView(
        padding: EdgeInsets.zero,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDatePicker(),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ... checklist UI ...
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Today's Checklist",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF44403B),
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          if (hasPet && currentId != null) {
                            _openTaskSheet(currentId);
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("Please register a pet first."),
                              ),
                            );
                          }
                        },
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
                              onToggle: () {
                                setState(() {
                                  record.petChecklists[currentId]![index]['isDone'] =
                                      !task.isDone;
                                });
                              },
                              onTap: () => _showDetailDialog(task),
                              onEdit: () => _openTaskSheet(
                                currentId!,
                                editIndex: index,
                                existingTask: task,
                              ),
                              onDelete: () {
                                setState(() {
                                  record.petChecklists[currentId]!.removeAt(
                                    index,
                                  );
                                });
                              },
                            );
                          },
                        ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDatePicker() {
    final List<String> weekdays = ["", "월", "화", "수", "목", "금", "토", "일"];

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: SizedBox(
        height: 50,
        child: PageView.builder(
          controller: _dateController,
          clipBehavior: Clip.hardEdge, // 양옆 날짜가 잘리지 않고 부드럽게 보이게 합니다.
          onPageChanged: (idx) {
            setState(() {
              _selectedDate = _dateForPage(idx);
            });
          },
          itemBuilder: (context, index) {
            final date = _dateForPage(index);
            final isSelected = _isSameDate(date, _selectedDate);
            final isToday = _isSameDate(date, DateTime.now());
            final dateLabel = "${date.month}.${date.day}";
            final weekdayLabel = weekdays[date.weekday];

            return Center(
              // 이 Center가 1/3 등분된 영역의 정중앙에 내용을 배치합니다.
              child: GestureDetector(
                onTap: () {
                  _dateController.animateToPage(
                    index,
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeInOut,
                  );
                },
                child: Opacity(
                  opacity: isSelected
                      ? 1.0
                      : 0.4, // 선택 안 된 날짜는 조금 더 흐리게 조절 가능해요.
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        dateLabel,
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
                          padding: EdgeInsets.symmetric(
                            horizontal: isToday ? 10 : 6,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black,
                            borderRadius: BorderRadius.circular(
                              isToday ? 20 : 50,
                            ),
                          ),
                          child: Text(
                            isToday ? "오늘" : weekdayLabel,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        )
                      else
                        Text(
                          weekdayLabel,
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

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Text(
          "No schedules yet.\nTap (+) to add one.",
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey[400], fontSize: 14),
        ),
      ),
    );
  }
}
