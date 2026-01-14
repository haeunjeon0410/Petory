import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CommonTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final bool isNumber;
  final bool noSpecialChars;
  final int maxLines;
  final VoidCallback? onTap;
  final bool readOnly;
  final int? maxLength;

  final String? errorText;
  final FocusNode? focusNode;
  final Key? fieldKey;

  const CommonTextField({
    super.key,
    required this.controller,
    required this.hint,
    this.isNumber = false,
    this.noSpecialChars = false,
    this.maxLines = 1,
    this.onTap,
    this.readOnly = false,
    this.maxLength,
    this.errorText,
    this.focusNode,
    this.fieldKey,
  });

  @override
  Widget build(BuildContext context) {
    bool hasError = errorText != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. 입력창
        Container(
          key: fieldKey,
          // [수정 1] 컨테이너가 자식(TextField)의 둥근 모서리를 넘지 않도록 자름
          clipBehavior: Clip.hardEdge,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: TextField(
            controller: controller,
            focusNode: focusNode,
            cursorColor: const Color(0xFF44403B),
            keyboardType: isNumber
                ? const TextInputType.numberWithOptions(decimal: true)
                : TextInputType.text,
            inputFormatters: [
              // 1. 숫자만 허용하는 경우
              if (isNumber)
                FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d*')),

              // 2. [추가] 특수문자를 제한하는 경우 (한글, 영어, 숫자, 띄어쓰기만 허용)
              if (noSpecialChars)
                FilteringTextInputFormatter.allow(
                  RegExp(r'[a-zA-Z0-9ㄱ-ㅎㅏ-ㅣ가-힣 ]'),
                ),
            ],
            onTap: onTap,
            maxLines: maxLines,
            maxLength: maxLength,
            readOnly: readOnly,

            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(
                color: Color(0xFF605A55),
                fontSize: 14,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
              counterText: "",
              errorText: null,

              // 평소 테두리
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: hasError ? Colors.red : Colors.transparent,
                  // [수정 2] 에러 상태일 때 두께를 1.5로 고정 (기존 1.0 -> 1.5)
                  width: hasError ? 1.5 : 1.0,
                ),
              ),

              // 포커스 됐을 때 테두리
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: hasError ? Colors.red : const Color(0xFF44403B),
                  width: 1.5,
                ),
              ),

              fillColor: Colors.white,
              filled: true,
            ),
          ),
        ),

        // 2. 에러 메시지
        if (hasError)
          Padding(
            padding: const EdgeInsets.only(top: 6, left: 12),
            child: Text(
              errorText!,
              style: const TextStyle(
                color: Colors.red,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
      ],
    );
  }
}
