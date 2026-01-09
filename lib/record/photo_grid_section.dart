import 'package:flutter/material.dart';
import 'record_data.dart';

class PhotoGridSection extends StatelessWidget {
  const PhotoGridSection({super.key});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: recordImages.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 0.85,
      ),
      itemBuilder: (context, index) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: Image.asset(
            recordImages[index],
            fit: BoxFit.cover,
          ),
        );
      },
    );
  }
}
