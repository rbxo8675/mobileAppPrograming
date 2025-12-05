enum TimerStatus { idle, running, paused, completed, cancelled }

class CookingTimer {
  final String id;
  final String label;
  final int totalSeconds;
  final int remainingSeconds;
  final TimerStatus status;
  final DateTime? startedAt;
  final DateTime? pausedAt;

  const CookingTimer({
    required this.id,
    required this.label,
    required this.totalSeconds,
    required this.remainingSeconds,
    this.status = TimerStatus.idle,
    this.startedAt,
    this.pausedAt,
  });

  CookingTimer copyWith({
    String? id,
    String? label,
    int? totalSeconds,
    int? remainingSeconds,
    TimerStatus? status,
    DateTime? startedAt,
    DateTime? pausedAt,
  }) {
    return CookingTimer(
      id: id ?? this.id,
      label: label ?? this.label,
      totalSeconds: totalSeconds ?? this.totalSeconds,
      remainingSeconds: remainingSeconds ?? this.remainingSeconds,
      status: status ?? this.status,
      startedAt: startedAt ?? this.startedAt,
      pausedAt: pausedAt ?? this.pausedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'label': label,
      'totalSeconds': totalSeconds,
      'remainingSeconds': remainingSeconds,
      'status': status.name,
      'startedAt': startedAt?.toIso8601String(),
      'pausedAt': pausedAt?.toIso8601String(),
    };
  }

  factory CookingTimer.fromJson(Map<String, dynamic> json) {
    return CookingTimer(
      id: json['id'] as String,
      label: json['label'] as String,
      totalSeconds: json['totalSeconds'] as int,
      remainingSeconds: json['remainingSeconds'] as int,
      status: TimerStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => TimerStatus.idle,
      ),
      startedAt: json['startedAt'] != null 
          ? DateTime.parse(json['startedAt'] as String) 
          : null,
      pausedAt: json['pausedAt'] != null 
          ? DateTime.parse(json['pausedAt'] as String) 
          : null,
    );
  }

  bool get isActive => status == TimerStatus.running;
  bool get isPaused => status == TimerStatus.paused;
  bool get isCompleted => status == TimerStatus.completed;
  
  String get formattedTime {
    final minutes = remainingSeconds ~/ 60;
    final seconds = remainingSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}
