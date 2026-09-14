import 'dart:math';
import 'package:flutter/material.dart';

class NumberChallengeLevelConfig {
  final int level;
  final int bubbleCount;
  final int minNumber;
  final int maxNumber;
  final int timeLimitSeconds;
  final String difficultyLabel;

  const NumberChallengeLevelConfig({
    required this.level,
    required this.bubbleCount,
    required this.minNumber,
    required this.maxNumber,
    required this.timeLimitSeconds,
    required this.difficultyLabel,
  });

  static const List<Color> bubbleColors = [
    Color(0xFFEF9F27), // turuncu
    Color(0xFF63C459), // yeşil
    Color(0xFFAF7BE0), // mor
    Color(0xFF378ADD), // mavi
    Color(0xFFD4537E), // pembe
    Color(0xFF1D9E75), // teal
  ];

  static NumberChallengeLevelConfig get(int level) {
    const configs = [
      // KOLAY 1-5 — sadece pozitif, 1-20
      NumberChallengeLevelConfig(level: 1, bubbleCount: 4, minNumber: 1, maxNumber: 20, timeLimitSeconds: 60, difficultyLabel: 'Kolay'),
      NumberChallengeLevelConfig(level: 2, bubbleCount: 4, minNumber: 1, maxNumber: 20, timeLimitSeconds: 60, difficultyLabel: 'Kolay'),
      NumberChallengeLevelConfig(level: 3, bubbleCount: 5, minNumber: 1, maxNumber: 20, timeLimitSeconds: 60, difficultyLabel: 'Kolay'),
      NumberChallengeLevelConfig(level: 4, bubbleCount: 5, minNumber: 1, maxNumber: 20, timeLimitSeconds: 60, difficultyLabel: 'Kolay'),
      NumberChallengeLevelConfig(level: 5, bubbleCount: 5, minNumber: 1, maxNumber: 20, timeLimitSeconds: 60, difficultyLabel: 'Kolay'),
      // ORTA 6-10 — negatif sayılar dahil, -20/30
      NumberChallengeLevelConfig(level: 6, bubbleCount: 5, minNumber: -20, maxNumber: 30, timeLimitSeconds: 55, difficultyLabel: 'Orta'),
      NumberChallengeLevelConfig(level: 7, bubbleCount: 6, minNumber: -20, maxNumber: 30, timeLimitSeconds: 55, difficultyLabel: 'Orta'),
      NumberChallengeLevelConfig(level: 8, bubbleCount: 6, minNumber: -20, maxNumber: 30, timeLimitSeconds: 55, difficultyLabel: 'Orta'),
      NumberChallengeLevelConfig(level: 9, bubbleCount: 6, minNumber: -20, maxNumber: 30, timeLimitSeconds: 55, difficultyLabel: 'Orta'),
      NumberChallengeLevelConfig(level: 10, bubbleCount: 6, minNumber: -20, maxNumber: 30, timeLimitSeconds: 55, difficultyLabel: 'Orta'),
      // ZOR 11-15 — geniş negatif/pozitif aralık, -50/100
      NumberChallengeLevelConfig(level: 11, bubbleCount: 6, minNumber: -50, maxNumber: 100, timeLimitSeconds: 50, difficultyLabel: 'Zor'),
      NumberChallengeLevelConfig(level: 12, bubbleCount: 7, minNumber: -50, maxNumber: 100, timeLimitSeconds: 50, difficultyLabel: 'Zor'),
      NumberChallengeLevelConfig(level: 13, bubbleCount: 7, minNumber: -50, maxNumber: 100, timeLimitSeconds: 50, difficultyLabel: 'Zor'),
      NumberChallengeLevelConfig(level: 14, bubbleCount: 8, minNumber: -50, maxNumber: 100, timeLimitSeconds: 50, difficultyLabel: 'Zor'),
      NumberChallengeLevelConfig(level: 15, bubbleCount: 8, minNumber: -50, maxNumber: 100, timeLimitSeconds: 50, difficultyLabel: 'Zor'),
    ];

    final idx = (level - 1).clamp(0, 14);
    return configs[idx];
  }

  // Tekrarsız, rastgele sayı listesi üretir
  List<int> generateNumbers(Random random) {
    final numbers = <int>{};
    while (numbers.length < bubbleCount) {
      numbers.add(minNumber + random.nextInt(maxNumber - minNumber + 1));
    }
    return numbers.toList();
  }

  // IF-THEN yıldız kuralı (diğer oyunlarla aynı mantık)
  int stars(int errors) {
    if (level <= 5) {
      if (errors == 0) return 3;
      if (errors <= 2) return 2;
      if (errors == 3) return 1;
      return 0;
    } else if (level <= 10) {
      if (errors == 0) return 3;
      if (errors <= 3) return 2;
      if (errors <= 5) return 1;
      return 0;
    } else {
      if (errors == 0) return 3;
      if (errors <= 4) return 2;
      if (errors <= 7) return 1;
      return 0;
    }
  }

  int nextLevel(int errors) {
    final limit = level <= 5 ? 3 : level <= 10 ? 5 : 7;
    if (errors <= limit) {
      return (level + 1).clamp(1, 15);
    }
    return level;
  }
}