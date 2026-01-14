import 'package:flutter/material.dart';
import '../models/task_model.dart';

class TaskDetailDialog extends StatelessWidget {
  final Task task;

  const TaskDetailDialog({super.key, required this.task});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent, // 배경 투명 처리 (Container에서 색상 지정)
      insetPadding: const EdgeInsets.symmetric(horizontal: 24), // 좌우 여백 확보
      child: Container(
        // [디자인] 배경색 및 둥근 모서리 적용 (다른 시트들과 통일)
        decoration: BoxDecoration(
          color: const Color(0xFFF1F2ED),
          borderRadius: BorderRadius.circular(24),
        ),
        clipBehavior: Clip.hardEdge,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 1. 헤더 (심플한 스타일)
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "일정 상세",
                    style: TextStyle(
                      color: Color(0xFF44403B),
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(
                      Icons.close,
                      color: Color(0xFF605A55),
                      size: 22,
                    ),
                  ),
                ],
              ),
            ),

            // 2. 본문 내용
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  // (1) 아이콘 + 제목 + 시간
                  Row(
                    children: [
                      // 아이콘 박스
                      Container(
                        width: 64,
                        height: 64,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE7E5E4), // 아이콘 배경색
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          task.icon ?? "🐾",
                          style: const TextStyle(fontSize: 32),
                        ),
                      ),
                      const SizedBox(width: 20),
                      // 제목 및 시간 텍스트
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              task.title,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF44403B),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              task.time,
                              style: const TextStyle(
                                fontSize: 15,
                                color: Color(0xFF605A55),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  // (2) 메모 영역 (흰색 카드로 강조)
                  if (task.memo != null && task.memo!.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "메모",
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFFA8A29E), // 연한 라벨 색상
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            task.memo!,
                            style: const TextStyle(
                              fontSize: 15,
                              color: Color(0xFF44403B),
                              height: 1.5, // 줄간격 확보
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 30),

                  // (3) 완료 상태 표시줄 (버튼 스타일)
                  Container(
                    width: double.infinity,
                    height: 52,
                    decoration: BoxDecoration(
                      color: task.isDone
                          ? const Color(0xFFE8F5E9) // 완료 시 연한 초록
                          : const Color(0xFFE7E5E4), // 미완료 시 연한 회색
                      borderRadius: BorderRadius.circular(16),
                    ),
                    alignment: Alignment.center,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (task.isDone) ...[
                          Icon(
                            Icons.check_circle,
                            size: 20,
                            color: Colors.green[700],
                          ),
                          const SizedBox(width: 8),
                        ],
                        Text(
                          task.isDone ? "완료됨" : "미완료",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: task.isDone
                                ? Colors.green[700]
                                : const Color(0xFF605A55),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
