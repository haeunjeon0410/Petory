import 'dart:convert';
import 'dart:math'; // 거리 계산 시뮬레이션용
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http; // [추가] API 통신
import 'package:url_launcher/url_launcher.dart'; // [추가] 전화 걸기

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

// [추가] 병원 데이터 모델
class Hospital {
  final String name;
  final String address; // 진료 시간 대신 주소나 설명으로 활용
  final String phoneNumber;
  final double distance; // 거리 (km)

  Hospital({
    required this.name,
    required this.address,
    required this.phoneNumber,
    required this.distance,
  });

  factory Hospital.fromJson(Map<String, dynamic> json) {
    // HTML 태그 제거 (예: <b>병원</b>)
    String cleanTitle = json['title'].toString().replaceAll(
      RegExp(r'<[^>]*>'),
      '',
    );

    return Hospital(
      name: cleanTitle,
      address: json['roadAddress'] ?? json['address'] ?? "정보 없음",
      phoneNumber: json['telephone'] ?? "번호 없음",
      // *참고: API가 거리를 주지 않으므로, 여기서는 0.5~5.0km 사이 랜덤 값으로 시뮬레이션합니다.
      // 실제로는 내 GPS 좌표와 mapx, mapy 좌표를 계산해야 합니다.
      distance: double.parse(
        (0.5 + Random().nextDouble() * 4.5).toStringAsFixed(1),
      ),
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

  void _showEmergencyDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return const EmergencyDialog(); // 별도 위젯으로 분리
      },
    );
  }

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
            child: Row(
              // Stack 대신 Row로 감싸서 버튼 나열
              children: [
                // [추가] 1. 비상 연락망 버튼 (왼쪽)
                IconButton(
                  icon: const Icon(
                    Icons.emergency_outlined,
                    color: Colors.redAccent,
                  ),
                  onPressed: () => _showEmergencyDialog(context),
                ),

                // 2. 기존 알림 버튼 (오른쪽)
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    IconButton(
                      icon: const Icon(
                        CupertinoIcons.bell,
                        color: Colors.black,
                      ),
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

// [추가] 비상 연락망 다이얼로그 위젯 (별도 분리)
class EmergencyDialog extends StatefulWidget {
  const EmergencyDialog({super.key});

  @override
  State<EmergencyDialog> createState() => _EmergencyDialogState();
}

class _EmergencyDialogState extends State<EmergencyDialog> {
  List<Hospital> hospitals = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchHospitals();
  }

  Future<void> _fetchHospitals() async {
    // ⚠ [중요] 네이버 개발자 센터에서 발급받은 키를 여기에 넣으세요
    const String clientId = "LxZobpd8acNKliAp598K";
    const String clientSecret = "YzsiQVnnCB";

    // 동물병원 검색 (display=5: 5개만 가져오기)
    final String url =
        "https://openapi.naver.com/v1/search/local.json?query=동물병원&display=5&sort=random";

    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {
          "X-Naver-Client-Id": clientId,
          "X-Naver-Client-Secret": clientSecret,
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> items = data['items'];

        List<Hospital> fetchedHospitals = items
            .map((item) => Hospital.fromJson(item))
            .toList();

        // [정렬 로직] 거리순 정렬 (오름차순: 가까운 순서)
        fetchedHospitals.sort((a, b) => a.distance.compareTo(b.distance));

        setState(() {
          hospitals = fetchedHospitals;
          isLoading = false;
        });
      } else {
        // API 에러 시 더미 데이터
        _loadDummyData();
      }
    } catch (e) {
      print("Error: $e");
      _loadDummyData();
    }
  }

  void _loadDummyData() {
    List<Hospital> dummies = [
      Hospital(
        name: "펫 응급센터",
        address: "24시간 연중무휴",
        phoneNumber: "02-987-6543",
        distance: 0.8,
      ),
      Hospital(
        name: "김수진 수의사",
        address: "평일 09:00-20:00",
        phoneNumber: "02-123-4567",
        distance: 1.2,
      ),
      Hospital(
        name: "박민수 수의사",
        address: "평일 10:00-19:00",
        phoneNumber: "02-456-7890",
        distance: 2.5,
      ),
    ];
    // 더미 데이터도 정렬
    dummies.sort((a, b) => a.distance.compareTo(b.distance));

    setState(() {
      hospitals = dummies;
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFFF1F2ED), // 앱 테마 색상 일치
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      insetPadding: const EdgeInsets.all(20),
      child: Container(
        width: double.infinity,
        height: 450,
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
        child: Column(
          children: [
            // 1. 헤더 영역
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(
                      Icons.local_hospital_rounded,
                      color: Colors.redAccent,
                      size: 24,
                    ),
                    SizedBox(width: 8),
                    Text(
                      '비상 연락처',
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

            // 2. 리스트 영역
            Expanded(
              child: isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF44403B),
                      ),
                    )
                  : ListView.builder(
                      itemCount: hospitals.length,
                      itemBuilder: (context, index) {
                        final hospital = hospitals[index];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(16),
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
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // 병원 이름
                                    Text(
                                      hospital.name,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF44403B),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    // 거리 & 진료시간
                                    Row(
                                      children: [
                                        const Icon(
                                          Icons.location_on,
                                          size: 14,
                                          color: Colors.redAccent,
                                        ),
                                        Text(
                                          " ${hospital.distance}km",
                                          style: const TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.redAccent,
                                          ),
                                        ),
                                        Container(
                                          margin: const EdgeInsets.symmetric(
                                            horizontal: 6,
                                          ),
                                          width: 1,
                                          height: 10,
                                          color: Colors.grey,
                                        ),
                                        Expanded(
                                          child: Text(
                                            hospital.address,
                                            style: TextStyle(
                                              fontSize: 13,
                                              color: const Color(
                                                0xFF44403B,
                                              ).withOpacity(0.6),
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              // 전화 버튼
                              InkWell(
                                onTap: () async {
                                  final Uri url = Uri(
                                    scheme: 'tel',
                                    path: hospital.phoneNumber,
                                  );
                                  if (await canLaunchUrl(url)) {
                                    await launchUrl(url);
                                  }
                                },
                                borderRadius: BorderRadius.circular(50),
                                child: Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: Colors.redAccent.withOpacity(0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.call,
                                    color: Colors.redAccent,
                                    size: 20,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
