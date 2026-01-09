import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

class PetRegistrationPage extends StatefulWidget {
  // [수정 1] 기존 데이터를 받을 수 있도록 변수와 생성자 추가
  final Map<String, dynamic>? existingData;

  const PetRegistrationPage({super.key, this.existingData});

  @override
  State<PetRegistrationPage> createState() => _PetRegistrationPageState();
}

class _PetRegistrationPageState extends State<PetRegistrationPage> {
  final TextEditingController _speciesController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _heightController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();

  String? _gender;
  bool? _isNeutered;
  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    // [수정 2] 만약 수정 모드라면(existingData가 있다면), 텍스트 필드에 기존 값 채워 넣기
    if (widget.existingData != null) {
      final data = widget.existingData!;
      _nameController.text = data['name'] ?? '';
      _speciesController.text = data['species'] ?? '';
      _ageController.text = data['age'] ?? '';
      _heightController.text = data['height'] ?? '';
      _weightController.text = data['weight'] ?? '';
      _gender = data['gender'];
      _isNeutered = data['isNeutered'];

      // 이미지가 파일 형태로 저장되어 있었다면 불러오기
      if (data['image'] != null && data['image'] is File) {
        _selectedImage = data['image'];
      }
    }
  }

  @override
  void dispose() {
    _speciesController.dispose();
    _nameController.dispose();
    _ageController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    super.dispose();
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
    // 수정 모드인지 확인
    bool isEditing = widget.existingData != null;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // 헤더
          Container(
            padding: const EdgeInsets.only(
              top: 50,
              bottom: 20,
              left: 20,
              right: 20,
            ),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFE040FB), Color(0xFF9C27B0)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  isEditing ? "프로필 수정" : "새 반려동물 등록", // [수정 3] 제목 변경
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Icon(Icons.close, color: Colors.white, size: 28),
                ),
              ],
            ),
          ),

          // 입력 폼
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 사진 업로드
                  Center(
                    child: GestureDetector(
                      onTap: _pickImage,
                      child: Column(
                        children: [
                          Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              color: const Color(0xFFF3E5F5),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: const Color(0xFFE1BEE7),
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
                                    Icons.upload,
                                    color: Color(0xFFAB47BC),
                                    size: 40,
                                  )
                                : null,
                          ),
                          const SizedBox(height: 10),
                          Text(
                            _selectedImage == null ? "사진 업로드" : "사진 변경",
                            style: const TextStyle(
                              color: Color(0xFFAB47BC),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),

                  _buildLabel("종 *"),
                  _buildTextField(_speciesController, "예: 골든 리트리버"),
                  const SizedBox(height: 20),

                  _buildLabel("이름 *"),
                  _buildTextField(_nameController, "예: 초코"),
                  const SizedBox(height: 20),

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

                  _buildLabel("나이 (살) *"),
                  _buildTextField(_ageController, "예: 3", isNumber: true),
                  const SizedBox(height: 20),

                  _buildLabel("키 (cm)"),
                  _buildTextField(_heightController, "예: 60.5", isNumber: true),
                  const SizedBox(height: 20),

                  _buildLabel("체중 (kg) *"),
                  _buildTextField(_weightController, "예: 32.4", isNumber: true),
                  const SizedBox(height: 20),

                  _buildLabel("중성화 여부"),
                  Row(
                    children: [
                      Expanded(
                        child: _buildSelectButton(
                          text: "중성화 O",
                          isSelected: _isNeutered == true,
                          onTap: () => setState(() => _isNeutered = true),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildSelectButton(
                          text: "중성화 X",
                          isSelected: _isNeutered == false,
                          onTap: () => setState(() => _isNeutered = false),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 40),

                  // 버튼
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: () {
                        if (_nameController.text.isNotEmpty) {
                          // [수정 4] 입력된 데이터를 Map으로 묶어서 반환
                          Navigator.pop(context, {
                            "name": _nameController.text,
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
                        backgroundColor: Colors.transparent,
                        padding: EdgeInsets.zero,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Ink(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFE040FB), Color(0xFF9C27B0)],
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Container(
                          alignment: Alignment.center,
                          child: Text(
                            isEditing ? "수정완료" : "등록하기", // [수정 5] 버튼 텍스트 변경
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
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
            color: Colors.black87,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
          children: [
            if (text.contains('*'))
              const TextSpan(
                text: ' *',
                style: TextStyle(color: Colors.deepPurple),
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
            borderSide: const BorderSide(color: Color(0xFFE1BEE7)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF9C27B0), width: 1.5),
          ),
          fillColor: const Color(0xFFFDF7FF),
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
          gradient: isSelected
              ? const LinearGradient(
                  colors: [Color(0xFFE040FB), Color(0xFF9C27B0)],
                )
              : null,
          color: isSelected ? null : const Color(0xFFFDF7FF),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Colors.transparent : const Color(0xFFE1BEE7),
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
