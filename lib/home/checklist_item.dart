import 'package:flutter/material.dart';

class CheckListItem extends StatelessWidget {
  final Map<String, dynamic> item;
  final VoidCallback onToggle;
  final VoidCallback onTap;
  // [수정] onMore 대신 onEdit, onDelete로 변경
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const CheckListItem({
    super.key,
    required this.item,
    required this.onToggle,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    bool isDone = item['isDone'];
    var iconData = item['icon'];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: isDone
            ? const Color.fromARGB(255, 217, 215, 210) // 완료 후 색상
            : Colors.white, // 완료 전 색상
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
                color: isDone ? const Color(0xFF44403B) : Colors.white,
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
                      color: isDone
                          ? const Color(0xFF44403B).withOpacity(0.2)
                          : const Color(0xFFF1F2ED),
                      shape: BoxShape.circle,
                    ),
                    child: iconData is String
                        ? Text(iconData, style: const TextStyle(fontSize: 20))
                        : Icon(
                            iconData ?? Icons.check_circle_outline,
                            size: 20,
                            color: null,
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
                            color: isDone ? Colors.grey : Colors.black87,
                            decoration: isDone
                                ? TextDecoration.lineThrough
                                : TextDecoration.none,
                            decorationColor: Colors.grey,
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

          // [핵심 변경] 3. 팝업 메뉴 버튼 (점 세 개)
          PopupMenuButton<String>(
            icon: Icon(
              Icons.more_vert,
              color: const Color.fromARGB(255, 0, 0, 0),
              size: 20,
            ),
            color: Colors.white,
            elevation: 3,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12), // 메뉴 자체도 둥글게
            ),
            onSelected: (String value) {
              if (value == 'edit') {
                onEdit();
              } else if (value == 'delete') {
                onDelete();
              }
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              const PopupMenuItem<String>(
                value: 'edit',
                child: Row(
                  children: [
                    Icon(Icons.edit, color: Colors.blue, size: 20),
                    SizedBox(width: 10),
                    Text('수정', style: TextStyle(fontSize: 14)),
                  ],
                ),
              ),
              const PopupMenuItem<String>(
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
