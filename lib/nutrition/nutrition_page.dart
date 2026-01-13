import 'package:flutter/material.dart';
import 'dart:math';
import 'package:intl/intl.dart';
import '../record/record_data.dart' as record;
import '../home/sheets/pet_register_sheet.dart';
import 'nutrition_components.dart';
import 'nutrition_dialogs.dart'; // [필수] 다이얼로그 파일 import
import '../home/models/pet_model.dart';
import '../home/widgets/pet_tab_bar.dart';

class NutritionPage extends StatefulWidget {
  final VoidCallback? onRefresh;
  const NutritionPage({super.key, this.onRefresh});

  @override
  State<NutritionPage> createState() => _NutritionPageState();
}

class _NutritionPageState extends State<NutritionPage> {
  // --------------------------------------------------------------------------
  // [State] V1 (UI 디자인) 및 V2 (기능) 변수 병합
  // --------------------------------------------------------------------------
  String _activityLevel = "보통"; // 사료량 계산용 활동량

  // 날짜 선택기 관련 변수 (V1)
  final int _initialDatePage = 10000;
  late PageController _dateController;
  DateTime _selectedDate = DateTime.now();
  bool _showStats = false; // 기록 vs 통계 토글

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
  // [Logic] 사료량 계산 및 데이터 관리 (V2 기능)
  // --------------------------------------------------------------------------
  int _calculateDailyFood(Map<String, dynamic> profile, double currentWeight) {
    if (currentWeight <= 0) return 0;

    bool isNeutered =
        profile['isNeutered'] == true ||
        profile['isNeutered'].toString() == 'true';
    String type = profile['type']?.toString() ?? "강아지";

    double rer = 70 * pow(currentWeight, 0.75).toDouble();
    double k = (type == "강아지")
        ? (isNeutered ? 1.6 : 1.8)
        : (isNeutered ? 1.2 : 1.4);

    if (_activityLevel == "저조") k -= 0.2;
    if (_activityLevel == "활발") k += 0.4;

    return (rer * k / 3.5).round();
  }

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

