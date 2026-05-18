class GameResultModel {
  final String gameName;
  final int score;
  final double accuracy;
  final double reactionTime;
  final int errors;
  final String difficulty;
  final DateTime playedAt;

  GameResultModel({
    required this.gameName,
    required this.score,
    required this.accuracy,
    required this.reactionTime,
    required this.errors,
    required this.difficulty,
    required this.playedAt,
  });

  factory GameResultModel.fromMap(Map<String, dynamic> map) {
    return GameResultModel(
      gameName: map['gameName'] ?? '',
      score: map['score'] ?? 0,
      accuracy: (map['accuracy'] ?? 0.0).toDouble(),
      reactionTime: (map['reactionTime'] ?? 0.0).toDouble(),
      errors: map['errors'] ?? 0,
      difficulty: map['difficulty'] ?? 'Kolay',
      playedAt: map['playedAt']?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'gameName': gameName,
      'score': score,
      'accuracy': accuracy,
      'reactionTime': reactionTime,
      'errors': errors,
      'difficulty': difficulty,
      'playedAt': playedAt,
    };
  }

  // IF-THEN adaptasyon kuralı
  String get nextDifficulty {
    if (accuracy >= 0.85 && reactionTime <= 1.0 && errors <= 2) {
      return 'Zor';
    } else if (accuracy >= 0.65 && errors <= 5) {
      return 'Orta';
    } else {
      return 'Kolay';
    }
  }
}
