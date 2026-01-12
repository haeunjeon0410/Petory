import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'record_data.dart' as record;
import 'photo_grid_section.dart';
import 'calendar_section.dart';
import '../home/sheets/pet_register_sheet.dart';
import '../home/models/pet_model.dart';
// [추가] 공통 탭바 위젯 import
import '../home/widgets/pet_tab_bar.dart';

class RecordPage extends StatefulWidget {
  final VoidCallback? onRefresh;
  const RecordPage({super.key, this.onRefresh});

  @override
  State<RecordPage> createState() => _RecordPageState();
}

class _RecordPageState extends State<RecordPage> {
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();

  // 1. 펫 추가 (ID 기반)
  void _openAddPetDialog() async {
    final dynamic result = await showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: const PetRegisterSheet(),
      ),
    );

    if (result != null && result is Pet) {
      String newId = DateTime.now().millisecondsSinceEpoch.toString();

      setState(() {
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
          "imagePath": result.imageFile?.path ?? result.imageAsset,
        };
        record.petChecklists[newId] = [];
        record.weightHistory[newId] = [];
        record.selectedPetId = newId;
      });

      if (widget.onRefresh != null) widget.onRefresh!();
    }
  }

  // 2. 사진 추가 (ID 기반)
  Future<void> _pickImage() async {
    if (record.selectedPetId.isEmpty) return;

    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      final today = DateTime.now();
      final key = record.normalizeDate(today);

      setState(() {
        record.photos.putIfAbsent(record.selectedPetId, () => {});
        record.photos[record.selectedPetId]!.putIfAbsent(key, () => []);
        record.photos[record.selectedPetId]![key]!.add(image.path);
      });

      if (widget.onRefresh != null) widget.onRefresh!();
    }
  }

  @override
  Widget build(BuildContext context) {
    String currentPetId = record.selectedPetId;

    if ((currentPetId.isEmpty || !record.myPetIds.contains(currentPetId)) &&
        record.myPetIds.isNotEmpty) {
      currentPetId = record.myPetIds[0];
      record.selectedPetId = currentPetId;
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF1F2ED),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 15, 20, 120),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // [수정] 직접 구현했던 버튼 리스트를 삭제하고 PetTabBar로 교체
            PetTabBar(
              petIds: record.myPetIds,
              petProfiles: record.petProfiles,
              selectedId: currentPetId,
              onTap: (id) {
                setState(() {
                  record.selectedPetId = id;
                });
                if (widget.onRefresh != null) widget.onRefresh!();
              },
              onAdd: _openAddPetDialog,
            ),

            const SizedBox(height: 20),

            // 캘린더 섹션
            CalendarSection(
              selectedPetName: currentPetId,
              onRefresh: widget.onRefresh,
              onDayChanged: (selectedDay, focusedDay) {
                setState(() {
                  _selectedDay = selectedDay;
                  _focusedDay = focusedDay;
                });
              },
            ),
            const SizedBox(height: 24),

            // 포토 그리드 섹션
            PhotoGridSection(
              selectedPetName: currentPetId,
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
}
