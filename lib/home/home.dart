import 'package:flutter/material.dart';
import 'dart:io';
import 'register_pet.dart';
import 'add_task_sheet.dart';
import 'checklist_item.dart';
import '../record/record_data.dart' as record;

class HomePage extends StatefulWidget {
  final VoidCallback? onRefresh;
  const HomePage({super.key, this.onRefresh});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // --- 1. 상태 데이터 ---
  List<String> get myPets => record.myPets;
  int _selectedPetIndex = 0;

  Map<String, List<Map<String, dynamic>>> get petChecklists =>
      record.petChecklists;
  Map<String, Map<String, dynamic>> get petProfiles => record.petProfiles;

  @override
  void initState() {
    super.initState();
    // [수정] 데이터가 하나도 없을 때만 기본값을 넣어줍니다.
    if (record.myPets.contains("맥스") && record.petProfiles["맥스"] == null) {
      record.petProfiles["맥스"] = {
        "name": "맥스",
        "species": "골든 리트리버",
        "age": "3",
        "height": "60",
        "weight": "32",
        "gender": "male",
        "isNeutered": true,
      };

      record.petChecklists["맥스"] = [
        {
          "title": "아침 식사",
          "time": "오전 8:00",
          "icon": Icons.restaurant,
          "isDone": true,
        },
        {
          "title": "아침 산책",
          "time": "오전 9:00",
          "icon": Icons.pets,
          "isDone": true,
        },
        {
          "title": "점심 산책",
          "time": "오후 1:00",
          "icon": Icons.pets,
          "isDone": false,
        },
      ];
    }
  }

  // --- 2. 로직 함수들 ---

