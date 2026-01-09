import 'package:flutter/material.dart';

// [역할] 체크리스트 아이템 하나를 그리는 UI
// 로직은(클릭 시 동작 등) 부모(HomePage)에게 함수로 전달받아서 실행함 (Callback 방식)
class CheckListItem extends StatelessWidget {
  final Map<String, dynamic> item;
  final VoidCallback onToggle; // 체크박스 눌렀을 때
  final VoidCallback onTap; // 글씨 눌렀을 때 (상세보기)
  final VoidCallback onMore; // 점 세개 눌렀을 때

  const CheckListItem({
    super.key,
    required this.item,
    required this.onToggle,
    required this.onTap,
    required this.onMore,
  });

  @override
  Widget build(BuildContext context) {
    bool isDone = item['isDone'];
    var iconData = item['icon'];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: isDone ? const Color(0xFFE8F5E9) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDone ? Colors.transparent : Colors.grey.withOpacity(0.1),
        ),
        boxShadow: [
          if (!isDone)
            BoxShadow(
              color: Colors.grey.withOpacity(0.05),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
        ],
      ),
      child: Row(
        children: [
          // 1. 체크박스
          GestureDetector(
            onTap: onToggle,
            child: Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isDone ? const Color(0xFF4CAF50) : Colors.white,
                border: Border.all(
                  color: isDone ? Colors.transparent : const Color(0xFFE0E0E0),
                  width: 2,
                ),
              ),
              child: isDone
                  ? const Icon(Icons.check, size: 18, color: Colors.white)
                  : null,
            ),
          ),
          const SizedBox(width: 14),

          // 2. 내용 (클릭 시 상세보기)
          Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: onTap,
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: isDone
                          ? const Color(0xFF4CAF50).withOpacity(0.2)
                          : const Color(0xFFF3E5F5),
                      shape: BoxShape.circle,
                    ),
                    child: iconData is String
                        ? Text(iconData, style: const TextStyle(fontSize: 20))
                        : Icon(
                            iconData ?? Icons.check_circle_outline,
                            size: 20,
                            color: isDone
                                ? const Color(0xFF2E7D32)
                                : const Color(0xFF9C27B0),
                          ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item['title'],
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                            decoration: isDone ? TextDecoration.none : null,
                          ),
                        ),
                        if (item['time'] != null &&
                            item['time'].isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            item['time'],
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 3. 더보기 (수정/삭제)
          GestureDetector(
            onTap: onMore,
            child: Icon(Icons.more_vert, color: Colors.grey[400], size: 20),
          ),
        ],
      ),
    );
  }
}
