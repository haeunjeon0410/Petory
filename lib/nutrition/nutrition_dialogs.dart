import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // [필수] 입력 제한(Formatter) 사용을 위해 추가
import '../record/record_data.dart' as record;

class NutritionDialogs {
  static void showWeightDialog(
    BuildContext context,
    String petId,
    DateTime date, {
    required VoidCallback onUpdate,
  }) {
    final TextEditingController weightController = TextEditingController();
    final FocusNode focusNode = FocusNode(); // 포커스 제어를 위한 노드

    // 기존 데이터가 있다면 불러오기
    if (record.weightHistory[petId] != null) {
      var existing = record.weightHistory[petId]!.firstWhere((e) {
        DateTime d = e['date'];
        return d.year == date.year &&
            d.month == date.month &&
            d.day == date.day;
      }, orElse: () => {});
      if (existing.isNotEmpty) {
        weightController.text = existing['weight'].toString();
      }
    }

    showDialog(
      context: context,
      builder: (context) {
        // [수정] 에러 메시지를 담을 변수 (null이면 에러 없음)
        String? errorMsg;

        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: const Text(
                "체중 등록",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 10),
                  TextField(
                    controller: weightController,
                    focusNode: focusNode,
                    maxLength: 6,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    cursorColor: Colors.black, // 커서 색상 검은색 고정
                    // 숫자와 소수점만 입력 가능하도록 제한
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                    ],

                    decoration: InputDecoration(
                      hintText: "체중을 입력해주세요 (kg)",
                      counterText: "",
                      filled: true,
                      fillColor: const Color(0xFFF5F5F0),

                      // [수정] 에러 메시지가 있으면 자동으로 빨간 테두리와 문구가 표시됨
                      errorText: errorMsg,

                      // 평소 테두리 (없음)
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),

                      // 포커스 됐을 때 테두리 (없음)
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),

                      // [추가] 에러 발생 시 테두리 (빨간색)
                      errorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: Colors.red,
                          width: 1.5,
                        ),
                      ),

                      // [추가] 에러 상태에서 포커스 시 테두리 (빨간색)
                      focusedErrorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: Colors.red,
                          width: 1.5,
                        ),
                      ),

                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                    ),

                    // 입력 시작하면 에러 메시지 초기화
                    onChanged: (value) {
                      if (errorMsg != null) {
                        setState(() {
                          errorMsg = null;
                        });
                      }
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("취소", style: TextStyle(color: Colors.grey)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF44403B),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                  ),
                  onPressed: () {
                    final String text = weightController.text.trim();
                    final double? newWeight = double.tryParse(text);

                    // [로직 수정] 상황별 에러 메시지 설정
                    if (text.isEmpty) {
                      setState(() {
                        errorMsg = "체중을 입력해주세요.";
                      });
                      FocusScope.of(context).requestFocus(focusNode);
                    } else if (newWeight == null) {
                      setState(() {
                        errorMsg = "숫자만 입력해주세요.";
                      });
                      FocusScope.of(context).requestFocus(focusNode);
                    } else if (newWeight >= 1000) {
                      // [요청 사항] 1000kg 이상일 때 안내 문구
                      setState(() {
                        errorMsg = "1000kg 미만으로 입력해주세요.";
                      });
                      FocusScope.of(context).requestFocus(focusNode);
                    } else {
                      // 정상 입력
                      if (record.weightHistory[petId] == null) {
                        record.weightHistory[petId] = [];
                      }

                      // 해당 날짜의 기존 기록 삭제 (덮어쓰기)
                      record.weightHistory[petId]!.removeWhere((item) {
                        DateTime d = item['date'];
                        return d.year == date.year &&
                            d.month == date.month &&
                            d.day == date.day;
                      });

                      // 새 기록 추가
                      record.weightHistory[petId]!.add({
                        "date": date,
                        "weight": newWeight,
                      });

                      onUpdate();
                      Navigator.pop(context);
                    }
                  },
                  child: const Text(
                    "확인",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
