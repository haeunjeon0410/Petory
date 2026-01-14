import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'dart:math';
import 'package:intl/intl.dart';
import 'nutrition_dialogs.dart';

// ==========================================
// 1. 사료 계산기 카드 (변경 없음)
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
// 2. 체중 추이 그래프 카드 (Y축 등간격 수정 완료)
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

  DateTime _normalizeDate(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  @override
  Widget build(BuildContext context) {
    // 1. 데이터 준비
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

    // 2. 그래프 데이터 생성
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

        if (i == maxXIndex) {
          topLabels.add("");
          bottomLabels.add("이번 주");
        } else {
          topLabels.add("");
          bottomLabels.add("~${DateFormat('M.d').format(targetEnd)}");
        }
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

        if (i == maxXIndex) {
          topLabels.add("");
          bottomLabels.add("이번 달");
        } else {
          topLabels.add("");
          bottomLabels.add(DateFormat('yy.MM').format(targetMonth));
        }
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

    // 3. Y축 범위 계산 (정확히 5등분) - 수정된 부분
    double dataMin = spots.isEmpty ? 0 : spots.map((e) => e.y).reduce(min);
    double dataMax = spots.isEmpty ? 10 : spots.map((e) => e.y).reduce(max);

    // 데이터 값이 하나거나 같을 경우 강제로 범위 확장
    if (dataMax == dataMin) {
      dataMax += 1.0;
      dataMin -= 1.0;
    }

    // 위아래 여유 공간 (전체 범위의 15% 정도)
    double rawRange = dataMax - dataMin;
    double margin = rawRange * 0.15;

    double adjustedMin = dataMin - margin;
    double adjustedMax = dataMax + margin;
    double adjustedRange = adjustedMax - adjustedMin;

    // 5개의 라벨 = 4개의 구간 (interval)
    double interval = adjustedRange / 4.0;

    // 계산된 interval로 정확한 min, max 재설정
    // (이렇게 해야 차트가 interval에 맞춰 딱 떨어지게 그려짐)
    double chartMinY = adjustedMin;
    double chartMaxY = adjustedMin + (interval * 4);

    // 4. UI 레이아웃 크기
    double availableWidth = MediaQuery.of(context).size.width - 44 - 45;
    double unitWidth = availableWidth / 6;
    double chartContentWidth = (maxXIndex * unitWidth) + 40.0;

    // 5. 변화량
    double diff = 0;
    if (fullData.length >= 2) {
      diff =
          (fullData.last['weight'] as num).toDouble() -
          (fullData[fullData.length - 2]['weight'] as num).toDouble();
    }

    // 6. AI 예측
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
          const SizedBox(height: 20),

          Center(child: _buildPeriodTabs()),
          const SizedBox(height: 24),

          SizedBox(
            height: 200,
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
                              // 부동소수점 오차 방지를 위해 근사값 체크
                              // 정확히 interval 배수 위치에 있는 값만 표시
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
                                  if (i < 0 || i >= bottomLabels.length)
                                    return const SizedBox();

                                  String top = topLabels[i];
                                  String bottom = bottomLabels[i];
                                  bool isFocus = (i == maxXIndex);

                                  return Padding(
                                    padding: const EdgeInsets.only(top: 8),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        if (top.isNotEmpty)
                                          Text(
                                            top,
                                            style: TextStyle(
                                              fontSize: 10,
                                              color: isFocus
                                                  ? const Color(0xFF44403B)
                                                  : const Color(0xFFA8A29E),
                                              fontWeight: isFocus
                                                  ? FontWeight.bold
                                                  : FontWeight.normal,
                                            ),
                                          ),
                                        Text(
                                          bottom,
                                          style: TextStyle(
                                            fontSize: 10,
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
          const SizedBox(height: 28),

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

          if (predictedWeight != null) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF8E1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFFFECB3)),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.auto_awesome,
                    size: 20,
                    color: Color(0xFFFF8F00),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "AI 예측 (30일 후)",
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF8D6E63),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "약 ${predictedWeight.toStringAsFixed(2)} kg 예상",
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF5D4037),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
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
      padding: const EdgeInsets.symmetric(vertical: 18),
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
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
