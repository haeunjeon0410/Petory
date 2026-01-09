import 'package:flutter/material.dart';
import 'home.dart';
import 'record.dart';
import 'nutrition.dart';
import 'aichat.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: '펫토리',
      home: const MainPage(),
    );
  }
}

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _currentIndex = 0;

  final screens = const [
    HomePage(),
    RecordPage(),
    NutritionPage(),
    AiPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: '홈'),
          BottomNavigationBarItem(icon: Icon(Icons.photo), label: '기록'),
          BottomNavigationBarItem(icon: Icon(Icons.monitor_weight), label: '영양'),
          BottomNavigationBarItem(icon: Icon(Icons.chat), label: 'AI'),
        ],
      ),
    );
  }
}
