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

    return LayoutBuilder(
      builder: (context, constraints) {
        const double baseHeight = 520;
        final double availableHeight = constraints.maxHeight.isFinite
            ? constraints.maxHeight
            : baseHeight;
        final double scale = (availableHeight / baseHeight).clamp(0.82, 1.0);

        final double padding = 20 * scale;
        final double headerHeight = 32 * scale;
        final double headerGap = 12 * scale;
        final double tabsHeight = 36 * scale;
        final double tabGap = 14 * scale;
        final double summaryHeight = 64 * scale;
        final double summaryGap = 10 * scale;
        final double predictHeight = predictedWeight != null ? 64 * scale : 0;

        final double contentHeight = availableHeight - (padding * 2);
        final double chartHeight = (contentHeight -
                (headerHeight +
                    headerGap +
                    tabsHeight +
                    tabGap +
                    summaryHeight +
                    (predictedWeight != null ? summaryGap + predictHeight : 0)))
            .clamp(140.0, 220.0);

        return Container(
          width: double.infinity,
          padding: EdgeInsets.all(padding),
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
              SizedBox(
                height: headerHeight,
                child: Row(
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
                      "?? ??",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF44403B),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: headerGap),
              SizedBox(
                height: tabsHeight,
                child: Center(child: _buildPeriodTabs(scale: scale)),
              ),
              SizedBox(height: tabGap),
              SizedBox(
                height: chartHeight,
                child: Row(
                  children: [
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
                          lineBarsData: [
                            LineChartBarData(spots: [], show: false),
                          ],
                        ),
                      ),
                    ),
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
                                        "$tooltipText
${spot.y.toStringAsFixed(2)}kg",
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
                                        const Color(0xFF44403B)
                                            .withOpacity(0.15),
                                        const Color(0xFF44403B)
                                            .withOpacity(0.0),
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
              SizedBox(height: chartHeight > 160 ? 12 * scale : 6 * scale),
              SizedBox(
                height: summaryHeight,
                child: Row(
                  children: [
                    Expanded(
                      child: _buildTrendSummary(
                        "?? ??",
                        "${widget.currentWeight.toStringAsFixed(2)} kg",
                        const Color(0xFF44403B),
                        scale: scale,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildTrendSummary(
                        "???",
                        "${diff >= 0 ? '+' : ''}${diff.toStringAsFixed(2)} kg",
                        const Color(0xFF2196F3),
                        isSkyBlue: true,
                        scale: scale,
                      ),
                    ),
                  ],
                ),
              ),
              if (predictedWeight != null) ...[
                SizedBox(height: summaryGap),
                SizedBox(
                  height: predictHeight,
                  child: Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(12 * scale),
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
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                "AI ?? (30? ?)",
                                style: TextStyle(
                                  fontSize: (12 * scale).clamp(10, 12),
                                  color: const Color(0xFF8D6E63),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "? ${predictedWeight.toStringAsFixed(2)} kg ??",
                                style: TextStyle(
                                  fontSize: (16 * scale).clamp(13, 16),
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF5D4037),
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
            ],
          ),
        );
      },
    );

  }

  Widget _buildPeriodTabs({double scale = 1}) {
    final double s = scale.clamp(0.85, 1.0);
    return Container(
      padding: EdgeInsets.all(4 * s),
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
              padding: EdgeInsets.symmetric(
                horizontal: 22 * s,
                vertical: 10 * s,
              ),
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
                  fontSize: (13 * s).clamp(11, 13),
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
    double scale = 1,
  }) {
    final double s = scale.clamp(0.85, 1.0);
    return Container(
      padding: EdgeInsets.symmetric(vertical: 18 * s),
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
            style: TextStyle(
              fontSize: (11 * s).clamp(10, 11),
              color: const Color(0xFF605A55),
            ),
          ),
          SizedBox(height: 8 * s),
          Text(
            value,
            style: TextStyle(
              fontSize: (18 * s).clamp(15, 18),
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
