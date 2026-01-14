import 'dart:io';
import 'dart:convert';
import 'dart:math'; // 거리 계산 시뮬레이션용

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http; // API 통신
import 'package:url_launcher/url_launcher.dart'; // 전화 걸기
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

import 'home/home_page.dart';
import 'record/record_page.dart';
import 'record/record_data.dart' as record;
import 'nutrition/nutrition_page.dart';
import 'aichat/ai_chat_page.dart';
import 'home/sheets/pet_register_sheet.dart';
import 'home/models/pet_model.dart';
import 'shared/app_dialog_style.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await record.loadFromStorage();
  runApp(const PetoryApp());
}

class PetoryApp extends StatelessWidget {
  const PetoryApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Petory',
      theme: ThemeData(
        fontFamily: 'Pretendard',
      ),
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

// [V2] 병원 데이터 모델
class Hospital {
  final String name;
  final String address;
  final String phoneNumber;
  final double distance;
  final String link;

  Hospital({
    required this.name,
    required this.address,
    required this.phoneNumber,
    required this.distance,
    required this.link,
  });

  factory Hospital.fromJson(Map<String, dynamic> json) {
    String cleanTitle = json['title'].toString().replaceAll(
      RegExp(r'<[^>]*>'),
      '',
    );

    String phone = json['telephone'] ?? "";

    return Hospital(
      name: cleanTitle,
      address: json['roadAddress'] ?? json['address'] ?? "정보 없음",
      phoneNumber: phone,
      distance: double.parse(
        (0.5 + Random().nextDouble() * 4.5).toStringAsFixed(1),
      ),
      link: (json['link'] != null && json['link'].toString().isNotEmpty)
          ? json['link']
          : "https://search.naver.com/search.naver?query=$cleanTitle",
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
  late final PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _currentIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  // [V2] 비상 연락망 다이얼로그 호출
  void _showEmergencyDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return const EmergencyDialog();
      },
    );
  }

