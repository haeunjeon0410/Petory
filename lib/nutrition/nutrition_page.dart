import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math';
import 'package:intl/intl.dart';
import '../record/record_data.dart' as record;
import 'nutrition_components.dart';
import '../home/models/pet_model.dart';

class NutritionPage extends StatefulWidget {
  final VoidCallback? onRefresh;
  const NutritionPage({super.key, this.onRefresh});

  @override
  State<NutritionPage> createState() => _NutritionPageState();
}

class _NutritionPageState extends State<NutritionPage> {
  // --------------------------------------------------------------------------
  // [State] 변수 - 모든 요소 유지
  // --------------------------------------------------------------------------
  static const double _recordCardHeight = 460; // 레코드 페이지와 동일하게 높이 고정
  final int _initialDatePage = 10000;
  late PageController _dateController;
  final TextEditingController _weightController = TextEditingController();
  final FocusNode _weightFocusNode = FocusNode();
  DateTime _selectedDate = DateTime.now();
  bool _showStats = false;
  String? _weightError;
  String _weightInputKey = '';

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
    _weightController.dispose();
    _weightFocusNode.dispose();
    super.dispose();
  }

  // --------------------------------------------------------------------------
  // [Logic] 데이터 관리 로직 - 기존 로직 유지
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

  void _syncWeightInput(String petId, double displayWeight) {
    final key =
        '$petId-${_selectedDate.year}-${_selectedDate.month}-${_selectedDate.day}';
    if (_weightInputKey == key) return;
    _weightInputKey = key;
    _weightController.text = displayWeight.toStringAsFixed(2);
    _weightController.selection = TextSelection.collapsed(
      offset: _weightController.text.length,
    );
    _weightError = null;
  }

  void _submitWeight(String petId) {
    final String text = _weightController.text.trim();
    final double? newWeight = double.tryParse(text);

    if (text.isEmpty) {
      setState(() => _weightError = "체중을 입력해주세요.");
      FocusScope.of(context).requestFocus(_weightFocusNode);
      return;
    }
    if (newWeight == null) {
      setState(() => _weightError = "숫자만 입력 가능합니다.");
      FocusScope.of(context).requestFocus(_weightFocusNode);
      return;
    }
    if (newWeight >= 1000) {
      setState(() => _weightError = "1000kg 미만으로 입력해주세요.");
      FocusScope.of(context).requestFocus(_weightFocusNode);
      return;
    }

    setState(() {
      _weightError = null;
      if (record.weightHistory[petId] == null) record.weightHistory[petId] = [];
      record.weightHistory[petId]!.removeWhere((item) {
        DateTime d = item['date'];
        return d.year == _selectedDate.year &&
            d.month == _selectedDate.month &&
            d.day == _selectedDate.day;
      });
      record.weightHistory[petId]!.add({
        "date": _selectedDate,
        "weight": newWeight,
      });
      _syncProfileWeight(petId);
    });
    FocusScope.of(context).unfocus();
    widget.onRefresh?.call();
  }

  // --------------------------------------------------------------------------
  // [Widgets] 컴포넌트 디자인 유지
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

  // [유지] 하은님이 만든 저울 아이콘과 입력 폼 디자인 그대로!

  Widget _buildWeightInputView(
    double currentWeight,
    String petId,
    String petName,
  ) {
    bool isToday = _isSameDate(_selectedDate, DateTime.now());
    String dateText = isToday
        ? "오늘"
        : "${_selectedDate.month}월 ${_selectedDate.day}일";

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Center(
        child: SizedBox(
          height: _recordCardHeight, // ? ?
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                children: [
                  Text(
                  '$dateText $petName의 체중은?',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      SizedBox(
                        width: 130,
                        child: TextField(
                          controller: _weightController,
                          focusNode: _weightFocusNode,
                          maxLength: 6,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                              RegExp(r'^\d*\.?\d*'),
                            ),
                          ],
                          textAlign: TextAlign.right,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 44,
                            fontWeight: FontWeight.w800,
                          ),
                          cursorColor: Colors.white,
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            counterText: "",
                            isDense: true,
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Text(
                        'kg',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  if (_weightError != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      _weightError!,
                      style: const TextStyle(
                        color: Colors.redAccent,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  // [?]? ? ? ? ?
                  Container(
                    width: 190,
                    height: 190,
                    decoration: BoxDecoration(
                      color: const Color(0xFF7FA6E1),
                      borderRadius: BorderRadius.circular(40),
                      boxShadow: [
                        const BoxShadow(
                          color: Color(0xFF5C85C0),
                          offset: Offset(0, 8),
                          blurRadius: 0,
                        ),
                      ],
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Positioned(
                          top: 32,
                          child: Container(
                            width: 78,
                            height: 40,
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(45),
                                topRight: Radius.circular(45),
                                bottomLeft: Radius.circular(5),
                                bottomRight: Radius.circular(5),
                              ),
                            ),
                            alignment: Alignment.bottomCenter,
                            child: const Icon(
                              Icons.arrow_drop_up_rounded,
                              size: 38,
                              color: Colors.redAccent,
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 40,
                          child: Icon(
                            Icons.pets,
                            size: 34,
                            color: Colors.white.withOpacity(0.5),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              GestureDetector(
                onTap: () => _submitWeight(petId),
                child: Container(
                  width: 210,
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
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
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
  Widget _buildStatsView(
    String displayPetName,
    List<Map<String, dynamic>> history,
    double currentWeight,
    String petId,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Center(
        child: SizedBox(
          height: _recordCardHeight, // 높이 고정
          child: WeightTrendCard(
            petName: displayPetName,
            history: history,
            currentWeight: currentWeight,
            onUpdate: () {
              setState(() => _syncProfileWeight(petId));
              widget.onRefresh?.call();
            },
          ),
        ),
      ),
    );
  }

  // --------------------------------------------------------------------------
  // [Build] 구조 동기화 (RecordPage와 동일하게)
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

    List<Map<String, dynamic>> history =
        record.weightHistory[currentPetId] ?? [];
    history.sort((a, b) => (a['date'] as DateTime).compareTo(b['date']));

    double displayWeight =
        _weightForDate(currentPetId, _selectedDate) ?? profileWeight;
    _syncWeightInput(currentPetId, displayWeight);

    double latestWeight = history.isNotEmpty
        ? double.parse(history.last['weight'].toString())
        : profileWeight;

    return Scaffold(
      backgroundColor: const Color(0xFF92A8D9), // 전체 배경색 통일
      body: Column(
        children: [
          _buildDatePicker(), // 최상단 고정 날짜 바
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                0,
                0,
                0,
                120,
              ), // 레코드 페이지와 하단 패딩 통일
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 8),
                  _buildHeader(displayPetName), // 헤더를 스크롤 안으로 넣어 위치 동기화
                  const SizedBox(height: 24),
                  // 콘텐츠 영역 (높이 고정으로 탭 전환 시 덜컹거림 방지)
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
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
