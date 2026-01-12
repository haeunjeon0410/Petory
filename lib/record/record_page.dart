import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'record_data.dart' as record;
import 'photo_grid_section.dart';
import 'calendar_section.dart';
import '../home/sheets/pet_register_sheet.dart';

class RecordPage extends StatefulWidget {
  final VoidCallback? onRefresh;
  const RecordPage({super.key, this.onRefresh});

  @override
  State<RecordPage> createState() => _RecordPageState();
}

class _RecordPageState extends State<RecordPage> {
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();

  // 펫 추가 다이얼로그 로직 (home.dart와 동일한 스타일 유지)
  void _openAddPetDialog() async {
    final result = await showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: const PetRegisterSheet(),
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

  Future<void> _pickImage() async {
    if (record.selectedPetName.isEmpty) return;

    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      final today = DateTime.now();
      final key = record.normalizeDate(today);

      setState(() {
        record.photos.putIfAbsent(record.selectedPetName, () => {});
        record.photos[record.selectedPetName]!.putIfAbsent(key, () => []);
        record.photos[record.selectedPetName]![key]!.add(image.path);
      });

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
      // [수정] home.dart와 위치를 맞추기 위해 SafeArea를 제거하고 padding을 조정함
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 15, 20, 120),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- 상단 펫 선택 탭 (home.dart의 구조와 동일하게 수정) ---
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  ...List.generate(record.myPets.length, (index) {
                    String petName = record.myPets[index];
                    bool isSelected = record.selectedPetName == petName;

                    return Padding(
                      padding: const EdgeInsets.only(right: 10),
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            record.selectedPetName = petName;
                          });
                          if (widget.onRefresh != null) widget.onRefresh!();
                        },
                        child: _buildPetSelectButton(petName, isSelected),
                      ),
                    );
                  }),
                  _buildAddPetButton(),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // 캘린더 섹션
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

            // 사진 그리드 섹션
            PhotoGridSection(
              selectedPetName: currentPetName,
              focusedDay: _focusedDay,
              onRefresh: () {
                setState(() {});
              },
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _pickImage,
        backgroundColor: const Color(0xFF44403B),
        child: const Icon(Icons.camera_alt, color: Colors.white),
      ),
    );
  }

  // [수정] home.dart와 UI 디자인을 완전히 동일하게 맞춤
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

  // [수정] home.dart와 UI 디자인(폰트 크기, 색상 등)을 동일하게 맞춤
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
