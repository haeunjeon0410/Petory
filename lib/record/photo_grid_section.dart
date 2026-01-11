import 'package:flutter/material.dart';
import 'dart:io';
import 'package:intl/intl.dart';
import 'record_data.dart' as record;

class PhotoGridSection extends StatelessWidget {
  final String selectedPetName;
  final DateTime focusedDay;

  const PhotoGridSection({super.key, required this.selectedPetName, required this.focusedDay});

  @override
  Widget build(BuildContext context) {
    if (selectedPetName.isEmpty) return const SizedBox.shrink();

    List<MapEntry<DateTime, String>> monthPhotos = [];
    final petPhotos = record.photos[selectedPetName];

    if (petPhotos != null) {
      petPhotos.forEach((date, paths) {
        if (date.year == focusedDay.year && date.month == focusedDay.month) {
          for (var path in paths) {
            monthPhotos.add(MapEntry(date, path));
          }
        }
      });
    }

    monthPhotos.sort((a, b) => a.key.compareTo(b.key));

    if (monthPhotos.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 40),
          child: Text('이번 달에 등록된 사진이 없습니다.', style: TextStyle(color: Colors.grey, fontSize: 14)),
        ),
      );
    }

    return GridView.builder(
      // [핵심] GridView가 스스로 스크롤하지 않고 전체 화면 스크롤을 따라가도록 설정합니다.
      shrinkWrap: true, // 내용만큼의 높이만 차지하게 함
      physics: const NeverScrollableScrollPhysics(), // 내부 스크롤 금지
      itemCount: monthPhotos.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 20,
        crossAxisSpacing: 20,
        childAspectRatio: 0.82,
      ),
      itemBuilder: (context, index) {
        final entry = monthPhotos[index];
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 12, offset: const Offset(0, 6))],
          ),
          child: Column(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
                  child: Image.file(File(entry.value), fit: BoxFit.cover, width: double.infinity),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.calendar_today, size: 14),
                    const SizedBox(width: 6),
                    Text(DateFormat('yyyy년 M월 d일').format(entry.key), style: const TextStyle(fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}