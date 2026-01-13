import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'home/home_page.dart';
import 'record/record_page.dart';
import 'record/record_data.dart' as record;
import 'nutrition/nutrition_page.dart';
import 'aichat/ai_chat_page.dart';
import 'home/sheets/pet_register_sheet.dart';
import 'home/models/pet_model.dart';

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

  void _showEmergencyDialog(BuildContext context) {
    showDialog(context: context, builder: (_) => const EmergencyDialog());
  }

  void _showNotificationDialog(BuildContext context) {
    setState(() => _isBadgeRead = true);
    final activeAlarms = record.getActiveAlarmsForNext24Hours();

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: const Color(0xFFF1F2ED),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        insetPadding: const EdgeInsets.all(20),
        child: SizedBox(
          height: 360,
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      '알림',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF44403B),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: const Icon(
                        Icons.close_rounded,
                        size: 20,
                        color: Color(0xFF605A55),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: activeAlarms.isEmpty
                      ? const Center(
                          child: Text(
                            '알림이 없습니다.',
                            style: TextStyle(
                              color: Color(0xFF605A55),
                              fontSize: 12,
                            ),
                          ),
                        )
                      : ListView.builder(
                          itemCount: activeAlarms.length,
                          itemBuilder: (context, index) {
                            final s = activeAlarms[index];
                            final petName =
                                record.petProfiles[s.petId]?['name'] ?? 'Pet';
                            final timeText = s.time != null
                                ? s.time!.format(context)
                                : '--:--';
                            return Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 36,
                                    height: 36,
                                    decoration: const BoxDecoration(
                                      color: Color(0xFF44403B),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.notifications,
                                      color: Colors.white,
                                      size: 18,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          s.title,
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            color: Color(0xFF44403B),
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          '$petName · $timeText',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: Color(0xFF77726E),
                                          ),
                                        ),
                                      ],
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
        ),
      ),
    );
  }

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
            horizontal: 33,
            vertical: 34,
          ),
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

  Widget _buildPetProfileItem(String id, BuildContext context) {
    final p = record.petProfiles[id] ?? {};
    final String? imgPath = p['imagePath'];
    ImageProvider? imgProvider;
    if (imgPath != null && imgPath.isNotEmpty && !imgPath.startsWith('assets')) {
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

  Widget _buildAddPetItem(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        final result = await showDialog(
          context: context,
          builder: (ctx) => Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: const EdgeInsets.symmetric(horizontal: 20),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: PetRegisterSheet(),
          ),
        );

        if (result != null && result is Pet) {
          record.addPetProfileFromPet(result);
          setState(() {});
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

    final List<Widget> screens = [
      HomePage(onRefresh: () => setState(() {})),
      RecordPage(onRefresh: () => setState(() {})),
      NutritionPage(onRefresh: () => setState(() {})),
      AiChatPage(onRefresh: () => setState(() {})),
    ];

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

      // main.dart의 AppBar 부분 수정
      // main.dart의 AppBar 부분을 이렇게 수정해 보세요!
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,

        // 1. 앱바 높이를 44~46 정도로 더 타이트하게 줄여줍니다.
        toolbarHeight: 56,

        leadingWidth: 100,
        leading: Padding(
          // 2. top 패딩을 8~10 정도로 줘서 사진을 앱바 하단에 가깝게 내려줍니다.
          padding: const EdgeInsets.only(left: 26, top: 10),
          child: Align(
            alignment: Alignment.centerLeft,
            child: GestureDetector(
              onTap: () => _showPetProfileDialog(context),
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
        // ... actions 등 나머지 유지
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(
                    Icons.local_hospital_rounded,
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
                  Icons.home,
                  Icons.assignment_rounded,
                  Icons.trending_up,
                  Icons.chat_bubble_rounded,
                ];
                final List<String> labels = [
                  '\uD648',
                  '\uAE30\uB85D',
                  '\uD1B5\uACC4',
                  'AI \uCC44\uD305',
                ];
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

class EmergencyDialog extends StatelessWidget {
  const EmergencyDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color.fromARGB(255, 255, 255, 255),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      // 가로 폭을 프로필 창과 동일하게 50으로 맞춰 통일감을 줍니다.
      insetPadding: const EdgeInsets.symmetric(horizontal: 50, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 320),
        child: Container(
          padding: const EdgeInsets.all(24),
          height: 240,
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Emergency',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF44403B),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(
                      Icons.close_rounded,
                      color: Color(0xFF605A55),
                      size: 20,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const Expanded(
                child: Center(
                  child: Text(
                    'Set up emergency contacts in this dialog.',
                    style: TextStyle(color: Color(0xFF44403B)),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
