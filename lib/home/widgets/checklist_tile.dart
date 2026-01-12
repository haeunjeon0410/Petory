import 'package:flutter/material.dart';
import '../models/task_model.dart';

class CheckListTile extends StatelessWidget {
  final Task task;
  final VoidCallback onToggle;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const CheckListTile({
    super.key,
    required this.task,
    required this.onToggle,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        // [디자인 수정] 완료 시 배경색을 너무 어둡지 않게 조정 (선택사항)
        color: task.isDone
            ? const Color(0xFFE0E0E0) // 기존보다 조금 더 밝은 회색
            : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: task.isDone
              ? Colors.transparent
              : Colors.grey.withOpacity(0.1),
        ),
        boxShadow: [
          if (!task.isDone)
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
                color: task.isDone ? const Color(0xFF44403B) : Colors.white,
                border: Border.all(
                  color: task.isDone
                      ? Colors.transparent
                      : const Color(0xFFE0E0E0),
                  width: 2,
                ),
              ),
              child: task.isDone
                  ? const Icon(Icons.check, size: 18, color: Colors.white)
                  : null,
            ),
          ),
          const SizedBox(width: 14),

          // 2. 내용
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
                      color: task.isDone
                          ? const Color(0xFF44403B).withOpacity(0.2)
                          : const Color(0xFFF1F2ED),
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      task.icon ?? "🐾",
                      style: const TextStyle(fontSize: 20),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // [핵심 수정] 텍스트 스타일 변경
                        Text(
                          task.title,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            // 완료 시 텍스트 색상
                            color: task.isDone
                                ? Colors.grey[600]
                                : Colors.black87,

                            // [수정] 취소선 설정
                            decoration: task.isDone
                                ? TextDecoration.lineThrough
                                : TextDecoration.none,
                            // [추가] 취소선 색상을 명확하게 지정 (끊김 방지)
                            decorationColor: task.isDone
                                ? Colors.grey[600]
                                : Colors.transparent,
                            // [추가] 취소선 두께 지정 (선명하게)
                            decorationThickness: 2.0,
                            decorationStyle: TextDecorationStyle.solid,
                          ),
                        ),
                        if (task.time.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            task.time,
                            style: TextStyle(
                              fontSize: 12,
                              color: task.isDone
                                  ? Colors.grey[600]
                                  : Colors.black,
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

          // 3. 더보기 메뉴
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.black, size: 20),
            color: Colors.white,
            elevation: 3,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            onSelected: (String value) {
              if (value == 'edit') onEdit();
              if (value == 'delete') onDelete();
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: [
                    Icon(Icons.edit, color: Colors.blue, size: 20),
                    SizedBox(width: 10),
                    Text('수정', style: TextStyle(fontSize: 14)),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete, color: Colors.red, size: 20),
                    SizedBox(width: 10),
                    Text('삭제', style: TextStyle(fontSize: 14)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
