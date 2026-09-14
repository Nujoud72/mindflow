import 'dart:math';

enum OpType { add, subtract, multiply, divide }

class NumberCard {
  final String expression; // ekranda gösterilecek metin
  final int value; // gerçek sonuç

  const NumberCard(this.expression, this.value);
}

class BigNumberLevelConfig {
  final int level;
  final int totalRounds;
  final int timeLimitSeconds;
  final List<OpType> allowedOps;
  final int maxNumber;
  final String difficultyLabel;

  const BigNumberLevelConfig({
    required this.level,
    required this.totalRounds,
    required this.timeLimitSeconds,
    required this.allowedOps,
    required this.maxNumber,
    required this.difficultyLabel,
  });

  static BigNumberLevelConfig get(int level) {
    const configs = [
      // KOLAY 1-5 — toplama/çıkarma, 1-20
      BigNumberLevelConfig(level: 1, totalRounds: 10, timeLimitSeconds: 60, allowedOps: [OpType.add, OpType.subtract], maxNumber: 20, difficultyLabel: 'Kolay'),
      BigNumberLevelConfig(level: 2, totalRounds: 10, timeLimitSeconds: 60, allowedOps: [OpType.add, OpType.subtract], maxNumber: 20, difficultyLabel: 'Kolay'),
      BigNumberLevelConfig(level: 3, totalRounds: 11, timeLimitSeconds: 60, allowedOps: [OpType.add, OpType.subtract], maxNumber: 20, difficultyLabel: 'Kolay'),
      BigNumberLevelConfig(level: 4, totalRounds: 11, timeLimitSeconds: 60, allowedOps: [OpType.add, OpType.subtract], maxNumber: 20, difficultyLabel: 'Kolay'),
      BigNumberLevelConfig(level: 5, totalRounds: 12, timeLimitSeconds: 60, allowedOps: [OpType.add, OpType.subtract], maxNumber: 20, difficultyLabel: 'Kolay'),
      // ORTA 6-10 — toplama/çıkarma/çarpma, 1-50
      BigNumberLevelConfig(level: 6, totalRounds: 12, timeLimitSeconds: 55, allowedOps: [OpType.add, OpType.subtract, OpType.multiply], maxNumber: 50, difficultyLabel: 'Orta'),
      BigNumberLevelConfig(level: 7, totalRounds: 13, timeLimitSeconds: 55, allowedOps: [OpType.add, OpType.subtract, OpType.multiply], maxNumber: 50, difficultyLabel: 'Orta'),
      BigNumberLevelConfig(level: 8, totalRounds: 13, timeLimitSeconds: 55, allowedOps: [OpType.add, OpType.subtract, OpType.multiply], maxNumber: 50, difficultyLabel: 'Orta'),
      BigNumberLevelConfig(level: 9, totalRounds: 14, timeLimitSeconds: 55, allowedOps: [OpType.add, OpType.subtract, OpType.multiply], maxNumber: 50, difficultyLabel: 'Orta'),
      BigNumberLevelConfig(level: 10, totalRounds: 14, timeLimitSeconds: 55, allowedOps: [OpType.add, OpType.subtract, OpType.multiply], maxNumber: 50, difficultyLabel: 'Orta'),
      // ZOR 11-15 — çarpma/bölme karışık, 1-100
      BigNumberLevelConfig(level: 11, totalRounds: 14, timeLimitSeconds: 50, allowedOps: [OpType.multiply, OpType.divide, OpType.add], maxNumber: 100, difficultyLabel: 'Zor'),
      BigNumberLevelConfig(level: 12, totalRounds: 15, timeLimitSeconds: 50, allowedOps: [OpType.multiply, OpType.divide, OpType.add], maxNumber: 100, difficultyLabel: 'Zor'),
      BigNumberLevelConfig(level: 13, totalRounds: 15, timeLimitSeconds: 50, allowedOps: [OpType.multiply, OpType.divide, OpType.subtract], maxNumber: 100, difficultyLabel: 'Zor'),
      BigNumberLevelConfig(level: 14, totalRounds: 16, timeLimitSeconds: 50, allowedOps: [OpType.multiply, OpType.divide, OpType.subtract], maxNumber: 100, difficultyLabel: 'Zor'),
      BigNumberLevelConfig(level: 15, totalRounds: 16, timeLimitSeconds: 50, allowedOps: [OpType.multiply, OpType.divide], maxNumber: 100, difficultyLabel: 'Zor'),
    ];

    final idx = (level - 1).clamp(0, 14);
    return configs[idx];
  }

  // Bir kart üretir: rastgele bir işlem türü seçip ifadeyi ve sonucu döndürür
  NumberCard generateCard(Random random) {
    final op = allowedOps[random.nextInt(allowedOps.length)];
    switch (op) {
      case OpType.add:
        final a = random.nextInt(maxNumber ~/ 2) + 1;
        final b = random.nextInt(maxNumber ~/ 2) + 1;
        return NumberCard('$a + $b', a + b);
      case OpType.subtract:
        final a = random.nextInt(maxNumber) + 5;
        final b = random.nextInt(a);
        return NumberCard('$a - $b', a - b);
      case OpType.multiply:
        final a = random.nextInt(10) + 2;
        final b = random.nextInt(10) + 2;
        return NumberCard('$a x $b', a * b);
      case OpType.divide:
        final b = random.nextInt(9) + 2;
        final result = random.nextInt(10) + 2;
        final a = b * result;
        return NumberCard('$a ÷ $b', result);
    }
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