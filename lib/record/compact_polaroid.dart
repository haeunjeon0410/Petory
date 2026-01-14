import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class CompactPolaroid extends StatelessWidget {
  final String imagePath;
  final DateTime date;

  const CompactPolaroid({
    super.key,
    required this.imagePath,
    required this.date,
  });

  @override
  Widget build(BuildContext context) {
    final dateText = DateFormat('yyyy.MM.dd').format(date);

    return Container(
      width: 146,
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 28),
      decoration: BoxDecoration(
        color: const Color(0xFFF9F9F9),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 6,
            offset: const Offset(2, 3),
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
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Colors.grey.shade300,
                    width: 0.3,
                  ),
                ),
                child: Image.file(
                  File(imagePath),
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    color: const Color(0xFFE7E5E4),
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.photo,
                      color: Colors.black38,
                      size: 20,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            dateText,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              fontFamily: 'Pretendard',
              letterSpacing: 0.3,
              color: Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }
}
