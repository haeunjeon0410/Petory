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
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 15, 20, 120),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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

            // ⭐ [수정 부분] onRefresh를 추가로 전달합니다.
            CalendarSection(
              selectedPetName: currentPetName,
              onRefresh: widget.onRefresh, // 이 부분이 추가되었습니다!
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