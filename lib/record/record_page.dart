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
  // [State] 날짜 제어 및 컨트롤러 (누트리션 페이지와 동일)
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();

  final int _initialDatePage = 10000;
  late PageController _dateController;

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

    return Scaffold(
      backgroundColor: const Color(0xFFF2A783), // 하은이가 픽한 살구색 배경
      body: Column(
        children: [
          _buildDatePicker(), // 1. 누트리션 페이지와 동일하게 최상단 고정!
          Expanded(
            child: SingleChildScrollView(
              // 2. 누트리션 페이지와 동일한 패딩 적용 (20, 15, 20, 120)
              padding: const EdgeInsets.fromLTRB(20, 15, 20, 120),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 3. 캘린더 섹션 (하얀 박스 느낌을 줄인 캘린더)
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

                  // 4. 포토 그리드 섹션
            PhotoGridSection(
              selectedPetName: currentPetId,
              focusedDay: _focusedDay,
              selectedDay: _selectedDay,
              onRefresh: () {
                setState(() {});
                widget.onRefresh?.call();
              },
            ),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _pickImage,
        backgroundColor: const Color(0xFF44403B),
        child: const Icon(Icons.camera_alt, color: Colors.white),
      ),
    );
  }
}
