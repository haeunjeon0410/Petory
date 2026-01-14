class TimeHelper {
  // "오전 8:00" -> 분 단위 정수 변환 (정렬용)
  static int parseTimeToMinutes(String timeStr) {
    try {
      if (timeStr.isEmpty || timeStr == "--:--") return 99999;
      final parts = timeStr.split(' ');
      if (parts.length < 2) return 99999;

      final ampm = parts[0];
      final timeParts = parts[1].split(':');

      int hour = int.parse(timeParts[0]);
      int minute = int.parse(timeParts[1]);

      if (ampm == "오후" && hour != 12) hour += 12;
      if (ampm == "오전" && hour == 12) hour = 0;

      return hour * 60 + minute;
    } catch (e) {
      return 99999;
    }
  }
}
