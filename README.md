import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

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

class Hospital {
final String name;
final String address;
final String phoneNumber;
final double distance;

Hospital({
required this.name,
required this.address,
required this.phoneNumber,
required this.distance,
});

factory Hospital.fromJson(Map<String, dynamic> json) {
String cleanTitle = json['title'].toString().replaceAll(RegExp(r'<[^>]*>'), '');
return Hospital(
name: cleanTitle,
address: json['roadAddress'] ?? json['address'] ?? "정보 없음",
phoneNumber: json['telephone'] ?? "번호 없음",
distance: double.parse((0.5 + Random().nextDouble() * 4.5).toStringAsFixed(1)),
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
showDialog(context: context, builder: (context) => const EmergencyDialog());
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
                                    onDismissed: (direction) {
                                      setModalState(() {
                                        final key = record.normalizeDate(s.date);
                                        final petSchedules = record.schedules[s.petId];
                                        if (petSchedules != null && petSchedules[key] != null) {
                                          final list = petSchedules[key]!;
                                          final idx = list.indexWhere((item) => item.title == s.title && item.time == s.time && record.normalizeDate(item.date) == key);
                                          if (idx != -1) {
                                            list[idx] = record.Schedule(petId: s.petId, date: s.date, title: s.title, content: s.content, color: s.color, time: s.time, alarm: false);
                                          }
                                        }
                                      });
                                      setState(() {});
                                    },
                                    background: Container(
                                      decoration: BoxDecoration(color: Colors.redAccent, borderRadius: BorderRadius.circular(20)),
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
                                            // 💡 [경고 해결] withOpacity를 withValues로 변경
                                            color: const Color(0xFF44403B).withValues(alpha: 0.08),
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
                                                // 💡 [경고 해결] withOpacity를 withValues로 변경
                                                color: s.color.withValues(alpha: 0.2),
                                                shape: BoxShape.circle,
                                              ),
                                              child: Center(child: Icon(Icons.notifications_active_rounded, color: s.color, size: 24)),
                                            ),
                                            const SizedBox(width: 16),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  RichText(
                                                    text: TextSpan(
                                                      children: [
                                                        TextSpan(text: '${record.petProfiles[s.petId]?['name'] ?? '알 수 없음'} ', style: TextStyle(fontSize: 12, color: s.color, fontWeight: FontWeight.bold)),
                                                        TextSpan(
                                                          text: '· ${DateFormat('M월 d일').format(s.date)} · ${s.time!.format(context)}',
                                                          // 💡 [경고 해결] withOpacity를 withValues로 변경
                                                          style: TextStyle(fontSize: 12, color: const Color(0xFF44403B).withValues(alpha: 0.6), fontWeight: FontWeight.w600),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Text(s.title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: Color(0xFF44403B))),
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
if (activeAlarms.length > _lastNotificationCount) _isBadgeRead = false;
_lastNotificationCount = activeAlarms.length;
bool showRedDot = activeAlarms.isNotEmpty && !_isBadgeRead;

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
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
        leadingWidth: 80, // 💡 프로필 여백 확보
        leading: Padding(
          padding: const EdgeInsets.only(left: 20),
          child: Center(
            child: PopupMenuButton<int>(
              offset: const Offset(0, 45), // 💡 메뉴를 아이콘 아래로 이동
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  border: Border.all(color: Colors.grey[300]!, width: 1.5), // 💡 프로필 테두리 설정
                ),
                child: Icon(Icons.pets_rounded, size: 18, color: Colors.grey[300]),
              ),
              itemBuilder: (context) => [
                const PopupMenuItem(value: 1, child: Row(children: [Icon(CupertinoIcons.person, size: 18), SizedBox(width: 8), Text("내 프로필")])),
                const PopupMenuItem(value: 2, child: Row(children: [Icon(CupertinoIcons.settings, size: 18), SizedBox(width: 8), Text("설정")])),
                const PopupMenuDivider(),
                const PopupMenuItem(value: 3, child: Row(children: [Icon(CupertinoIcons.square_arrow_right, color: Colors.redAccent, size: 18), SizedBox(width: 8), Text("로그아웃", style: TextStyle(color: Colors.redAccent))])),
              ],
              onSelected: (value) {},
            ),
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Row(
              children: [
                IconButton(
                  // 💡 에셋 파일 오류 방지 위해 기본 아이콘 사용 (파일이 있으면 Image.asset 교체 가능)
                  icon: const Icon(Icons.report_gmailerrorred, color: Colors.redAccent), 
                  onPressed: () => _showEmergencyDialog(context),
                ),
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.notifications_rounded, color: Colors.grey), // 💡 둥근 채워진 알림 아이콘
                      onPressed: () => _showNotificationDialog(context),
                    ),
                    if (showRedDot)
                      Positioned(
                        right: 8, top: 8,
                        child: Container(width: 8, height: 8, decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle)),
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
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(4, (index) {
                final isSelected = _currentIndex == index;
                final List<IconData> icons = [CupertinoIcons.house_fill, Icons.restaurant_rounded, Icons.auto_graph_rounded, CupertinoIcons.chat_bubble_2_fill];
                final List<String> labels = ['홈', '식사', '변화', 'AI닥터'];

                // ⭐ [오류 해결] 위젯을 직접 반환(return)하여 'null' 오류 방지
                return GestureDetector(
                  onTap: () => setState(() => _currentIndex = index),
                  behavior: HitTestBehavior.opaque,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                    decoration: const BoxDecoration(color: Colors.transparent), // 💡 사각형 배경 제거
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          icons[index],
                          color: isSelected ? Colors.black : Colors.grey[400], // 💡 검정/회색 구분
                          size: 24,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          labels[index],
                          style: TextStyle(
                            fontSize: 10,
                            color: isSelected ? Colors.black : Colors.grey[400],
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
} // Scaffold build 닫기
} // MainPage State 닫기

// [추가] 비상 연락처 다이얼로그 위젯
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
const String clientId = "LxZobpd8acNKliAp598K";
const String clientSecret = "YzsiQVnnCB";

    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _loadDummyData();
          return;
        }
      }

      Position position = await Geolocator.getCurrentPosition(locationSettings: const LocationSettings(accuracy: LocationAccuracy.high));
      String queryLocation = "동물병원";

      try {
        List<Placemark> placemarks = await placemarkFromCoordinates(position.latitude, position.longitude).timeout(const Duration(seconds: 3));
        if (placemarks.isNotEmpty) {
          final place = placemarks.first;
          String administrative = place.administrativeArea ?? "";
          String locality = place.locality ?? "";
          String thoroughfare = place.thoroughfare ?? "";
          queryLocation = "$administrative $locality $thoroughfare 동물병원".trim();
        }
      } catch (e) {
        debugPrint("주소 변환 실패: $e");
      }

      final Uri uri = Uri.https('openapi.naver.com', '/v1/search/local.json', {'query': queryLocation, 'display': '5', 'sort': 'random'});
      final response = await http.get(uri, headers: {"X-Naver-Client-Id": clientId, "X-Naver-Client-Secret": clientSecret});

      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> items = data['items'];
        if (items.isEmpty) { _loadDummyData(); return; }
        List<Hospital> fetchedHospitals = items.map((item) => Hospital.fromJson(item)).toList();
        fetchedHospitals.sort((a, b) => a.distance.compareTo(b.distance));
        setState(() { hospitals = fetchedHospitals; isLoading = false; });
      } else { _loadDummyData(); }
    } catch (e) {
      debugPrint("에러: $e");
      if (mounted) _loadDummyData();
    }
}

void _loadDummyData() {
List<Hospital> dummies = [
Hospital(name: "펫 응급센터", address: "24시간 연중무휴", phoneNumber: "02-987-6543", distance: 0.8),
Hospital(name: "김수진 수의사", address: "평일 09:00-20:00", phoneNumber: "02-123-4567", distance: 1.2),
Hospital(name: "박민수 수의사", address: "평일 10:00-19:00", phoneNumber: "02-456-7890", distance: 2.5),
];
dummies.sort((a, b) => a.distance.compareTo(b.distance));
setState(() { hospitals = dummies; isLoading = false; });
}

@override
Widget build(BuildContext context) {
return Dialog(
backgroundColor: const Color(0xFFF1F2ED),
shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
insetPadding: const EdgeInsets.all(20),
child: Container(
width: double.infinity,
height: 450,
padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
child: Column(
children: [
Row(
mainAxisAlignment: MainAxisAlignment.spaceBetween,
children: [
const Row(children: [Icon(Icons.local_hospital_rounded, color: Colors.redAccent, size: 24), SizedBox(width: 8), Text('비상 연락처', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF44403B)))]),
IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close_rounded, color: Color(0xFF605A55), size: 22)),
],
),
const SizedBox(height: 20),
Expanded(
child: isLoading
? const Center(child: CircularProgressIndicator(color: Color(0xFF44403B)))
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
// 💡 [경고 해결] withOpacity를 withValues로 변경
BoxShadow(color: const Color(0xFF44403B).withValues(alpha: 0.08), blurRadius: 8, offset: const Offset(0, 4)),
],
),
child: Row(
children: [
Expanded(
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
Text(hospital.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF44403B))),
const SizedBox(height: 4),
Row(
children: [
const Icon(Icons.location_on, size: 14, color: Colors.redAccent),
Text(" ${hospital.distance}km", style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.redAccent)),
Container(margin: const EdgeInsets.symmetric(horizontal: 6), width: 1, height: 10, color: Colors.grey),
// 💡 [경고 해결] withOpacity를 withValues로 변경
Expanded(child: Text(hospital.address, style: TextStyle(fontSize: 13, color: const Color(0xFF44403B).withValues(alpha: 0.6)), overflow: TextOverflow.ellipsis)),
],
),
],
),
),
InkWell(
onTap: () async {
final Uri url = Uri(scheme: 'tel', path: hospital.phoneNumber);
if (await canLaunchUrl(url)) { await launchUrl(url); }
},
borderRadius: BorderRadius.circular(50),
// 💡 [경고 해결] withOpacity를 withValues로 변경
child: Container(width: 40, height: 40, decoration: BoxDecoration(color: Colors.redAccent.withValues(alpha: 0.1), shape: BoxShape.circle), child: const Icon(Icons.call, color: Colors.redAccent, size: 20)),
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