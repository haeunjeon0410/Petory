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
  late String _selectedPetName;

  @override
  void initState() {
    super.initState();
    // 초기값으로 첫 번째 펫을 선택합니다.
    _selectedPetName = record.myPets.isNotEmpty ? record.myPets[0] : "";
  }

  // 반려동물 등록 다이얼로그를 여는 함수
  void _openAddPetDialog() async {
    final result = await showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: const PetRegistrationDialog(),
      ),
    );

    if (result != null && result is Map<String, dynamic>) {
      String newName = result['name'];
      setState(() {
        // 공통 데이터(record_data.dart)에 새 펫 정보 추가
        record.myPets.add(newName);
        record.petChecklists[newName] = [];
        record.petProfiles[newName] = result;

        // 새로 등록한 펫을 바로 선택 상태로 변경
        _selectedPetName = newName;
      });
      // 상위 위젯(MainPage 등)의 배지나 상태를 갱신해야 할 때 호출
      if (widget.onRefresh != null) widget.onRefresh!();
    }
  }

  Future<void> _pickImage() async {
    if (_selectedPetName.isEmpty) return;

    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        final key = record.normalizeDate(_selectedDay);
        record.photos.putIfAbsent(_selectedPetName, () => {});
        record.photos[_selectedPetName]!.putIfAbsent(key, () => []);
        record.photos[_selectedPetName]![key]!.add(image.path);
      });
      if (widget.onRefresh != null) widget.onRefresh!();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F2ED),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 15, 20, 120),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 펫 선택 바 + 추가 버튼
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    // 기존 펫 목록
                    ...record.myPets.map((name) {
                      bool isSelected = _selectedPetName == name;
                      return Padding(
                        padding: const EdgeInsets.only(right: 10),
                        child: GestureDetector(
                          onTap: () => setState(() => _selectedPetName = name),
                          child: _buildPetSelectButton(name, isSelected),
                        ),
                      );
                    }).toList(),

                    // 2. 추가 버튼 배치
                    _buildAddPetButton(),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // 캘린더 섹션
              CalendarSection(
                selectedPetName: _selectedPetName,
                onDayChanged: (selectedDay, focusedDay) {
                  setState(() {
                    _selectedDay = selectedDay;
                    _focusedDay = focusedDay;
                  });
                  if (widget.onRefresh != null) widget.onRefresh!();
                },
              ),
              const SizedBox(height: 24),

              // 사진 그리드 섹션
              PhotoGridSection(
                selectedPetName: _selectedPetName,
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

  // 추가(+) 버튼 위젯 (홈 탭과 디자인 통일)
  Widget _buildAddPetButton() {
    return GestureDetector(
      onTap: _openAddPetDialog,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: const Color(0xFF44403B),
          shape: BoxShape.circle,
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