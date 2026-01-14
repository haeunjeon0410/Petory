import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../home/models/pet_model.dart';

// 1. 일정 데이터 클래스
class Schedule {
  final String? petId;
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

String selectedPetId = "default_1";
List<String> myPetIds = ["default_1"];

Map<String, Map<String, dynamic>> petProfiles = {
  "default_1": {
    "name": "맥스",
    "species": "골든 리트리버",
    "age": "3",
    "height": "60",
    "weight": "32",
    "gender": "male",
    "isNeutered": true,
    "activityLevel": "보통",
    "imagePath": "assets/images/golden.jpg",
  },
};

// 날짜별 체크리스트 관리
Map<String, Map<DateTime, List<Map<String, dynamic>>>> petChecklists = {
  "default_1": {
    normalizeDate(DateTime.now()): [
      {"title": "아침 식사", "time": "오전 8:00", "icon": "🍴", "isDone": true},
      {"title": "아침 산책", "time": "오전 9:00", "icon": "🦮", "isDone": true},
      {"title": "점심 산책", "time": "오후 1:00", "icon": "🐾", "isDone": false},
    ],
  },
};

// --- [레코드 데이터 섹션] ---

// [수정] home_page.dart와 일치시키기 위해 schedules -> petSchedules로 변경
final Map<String, Map<DateTime, List<Schedule>>> petSchedules = {};
final Map<String, Map<DateTime, List<String>>> photos = {};
Map<String, List<Map<String, dynamic>>> weightHistory = {};

const String _storageKey = 'record_data_v1';

// --- [JSON 변환 로직] ---

Map<String, dynamic> _scheduleToJson(Schedule schedule) {
  return {
    'petId': schedule.petId,
    'date': schedule.date.toIso8601String(),
    'title': schedule.title,
    'content': schedule.content,
    'color': schedule.color.value,
    'time': schedule.time == null
        ? null
        : {'hour': schedule.time!.hour, 'minute': schedule.time!.minute},
    'alarm': schedule.alarm,
  };
}

Schedule _scheduleFromJson(Map<String, dynamic> json) {
  final Map<String, dynamic>? timeMap = json['time'] is Map<String, dynamic>
      ? (json['time'] as Map<String, dynamic>)
      : null;
  final TimeOfDay? time = timeMap == null
      ? null
      : TimeOfDay(
          hour: (timeMap['hour'] as num?)?.toInt() ?? 0,
          minute: (timeMap['minute'] as num?)?.toInt() ?? 0,
        );
  return Schedule(
    petId: json['petId']?.toString(),
    date: DateTime.parse(json['date'] as String),
    title: json['title']?.toString() ?? '',
    content: json['content']?.toString() ?? '',
    color: Color((json['color'] as num?)?.toInt() ?? 0xFF44403B),
    time: time,
    alarm: json['alarm'] == true,
  );
}

Map<String, dynamic> _weightEntryToJson(Map<String, dynamic> entry) {
  final date = entry['date'];
  return {
    'date': date is DateTime ? date.toIso8601String() : date?.toString(),
    'weight': entry['weight'],
  };
}

Map<String, dynamic> _weightEntryFromJson(Map<String, dynamic> json) {
  return {
    'date': DateTime.parse(json['date'] as String),
    'weight': (json['weight'] as num?)?.toDouble() ?? 0,
  };
}

// --- [저장소 로직] ---

Future<void> saveToStorage() async {
  final prefs = await SharedPreferences.getInstance();
  final Map<String, dynamic> data = {
    'selectedPetId': selectedPetId,
    'myPetIds': myPetIds,
    'petProfiles': petProfiles,
    'petChecklists': petChecklists.map((petId, dateMap) {
      return MapEntry(
        petId,
        dateMap.map((date, list) {
          return MapEntry(date.toIso8601String(), list);
        }),
      );
    }),
    'photos': photos.map((petId, dateMap) {
      return MapEntry(
        petId,
        dateMap.map((date, paths) {
          return MapEntry(date.toIso8601String(), paths);
        }),
      );
    }),
    'weightHistory': weightHistory.map((petId, list) {
      return MapEntry(petId, list.map(_weightEntryToJson).toList());
    }),
    // [수정] schedules -> petSchedules
    'schedules': petSchedules.map((petId, dateMap) {
      return MapEntry(
        petId,
        dateMap.map((date, list) {
          return MapEntry(
            date.toIso8601String(),
            list.map(_scheduleToJson).toList(),
          );
        }),
      );
    }),
  };
  await prefs.setString(_storageKey, jsonEncode(data));
}

Future<void> loadFromStorage() async {
  final prefs = await SharedPreferences.getInstance();
  final raw = prefs.getString(_storageKey);
  if (raw == null || raw.isEmpty) return;

  final Map<String, dynamic> data = jsonDecode(raw) as Map<String, dynamic>;

  // 프로필 데이터 로드
  final storedPetIds = data['myPetIds'] as List<dynamic>?;
  final storedProfiles = data['petProfiles'] as Map<String, dynamic>?;
  if (storedPetIds != null && storedProfiles != null) {
    myPetIds = storedPetIds.map((e) => e.toString()).toList();
    petProfiles = storedProfiles.map(
      (key, value) =>
          MapEntry(key.toString(), Map<String, dynamic>.from(value as Map)),
    );
    selectedPetId = data['selectedPetId']?.toString() ?? '';
  }

  // 체크리스트 로드
  final storedChecklists = data['petChecklists'] as Map<String, dynamic>?;
  if (storedChecklists != null) {
    petChecklists = {};
    storedChecklists.forEach((petId, value) {
      final dateMap = <DateTime, List<Map<String, dynamic>>>{};
      if (value is Map<String, dynamic>) {
        value.forEach((dateKey, list) {
          dateMap[DateTime.parse(dateKey)] = (list as List<dynamic>)
              .map((e) => Map<String, dynamic>.from(e as Map))
              .toList();
        });
      }
      petChecklists[petId.toString()] = dateMap;
    });
  }

  // 사진 로드
  final storedPhotos = data['photos'] as Map<String, dynamic>?;
  if (storedPhotos != null) {
    photos.clear();
    storedPhotos.forEach((petId, dateMap) {
      final map = <DateTime, List<String>>{};
      (dateMap as Map<String, dynamic>).forEach((dateKey, paths) {
        map[DateTime.parse(dateKey)] = (paths as List<dynamic>)
            .map((e) => e.toString())
            .toList();
      });
      photos[petId.toString()] = map;
    });
  }

  // 체중 기록 로드
  final storedWeights = data['weightHistory'] as Map<String, dynamic>?;
  if (storedWeights != null) {
    weightHistory = storedWeights.map(
      (key, value) => MapEntry(
        key.toString(),
        (value as List<dynamic>)
            .map((e) => _weightEntryFromJson(Map<String, dynamic>.from(e)))
            .toList(),
      ),
    );
  }

  // [수정] 일정 데이터 로드 (schedules -> petSchedules)
  final storedSchedules = data['schedules'] as Map<String, dynamic>?;
  if (storedSchedules != null) {
    petSchedules.clear();
    storedSchedules.forEach((petId, dateMap) {
      final map = <DateTime, List<Schedule>>{};
      (dateMap as Map<String, dynamic>).forEach((dateKey, list) {
        map[DateTime.parse(dateKey)] = (list as List<dynamic>)
            .map((e) => _scheduleFromJson(Map<String, dynamic>.from(e)))
            .toList();
      });
      petSchedules[petId.toString()] = map;
    });
  }
}

// --- [비즈니스 로직] ---

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
    'activityLevel': pet.activityLevel,
    'imagePath': imagePath,
  };
  petChecklists.putIfAbsent(newId, () => {});
  weightHistory.putIfAbsent(newId, () => []);
  selectedPetId = newId;
  saveToStorage(); // 데이터 저장 트리거
  return newId;
}

int calculateDailyFood(
  Map<String, dynamic> profile, {
  String activityLevel = '보통',
}) {
  final double weight =
      double.tryParse(profile['weight']?.toString() ?? '0') ?? 0;
  if (weight <= 0) return 0;

  final bool isNeutered =
      profile['isNeutered'] == true ||
      profile['isNeutered'].toString() == 'true';
  final double rer = 70 * pow(weight, 0.75).toDouble();
  String level = activityLevel == '저활동' ? '저조' : activityLevel;
  double factor = 1.6;
  if (isNeutered) {
    if (level == '저조') factor = 1.2;
    if (level == '보통') factor = 1.6;
    if (level == '활발') factor = 2.0;
  } else {
    if (level == '저조') factor = 1.4;
    if (level == '보통') factor = 1.8;
    if (level == '활발') factor = 2.5;
  }
  return (rer * factor).round();
}

List<Schedule> getActiveAlarmsForNext24Hours() {
  final now = DateTime.now();
  final tomorrow = now.add(const Duration(hours: 24));
  List<Schedule> active = [];

  // [수정] schedules -> petSchedules
  petSchedules.forEach((petId, dateMap) {
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
            active.add(s);
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
