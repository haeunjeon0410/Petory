import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../record/record_data.dart' as record;

class NutritionDialogs {
  // 1. 관리 메뉴 (수정/삭제 선택)
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
        insetPadding: const EdgeInsets.symmetric(horizontal: 50),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("기록 관리", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF44403B))),
              const SizedBox(height: 24),
              _buildCompactMenuButton(
                label: "수정하기",
                icon: Icons.edit_outlined,
                onTap: () {
                  Navigator.pop(context);
                  showWeightDialog(context, petName, editIndex: index, onUpdate: onUpdate);
                },
              ),
              const SizedBox(height: 12),
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

  // 2. 체중 등록/수정 입력창
  static void showWeightDialog(BuildContext context, String petName, {int? editIndex, required VoidCallback onUpdate}) {
    TextEditingController weightController = TextEditingController();
    DateTime selectedDate = DateTime.now();

    if (editIndex != null) {
      weightController.text = record.weightHistory[petName]![editIndex]['weight'].toString();
      selectedDate = record.weightHistory[petName]![editIndex]['date'];
    }

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFFF1F2ED),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
          titlePadding: const EdgeInsets.fromLTRB(28, 28, 28, 0),
          title: Text(editIndex == null ? '체중 등록' : '날짜 수정',
              style: const TextStyle(color: Color(0xFF44403B), fontSize: 18, fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              GestureDetector(
                onTap: () async {
                  final DateTime? picked = await showDatePicker(
                    context: context,
                    initialDate: selectedDate,
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now(),
                    builder: (context, child) => Theme(
                      data: Theme.of(context).copyWith(
                        colorScheme: const ColorScheme.light(primary: Color(0xFF44403B), onPrimary: Colors.white, surface: Color(0xFFF1F2ED), onSurface: Color(0xFF44403B)),
                        datePickerTheme: DatePickerThemeData(backgroundColor: const Color(0xFFF1F2ED), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)), headerBackgroundColor: const Color(0xFF44403B), headerForegroundColor: Colors.white),
                      ),
                      child: child!,
                    ),
                  );
                  if (picked != null) setDialogState(() => selectedDate = picked);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(DateFormat('yyyy. MM. dd').format(selectedDate), style: const TextStyle(color: Color(0xFF44403B), fontSize: 14)),
                      const Icon(Icons.calendar_today_rounded, size: 14, color: Color(0xFF605A55)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: weightController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(hintText: "0.0 kg", filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none)),
              ),
            ],
          ),
          actionsPadding: const EdgeInsets.fromLTRB(0, 0, 24, 24),
          actions: [
            _buildSmallButton(label: "취소", isPrimary: false, onTap: () => Navigator.pop(context)),
            const SizedBox(width: 8),
            _buildSmallButton(label: editIndex == null ? "확인" : "변경", isPrimary: true, onTap: () {
              if (weightController.text.isNotEmpty) {
                double newWeight = double.parse(weightController.text);
                if (editIndex == null) {
                  record.weightHistory.putIfAbsent(petName, () => []);
                  record.weightHistory[petName]!.add({"date": selectedDate, "weight": newWeight});
                } else {
                  record.weightHistory[petName]![editIndex] = {"date": selectedDate, "weight": newWeight};
                }
                record.weightHistory[petName]!.sort((a, b) => a['date'].compareTo(b['date']));
                record.petProfiles[petName]?['weight'] = record.weightHistory[petName]!.last['weight'].toString();
                onUpdate();
                Navigator.pop(context);
              }
            }),
          ],
        ),
      ),
    );
  }

  // 3. 삭제 확인 팝업
  static void _confirmDelete(BuildContext context, String petName, int index, VoidCallback onUpdate) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFFF1F2ED),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
        title: const Text("삭제", style: TextStyle(color: Color(0xFF44403B), fontWeight: FontWeight.bold)),
        content: const Text("기록을 정말 삭제할까요?", style: TextStyle(color: Color(0xFF605A55), fontSize: 14)),
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

  // UI 헬퍼 버튼들
  static Widget _buildCompactMenuButton({required String label, required IconData icon, bool isDelete = false, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFE7E5E4))),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, size: 18, color: isDelete ? Colors.redAccent : const Color(0xFF44403B)),
          const SizedBox(width: 10),
          Text(label, style: TextStyle(color: isDelete ? Colors.redAccent : const Color(0xFF44403B), fontWeight: FontWeight.bold, fontSize: 14)),
        ]),
      ),
    );
  }

  static Widget _buildSmallButton({required String label, required VoidCallback onTap, required bool isPrimary}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(color: isPrimary ? const Color(0xFF44403B) : Colors.white, borderRadius: BorderRadius.circular(14), border: isPrimary ? null : Border.all(color: const Color(0xFFE7E5E4))),
        child: Text(label, style: TextStyle(color: isPrimary ? Colors.white : const Color(0xFF605A55), fontWeight: FontWeight.bold, fontSize: 14)),
      ),
    );
  }
}