import 'package:flutter/material.dart';

class AiPage extends StatelessWidget {
  const AiPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('AI 상담')),
      body: const Center(
        child: Text('AI 채팅 화면'),
      ),
    );
  }
}
