import 'package:flutter/material.dart';

// 1. 일정 데이터 클래스
class Schedule {
  final String? petName; // 어떤 펫의 일정인지 저장
  final DateTime date;
  final String title;
  final String content;
  final Color color;
  final TimeOfDay? time;
  final bool alarm;

  Schedule({
    this.petName,
    required this.date,
    required this.title,
    required this.content,
    required this.color,
    this.time,
    this.alarm = false,
  });
}

// 2. 날짜 정규화 함수 (시간 제외)
DateTime normalizeDate(DateTime date) {
  return DateTime(date.year, date.month, date.day);
}

// --- [공용 데이터 섹션] 홈 탭과 레코드 탭이 공유합니다 ---

List<String> myPets = ["맥스"];

Map<String, Map<String, dynamic>> petProfiles = {
  "맥스": {
    "name": "맥스",
    "species": "골든 리트리버",
    "age": "3",
    "height": "60",
    "weight": "32",
    "gender": "male",
    "isNeutered": true,
  },
};

Map<String, List<Map<String, dynamic>>> petChecklists = {
  "맥스": [
    {"title": "아침 식사", "time": "오전 8:00", "icon": Icons.restaurant, "isDone": true},
    {"title": "아침 산책", "time": "오전 9:00", "icon": Icons.pets, "isDone": true},
    {"title": "점심 산책", "time": "오후 1:00", "icon": Icons.pets, "isDone": false},
  ],
};

// --- [레코드 데이터 섹션] 펫별로 일정과 사진을 관리합니다 ---

final Map<String, Map<DateTime, List<Schedule>>> schedules = {};
final Map<String, Map<DateTime, List<String>>> photos = {};

// 3. 알림 로직: 모든 펫의 일정을 순회하여 다음 24시간 알림을 가져오고 정렬합니다.
List<Schedule> getActiveAlarmsForNext24Hours() {
  final now = DateTime.now();
  final tomorrow = now.add(const Duration(hours: 24));
  List<Schedule> active = [];

  // 모든 펫의 일정을 확인
  schedules.forEach((petName, dateMap) {
    dateMap.forEach((date, list) {
      for (var s in list) {
        if (s.alarm && s.time != null) {
          // 비교를 위한 정확한 날짜+시간 객체 생성
          final scheduleDateTime = DateTime(
            s.date.year, s.date.month, s.date.day,
            s.time!.hour, s.time!.minute,
          );

          // 현재 시간 이후 ~ 24시간 이내인 경우만 추가
          if (scheduleDateTime.isAfter(now) && scheduleDateTime.isBefore(tomorrow)) {
            active.add(Schedule(
              petName: petName, // 펫 이름 저장
              date: s.date,
              title: s.title,
              content: s.content,
              color: s.color,
              time: s.time,
              alarm: s.alarm,
            ));
          }
        }
      }
    });
  });

  // --- [핵심 수정] 시간순 정렬: 다가올 일정이 위로 오도록 합니다 ---
  active.sort((a, b) {
    // a와 b의 날짜+시간을 합쳐서 비교합니다.
    final aDt = DateTime(a.date.year, a.date.month, a.date.day, a.time!.hour, a.time!.minute);
    final bDt = DateTime(b.date.year, b.date.month, b.date.day, b.time!.hour, b.time!.minute);
    return aDt.compareTo(bDt); // 더 빠른 시간이 리스트의 앞(위)으로 옵니다.
  });

  return active;
}