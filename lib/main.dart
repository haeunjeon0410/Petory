import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart';
import 'home/home_page.dart';
import 'record/record_page.dart';
import 'record/record_data.dart' as record;
import 'nutrition/nutrition_page.dart';
import 'aichat/ai_chat_page.dart';

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
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
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
                            Icon(
                              Icons.notifications_active_rounded,
                              color: Color(0xFF44403B),
                              size: 22,
                            ),
                            SizedBox(width: 8),
                            Text(
                              '알림창',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF44403B),
                              ),
                            ),
                          ],
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(
                            Icons.close_rounded,
                            color: Color(0xFF605A55),
                            size: 22,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Expanded(
                      child: activeAlarms.isEmpty
                          ? const Center(
                              child: Text(
                                '알림이 없습니다.',
                                style: TextStyle(color: Colors.grey),
                              ),
                            )
                          : ListView.builder(
                              itemCount: activeAlarms.length,
                              itemBuilder: (context, index) {
                                final s = activeAlarms[index];
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: Dismissible(
                                    key: UniqueKey(),
                                    direction: DismissDirection.endToStart,
                                    onDismissed: (direction) {
                                      setModalState(() {
                                        final key = record.normalizeDate(
                                          s.date,
                                        );
                                        final petSchedules =
                                            record.schedules[s.petId];
                                        if (petSchedules != null &&
                                            petSchedules[key] != null) {
                                          final list = petSchedules[key]!;
                                          final idx = list.indexWhere(
                                            (item) =>
                                                item.title == s.title &&
                                                item.time == s.time &&
                                                record.normalizeDate(
                                                      item.date,
                                                    ) ==
                                                    key,
                                          );

                                          if (idx != -1) {
                                            list[idx] = record.Schedule(
                                              petId: s.petId,
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
                                      setState(() {});
                                    },
                                    background: Container(
                                      decoration: BoxDecoration(
                                        color: Colors.redAccent,
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      alignment: Alignment.centerRight,
                                      padding: const EdgeInsets.only(right: 20),
                                      child: const Icon(
                                        Icons.notifications_off_rounded,
                                        color: Colors.white,
                                      ),
                                    ),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(20),
                                        boxShadow: [
                                          BoxShadow(
                                            color: const Color(
                                              0xFF44403B,
                                            ).withOpacity(0.08),
                                            blurRadius: 8,
                                            offset: const Offset(0, 4),
                                          ),
                                        ],
                                      ),
                                      child: Padding(
                                        padding: const EdgeInsets.all(12.0),
                                        child: Row(
                                          children: [
                                            Container(
                                              width: 48,
                                              height: 48,
                                              decoration: BoxDecoration(
                                                color: s.color.withOpacity(0.2),
                                                shape: BoxShape.circle,
                                              ),
                                              child: Center(
                                                child: Icon(
                                                  Icons
                                                      .notifications_active_rounded,
                                                  color: s.color,
                                                  size: 24,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 16),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  RichText(
                                                    text: TextSpan(
                                                      children: [
                                                        TextSpan(
                                                          text:
                                                              '${record.petProfiles[s.petId]?['name'] ?? '알 수 없음'} ',
                                                          style: TextStyle(
                                                            fontSize: 12,
                                                            color: s.color,
                                                            fontWeight:
                                                                FontWeight.bold,
                                                          ),
                                                        ),
                                                        TextSpan(
                                                          text:
                                                              '· ${DateFormat('M월 d일').format(s.date)} · ${s.time!.format(context)}',
                                                          style: TextStyle(
                                                            fontSize: 12,
                                                            color: const Color(
                                                              0xFF44403B,
                                                            ).withOpacity(0.6),
                                                            fontWeight:
                                                                FontWeight.w600,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    s.title,
                                                    style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.w700,
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

    // ⭐ [가장 중요한 수정] HomePage에도 onRefresh를 전달합니다.
    // 이제 홈 탭에서 펫을 바꾸면 MainPage가 새로고침되어 레코드 탭도 동기화됩니다.
    final List<Widget> screens = [
      HomePage(onRefresh: () => setState(() {})),
      RecordPage(onRefresh: () => setState(() {})),
      NutritionPage(onRefresh: () => setState(() {})),
      AiChatPage(onRefresh: () => setState(() {})),
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
        title: const Text(
          'Petory',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w700,
            fontSize: 20,
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
                  onPressed: () => _showNotificationDialog(context),
                ),
                if (showRedDot)
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
      body: IndexedStack(index: _currentIndex, children: screens),
      bottomNavigationBar: Container(
        color: Colors.white,
        child: SafeArea(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 4),
            child: Row(
              children: List.generate(4, (index) {
                final isSelected = _currentIndex == index;
                final List<IconData> icons = [
                  CupertinoIcons.house_fill,
                  CupertinoIcons.photo_on_rectangle,
                  CupertinoIcons.heart,
                  CupertinoIcons.chat_bubble_text,
                ];
                final List<String> labels = ['홈', '기록', '영양관리', 'AI 채팅'];
                return Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _currentIndex = index),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFFF1F2ED)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            icons[index],
                            size: 20,
                            color: isSelected
                                ? const Color(0xFF44403B)
                                : Colors.grey,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            labels[index],
                            style: TextStyle(
                              fontSize: 9,
                              color: isSelected
                                  ? const Color(0xFF44403B)
                                  : Colors.grey,
                            ),
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
      ),
    );
  }
}
