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
        record.selectedPetName = newName;
      });
      if (widget.onRefresh != null) widget.onRefresh!();
    }
  }

  // ⭐ [수정] 사진 업로드 시 현재 선택된 날짜가 아닌 '오늘' 날짜로 저장되도록 변경
  Future<void> _pickImage() async {
    if (record.selectedPetName.isEmpty) return;

    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      // 캘린더에서 선택한 _selectedDay 대신 오늘(DateTime.now())을 사용합니다.
      final today = DateTime.now();
      final key = record.normalizeDate(today);

      setState(() {
        record.photos.putIfAbsent(record.selectedPetName, () => {});
        record.photos[record.selectedPetName]!.putIfAbsent(key, () => []);
        record.photos[record.selectedPetName]![key]!.add(image.path);
      });

      // 사진 등록 후 다른 탭이나 UI가 갱신되도록 콜백 실행
      if (widget.onRefresh != null) widget.onRefresh!();
    }
  }

  @override
  Widget build(BuildContext context) {
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
              // ⭐ PhotoGridSection 호출 시 onRefresh 인자를 전달하여
              // 사진 삭제나 날짜 변경 시 화면이 즉시 새로고침되게 합니다.
              PhotoGridSection(
                selectedPetName: currentPetName,
                focusedDay: _focusedDay,
                onRefresh: () {
                  setState(() {}); // 데이터 변경 감지 시 UI 갱신
                },
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

  Widget _buildAddPetButton() {
    return GestureDetector(
      onTap: _openAddPetDialog,
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