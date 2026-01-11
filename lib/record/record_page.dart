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

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        final key = record.normalizeDate(_selectedDay);
        record.photos.putIfAbsent(key, () => []);
        record.photos[key]!.add(image.path);
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
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
          child: Column(
            children: [
              const SizedBox(height: 16),
              CalendarSection(
                onDayChanged: (selectedDay, focusedDay) {
                  setState(() {
                    _selectedDay = selectedDay;
                    _focusedDay = focusedDay;
                  });
                  if (widget.onRefresh != null) widget.onRefresh!();
                },
              ),
              const SizedBox(height: 24),
              PhotoGridSection(focusedDay: _focusedDay),
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
}