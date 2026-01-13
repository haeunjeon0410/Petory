import 'package:flutter/material.dart';
import '../record/record_data.dart' as record;
import 'nutrition_components.dart';
import 'nutrition_dialogs.dart';

class NutritionPage extends StatefulWidget {
  final VoidCallback? onRefresh;
  const NutritionPage({super.key, this.onRefresh});

  @override
  State<NutritionPage> createState() => _NutritionPageState();
}

class _NutritionPageState extends State<NutritionPage> {
  final int _initialDatePage = 10000;
  late PageController _dateController;
  DateTime _selectedDate = DateTime.now();
  bool _showStats = false;

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

  DateTime _dateForPage(int page) =>
      DateTime.now().add(Duration(days: page - _initialDatePage));

  bool _isSameDate(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  void _openWeightDialog(String petId, {DateTime? initialDate}) {
    final date = initialDate ?? _selectedDate;
    final initialWeight = _weightForDate(petId, date);
    NutritionDialogs.showWeightDialog(
      context,
      petId,
      initialDate: date,
      initialWeight: initialWeight == null
          ? null
          : initialWeight.toStringAsFixed(1),
      onUpdate: () {
        setState(() {});
        widget.onRefresh?.call();
      },
    );
  }

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

  Widget _buildDatePicker() {
    final List<String> weekdays = [
      '',
      '월',
      '화',
      '수',
      '목',
      '금',
      '토',
      '일',
    ];
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
                          fontWeight:
                              isSelected ? FontWeight.w900 : FontWeight.w500,
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
        setState(() {});
        widget.onRefresh?.call();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    String currentPetId = record.selectedPetId;

    if ((currentPetId.isEmpty || !record.myPetIds.contains(currentPetId)) &&
        record.myPetIds.isNotEmpty) {
      currentPetId = record.myPetIds[0];
      record.selectedPetId = currentPetId;
    }

    final Map<String, dynamic> currentProfile =
        record.petProfiles[currentPetId] ?? {};
    final double profileWeight =
        double.tryParse(currentProfile['weight']?.toString() ?? '0') ?? 0;
    final String displayPetName =
        currentProfile['name']?.toString() ?? '이름 없음';

    final List<Map<String, dynamic>> history =
        record.weightHistory[currentPetId] ?? [];
    final double currentWeight =
        _weightForDate(currentPetId, _selectedDate) ?? profileWeight;

    return Container(
      color: const Color(0xFF92A8D9),
      child: Column(
        children: [
          _buildDatePicker(),
          _buildHeader(displayPetName),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
              child: _showStats
                  ? _buildStatsView(displayPetName, history, currentWeight, currentPetId)
                  : _buildWeightInputView(currentWeight, currentPetId),
            ),
          ),
        ],
      ),
    );
  }
}
