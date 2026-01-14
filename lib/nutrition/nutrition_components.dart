import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'dart:math';
import 'package:intl/intl.dart';

// ==========================================
// 1. 사료 계산기 카드 (기존 로직 유지)
// ==========================================
class FoodCalculatorCard extends StatelessWidget {
  final Map<String, dynamic> profile;
  final int foodAmount;
  final String activityLevel;
  final Function(String) onActivityChanged;

  const FoodCalculatorCard({
    super.key,
    required this.profile,
    required this.foodAmount,
    required this.activityLevel,
    required this.onActivityChanged,
  });

  @override
  Widget build(BuildContext context) {
    String petType = profile['type']?.toString() ?? "강아지";
    String emoji = petType == "강아지" ? "🐶" : "🐱";
    String weightStr = profile['weight']?.toString() ?? '?';
    String ageStr = profile['age']?.toString() ?? '?';
    bool isNeutered =
        (profile['isNeutered'] == true ||
        profile['isNeutered'].toString() == 'true');

    return Container(
      width: double.infinity,
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
              Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: Color(0xFF44403B),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.calculate,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                "$emoji 사료 양 계산기",
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF44403B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              color: const Color(0xFFE7E5E4).withOpacity(0.4),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              children: [
                Expanded(child: _buildInfoItem("체중", "$weightStr kg")),
                Expanded(child: _buildInfoItem("나이", "$ageStr살")),
                Expanded(child: _buildInfoItem("중성화", isNeutered ? "O" : "X")),
              ],
            ),
          ),
          const SizedBox(height: 18),
          _buildActivitySelector(),
          const SizedBox(height: 18),
          _buildResultBox(foodAmount),
        ],
      ),
    );
  }

  Widget _buildActivitySelector() => Row(
    children: ["저조", "보통", "활발"].map((level) {
      bool isSelected = activityLevel == level;
      return Expanded(
        child: GestureDetector(
          onTap: () => onActivityChanged(level),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 5),
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              color: isSelected
                  ? const Color(0xFF44403B)
                  : const Color(0xFFE7E5E4).withOpacity(0.4),
              borderRadius: BorderRadius.circular(14),
            ),
            alignment: Alignment.center,
            child: Text(
              level,
              style: TextStyle(
                color: isSelected ? Colors.white : const Color(0xFF605A55),
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        ),
      );
    }).toList(),
  );

  Widget _buildInfoItem(String label, String value) => Column(
    children: [
      Text(
        label,
        style: const TextStyle(color: Color(0xFF605A55), fontSize: 11),
      ),
      const SizedBox(height: 3),
      Text(
        value,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 14,
          color: Color(0xFF44403B),
        ),
      ),
    ],
  );

  Widget _buildResultBox(int amount) => Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(vertical: 18),
    decoration: BoxDecoration(
      color: const Color(0xFFE7E5E4),
      borderRadius: BorderRadius.circular(18),
    ),
    child: Column(
      children: [
        const Text(
          "1일 권장 사료 양",
          style: TextStyle(
            color: Color(0xFF44403B),
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "$amount",
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Color(0xFF44403B),
              ),
            ),
            const SizedBox(width: 4),
            const Text(
              "g/일",
              style: TextStyle(
                color: Color(0xFF605A55),
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

// ==========================================
// 2. 체중 추이 그래프 카드
// ==========================================
class WeightTrendCard extends StatefulWidget {
  final String petName;
  final List<Map<String, dynamic>> history;
  final double currentWeight;
  final VoidCallback onUpdate;

  const WeightTrendCard({
    super.key,
    required this.petName,
    required this.history,
    required this.currentWeight,
    required this.onUpdate,
  });

  @override
  State<WeightTrendCard> createState() => _WeightTrendCardState();
}

class _WeightTrendCardState extends State<WeightTrendCard> {
  String _selectedPeriod = "일간";
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollToEnd();
  }

  void _onPeriodChanged(String period) {
    setState(() {
      _selectedPeriod = period;
    });
    _scrollToEnd();
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
    });
  }

  void _showPredictionDialog(double predictedWeight) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 36, vertical: 20),
        backgroundColor: const Color(0xFFF7F6F0),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 280),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "AI 예측 (30일 후)",
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF5D4037),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  "약 ${predictedWeight.toStringAsFixed(2)} kg 예상",
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF3F3A36),
                  ),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4B4742),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
                      "닫기",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  DateTime _normalizeDate(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  @override
  Widget build(BuildContext context) {
    List<Map<String, dynamic>> fullData = List.from(widget.history);
    DateTime today = _normalizeDate(DateTime.now());

    bool hasTodayData = fullData.any((element) {
      DateTime d = element['date'];
      return _normalizeDate(d).isAtSameMomentAs(today);
    });

    if (!hasTodayData) {
      fullData.add({'date': DateTime.now(), 'weight': widget.currentWeight});
    }

    fullData.sort((a, b) => (a['date'] as DateTime).compareTo(b['date']));

    if (fullData.isEmpty) {
      return const SizedBox(
        height: 200,
        child: Center(child: Text("데이터가 없습니다.")),
      );
    }

    DateTime firstDate = fullData.first['date'];
    DateTime oldestDate = _normalizeDate(firstDate);

    List<FlSpot> spots = [];
    List<String> topLabels = [];
    List<String> bottomLabels = [];
    List<String> tooltips = [];

    int maxXIndex = 0;

    if (_selectedPeriod == "일간") {
      int totalDays = today.difference(oldestDate).inDays + 1;
      maxXIndex = max(6, totalDays - 1);

      for (int i = 0; i <= maxXIndex; i++) {
        DateTime targetDate = today.subtract(Duration(days: maxXIndex - i));

        bool isToday = _normalizeDate(targetDate).isAtSameMomentAs(today);
        topLabels.add(
          isToday ? "오늘" : DateFormat('E', 'ko_KR').format(targetDate),
        );
        bottomLabels.add(DateFormat('M.d').format(targetDate));
        tooltips.add(DateFormat('yyyy.MM.dd').format(targetDate));

        var match = fullData.where(
          (e) => _normalizeDate(e['date']).isAtSameMomentAs(targetDate),
        );
        if (match.isNotEmpty) {
          spots.add(
            FlSpot(i.toDouble(), (match.last['weight'] as num).toDouble()),
          );
        }
      }
    } else if (_selectedPeriod == "주간") {
      DateTime thisWeekStart = today.subtract(
        Duration(days: today.weekday - 1),
      );
      DateTime oldestWeekStart = oldestDate.subtract(
        Duration(days: oldestDate.weekday - 1),
      );

      int totalWeeks =
          (thisWeekStart.difference(oldestWeekStart).inDays / 7).round() + 1;
      maxXIndex = max(6, totalWeeks - 1);

      for (int i = 0; i <= maxXIndex; i++) {
        DateTime targetStart = thisWeekStart.subtract(
          Duration(days: (maxXIndex - i) * 7),
        );
        DateTime targetEnd = targetStart.add(const Duration(days: 6));

        topLabels.add("");
        bottomLabels.add(
          i == maxXIndex ? "이번 주" : "~${DateFormat('M.d').format(targetEnd)}",
        );
        tooltips.add(
          "${DateFormat('M.d').format(targetStart)}~${DateFormat('M.d').format(targetEnd)}",
        );

        var matches = fullData.where((e) {
          DateTime d = _normalizeDate(e['date']);
          return !d.isBefore(targetStart) && !d.isAfter(targetEnd);
        });

        if (matches.isNotEmpty) {
          double avgWeight =
              matches
                  .map((e) => (e['weight'] as num).toDouble())
                  .reduce((a, b) => a + b) /
              matches.length;
          spots.add(FlSpot(i.toDouble(), avgWeight));
        }
      }
    } else {
      DateTime thisMonthStart = DateTime(today.year, today.month, 1);
      DateTime oldestMonthStart = DateTime(
        oldestDate.year,
        oldestDate.month,
        1,
      );

      int totalMonths =
          (thisMonthStart.year - oldestMonthStart.year) * 12 +
          (thisMonthStart.month - oldestMonthStart.month) +
          1;
      maxXIndex = max(6, totalMonths - 1);

      for (int i = 0; i <= maxXIndex; i++) {
        int monthsToSubtract = maxXIndex - i;
        DateTime targetMonth = DateTime(
          thisMonthStart.year,
          thisMonthStart.month - monthsToSubtract,
          1,
        );

        topLabels.add("");
        bottomLabels.add(
          i == maxXIndex ? "이번 달" : DateFormat('yy.MM').format(targetMonth),
        );
        tooltips.add(DateFormat('yyyy년 M월').format(targetMonth));

        var matches = fullData.where((e) {
          DateTime d = e['date'];
          return d.year == targetMonth.year && d.month == targetMonth.month;
        });

        if (matches.isNotEmpty) {
          double avgWeight =
              matches
                  .map((e) => (e['weight'] as num).toDouble())
                  .reduce((a, b) => a + b) /
              matches.length;
          spots.add(FlSpot(i.toDouble(), avgWeight));
        }
      }
    }

    // [수정] 3. Y축 범위 계산 (정확히 5등분 및 X축 겹침 방지 여유 확보)
    double dataMin = spots.isEmpty ? 0 : spots.map((e) => e.y).reduce(min);
    double dataMax = spots.isEmpty ? 10 : spots.map((e) => e.y).reduce(max);

    if (dataMax == dataMin) {
      dataMax += 1.0;
      dataMin -= 1.0;
    }

    double totalDataRange = dataMax - dataMin;
    double interval = totalDataRange / 4.0;

    // 첫 번째 라벨이 X축과 겹치지 않게 minY를 넉넉히 설정
    double chartMinY = dataMin - (interval * 0.6);
    double chartMaxY = dataMax + (interval * 0.4);

    // [수정] 중복 선언 방지를 위해 여기서 한 번만 선언
    final List<double> fixedYLabels = List.generate(
      5,
      (i) => dataMin + (interval * i),
    );

    double availableWidth = MediaQuery.of(context).size.width - 44 - 45;
    double unitWidth = availableWidth / 6;
    double chartContentWidth = (maxXIndex * unitWidth) + 40.0;

    double diff = 0;
    if (fullData.length >= 2) {
      diff =
          (fullData.last['weight'] as num).toDouble() -
          (fullData[fullData.length - 2]['weight'] as num).toDouble();
    }

    double? predictedWeight;
    if (fullData.length <= 10) {
      predictedWeight =
          fullData
              .map((e) => (e['weight'] as num).toDouble())
              .reduce((a, b) => a + b) /
          fullData.length;
    } else {
      DateTime start = fullData.first['date'];
      double sumX = 0, sumY = 0, sumXY = 0, sumXX = 0;
      int n = fullData.length;
      for (var h in fullData) {
        double x = (h['date'] as DateTime).difference(start).inDays.toDouble();
        double y = (h['weight'] as num).toDouble();
        sumX += x;
        sumY += y;
        sumXY += (x * y);
        sumXX += (x * x);
      }

      double denominatorCorrect = (n * sumXX - sumX * sumX);

      if (denominatorCorrect != 0) {
        double slope = (n * sumXY - sumX * sumY) / denominatorCorrect;
        double intercept = (sumY - slope * sumX) / n;
        int lastDay = (fullData.last['date'] as DateTime)
            .difference(start)
            .inDays;
        predictedWeight = (slope * (lastDay + 30)) + intercept;
      }
    }

    return Container(
      width: double.infinity,
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: Color(0xFF44403B),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.show_chart,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    "체중 추이",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF44403B),
                    ),
                  ),
                ],
              ),
              if (predictedWeight != null)
                TextButton(
                  onPressed: () => _showPredictionDialog(predictedWeight!),
                  style: TextButton.styleFrom(
                    backgroundColor: const Color(0xFFF1F2ED),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                  ),
                  child: const Text(
                    "예측 보기",
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF44403B),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 34),
          Center(child: _buildPeriodTabs()),
          const SizedBox(height: 24),
          SizedBox(
            height: 150,
            child: Row(
              children: [
                // 1. 고정 Y축
                SizedBox(
                  width: 45,
                  child: LineChart(
                    LineChartData(
                      minY: chartMinY,
                      maxY: chartMaxY,
                      titlesData: FlTitlesData(
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 40,
                            interval: interval,
                            getTitlesWidget: (value, meta) {
                              bool isLabel = fixedYLabels.any(
                                (target) =>
                                    (target - value).abs() <= (interval / 100),
                              );
                              if (!isLabel) return const SizedBox();

                              return Text(
                                value.toStringAsFixed(1),
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: Color(0xFFA8A29E),
                                ),
                              );
                            },
                          ),
                        ),
                        bottomTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                      ),
                      gridData: const FlGridData(show: false),
                      borderData: FlBorderData(show: false),
                      lineBarsData: [LineChartBarData(spots: [], show: false)],
                    ),
                  ),
                ),
                // 2. 스크롤 그래프
                Expanded(
                  child: SingleChildScrollView(
                    controller: _scrollController,
                    scrollDirection: Axis.horizontal,
                    child: Container(
                      width: chartContentWidth,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: LineChart(
                        LineChartData(
                          minX: 0,
                          maxX: maxXIndex.toDouble(),
                          minY: chartMinY,
                          maxY: chartMaxY,
                          lineTouchData: LineTouchData(
                            touchTooltipData: LineTouchTooltipData(
                              getTooltipColor: (spot) =>
                                  const Color(0xFF44403B),
                              getTooltipItems: (touchedSpots) {
                                return touchedSpots.map((spot) {
                                  int idx = spot.x.toInt();
                                  String tooltipText =
                                      (idx >= 0 && idx < tooltips.length)
                                      ? tooltips[idx]
                                      : "";
                                  return LineTooltipItem(
                                    "$tooltipText\n${spot.y.toStringAsFixed(2)}kg",
                                    const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 11,
                                    ),
                                  );
                                }).toList();
                              },
                            ),
                          ),
                          titlesData: FlTitlesData(
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                interval: 1,
                                reservedSize: 40,
                                getTitlesWidget: (value, meta) {
                                  int i = value.toInt();
                                  if (i < 0 || i >= bottomLabels.length) {
                                    return const SizedBox();
                                  }
                                  bool isFocus = (i == maxXIndex);
                                  return Padding(
                                    padding: const EdgeInsets.only(top: 8),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        if (topLabels[i].isNotEmpty)
                                          Text(
                                            topLabels[i],
                                            style: TextStyle(
                                              fontSize: 9,
                                              color: isFocus
                                                  ? const Color(0xFF44403B)
                                                  : const Color(0xFFA8A29E),
                                              fontWeight: isFocus
                                                  ? FontWeight.bold
                                                  : FontWeight.normal,
                                            ),
                                          ),
                                        Text(
                                          bottomLabels[i],
                                          style: TextStyle(
                                            fontSize: 9,
                                            color: isFocus
                                                ? const Color(0xFF44403B)
                                                : const Color(0xFFA8A29E),
                                            fontWeight: isFocus
                                                ? FontWeight.bold
                                                : FontWeight.normal,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ),
                            leftTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                            rightTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                            topTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                          ),
                          gridData: FlGridData(
                            show: true,
                            drawVerticalLine: false,
                            horizontalInterval: interval,
                            getDrawingHorizontalLine: (v) => FlLine(
                              color: Colors.grey.withOpacity(0.1),
                              strokeWidth: 1,
                            ),
                          ),
                          borderData: FlBorderData(show: false),
                          lineBarsData: [
                            LineChartBarData(
                              spots: spots,
                              isCurved: true,
                              color: const Color(0xFF44403B),
                              barWidth: 3.5,
                              dotData: FlDotData(
                                show: true,
                                getDotPainter: (spot, p, b, i) =>
                                    FlDotCirclePainter(
                                      radius: (spot.x == maxXIndex) ? 5 : 3.5,
                                      color: (spot.x == maxXIndex)
                                          ? const Color(0xFFFF8A00)
                                          : const Color(0xFF44403B),
                                      strokeWidth: 2,
                                      strokeColor: Colors.white,
                                    ),
                              ),
                              belowBarData: BarAreaData(
                                show: true,
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    const Color(0xFF44403B).withOpacity(0.15),
                                    const Color(0xFF44403B).withOpacity(0.0),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildTrendSummary(
                  "현재 체중",
                  "${widget.currentWeight.toStringAsFixed(2)} kg",
                  const Color(0xFF44403B),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildTrendSummary(
                  "변화량",
                  "${diff >= 0 ? '+' : ''}${diff.toStringAsFixed(2)} kg",
                  const Color(0xFF2196F3),
                  isSkyBlue: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _buildPeriodTabs() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F2ED),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: ["일간", "주간", "월간"].map((period) {
          bool isSelected = _selectedPeriod == period;
          return GestureDetector(
            onTap: () => _onPeriodChanged(period),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFF44403B)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
              child: Text(
                period,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? Colors.white : const Color(0xFFA8A29E),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTrendSummary(
    String label,
    String value,
    Color color, {
    bool isSkyBlue = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: isSkyBlue
            ? const Color(0xFF2196F3).withOpacity(0.06)
            : const Color(0xFFE7E5E4).withOpacity(0.4),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 11, color: Color(0xFF605A55)),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
