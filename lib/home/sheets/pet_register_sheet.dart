import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import '../models/pet_model.dart';
import '../widgets/common_text_field.dart';

class PetRegisterSheet extends StatefulWidget {
  final Pet? existingPet;

  const PetRegisterSheet({super.key, this.existingPet});

  @override
  State<PetRegisterSheet> createState() => _PetRegisterSheetState();
}

class _PetRegisterSheetState extends State<PetRegisterSheet> {
  // 1. 컨트롤러 & 포커스 노드
  final _nameController = TextEditingController();
  final _nameFocus = FocusNode();

  final _speciesController = TextEditingController();
  final _speciesFocus = FocusNode();

  final _ageController = TextEditingController();
  final _ageFocus = FocusNode();

  final _heightController = TextEditingController();
  final _heightFocus = FocusNode();

  final _weightController = TextEditingController();
  final _weightFocus = FocusNode();

  // 2. 스크롤 이동을 위한 키(Key)
  final _imageKey = GlobalKey();
  final _nameKey = GlobalKey();
  final _speciesKey = GlobalKey();
  final _ageKey = GlobalKey();
  final _genderKey = GlobalKey();
  final _heightKey = GlobalKey();
  final _weightKey = GlobalKey();
  final _neuteredKey = GlobalKey();

  // 3. 에러 상태 변수
  bool _imageHasError = false;
  String? _nameError;
  String? _speciesError;
  String? _ageError;
  String? _genderError;
  String? _heightError;
  String? _weightError;
  String? _neuteredError;

  // 4. 데이터 상태
  String _petType = "강아지";
  String? _gender;
  bool? _isNeutered;
  File? _selectedImage;
  String? _savedImageAsset;
  final ImagePicker _picker = ImagePicker();
  bool _isPickingImage = false;