  void _openTaskSheet(
      String petName, {
        int? editIndex,
        Map<String, dynamic>? existingItem,
      }) async {
    final result = await showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 20),
          // [핵심] 다이얼로그 배경 모양을 둥글게 설정
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.0),
          ),
          child: AddTaskSheet(existingItem: existingItem),
        );
      },
    );

    // 결과가 돌아오면 데이터 업데이트
    if (result != null && result is Map<String, dynamic>) {
      setState(() {
        if (editIndex != null) {
          record.petChecklists[petName]![editIndex] = result; // 수정
        } else {
          record.petChecklists[petName]!.add(result); // 추가
        }
      });
    }
  }

  // 상세 보기 모달
  void _showDetailSheet(Map<String, dynamic> item) {
    bool isDone = item['isDone'];
    var iconData = item['icon'];
    String? memo = item['memo'];

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 20), // 가로 여백
          child: Container(
            // [수정] 팝업창 디자인 (모서리 전체 둥글게)
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20), // 전체 둥글게
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min, // 내용만큼만 높이 차지
              children: [
                // 헤더 (모서리 둥글기 수정)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 15,
                  ),
                  decoration: const BoxDecoration(
                    color: Color(0xFF44403B),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "일정 상세",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: const Icon(Icons.close, color: Colors.white),
                      ),
                    ],
                  ),
                ),
                // 내용 본문
                Padding(
                  padding: const EdgeInsets.all(30),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 60,
                            height: 60,
                            alignment: Alignment.center,
                            decoration: const BoxDecoration(
                              color: Color(0xFFF1F2ED),
                              shape: BoxShape.circle,
                            ),
                            child: iconData is String
                                ? Text(
                              iconData,
                              style: const TextStyle(fontSize: 30),
                            )
                                : Icon(
                              iconData ?? Icons.check_circle_outline,
                              size: 30,
                              color: const Color(0xFF44403B),
                            ),
                          ),
                          const SizedBox(width: 20),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item['title'],
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  item['time'],
                                  style: const TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      if (memo != null && memo.trim().isNotEmpty) ...[
                        const SizedBox(height: 24), // 간격 띄우기
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF5F5F5), // 연한 회색 배경
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                memo,
                                style: const TextStyle(
                                  fontSize: 15,
                                  color: Colors.black87,
                                  height: 1.4, // 줄 간격
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      const SizedBox(height: 30),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: isDone
                              ? const Color(0xFFE8F5E9)
                              : Colors.grey[100],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          isDone ? "완료됨" : "미완료",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isDone
                                ? Colors.green[700]
                                : Colors.grey[600],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  int _parseTimeToMinutes(String timeStr) {
    try {
      if (timeStr.isEmpty || timeStr == "--:--") return 99999;
      final parts = timeStr.split(' ');
      if (parts.length < 2) return 99999;

      final ampm = parts[0];
      final timeParts = parts[1].split(':');

      int hour = int.parse(timeParts[0]);
      int minute = int.parse(timeParts[1]);

      if (ampm == "오후" && hour != 12) hour += 12;
      if (ampm == "오전" && hour == 12) hour = 0;

      return hour * 60 + minute;
    } catch (e) {
      return 99999;
    }
  }

  // --- 3. 화면 빌드 ---
  @override
  Widget build(BuildContext context) {
    // [1] 예외 처리: 등록된 반려동물이 0마리일 때 (체크리스트 포함 버전)
    if (myPets.isEmpty) {
      return Container(
        color: const Color(0xFFF1F2ED),
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. 상단 펫 추가 버튼 (여기로 등록 유도)
              Row(children: [_buildAddPetButton()]),
              const SizedBox(height: 20),

              // 2. 빈 프로필 카드 (수정됨)
              Container(
                width: double.infinity,
                // height: 200, <--- [삭제] 고정 높이를 지워서 내용물 크기에 맞춥니다.
                padding: const EdgeInsets.all(20), // <--- [추가] 일반 카드와 동일한 패딩
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
                child: Center(
                  // 컬럼 대신 텍스트만 깔끔하게 배치하거나, 높이를 맞추고 싶다면 Padding 조절
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 20,
                    ), // 내부 여백으로 높이 조절
                    child: Text(
                      "등록된 반려동물이 없습니다.\n상단의 (+) 버튼을 눌러 등록해주세요.", // 안내 문구 수정
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 14,
                        height: 1.5,
                      ),
                    ),
                  ),
                ),
              ),

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
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("일정을 추가하려면 반려동물을 먼저 등록해주세요 🐾"),
                          duration: Duration(seconds: 2),
                        ),
                      );
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

              // 4. 빈 체크리스트 화면
              _buildEmptyState(),
            ],
          ),
        ),
      );
    }
    String currentPetId = myPets[_selectedPetIndex];
    List<Map<String, dynamic>> currentCheckList =
        petChecklists[currentPetId] ?? [];
    Map<String, dynamic> currentProfile = petProfiles[currentPetId] ?? {};
    String currentDisplayName = currentProfile['name'] ?? "이름 없음";

    // [1] 리스트를 시간 순서대로 정렬
    currentCheckList.sort((a, b) {
      int timeA = _parseTimeToMinutes(a['time'] ?? "");
      int timeB = _parseTimeToMinutes(b['time'] ?? "");
      return timeA.compareTo(timeB);
    });

    return Container(
      color: const Color(0xFFF1F2ED),
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 상단 탭 (펫 선택)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  ...List.generate(myPets.length, (index) {
                    String id = myPets[index];
                    String name = petProfiles[id]?['name'] ?? "이름 없음";

                    return Padding(
                      padding: const EdgeInsets.only(right: 10),
                      child: GestureDetector(
                        onTap: () => setState(() => _selectedPetIndex = index),
                        child: _buildPetSelectButton(
                          name,
                          _selectedPetIndex == index,
                        ),
                      ),
                    );
                  }),
                  _buildAddPetButton(),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // 프로필 카드
            _buildProfileCard(currentDisplayName, currentProfile),

            const SizedBox(height: 30),

            // 체크리스트 헤더
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
                  // [2] 추가 버튼: 중앙 팝업(_openTaskSheet)으로 연결
                  onTap: () => _openTaskSheet(currentPetId),
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

            // 체크리스트 아이템들
            currentCheckList.isEmpty
                ? _buildEmptyState()
                : ListView.separated(
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              itemCount: currentCheckList.length,
              separatorBuilder: (context, index) =>
              const SizedBox(height: 12),
              itemBuilder: (context, index) {
                return CheckListItem(
                  item: currentCheckList[index],

                  // [3] 완료/미완료 토글
                  onToggle: () {
                    setState(() {
                      currentCheckList[index]['isDone'] =
                      !currentCheckList[index]['isDone'];
                    });
                  },

                  // [4] 상세 보기 (글씨 클릭)
                  onTap: () => _showDetailSheet(currentCheckList[index]),

                  // [5] 핵심 수정: onMore 대신 onEdit/onDelete 연결
                  onEdit: () {
                    // 수정 팝업 열기
                    _openTaskSheet(
                      currentPetName,
                      editIndex: index,
                      existingItem: currentCheckList[index],
                    );
                  },
                  onDelete: () {
                    // 삭제 처리
                    setState(() {
                      petChecklists[currentPetName]!.removeAt(index);
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

  // --- 이하 UI Helper (프로필 카드 등 간단한 것은 여기에 둠) ---

  Widget _buildProfileCard(String petName, Map<String, dynamic> profileData) {
    // [1] 강아지/고양이 이모지 결정 로직
    String petType = profileData['type'] ?? "강아지";
    String typeEmoji = petType == "강아지"
        ? "🐶"
        : (petType == "고양이" ? "🐱" : "🐾");

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
        );

        if (updatedData != null) {
          setState(() {
            String newName = updatedData['name'];
            if (newName != petName) {
              int index = record.myPets.indexOf(petName);
              record.myPets[index] = newName;

              // 1. 여기서도 record.을 붙여서 명확하게 해주는 게 좋아!
              record.petChecklists[newName] =
                  record.petChecklists.remove(petName) ?? [];
              record.petProfiles[newName] = updatedData;
              record.petProfiles.remove(petName);

              record.schedules[newName] =
                  record.schedules.remove(petName) ?? {};
              record.photos[newName] = record.photos.remove(petName) ?? {};
            } else {
              // 2. [가장 중요한 수정!] 이 부분에 record.을 붙여줘
              record.petProfiles[petName] = updatedData;
            }
          });
        }
      },
      child: Container(
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
        child: Row(
          children: [
            // 프로필 이미지 (기존 코드 유지)
            Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.grey[200],
                image:
                (profileData['image'] != null &&
                    profileData['image'] is File)
                    ? DecorationImage(
                  image: FileImage(profileData['image']),
                  fit: BoxFit.cover,
                )
                    : null,
              ),
              child: (profileData['image'] == null)
                  ? Icon(Icons.pets, size: 40, color: Colors.grey[400])
                  : null,
            ),
            child: (profileData['image'] == null)
                ? Icon(Icons.pets, size: 40, color: Colors.grey[400])
                : null,
          ),
          const SizedBox(width: 18),

          // 2. 텍스트 정보 (Expanded 사용)
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 4),
                // 이름 + 이모지
                Row(
                  children: [
                    Text(
                      profileData['name'] ?? petName,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF43403C),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(typeEmoji, style: const TextStyle(fontSize: 20)),
                  ],
                ),
                const SizedBox(height: 4),

                // 품종 • 나이 + 성별 아이콘
                Row(
                  children: [
                    Text(
                      "${profileData['species'] ?? '품종 모름'} • ${profileData['age'] ?? '?'}살",
                      style: const TextStyle(
                        color: Colors.black54,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(width: 6),
                    if (profileData['gender'] == 'male')
                      const Icon(Icons.male, color: Colors.blue, size: 16)
                    else if (profileData['gender'] == 'female')
                      const Icon(Icons.female, color: Colors.red, size: 16),
                  ],
                ),
                const SizedBox(height: 12),

                // 키/체중 태그
                Row(
                  children: [
                    _buildTag(
                      "${profileData['height'] ?? '?'} cm",
                      Colors.blue,
                    ),
                    const SizedBox(width: 8),
                    _buildTag("${profileData['weight'] ?? '?'} kg", Colors.red),
                  ],
                ),
              ],
            ),
          ),

          // 3. 점 세 개 (더보기) 메뉴 버튼
          PopupMenuButton<String>(
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            icon: const Icon(Icons.more_vert, color: Colors.grey),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            onSelected: (String value) async {
              String currentPetId = myPets[_selectedPetIndex];

              if (value == 'edit') {
                // --- 수정 로직 ---
                String? resultName = await PetRegistrationDialog.editPetProfile(
                  context,
                  currentPetId,
                  profileData,
                );

                if (resultName != null) {
                  setState(() {}); // 화면 갱신
                  if (widget.onRefresh != null) widget.onRefresh!();
                }
              } else if (value == 'delete') {
                // --- 삭제 로직 ---
                bool? confirm = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text("반려동물 삭제"),
                    content: Text(
                      "정말로 '$petName' 정보를 삭제하시겠습니까?\n이 작업은 되돌릴 수 없습니다.",
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text(
                          "취소",
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text(
                          "삭제",
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  ),
                );

                if (confirm == true) {
                  setState(() {
                    // 데이터 삭제
                    record.myPets.remove(currentPetId);
                    record.petProfiles.remove(currentPetId);
                    record.petChecklists.remove(currentPetId);

                    // 인덱스 초기화 (삭제 후 첫 번째 펫으로 이동)
                    if (record.myPets.isEmpty) {
                      // 다 지워졌으면 0으로 초기화 (build의 예외 처리가 화면을 그림)
                      _selectedPetIndex = 0;
                    } else if (_selectedPetIndex > 0) {
                      // 현재 인덱스가 0보다 크면 하나 줄여서 '이전' 펫을 보여줌
                      _selectedPetIndex--;
                    } else {
                      // 0번(맨 앞)을 지웠다면, 그대로 0번을 유지 (자동으로 다음 펫이 0번이 됨)
                      _selectedPetIndex = 0;
                    }
                  });
                }
              }
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              // 수정 메뉴
              const PopupMenuItem<String>(
                value: 'edit',
                child: Row(
                  children: [
                    Icon(Icons.edit, size: 20, color: Colors.black54),
                    SizedBox(width: 8),
                    Text('수정'),
                  ],
                ),
              ),
              const PopupMenuDivider(), // 구분선
              // 삭제 메뉴
              const PopupMenuItem<String>(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete, size: 20, color: Colors.redAccent),
                    SizedBox(width: 8),
                    Text('삭제', style: TextStyle(color: Colors.redAccent)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 나머지 버튼, 태그, 빈 상태 위젯 등은 코드가 짧아서 Home에 두어도 됩니다.
  Widget _buildAddPetButton() {
    return GestureDetector(
      onTap: () async {
        // [핵심 변경] push -> showDialog
        final result = await showDialog(
          context: context,
          builder: (context) => Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: const EdgeInsets.symmetric(horizontal: 20),
            // 모서리 둥글게
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: const PetRegistrationDialog(), // (이름 변경 예정)
          ),
        );

        if (result != null && result is Map<String, dynamic>) {
          // [수정 전] 이름(newName)을 바로 키로 사용함
          // String newName = result['name'];

          // [수정 후] 고유 ID를 생성하여 키로 사용
          String newId = DateTime.now().millisecondsSinceEpoch.toString();

          setState(() {
            record.myPets.add(newId); // 리스트에 ID 저장
            record.petChecklists[newId] = []; // 체크리스트도 ID로 관리
            record.petProfiles[newId] = result; // 프로필도 ID로 관리
            _selectedPetIndex = myPets.length - 1;
          });
        }
      },
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: const Color(0xFF44403B),
          borderRadius: BorderRadius.circular(18),
        ),
        child: const Icon(Icons.add, color: Colors.white, size: 20),
      ),
    );
  }

  Widget _buildPetSelectButton(String name, bool isSelected) {
    /* ... 기존 코드 ... */
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFF44403B) : Color(0xFFF1F2ED),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isSelected ? Colors.transparent : const Color(0xFF44403B),
          width: 1.5,
        ),
        boxShadow: [
          if (isSelected)
            BoxShadow(
              color: const Color(0xFF44403B).withOpacity(0.3),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
        ],
      ),
      child: Text(
        name,
        style: TextStyle(
          color: isSelected ? Colors.white : const Color(0xFF44403B),
          fontWeight: FontWeight.bold,
          fontSize: 15,
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    /* ... 기존 코드 ... */
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

  Widget _buildTag(String text, Color bgColor) {
    /* ... 기존 코드 ... */
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor.withOpacity(0.4),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.black87,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
