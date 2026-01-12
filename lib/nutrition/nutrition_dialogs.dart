import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import '../record/record_data.dart' as record;

class NutritionDialogs {
  // 기록 관리 (수정/삭제 선택) 다이얼로그
  static void showEditDeleteDialog({
    required BuildContext context,
    required String petName,
    required int index,
    required VoidCallback onUpdate,
  }) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: const Color(0xFFF1F2ED),
        insetPadding: const EdgeInsets.symmetric(horizontal: 70),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("기록 관리", style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF44403B))),
              const SizedBox(height: 20),
              _buildCompactMenuButton(
                label: "수정하기",
                icon: Icons.edit_outlined,
                onTap: () {
                  Navigator.pop(context);
                  showWeightDialog(context, petName, editIndex: index, onUpdate: onUpdate);
                },
              ),
              const SizedBox(height: 10),
              _buildCompactMenuButton(
                label: "삭제하기",
                icon: Icons.delete_outline_rounded,
                isDelete: true,
                onTap: () {
                  Navigator.pop(context);
                  _confirmDelete(context, petName, index, onUpdate);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 체중 입력 다이얼로그
  static void showWeightDialog(BuildContext context, String petName, {int? editIndex, required VoidCallback onUpdate, DateTime? initialDate, String? initialWeight}) {
    TextEditingController weightController = TextEditingController(text: initialWeight);
    DateTime selectedDate = initialDate ?? DateTime.now();

    if (editIndex != null && initialDate == null && initialWeight == null) {
      weightController.text = record.weightHistory[petName]![editIndex]['weight'].toString();
      selectedDate = record.weightHistory[petName]![editIndex]['date'];
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFFF1F2ED),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
        title: Text(editIndex == null ? '체중 등록' : '기록 수정',
            style: const TextStyle(color: Color(0xFF44403B), fontSize: 16, fontWeight: FontWeight.bold)),
        content: SizedBox(
          width: 230,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              GestureDetector(
                onTap: () {
                  Navigator.pop(context);
                  _showCalendarPicker(context, petName, editIndex: editIndex, onUpdate: onUpdate, currentDate: selectedDate, currentWeight: weightController.text);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(DateFormat('yyyy. MM. dd').format(selectedDate), style: const TextStyle(color: Color(0xFF44403B), fontSize: 13)),
                      const Icon(Icons.calendar_today_rounded, size: 13, color: Color(0xFF605A55)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: weightController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                style: const TextStyle(fontSize: 13),
                // 소수점 2자리까지만 입력 가능하도록 제한
                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}'))],
                decoration: InputDecoration(
                  hintText: "체중을 입력해주세요",
                  hintStyle: const TextStyle(color: Color(0xFFA8A29E), fontSize: 12),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                ),
              ),
            ],
          ),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(0, 0, 16, 16),
        actions: [
          _buildSmallButton(label: "취소", isPrimary: false, onTap: () => Navigator.pop(context)),
          _buildSmallButton(label: editIndex == null ? "확인" : "변경", isPrimary: true, onTap: () {
            final input = weightController.text;
            if (input.isNotEmpty && double.tryParse(input) != null) {
              _saveData(petName, selectedDate, input, editIndex, onUpdate, context);
            }
          }),
        ],
      ),
    );
  }

  // 날짜 선택 달력 다이얼로그
  static void _showCalendarPicker(BuildContext context, String petName, {int? editIndex, required VoidCallback onUpdate, required DateTime currentDate, required String currentWeight}) {
    DateTime tempDate = currentDate;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFFF1F2ED),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
          title: const Text('날짜 선택', style: TextStyle(color: Color(0xFF44403B), fontSize: 16, fontWeight: FontWeight.bold)),
          content: SizedBox(
            width: MediaQuery.of(context).size.width * 0.85,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 16),
                Container(
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
                  padding: const EdgeInsets.only(bottom: 8),
                  child: TableCalendar(
                    locale: 'ko_KR',
                    firstDay: DateTime.utc(2020, 1, 1),
                    lastDay: DateTime.now(),
                    focusedDay: tempDate,
                    selectedDayPredicate: (day) => isSameDay(tempDate, day),
                    headerStyle: const HeaderStyle(formatButtonVisible: false, titleCentered: true),
                    calendarStyle: const CalendarStyle(
                      selectedDecoration: BoxDecoration(color: Color(0xFF44403B), shape: BoxShape.circle),
                      // 오늘 날짜 디자인: 연한 회색
                      todayDecoration: BoxDecoration(color: Color(0xFFE7E5E4), shape: BoxShape.circle),
                      todayTextStyle: TextStyle(color: Color(0xFF44403B), fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    // 토요일(파랑), 일요일(빨강) 색상 수정
                    calendarBuilders: CalendarBuilders(
                      dowBuilder: (context, day) {
                        if (day.weekday == DateTime.sunday) return const Center(child: Text('일', style: TextStyle(color: Colors.red, fontSize: 13, fontWeight: FontWeight.w500)));
                        if (day.weekday == DateTime.saturday) return const Center(child: Text('토', style: TextStyle(color: Colors.blue, fontSize: 13, fontWeight: FontWeight.w500)));
                        return null;
                      },
                      defaultBuilder: (context, day, focusedDay) {
                        if (day.weekday == DateTime.sunday) return Center(child: Text('${day.day}', style: const TextStyle(color: Colors.red, fontSize: 13)));
                        if (day.weekday == DateTime.saturday) return Center(child: Text('${day.day}', style: const TextStyle(color: Colors.blue, fontSize: 13)));
                        return null;
                      },
                    ),
                    onDaySelected: (selectedDay, focusedDay) => setDialogState(() => tempDate = selectedDay),
                  ),
                ),
              ],
            ),
          ),
          actionsPadding: const EdgeInsets.fromLTRB(0, 0, 16, 16),
          actions: [
            _buildSmallButton(label: "취소", isPrimary: false, onTap: () {
              Navigator.pop(context);
              showWeightDialog(context, petName, editIndex: editIndex, onUpdate: onUpdate, initialDate: currentDate, initialWeight: currentWeight);
            }),
            _buildSmallButton(label: "확인", isPrimary: true, onTap: () {
              Navigator.pop(context);
              showWeightDialog(context, petName, editIndex: editIndex, onUpdate: onUpdate, initialDate: tempDate, initialWeight: currentWeight);
            }),
          ],
        ),
      ),
    );
  }

  static void _saveData(String petName, DateTime date, String weightStr, int? editIndex, VoidCallback onUpdate, BuildContext context) {
    double newWeight = double.tryParse(weightStr) ?? 0.0;
    List<Map<String, dynamic>> history = record.weightHistory[petName] ?? [];

    // 동일한 날짜 중복 추가 금지 (수정 시에는 본인 인덱스 제외)
    bool isDuplicate = history.asMap().entries.any((entry) {
      if (editIndex != null && entry.key == editIndex) return false;
      return isSameDay(entry.value['date'], date);
    });

    if (isDuplicate) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("해당 날짜에 이미 기록이 있습니다.")));
      return;
    }

    if (editIndex == null) {
      history.add({"date": date, "weight": newWeight});
    } else {
      history[editIndex] = {"date": date, "weight": newWeight};
    }

    // 날짜별 재정렬 (꺾은선 그래프 꼬임 방지)
    history.sort((a, b) => (a['date'] as DateTime).compareTo(b['date'] as DateTime));
    record.petProfiles[petName]?['weight'] = history.last['weight'].toString();

    onUpdate();
    Navigator.pop(context);
  }

  static Widget _buildSmallButton({required String label, required VoidCallback onTap, required bool isPrimary}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isPrimary ? const Color(0xFF44403B) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: isPrimary ? null : Border.all(color: const Color(0xFFE7E5E4)),
        ),
        child: Text(label, style: TextStyle(color: isPrimary ? Colors.white : const Color(0xFF605A55), fontWeight: FontWeight.bold, fontSize: 12)),
      ),
    );
  }

  static Widget _buildCompactMenuButton({required String label, required IconData icon, bool isDelete = false, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFFE7E5E4))),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, size: 16, color: isDelete ? Colors.redAccent : const Color(0xFF44403B)),
          const SizedBox(width: 8),
          Text(label, style: TextStyle(color: isDelete ? Colors.redAccent : const Color(0xFF44403B), fontWeight: FontWeight.bold, fontSize: 13)),
        ]),
      ),
    );
  }

  static void _confirmDelete(BuildContext context, String petName, int index, VoidCallback onUpdate) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFFF1F2ED),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
        title: const Text("삭제", style: TextStyle(color: Color(0xFF44403B), fontWeight: FontWeight.bold, fontSize: 16)),
        content: const Text("기록을 정말 삭제할까요?", style: TextStyle(color: Color(0xFF605A55), fontSize: 13)),
        actionsPadding: const EdgeInsets.fromLTRB(0, 0, 16, 16),
        actions: [
          _buildSmallButton(label: "취소", isPrimary: false, onTap: () => Navigator.pop(context)),
          _buildSmallButton(label: "삭제", isPrimary: true, onTap: () {
            record.weightHistory[petName]!.removeAt(index);
            if (record.weightHistory[petName]!.isNotEmpty) {
              record.petProfiles[petName]?['weight'] = record.weightHistory[petName]!.last['weight'].toString();
            }
            onUpdate();
            Navigator.pop(context);
          }),
        ],
      ),
    );
  }
}