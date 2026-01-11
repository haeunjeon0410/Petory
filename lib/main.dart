import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart';
import 'home/home.dart';
import 'record/record_page.dart';
import 'record/record_data.dart' as record;
import 'nutrition.dart';
import 'aichat.dart';

void main() {
  runApp(const PetoryApp());
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
  bool _isBadgeRead = false;
  int _lastNotificationCount = 0;

  void _showNotificationDialog(BuildContext context) {
    setState(() => _isBadgeRead = true);
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final activeAlarms = record.getActiveAlarmsForNext24Hours();

            return Dialog(
              backgroundColor: const Color(0xFFF1F2ED),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              insetPadding: const EdgeInsets.all(20),
              child: Container(
                width: double.infinity,
                height: 420,
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.notifications_active_rounded, color: Color(0xFF44403B), size: 22),
                            SizedBox(width: 8),
                            Text('알림창', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF44403B))),
                          ],
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.close_rounded, color: Color(0xFF605A55), size: 22),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Expanded(
                      child: activeAlarms.isEmpty
                          ? const Center(child: Text('알림이 없습니다.', style: TextStyle(color: Colors.grey)))
                          : ListView.builder(
                        itemCount: activeAlarms.length,
                        itemBuilder: (context, index) {
                          final s = activeAlarms[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Dismissible(
                              key: UniqueKey(),
                              direction: DismissDirection.endToStart,
                              // main.dart의 Dismissible 내부
                              // main.dart의 Dismissible 내부 onDismissed 부분
                              onDismissed: (direction) {
                                setModalState(() {
                                  final key = record.normalizeDate(s.date);
                                  // [수정] s.petName을 사용하여 해당 펫의 일정 리스트를 정확히 찾아갑니다.
                                  final petSchedules = record.schedules[s.petName];
                                  if (petSchedules != null && petSchedules[key] != null) {
                                    final list = petSchedules[key]!;
                                    // 인스턴스가 다를 수 있으므로 속성(제목, 시간 등)으로 해당 일정을 찾습니다.
                                    final idx = list.indexWhere((item) =>
                                    item.title == s.title &&
                                        item.time == s.time &&
                                        record.normalizeDate(item.date) == key
                                    );

                                    if (idx != -1) {
                                      // 알림 상태만 false로 변경하여 리스트에서 제거합니다.
                                      list[idx] = record.Schedule(
                                        petName: s.petName,
                                        date: s.date,
                                        title: s.title,
                                        content: s.content,
                                        color: s.color,
                                        time: s.time,
                                        alarm: false,
                                      );
                                    }
                                  }
                                });
                                setState(() {}); // 메인 배지 갱신
                              },
                              background: Container(
                                decoration: BoxDecoration(
                                  color: Colors.redAccent,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                alignment: Alignment.centerRight,
                                padding: const EdgeInsets.only(right: 20),
                                child: const Icon(Icons.notifications_off_rounded, color: Colors.white),
                              ),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF44403B).withOpacity(0.08),
                                      blurRadius: 8,
                                      offset: const Offset(0, 4),
                                    )
                                  ],
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(12.0),
                                  child: Row( // Row에는 children: [] 이 꼭 필요해!
                                    children: [
                                      // 1. 왼쪽 아이콘 아이콘
                                      Container(
                                        width: 48,
                                        height: 48,
                                        decoration: BoxDecoration(
                                          color: s.color.withOpacity(0.2),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Center(
                                          child: Icon(Icons.notifications_active_rounded, color: s.color, size: 24),
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      // 2. 오른쪽 텍스트 영역 (Expanded로 감싸야 텍스트가 넘치지 않아!)
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            // 펫 이름과 시간을 한 줄에 표시
                                            RichText(
                                              text: TextSpan(
                                                children: [
                                                  TextSpan(
                                                    text: '${s.petName} ', //
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      color: s.color, // 일정 색상과 맞춰서 강조
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                  ),
                                                  TextSpan(
                                                    text: '· ${DateFormat('M월 d일').format(s.date)} · ${s.time!.format(context)}',
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      color: const Color(0xFF44403B).withOpacity(0.6),
                                                      fontWeight: FontWeight.w600,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            // 일정 제목
                                            Text(
                                              s.title,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w700,
                                                fontSize: 15,
                                                color: Color(0xFF44403B),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final activeAlarms = record.getActiveAlarmsForNext24Hours();
    if (activeAlarms.length > _lastNotificationCount) {
      _isBadgeRead = false;
    }
    _lastNotificationCount = activeAlarms.length;
    bool showRedDot = activeAlarms.isNotEmpty && !_isBadgeRead;

    final List<Widget> screens = [
      const HomePage(),
      RecordPage(onRefresh: () => setState(() {})),
      const NutritionPage(),
      const AiPage(),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF1F2ED),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFFF1F2ED),
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
        leading: Padding(
          padding: const EdgeInsets.only(left: 12),
          child: IconButton(
            icon: const Icon(CupertinoIcons.paw, color: Colors.black),
            onPressed: () {},
          ),
        ),
        title: const Text('Petory', style: TextStyle(color: Colors.black, fontWeight: FontWeight.w700, fontSize: 20)),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                IconButton(
                  icon: const Icon(CupertinoIcons.bell, color: Colors.black),
                  onPressed: () => _showNotificationDialog(context),
                ),
                if (showRedDot)
                  Positioned(
                    right: 6,
                    top: 6,
                    child: Container(width: 8, height: 8, decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle)),
                  ),
              ],
            ),
          ),
        ],
      ),
      body: IndexedStack(index: _currentIndex, children: screens),
      bottomNavigationBar: Container(
        color: Colors.white,
        child: SafeArea(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 4),
            child: Row(
              children: List.generate(4, (index) {
                final isSelected = _currentIndex == index;
                final List<IconData> icons = [CupertinoIcons.house_fill, CupertinoIcons.photo_on_rectangle, CupertinoIcons.heart, CupertinoIcons.chat_bubble_text];
                final List<String> labels = ['홈', '기록', '영양관리', 'AI 채팅'];
                return Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _currentIndex = index),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected ? const Color(0xFFF1F2ED) : Colors.transparent,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(icons[index], size: 20, color: isSelected ? const Color(0xFF44403B) : Colors.grey),
                          const SizedBox(height: 2),
                          Text(labels[index], style: TextStyle(fontSize: 9, color: isSelected ? const Color(0xFF44403B) : Colors.grey)),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}