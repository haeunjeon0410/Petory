import 'package:flutter/material.dart';
import 'models/pet_model.dart';
import 'models/task_model.dart';
import 'utils/time_helper.dart';

import 'widgets/pet_tab_bar.dart';
import 'widgets/pet_profile_card.dart';
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
  // 상태 데이터
  List<String> myPetIds = [];
  Map<String, Pet> profiles = {};
  Map<String, List<Task>> checklists = {};
  int _selectedPetIndex = 0;

  @override
  void initState() {
    super.initState();
    // [수정] 초기 데이터가 없어도 강제로 생성하지 않고 빈 상태로 둡니다.
    // 필요하다면 _initializeData() 내부 로직을 사용하세요.
    _initializeData();
  }

  // (테스트용) 초기 데이터 생성 함수
  void _initializeData() {
    if (myPetIds.isEmpty) {
      String defaultId = DateTime.now().millisecondsSinceEpoch.toString();
      myPetIds.add(defaultId);

      profiles[defaultId] = Pet(
        name: "맥스",
        species: "골든 리트리버",
        age: "3",
        height: "60",
        weight: "32",
        gender: "male",
        isNeutered: true,
        imageAsset: "assets/images/golden.jpg",
      );

      checklists[defaultId] = [
        Task(title: "아침 식사", time: "오전 8:00", icon: "🍴", isDone: true),
        Task(title: "아침 산책", time: "오전 9:00", icon: "🦮", isDone: true),
        Task(title: "점심 산책", time: "오후 1:00", icon: "🐾", isDone: false),
      ];
      _selectedPetIndex = 0;
    }
  }

  // --- 로직 함수들 ---

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
        if (existingPet != null) {
          // 수정
          String currentId = myPetIds[_selectedPetIndex];
          profiles[currentId] = result;
        } else {
          // 등록
          String newId = DateTime.now().millisecondsSinceEpoch.toString();
          myPetIds.add(newId);
          profiles[newId] = result;
          checklists[newId] = [];
          _selectedPetIndex = myPetIds.length - 1;
        }
      });
    }
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
        if (editIndex != null) {
          checklists[petId]![editIndex] = result;
        } else {
          checklists[petId]!.add(result);
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

  // --- 화면 빌드 ---
  @override
  Widget build(BuildContext context) {
    // [핵심 변경 1] 빈 화면 반환 코드 삭제 (이제 아래 UI를 무조건 그립니다)
    // if (myPetIds.isEmpty) return Container(...);

    // [핵심 변경 2] 데이터가 있는지 확인하여 변수 할당
    final bool hasPet = myPetIds.isNotEmpty;

    // 펫이 없으면 null 처리
    String? currentId = hasPet ? myPetIds[_selectedPetIndex] : null;
    Pet? currentPet = hasPet ? profiles[currentId] : null;
    List<Task> currentTasks = hasPet ? (checklists[currentId] ?? []) : [];

    // 정렬 (펫이 있을 때만)
    if (hasPet) {
      currentTasks.sort(
        (a, b) => TimeHelper.parseTimeToMinutes(
          a.time,
        ).compareTo(TimeHelper.parseTimeToMinutes(b.time)),
      );
    }

    // 이름 리스트 (없으면 빈 리스트)
    List<String> displayNames = hasPet
        ? myPetIds.map((id) => profiles[id]!.name).toList()
        : [];

    return Scaffold(
      backgroundColor: const Color(0xFFF1F2ED),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. 상단 탭바 (펫이 없어도 추가 버튼은 보여야 함)
            PetTabBar(
              petNames: displayNames,
              selectedIndex: _selectedPetIndex,
              onTap: (index) => setState(() => _selectedPetIndex = index),
              onAdd: () => _openRegisterSheet(),
            ),

            const SizedBox(height: 20),

            // 2. 프로필 카드 (펫이 없으면 안내 문구 표시)
            if (hasPet && currentPet != null)
              PetProfileCard(
                pet: currentPet,
                onEdit: () => _openRegisterSheet(existingPet: currentPet),
                onDelete: () => _deletePet(currentId!, currentPet.name),
              )
            else
              _buildEmptyProfileCard(), // [추가] 빈 프로필 카드 위젯

            const SizedBox(height: 30),

            // 3. 체크리스트 헤더
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "오늘의 체크리스트",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF44403B),
                  ),
                ),
                GestureDetector(
                  // 펫이 없으면 버튼 눌러도 반응 없거나 안내 메시지
                  onTap: () {
                    if (hasPet && currentId != null) {
                      _openTaskSheet(currentId);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("반려동물을 먼저 등록해주세요! 🐾")),
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
                    child: const Icon(Icons.add, color: Colors.white, size: 20),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 15),

            // 4. 체크리스트 목록
            currentTasks.isEmpty
                ? _buildEmptyState()
                : ListView.separated(
                    physics: const NeverScrollableScrollPhysics(),
                    shrinkWrap: true,
                    itemCount: currentTasks.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final task = currentTasks[index];
                      return CheckListTile(
                        task: task,
                        onToggle: () {
                          setState(() {
                            task.isDone = !task.isDone;
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
                            checklists[currentId]!.removeAt(index);
                          });
                        },
                      );
                    },
                  ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // [추가] 펫 삭제 로직 분리
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
                myPetIds.removeAt(_selectedPetIndex);
                profiles.remove(petId);
                checklists.remove(petId);

                if (_selectedPetIndex >= myPetIds.length) {
                  _selectedPetIndex = myPetIds.length - 1;
                }
                if (_selectedPetIndex < 0) _selectedPetIndex = 0;
              });
            },
            child: const Text("삭제", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  // [추가] 프로필이 없을 때 보여줄 안내 카드
  Widget _buildEmptyProfileCard() {
    return Container(
      width: double.infinity,
      // [핵심 1] 등록된 프로필 카드와 똑같은 패딩(20)을 줍니다.
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.08),
            blurRadius: 12,
            spreadRadius: 2,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      // [핵심 2] 내부 높이를 프로필 사진 크기(76)만큼 강제로 지정합니다.
      child: const SizedBox(
        height: 88,
        child: Center(
          child: Text(
            "상단의 (+) 버튼을 이용해\n반려동물 프로필을 등록해주세요!",
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey,
              fontSize: 15,
              height: 1.4, // 줄간격
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Text(
          "등록된 일정이 없습니다.\n(+) 버튼을 눌러 추가해주세요.",
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey[400], fontSize: 14),
        ),
      ),
    );
  }
}
