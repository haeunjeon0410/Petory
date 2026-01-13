import 'dart:io';
import 'package:flutter/material.dart';
import '../record/record_data.dart' as record;

// 모델 및 위젯 import
import 'models/pet_model.dart';
import 'models/task_model.dart';
import 'utils/time_helper.dart';
import 'widgets/checklist_tile.dart';
import 'sheets/pet_register_sheet.dart';
import 'sheets/task_editor_sheet.dart';
import 'sheets/task_detail_dialog.dart';

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

  // [V2] 펫 관련 State
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
        insetPadding: const EdgeInsets.symmetric(horizontal: 20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
          // 체중 기록 업데이트 로직
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
          record.petChecklists[newId] = [];
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
        title: const Text("반려동물 삭제"),
        content: Text("'$petName' 프로필을 삭제하시겠습니까?"),
        backgroundColor: Colors.white,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("취소", style: TextStyle(color: Colors.grey)),
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
            child: const Text("삭제", style: TextStyle(color: Colors.red)),
          ),
        ],
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

    // 데이터 로드
    Pet? currentPet;
    List<Task> currentTasks = [];
    int foodAmount = 0;

    if (hasPet && currentId != null) {
      var pData = record.petProfiles[currentId];
      if (pData != null) {
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

        try {
          foodAmount = record.calculateDailyFood(pData, activityLevel: '보통');
        } catch (e) {
          foodAmount = 0;
        }
      }

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

    // 완료율 계산
    int totalCount = currentTasks.length;
    int doneCount = currentTasks.where((t) => t.isDone).length;
    int completionRate = totalCount == 0
        ? 0
        : ((doneCount / totalCount) * 100).round();

    return Scaffold(
      backgroundColor: const Color(0xFF92C6D1), // [V1] 하늘색 배경
      // [구조 변경] Stack을 사용하여 프로필(배경)과 체크리스트(시트) 분리
      body: Stack(
        children: [
          // -------------------------------------------------------
          // 1. 배경 레이어: 날짜 + 프로필 정보 (고정된 위치)
          // -------------------------------------------------------
          Column(
            children: [
              // 1. 날짜 선택기
              _buildDatePicker(),

              const SizedBox(height: 45),

              // 2. 프로필 정보 (PetTabBar 제거됨)
              Expanded(
                child: SingleChildScrollView(
                  physics: const ClampingScrollPhysics(),
                  child: Column(
                    children: [
                      if (currentPet != null) ...[
                        // 이름 & 메뉴 버튼 (Stack으로 중앙 정렬 + 우측 배치)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: SizedBox(
                            width: double.infinity,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                // A. 중앙 펫 이름
                                Text(
                                  currentPet.name,
                                  style: const TextStyle(
                                    fontSize: 26,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),

                                // B. 우측 끝 메뉴 버튼 (세로 점 3개)
                                Positioned(
                                  right: 0,
                                  child: Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.4),
                                      shape: BoxShape.circle,
                                    ),
                                    child: PopupMenuButton<String>(
                                      padding: EdgeInsets.zero,
                                      icon: const Icon(
                                        Icons.more_vert_rounded,
                                        color: Color(0xFF44403B),
                                        size: 24,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      onSelected: (value) {
                                        if (value == 'edit') {
                                          _openRegisterSheet(
                                            existingPet: currentPet,
                                          );
                                        } else if (value == 'delete') {
                                          _deletePet(
                                            currentId!,
                                            currentPet!.name,
                                          );
                                        }
                                      },
                                      itemBuilder: (BuildContext context) =>
                                          <PopupMenuEntry<String>>[
                                            const PopupMenuItem<String>(
                                              value: 'edit',
                                              child: Row(
                                                children: [
                                                  Icon(
                                                    Icons.edit_rounded,
                                                    size: 18,
                                                    color: Color(0xFF44403B),
                                                  ),
                                                  SizedBox(width: 10),
                                                  Text(
                                                    '프로필 수정',
                                                    style: TextStyle(
                                                      fontSize: 14,
                                                      color: Color(0xFF44403B),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            const PopupMenuDivider(),
                                            const PopupMenuItem<String>(
                                              value: 'delete',
                                              child: Row(
                                                children: [
                                                  Icon(
                                                    Icons.delete_rounded,
                                                    size: 18,
                                                    color: Colors.redAccent,
                                                  ),
                                                  SizedBox(width: 10),
                                                  Text(
                                                    '프로필 삭제',
                                                    style: TextStyle(
                                                      fontSize: 14,
                                                      color: Colors.redAccent,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // 프로필 사진
                        GestureDetector(
                          onTap: () =>
                              _openRegisterSheet(existingPet: currentPet),
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
                            child: ClipOval(
                              child: _buildProfileImage(currentPet),
                            ),
                          ),
                        ),
                        const SizedBox(height: 40),

                        // 지표 섹션
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _buildMetricItem(
                                "권장 식사량",
                                "$foodAmount g",
                                Colors.white,
                                const Color(0xFF92C6D1),
                              ),
                              _buildMetricItem(
                                "완료율",
                                "$completionRate %",
                                const Color(0xFFFFF59D),
                                Colors.black87,
                              ),
                              _buildMetricItem(
                                "건강검진",
                                "D-10",
                                const Color(0xFF2D4464),
                                Colors.white,
                              ),
                            ],
                          ),
                        ),
                        // 시트가 올라올 공간 확보
                        const SizedBox(height: 100),
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
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),

          // -------------------------------------------------------
          // 2. 전경 레이어: 체크리스트 (DraggableScrollableSheet)
          // -------------------------------------------------------
          DraggableScrollableSheet(
            initialChildSize: 0.33, // 초기 높이 비율
            minChildSize: 0.33, // 최소 높이
            maxChildSize: 0.92, // 최대 높이
            snap: true,
            builder: (BuildContext context, ScrollController scrollController) {
              return Container(
                decoration: const BoxDecoration(
                  color: Color(0xFFF1F2ED), // 베이지색 배경
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(30),
                    topRight: Radius.circular(30),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 10,
                      spreadRadius: 2,
                      offset: Offset(0, -2),
                    ),
                  ],
                ),
                child: SingleChildScrollView(
                  controller: scrollController,
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 핸들 바 (시각적 힌트)
                        Center(
                          child: Container(
                            width: 40,
                            height: 4,
                            margin: const EdgeInsets.only(bottom: 20),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade300,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),

                        // 체크리스트 헤더
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
                              ],
                            ),
                            GestureDetector(
                              onTap: () {
                                if (hasPet && currentId != null) {
                                  _openTaskSheet(currentId);
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

                        // 체크리스트 아이템들
                        currentTasks.isEmpty
                            ? Center(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 40,
                                  ),
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
                                        record.petChecklists[currentId]!
                                            .removeAt(index);
                                      });
                                    },
                                  );
                                },
                              ),
                        // 하단 여백
                        const SizedBox(height: 80),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ],
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
          constraints: const BoxConstraints(minWidth: 88),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
          decoration: BoxDecoration(
            color: circleColor,
            borderRadius: BorderRadius.circular(24),
          ),
          alignment: Alignment.center,
          child: Text(
            circleText,
            style: TextStyle(
              fontSize: 15,
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
