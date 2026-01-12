import 'dart:io'; // [필수] File 객체 사용을 위해 추가
import 'package:flutter/material.dart';
import '../record/record_data.dart' as record;

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
  int _selectedPetIndex = 0;

  @override
  void initState() {
    super.initState();
    // 초기화 시 record에 선택된 ID가 있다면 인덱스 동기화
    if (record.myPetIds.isNotEmpty && record.selectedPetId.isNotEmpty) {
      int idx = record.myPetIds.indexOf(record.selectedPetId);
      if (idx != -1) _selectedPetIndex = idx;
    }
  }

  // --- 1. 펫 등록/수정 함수 ---
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
        // [핵심 수정 1] 이미지 경로 추출
        // 사용자가 갤러리에서 사진을 골랐다면 imageFile에 값이 있고,
        // 아니면 기존 에셋(imageAsset)을 유지하거나 null입니다.
        String? imagePath;
        if (result.imageFile != null) {
          imagePath = result.imageFile!.path; // 파일 경로 저장
        } else {
          imagePath = result.imageAsset; // 기존 에셋 경로 유지
        }

        if (existingPet != null) {
          // [수정 모드]
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
            "imagePath": imagePath, // [저장] 이미지 경로 저장
          };
        } else {
          // [새 등록 모드]
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
            "imagePath": imagePath, // [저장]
          };

          record.petChecklists[newId] = [];
          _selectedPetIndex = record.myPetIds.length - 1;
          record.selectedPetId = newId;
        }
      });

      widget.onRefresh?.call();
    }
  }

  // --- 2. 펫 삭제 함수 (기존 동일) ---
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

                if (record.myPetIds.isNotEmpty) {
                  record.selectedPetId = record.myPetIds[_selectedPetIndex];
                } else {
                  record.selectedPetId = "";
                }
              });

              widget.onRefresh?.call();
            },
            child: const Text("삭제", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  // 체크리스트 관련 함수들 (기존 동일)
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

    // 현재 선택된 ID 확인 (동기화)
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
      // 탭바 변경 시 전역 변수 업데이트는 onTap에서 처리함
    }

    // 데이터 가져오기
    Pet? currentPet;
    List<Task> currentTasks = [];

    if (hasPet && currentId != null) {
      var pData = record.petProfiles[currentId];
      if (pData != null) {
        // [핵심 수정 2] 이미지 경로 처리 로직
        String? imgPath = pData['imagePath'];
        File? imgFile;
        String? imgAsset;

        // 경로가 있고, 파일 시스템 경로(/data/...)라면 File 객체 생성
        if (imgPath != null && !imgPath.startsWith('assets')) {
          imgFile = File(imgPath);
        } else {
          // assets 경로거나 null이면 기본 이미지 사용
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
          imageFile: imgFile, // [적용] 파일 이미지
          imageAsset: imgAsset, // [적용] 에셋 이미지
        );
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

    return Scaffold(
      backgroundColor: const Color(0xFFF1F2ED),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PetTabBar(
              petIds: record.myPetIds, // [변경] ID 리스트 전달
              petProfiles: record.petProfiles, // [변경] 프로필 데이터 전달
              selectedId: record.selectedPetId, // [변경] 현재 ID 전달
              onTap: (id) => setState(() {
                _selectedPetIndex = record.myPetIds.indexOf(id);
                record.selectedPetId = id;
                widget.onRefresh?.call();
              }),
              onAdd: () => _openRegisterSheet(),
            ),

            const SizedBox(height: 20),

            if (hasPet && currentPet != null)
              PetProfileCard(
                pet: currentPet,
                onEdit: () => _openRegisterSheet(existingPet: currentPet),
                onDelete: () => _deletePet(currentId!, currentPet!.name),
              )
            else
              _buildEmptyProfileCard(),

            const SizedBox(height: 30),

            // ... 체크리스트 UI (기존 동일) ...
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
                            record.petChecklists[currentId]!.removeAt(index);
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

  // ... (하단 Widget 빌더 함수들은 기존과 동일) ...
  Widget _buildEmptyProfileCard() {
    return Container(
      width: double.infinity,
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
      child: const SizedBox(
        height: 76,
        child: Center(
          child: Text(
            "상단의 (+) 버튼을 이용해\n반려동물 프로필을 등록해주세요!",
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey,
              fontSize: 15,
              height: 1.4,
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
