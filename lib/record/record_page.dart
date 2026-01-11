import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'record_data.dart' as record;
import 'photo_grid_section.dart';
import 'calendar_section.dart';
import '../home/register_pet.dart';

class RecordPage extends StatefulWidget {
  final VoidCallback? onRefresh;
  const RecordPage({super.key, this.onRefresh});

  @override
  State<RecordPage> createState() => _RecordPageState();
}

class _RecordPageState extends State<RecordPage> {
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();

  // 1. [로직 변경] 로컬 변수를 삭제하고 record.selectedPetName을 직접 사용합니다.

  void _openAddPetDialog() async {
    final result = await showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: const PetRegistrationDialog(),
      ),
    );

    if (result != null && result is Map<String, dynamic>) {
      String newName = result['name'];
      setState(() {
        record.myPets.add(newName);
        record.petChecklists[newName] = [];
        record.petProfiles[newName] = result;
        // 2. [연동] 새로 등록한 펫을 공용 선택 변수에 저장
        record.selectedPetName = newName;
      });
      // 3. [연동] MainPage를 새로고침하여 홈 탭도 알게 함
      if (widget.onRefresh != null) widget.onRefresh!();
    }
  }

  Future<void> _pickImage() async {
    if (record.selectedPetName.isEmpty) return;
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        final key = record.normalizeDate(_selectedDay);
        record.photos.putIfAbsent(record.selectedPetName, () => {});
        record.photos[record.selectedPetName]!.putIfAbsent(key, () => []);
        record.photos[record.selectedPetName]![key]!.add(image.path);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // 4. [연동] 공용 변수에서 현재 선택된 펫 이름을 가져옴
    String currentPetName = record.selectedPetName;
    if (currentPetName.isEmpty && record.myPets.isNotEmpty) {
      currentPetName = record.myPets[0];
      record.selectedPetName = currentPetName;
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF1F2ED),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 15, 20, 120),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 5. [디자인 통일] 홈 탭과 똑같은 펫 선택 바
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    ...record.myPets.map((name) {
                      bool isSelected = record.selectedPetName == name;
                      return Padding(
                        padding: const EdgeInsets.only(right: 10),
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              record.selectedPetName = name;
                            });
                            if (widget.onRefresh != null) widget.onRefresh!();
                          },
                          child: _buildPetSelectButton(name, isSelected),
                        ),
                      );
                    }).toList(),
                    _buildAddPetButton(),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              CalendarSection(
                selectedPetName: currentPetName,
                onDayChanged: (selectedDay, focusedDay) {
                  setState(() {
                    _selectedDay = selectedDay;
                    _focusedDay = focusedDay;
                  });
                },
              ),
              const SizedBox(height: 24),
              PhotoGridSection(
                selectedPetName: currentPetName,
                focusedDay: _focusedDay,
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _pickImage,
        backgroundColor: const Color(0xFF44403B),
        child: const Icon(Icons.camera_alt, color: Colors.white),
      ),
    );
  }

  // 6. [디자인 통일] 홈 탭과 버튼 스타일 완벽 일치
  Widget _buildAddPetButton() {
    return GestureDetector(
      onTap: _openAddPetDialog,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: const Color(0xFF44403B),
          borderRadius: BorderRadius.circular(18), // 둥글기 일치
        ),
        child: const Icon(Icons.add, color: Colors.white, size: 20),
      ),
    );
  }

  Widget _buildPetSelectButton(String name, bool isSelected) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFF44403B) : const Color(0xFFF1F2ED),
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
}