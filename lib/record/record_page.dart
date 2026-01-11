import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'record_data.dart' as record;
import 'photo_grid_section.dart';
import 'calendar_section.dart';

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
        // 1. SingleChildScrollView가 캘린더와 사진 전체를 감싸서 어디서든 스크롤이 가능하게 합니다.
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 15, 20, 120),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 펫 선택 바
              if (record.myPets.isNotEmpty)
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: record.myPets.map((name) {
                      bool isSelected = _selectedPetName == name;
                      return Padding(
                        padding: const EdgeInsets.only(right: 10),
                        child: GestureDetector(
                          onTap: () => setState(() => _selectedPetName = name),
                          child: _buildPetSelectButton(name, isSelected),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              const SizedBox(height: 20),

              // 2. 캘린더 섹션 (함께 스크롤됨)
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

              // 3. 사진 그리드 섹션 (아래에 자연스럽게 이어짐)
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