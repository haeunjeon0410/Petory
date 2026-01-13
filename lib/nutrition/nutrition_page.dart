import 'package:flutter/material.dart';
import 'dart:math';
import '../record/record_data.dart' as record;
import '../home/sheets/pet_register_sheet.dart';
import 'nutrition_components.dart';
import '../home/models/pet_model.dart';
import '../home/widgets/pet_tab_bar.dart';

class NutritionPage extends StatefulWidget {
  final VoidCallback? onRefresh;
  const NutritionPage({super.key, this.onRefresh});
  @override
  State<NutritionPage> createState() => _NutritionPageState();
}

class _NutritionPageState extends State<NutritionPage> {
  String _activityLevel = "보통";

  // 사료량 계산 로직
  int _calculateDailyFood(Map<String, dynamic> profile, double currentWeight) {
    if (currentWeight <= 0) return 0;

    bool isNeutered =
        profile['isNeutered'] == true ||
        profile['isNeutered'].toString() == 'true';
    String type = profile['type']?.toString() ?? "강아지";

    double rer = 70 * pow(currentWeight, 0.75).toDouble();
    double k = (type == "강아지")
        ? (isNeutered ? 1.6 : 1.8)
        : (isNeutered ? 1.2 : 1.4);

    if (_activityLevel == "저조") k -= 0.2;
    if (_activityLevel == "활발") k += 0.4;

    return (rer * k / 3.5).round();
  }

  // [핵심] 프로필과 히스토리 동기화 함수
  void _syncProfileWeight(String petId) {
    List<Map<String, dynamic>> history = record.weightHistory[petId] ?? [];
    if (history.isEmpty) return;
    history.sort((a, b) => (a['date'] as DateTime).compareTo(b['date']));
    double latestWeight = double.parse(history.last['weight'].toString());

    if (record.petProfiles[petId] != null) {
      // 소수점 제거 로직
      String weightStr = latestWeight == latestWeight.toInt()
          ? latestWeight.toInt().toString()
          : latestWeight.toString();
      record.petProfiles[petId]!['weight'] = weightStr;
    }
  }

  // 펫 추가 다이얼로그
  // [수정] 펫 추가/수정 시 히스토리 자동 추가 로직
  void _openAddPetDialog() async {
    final result = await showDialog(
      context: context,
      builder: (context) => const Dialog(
        backgroundColor: Colors.transparent,
        child: PetRegisterSheet(),
      ),
    );

    if (result != null && result is Pet) {
      // 기존 로직: 새 ID 생성 (실제 앱에서는 수정 시 기존 ID 유지해야 함)
      // 여기서는 '추가' 상황을 가정합니다.
      String newId = DateTime.now().millisecondsSinceEpoch.toString();

      setState(() {
        record.myPetIds.add(newId);
        record.petProfiles[newId] = {
          "name": result.name,
          "type": result.type,
          "species": result.species,
          "age": result.age,
          "height": result.height,
          "weight": result.weight,
          "gender": result.gender,
          "isNeutered": result.isNeutered,
          "imagePath": result.imageFile?.path ?? result.imageAsset,
        };

        // [핵심 수정] 프로필 체중을 히스토리에 '오늘' 날짜로 강제 추가
        // 이렇게 해야 그래프에 점이 즉시 찍힙니다.
        double initWeight = double.tryParse(result.weight) ?? 0.0;
        record.weightHistory[newId] = [];
        if (initWeight > 0) {
          record.weightHistory[newId]!.add({
            "date": DateTime.now(),
            "weight": initWeight,
          });
        }

        if (record.petChecklists[newId] == null) {
          record.petChecklists[newId] = [];
        }
        record.selectedPetId = newId;
      });
      if (widget.onRefresh != null) widget.onRefresh!();
    }
  }

  @override
  Widget build(BuildContext context) {
    // 1. 현재 선택된 ID 확인
    String currentPetId = record.selectedPetId;
    if ((currentPetId.isEmpty || !record.myPetIds.contains(currentPetId)) &&
        record.myPetIds.isNotEmpty) {
      currentPetId = record.myPetIds[0];
      record.selectedPetId = currentPetId;
    }

    // 2. 프로필 데이터 로드
    Map<String, dynamic> currentProfile =
        record.petProfiles[currentPetId] ?? {};
    double profileWeight =
        double.tryParse(currentProfile['weight']?.toString() ?? '0') ?? 0;
    String displayPetName = currentProfile['name']?.toString() ?? "이름 없음";

    // 3. 그래프 데이터 초기화 (데이터가 아예 없을 때 프로필 값으로 채움)
    if (currentPetId.isNotEmpty) {
      if (record.weightHistory[currentPetId] == null) {
        record.weightHistory[currentPetId] = [];
      }
      // 히스토리가 비어있다면 프로필 체중을 '오늘' 날짜로 기록
      if (record.weightHistory[currentPetId]!.isEmpty && profileWeight > 0) {
        record.weightHistory[currentPetId]!.add({
          "date": DateTime.now(), // [수정] 2000년 -> DateTime.now()로 변경
          "weight": profileWeight,
        });
      }
    }

    List<Map<String, dynamic>> history =
        record.weightHistory[currentPetId] ?? [];

    // 날짜순 정렬
    history.sort((a, b) => (a['date'] as DateTime).compareTo(b['date']));

    // 최신 체중 결정 (히스토리의 마지막 값)
    double currentWeight = history.isNotEmpty
        ? double.parse(history.last['weight'].toString())
        : profileWeight;

    // 화면 표시용 프로필 (최신 체중 반영)
    Map<String, dynamic> displayProfile = Map.from(currentProfile);
    displayProfile['weight'] = currentWeight;

    // 사료량 계산
    int foodAmount = _calculateDailyFood(displayProfile, currentWeight);

    return Container(
      color: const Color(0xFFF1F2ED),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 15, 20, 30),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PetTabBar(
              petIds: record.myPetIds,
              petProfiles: record.petProfiles,
              selectedId: currentPetId,
              onTap: (id) {
                setState(() => record.selectedPetId = id);
                if (widget.onRefresh != null) widget.onRefresh!();
              },
              onAdd: _openAddPetDialog,
            ),

            const SizedBox(height: 20),

            FoodCalculatorCard(
              profile: displayProfile,
              foodAmount: foodAmount,
              activityLevel: _activityLevel,
              onActivityChanged: (val) => setState(() => _activityLevel = val),
            ),
            const SizedBox(height: 20),

            WeightTrendCard(
              petName: displayPetName,
              history: history,
              currentWeight: currentWeight,
              onUpdate: () {
                // [핵심] 그래프 데이터가 변경되면 프로필 데이터도 동기화
                setState(() {
                  _syncProfileWeight(currentPetId);
                });
                if (widget.onRefresh != null) widget.onRefresh!();
              },
            ),
          ],
        ),
      ),
    );
  }
}
