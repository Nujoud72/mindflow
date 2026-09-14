import 'package:flutter/material.dart';

class ColorWordOption {
  final String label;
  final Color color;
  const ColorWordOption(this.label, this.color);
}

class WordColorLevelConfig {
  final int level;
  final int totalRounds;
  final int colorCount;
  final int timeLimitSeconds;
  final String difficultyLabel;

  const WordColorLevelConfig({
    required this.level,
    required this.totalRounds,
    required this.colorCount,
    required this.timeLimitSeconds,
    required this.difficultyLabel,
  });

  static const List<ColorWordOption> allColors = [
    ColorWordOption('KIRMIZI', Color(0xFFE53935)),
    ColorWordOption('MAVİ', Color(0xFF1E88E5)),
    ColorWordOption('SARI', Color(0xFFFDD835)),
    ColorWordOption('YEŞİL', Color(0xFF43A047)),
    ColorWordOption('MOR', Color(0xFF8E24AA)),
  ];

  static WordColorLevelConfig get(int level) {
    final configs = [
      // KOLAY 1-5
      const WordColorLevelConfig(level: 1, totalRounds: 10, colorCount: 3, timeLimitSeconds: 45, difficultyLabel: 'Kolay'),
      const WordColorLevelConfig(level: 2, totalRounds: 10, colorCount: 3, timeLimitSeconds: 43, difficultyLabel: 'Kolay'),
      const WordColorLevelConfig(level: 3, totalRounds: 11, colorCount: 3, timeLimitSeconds: 42, difficultyLabel: 'Kolay'),
      const WordColorLevelConfig(level: 4, totalRounds: 11, colorCount: 3, timeLimitSeconds: 40, difficultyLabel: 'Kolay'),
      const WordColorLevelConfig(level: 5, totalRounds: 12, colorCount: 3, timeLimitSeconds: 38, difficultyLabel: 'Kolay'),
      // ORTA 6-10
      const WordColorLevelConfig(level: 6, totalRounds: 12, colorCount: 4, timeLimitSeconds: 40, difficultyLabel: 'Orta'),
      const WordColorLevelConfig(level: 7, totalRounds: 13, colorCount: 4, timeLimitSeconds: 38, difficultyLabel: 'Orta'),
      const WordColorLevelConfig(level: 8, totalRounds: 13, colorCount: 4, timeLimitSeconds: 36, difficultyLabel: 'Orta'),
      const WordColorLevelConfig(level: 9, totalRounds: 14, colorCount: 4, timeLimitSeconds: 35, difficultyLabel: 'Orta'),
      const WordColorLevelConfig(level: 10, totalRounds: 14, colorCount: 4, timeLimitSeconds: 33, difficultyLabel: 'Orta'),
      // ZOR 11-15
      const WordColorLevelConfig(level: 11, totalRounds: 15, colorCount: 5, timeLimitSeconds: 35, difficultyLabel: 'Zor'),
      const WordColorLevelConfig(level: 12, totalRounds: 15, colorCount: 5, timeLimitSeconds: 33, difficultyLabel: 'Zor'),
      const WordColorLevelConfig(level: 13, totalRounds: 16, colorCount: 5, timeLimitSeconds: 32, difficultyLabel: 'Zor'),
      const WordColorLevelConfig(level: 14, totalRounds: 16, colorCount: 5, timeLimitSeconds: 30, difficultyLabel: 'Zor'),
      const WordColorLevelConfig(level: 15, totalRounds: 17, colorCount: 5, timeLimitSeconds: 28, difficultyLabel: 'Zor'),
    ];

    final idx = (level - 1).clamp(0, 14);
    return configs[idx];
  }

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