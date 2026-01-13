import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../record/record_data.dart' as record;
import '../home/widgets/common_text_field.dart'; // CommonTextField 위치에 맞게 경로 수정 필요
import '../shared/app_dialog_style.dart';

class NutritionDialogs {
  // [체중 등록 다이얼로그]
  static void showWeightDialog(
    BuildContext context,
    String petName, {
    DateTime? initialDate,
    required VoidCallback onUpdate,
  }) {
    DateTime selectedDate = initialDate ?? DateTime.now();
    TextEditingController weightController = TextEditingController();
    FocusNode weightFocus = FocusNode();

    showDialog(
      context: context,
      builder: (context) {
        String? errorText;

        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              backgroundColor: AppDialogStyle.background,
              shape: AppDialogStyle.shape(),
              insetPadding: AppDialogStyle.insetPadding,
              child: Padding(
                padding: AppDialogStyle.contentPadding,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "체중 등록",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppDialogStyle.text,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // 날짜 선택
                    GestureDetector(
                      onTap: () async {
                        DateTime? picked = await showDatePicker(
                          context: context,
                          initialDate: selectedDate,
                          firstDate: DateTime(2020),
                          lastDate: DateTime.now(),
                          builder: (context, child) {
                            return Theme(
                              data: Theme.of(context).copyWith(
                                colorScheme: const ColorScheme.light(
                                  primary: Color(0xFF44403B),
                                  onPrimary: Colors.white,
                                  onSurface: Color(0xFF44403B),
                                ),
                              ),
                              child: child!,
                            );
                          },
                        );
                        if (picked != null) {
                          setState(() => selectedDate = picked);
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE7E5E4)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              DateFormat('yyyy. MM. dd').format(selectedDate),
                              style: const TextStyle(
                                color: AppDialogStyle.text,
                              ),
                            ),
                            const Icon(
                              Icons.calendar_today,
                              size: 16,
                              color: AppDialogStyle.mutedText,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // 체중 입력 필드 (CommonTextField 사용)
                    CommonTextField(
                      controller: weightController,
                      focusNode: weightFocus,
                      hint: "체중을 입력해주세요",
                      isNumber: true, // 숫자와 소수점만 입력 허용
                      maxLength: 6,
                      errorText: errorText,
                    ),

                    const SizedBox(height: 24),

                    // 버튼 영역
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text(
                            "취소",
                            style: TextStyle(color: AppDialogStyle.mutedText),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () {
                            // [검증 로직]
                            String text = weightController.text.trim();

                            if (text.isEmpty) {
                              setState(() => errorText = "체중을 입력해주세요");
                              weightFocus.requestFocus();
                              return;
                            }

                            double? w = double.tryParse(text);
                            if (w == null) {
                              setState(() => errorText = "숫자만 입력해주세요");
                              weightFocus.requestFocus();
                              return;
                            }

                            if (w >= 1000) {
                              setState(
                                () => errorText = "체중은 1000kg 미만이어야 합니다",
                              );
                              weightFocus.requestFocus();
                              return;
                            }

                            // 저장 로직
                            String currentId = record.selectedPetId;
                            if (record.weightHistory[currentId] == null) {
                              record.weightHistory[currentId] = [];
                            }

                            // 같은 날짜 중복 제거
                            record.weightHistory[currentId]!.removeWhere((h) {
                              DateTime d = h['date'];
                              return d.year == selectedDate.year &&
                                  d.month == selectedDate.month &&
                                  d.day == selectedDate.day;
                            });

                            record.weightHistory[currentId]!.add({
                              "date": selectedDate,
                              "weight": w,
                            });

                            onUpdate(); // 화면 갱신 콜백 호출
                            Navigator.pop(context);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppDialogStyle.text,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                          ),
                          child: const Text(
                            "확인",
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // [편집/삭제 다이얼로그] - WeightTrendCard에서 그래프 클릭 시 사용됨
  static void showEditDeleteDialog({
    required BuildContext context,
    required String petName,
    required int index,
    required VoidCallback onUpdate,
  }) {
    String currentId = record.selectedPetId;
    List<Map<String, dynamic>> history = record.weightHistory[currentId] ?? [];
    if (index < 0 || index >= history.length) return;

    Map<String, dynamic> data = history[index];
    DateTime selectedDate = data['date'];
    TextEditingController weightController = TextEditingController(
      text: data['weight'].toString(),
    );
    FocusNode weightFocus = FocusNode();

    showDialog(
      context: context,
      builder: (context) {
        String? errorText;

        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              backgroundColor: AppDialogStyle.background,
              shape: AppDialogStyle.shape(),
              insetPadding: AppDialogStyle.insetPadding,
              child: Padding(
                padding: AppDialogStyle.contentPadding,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      "기록 수정",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppDialogStyle.text,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // CommonTextField 사용
                    CommonTextField(
                      controller: weightController,
                      focusNode: weightFocus,
                      hint: "체중 (kg)",
                      isNumber: true,
                      maxLength: 6,
                      errorText: errorText,
                    ),

                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        TextButton(
                          onPressed: () {
                            record.weightHistory[currentId]!.removeAt(index);
                            onUpdate();
                            Navigator.pop(context);
                          },
                          child: const Text(
                            "삭제",
                            style: TextStyle(color: Colors.red),
                          ),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            String text = weightController.text.trim();

                            if (text.isEmpty) {
                              setState(() => errorText = "체중을 입력해주세요");
                              weightFocus.requestFocus();
                              return;
                            }

                            double? w = double.tryParse(text);
                            if (w == null) {
                              setState(() => errorText = "숫자만 입력해주세요");
                              weightFocus.requestFocus();
                              return;
                            }

                            if (w >= 1000) {
                              setState(
                                () => errorText = "체중은 1000kg 미만이어야 합니다",
                              );
                              weightFocus.requestFocus();
                              return;
                            }

                            record.weightHistory[currentId]![index] = {
                              "date": selectedDate,
                              "weight": w,
                            };
                            onUpdate();
                            Navigator.pop(context);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppDialogStyle.text,
                          ),
                          child: const Text(
                            "수정",
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
