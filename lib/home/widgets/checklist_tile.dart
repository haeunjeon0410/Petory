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
        color: task.isDone ? const Color(0xFFE0E0E0) : Colors.white,
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
                        Text(
                          task.title,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: task.isDone
                                ? Colors.grey[600]
                                : Colors.black87,
                            decoration: task.isDone
                                ? TextDecoration.lineThrough
                                : TextDecoration.none,
                            decorationColor: task.isDone
                                ? Colors.grey[600]
                                : Colors.transparent,
                            decorationThickness: 2.0,
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

          // 3. 더보기 메뉴 (디자인 수정됨)
          PopupMenuButton<String>(
            icon: const Icon(
              Icons.more_vert,
              color: Color(0xFF605A55),
              size: 20,
            ),
            color: Colors.white,
            elevation: 3,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14), // 둥근 모서리 통일
            ),
            onSelected: (String value) {
              if (value == 'edit') onEdit();
              if (value == 'delete') onDelete();
            },
            itemBuilder: (context) => [
              // (1) 수정 메뉴
              const PopupMenuItem(
                value: 'edit',
                height: 40,
                child: Row(
                  children: [
                    // 아이콘 모양과 색상을 프로필 팝업과 통일
                    Icon(
                      Icons.mode_rounded,
                      color: Color(0xFF44403B),
                      size: 18,
                    ),
                    SizedBox(width: 10),
                    Text(
                      '수정',
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF44403B), // 진한 갈색 텍스트
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),

              // (2) 구분선 추가 (핵심 포인트)
              const PopupMenuDivider(height: 1),

              // (3) 삭제 메뉴
              const PopupMenuItem(
                value: 'delete',
                height: 40,
                child: Row(
                  children: [
                    Icon(
                      Icons.delete_rounded,
                      color: Colors.redAccent,
                      size: 18,
                    ),
                    SizedBox(width: 10),
                    Text(
                      '삭제',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.redAccent, // 빨간색 텍스트
                        fontWeight: FontWeight.w500,
                      ),
                    ),
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