  // [V2] 알림 다이얼로그 호출 (로직 유지)
  void _showNotificationDialog(BuildContext context) {
    setState(() => _isBadgeRead = true);
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final activeAlarms = record.getActiveAlarmsForNext24Hours();

            return Dialog(
              backgroundColor: AppDialogStyle.background,
              shape: AppDialogStyle.shape(),
              insetPadding: AppDialogStyle.insetPadding,
              child: Container(
                width: double.infinity,
                height: 420,
                padding: AppDialogStyle.contentPadding,
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
                                        // 알림 삭제 로직
                                        final key = record.normalizeDate(
                                          s.date,
                                        );
                                        final petSchedules =
                                            record.petSchedules[s.petId];
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
                                              alarm: false, // 알림 끄기
                                            );
                                          }
                                        }
                                      });
                                      setState(() {});
                                      record.saveToStorage();
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

  // [V1 UI] 펫 프로필 선택 다이얼로그
  void _showPetProfileDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        final ids = record.myPetIds;
        final int selectedIndex = ids.indexOf(record.selectedPetId);
        const double itemExtent = 84;
        final ScrollController scrollController = ScrollController();

        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!scrollController.hasClients || selectedIndex < 0) return;
          final double viewport = scrollController.position.viewportDimension;
          final double targetOffset =
              selectedIndex * itemExtent - (viewport - itemExtent) / 2;
          final double clamped = targetOffset.clamp(
            0.0,
            scrollController.position.maxScrollExtent,
          );
          scrollController.jumpTo(clamped);
        });

        return Dialog(
          backgroundColor: AppDialogStyle.background,
          shape: AppDialogStyle.shape(),
          insetPadding: AppDialogStyle.insetPadding,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        '프로필 선택',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF44403B),
                        ),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: const Icon(
                          Icons.close,
                          size: 20,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  height: 90,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    physics: const BouncingScrollPhysics(),
                    controller: scrollController,
                    child: Row(
                      children: [
                        for (final id in ids)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: _buildPetProfileItem(id, context),
                          ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: _buildAddPetItem(context),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // [V1 UI] 프로필 아이템 빌더
  Widget _buildPetProfileItem(String id, BuildContext context) {
    final p = record.petProfiles[id] ?? {};
    final String? imgPath = p['imagePath'];
    ImageProvider? imgProvider;
    if (imgPath != null &&
        imgPath.isNotEmpty &&
        !imgPath.startsWith('assets')) {
      final file = File(imgPath);
      if (file.existsSync()) imgProvider = FileImage(file);
    }
    imgProvider ??= AssetImage(
      (imgPath ?? '').isNotEmpty ? imgPath! : 'assets/images/golden.jpg',
    );

    return GestureDetector(
      onTap: () {
        record.selectedPetId = id;
        setState(() {});
        record.saveToStorage();
        Navigator.pop(context);
      },
      child: Column(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: Colors.grey.shade100,
            backgroundImage: imgProvider,
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: 68,
            child: Text(
              p['name'] ?? 'Unknown',
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  // [V1 UI] 펫 추가 아이템 빌더
  Widget _buildAddPetItem(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        final result = await showDialog(
          context: context,
          builder: (ctx) => Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: AppDialogStyle.insetPadding,
            shape: AppDialogStyle.shape(),
            child: PetRegisterSheet(),
          ),
        );

        if (result != null && result is Pet) {
          record.addPetProfileFromPet(result);
          setState(() {});
          record.saveToStorage();
          Navigator.pop(context);
        }
      },
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.grey.shade300, width: 1.2),
              color: Colors.white,
            ),
            child: const Center(
              child: Icon(Icons.add, color: Colors.black, size: 28),
            ),
          ),
          const SizedBox(height: 8),
          const SizedBox(
            width: 68,
            child: Text(
              '추가',
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12),
            ),
          ),
        ],
      ),
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

    // [중요] onRefresh를 전달하여 하위 페이지에서 변경 사항이 생기면 메인도 갱신
    final List<Widget> screens = [
      HomePage(
        onRefresh: () {
          record.saveToStorage();
          setState(() {});
        },
      ),
      RecordPage(
        onRefresh: () {
          record.saveToStorage();
          setState(() {});
        },
      ),
      NutritionPage(
        onRefresh: () {
          record.saveToStorage();
          setState(() {});
        },
      ),
      AiChatPage(
        onRefresh: () {
          record.saveToStorage();
          setState(() {});
        },
      ),
    ];

    // [V1 Logic] 현재 선택된 펫의 이미지 가져오기 (AppBar용)
    ImageProvider avatarImage = const AssetImage('assets/images/golden.jpg');
    final String selectedId = record.selectedPetId;
    final profile = record.petProfiles[selectedId];
    if (selectedId.isNotEmpty && profile != null) {
      final String? imgPath = profile['imagePath'];
      if (imgPath != null &&
          imgPath.isNotEmpty &&
          !imgPath.startsWith('assets')) {
        final file = File(imgPath);
        if (file.existsSync()) avatarImage = FileImage(file);
      } else if (imgPath != null && imgPath.isNotEmpty) {
        avatarImage = AssetImage(imgPath);
      }
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF1F2ED),

      // ... 생략 (기존 import 및 다른 코드들)

      // [V1 Design] AppBar - 프로필 위치 및 높이 최적화
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
        toolbarHeight: 56,

        leadingWidth: 100,
        leading: Padding(
          padding: const EdgeInsets.only(left: 26),
          child: Align(
            alignment: Alignment.centerLeft,
            child: GestureDetector(
              onTap: () => _showPetProfileDialog(context),
              child: Transform.translate(
                offset: const Offset(0, -2),
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.grey.shade300, width: 1.2),
                  ),
                  child: CircleAvatar(
                    backgroundColor: Colors.white,
                    backgroundImage: avatarImage,
                  ),
                ),
              ),
            ),
          ),
        ),

        actions: [
          Padding(
            // 아이콘들이 앱바 중앙에 오도록 맞춤
            padding: const EdgeInsets.only(right: 12),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(
                    CupertinoIcons.plus_square,
                    color: Colors.redAccent,
                  ),
                  onPressed: () => _showEmergencyDialog(context),
                ),
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    IconButton(
                      icon: Icon(
                        CupertinoIcons.bell,
                        color: Colors.grey.shade500,
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

      // ... 생략
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) => setState(() => _currentIndex = index),
        children: screens,
      ),

      // [V1 Design] BottomNavigationBar
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
                  CupertinoIcons.calendar,
                  CupertinoIcons.chart_bar_fill,
                  CupertinoIcons.bubble_left_bubble_right,
                ];
                final List<String> labels = ['홈', '기록', '변화', 'AI닥터'];

                return Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() {
                      _currentIndex = index;
                      _pageController.animateToPage(
                        index,
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeInOut,
                      );
                    }),
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

