import 'package:flutter/material.dart';

class NutritionPage extends StatelessWidget {
  const NutritionPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('영양관리')),
      body: const Center(
        child: Text('사료 계산기'),
      ),
    );
  }
}
