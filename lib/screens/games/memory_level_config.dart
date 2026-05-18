class MemoryLevelConfig {
  final int level;
  final int pairs;
  final int gridCols;
  final String difficultyLabel;
  final int timeLimitSeconds; // 0 = süresiz
  final double previewSeconds; // kartların başta açık kalma süresi

  const MemoryLevelConfig({
    required this.level,
    required this.pairs,
    required this.gridCols,
    required this.difficultyLabel,
    required this.timeLimitSeconds,
    required this.previewSeconds,
  });

  // Tüm 15 level'ın konfigürasyonu
  static MemoryLevelConfig get(int level) {
    const configs = [
      // KOLAY — Level 1-5
      MemoryLevelConfig(
        level: 1,
        pairs: 3,
        gridCols: 3,
        difficultyLabel: 'Kolay',
        timeLimitSeconds: 60,
        previewSeconds: 3.0,
      ),
      MemoryLevelConfig(
        level: 2,
        pairs: 4,
        gridCols: 4,
        difficultyLabel: 'Kolay',
        timeLimitSeconds: 75,
        previewSeconds: 2.5,
      ),
      MemoryLevelConfig(
        level: 3,
        pairs: 4,
        gridCols: 4,
        difficultyLabel: 'Kolay',
        timeLimitSeconds: 70,
        previewSeconds: 2.0,
      ),
      MemoryLevelConfig(
        level: 4,
        pairs: 5,
        gridCols: 4,
        difficultyLabel: 'Kolay',
        timeLimitSeconds: 85,
        previewSeconds: 2.0,
      ),
      MemoryLevelConfig(
        level: 5,
        pairs: 5,
        gridCols: 4,
        difficultyLabel: 'Kolay',
        timeLimitSeconds: 80,
        previewSeconds: 1.5,
      ),
      // ORTA — Level 6-10
      MemoryLevelConfig(
        level: 6,
        pairs: 6,
        gridCols: 4,
        difficultyLabel: 'Orta',
        timeLimitSeconds: 120,
        previewSeconds: 3.0,
      ),
      MemoryLevelConfig(
        level: 7,
        pairs: 6,
        gridCols: 4,
        difficultyLabel: 'Orta',
        timeLimitSeconds: 110,
        previewSeconds: 2.5,
      ),
      MemoryLevelConfig(
        level: 8,
        pairs: 6,
        gridCols: 4,
        difficultyLabel: 'Orta',
        timeLimitSeconds: 100,
        previewSeconds: 2.5,
      ),
      MemoryLevelConfig(
        level: 9,
        pairs: 7,
        gridCols: 4,
        difficultyLabel: 'Orta',
        timeLimitSeconds: 130,
        previewSeconds: 2.0,
      ),
      MemoryLevelConfig(
        level: 10,
        pairs: 7,
        gridCols: 4,
        difficultyLabel: 'Orta',
        timeLimitSeconds: 120,
        previewSeconds: 2.0,
      ),
      // ZOR — Level 11-15
      MemoryLevelConfig(
        level: 11,
        pairs: 7,
        gridCols: 4,
        difficultyLabel: 'Zor',
        timeLimitSeconds: 100,
        previewSeconds: 3.0,
      ),
      MemoryLevelConfig(
        level: 12,
        pairs: 8,
        gridCols: 4,
        difficultyLabel: 'Zor',
        timeLimitSeconds: 110,
        previewSeconds: 3.0,
      ),
      MemoryLevelConfig(
        level: 13,
        pairs: 8,
        gridCols: 4,
        difficultyLabel: 'Zor',
        timeLimitSeconds: 100,
        previewSeconds: 2.5,
      ),
      MemoryLevelConfig(
        level: 14,
        pairs: 8,
        gridCols: 4,
        difficultyLabel: 'Zor',
        timeLimitSeconds: 90,
        previewSeconds: 2.5,
      ),
      MemoryLevelConfig(
        level: 15,
        pairs: 9,
        gridCols: 4,
        difficultyLabel: 'Zor',
        timeLimitSeconds: 100,
        previewSeconds: 2.0,
      ),
    ];

    final idx = (level - 1).clamp(0, 14);
    return configs[idx];
  }

  // IF-THEN adaptasyon kuralı
  int stars(int accuracy, int errors) {
    if (level <= 5) {
      // Kolay
      if (errors == 0) return 3;
      if (errors <= 2) return 2;
      if (errors == 3) return 1;
      return 0;
    } else if (level <= 10) {
      // Orta
      if (errors == 0) return 3;
      if (errors <= 3) return 2;
      if (errors <= 5) return 1;
      return 0;
    } else {
      // Zor
      if (errors == 0) return 3;
      if (errors <= 4) return 2;
      if (errors <= 7) return 1;
      return 0;
    }
  }

  int nextLevel(int accuracy, int errors) {
    final limit = level <= 5
        ? 3
        : level <= 10
        ? 5
        : 7;
    if (errors <= limit) {
      return (level + 1).clamp(1, 15);
    } else {
      return level;
    }
  }
}
