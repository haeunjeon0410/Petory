class Task {
  final String title;
  final String time;
  final String? icon; // 이모지
  final String? memo;
  bool isDone;

  Task({
    required this.title,
    required this.time,
    this.icon,
    this.memo,
    this.isDone = false,
  });

  factory Task.fromMap(Map<String, dynamic> map) {
    return Task(
      title: map['title'],
      time: map['time'],
      icon: map['icon'],
      memo: map['memo'],
      isDone: map['isDone'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'time': time,
      'icon': icon,
      'memo': memo,
      'isDone': isDone,
    };
  }
}
