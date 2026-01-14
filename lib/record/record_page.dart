import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'record_data.dart' as record;
import 'calendar_section.dart';

class RecordPage extends StatefulWidget {
  final VoidCallback? onRefresh;
  const RecordPage({super.key, this.onRefresh});

  @override
  State<RecordPage> createState() => _RecordPageState();
}

class _RecordPageState extends State<RecordPage> {
  static const double _recordCardHeight = 520;
  // [State] 날짜 제어 및 컨트롤러 (누트리션 페이지와 동일)
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();

  final int _initialDatePage = 10000;
  late PageController _dateController;
  bool _showAlbum = false;
  DateTime _albumMonth = DateTime.now();

  @override
  void initState() {
    super.initState();
    _dateController = PageController(
      initialPage: _initialDatePage,
      viewportFraction: 0.35, // 간격 통일
    );
  }

  @override
  void dispose() {
    _dateController.dispose();
    super.dispose();
  }

  // 날짜 계산 로직
  DateTime _dateForPage(int page) =>
      DateTime.now().add(Duration(days: page - _initialDatePage));

  bool _isSameDate(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  Widget _buildHeader(String petName) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '$petName의 기록',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          Container(
            height: 36,
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.1),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              children: [
                _buildToggleButton(
                  text: '캘린더',
                  isSelected: !_showAlbum,
                  onTap: () => setState(() => _showAlbum = false),
                ),
                _buildToggleButton(
                  text: '앨범',
                  isSelected: _showAlbum,
                  onTap: () {
                    setState(() {
                      _showAlbum = true;
                      _albumMonth =
                          DateTime(_focusedDay.year, _focusedDay.month);
                    });
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleButton({
    required String text,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        margin: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: isSelected ? const Color(0xFFF2A783) : Colors.white,
          ),
        ),
      ),
    );
  }

  // [Widget] 누트리션 페이지와 "완전히 똑같은" 날짜 선택 바
  Widget _buildDatePicker() {
    final List<String> weekdays = ['', '월', '화', '수', '목', '금', '토', '일'];
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: SizedBox(
        height: 30, // 높이 통일
        child: PageView.builder(
          controller: _dateController,
          onPageChanged: (idx) {
            setState(() {
              _selectedDay = _dateForPage(idx);
              _focusedDay = _selectedDay;
            });
          },
          itemBuilder: (context, index) {
            final date = _dateForPage(index);
            final isSelected = _isSameDate(date, _selectedDay);
            final isToday = _isSameDate(date, DateTime.now());

            return Center(
              child: GestureDetector(
                onTap: () {
                  _dateController.animateToPage(
                    index,
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeInOut,
                  );
                },
                child: Opacity(
                  opacity: isSelected ? 1.0 : 0.4,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        "${date.month}.${date.day}",
                        style: TextStyle(
                          fontSize: isSelected ? 22 : 18,
                          fontWeight: isSelected
                              ? FontWeight.w900
                              : FontWeight.w500,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(width: 4),
                      if (isSelected)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black,
                            borderRadius: BorderRadius.circular(
                              isToday ? 20 : 50,
                            ),
                          ),
                          child: Text(
                            isToday ? '오늘' : weekdays[date.weekday],
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        )
                      else
                        Text(
                          weekdays[date.weekday],
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.black,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // 사진 선택 로직
  List<MapEntry<DateTime, String>> _getMonthPhotos(
    String petId,
    DateTime month,
  ) {
    final List<MapEntry<DateTime, String>> items = [];
    final petPhotos = record.photos[petId];
    if (petPhotos == null) return items;

    petPhotos.forEach((date, paths) {
      if (date.year == month.year && date.month == month.month) {
        for (final path in paths) {
          items.add(MapEntry(date, path));
        }
      }
    });
    items.sort((a, b) => a.key.compareTo(b.key));
    return items;
  }

  void _showPhotoPreview(String path) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.85),
      builder: (context) => GestureDetector(
        onTap: () => Navigator.pop(context),
        child: Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(12),
          child: Stack(
            children: [
              Center(
                child: InteractiveViewer(
                  child: Image.file(
                    File(path),
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) =>
                        const Icon(Icons.error_outline, color: Colors.white),
                  ),
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.4),
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAlbumView(String petId) {
    final photos = _getMonthPhotos(petId, _albumMonth);
    const EdgeInsets iconPadding = EdgeInsets.all(4);
    const BoxConstraints iconConstraints = BoxConstraints.tightFor(
      width: 32,
      height: 32,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Center(
        child: SizedBox(
          height: _recordCardHeight,
          child: Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF44403B).withOpacity(0.04),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.chevron_left,
                        color: Color(0xFF44403B),
                      ),
                      padding: iconPadding,
                      constraints: iconConstraints,
                      onPressed: () => setState(
                        () => _albumMonth =
                            DateTime(_albumMonth.year, _albumMonth.month - 1),
                      ),
                    ),
                    Expanded(
                      child: Center(
                        child: Text(
                          DateFormat('yyyy년 M월').format(_albumMonth),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF44403B),
                          ),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.chevron_right,
                        color: Color(0xFF44403B),
                      ),
                      padding: iconPadding,
                      constraints: iconConstraints,
                      onPressed: () => setState(
                        () => _albumMonth =
                            DateTime(_albumMonth.year, _albumMonth.month + 1),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: photos.isEmpty
                      ? const Center(
                          child: Text(
                            '이번 달에 기록된 사진이 없습니다.',
                            style: TextStyle(color: Colors.black, fontSize: 14),
                          ),
                        )
                      : GridView.builder(
                          itemCount: photos.length,
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            mainAxisSpacing: 18,
                            crossAxisSpacing: 18,
                            childAspectRatio: 1.0,
                          ),
                          itemBuilder: (context, index) {
                            final entry = photos[index];
                            return ClipRRect(
                              borderRadius: BorderRadius.circular(20),
                              child: GestureDetector(
                                onTap: () => _showPhotoPreview(entry.value),
                                child: Image.file(
                                  File(entry.value),
                                  fit: BoxFit.cover,
                                  errorBuilder:
                                      (context, error, stackTrace) => Container(
                                    color: const Color(0xFFE7E5E4),
                                    alignment: Alignment.center,
                                    child: const Icon(
                                      Icons.error_outline,
                                      color: Colors.redAccent,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _pickImage() async {
    if (record.selectedPetId.isEmpty) return;

    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      final key = record.normalizeDate(_selectedDay);

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
    final currentProfile = record.petProfiles[currentPetId] ?? {};
    final displayPetName = currentProfile['name']?.toString() ?? '이름 없음';

    return Scaffold(
      backgroundColor: const Color(0xFFF2A783),
      body: Column(
        children: [
          _buildDatePicker(), // 1. 누트리션 페이지와 동일하게 최상단 고정!
          Expanded(
            child: SingleChildScrollView(
              // 2. 누트리션 페이지와 동일한 패딩 적용 (20, 15, 20, 120)
              padding: const EdgeInsets.fromLTRB(0, 0, 0, 120),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildHeader(displayPetName),
                  const SizedBox(height: 30),
                  // 3. ??? ?? / ?? ??
                  _showAlbum
                      ? _buildAlbumView(currentPetId)
                      : Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Center(
                            child: SizedBox(
                              height: _recordCardHeight,
                              child: CalendarSection(
                                selectedPetName: currentPetId,
                                onRefresh: widget.onRefresh,
                                onDayChanged: (selectedDay, focusedDay) {
                                  setState(() {
                                    _selectedDay = selectedDay;
                                    _focusedDay = focusedDay;
                                  });
                                },
                              ),
                            ),
                          ),
                        ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: _showAlbum
          ? FloatingActionButton(
              onPressed: _pickImage,
              backgroundColor: const Color(0xFF44403B),
              child: const Icon(Icons.camera_alt, color: Colors.white),
            )
          : null,
    );
  }
}
