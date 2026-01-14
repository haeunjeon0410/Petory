import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AlbumItem {
  final String imagePath;
  final DateTime date;
  final String note;

  const AlbumItem({
    required this.imagePath,
    required this.date,
    required this.note,
  });
}

class PolaroidCard extends StatelessWidget {
  final String imagePath;
  final DateTime date;
  final String note;

  const PolaroidCard({
    super.key,
    required this.imagePath,
    required this.date,
    required this.note,
  });

  @override
  Widget build(BuildContext context) {
    final dateText = DateFormat('yyyy.MM.dd').format(date);

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 40),
      decoration: BoxDecoration(
        color: const Color(0xFFFDFDFD),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 14,
            offset: const Offset(4, 6),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AspectRatio(
            aspectRatio: 1 / 1,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: Image.file(
                File(imagePath),
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  color: const Color(0xFFE7E5E4),
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.photo,
                    color: Colors.black38,
                    size: 28,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            dateText,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF44403B),
              fontFamily: 'Pretendard',
            ),
          ),
          const SizedBox(height: 4),
          Text(
            note,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF605A55),
              fontFamily: 'Pretendard',
            ),
          ),
        ],
      ),
    );
  }
}

class AlbumPage extends StatelessWidget {
  final List<AlbumItem> items;

  const AlbumPage({
    super.key,
    required this.items,
  });

  double _rotationFor(AlbumItem item, int index) {
    final seed = item.imagePath.hashCode ^ index;
    final random = math.Random(seed);
    return (random.nextDouble() * 0.06) - 0.03;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2A783),
      body: GridView.builder(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
        itemCount: items.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 18,
          mainAxisSpacing: 18,
          childAspectRatio: 0.78,
        ),
        itemBuilder: (context, index) {
          final item = items[index];
          return Transform.rotate(
            angle: _rotationFor(item, index),
            child: PolaroidCard(
              imagePath: item.imagePath,
              date: item.date,
              note: item.note,
            ),
          );
        },
      ),
    );
  }
}
