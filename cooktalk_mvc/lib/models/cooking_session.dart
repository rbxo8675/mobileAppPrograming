import 'timer.dart';

enum SessionStatus { inProgress, paused, completed, cancelled }

class CookingSession {
  final String id;
  final String recipeId;
  final String userId;
  final int currentStep;
  final SessionStatus status;
  final DateTime startedAt;
  final DateTime? completedAt;
  final DateTime? pausedAt;
  final List<CookingTimer> timers;
  final String? photoPath;
  final int? rating;
  final String? notes;

  const CookingSession({
    required this.id,
    required this.recipeId,
    required this.userId,
    this.currentStep = 0,
    this.status = SessionStatus.inProgress,
    required this.startedAt,
    this.completedAt,
    this.pausedAt,
    this.timers = const [],
    this.photoPath,
    this.rating,
    this.notes,
  });

  CookingSession copyWith({
    String? id,
    String? recipeId,
    String? userId,
    int? currentStep,
    SessionStatus? status,
    DateTime? startedAt,
    DateTime? completedAt,
    DateTime? pausedAt,
    List<CookingTimer>? timers,
    String? photoPath,
    int? rating,
    String? notes,
  }) {
    return CookingSession(
      id: id ?? this.id,
      recipeId: recipeId ?? this.recipeId,
      userId: userId ?? this.userId,
      currentStep: currentStep ?? this.currentStep,
      status: status ?? this.status,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
      pausedAt: pausedAt ?? this.pausedAt,
      timers: timers ?? this.timers,
      photoPath: photoPath ?? this.photoPath,
      rating: rating ?? this.rating,
      notes: notes ?? this.notes,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'recipeId': recipeId,
      'userId': userId,
      'currentStep': currentStep,
      'status': status.name,
      'startedAt': startedAt.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
      'pausedAt': pausedAt?.toIso8601String(),
      'timers': timers.map((t) => t.toJson()).toList(),
      'photoPath': photoPath,
      'rating': rating,
      'notes': notes,
    };
  }

  factory CookingSession.fromJson(Map<String, dynamic> json) {
    return CookingSession(
      id: json['id'] as String,
      recipeId: json['recipeId'] as String,
      userId: json['userId'] as String,
      currentStep: json['currentStep'] as int? ?? 0,
      status: SessionStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => SessionStatus.inProgress,
      ),
      startedAt: DateTime.parse(json['startedAt'] as String),
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'] as String)
          : null,
      pausedAt: json['pausedAt'] != null
          ? DateTime.parse(json['pausedAt'] as String)
          : null,
      timers: (json['timers'] as List<dynamic>?)
              ?.map((t) => CookingTimer.fromJson(t as Map<String, dynamic>))
              .toList() ??
          [],
      photoPath: json['photoPath'] as String?,
      rating: json['rating'] as int?,
      notes: json['notes'] as String?,
    );
  }

  bool get isCompleted => status == SessionStatus.completed;
  bool get isActive => status == SessionStatus.inProgress;
  bool get isPaused => status == SessionStatus.paused;
  
  Duration get duration {
    final end = completedAt ?? DateTime.now();
    return end.difference(startedAt);
  }
}
