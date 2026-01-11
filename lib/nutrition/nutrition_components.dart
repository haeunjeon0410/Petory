import 'package:flutter/material.dart';
import 'dart:math';
import 'dart:ui' as ui;
import 'package:intl/intl.dart';
import 'nutrition_dialogs.dart';

// 1. 사료 계산기 카드
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
    return Container(
      width: double.infinity, padding: const EdgeInsets.all(22),
      decoration: _cardDecoration(),
      child: Column(children: [
        Row(children: [
          Container(padding: const EdgeInsets.all(8), decoration: const BoxDecoration(color: Color(0xFF44403B), shape: BoxShape.circle), child: const Icon(Icons.calculate, color: Colors.white, size: 20)),
          const SizedBox(width: 10),
          Text("$emoji 사료 양 계산기", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF44403B))),
        ]),
        const SizedBox(height: 18),
        Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(color: const Color(0xFFE7E5E4).withOpacity(0.4), borderRadius: BorderRadius.circular(18)),
          child: Row(children: [
            Expanded(child: _buildInfoItem("체중", "${profile['weight'] ?? '?'} kg")),
            Expanded(child: _buildInfoItem("나이", "${profile['age'] ?? '?'}살")),
            Expanded(child: _buildInfoItem("중성화", (profile['isNeutered'] ?? false) ? "O" : "X")),
          ]),
        ),
        const SizedBox(height: 18),
        _buildActivitySelector(),
        const SizedBox(height: 18),
        _buildResultBox(foodAmount),
      ]),
    );
  }

  Widget _buildActivitySelector() => Row(children: ["저조", "보통", "활발"].map((level) {
    bool isSelected = activityLevel == level;
    return Expanded(child: GestureDetector(onTap: () => onActivityChanged(level), child: Container(margin: const EdgeInsets.symmetric(horizontal: 5), padding: const EdgeInsets.symmetric(vertical: 14), decoration: BoxDecoration(color: isSelected ? const Color(0xFF44403B) : const Color(0xFFE7E5E4).withOpacity(0.4), borderRadius: BorderRadius.circular(14)), alignment: Alignment.center, child: Text(level, style: TextStyle(color: isSelected ? Colors.white : const Color(0xFF605A55), fontSize: 14, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)))));
  }).toList());

  Widget _buildInfoItem(String label, String value) => Column(children: [Text(label, style: const TextStyle(color: Color(0xFF605A55), fontSize: 11)), const SizedBox(height: 3), Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF44403B)))]);

  Widget _buildResultBox(int amount) => Container(width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 18), decoration: BoxDecoration(color: const Color(0xFFE7E5E4), borderRadius: BorderRadius.circular(18)), child: Column(children: [const Text("1일 권장 사료 양", style: TextStyle(color: Color(0xFF44403B), fontSize: 13, fontWeight: FontWeight.w600)), Row(mainAxisAlignment: MainAxisAlignment.center, children: [Text("$amount", style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Color(0xFF44403B))), const SizedBox(width: 4), const Text("g/일", style: TextStyle(color: Color(0xFF605A55), fontSize: 14, fontWeight: FontWeight.bold))])]));
}

// 2. 체중 추이 그래프 카드 (하은님의 탭 감지 로직 포함)
class WeightTrendCard extends StatelessWidget {
  final String petName;
  final List<Map<String, dynamic>> history;
  final double currentWeight;
  final VoidCallback onUpdate;

  const WeightTrendCard({super.key, required this.petName, required this.history, required this.currentWeight, required this.onUpdate});

