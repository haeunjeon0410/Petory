import 'package:flutter/material.dart';
import '../shared/app_dialog_style.dart';

class HospitalCard extends StatelessWidget {
  final String name;
  final String time;
  final String phone;
  final String distance;

  const HospitalCard({super.key, required this.name, required this.time, required this.phone, required this.distance});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              Text(distance, style: const TextStyle(color: Colors.redAccent, fontSize: 12, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 8),
          Text("진료시간: $time", style: const TextStyle(fontSize: 13, color: Colors.grey)),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () {}, // 통화 기능 연결 부분
            child: Text(phone, style: const TextStyle(color: Colors.blue, decoration: TextDecoration.underline)),
          ),
        ],
      ),
    );
  }
}

void showEmergencyDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: AppDialogStyle.background,
      shape: AppDialogStyle.shape(),
      insetPadding: AppDialogStyle.insetPadding,
      title: const Text(
        "응급 상황 안내",
        style: TextStyle(color: AppDialogStyle.text),
      ),
      content: const Text(
        "??? 24? ???? ???? ???? ?? ?????.",
        style: TextStyle(color: AppDialogStyle.mutedText),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text(
            "??",
            style: TextStyle(color: AppDialogStyle.text),
          ),
        ),
      ],
    ),
  );
}
