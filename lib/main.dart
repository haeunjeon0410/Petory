import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'home.dart';
import 'record.dart';
import 'nutrition.dart';
import 'aichat.dart';

void main() {
  runApp(PetoryApp());
}

class PetoryApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: MainPage(),
    );
  }
}

class MainPage extends StatefulWidget {
  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    HomePage(),
    RecordPage(),
    NutritionPage(),
    AiPage(),
  ];

  final List<IconData> _icons = [
    CupertinoIcons.house_fill,
    CupertinoIcons.photo_on_rectangle,
    CupertinoIcons.heart,
    CupertinoIcons.chat_bubble_text,
  ];

  final List<String> _labels = [
    '홈',
    '기록',
    '영양관리',
    'AI 채팅',
  ];

  @override
  Widget build(BuildContext context) {
    final double bottomInset = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F2FF),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFFFFFFFF),
        toolbarHeight: 56,
        titleSpacing: 8,
        title: const Text(
          'Petory',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w700,
            fontSize: 20,
          ),
        ),
        leading: Padding(
          padding: const EdgeInsets.only(left: 12),
          child: IconButton(
            icon: const Icon(CupertinoIcons.paw, color: Colors.black),
            onPressed: () {},
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: IconButton(
              icon: const Icon(CupertinoIcons.bell, color: Colors.black),
              onPressed: () {},
            ),
          ),
        ],
      ),
      body: _screens[_currentIndex],
      bottomNavigationBar: Container(
        color: Colors.white,
        padding: EdgeInsets.fromLTRB(12, 8, 12, 8 + bottomInset),
        child: SizedBox(
          height: 56,
          child: Row(
            children: List.generate(4, (index) {
              final bool isSelected = _currentIndex == index;

              return Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    setState(() {
                      _currentIndex = index;
                    });
                  },
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 6),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFFE9DFFF)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _icons[index],
                          size: 22,
                          color: isSelected
                              ? const Color(0xFFB388FF)
                              : Colors.grey,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _labels[index],
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.w400,
                            color: isSelected
                                ? const Color(0xFFB388FF)
                                : Colors.grey,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}