  @override
  Widget build(BuildContext context) {
    double diff = history.length > 1 ? currentWeight - (history[history.length - 2]['weight'] as double) : 0;
    return Container(
      width: double.infinity, padding: const EdgeInsets.all(22), decoration: _cardDecoration(),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Row(children: [
            Container(padding: const EdgeInsets.all(8), decoration: const BoxDecoration(color: Color(0xFF605A55), shape: BoxShape.circle), child: const Icon(Icons.show_chart, color: Colors.white, size: 20)),
            const SizedBox(width: 12),
            const Text("체중 추이", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF44403B))),
          ]),
          GestureDetector(onTap: () => NutritionDialogs.showWeightDialog(context, petName, onUpdate: onUpdate), child: Container(width: 34, height: 34, decoration: const BoxDecoration(color: Color(0xFF44403B), shape: BoxShape.circle), child: const Icon(Icons.add, color: Colors.white, size: 20))),
        ]),
        const SizedBox(height: 34),
        LayoutBuilder(builder: (context, constraints) => GestureDetector(
          onTapDown: (details) {
            if (history.isEmpty) return;
            double paddingLeft = 35; double paddingBottom = 30;
            double chartWidth = constraints.maxWidth - paddingLeft; double chartHeight = 160 - paddingBottom;
            double minW = history.map((e) => e['weight'] as double).reduce(min); double maxW = history.map((e) => e['weight'] as double).reduce(max);
            if (minW == maxW) { minW -= 0.5; maxW += 0.5; }
            double xInterval = chartWidth / (history.length - 1);
            for (int i = 0; i < history.length; i++) {
              double x = paddingLeft + (i * xInterval); double y = chartHeight - ((history[i]['weight'] - minW) / (maxW - minW) * chartHeight);
              if (sqrt(pow(details.localPosition.dx - x, 2) + pow(details.localPosition.dy - y, 2)) < 25) {
                NutritionDialogs.showEditDeleteDialog(context: context, petName: petName, index: i, onUpdate: onUpdate);
                break;
              }
            }
          },
          child: SizedBox(height: 160, width: double.infinity, child: history.length < 2 ? const Center(child: Text("기록을 추가하여 추이를 확인하세요.", style: TextStyle(color: Color(0xFF605A55), fontSize: 12))) : CustomPaint(painter: MonotoneWeightChartPainter(history))),
        )),
        const SizedBox(height: 28),
        Row(children: [
          Expanded(child: _buildTrendSummary("현재 체중", "$currentWeight kg", const Color(0xFF44403B))),
          const SizedBox(width: 12),
          Expanded(child: _buildTrendSummary("변화량", "${diff >= 0 ? '+' : ''}${diff.toStringAsFixed(1)} kg", const Color(0xFF2196F3), isSkyBlue: true)),
        ]),
      ]),
    );
  }

  Widget _buildTrendSummary(String label, String value, Color color, {bool isSkyBlue = false}) => Container(padding: const EdgeInsets.symmetric(vertical: 18), decoration: BoxDecoration(color: isSkyBlue ? const Color(0xFF2196F3).withOpacity(0.06) : const Color(0xFFE7E5E4).withOpacity(0.4), borderRadius: BorderRadius.circular(22)), child: Column(children: [Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF605A55))), const SizedBox(height: 8), Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color))]));
}

// 3. 그래프 그림 그리는 도구 (Painter)
class MonotoneWeightChartPainter extends CustomPainter {
  final List<Map<String, dynamic>> history;
  MonotoneWeightChartPainter(this.history);
  @override
  void paint(Canvas canvas, Size size) {
    if (history.length < 2) return;
    const primaryColor = Color(0xFF44403B); const pointColor = Color(0xFF605A55);
    final axisPaint = Paint()..color = pointColor.withOpacity(0.12)..strokeWidth = 1;
    final linePaint = Paint()..color = primaryColor..strokeWidth = 2.8..style = PaintingStyle.stroke..strokeCap = StrokeCap.round;
    final dotPaint = Paint()..color = primaryColor..style = PaintingStyle.fill;
    double minW = history.map((e) => e['weight'] as double).reduce(min); double maxW = history.map((e) => e['weight'] as double).reduce(max);
    if (minW == maxW) { minW -= 0.5; maxW += 0.5; }
    double paddingLeft = 35; double paddingBottom = 30;
    double chartWidth = size.width - paddingLeft; double chartHeight = size.height - paddingBottom;
    canvas.drawLine(Offset(paddingLeft, 0), Offset(paddingLeft, chartHeight), axisPaint);
    canvas.drawLine(Offset(paddingLeft, chartHeight), Offset(size.width, chartHeight), axisPaint);
    for (int i = 0; i <= 3; i++) { double yVal = minW + (maxW - minW) * i / 3; double yPos = chartHeight - (i / 3 * chartHeight); _drawText(canvas, yVal.toStringAsFixed(1), Offset(0, yPos - 7), pointColor); }
    double xInterval = chartWidth / (history.length - 1); Path path = Path();
    for (int i = 0; i < history.length; i++) {
      double x = paddingLeft + (i * xInterval); double weight = history[i]['weight']; double y = chartHeight - ((weight - minW) / (maxW - minW) * chartHeight);
      if (i == 0) path.moveTo(x, y); else path.lineTo(x, y);
      if (i > 0) { String dateStr = DateFormat('M/d').format(history[i]['date']); _drawText(canvas, dateStr, Offset(x - 12, chartHeight + 10), pointColor, fontSize: 10); }
      canvas.drawCircle(Offset(x, y), 3.8, dotPaint);
    }
    canvas.drawPath(path, linePaint);
  }
  void _drawText(Canvas canvas, String text, Offset offset, Color color, {double fontSize = 11}) { final textPainter = TextPainter(text: TextSpan(text: text, style: TextStyle(color: color, fontSize: fontSize, fontWeight: FontWeight.w500)), textDirection: ui.TextDirection.ltr); textPainter.layout(); textPainter.paint(canvas, offset); }
  @override bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

BoxDecoration _cardDecoration() => BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(28), boxShadow: [BoxShadow(color: const Color(0xFF44403B).withOpacity(0.04), blurRadius: 12, offset: const Offset(0, 6))]);