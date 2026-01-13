import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'dart:math';
import 'package:intl/intl.dart';
import 'nutrition_dialogs.dart';

// ==========================================
// 1. 사료 계산기 카드 (기존 유지)
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
    String petType = profile['type'] ?? "강아지";
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
// 2. 체중 추이 그래프 카드 (X축, Y축 전면 수정)
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
    // 1. 차트 데이터 준비
    List<_ChartData> chartDataList = _prepareChartData();

    // 2. 변화량 계산
    double diff = 0;
    if (chartDataList.isNotEmpty) {
      double current = chartDataList.last.weight;
      if (chartDataList.length >= 2) {
        double prev = chartDataList[chartDataList.length - 2].weight;
        diff = current - prev;
      }
    }

    // 3. FlSpot 변환
    List<FlSpot> spots = chartDataList
        .map((e) => FlSpot(e.xIndex.toDouble(), e.weight))
        .toList();

    // 4. [핵심] Y축 범위 및 간격 계산 (Nice Numbers 적용)
    double minW, maxW, yInterval;

    if (spots.isEmpty) {
      minW = 0;
      maxW = 10;
      yInterval = 2.5;
    } else {
      // 데이터의 실제 최소/최대값 조회
      double dataMin = spots.map((e) => e.y).reduce(min);
      double dataMax = spots.map((e) => e.y).reduce(max);

      // 값이 하나거나 모두 같을 경우 처리
      if (dataMax == dataMin) {
        dataMin -= 1;
        dataMax += 1;
      }

      // 목표 간격 계산 (전체 범위를 4등분)
      double rawRange = dataMax - dataMin;
      double targetInterval = rawRange / 4.0;

      // 간격의 자릿수(Magnitude) 계산 (예: 35 -> 10, 0.35 -> 0.1)
      double magnitude = pow(
        10,
        (log(targetInterval) / ln10).floor(),
      ).toDouble();
      double normalizedStep = targetInterval / magnitude;

      // 보기 좋은 간격(Nice Step) 선정 (1, 2, 2.5, 5 단위)
      double niceStep;
      if (normalizedStep <= 1.0) {
        niceStep = 1.0;
      } else if (normalizedStep <= 2.0) {
        niceStep = 2.0;
      } else if (normalizedStep <= 2.5) {
        niceStep = 2.5;
      } else {
        niceStep = 5.0;
      }

      yInterval = niceStep * magnitude;

      // 그래프의 최소값(minW)을 간격에 맞춰 내림 (Grid 정렬)
      minW = (dataMin / yInterval).floorToDouble() * yInterval;
      maxW = minW + (yInterval * 4);

      // 만약 계산된 범위가 실제 최대 데이터를 포함하지 못하면 간격을 한 단계 키움
      if (maxW < dataMax) {
        if (niceStep == 1.0)
          niceStep = 2.0;
        else if (niceStep == 2.0)
          niceStep = 2.5;
        else if (niceStep == 2.5)
          niceStep = 5.0;
        else
          niceStep = 10.0; // 다음 자릿수로 넘어감

        yInterval = niceStep * magnitude;
        minW = (dataMin / yInterval).floorToDouble() * yInterval;
        maxW = minW + (yInterval * 4);
      }

      // 그래도 부족하면 한 번 더 보정 (안전장치)
      if (maxW < dataMax) {
        yInterval *= 2;
        minW = (dataMin / yInterval).floorToDouble() * yInterval;
        maxW = minW + (yInterval * 4);
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

          // 차트 영역
          SizedBox(
            height: 200,
            width: double.infinity,
            child: spots.isEmpty && widget.history.isEmpty
                ? const Center(
                    child: Text(
                      "데이터가 없습니다.",
                      style: TextStyle(color: Colors.grey),
                    ),
                  )
                : LineChart(
                    LineChartData(
                      lineTouchData: LineTouchData(
                        touchTooltipData: LineTouchTooltipData(
                          getTooltipColor: (touchedSpot) =>
                              const Color(0xFF44403B),
                          getTooltipItems: (touchedSpots) {
                            return touchedSpots.map((spot) {
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
                        touchCallback:
                            (FlTouchEvent event, lineTouchResponse) {},
                      ),
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        horizontalInterval: yInterval, // [적용] Nice Interval
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
                              // [중요] 계산된 5개 지점(minW, minW+I, ...) 외의 자동 생성 라벨 숨김
                              // 부동소수점 오차 고려하여 비교
                              double step = (value - minW) / yInterval;
                              if ((step - step.round()).abs() > 0.01) {
                                return const SizedBox();
                              }

                              // [포맷팅] 정수면 소수점 제거, 아니면 소수점 1자리
                              String text = (value % 1 == 0)
                                  ? value.toInt().toString()
                                  : value.toStringAsFixed(1);

                              // 맨 위/아래 라벨 정렬 보정
                              bool isMin = (value - minW).abs() < 0.01;
                              bool isMax = (value - maxW).abs() < 0.01;

                              return Container(
                                color: Colors.white, // 배경색으로 그리드 가림
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
                      minY: minW, // [적용]
                      maxY: maxW, // [적용]
                      lineBarsData: [
                        LineChartBarData(
                          spots: spots,
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
                      ],
                    ),
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
        ],
      ),
    );
  }

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
          double weight = matches.first['weight'];
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
          double avg =
              matches
                  .map((e) => e['weight'] as double)
                  .reduce((a, b) => a + b) /
              matches.length;
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
          double avg =
              matches
                  .map((e) => e['weight'] as double)
                  .reduce((a, b) => a + b) /
              matches.length;
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
