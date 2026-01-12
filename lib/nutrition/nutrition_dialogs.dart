import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import '../record/record_data.dart' as record;

class NutritionDialogs {
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
        titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
        title: Text(editIndex == null ? '체중 등록' : '날짜 수정',
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
            if (weightController.text.isNotEmpty) {
              _saveData(petName, selectedDate, weightController.text, editIndex, onUpdate, context);
            }
          }),
        ],
      ),
    );
  }

  static void _showCalendarPicker(BuildContext context, String petName, {int? editIndex, required VoidCallback onUpdate, required DateTime currentDate, required String currentWeight}) {
    DateTime tempDate = currentDate;
    final pointColor = const Color(0xFF44403B);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFFF1F2ED),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
          titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
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
                    sixWeekMonthsEnforced: true, // ⭐ 주차에 상관없이 6주로 높이 고정
                    headerStyle: HeaderStyle(
                      formatButtonVisible: false,
                      titleCentered: true,
                      titleTextStyle: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: pointColor),
                      leftChevronIcon: Icon(Icons.chevron_left, size: 20, color: pointColor),
                      rightChevronIcon: Icon(Icons.chevron_right, size: 20, color: pointColor),
                    ),
                    rowHeight: 48,
                    daysOfWeekHeight: 35,
                    calendarStyle: CalendarStyle(
                      selectedDecoration: BoxDecoration(color: pointColor, shape: BoxShape.circle),
                      cellMargin: const EdgeInsets.all(6),
                      selectedTextStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                      todayDecoration: BoxDecoration(color: pointColor.withOpacity(0.1), shape: BoxShape.circle),
                      todayTextStyle: TextStyle(color: pointColor, fontWeight: FontWeight.bold, fontSize: 13),
                      defaultTextStyle: const TextStyle(fontSize: 13, color: Color(0xFF44403B)),
                      weekendTextStyle: const TextStyle(fontSize: 13),
                      outsideDaysVisible: false,
                    ),
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
                    onDaySelected: (selectedDay, focusedDay) {
                      setDialogState(() => tempDate = selectedDay);
                    },
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
    if (editIndex == null) {
      record.weightHistory[petName]!.add({"date": date, "weight": newWeight});
    } else {
      record.weightHistory[petName]![editIndex] = {"date": date, "weight": newWeight};
    }
    record.weightHistory[petName]!.sort((a, b) => a['date'].compareTo(b['date']));
    record.petProfiles[petName]?['weight'] = record.weightHistory[petName]!.last['weight'].toString();
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
        child: Text(
          label,
          style: TextStyle(
            color: isPrimary ? Colors.white : const Color(0xFF605A55),
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
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