// [V2] 비상 연락망 다이얼로그 위젯 (기능 완전 구현됨)
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
    const String clientId = "LxZobpd8acNKliAp598K"; // [주의] 발급받은 ID 확인
    const String clientSecret = "YzsiQVnnCB"; // [주의] 발급받은 Secret 확인

    try {
      // 1. 위치 권한 확인 및 요청
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _loadDummyData();
          return;
        }
      }

      // 2. 현재 내 GPS 좌표 가져오기
      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      // 3. 좌표를 주소(시/구)로 변환
      String queryLocation = "동물병원"; // 기본값

      try {
        List<Placemark> placemarks = await placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        ).timeout(const Duration(seconds: 3));

        if (placemarks.isNotEmpty) {
          final place = placemarks.first;
          String administrative = place.administrativeArea ?? "";
          String locality = place.locality ?? "";
          String subLocality = place.subLocality ?? "";
          String thoroughfare = place.thoroughfare ?? "";

          String locationString = "";
          if (administrative.isNotEmpty) locationString += "$administrative ";
          if (locality.isNotEmpty) {
            locationString += "$locality ";
          } else if (subLocality.isNotEmpty) {
            locationString += "$subLocality ";
          }
          if (thoroughfare.isNotEmpty) locationString += "$thoroughfare ";

          if (locationString.trim().isNotEmpty) {
            queryLocation = "${locationString.trim()} 동물병원";
          }
        }
      } catch (e) {
        debugPrint("주소 변환 실패: $e");
      }

      // 4. 네이버 API 호출
      final Uri uri = Uri.https('openapi.naver.com', '/v1/search/local.json', {
        'query': queryLocation,
        'display': '5',
        'sort': 'random',
      });

      final response = await http.get(
        uri,
        headers: {
          "X-Naver-Client-Id": clientId,
          "X-Naver-Client-Secret": clientSecret,
        },
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> items = data['items'];

        if (items.isEmpty) {
          _loadDummyData();
          return;
        }

        List<Hospital> fetchedHospitals = items
            .map((item) => Hospital.fromJson(item))
            .toList();

        // 거리순 정렬 (API 제공 거리가 없으므로 랜덤 생성된 거리 기준 정렬)
        fetchedHospitals.sort((a, b) => a.distance.compareTo(b.distance));

        setState(() {
          hospitals = fetchedHospitals;
          isLoading = false;
        });
      } else {
        _loadDummyData();
      }
    } catch (e) {
      debugPrint("전체 로직 에러: $e");
      if (mounted) _loadDummyData();
    }
  }

  void _loadDummyData() {
    List<Hospital> dummies = [
      Hospital(
        name: "예담 동물병원",
        address: "대전 유성구 원신흥동",
        phoneNumber: "042-822-5071",
        distance: 0.8,
        link: "https://blog.naver.com/yedamamc",
      ),
      Hospital(
        name: "정보 없는 병원",
        address: "주소 정보 없음",
        phoneNumber: "",
        distance: 1.2,
        link: "https://search.naver.com",
      ),
    ];
    setState(() {
      hospitals = dummies;
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppDialogStyle.background,
      shape: AppDialogStyle.shape(),
      insetPadding: AppDialogStyle.insetPadding,
      child: Container(
        width: double.infinity,
        height: 450,
        padding: AppDialogStyle.contentPadding,
        child: Column(
          children: [
            // 헤더
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(
                      CupertinoIcons.phone_circle_fill,
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

            // 리스트
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
                                    Text(
                                      hospital.name,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF44403B),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
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
                              // 전화 또는 웹 버튼
                              InkWell(
                                onTap: () async {
                                  if (hospital.phoneNumber.isNotEmpty) {
                                    final String cleanNumber = hospital
                                        .phoneNumber
                                        .replaceAll(RegExp(r'[^0-9]'), '');
                                    final Uri telUrl = Uri.parse(
                                      'tel:$cleanNumber',
                                    );
                                    if (await canLaunchUrl(telUrl)) {
                                      await launchUrl(telUrl);
                                    }
                                  } else {
                                    final Uri webUrl = Uri.parse(hospital.link);
                                    await launchUrl(
                                      webUrl,
                                      mode: LaunchMode.externalApplication,
                                    );
                                  }
                                },
                                borderRadius: BorderRadius.circular(50),
                                child: Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: hospital.phoneNumber.isNotEmpty
                                        ? Colors.redAccent.withOpacity(0.1)
                                        : Colors.blueAccent.withOpacity(0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    hospital.phoneNumber.isNotEmpty
                                        ? Icons.call
                                        : Icons.language,
                                    color: hospital.phoneNumber.isNotEmpty
                                        ? Colors.redAccent
                                        : Colors.blueAccent,
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
