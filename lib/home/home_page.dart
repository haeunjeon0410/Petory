import 'dart:io';
import 'package:flutter/material.dart';
import '../record/record_data.dart' as record;

// V2 모델 및 위젯 import
import 'models/pet_model.dart';
import 'models/task_model.dart';
import 'utils/time_helper.dart';
import 'widgets/checklist_tile.dart';
import 'sheets/pet_register_sheet.dart';
import 'sheets/task_editor_sheet.dart';
import 'sheets/task_detail_dialog.dart';
import '../shared/app_dialog_style.dart';

class HomePage extends StatefulWidget {
  final VoidCallback? onRefresh;
  const HomePage({super.key, this.onRefresh});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // [V1] 날짜 선택기 관련 State
  final int _initialDatePage = 10000;
  late final PageController _dateController;
  DateTime _selectedDate = DateTime.now();

  // [V2] 펫 및 기능 관련 State
  int _selectedPetIndex = 0;

  @override
  void initState() {
    super.initState();
    _dateController = PageController(
      initialPage: _initialDatePage,
      viewportFraction: 0.35,
    );

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

  // [V1] 날짜 헬퍼 메서드
  DateTime _dateForPage(int page) =>
      DateTime.now().add(Duration(days: page - _initialDatePage));

  bool _isSameDate(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  // ------------------------------------------------------------------------
  // [V2] 기능 로직 (등록, 삭제, 체크리스트 관리)
  // ------------------------------------------------------------------------

  void _openRegisterSheet({Pet? existingPet}) async {
    final Pet? result = await showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: AppDialogStyle.insetPadding,
        shape: AppDialogStyle.shape(),
        child: PetRegisterSheet(existingPet: existingPet),
      ),
    );

    if (result != null) {
      setState(() {
        String? imagePath;
        if (result.imageFile != null) {
          imagePath = result.imageFile!.path;
        } else {
          imagePath = result.imageAsset;
        }

        if (existingPet != null) {
          // 수정
          String currentId = record.myPetIds[_selectedPetIndex];
          record.petProfiles[currentId] = {
            "name": result.name,
            "type": result.type,
            "species": result.species,
            "age": result.age,
            "height": result.height,
            "weight": result.weight,
            "gender": result.gender,
            "isNeutered": result.isNeutered,
            "imagePath": imagePath,
          };
          // 체중 기록 업데이트 로직 유지 (생략 가능하나 기능 유지를 위해 포함)
          double? newWeight = double.tryParse(result.weight);
          if (newWeight != null) {
            if (record.weightHistory[currentId] == null) {
              record.weightHistory[currentId] = [];
            }
            List<Map<String, dynamic>> history =
                record.weightHistory[currentId]!;
            DateTime now = DateTime.now();
            history.removeWhere((h) {
              DateTime d = h['date'];
              return d.year == now.year &&
                  d.month == now.month &&
                  d.day == now.day;
            });
            history.add({"date": DateTime.now(), "weight": newWeight});
          }
        } else {
          // 추가
          String newId = DateTime.now().millisecondsSinceEpoch.toString();
          record.myPetIds.add(newId);
          record.petProfiles[newId] = {
            "name": result.name,
            "type": result.type,
            "species": result.species,
            "age": result.age,
            "height": result.height,
            "weight": result.weight,
            "gender": result.gender,
            "isNeutered": result.isNeutered,
            "imagePath": imagePath,
          };
          record.petChecklists[newId] = {};
          _selectedPetIndex = record.myPetIds.length - 1;
          record.selectedPetId = newId;
        }
      });
      widget.onRefresh?.call();
    }
  }

