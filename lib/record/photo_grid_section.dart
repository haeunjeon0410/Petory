import 'package:flutter/material.dart';
import 'dart:io';
import 'package:intl/intl.dart';
import 'record_data.dart' as record;

class PhotoGridSection extends StatelessWidget {
  final DateTime focusedDay;

  const PhotoGridSection({super.key, required this.focusedDay});

  @override
  Widget build(BuildContext context) {
    List<MapEntry<DateTime, String>> monthPhotos = [];
    record.photos.forEach((date, paths) {
      if (date.year == focusedDay.year && date.month == focusedDay.month) {
        for (var path in paths) {
          monthPhotos.add(MapEntry(date, path));
        }
      }
    });

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
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
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