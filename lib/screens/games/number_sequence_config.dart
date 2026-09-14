class NumberSequenceLevelConfig {
  final int level;
  final int sequenceLength;
  final int digitDisplayMs;
  final int decoyCount;
  final String difficultyLabel;

  const NumberSequenceLevelConfig({
    required this.level,
    required this.sequenceLength,
    required this.digitDisplayMs,
    required this.decoyCount,
    required this.difficultyLabel,
  });

  static NumberSequenceLevelConfig get(int level) {
    const configs = [
      // KOLAY 1-5
      NumberSequenceLevelConfig(level: 1, sequenceLength: 3, digitDisplayMs: 1000, decoyCount: 2, difficultyLabel: 'Kolay'),
      NumberSequenceLevelConfig(level: 2, sequenceLength: 3, digitDisplayMs: 950, decoyCount: 2, difficultyLabel: 'Kolay'),
      NumberSequenceLevelConfig(level: 3, sequenceLength: 4, digitDisplayMs: 900, decoyCount: 3, difficultyLabel: 'Kolay'),
      NumberSequenceLevelConfig(level: 4, sequenceLength: 4, digitDisplayMs: 850, decoyCount: 3, difficultyLabel: 'Kolay'),
      NumberSequenceLevelConfig(level: 5, sequenceLength: 4, digitDisplayMs: 800, decoyCount: 3, difficultyLabel: 'Kolay'),
      // ORTA 6-10
      NumberSequenceLevelConfig(level: 6, sequenceLength: 4, digitDisplayMs: 800, decoyCount: 3, difficultyLabel: 'Orta'),
      NumberSequenceLevelConfig(level: 7, sequenceLength: 5, digitDisplayMs: 750, decoyCount: 3, difficultyLabel: 'Orta'),
      NumberSequenceLevelConfig(level: 8, sequenceLength: 5, digitDisplayMs: 700, decoyCount: 4, difficultyLabel: 'Orta'),
      NumberSequenceLevelConfig(level: 9, sequenceLength: 5, digitDisplayMs: 650, decoyCount: 4, difficultyLabel: 'Orta'),
      NumberSequenceLevelConfig(level: 10, sequenceLength: 5, digitDisplayMs: 600, decoyCount: 4, difficultyLabel: 'Orta'),
      // ZOR 11-15
      NumberSequenceLevelConfig(level: 11, sequenceLength: 5, digitDisplayMs: 600, decoyCount: 4, difficultyLabel: 'Zor'),
      NumberSequenceLevelConfig(level: 12, sequenceLength: 6, digitDisplayMs: 550, decoyCount: 4, difficultyLabel: 'Zor'),
      NumberSequenceLevelConfig(level: 13, sequenceLength: 6, digitDisplayMs: 500, decoyCount: 5, difficultyLabel: 'Zor'),
      NumberSequenceLevelConfig(level: 14, sequenceLength: 7, digitDisplayMs: 450, decoyCount: 5, difficultyLabel: 'Zor'),
      NumberSequenceLevelConfig(level: 15, sequenceLength: 7, digitDisplayMs: 400, decoyCount: 5, difficultyLabel: 'Zor'),
    ];

    final idx = (level - 1).clamp(0, 14);
    return configs[idx];
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