  void _deletePet(String petId, String petName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppDialogStyle.background,
        shape: AppDialogStyle.shape(),
        insetPadding: AppDialogStyle.insetPadding,
        title: const Text(
          "반려동물 삭제",
          style: TextStyle(color: AppDialogStyle.text),
        ),
        content: Text(
          "'$petName' 프로필을 삭제하시겠습니까?",
          style: const TextStyle(color: AppDialogStyle.mutedText),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              "취소",
              style: TextStyle(color: AppDialogStyle.mutedText),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                record.myPetIds.remove(petId);
                record.petProfiles.remove(petId);
                record.petChecklists.remove(petId);
                if (_selectedPetIndex >= record.myPetIds.length) {
                  _selectedPetIndex = record.myPetIds.length - 1;
                }
                if (_selectedPetIndex < 0) _selectedPetIndex = 0;
                record.selectedPetId = record.myPetIds.isNotEmpty
                    ? record.myPetIds[_selectedPetIndex]
                    : "";
              });
              widget.onRefresh?.call();
            },
            child: const Text(
              "삭제",
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  void _openTaskSheet(
    String petId,
    DateTime dateKey, {
    int? editIndex,
    Task? existingTask,
  }) async {
    final Task? result = await showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: AppDialogStyle.insetPadding,
        shape: AppDialogStyle.shape(),
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
        record.petChecklists.putIfAbsent(petId, () => {});
        record.petChecklists[petId]!.putIfAbsent(dateKey, () => []);
        if (editIndex != null) {
          record.petChecklists[petId]![dateKey]![editIndex] = taskMap;
        } else {
          record.petChecklists[petId]![dateKey]!.add(taskMap);
        }
      });
      widget.onRefresh?.call();
    }
  }

  void _showDetailDialog(Task task) {
    showDialog(
      context: context,
      builder: (context) => TaskDetailDialog(task: task),
    );
  }

  // ------------------------------------------------------------------------
  // [Main Build] UI 구성
  // ------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final bool hasPet = record.myPetIds.isNotEmpty;

    // ID 동기화
    if (hasPet && record.selectedPetId.isNotEmpty) {
      int idx = record.myPetIds.indexOf(record.selectedPetId);
      if (idx != -1) _selectedPetIndex = idx;
    }

    String? currentId;
    if (hasPet) {
      if (_selectedPetIndex >= record.myPetIds.length) _selectedPetIndex = 0;
      currentId = record.myPetIds[_selectedPetIndex];
    }

    final DateTime dateKey = record.normalizeDate(_selectedDate);

    // 데이터 로드
    Pet? currentPet;
    List<Task> currentTasks = [];
    int foodAmount = 0;

    if (hasPet && currentId != null) {
      var pData = record.petProfiles[currentId];
      if (pData != null) {
        // 이미지 경로 처리
        String? imgPath = pData['imagePath'];
        File? imgFile;
        String? imgAsset;
        if (imgPath != null && !imgPath.startsWith('assets')) {
          imgFile = File(imgPath);
        } else {
          imgAsset = imgPath ?? "assets/images/golden.jpg";
        }

        currentPet = Pet(
          name: pData['name'] ?? '',
          type: pData['type'] ?? '강아지',
          species: pData['species'] ?? '',
          age: pData['age'] ?? '',
          height: pData['height'] ?? '',
          weight: pData['weight'] ?? '',
          gender: pData['gender'] ?? 'male',
          isNeutered: pData['isNeutered'] ?? false,
          imageFile: imgFile,
          imageAsset: imgAsset,
        );

        // 사료량 계산 (record_data에 함수가 있다고 가정하거나 로컬 로직 사용)
        // 만약 record.calculateDailyFood가 없다면 0으로 처리됩니다.
        try {
          foodAmount = record.calculateDailyFood(pData, activityLevel: '보통');
        } catch (e) {
          foodAmount = 0;
        }
      }

      var dateMap = record.petChecklists[currentId];
      final cList = dateMap?[dateKey];
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

    // 완료율 계산
    int totalCount = currentTasks.length;
    int doneCount = currentTasks.where((t) => t.isDone).length;
    int completionRate = totalCount == 0
        ? 0
        : ((doneCount / totalCount) * 100).round();

    return Scaffold(
      backgroundColor: const Color(0xFF92C6D1), // [V1] 하늘색 배경
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // 1. 날짜 선택기 (V1 스타일)
            _buildDatePicker(),

            const SizedBox(height: 10),

            // 3. 프로필 정보 (V1 디자인: 이름 -> 아바타 -> 메트릭)
            if (currentPet != null) ...[
              // 이름
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    currentPet.name,
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  // 삭제 버튼 (V2 기능 - 작게 추가)
                  IconButton(
                    icon: const Icon(
                      Icons.delete_outline,
                      color: Colors.white70,
                      size: 20,
                    ),
                    onPressed: () => _deletePet(currentId!, currentPet!.name),
                  ),
                ],
              ),
              const SizedBox(height: 15),

              // 아바타 (터치 시 수정 V2 기능 연결)
              GestureDetector(
                onTap: () => _openRegisterSheet(existingPet: currentPet),
                child: Container(
                  width: 180,
                  height: 180,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                    border: Border.all(color: Colors.white, width: 4),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: ClipOval(child: _buildProfileImage(currentPet)),
                ),
              ),
              const SizedBox(height: 40),

              // 지표 섹션 (V1 디자인)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildMetricItem(
                      "식사량",
                      "$foodAmount g",
                      Colors.white,
                      const Color(0xFF92C6D1),
                    ),
                    _buildMetricItem(
                      "달성도",
                      "중간", // 추후 로직 추가 가능
                      const Color(0xFFFFF59D),
                      Colors.black87,
                    ),
                    _buildMetricItem(
                      "건강검진",
                      "D-10", // 추후 로직 추가 가능
                      const Color(0xFF2D4464),
                      Colors.white,
                    ),
                  ],
                ),
              ),
            ] else ...[
              // 펫 없음 상태
              const SizedBox(height: 60),
              GestureDetector(
                onTap: () => _openRegisterSheet(),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.3),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.add,
                        size: 40,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      "반려동물을 등록해주세요!",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
            ],

            const SizedBox(height: 40),

            // 4. 체크리스트 섹션 (V2 기능 + 하단 배치)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: Color(0xFFF1F2ED), // V2의 베이지 배경
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(30),
                  topRight: Radius.circular(30),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Text(
                            "오늘의 체크리스트",
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF44403B),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            "$completionRate%",
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2196F3),
                            ),
                          ),
                        ],
                      ),
                      GestureDetector(
                        onTap: () {
                          if (hasPet && currentId != null) {
                            _openTaskSheet(currentId, dateKey);
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("반려동물을 먼저 등록해주세요! 🐾"),
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
                  const SizedBox(height: 20),

                  // 체크리스트 리스트뷰
                  currentTasks.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 40),
                            child: Text(
                              "등록된 일정이 없습니다.\n(+) 버튼을 눌러 추가해주세요.",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.grey[400],
                                fontSize: 14,
                              ),
                            ),
                          ),
                        )
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
                                  record
                                      .petChecklists[currentId]![dateKey]![index]['isDone'] =
                                      !task.isDone;
                                });
                                widget.onRefresh?.call();
                              },
                              onTap: () => _showDetailDialog(task),
                              onEdit: () => _openTaskSheet(
                                currentId!,
                                dateKey,
                                editIndex: index,
                                existingTask: task,
                              ),
                              onDelete: () {
                                setState(() {
                                  record.petChecklists[currentId]![dateKey]!
                                      .removeAt(index);
                                });
                                widget.onRefresh?.call();
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

  // ------------------------------------------------------------------------
  // [V1] UI 위젯 빌더 (날짜, 이미지, 메트릭)
  // ------------------------------------------------------------------------

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
              child: GestureDetector(
                onTap: () {
                  _dateController.animateToPage(
                    index,
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeInOut,
                  );
                },
                child: Opacity(
                  opacity: isSelected ? 1.0 : 0.4,
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

  Widget _buildProfileImage(Pet pet) {
    if (pet.imageFile != null) {
      return Image.file(pet.imageFile!, fit: BoxFit.cover);
    } else if (pet.imageAsset != null) {
      return Image.asset(pet.imageAsset!, fit: BoxFit.cover);
    }
    return const Icon(Icons.pets, size: 80, color: Colors.grey);
  }

  Widget _buildMetricItem(
    String circleText,
    String value,
    Color circleColor,
    Color textColor,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 70,
          height: 35,
          decoration: BoxDecoration(
            color: circleColor,
            borderRadius: BorderRadius.circular(22),
          ),
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Text(
            circleText,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w500,
            color: Colors.black,
          ),
        ),
      ],
    );
  }
}
