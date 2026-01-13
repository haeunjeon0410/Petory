import 'dart:convert';
import 'dart:math'; // 거리 계산 시뮬레이션용
import 'dart:io'; // File 사용 (아바타 이미지)
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http; // [추가] API 통신
import 'package:url_launcher/url_launcher.dart'; // [추가] 전화 걸기
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

import 'home/home_page.dart';
import 'home/sheets/pet_register_sheet.dart'; // 팝업에서 프로필 추가를 위해 import
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

  // 펫 프로필 다이얼로그 표시 (원형 아바타, 깔끔한 화이트 팝업)
  void _showPetProfileDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        final ids = record.myPetIds;

        return Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 28,
            vertical: 24,
          ),
          child: Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      '펫 선택',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close, size: 20),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // 아바타 목록(가로 스크롤)
                SizedBox(
                  height: 110,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        const SizedBox(width: 6),
                        // 등록된 펫들
                        ...ids.map((id) {
                          final p = record.petProfiles[id] ?? {};
                          final String? imgPath = p['imagePath'];
                          ImageProvider? imgProvider;
                          if (imgPath != null &&
                              imgPath.isNotEmpty &&
                              !imgPath.startsWith('assets')) {
                            final file = File(imgPath);
                            if (file.existsSync()) {
                              imgProvider = FileImage(file);
                            }
                          }
                          imgProvider ??= AssetImage(
                            (imgPath ?? '').isNotEmpty
                                ? imgPath!
                                : 'assets/images/golden.jpg',
                          );

                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: GestureDetector(
                              onTap: () {
                                record.selectedPetId = id;
                                setState(() {});
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
                                      p['name'] ?? '이름 없음',
                                      overflow: TextOverflow.ellipsis,
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }),

                        // 추가 버튼 (+)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: GestureDetector(
                            onTap: () async {
                              // PetRegisterSheet 열기
                              final result = await showDialog(
                                context: context,
                                builder: (ctx) => Dialog(
                                  backgroundColor: Colors.transparent,
                                  insetPadding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: PetRegisterSheet(),
                                ),
                              );

                              if (result != null) {
                                // result는 Pet 객체 형태 예상 (home/models/pet_model.dart)
                                final dynamic pet = result;
                                String? imagePath;
                                if (pet.imageFile != null) {
                                  imagePath = (pet.imageFile as File).path;
                                } else {
                                  imagePath = pet.imageAsset;
                                }

                                // 새 ID 추가 및 선택
                                final String newId = DateTime.now()
                                    .millisecondsSinceEpoch
                                    .toString();
                                record.myPetIds.add(newId);
                                record.petProfiles[newId] = {
                                  "name": pet.name,
                                  "type": pet.type,
                                  "species": pet.species,
                                  "age": pet.age,
                                  "height": pet.height,
                                  "weight": pet.weight,
                                  "gender": pet.gender,
                                  "isNeutered": pet.isNeutered,
                                  "imagePath": imagePath,
                                };
                                record.petChecklists[newId] = [];
                                record.selectedPetId = newId;
                                setState(() {});
                                Navigator.pop(context); // 팝업 닫기
                              }
                            },
                            child: Column(
                              children: [
                                Container(
                                  width: 60,
                                  height: 60,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.grey.shade300,
                                      width: 1.2,
                                    ),
                                    color: Colors.white,
                                  ),
                                  child: const Center(
                                    child: Icon(
                                      Icons.add,
                                      color: Colors.black,
                                      size: 28,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                const SizedBox(
                                  width: 68,
                                  child: Text(
                                    '프로필 추가',
                                    overflow: TextOverflow.ellipsis,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(fontSize: 12),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
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

    // 언셀렉티드 아이콘/텍스트 색상: 앱바의 발자국/종 아이콘과 동일하게 맞춤
    final Color unselectedIconColor = Colors.grey.shade500;

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
        backgroundColor: Colors.white, // 변경: 앱바 배경을 흰색으로
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
        leading: Padding(
          padding: const EdgeInsets.only(left: 12),
          child: IconButton(
            icon: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.grey.shade300, // 연한 테두리
                  width: 1.2,
                ),
              ),
              child: Center(
                child: Icon(
                  CupertinoIcons.paw,
                  color: Colors.grey.shade500, // 연한 회색 아이콘
                  size: 18,
                ),
              ),
            ),
            tooltip: '펫 프로필',
            onPressed: () => _showPetProfileDialog(context),
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
                    Icons.local_hospital_rounded,
                    color: Colors.redAccent,
                  ),
                  tooltip: '비상 연락처',
                  onPressed: () => _showEmergencyDialog(context),
                ),

                // 2. 기존 알림 버튼 (오른쪽)
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    IconButton(
                      icon: Icon(
                        CupertinoIcons.bell,
                        color: Colors.grey.shade500, // 연한 회색 종 아이콘
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
                // 변경: 레이블에 더 적합한 아이콘으로 교체
                final List<IconData> icons = [
                  Icons.home, // 홈
                  Icons.restaurant, // 식사
                  Icons.trending_up, // 변화 (트렌드)
                  Icons.chat_bubble_rounded, // AI채팅
                ];
                final List<String> labels = ['홈', '식사', '변화', 'AI채팅'];
                return Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _currentIndex = index),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            icons[index],
                            size: 20,
                            color: isSelected
                                ? const Color(0xFF44403B)
                                : unselectedIconColor,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            labels[index],
                            style: TextStyle(
                              fontSize: 9,
                              color: isSelected
                                  ? const Color(0xFF44403B)
                                  : unselectedIconColor,
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
    const String clientId = "LxZobpd8acNKliAp598K"; // [주의] 발급받은 ID 입력
    const String clientSecret = "YzsiQVnnCB"; // [주의] 발급받은 Secret 입력

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
        // [수정 핵심 1] timeout 설정 (3초 안에 응답 없으면 취소) 및 한국어 설정
        List<Placemark> placemarks = await placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        ).timeout(const Duration(seconds: 3));

        if (placemarks.isNotEmpty) {
          final place = placemarks.first;
          // 행정구역(시/도) + 시/군/구 조합
          String administrative = place.administrativeArea ?? ""; // 예: 대전광역시
          String locality = place.locality ?? ""; // 예: 유성구 (또는 시)
          String subLocality =
              place.subLocality ?? ""; // 예: 유성구 (locality가 비었을 경우)
          String thoroughfare = place.thoroughfare ?? ""; // 예: 궁동 (동 단위)

          // 구글 지오코더는 한국 주소 체계가 복잡하여 locality와 subLocality가 섞일 때가 많음
          // 최대한 겹치지 않게 조합
          String locationString = "";

          if (administrative.isNotEmpty) locationString += "$administrative ";

          // locality와 subLocality 중 있는 것을 사용
          if (locality.isNotEmpty) {
            locationString += "$locality ";
          } else if (subLocality.isNotEmpty) {
            locationString += "$subLocality ";
          }

          // 동 단위까지 있으면 정확도 상승
          if (thoroughfare.isNotEmpty) locationString += "$thoroughfare ";

          if (locationString.trim().isNotEmpty) {
            queryLocation = "${locationString.trim()} 동물병원";
          }
        }
      } catch (e) {
        debugPrint("주소 변환 실패(시간 초과 등): $e");
        // [수정 핵심 3] 주소 변환 실패 시 '내 주변' 검색을 위한 차선책
        // 여기서는 간단히 '동물병원'으로 검색되지만,
        // 실제로는 사용자에게 '주소를 찾을 수 없어 기본 검색합니다' 등을 알릴 수 있음.
      }

      debugPrint("최종 검색어: $queryLocation");

      // 4. 네이버 API 호출
      final Uri uri = Uri.https('openapi.naver.com', '/v1/search/local.json', {
        'query': queryLocation,
        'display': '5',
        'sort': 'random', // random으로 해야 유사도(검색어 포함) 순으로 나옴
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
          // 검색 결과가 없으면 더미 데이터라도 보여줌
          _loadDummyData();
          return;
        }

        List<Hospital> fetchedHospitals = items
            .map((item) => Hospital.fromJson(item))
            .toList();

        // 거리순 정렬 (API가 거리를 안 주므로 랜덤 값이지만 정렬하는 척)
        fetchedHospitals.sort((a, b) => a.distance.compareTo(b.distance));

        setState(() {
          hospitals = fetchedHospitals;
          isLoading = false;
        });
      } else {
        debugPrint("API 호출 오류: ${response.statusCode}");
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
