import 'package:flutter/material.dart';
import 'register_pet.dart';
import 'add_task_sheet.dart';
import 'checklist_item.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // --- 1. 상태 데이터 ---
  List<String> myPets = ["맥스"];
  int _selectedPetIndex = 0;

  late Map<String, List<Map<String, dynamic>>> petChecklists;
  late Map<String, Map<String, dynamic>> petProfiles;

  @override
  void initState() {
    super.initState();
    // 데이터 초기화
    petChecklists = {
      "맥스": [
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
      ],
    };
    petProfiles = {
      "맥스": {
        "name": "맥스",
        "species": "골든 리트리버",
        "age": "3",
        "height": "60",
        "weight": "32",
        "gender": "male",
        "isNeutered": true,
      },
    };
  }

  // --- 2. 로직 함수들 ---

  // 일정 추가/수정 모달 띄우기 (코드가 훨씬 짧아짐!)
  void _openTaskSheet(
    String petName, {
    int? editIndex,
    Map<String, dynamic>? existingItem,
  }) async {
    // 분리한 AddTaskSheet 위젯을 띄우고, 결과를 기다림(await)
    final result = await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddTaskSheet(existingItem: existingItem),
    );

    // 결과가 돌아오면 데이터 업데이트
    if (result != null && result is Map<String, dynamic>) {
      setState(() {
        if (editIndex != null) {
          petChecklists[petName]![editIndex] = result; // 수정
        } else {
          petChecklists[petName]!.add(result); // 추가
        }
      });
    }
  }

  // 상세 보기 모달
  void _showDetailSheet(Map<String, dynamic> item) {
    bool isDone = item['isDone'];
    var iconData = item['icon'];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 헤더 (간단해서 여기 둠)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 15,
                ),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFFE040FB), Color(0xFF9C27B0)],
                  ),
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
                            color: Color(0xFFF3E5F5),
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
                                  color: const Color(0xFF9C27B0),
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
                                  fontSize: 22,
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
                          color: isDone ? Colors.green[700] : Colors.grey[600],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // 더보기 메뉴 (수정/삭제)
  void _showMoreOptionSheet(
    String petName,
    int index,
    Map<String, dynamic> item,
  ) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.edit, color: Colors.blue),
                title: const Text("수정"),
                onTap: () {
                  Navigator.pop(context);
                  _openTaskSheet(
                    petName,
                    editIndex: index,
                    existingItem: item,
                  ); // 수정 모드로 열기
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text("삭제"),
                onTap: () {
                  setState(() {
                    petChecklists[petName]!.removeAt(index);
                  });
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // --- 3. 화면 빌드 ---
  @override
  Widget build(BuildContext context) {
    String currentPetName = myPets[_selectedPetIndex];
    List<Map<String, dynamic>> currentCheckList =
        petChecklists[currentPetName] ?? [];
    Map<String, dynamic> currentProfile = petProfiles[currentPetName] ?? {};

    return Container(
      color: const Color(0xFFFDF7FF),
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
                    return Padding(
                      padding: const EdgeInsets.only(right: 10),
                      child: GestureDetector(
                        onTap: () => setState(() => _selectedPetIndex = index),
                        child: _buildPetSelectButton(
                          myPets[index],
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
            _buildProfileCard(currentPetName, currentProfile),

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
                    color: Color(0xFF6A1B9A),
                  ),
                ),
                GestureDetector(
                  onTap: () => _openTaskSheet(currentPetName),
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: const Color(0xFF6A1B9A),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(Icons.add, color: Colors.white, size: 20),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 15),

            // 체크리스트 (분리된 위젯 사용)
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
                        onToggle: () {
                          setState(() {
                            currentCheckList[index]['isDone'] =
                                !currentCheckList[index]['isDone'];
                          });
                        },
                        onTap: () => _showDetailSheet(currentCheckList[index]),
                        onMore: () => _showMoreOptionSheet(
                          currentPetName,
                          index,
                          currentCheckList[index],
                        ),
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
    // (기존 코드와 동일, 생략 없이 사용하세요)
    return GestureDetector(
      onTap: () async {
        final updatedData = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                PetRegistrationPage(existingData: profileData),
          ),
        );
        if (updatedData != null) {
          setState(() {
            String newName = updatedData['name'];
            if (newName != petName) {
              int index = myPets.indexOf(petName);
              myPets[index] = newName;
              petChecklists[newName] = petChecklists.remove(petName) ?? [];
              petProfiles[newName] = updatedData;
              petProfiles.remove(petName);
            } else {
              petProfiles[petName] = updatedData;
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
            const CircleAvatar(
              radius: 38,
              backgroundColor: Colors.grey,
              backgroundImage: NetworkImage('https://placedog.net/100/100'),
            ),
            const SizedBox(width: 18),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        profileData['name'] ?? petName,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF4A148C),
                        ),
                      ),
                      const SizedBox(width: 6),
                      if (profileData['gender'] == 'male')
                        const Icon(Icons.male, color: Colors.blue, size: 20)
                      else if (profileData['gender'] == 'female')
                        const Icon(Icons.female, color: Colors.pink, size: 20),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "${profileData['species'] ?? '종 정보 없음'} • ${profileData['age'] ?? '?'}살",
                    style: const TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      _buildTag(
                        "${profileData['height'] ?? '?'} cm",
                        const Color(0xFFBBDEFB),
                      ),
                      const SizedBox(width: 8),
                      _buildTag(
                        "${profileData['weight'] ?? '?'} kg",
                        const Color(0xFFF8BBD0),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 나머지 버튼, 태그, 빈 상태 위젯 등은 코드가 짧아서 Home에 두어도 됩니다.
  Widget _buildAddPetButton() {
    /* ... 기존 코드 ... */
    return GestureDetector(
      onTap: () async {
        final result = await Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const PetRegistrationPage()),
        );
        if (result != null && result is Map<String, dynamic>) {
          String newName = result['name'];
          setState(() {
            myPets.add(newName);
            petChecklists[newName] = [];
            petProfiles[newName] = result;
            _selectedPetIndex = myPets.length - 1;
          });
        }
      },
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: const Color(0xFF6A1B9A),
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
        gradient: isSelected
            ? const LinearGradient(
                colors: [Color(0xFFE040FB), Color(0xFF6A1B9A)],
              )
            : null,
        color: isSelected ? null : Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isSelected ? Colors.transparent : const Color(0xFFD1C4E9),
          width: 1.5,
        ),
        boxShadow: [
          if (isSelected)
            BoxShadow(
              color: const Color(0xFFE040FB).withOpacity(0.3),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
        ],
      ),
      child: Text(
        name,
        style: TextStyle(
          color: isSelected ? Colors.white : const Color(0xFF9C27B0),
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
