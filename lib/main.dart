import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'home/home.dart';
import 'record/record_page.dart';
import 'nutrition.dart'; // 파일이 없다면 주석 처리
import 'aichat.dart'; // 파일이 없다면 주석 처리

void main() {
  runApp(PetoryApp());
}

class PetoryApp extends StatelessWidget {
  const PetoryApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Petory',

      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('ko', 'KR')],
      locale: const Locale('ko'),

      home: MainPage(),
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
  bool hasNotification = true;

  final List<Widget> screens = [
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

  final List<String> _labels = ['홈', '기록', '영양관리', 'AI 채팅'];

  @override
  Widget build(BuildContext context) {
    // final List<Widget> screens = [
    //   HomePage(),
    //   RecordPage(),
    //   NutritionPage(),
    //   AiPage(),
    // ];
    return Scaffold(
      // [핵심 변경 1] 몸통(Body) 전체의 배경색을 '연한 보라색'으로 설정
      // 이렇게 하면 콘텐츠가 짧아도 화면 중간이 보라색으로 꽉 찹니다.
      backgroundColor: const Color(0xFFF1F2ED),

      appBar: AppBar(
        elevation: 0,
        // [핵심 변경 2] 앱 바는 '흰색' 유지 (몸통과 색 분리)
        backgroundColor: Colors.white,
        scrolledUnderElevation: 0,
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
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                IconButton(
                  icon: const Icon(CupertinoIcons.bell, color: Colors.black),
                  onPressed: () {},
                ),
                if (hasNotification)
                  Positioned(
                    right: 6,
                    top: 6,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),

      body: IndexedStack(
        index: _currentIndex, // 현재 보여줄 페이지 번호
        children: screens, // 모든 페이지를 미리 쌓아둠
      ),

      bottomNavigationBar: SafeArea(
        top: false,
        bottom: false,
        child: Container(
          // [핵심 변경 3] 하단 네비게이션 바도 '흰색' 유지
          color: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 8),
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
                    margin: const EdgeInsets.symmetric(horizontal: 17),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFFF1F2ED)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _icons[index],
                          size: 20,
                          color: isSelected
                              ? const Color(0xFF44403B)
                              : Colors.grey,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _labels[index],
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.w400,
                            color: isSelected
                                ? const Color(0xFF44403B)
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
