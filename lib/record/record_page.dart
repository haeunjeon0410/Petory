import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'record_data.dart' as record;
import 'photo_grid_section.dart';
import 'calendar_section.dart';
import '../home/sheets/pet_register_sheet.dart';
import '../home/models/pet_model.dart';

class RecordPage extends StatefulWidget {
  final VoidCallback? onRefresh;
  const RecordPage({super.key, this.onRefresh});

  @override
  State<RecordPage> createState() => _RecordPageState();
}

class _RecordPageState extends State<RecordPage> {
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();

  void _shiftDay(int offset) {
    setState(() {
      _selectedDay = _selectedDay.add(Duration(days: offset));
      _focusedDay = _selectedDay;
    });
    if (widget.onRefresh != null) widget.onRefresh!();
  }

  Widget _buildSideDate({required String label, required VoidCallback onTap}) {
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey.shade400,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildDateSwipeBar() {
    final prevDay = _selectedDay.subtract(const Duration(days: 1));
    final nextDay = _selectedDay.add(const Duration(days: 1));
    final dateFormat = DateFormat('M.d', 'ko_KR');

    return GestureDetector(
      onHorizontalDragEnd: (details) {
        final velocity = details.primaryVelocity ?? 0;
        if (velocity.abs() < 200) return;
        _shiftDay(velocity < 0 ? 1 : -1);
      },
      child: Container(
        color: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            Expanded(
              child: Align(
                alignment: Alignment.centerLeft,
                child: _buildSideDate(
                  label: dateFormat.format(prevDay),
                  onTap: () => _shiftDay(-1),
                ),
              ),
            ),
            Expanded(
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F2ED),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    dateFormat.format(_selectedDay),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF111111),
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: Align(
                alignment: Alignment.centerRight,
                child: _buildSideDate(
                  label: dateFormat.format(nextDay),
                  onTap: () => _shiftDay(1),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

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
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(top: 15),
        child: Column(
          children: [
            _buildDateSwipeBar(),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CalendarSection(
                    selectedPetName: currentPetId,
                    selectedDay: _selectedDay,
                    focusedDay: _focusedDay,
                    onRefresh: widget.onRefresh,
                    onDayChanged: (selectedDay, focusedDay) {
                      setState(() {
                        _selectedDay = selectedDay;
                        _focusedDay = focusedDay;
                      });
                    },
                  ),
                  const SizedBox(height: 24),
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
