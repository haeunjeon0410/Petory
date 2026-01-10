import 'package:flutter/material.dart';

class Schedule {
  final DateTime date;
  final String title;
  final String content;
  final Color color;
  final TimeOfDay? time;
  final bool alarm;

  Schedule({
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

final Map<DateTime, List<Schedule>> schedules = {};
final Map<DateTime, List<String>> photos = {};

List<Schedule> getActiveAlarmsForNext24Hours() {
  final now = DateTime.now();
  final tomorrow = now.add(const Duration(hours: 24));
  List<Schedule> active = [];

  schedules.forEach((date, list) {
    for (var s in list) {
      if (s.alarm && s.time != null) {
        final scheduleDateTime = DateTime(
          s.date.year, s.date.month, s.date.day,
          s.time!.hour, s.time!.minute,
        );
        if (scheduleDateTime.isAfter(now) && scheduleDateTime.isBefore(tomorrow)) {
          active.add(s);
        }
      }
    }
  });
  return active;
}