import 'dart:math';
import 'package:flutter/material.dart';
import '../home/models/pet_model.dart';

// 1. 일정 데이터 클래스
class Schedule {
  final String? petId; // [수정] petName -> petId (ID로 관리)
  final DateTime date;
  final String title;
  final String content;
  final Color color;
  final TimeOfDay? time;
  final bool alarm;

  Schedule({
    this.petId,
    required this.date,
    required this.title,
    required this.content,
    required this.color,
    this.time,
    this.alarm = false,
  });
}

DateTime normalizeDate(DateTime date) {
  return DateTime(date.year, date.month, date.day);
}

// --- [공용 데이터 섹션] ---

// [핵심 변경] 이름 대신 '고유 ID'를 저장합니다.
String selectedPetId = "default_1";

// 펫 ID 리스트
List<String> myPetIds = ["default_1"];

// ID를 키(Key)로 사용하는 프로필 데이터 맵
Map<String, Map<String, dynamic>> petProfiles = {
  "default_1": {
    "name": "맥스", // 이름은 데이터 안에만 존재
    "species": "골든 리트리버",
    "age": "3",
    "height": "60",
    "weight": "32",
    "gender": "male",
    "isNeutered": true,
    "imagePath": "assets/images/golden.jpg",
  },
};

// ID를 키(Key)로 사용하는 체크리스트 맵
Map<String, List<Map<String, dynamic>>> petChecklists = {
  "default_1": [
    {"title": "아침 식사", "time": "오전 8:00", "icon": "🍴", "isDone": true},
    {"title": "아침 산책", "time": "오전 9:00", "icon": "🦮", "isDone": true},
    {"title": "점심 산책", "time": "오후 1:00", "icon": "🐾", "isDone": false},
  ],
};

// --- [레코드 데이터 섹션] ---

// 스케줄도 ID를 키로 관리
final Map<String, Map<DateTime, List<Schedule>>> schedules = {};
final Map<String, Map<DateTime, List<String>>> photos = {};
Map<String, List<Map<String, dynamic>>> weightHistory = {};

String addPetProfileFromPet(Pet pet) {
  final String newId = DateTime.now().millisecondsSinceEpoch.toString();
  final String? imagePath = pet.imageFile?.path ?? pet.imageAsset;

  myPetIds.add(newId);
  petProfiles[newId] = {
    'name': pet.name,
    'type': pet.type,
    'species': pet.species,
    'age': pet.age,
    'height': pet.height,
    'weight': pet.weight,
    'gender': pet.gender,
    'isNeutered': pet.isNeutered,
    'imagePath': imagePath,
  };
  petChecklists.putIfAbsent(newId, () => []);
  weightHistory.putIfAbsent(newId, () => []);
  selectedPetId = newId;
  return newId;
}

int calculateDailyFood(
  Map<String, dynamic> profile, {
  String activityLevel = '\ubcf4\ud1b5',
}) {
  final double weight =
      double.tryParse(profile['weight']?.toString() ?? '0') ?? 0;
  if (weight <= 0) return 0;

  final bool isNeutered =
      profile['isNeutered'] == true ||
      profile['isNeutered'].toString() == 'true';
  final String type = profile['type']?.toString() ?? '\uac15\uc544\uc9c0';

  final double rer = 70 * pow(weight, 0.75).toDouble();
  double k = (type == '\uac15\uc544\uc9c0')
      ? (isNeutered ? 1.6 : 1.8)
      : (isNeutered ? 1.2 : 1.4);
  if (activityLevel == '\uc800\ud65c\ub3d9') k -= 0.2;
  if (activityLevel == '\ud65c\ubc1c') k += 0.4;
  return (rer * k / 3.5).round();
}

// 알림 로직 (ID 기반으로 수정)
List<Schedule> getActiveAlarmsForNext24Hours() {
  final now = DateTime.now();
  final tomorrow = now.add(const Duration(hours: 24));
  List<Schedule> active = [];

  schedules.forEach((petId, dateMap) {
    dateMap.forEach((date, list) {
      for (var s in list) {
        if (s.alarm && s.time != null) {
          final scheduleDateTime = DateTime(
            s.date.year,
            s.date.month,
            s.date.day,
            s.time!.hour,
            s.time!.minute,
          );

          if (scheduleDateTime.isAfter(now) &&
              scheduleDateTime.isBefore(tomorrow)) {
            active.add(
              Schedule(
                petId: petId, // 여기에 루프의 Key인 petId를 넣어줍니다.
                date: s.date,
                title: s.title,
                content: s.content,
                color: s.color,
                time: s.time,
                alarm: s.alarm,
              ),
            );
          }
        }
      }
    });
  });

  active.sort((a, b) {
    final aDt = DateTime(
      a.date.year,
      a.date.month,
      a.date.day,
      a.time!.hour,
      a.time!.minute,
    );
    final bDt = DateTime(
      b.date.year,
      b.date.month,
      b.date.day,
      b.time!.hour,
      b.time!.minute,
    );
    return aDt.compareTo(bDt);
  });

  return active;
}
