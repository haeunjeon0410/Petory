import 'package:flutter/material.dart';
import 'dart:math';
import 'package:intl/intl.dart';
import '../record/record_data.dart' as record;
import 'nutrition_components.dart';
import 'nutrition_dialogs.dart'; // [필수] 다이얼로그 파일 import
import '../home/models/pet_model.dart';

class NutritionPage extends StatefulWidget {
  final VoidCallback? onRefresh;
  const NutritionPage({super.key, this.onRefresh});

  @override
  State<NutritionPage> createState() => _NutritionPageState();
}

class _NutritionPageState extends State<NutritionPage> {
  // --------------------------------------------------------------------------
  // [State] 변수
  // --------------------------------------------------------------------------
  final int _initialDatePage = 10000;
  late PageController _dateController;
  DateTime _selectedDate = DateTime.now();
  bool _showStats = false; // false: 기록(Input), true: 통계(Chart)

  @override
  void initState() {
    super.initState();
    _dateController = PageController(
      initialPage: _initialDatePage,
      viewportFraction: 0.35,
    );
  }

  @override
  void dispose() {
    _dateController.dispose();
    super.dispose();
  }

  // --------------------------------------------------------------------------
  // [Logic] 데이터 관리
  // --------------------------------------------------------------------------

  void _syncProfileWeight(String petId) {
    List<Map<String, dynamic>> history = record.weightHistory[petId] ?? [];
    if (history.isEmpty) return;
    history.sort((a, b) => (a['date'] as DateTime).compareTo(b['date']));
    double latestWeight = double.parse(history.last['weight'].toString());

    if (record.petProfiles[petId] != null) {
      String weightStr = latestWeight == latestWeight.toInt()
          ? latestWeight.toInt().toString()
          : latestWeight.toString();
      record.petProfiles[petId]!['weight'] = weightStr;
    }
  }

  DateTime _dateForPage(int page) =>
      DateTime.now().add(Duration(days: page - _initialDatePage));

