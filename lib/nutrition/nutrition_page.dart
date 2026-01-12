import 'package:flutter/material.dart';
import 'dart:math';
import '../record/record_data.dart' as record;
import '../home/sheets/pet_register_sheet.dart';
import 'nutrition_components.dart';
import '../home/models/pet_model.dart';
// [추가] 공통 탭바 위젯 import
import '../home/widgets/pet_tab_bar.dart';

class NutritionPage extends StatefulWidget {
  final VoidCallback? onRefresh;
  const NutritionPage({super.key, this.onRefresh});
  @override
  State<NutritionPage> createState() => _NutritionPageState();
}

class _NutritionPageState extends State<NutritionPage> {
  String _activityLevel = "보통";

  int _calculateDailyFood(Map<String, dynamic> profile) {
    double weight = double.tryParse(profile['weight']?.toString() ?? '0') ?? 0;
    if (weight <= 0) return 0;

    bool isNeutered =
        profile['isNeutered'] == true ||
        profile['isNeutered'].toString() == 'true';
    String type = profile['type']?.toString() ?? "강아지";

    double rer = 70 * pow(weight, 0.75).toDouble();
    double k = (type == "강아지")
        ? (isNeutered ? 1.6 : 1.8)
        : (isNeutered ? 1.2 : 1.4);
    if (_activityLevel == "저조") k -= 0.2;
    if (_activityLevel == "활발") k += 0.4;
    return (rer * k / 3.5).round();
  }

  // 펫 추가 로직 (함수로 분리)
  void _openAddPetDialog() async {
    final result = await showDialog(
      context: context,
      builder: (context) => const Dialog(
        backgroundColor: Colors.transparent,
        child: PetRegisterSheet(),
      ),
    );

    if (result != null && result is Pet) {
      String newId = DateTime.now().millisecondsSinceEpoch.toString();

      setState(() {
        record.myPetIds.add(newId);
        record.petProfiles[newId] = {
          "name": result.name,
          "species": result.species,
          "age": result.age,
          "height": result.height,
          "weight": result.weight,
          "gender": result.gender,
          "isNeutered": result.isNeutered,
          "imagePath": result.imageFile?.path ?? result.imageAsset,
        };
        record.weightHistory[newId] = [];
        if (record.petChecklists[newId] == null) {
          record.petChecklists[newId] = [];
        }

        // 새 펫 선택
        record.selectedPetId = newId;
      });
      if (widget.onRefresh != null) widget.onRefresh!();
    }
  }

  @override
  Widget build(BuildContext context) {
    // 1. 현재 선택된 ID 가져오기
    String currentPetId = record.selectedPetId;

    // 유효성 검사 및 기본값 설정
    if ((currentPetId.isEmpty || !record.myPetIds.contains(currentPetId)) &&
        record.myPetIds.isNotEmpty) {
      currentPetId = record.myPetIds[0];
      record.selectedPetId = currentPetId;
    }

    // 2. ID로 데이터 조회
    Map<String, dynamic> currentProfile =
        record.petProfiles[currentPetId] ?? {};
    double profileWeight =
        double.tryParse(currentProfile['weight']?.toString() ?? '0') ?? 0;
    String displayPetName = currentProfile['name']?.toString() ?? "이름 없음";

    // 3. 그래프 데이터 초기화
    if (currentPetId.isNotEmpty) {
      if (record.weightHistory[currentPetId] == null) {
        record.weightHistory[currentPetId] = [];
      }
      if (record.weightHistory[currentPetId]!.isEmpty && profileWeight > 0) {
        record.weightHistory[currentPetId]!.add({
          "date": DateTime(2000, 1, 1),
          "weight": profileWeight,
        });
      }
    }

    List<Map<String, dynamic>> history =
        record.weightHistory[currentPetId] ?? [];
    double currentWeight = history.isNotEmpty
        ? (history.last['weight'] as double)
        : profileWeight;
    int foodAmount = _calculateDailyFood(currentProfile);

    return Container(
      color: const Color(0xFFF1F2ED),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 15, 20, 30),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // [수정] _buildPetSelectionBar 삭제 후 PetTabBar 사용
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
              profile: currentProfile,
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
                setState(() {});
                if (widget.onRefresh != null) widget.onRefresh!();
              },
            ),
          ],
        ),
      ),
    );
  }
}
