import 'package:flutter/material.dart';

class PetTabBar extends StatefulWidget {
  final List<String> petIds; // 펫 ID 리스트
  final Map<String, Map<String, dynamic>> petProfiles; // 프로필 데이터
  final String selectedId; // 현재 선택된 ID
  final Function(String) onTap; // 탭 했을 때 실행할 함수
  final VoidCallback onAdd; // 추가 버튼 눌렀을 때 실행할 함수

  const PetTabBar({
    super.key,
    required this.petIds,
    required this.petProfiles,
    required this.selectedId,
    required this.onTap,
    required this.onAdd,
  });

  @override
  State<PetTabBar> createState() => _PetTabBarState();
}

class _PetTabBarState extends State<PetTabBar> {
  // 각 버튼의 위치를 기억하기 위한 키(Key) 저장소
  final Map<String, GlobalKey> _keys = {};

  @override
  void initState() {
    super.initState();
    // 화면이 그려진 직후에 스크롤 이동 실행
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToSelected());
  }

  @override
  void didUpdateWidget(covariant PetTabBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 선택된 ID가 바뀌면 다시 스크롤 이동
    if (oldWidget.selectedId != widget.selectedId) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToSelected());
    }
  }

  // [핵심 기능] 선택된 펫 버튼이 화면 중앙에 오도록 스크롤
  void _scrollToSelected() {
    final key = _keys[widget.selectedId];
    if (key?.currentContext != null) {
      Scrollable.ensureVisible(
        key!.currentContext!,
        duration: const Duration(milliseconds: 300), // 부드러운 애니메이션 시간
        alignment: 0.5, // 0.0: 왼쪽 정렬, 0.5: 중앙 정렬, 1.0: 오른쪽 정렬
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          // 1. 펫 버튼 리스트 생성
          ...widget.petIds.map((id) {
            // 키가 없으면 생성하여 등록
            if (!_keys.containsKey(id)) _keys[id] = GlobalKey();

            // 이름 가져오기 (없으면 '이름 없음')
            final name = widget.petProfiles[id]?['name']?.toString() ?? "이름 없음";
            final isSelected = widget.selectedId == id;

            return Padding(
              padding: const EdgeInsets.only(right: 10),
              child: GestureDetector(
                key: _keys[id], // [중요] 위치 추적을 위한 키 할당
                onTap: () => widget.onTap(id),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFF44403B)
                        : const Color(0xFFF1F2ED),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: const Color(0xFF44403B),
                      width: 1.5,
                    ),
                    boxShadow: [
                      if (isSelected)
                        BoxShadow(
                          color: const Color(0xFF44403B).withOpacity(0.3),
                          blurRadius: 6,
                          offset: const Offset(0, 3),
                        ),
                    ],
                  ),
                  child: Text(
                    name,
                    style: TextStyle(
                      color: isSelected
                          ? Colors.white
                          : const Color(0xFF44403B),
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ),
              ),
            );
          }),

          // 2. 추가 버튼
          GestureDetector(
            onTap: widget.onAdd,
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: const Color(0xFF44403B),
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Icon(Icons.add, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}