  bool _isSameDate(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  double? _weightForDate(String petId, DateTime date) {
    final history = record.weightHistory[petId];
    if (history == null) return null;
    final target = DateTime(date.year, date.month, date.day);
    for (final entry in history) {
      final d = entry['date'] as DateTime;
      if (d.year == target.year &&
          d.month == target.month &&
          d.day == target.day) {
        return entry['weight'] as double;
      }
    }
    return null;
  }

  int _calculateNutrition(Map<String, dynamic> profile, String activityLevel) {
    final double weight =
        double.tryParse(profile['weight']?.toString() ?? '0') ?? 0;
    if (weight <= 0) return 0;

    final bool isNeutered =
        profile['isNeutered'] == true ||
        profile['isNeutered'].toString() == 'true';

    final double rer = 70 * pow(weight, 0.75).toDouble();
    String level = activityLevel == '저활동' ? '저조' : activityLevel;
    double factor = 1.6;
    if (isNeutered) {
      if (level == '저조') factor = 1.2;
      if (level == '보통') factor = 1.6;
      if (level == '활발') factor = 2.0;
    } else {
      if (level == '저조') factor = 1.4;
      if (level == '보통') factor = 1.8;
      if (level == '활발') factor = 2.5;
    }
    return (rer * factor).round();
  }

  // [수정] 다이얼로그 호출 시 petId와 현재 선택된 날짜(_selectedDate)를 전달
  void _openWeightDialog(String petId) {
    NutritionDialogs.showWeightDialog(
      context,
      petId, // 저장할 펫 ID 전달
      _selectedDate, // 현재 선택된 날짜 전달
      onUpdate: () {
        setState(() {
          _syncProfileWeight(petId);
        });
        widget.onRefresh?.call();
      },
    );
  }

  // --------------------------------------------------------------------------
  // [Widgets] 컴포넌트들
  // --------------------------------------------------------------------------
  Widget _buildDatePicker() {
    final List<String> weekdays = ['', '월', '화', '수', '목', '금', '토', '일'];
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
                            isToday ? '오늘' : weekdayLabel,
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

  Widget _buildHeader(String petName) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '$petName의 변화',
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
                  text: '기록',
                  isSelected: !_showStats,
                  onTap: () => setState(() => _showStats = false),
                ),
                _buildToggleButton(
                  text: '통계',
                  isSelected: _showStats,
                  onTap: () => setState(() => _showStats = true),
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
            color: isSelected ? const Color(0xFF92A8D9) : Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildWeightInputView(
    double currentWeight,
    String petId,
    String petName,
  ) {
    bool isToday = _isSameDate(_selectedDate, DateTime.now());
    String dateText = isToday
        ? "오늘"
        : "${_selectedDate.month}월 ${_selectedDate.day}일";

    return Column(
      children: [
        const SizedBox(height: 30),
        Text(
          '$dateText $petName의 체중은?',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          '${currentWeight.toStringAsFixed(2)} kg',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 52,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 40),

        Container(
          width: 240,
          height: 240,
          decoration: BoxDecoration(
            color: const Color(0xFF7FA6E1),
            borderRadius: BorderRadius.circular(40),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF5C85C0),
                offset: const Offset(0, 12),
                blurRadius: 0,
              ),
            ],
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Positioned(
                top: 45,
                child: Container(
                  width: 100,
                  height: 50,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(50),
                      topRight: Radius.circular(50),
                      bottomLeft: Radius.circular(5),
                      bottomRight: Radius.circular(5),
                    ),
                  ),
                  alignment: Alignment.bottomCenter,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 2.0),
                    child: const Icon(
                      Icons.arrow_drop_up_rounded,
                      size: 50,
                      color: Colors.redAccent,
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 55,
                child: Icon(
                  Icons.pets,
                  size: 45,
                  color: Colors.white.withOpacity(0.5),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 50),

        GestureDetector(
          onTap: () => _openWeightDialog(petId),
          child: Container(
            width: 260,
            padding: const EdgeInsets.symmetric(vertical: 18),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(30),
            ),
            child: const Text(
              '기록하기',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatsView(
    String displayPetName,
    List<Map<String, dynamic>> history,
    double currentWeight,
    String petId,
  ) {
    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: WeightTrendCard(
        petName: displayPetName,
        history: history,
        currentWeight: currentWeight,
        onUpdate: () {
          setState(() => _syncProfileWeight(petId));
          widget.onRefresh?.call();
        },
      ),
    );
  }

  // --------------------------------------------------------------------------
  // [Build] 메인 빌드 메서드
  // --------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    String currentPetId = record.selectedPetId;
    if ((currentPetId.isEmpty || !record.myPetIds.contains(currentPetId)) &&
        record.myPetIds.isNotEmpty) {
      currentPetId = record.myPetIds[0];
      record.selectedPetId = currentPetId;
    }

    Map<String, dynamic> currentProfile =
        record.petProfiles[currentPetId] ?? {};
    double profileWeight =
        double.tryParse(currentProfile['weight']?.toString() ?? '0') ?? 0;
    String displayPetName = currentProfile['name']?.toString() ?? "이름 없음";

    if (currentPetId.isNotEmpty) {
      if (record.weightHistory[currentPetId] == null) {
        record.weightHistory[currentPetId] = [];
      }
      if (record.weightHistory[currentPetId]!.isEmpty && profileWeight > 0) {
        record.weightHistory[currentPetId]!.add({
          "date": DateTime.now(),
          "weight": profileWeight,
        });
      }
    }

    List<Map<String, dynamic>> history =
        record.weightHistory[currentPetId] ?? [];
    history.sort((a, b) => (a['date'] as DateTime).compareTo(b['date']));

    double displayWeight =
        _weightForDate(currentPetId, _selectedDate) ?? profileWeight;

    double latestWeight = history.isNotEmpty
        ? double.parse(history.last['weight'].toString())
        : profileWeight;

    return Scaffold(
      backgroundColor: const Color(0xFFF1F2ED),
      body: Column(
        children: [
          // 1. 날짜 선택기
          _buildDatePicker(),

          // 2. 체중 기록 및 통계 섹션 (고정 레이아웃)
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Color(0xFF92A8D9),
                borderRadius: BorderRadius.zero,
              ),
              child: Column(
                children: [
                  // (1) 헤더
                  _buildHeader(displayPetName),

                  // (2) 콘텐츠
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                      child: Column(
                        children: [
                          _showStats
                              ? _buildStatsView(
                                  displayPetName,
                                  history,
                                  latestWeight,
                                  currentPetId,
                                )
                              : _buildWeightInputView(
                                  displayWeight,
                                  currentPetId,
                                  displayPetName,
                                ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
