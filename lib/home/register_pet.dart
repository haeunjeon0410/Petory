import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

class PetRegistrationDialog extends StatefulWidget {
  final Map<String, dynamic>? existingData;

  const PetRegistrationDialog({super.key, this.existingData});

  @override
  State<PetRegistrationDialog> createState() => _PetRegistrationDialogState();
}

class _PetRegistrationDialogState extends State<PetRegistrationDialog> {
  // 컨트롤러
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _speciesController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _heightController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();

  // 상태 변수
  String _petType = "강아지"; // [추가] 기본값 강아지
  String? _gender;
  bool? _isNeutered;
  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    // 수정 모드일 때 기존 데이터 채우기
    if (widget.existingData != null) {
      final data = widget.existingData!;
      _nameController.text = data['name'] ?? '';
      _speciesController.text = data['species'] ?? '';
      _ageController.text = data['age'] ?? '';
      _heightController.text = data['height'] ?? '';
      _weightController.text = data['weight'] ?? '';
      _gender = data['gender'];
      _isNeutered = data['isNeutered'];
      _petType = data['type'] ?? "강아지"; // 저장된 타입 불러오기

      if (data['image'] != null && data['image'] is File) {
        _selectedImage = data['image'];
      }
    }
  }

  Future<void> _pickImage() async {
    final XFile? pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
    );
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isEditing = widget.existingData != null;

    // 팝업 창 내부 디자인
    return Container(
      height: MediaQuery.of(context).size.height * 0.85, // 높이 제한
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      clipBehavior: Clip.hardEdge, // 둥근 모서리 적용
      child: Column(
        children: [
          // 1. 헤더 (갈색 테마)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            decoration: const BoxDecoration(
              color: Color(0xFF44403B), // 갈색 배경
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  isEditing ? "반려동물 정보 수정" : "새 반려동물 등록",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Icon(Icons.close, color: Colors.white, size: 24),
                ),
              ],
            ),
          ),

          // 2. 입력 폼 (스크롤 가능)
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // (1) 사진 업로드
                  Center(
                    child: GestureDetector(
                      onTap: _pickImage,
                      child: Column(
                        children: [
                          Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F2ED), // 크림색 배경
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: const Color(0xFFF1F2ED),
                                width: 2,
                              ),
                              image: _selectedImage != null
                                  ? DecorationImage(
                                      image: FileImage(_selectedImage!),
                                      fit: BoxFit.cover,
                                    )
                                  : null,
                            ),
                            child: _selectedImage == null
                                ? const Icon(
                                    Icons.camera_alt,
                                    color: Color(0xFF44403B),
                                    size: 40,
                                  )
                                : null,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _selectedImage == null ? "사진 등록" : "사진 변경",
                            style: const TextStyle(
                              color: Color(0xFF44403B),
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),

                  // (2) 강아지/고양이 선택 (드롭다운)
                  _buildLabel("종류 *"),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F2ED),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFF1F2ED)),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        dropdownColor: const Color(0xFFF1F2ED),
                        borderRadius: BorderRadius.circular(12),
                        value: _petType,
                        isExpanded: true,
                        icon: const Icon(
                          Icons.arrow_drop_down,
                          color: Color(0xFF44403B),
                        ),
                        items: ["강아지", "고양이"].map((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(
                              value,
                              style: const TextStyle(color: Colors.black87),
                            ),
                          );
                        }).toList(),
                        onChanged: (newValue) {
                          setState(() {
                            _petType = newValue!;
                          });
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // (3) 이름
                  _buildLabel("이름 *"),
                  _buildTextField(_nameController, "예: 초코"),
                  const SizedBox(height: 20),

                  // (4) 품종
                  _buildLabel("품종"),
                  _buildTextField(_speciesController, "예: 골든 리트리버"),
                  const SizedBox(height: 20),

                  // (5) 나이
                  _buildLabel("나이 (살) *"),
                  _buildTextField(_ageController, "예: 3", isNumber: true),
                  const SizedBox(height: 20),

                  // (6) 성별
                  _buildLabel("성별 *"),
                  Row(
                    children: [
                      Expanded(
                        child: _buildSelectButton(
                          text: "수컷 ♂",
                          isSelected: _gender == 'male',
                          onTap: () => setState(() => _gender = 'male'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildSelectButton(
                          text: "암컷 ♀",
                          isSelected: _gender == 'female',
                          onTap: () => setState(() => _gender = 'female'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // (7) 키
                  _buildLabel("키 (cm)"),
                  _buildTextField(_heightController, "예: 60.5", isNumber: true),
                  const SizedBox(height: 20),

                  // (8) 체중
                  _buildLabel("체중 (kg) *"),
                  _buildTextField(_weightController, "예: 32.4", isNumber: true),
                  const SizedBox(height: 20),

                  // (9) 중성화 여부
                  _buildLabel("중성화 여부"),
                  Row(
                    children: [
                      Expanded(
                        child: _buildSelectButton(
                          text: "O",
                          isSelected: _isNeutered == true,
                          onTap: () => setState(() => _isNeutered = true),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildSelectButton(
                          text: "X",
                          isSelected: _isNeutered == false,
                          onTap: () => setState(() => _isNeutered = false),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 40),

                  // 등록 완료 버튼
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: () {
                        if (_nameController.text.isNotEmpty) {
                          Navigator.pop(context, {
                            "name": _nameController.text,
                            "type": _petType,
                            "species": _speciesController.text,
                            "age": _ageController.text,
                            "height": _heightController.text,
                            "weight": _weightController.text,
                            "gender": _gender,
                            "isNeutered": _isNeutered,
                            "image": _selectedImage,
                          });
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF44403B), // 갈색 버튼
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        isEditing ? "수정완료" : "등록하기",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- 위젯 빌더 ---

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: RichText(
        text: TextSpan(
          text: text.replaceAll('*', ''),
          style: const TextStyle(
            color: Color(0xFF44403B), // 텍스트 색상 갈색
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
          children: [
            if (text.contains('*'))
              const TextSpan(
                text: ' *',
                style: TextStyle(color: Colors.redAccent),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String hint, {
    bool isNumber = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        keyboardType: isNumber
            ? const TextInputType.numberWithOptions(decimal: true)
            : TextInputType.text,
        inputFormatters: isNumber
            ? [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d*'))]
            : [],
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFF1F2ED)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(
              color: Color(0xFF44403B),
              width: 1.5,
            ), // 포커스 색상 갈색
          ),
          fillColor: const Color(0xFFF1F2ED),
          filled: true,
        ),
      ),
    );
  }

  Widget _buildSelectButton({
    required String text,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF44403B) : const Color(0xFFF1F2ED),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Colors.transparent : const Color(0xFFF1F2ED),
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          text,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black54,
            fontSize: 16,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
