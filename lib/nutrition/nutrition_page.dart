import 'package:flutter/material.dart';
import 'dart:math';
import '../record/record_data.dart' as record;
import '../home/register_pet.dart';
import 'nutrition_components.dart';

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
    bool isNeutered = profile['isNeutered'] ?? false;
    double rer = 70 * pow(weight, 0.75).toDouble();
    double k = (profile['type'] == "강아지")
        ? (isNeutered ? 1.6 : 1.8)
        : (isNeutered ? 1.2 : 1.4);
    if (_activityLevel == "저조") k -= 0.2;
    if (_activityLevel == "활발") k += 0.4;
    return (rer * k / 3.5).round();
  }

  @override
  Widget build(BuildContext context) {
    String currentPetName =
        record.selectedPetName.isEmpty && record.myPets.isNotEmpty
        ? record.myPets[0]
        : record.selectedPetName;

    Map<String, dynamic> currentProfile =
        record.petProfiles[currentPetName] ?? {};
    double profileWeight =
        double.tryParse(currentProfile['weight']?.toString() ?? '0') ?? 0;

    // 그래프 시작점 고정 로직 (index 0)
    if (currentPetName.isNotEmpty) {
      if (record.weightHistory[currentPetName] == null)
        record.weightHistory[currentPetName] = [];
      if (record.weightHistory[currentPetName]!.isEmpty && profileWeight > 0) {
        record.weightHistory[currentPetName]!.add({
          "date": DateTime(2000, 1, 1),
          "weight": profileWeight,
        });
      }
    }

    List<Map<String, dynamic>> history =
        record.weightHistory[currentPetName] ?? [];
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
            _buildPetSelectionBar(),
            const SizedBox(height: 20),
            FoodCalculatorCard(
              profile: currentProfile,
              foodAmount: foodAmount,
              activityLevel: _activityLevel,
              onActivityChanged: (val) => setState(() => _activityLevel = val),
            ),
            const SizedBox(height: 20),
            WeightTrendCard(
              petName: currentPetName,
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

  Widget _buildPetSelectionBar() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          ...record.myPets.map((petName) {
            bool isSelected = record.selectedPetName == petName;
            return Padding(
              padding: const EdgeInsets.only(right: 10),
              child: GestureDetector(
                onTap: () {
                  setState(() => record.selectedPetName = petName);
                  if (widget.onRefresh != null) widget.onRefresh!();
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFF44403B)
                        : const Color(0xFFF1F2ED),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: const Color(0xFF44403B),
                      width: 1.5,
                    ),
                    boxShadow: [
                      if (isSelected)
                        BoxShadow(
                          color: const Color(0xFF44403B).withOpacity(0.3),
                          blurRadius: 6,
                          offset: const Offset(0, 3),
                        ),
                    ],
                  ),
                  child: Text(
                    petName,
                    style: TextStyle(
                      color: isSelected
                          ? Colors.white
                          : const Color(0xFF44403B),
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ),
              ),
            );
          }),
          GestureDetector(
            onTap: () async {
              final result = await showDialog(
                context: context,
                builder: (context) => const Dialog(
                  backgroundColor: Colors.transparent,
                  child: PetRegistrationDialog(),
                ),
              );
              if (result != null) {
                setState(() {
                  record.myPets.add(result['name']);
                  record.petProfiles[result['name']] = result;
                  record.selectedPetName = result['name'];
                });
                if (widget.onRefresh != null) widget.onRefresh!();
              }
            },
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: const Color(0xFF44403B),
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Icon(Icons.add, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}
