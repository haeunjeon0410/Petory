import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'dart:math';
import 'package:intl/intl.dart';
import 'nutrition_dialogs.dart';

// ==========================================
// 1. 사료 계산기 카드 (V1 디자인 + V2 데이터 파싱)
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
    // [V2 Logic] 안전한 데이터 파싱
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
          // 헤더 영역
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

          // 정보 표시 영역 (V1 디자인)
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

          // 활동량 선택 (V1 디자인)
          _buildActivitySelector(),
          const SizedBox(height: 18),

          // 결과 박스 (V1 디자인)
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
// 2. 체중 추이 그래프 카드 (V2 기능 + V1 스타일 컨테이너)
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

class _ChartData {
  final int xIndex;
  final double weight;
  final String tooltipDate;

  _ChartData(this.xIndex, this.weight, this.tooltipDate);
}

class _WeightTrendCardState extends State<WeightTrendCard> {
  String _selectedPeriod = "일간";

  @override
  Widget build(BuildContext context) {
    // --------------------------------------------------------
    // [V2 Logic] 데이터 준비 및 선형 회귀 분석
    // --------------------------------------------------------
    List<_ChartData> chartDataList = _prepareChartData();

    double diff = 0;
    List<Map<String, dynamic>> sortedHistory = List.from(widget.history);
    sortedHistory.sort((a, b) => (a['date'] as DateTime).compareTo(b['date']));

    Map<String, Map<String, dynamic>> distinctMap = {};
    for (var h in sortedHistory) {
      DateTime d = h['date'];
      distinctMap["${d.year}-${d.month}-${d.day}"] = h;
    }
    List<Map<String, dynamic>> fullHistory = distinctMap.values.toList();

    if (fullHistory.length >= 2) {
      diff =
          fullHistory.last['weight'] -
          fullHistory[fullHistory.length - 2]['weight'];
    }

    List<FlSpot> trendSpots = [];
    double? predictedWeightIn30Days;

    if (fullHistory.isNotEmpty) {
      if (fullHistory.length >= 2) {
        // [케이스 A] 데이터가 2개 이상일 때 -> 선형 회귀(추세선) 계산
        DateTime startDate = fullHistory.first['date'];

        double sumX = 0, sumY = 0, sumXY = 0, sumXX = 0;
        int n = fullHistory.length;

        for (var h in fullHistory) {
          double x = (h['date'] as DateTime)
              .difference(startDate)
              .inDays
              .toDouble();
          final double y = (h['weight'] as num?)?.toDouble() ?? double.nan;
          if (!y.isFinite) continue;

          sumX += x;
          sumY += y;
          sumXY += (x * y);
          sumXX += (x * x);
        }

        final double denominator = (n * sumXX - sumX * sumX);
        double slope = 0;
        double intercept = 0;
        if (denominator != 0) {
          slope = (n * sumXY - sumX * sumY) / denominator;
          intercept = (sumY - slope * sumX) / n;
        } else {
          slope = double.nan;
          intercept = double.nan;
        }

        // 30일 후 예측
        int lastDayDays = (fullHistory.last['date'] as DateTime)
            .difference(startDate)
            .inDays;
        predictedWeightIn30Days = (slope * (lastDayDays + 30)) + intercept;

        // 추세선(점선) 좌표 계산
        DateTime today = DateTime.now();
        DateTime viewEndDate = DateTime(today.year, today.month, today.day);
        DateTime viewStartDate;

        if (_selectedPeriod == "일간") {
          viewStartDate = viewEndDate.subtract(const Duration(days: 6));
        } else if (_selectedPeriod == "주간") {
          viewStartDate = viewEndDate.subtract(const Duration(days: 6 * 7));
        } else {
          viewStartDate = DateTime(viewEndDate.year, viewEndDate.month - 6, 1);
        }

        double startX = viewStartDate.difference(startDate).inDays.toDouble();
        double endX = viewEndDate.difference(startDate).inDays.toDouble();

        double startY = (slope * startX) + intercept;
        double endY = (slope * endX) + intercept;
        if (startY.isFinite && endY.isFinite) {
          trendSpots = [FlSpot(0, startY), FlSpot(6, endY)];
        }
      } else {
        // [케이스 B] 데이터가 1개일 때 -> 현재 체중 유지로 가정
        predictedWeightIn30Days = fullHistory.first['weight'];
      }

      if (predictedWeightIn30Days != null) {
        if (!predictedWeightIn30Days!.isFinite) {
          predictedWeightIn30Days = null;
        } else if (predictedWeightIn30Days < 0) {
          predictedWeightIn30Days = 0;
        }
      }
    }

    // 메인 그래프 데이터
    List<FlSpot> mainSpots = chartDataList
        .map((e) => FlSpot(e.xIndex.toDouble(), e.weight))
        .toList();

    // Y축 범위 계산
    List<double> allYValues = [
      ...mainSpots.map((e) => e.y),
      ...trendSpots.map((e) => e.y),
    ];

    double minW, maxW, yInterval;

    if (allYValues.isEmpty) {
      minW = 0;
      maxW = 10;
      yInterval = 2.5;
    } else {
      double dataMin = allYValues.reduce(min);
      double dataMax = allYValues.reduce(max);

      if (dataMax == dataMin) {
        dataMin -= 1;
        dataMax += 1;
      }

      double rawRange = dataMax - dataMin;
      double targetInterval = rawRange / 4.0;
      if (!targetInterval.isFinite || targetInterval == 0) {
        minW = 0;
        maxW = 10;
        yInterval = 2.5;
      } else {
        double magnitude = pow(
          10,
          (log(targetInterval) / ln10).floor(),
        ).toDouble();
        double niceStep = targetInterval / magnitude;

        if (niceStep <= 1.0)
          niceStep = 1.0;
        else if (niceStep <= 2.0)
          niceStep = 2.0;
        else if (niceStep <= 2.5)
          niceStep = 2.5;
        else
          niceStep = 5.0;

        yInterval = niceStep * magnitude;
        if (!yInterval.isFinite || yInterval == 0) {
          minW = 0;
          maxW = 10;
          yInterval = 2.5;
        } else {
          minW = (dataMin / yInterval).floorToDouble() * yInterval;
          maxW = minW + (yInterval * 4);

          if (maxW < dataMax) {
            yInterval *= 2;
            minW = (dataMin / yInterval).floorToDouble() * yInterval;
            maxW = minW + (yInterval * 4);
          }
        }
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
          // 상단바
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
              GestureDetector(
                onTap: () => NutritionDialogs.showWeightDialog(
                  context,
                  widget.petName,
                  onUpdate: widget.onUpdate,
                ),
                child: Container(
                  width: 34,
                  height: 34,
                  decoration: const BoxDecoration(
                    color: Color(0xFF44403B),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.add, color: Colors.white, size: 20),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildPeriodTabs(),
          const SizedBox(height: 24),

          // 차트 영역 (V2 fl_chart 사용)
          SizedBox(
            height: 200,
            width: double.infinity,
            child: mainSpots.isEmpty && widget.history.isEmpty
                ? const Center(
                    child: Text(
                      "데이터가 부족합니다.",
                      style: TextStyle(color: Colors.grey),
                    ),
                  )
                : LineChart(
                    LineChartData(
                      lineTouchData: LineTouchData(
                        touchTooltipData: LineTouchTooltipData(
                          getTooltipColor: (spot) => const Color(0xFF44403B),
                          getTooltipItems: (touchedSpots) {
                            return touchedSpots.map((spot) {
                              if (spot.barIndex == 1) return null;
                              if (!spot.x.isFinite || !spot.y.isFinite) {
                                return null;
                              }
                              var data = chartDataList.firstWhere(
                                (e) => e.xIndex == spot.x.toInt(),
                                orElse: () => _ChartData(0, 0, ''),
                              );
                              if (data.tooltipDate.isEmpty) return null;
                              return LineTooltipItem(
                                "${data.tooltipDate}\n${spot.y.toStringAsFixed(2)}kg",
                                const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              );
                            }).toList();
                          },
                        ),
                      ),
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        horizontalInterval: yInterval,
                        getDrawingHorizontalLine: (value) => FlLine(
                          color: Colors.grey.withOpacity(0.05),
                          strokeWidth: 1,
                        ),
                      ),
                      titlesData: FlTitlesData(
                        topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 45,
                            interval: yInterval,
                            getTitlesWidget: (value, meta) {
                              if (!value.isFinite ||
                                  !yInterval.isFinite ||
                                  yInterval == 0) {
                                return const SizedBox();
                              }
                              double step = (value - minW) / yInterval;
                              if ((step - step.round()).abs() > 0.01) {
                                return const SizedBox();
                              }
                              String text = (value % 1 == 0)
                                  ? value.toInt().toString()
                                  : value.toStringAsFixed(1);
                              bool isMin = (value - minW).abs() < 0.01;
                              bool isMax = (value - maxW).abs() < 0.01;

                              return Container(
                                color: Colors.white,
                                margin: const EdgeInsets.only(right: 5),
                                height: 20,
                                alignment: isMin
                                    ? Alignment.bottomCenter
                                    : (isMax
                                          ? Alignment.topCenter
                                          : Alignment.center),
                                child: Text(
                                  text,
                                  style: const TextStyle(
                                    color: Color(0xFFA8A29E),
                                    fontSize: 10,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            interval: 1,
                            getTitlesWidget: (value, meta) {
                              if (!value.isFinite) return const SizedBox();
                              int index = value.toInt();
                              if (index < 0 || index > 6)
                                return const SizedBox();

                              DateTime now = DateTime.now();
                              DateTime today = DateTime(
                                now.year,
                                now.month,
                                now.day,
                              );
                              int offset = 6 - index;
                              String text = "";
                              bool isLast = (offset == 0);

                              if (_selectedPeriod == "일간") {
                                DateTime target = today.subtract(
                                  Duration(days: offset),
                                );
                                text = isLast
                                    ? "오늘"
                                    : DateFormat('M.d').format(target);
                              } else if (_selectedPeriod == "주간") {
                                DateTime weekEnd = today.subtract(
                                  Duration(days: offset * 7),
                                );
                                text = isLast
                                    ? "이번 주"
                                    : "~${DateFormat('M.d').format(weekEnd)}";
                              } else {
                                DateTime target = DateTime(
                                  today.year,
                                  today.month - offset,
                                  1,
                                );
                                text = isLast
                                    ? "이번 달"
                                    : DateFormat('yy.MM').format(target);
                              }
                              return Padding(
                                padding: const EdgeInsets.only(top: 10),
                                child: Text(
                                  text,
                                  style: TextStyle(
                                    color: isLast
                                        ? const Color(0xFF44403B)
                                        : const Color(0xFFA8A29E),
                                    fontWeight: isLast
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                    fontSize: 10,
                                  ),
                                ),
                              );
                            },
                            reservedSize: 32,
                          ),
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      minX: 0,
                      maxX: 6,
                      minY: minW,
                      maxY: maxW,
                      lineBarsData: [
                        LineChartBarData(
                          spots: mainSpots,
                          isCurved: true,
                          color: const Color(0xFF44403B),
                          barWidth: 3.5,
                          isStrokeCapRound: true,
                          dotData: FlDotData(
                            show: true,
                            getDotPainter: (spot, percent, barData, index) {
                              bool isLast = spot.x == 6;
                              return FlDotCirclePainter(
                                radius: isLast ? 5 : 3.5,
                                color: isLast
                                    ? const Color(0xFFFF8A00)
                                    : const Color(0xFF44403B),
                                strokeWidth: 2,
                                strokeColor: Colors.white,
                              );
                            },
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
                        if (trendSpots.isNotEmpty)
                          LineChartBarData(
                            spots: trendSpots,
                            isCurved: false,
                            color: Colors.grey.withOpacity(0.5),
                            barWidth: 2,
                            dashArray: [5, 5],
                            dotData: const FlDotData(show: false),
                          ),
                      ],
                    ),
                  ),
          ),
          const SizedBox(height: 28),

          // 하단 정보
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

          // [V2 Logic] 미래 예측 박스
          if (predictedWeightIn30Days != null) ...[
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
                          "약 ${predictedWeightIn30Days.toStringAsFixed(2)} kg 예상",
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

  // 데이터 처리 로직 (V2)
  List<_ChartData> _prepareChartData() {
    List<Map<String, dynamic>> rawHistory = widget.history;
    if (rawHistory.isEmpty) return [];

    Map<String, Map<String, dynamic>> distinctMap = {};
    List<Map<String, dynamic>> sortedRaw = List.from(rawHistory);
    sortedRaw.sort((a, b) => (a['date'] as DateTime).compareTo(b['date']));

    for (var h in sortedRaw) {
      DateTime d = h['date'];
      String dateKey = "${d.year}-${d.month}-${d.day}";
      distinctMap[dateKey] = h;
    }
    List<Map<String, dynamic>> cleanHistory = distinctMap.values.toList();

    DateTime now = DateTime.now();
    DateTime today = DateTime(now.year, now.month, now.day);
    List<_ChartData> result = [];

    for (int i = 0; i < 7; i++) {
      int offset = 6 - i;
      if (_selectedPeriod == "일간") {
        DateTime targetDate = today.subtract(Duration(days: offset));
        var matches = cleanHistory.where((h) {
          DateTime d = h['date'];
          return d.year == targetDate.year &&
              d.month == targetDate.month &&
              d.day == targetDate.day;
        }).toList();
        if (matches.isNotEmpty) {
          final double weight =
              (matches.first['weight'] as num?)?.toDouble() ?? double.nan;
          if (!weight.isFinite) continue;
          result.add(
            _ChartData(i, weight, DateFormat('yyyy.MM.dd').format(targetDate)),
          );
        }
      } else if (_selectedPeriod == "주간") {
        DateTime weekEnd = today.subtract(Duration(days: offset * 7));
        DateTime weekStart = weekEnd.subtract(const Duration(days: 6));
        var matches = cleanHistory.where((h) {
          DateTime d = h['date'];
          DateTime dDate = DateTime(d.year, d.month, d.day);
          return !dDate.isBefore(weekStart) && !dDate.isAfter(weekEnd);
        }).toList();
        if (matches.isNotEmpty) {
          final weights = matches
              .map((e) => (e['weight'] as num?)?.toDouble() ?? double.nan)
              .where((w) => w.isFinite)
              .toList();
          if (weights.isEmpty) continue;
          double avg = weights.reduce((a, b) => a + b) / weights.length;
          String tooltip =
              "${DateFormat('M.d').format(weekStart)} ~ ${DateFormat('M.d').format(weekEnd)}";
          result.add(_ChartData(i, avg, tooltip));
        }
      } else {
        DateTime targetMonthDate = DateTime(
          today.year,
          today.month - offset,
          1,
        );
        var matches = cleanHistory.where((h) {
          DateTime d = h['date'];
          return d.year == targetMonthDate.year &&
              d.month == targetMonthDate.month;
        }).toList();
        if (matches.isNotEmpty) {
          final weights = matches
              .map((e) => (e['weight'] as num?)?.toDouble() ?? double.nan)
              .where((w) => w.isFinite)
              .toList();
          if (weights.isEmpty) continue;
          double avg = weights.reduce((a, b) => a + b) / weights.length;
          String tooltip = DateFormat('yyyy년 M월').format(targetMonthDate);
          result.add(_ChartData(i, avg, tooltip));
        }
      }
    }
    return result;
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
            onTap: () => setState(() => _selectedPeriod = period),
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
