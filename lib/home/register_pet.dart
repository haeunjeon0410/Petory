import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import '../record/record_data.dart' as record;

class PetRegistrationDialog extends StatefulWidget {
  final Map<String, dynamic>? existingData;

  const PetRegistrationDialog({super.key, this.existingData});

  static Future<String?> editPetProfile(
    BuildContext context,
    String currentPetId, // [수정] 매개변수 이름을 ID로 변경 (의미 명확화)
    Map<String, dynamic> currentProfile,
  ) async {
    // 1. 다이얼로그 띄우기
    final updatedData = await showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: PetRegistrationDialog(existingData: currentProfile),
      ),
    );

    // 2. 결과 처리
    if (updatedData != null && updatedData is Map<String, dynamic>) {
      // [핵심 수정]
      // ID(currentPetId)는 변하지 않으므로, 복잡한 키 이동 로직 없이 바로 덮어씁니다.
      record.petProfiles[currentPetId] = updatedData;

      // 바뀐 이름 반환 (UI 갱신용)
      return updatedData['name'];
    }
    return null; // 취소됨
  }

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

  final FocusNode _nameFocus = FocusNode();
  final FocusNode _ageFocus = FocusNode();
  final FocusNode _heightFocus = FocusNode();
  final FocusNode _weightFocus = FocusNode();
  final FocusNode _speciesFocus = FocusNode();

  final GlobalKey _petTypeKey = GlobalKey();
  final GlobalKey _nameKey = GlobalKey();
  final GlobalKey _speciesKey = GlobalKey();
  final GlobalKey _ageKey = GlobalKey();
  final GlobalKey _genderKey = GlobalKey();
  final GlobalKey _heightKey = GlobalKey();
  final GlobalKey _weightKey = GlobalKey();
  final GlobalKey _neuteredKey = GlobalKey();
  final GlobalKey _imageKey = GlobalKey();

  String? _nameError;
  String? _speciesError;
  String? _ageError;
  String? _genderError;
  String? _heightError;
  String? _weightError;
  String? _neuteredError;
  bool _imageError = false;

  // 상태 변수
  String _petType = "강아지"; // [추가] 기본값 강아지
  String? _gender;
  bool? _isNeutered;
  File? _selectedImage;
  String? _savedImage;
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
      } else if (data['image'] is String) {
        _savedImage = data['image']; // 문자열(Asset 경로) 저장
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
        _imageError = false;
      });
    }
  }

  @override
  void dispose() {
    // 컨트롤러 정리 (기존 코드 유지)
    _nameController.dispose();
    _speciesController.dispose();
    _ageController.dispose();
    _heightController.dispose();
    _weightController.dispose();

    // [추가 2] 포커스 노드 정리 (메모리 해제)
    _nameFocus.dispose();
    _ageFocus.dispose();
    _heightFocus.dispose();
    _weightFocus.dispose();

    super.dispose();
  }

  void _scrollToErrorField(GlobalKey key, {FocusNode? focusNode}) {
    if (focusNode != null) {
      focusNode.requestFocus();
    }

    Future.delayed(const Duration(milliseconds: 300), () {
      if (key.currentContext != null) {
        Scrollable.ensureVisible(
          key.currentContext!,
          duration: const Duration(milliseconds: 300),
          alignment: 0.1, // 화면 상단 10% 위치로 이동
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    bool isEditing = widget.existingData != null;

    // 팝업 창 내부 디자인
    return Container(
      height: MediaQuery.of(context).size.height * 0.7, // 높이 제한
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
            child: NotificationListener<OverscrollIndicatorNotification>(
              onNotification: (OverscrollIndicatorNotification overscroll) {
                overscroll.disallowIndicator(); // 여기서 시각적 효과를 끕니다.
                return true;
              },
              child: SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
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
                              key: _imageKey,
                              width: 100,
                              height: 100,
                              decoration: BoxDecoration(
                                color: const Color(0xFFF1F2ED), // 크림색 배경
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: _imageError
                                      ? Colors.red
                                      : const Color(0xFFF1F2ED),
                                  width: 2,
                                ),
                                image: _selectedImage != null
                                    ? DecorationImage(
                                        image: FileImage(_selectedImage!),
                                        fit: BoxFit.cover,
                                      )
                                    : (_savedImage != null &&
                                          _savedImage!.isNotEmpty)
                                    ? DecorationImage(
                                        // 2순위: 저장된 Asset 이미지 (URL 체크 삭제)
                                        image: AssetImage(_savedImage!),
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
                            // const SizedBox(height: 8),
                            // Text(
                            //   _selectedImage == null ? "사진 등록" : "사진 변경",
                            //   style: const TextStyle(
                            //     color: Color(0xFF44403B),
                            //     fontSize: 13,
                            //   ),
                            // ),
                            if (_imageError) ...[
                              const SizedBox(height: 6),
                              const Text(
                                "사진을 등록해주세요.",
                                style: TextStyle(
                                  color: Colors.red,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),

                    // (2) 강아지/고양이 선택 (드롭다운)
                    _buildLabel("종류"),
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
                    _buildLabel("이름"),
                    _buildTextField(
                      _nameController,
                      "예: 초코",
                      focusNode: _nameFocus,
                      errorText: _nameError,
                      fieldKey: _nameKey,
                      maxLength: 8,
                    ),
                    const SizedBox(height: 20),

                    // (4) 품종
                    _buildLabel("품종"),
                    _buildTextField(
                      _speciesController,
                      "예: 골든 리트리버",
                      focusNode: _speciesFocus,
                      errorText: _speciesError,
                      fieldKey: _speciesKey,
                      maxLength: 9,
                    ),
                    const SizedBox(height: 20),

                    // (5) 나이
                    _buildLabel("나이 (살)"),
                    _buildTextField(
                      _ageController,
                      "예: 3",
                      isNumber: true,
                      focusNode: _ageFocus,
                      errorText: _ageError,
                      fieldKey: _ageKey,
                      maxLength: 2,
                    ),
                    const SizedBox(height: 20),

                    // (6) 성별
                    _buildLabel("성별"),
                    Container(
                      key: _genderKey, // [핵심] 스크롤 이동용 키
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: _buildSelectButton(
                                  text: "수컷 ♂",
                                  isSelected: _gender == 'male',
                                  hasError:
                                      _genderError != null, // [추가] 에러 상태 전달
                                  onTap: () => setState(() {
                                    _gender = 'male';
                                    _genderError = null; // 선택 시 에러 해제
                                  }),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildSelectButton(
                                  text: "암컷 ♀",
                                  isSelected: _gender == 'female',
                                  hasError: _genderError != null, // [추가]
                                  onTap: () => setState(() {
                                    _gender = 'female';
                                    _genderError = null;
                                  }),
                                ),
                              ),
                            ],
                          ),
                          // [추가] 에러 메시지 텍스트
                          if (_genderError != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 8, left: 12),
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
                    _buildLabel("키 (cm)"),
                    _buildTextField(
                      _heightController,
                      "예: 60.5",
                      isNumber: true,
                      focusNode: _heightFocus,
                      errorText: _heightError,
                      fieldKey: _heightKey,
                      maxLength: 5,
                    ),
                    const SizedBox(height: 20),

                    // (8) 체중
                    _buildLabel("체중 (kg)"),
                    _buildTextField(
                      _weightController,
                      "예: 32.4",
                      isNumber: true,
                      focusNode: _weightFocus,
                      errorText: _weightError,
                      fieldKey: _weightKey,
                      maxLength: 5,
                    ),
                    const SizedBox(height: 20),

                    // (9) 중성화 여부
                    _buildLabel("중성화 여부"),
                    Container(
                      key: _neuteredKey, // [핵심] 스크롤 이동용 키
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
                                  hasError: _neuteredError != null, // [추가]
                                  onTap: () => setState(() {
                                    _isNeutered = false;
                                    _neuteredError = null;
                                  }),
                                ),
                              ),
                            ],
                          ),
                          // [추가] 에러 메시지 텍스트
                          if (_neuteredError != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 8, left: 12),
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
                    const SizedBox(height: 20),

                    // 등록 완료 버튼
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: () async {
                          setState(() {
                            _nameError = null;
                            _speciesError = null;
                            _ageError = null;
                            _genderError = null;
                            _heightError = null;
                            _weightError = null;
                            _neuteredError = null;
                            _imageError = false;
                          });

                          // 2. 순서대로 검사 (위에서부터 아래로)
                          if (_selectedImage == null) {
                            setState(() => _imageError = true);
                            _scrollToErrorField(_imageKey); // 맨 위로 스크롤
                            return;
                          }
                          // [이름]
                          if (_nameController.text.trim().isEmpty) {
                            setState(() => _nameError = "이름을 입력해주세요.");
                            _scrollToErrorField(
                              _nameKey,
                              focusNode: _nameFocus,
                            );
                            return;
                          }

                          // [품종] (새로 추가된 필수 검사)
                          if (_speciesController.text.trim().isEmpty) {
                            setState(() => _speciesError = "품종을 입력해주세요.");
                            _scrollToErrorField(
                              _speciesKey,
                              focusNode: _speciesFocus,
                            );
                            return;
                          }

                          // [나이]
                          if (_ageController.text.trim().isEmpty) {
                            setState(() => _ageError = "나이를 입력해주세요.");
                            _scrollToErrorField(_ageKey, focusNode: _ageFocus);
                            return;
                          }

                          // [성별] (선택형 검사)
                          if (_gender == null) {
                            setState(() => _genderError = "성별을 선택해주세요.");
                            _scrollToErrorField(
                              _genderKey,
                            ); // FocusNode 없이 키만 전달 -> 스크롤만 이동
                            return;
                          }

                          // [키]
                          if (_heightController.text.trim().isEmpty) {
                            setState(() => _heightError = "키를 입력해주세요.");
                            _scrollToErrorField(
                              _heightKey,
                              focusNode: _heightFocus,
                            );
                            return;
                          }

                          // [체중]
                          if (_weightController.text.trim().isEmpty) {
                            setState(() => _weightError = "체중을 입력해주세요.");
                            _scrollToErrorField(
                              _weightKey,
                              focusNode: _weightFocus,
                            );
                            return;
                          }

                          // [중성화] (선택형 검사)
                          if (_isNeutered == null) {
                            setState(() => _neuteredError = "중성화 여부를 선택해주세요.");
                            _scrollToErrorField(_neuteredKey); // 스크롤만 이동
                            return;
                          }

                          final newPet = {
                            "name": _nameController.text,
                            "type": _petType,
                            "species": _speciesController.text,
                            "age": _ageController.text,
                            "height": _heightController.text,
                            "weight": _weightController.text,
                            "gender": _gender,
                            "isNeutered": _isNeutered,
                            "image": _selectedImage,
                          };
                          Navigator.pop(context, newPet);
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
          ),
        ],
      ),
    );
  }

  // --- 위젯 빌더 ---

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: const TextStyle(
          color: Color(0xFF44403B), // 갈색 텍스트
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String hint, {
    bool isNumber = false,
    FocusNode? focusNode,
    String? errorText,
    GlobalKey? fieldKey,
    int? maxLength,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          key: fieldKey,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: TextField(
            maxLength: maxLength,
            // buildCounter: null,
            cursorColor: const Color(0xFF44403B),
            cursorErrorColor: const Color(0xFF44403B),
            controller: controller,
            focusNode: focusNode,
            keyboardType: isNumber
                ? const TextInputType.numberWithOptions(decimal: true)
                : TextInputType.text,
            inputFormatters: isNumber
                ? [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d*'))]
                : [],
            decoration: InputDecoration(
              hintText: hint,
              counterText: "",
              hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
              errorText: errorText,
              errorStyle: const TextStyle(
                color: Colors.red,
                fontSize: 12,
                height: 1.2,
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
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.red, width: 1.5),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.red, width: 1.5),
              ),
              fillColor: const Color(0xFFF1F2ED),
              filled: true,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSelectButton({
    required String text,
    required bool isSelected,
    required VoidCallback onTap,
    bool hasError = false,
  }) {
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
          border: Border.all(color: borderColor, width: hasError ? 1.0 : 1.5),
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
