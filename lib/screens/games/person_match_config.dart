class PersonMatchLevelConfig {
  final int level;
  final int nBack; // kaç adım geriye bakılacak
  final int totalRounds;
  final int avatarPoolSize;
  final int timeLimitSeconds;
  final String difficultyLabel;

  const PersonMatchLevelConfig({
    required this.level,
    required this.nBack,
    required this.totalRounds,
    required this.avatarPoolSize,
    required this.timeLimitSeconds,
    required this.difficultyLabel,
  });

  static const List<String> avatarPool = [
    '👨', '👩', '👦', '👧', '👴', '👵', '🧑', '👱‍♀️',
  ];

  static PersonMatchLevelConfig get(int level) {
    final configs = [
      // KOLAY 1-5 — 1-Back
      const PersonMatchLevelConfig(level: 1, nBack: 1, totalRounds: 10, avatarPoolSize: 4, timeLimitSeconds: 45, difficultyLabel: 'Kolay'),
      const PersonMatchLevelConfig(level: 2, nBack: 1, totalRounds: 10, avatarPoolSize: 4, timeLimitSeconds: 44, difficultyLabel: 'Kolay'),
      const PersonMatchLevelConfig(level: 3, nBack: 1, totalRounds: 11, avatarPoolSize: 4, timeLimitSeconds: 43, difficultyLabel: 'Kolay'),
      const PersonMatchLevelConfig(level: 4, nBack: 1, totalRounds: 11, avatarPoolSize: 4, timeLimitSeconds: 42, difficultyLabel: 'Kolay'),
      const PersonMatchLevelConfig(level: 5, nBack: 1, totalRounds: 12, avatarPoolSize: 4, timeLimitSeconds: 40, difficultyLabel: 'Kolay'),
      // ORTA 6-10 — 2-Back
      const PersonMatchLevelConfig(level: 6, nBack: 2, totalRounds: 12, avatarPoolSize: 5, timeLimitSeconds: 42, difficultyLabel: 'Orta'),
      const PersonMatchLevelConfig(level: 7, nBack: 2, totalRounds: 13, avatarPoolSize: 5, timeLimitSeconds: 41, difficultyLabel: 'Orta'),
      const PersonMatchLevelConfig(level: 8, nBack: 2, totalRounds: 13, avatarPoolSize: 5, timeLimitSeconds: 40, difficultyLabel: 'Orta'),
      const PersonMatchLevelConfig(level: 9, nBack: 2, totalRounds: 14, avatarPoolSize: 5, timeLimitSeconds: 39, difficultyLabel: 'Orta'),
      const PersonMatchLevelConfig(level: 10, nBack: 2, totalRounds: 14, avatarPoolSize: 5, timeLimitSeconds: 38, difficultyLabel: 'Orta'),
      // ZOR 11-15 — 3-Back
      const PersonMatchLevelConfig(level: 11, nBack: 3, totalRounds: 15, avatarPoolSize: 6, timeLimitSeconds: 40, difficultyLabel: 'Zor'),
      const PersonMatchLevelConfig(level: 12, nBack: 3, totalRounds: 15, avatarPoolSize: 6, timeLimitSeconds: 39, difficultyLabel: 'Zor'),
      const PersonMatchLevelConfig(level: 13, nBack: 3, totalRounds: 16, avatarPoolSize: 6, timeLimitSeconds: 38, difficultyLabel: 'Zor'),
      const PersonMatchLevelConfig(level: 14, nBack: 3, totalRounds: 16, avatarPoolSize: 6, timeLimitSeconds: 37, difficultyLabel: 'Zor'),
      const PersonMatchLevelConfig(level: 15, nBack: 3, totalRounds: 17, avatarPoolSize: 6, timeLimitSeconds: 36, difficultyLabel: 'Zor'),
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