  void _openAddPetDialog() async {
    final result = await showDialog(
      context: context,
      builder: (context) => const Dialog(
        backgroundColor: Colors.transparent,
        child: PetRegisterSheet(),
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

        double initWeight = double.tryParse(result.weight) ?? 0.0;
        record.weightHistory[newId] = [];
        if (initWeight > 0) {
          record.weightHistory[newId]!.add({
            "date": DateTime.now(),
            "weight": initWeight,
          });
        }

        if (record.petChecklists[newId] == null) {
          record.petChecklists[newId] = [];
        }
        record.selectedPetId = newId;
      });
      if (widget.onRefresh != null) widget.onRefresh!();
    }
  }

  // --------------------------------------------------------------------------
  // [Logic] 날짜 및 체중 기록 관련 (V1 기능)
  // --------------------------------------------------------------------------
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

  void _openWeightDialog(String petId, {DateTime? initialDate}) {
    final date = initialDate ?? _selectedDate;
    // NutritionDialogs 사용
    NutritionDialogs.showWeightDialog(
      context,
      record.petProfiles[petId]?['name'] ?? '',
      onUpdate: () {
        setState(() {
          _syncProfileWeight(petId);
        });
        widget.onRefresh?.call();
      },
    );
  }

  // --------------------------------------------------------------------------
  // [Widgets] V1의 UI 컴포넌트들
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
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            '나의 변화',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          GestureDetector(
            onTap: () => setState(() => _showStats = !_showStats),
            child: Text(
              _showStats ? '기록' : '통계',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                decoration: TextDecoration.underline,
                decorationColor: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeightInputView(double currentWeight, String petId) {
    return Column(
      children: [
        const SizedBox(height: 14),
        const Text(
          '오늘 내 체중은?',
          style: TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          '${currentWeight.toStringAsFixed(1)} kg',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 42,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 24),
        Container(
          width: 170,
          height: 170,
          decoration: BoxDecoration(
            color: const Color(0xFF7FA6E1),
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.12),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Center(
            child: Container(
              width: 100,
              height: 50,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9),
                borderRadius: BorderRadius.circular(50),
              ),
              child: const Icon(
                Icons.change_history,
                size: 18,
                color: Color(0xFF7FA6E1),
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
        GestureDetector(
          onTap: () => _openWeightDialog(petId, initialDate: _selectedDate),
          child: Container(
            width: 200,
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(30),
            ),
            child: const Text(
              '기록하기',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          '건강 앱에서 불러오기 ↻',
          style: TextStyle(
            color: Colors.white.withOpacity(0.7),
            fontSize: 11,
            fontWeight: FontWeight.w500,
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
    return WeightTrendCard(
      petName: displayPetName,
      history: history,
      currentWeight: currentWeight,
      onUpdate: () {
        setState(() => _syncProfileWeight(petId));
        widget.onRefresh?.call();
      },
    );
  }

  // --------------------------------------------------------------------------
  // [Build] 메인 빌드 메서드
  // --------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    // 1. 펫 ID 선택 로직 (V2)
    String currentPetId = record.selectedPetId;
    if ((currentPetId.isEmpty || !record.myPetIds.contains(currentPetId)) &&
        record.myPetIds.isNotEmpty) {
      currentPetId = record.myPetIds[0];
      record.selectedPetId = currentPetId;
    }

    // 2. 프로필 및 데이터 로드 (V2)
    Map<String, dynamic> currentProfile =
        record.petProfiles[currentPetId] ?? {};
    double profileWeight =
        double.tryParse(currentProfile['weight']?.toString() ?? '0') ?? 0;
    String displayPetName = currentProfile['name']?.toString() ?? "이름 없음";

    // 데이터 초기화
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

    // 히스토리 가져오기
    List<Map<String, dynamic>> history =
        record.weightHistory[currentPetId] ?? [];
    history.sort((a, b) => (a['date'] as DateTime).compareTo(b['date']));

    // 현재 선택된 날짜의 체중 (없으면 최신 체중) - V1 로직 결합
    double currentWeight =
        _weightForDate(currentPetId, _selectedDate) ?? profileWeight;
    // (통계용 최신 체중은 히스토리 마지막 값)
    double latestWeight = history.isNotEmpty
        ? double.parse(history.last['weight'].toString())
        : profileWeight;

    // 사료량 계산
    Map<String, dynamic> displayProfile = Map.from(currentProfile);
    displayProfile['weight'] = latestWeight;
    int foodAmount = _calculateDailyFood(displayProfile, latestWeight);

    return Container(
      color: const Color(0xFFF1F2ED), // 전체 배경 (V2 스타일)
      child: Column(
        children: [
          // 1. 펫 선택 탭바 (V2)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 15, 20, 0),
            child: PetTabBar(
              petIds: record.myPetIds,
              petProfiles: record.petProfiles,
              selectedId: currentPetId,
              onTap: (id) {
                setState(() => record.selectedPetId = id);
                if (widget.onRefresh != null) widget.onRefresh!();
              },
              onAdd: _openAddPetDialog,
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  const SizedBox(height: 20),

                  // 2. 사료량 계산기 (V2)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: FoodCalculatorCard(
                      profile: displayProfile,
                      foodAmount: foodAmount,
                      activityLevel: _activityLevel,
                      onActivityChanged: (val) =>
                          setState(() => _activityLevel = val),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // 3. 체중 기록 및 통계 섹션 (V1 디자인 적용)
                  // 파란색 배경의 새로운 디자인 섹션
                  Container(
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      color: Color(0xFF92A8D9), // V1의 파란색 배경
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(30),
                        topRight: Radius.circular(30),
                      ),
                    ),
                    child: Column(
                      children: [
                        // (1) 날짜 선택기 (V1) - 상단 둥근 모서리 안쪽에 배치
                        ClipRRect(
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(30),
                            topRight: Radius.circular(30),
                          ),
                          child: _buildDatePicker(),
                        ),

                        // (2) 헤더 (나의 변화 / 기록<->통계)
                        _buildHeader(displayPetName),

                        // (3) 콘텐츠 (입력 뷰 또는 그래프)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 10, 20, 40),
                          child: _showStats
                              ? _buildStatsView(
                                  displayPetName,
                                  history,
                                  latestWeight,
                                  currentPetId,
                                )
                              : _buildWeightInputView(
                                  currentWeight,
                                  currentPetId,
                                ),
                        ),
                      ],
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
