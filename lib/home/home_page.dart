import 'package:flutter/material.dart';
import '../record/record_data.dart' as record;
import 'dart:io';

class HomePage extends StatefulWidget {
  final VoidCallback? onRefresh;
  const HomePage({super.key, this.onRefresh});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final int _initialDatePage = 10000;
  final PageController _dateController = PageController(
    initialPage: 10000,
    viewportFraction: 0.35,
  );
  DateTime _selectedDate = DateTime.now();

  DateTime _dateForPage(int page) =>
      DateTime.now().add(Duration(days: page - _initialDatePage));

  bool _isSameDate(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  @override
  void dispose() {
    _dateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // [연동] 현재 선택된 펫 정보 가져오기
    String currentPetId = record.selectedPetId;
    var petProfile = record.petProfiles[currentPetId];
    final int foodAmount = petProfile == null
        ? 0
        : record.calculateDailyFood(petProfile, activityLevel: '\ubcf4\ud1b5');

    return Scaffold(
      backgroundColor: const Color(0xFF92C6D1), // 원래 하늘색 배경으로 복구
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _buildDatePicker(), // 기존 디자인 날짜 바 사용
            const SizedBox(height: 40),

            if (petProfile != null) ...[
              // 1. 이름
              Text(
                petProfile['name'] ?? '이름 없음',
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 20),

              // 2. 아바타 써클 (프로필 사진 연동)
              Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  border: Border.all(color: Colors.white, width: 4),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: ClipOval(
                  child: _buildProfileImage(petProfile['imagePath']),
                ),
              ),
              const SizedBox(height: 60), // 아바타와 지표 사이 간격 넓힘
              // 3. 지표 섹션 (세로 줄바꿈 정렬 반영)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildMetricItem(
                      "식사량",
                      "${foodAmount} g",
                      Colors.white,
                      const Color(0xFF92C6D1),
                    ),
                    _buildMetricItem(
                      "달성도",
                      "중간",
                      const Color(0xFFFFF59D),
                      Colors.black87,
                    ),
                    _buildMetricItem(
                      "건강검진",
                      "D-10",
                      const Color(0xFF2D4464),
                      Colors.white,
                    ),
                  ],
                ),
              ),
            ] else ...[
              const SizedBox(height: 100),
              const Text(
                "등록된 반려동물이 없어요.\n레코드 탭에서 등록해주세요!",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // 프로필 이미지 헬퍼
  Widget _buildProfileImage(String? imagePath) {
    if (imagePath == null || imagePath.isEmpty) {
      return const Icon(Icons.pets, size: 80, color: Colors.grey);
    }
    if (imagePath.startsWith('assets/')) {
      return Image.asset(imagePath, fit: BoxFit.cover);
    }
    return Image.file(File(imagePath), fit: BoxFit.cover);
  }

  // [수정] 세로형 지표 위젯 (아이콘 바로 밑에 수치가 뜨도록 Column 사용)
  // [수정본] 가로로 긴 둥근 사각형 형태의 지표 위젯
  Widget _buildMetricItem(
    String circleText,
    String value,
    Color circleColor,
    Color textColor,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 상단: 가로가 더 긴 둥근 사각형 (Container로 변경)
        Container(
          width: 70, // 가로폭을 더 넓게 설정
          height: 35, // 높이는 기존과 비슷하게 유지
          decoration: BoxDecoration(
            color: circleColor,
            // 둥근 모서리 설정 (숫자를 키우면 캡슐 모양이 돼요!)
            borderRadius: BorderRadius.circular(22),
          ),
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 4), // 좌우 여백
          child: Text(
            circleText,
            style: TextStyle(
              fontSize: 14, // 가로가 넓어져서 글자 크기를 조금 키워도 괜찮아요
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
        ),
        const SizedBox(height: 12), // 아이콘과 수치 사이 간격
        // 하단: 수치 텍스트
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w500,
            color: Colors.black, // 수치는 검은색으로 강조
          ),
        ),
      ],
    );
  }

  Widget _buildDatePicker() {
    final List<String> weekdays = ["", "월", "화", "수", "목", "금", "토", "일"];
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: SizedBox(
        height: 30,
        child: PageView.builder(
          controller: _dateController,
          onPageChanged: (idx) {
            setState(() {
              _selectedDate = _dateForPage(idx);
            });
          },
          itemBuilder: (context, index) {
            final date = _dateForPage(index);
            final isSelected = _isSameDate(date, _selectedDate);
            final isToday = _isSameDate(date, DateTime.now());
            final dateLabel = "${date.month}.${date.day}";
            final weekdayLabel = weekdays[date.weekday];

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
                        dateLabel,
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
                            isToday ? "오늘" : weekdayLabel,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        )
                      else
                        Text(
                          weekdayLabel,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
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
}