  @override
  void initState() {
    super.initState();
    if (widget.existingPet != null) {
      final pet = widget.existingPet!;
      _nameController.text = pet.name;
      _speciesController.text = pet.species;
      _ageController.text = pet.age;
      _heightController.text = pet.height;
      _weightController.text = pet.weight;
      _petType = pet.type;
      _gender = pet.gender;
      _isNeutered = pet.isNeutered;

      _selectedImage = pet.imageFile;
      _savedImageAsset = pet.imageAsset;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _nameFocus.dispose();
    _speciesController.dispose();
    _speciesFocus.dispose();
    _ageController.dispose();
    _ageFocus.dispose();
    _heightController.dispose();
    _heightFocus.dispose();
    _weightController.dispose();
    _weightFocus.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    if (_isPickingImage) {
      return;
    }
    _isPickingImage = true;
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
      );
      if (pickedFile != null && mounted) {
        setState(() {
          _selectedImage = File(pickedFile.path);
          _imageHasError = false;
        });
      }
    } on PlatformException {
      // Ignore "already_active" race; user can tap again after picker closes.
    } finally {
      _isPickingImage = false;
    }
  }

  // [핵심] 에러 필드로 스크롤 및 포커스 이동 함수
  void _scrollToErrorField(GlobalKey key, {FocusNode? focusNode}) {
    if (key.currentContext != null) {
      Scrollable.ensureVisible(
        key.currentContext!,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        alignment: 0.1, // 화면 상단에서 약간 아래에 위치하도록 조정
      );
      if (focusNode != null) {
        FocusScope.of(context).requestFocus(focusNode);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.existingPet != null;

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      clipBehavior: Clip.hardEdge,
      child: Column(
        children: [
          // 헤더
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            color: const Color(0xFF44403B),
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

          // 입력 폼
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
                            key: _imageKey, // [키 연결]
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F2ED),
                              shape: BoxShape.circle,
                              image: _getDecorationImage(),
                              border: Border.all(
                                color: _imageHasError
                                    ? Colors.red
                                    : const Color(0xFFF1F2ED),
                                width: 2,
                              ),
                            ),
                            child:
                                (_selectedImage == null &&
                                    _savedImageAsset == null)
                                ? Icon(
                                    Icons.camera_alt,
                                    color: _imageHasError
                                        ? Colors.red
                                        : const Color(0xFF44403B),
                                    size: 40,
                                  )
                                : null,
                          ),
                          if (_imageHasError) ...[
                            const SizedBox(height: 4),
                            const Text(
                              "사진을 등록해주세요",
                              style: TextStyle(color: Colors.red, fontSize: 12),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),

                  // (2) 종류
                  _buildLabel("종류 *"),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F2ED),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        dropdownColor: const Color(0xFFF1F2ED),
                        borderRadius: BorderRadius.circular(12),
                        value: _petType,
                        isExpanded: true,
                        items: ["강아지", "고양이"].map((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          );
                        }).toList(),
                        onChanged: (val) => setState(() => _petType = val!),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // (3) 이름
                  _buildLabel("이름 *"),
                  CommonTextField(
                    fieldKey: _nameKey,
                    controller: _nameController,
                    focusNode: _nameFocus,
                    hint: "예: 초코",
                    noSpecialChars: true,
                    maxLength: 7,
                    errorText: _nameError,
                  ),
                  const SizedBox(height: 20),

                  // (4) 품종
                  _buildLabel("품종 *"),
                  CommonTextField(
                    fieldKey: _speciesKey,
                    controller: _speciesController,
                    focusNode: _speciesFocus,
                    hint: "예: 골든 리트리버",
                    noSpecialChars: true,
                    maxLength: 10,
                    errorText: _speciesError,
                  ),
                  const SizedBox(height: 20),

                  // (5) 나이
                  _buildLabel("나이 (살) *"),
                  CommonTextField(
                    fieldKey: _ageKey,
                    controller: _ageController,
                    focusNode: _ageFocus,
                    hint: "예: 3",
                    isNumber: true,
                    maxLength: 2,
                    errorText: _ageError,
                  ),
                  const SizedBox(height: 20),

                  // (6) 성별
                  _buildLabel("성별 *"),
                  Container(
                    key: _genderKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: _buildSelectButton(
                                text: "수컷 ♂",
                                isSelected: _gender == 'male',
                                hasError: _genderError != null,
                                onTap: () => setState(() {
                                  _gender = 'male';
                                  _genderError = null;
                                }),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildSelectButton(
                                text: "암컷 ♀",
                                isSelected: _gender == 'female',
                                hasError: _genderError != null,
                                onTap: () => setState(() {
                                  _gender = 'female';
                                  _genderError = null;
                                }),
                              ),
                            ),
                          ],
                        ),
                        if (_genderError != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 5, left: 5),
                            child: Text(
                              _genderError!,
                              style: const TextStyle(
                                color: Colors.red,
                                fontSize: 12,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // (7) 키
                  _buildLabel("키 (cm) *"),
                  CommonTextField(
                    fieldKey: _heightKey,
                    controller: _heightController,
                    focusNode: _heightFocus,
                    hint: "예: 60.5",
                    isNumber: true,
                    maxLength: 5,
                    errorText: _heightError,
                  ),
                  const SizedBox(height: 20),

                  // (8) 체중
                  _buildLabel("체중 (kg) *"),
                  CommonTextField(
                    fieldKey: _weightKey,
                    controller: _weightController,
                    focusNode: _weightFocus,
                    hint: "예: 32.4",
                    isNumber: true,
                    maxLength: 5,
                    errorText: _weightError,
                  ),
                  const SizedBox(height: 20),

                  // (9) 중성화 여부
                  _buildLabel("중성화 여부 *"),
                  Container(
                    key: _neuteredKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: _buildSelectButton(
                                text: "O",
                                isSelected: _isNeutered == true,
                                hasError: _neuteredError != null,
                                onTap: () => setState(() {
                                  _isNeutered = true;
                                  _neuteredError = null;
                                }),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildSelectButton(
                                text: "X",
                                isSelected: _isNeutered == false,
                                hasError: _neuteredError != null,
                                onTap: () => setState(() {
                                  _isNeutered = false;
                                  _neuteredError = null;
                                }),
                              ),
                            ),
                          ],
                        ),
                        if (_neuteredError != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 5, left: 5),
                            child: Text(
                              _neuteredError!,
                              style: const TextStyle(
                                color: Colors.red,
                                fontSize: 12,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),

                  // 저장 버튼
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _validateAndSave,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF44403B),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
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

  // [핵심 로직] 모든 필드 검사 및 에러 필드로 이동
  void _validateAndSave() {
    setState(() {
      _imageHasError = false;
      _nameError = null;
      _speciesError = null;
      _ageError = null;
      _genderError = null;
      _heightError = null;
      _weightError = null;
      _neuteredError = null;
    });

    // 1. 이미지 검사
    if (_selectedImage == null && _savedImageAsset == null) {
      setState(() => _imageHasError = true);
      _scrollToErrorField(_imageKey);
      return;
    }

    // 2. 이름 검사
    if (_nameController.text.trim().isEmpty) {
      setState(() => _nameError = "이름을 입력해주세요");
      _scrollToErrorField(_nameKey, focusNode: _nameFocus);
      return;
    }

    // 3. 품종 검사
    if (_speciesController.text.trim().isEmpty) {
      setState(() => _speciesError = "품종을 입력해주세요");
      _scrollToErrorField(_speciesKey, focusNode: _speciesFocus);
      return;
    }

    // 4. 나이 검사
    if (_ageController.text.trim().isEmpty) {
      setState(() => _ageError = "나이를 입력해주세요");
      _scrollToErrorField(_ageKey, focusNode: _ageFocus);
      return;
    }

    // 5. 성별 검사
    if (_gender == null) {
      setState(() => _genderError = "성별을 선택해주세요");
      _scrollToErrorField(_genderKey);
      return;
    }

    // ------------------------------------------------------------
    // [수정] 6. 키 검사 (10000cm 미만 제한 추가)
    // ------------------------------------------------------------
    String heightText = _heightController.text.trim();
    if (heightText.isEmpty) {
      setState(() => _heightError = "키를 입력해주세요");
      _scrollToErrorField(_heightKey, focusNode: _heightFocus);
      return;
    } else {
      double? h = double.tryParse(heightText);
      if (h == null) {
        setState(() => _heightError = "숫자만 입력해주세요");
        _scrollToErrorField(_heightKey, focusNode: _heightFocus);
        return;
      }
      if (h >= 10000) {
        // [추가된 로직]
        setState(() => _heightError = "키는 10000cm 미만이어야 합니다");
        _scrollToErrorField(_heightKey, focusNode: _heightFocus);
        return;
      }
    }

    // ------------------------------------------------------------
    // [수정] 7. 체중 검사 (1000kg 미만 제한 추가)
    // ------------------------------------------------------------
    String weightText = _weightController.text.trim();
    if (weightText.isEmpty) {
      setState(() => _weightError = "체중을 입력해주세요");
      _scrollToErrorField(_weightKey, focusNode: _weightFocus);
      return;
    } else {
      double? w = double.tryParse(weightText);
      if (w == null) {
        setState(() => _weightError = "숫자만 입력해주세요");
        _scrollToErrorField(_weightKey, focusNode: _weightFocus);
        return;
      }
      if (w >= 1000) {
        // [추가된 로직]
        setState(() => _weightError = "체중은 1000kg 미만이어야 합니다");
        _scrollToErrorField(_weightKey, focusNode: _weightFocus);
        return;
      }
    }
    // 8. 중성화 검사
    if (_isNeutered == null) {
      setState(() => _neuteredError = "중성화 여부를 선택해주세요");
      _scrollToErrorField(_neuteredKey);
      return;
    }

    // 모든 검사 통과 시 저장
    final newPet = Pet(
      name: _nameController.text,
      type: _petType,
      species: _speciesController.text,
      age: _ageController.text,
      height: _heightController.text,
      weight: _weightController.text,
      gender: _gender,
      isNeutered: _isNeutered,
      imageFile: _selectedImage,
      imageAsset: _selectedImage == null ? _savedImageAsset : null,
    );

    Navigator.pop(context, newPet);
  }

  DecorationImage? _getDecorationImage() {
    if (_selectedImage != null) {
      return DecorationImage(
        image: FileImage(_selectedImage!),
        fit: BoxFit.cover,
      );
    }
    if (_savedImageAsset != null && _savedImageAsset!.isNotEmpty) {
      if (_savedImageAsset!.startsWith('http')) {
        return DecorationImage(
          image: NetworkImage(_savedImageAsset!),
          fit: BoxFit.cover,
        );
      }
      return DecorationImage(
        image: AssetImage(_savedImageAsset!),
        fit: BoxFit.cover,
      );
    }
    return null;
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: RichText(
        text: TextSpan(
          text: text.replaceAll('*', ''),
          style: const TextStyle(
            color: Color(0xFF44403B),
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

  Widget _buildSelectButton({
    required String text,
    required bool isSelected,
    required VoidCallback onTap,
    bool hasError = false, // 에러 상태 표시용
  }) {
    // 에러일 때 빨간 테두리
    Color borderColor = hasError
        ? Colors.red
        : (isSelected ? Colors.transparent : const Color(0xFFF1F2ED));

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF44403B) : const Color(0xFFF1F2ED),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: borderColor,
            width: hasError ? 1.0 : (isSelected ? 0 : 1),
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
