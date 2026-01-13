import 'package:flutter/material.dart';
import '../models/task_model.dart';
import '../../shared/app_dialog_style.dart';

class TaskDetailDialog extends StatelessWidget {
  final Task task;

  const TaskDetailDialog({super.key, required this.task});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: AppDialogStyle.insetPadding,
      child: Container(
        decoration: BoxDecoration(
          color: AppDialogStyle.background,
          borderRadius: BorderRadius.circular(AppDialogStyle.radius),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 1. 헤더
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
              decoration: BoxDecoration(
                color: AppDialogStyle.text,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(AppDialogStyle.radius),
                  topRight: Radius.circular(AppDialogStyle.radius),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "일정 상세",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(Icons.close, color: Colors.white),
                  ),
                ],
              ),
            ),

            // 2. 내용 본문
            Padding(
              padding: const EdgeInsets.all(30),
              child: Column(
                children: [
                  // 아이콘 + 제목 + 시간
                  Row(
                    children: [
                      Container(
                        width: 60,
                        height: 60,
                        alignment: Alignment.center,
                        decoration: const BoxDecoration(
                          color: Color(0xFFF1F2ED),
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          task.icon ?? "🐾",
                          style: const TextStyle(fontSize: 30),
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              task.title,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              task.time,
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.black,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  // 메모 (있을 경우에만 표시)
                  if (task.memo != null && task.memo!.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F5F5),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            task.memo!,
                            style: const TextStyle(
                              fontSize: 15,
                              color: Colors.black87,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 30),

                  // 완료 상태 표시
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: task.isDone
                          ? const Color(0xFFE8F5E9)
                          : Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      task.isDone ? "완료됨" : "미완료",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: task.isDone
                            ? Colors.green[700]
                            : Colors.grey[600],
                      ),
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
