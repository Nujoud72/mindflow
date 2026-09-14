import 'package:flutter/material.dart';

class SymbolOption {
  final IconData icon;
  final Color color;
  const SymbolOption(this.icon, this.color);
}

class SymbolGridLevelConfig {
  final int level;
  final int gridSize;
  final int symbolCount;
  final int emptyCells;
  final String difficultyLabel;

  const SymbolGridLevelConfig({
    required this.level,
    required this.gridSize,
    required this.symbolCount,
    required this.emptyCells,
    required this.difficultyLabel,
  });

  static const List<SymbolOption> allSymbols = [
    SymbolOption(Icons.circle, Color(0xFF378ADD)), // mavi daire
    SymbolOption(Icons.crop_square, Color(0xFFD4537E)), // pembe kare
    SymbolOption(Icons.change_history, Color(0xFF63C459)), // yeşil üçgen
    SymbolOption(Icons.favorite, Color(0xFFEF9F27)), // turuncu kalp
    SymbolOption(Icons.star, Color(0xFFAF7BE0)), // mor yıldız
    SymbolOption(Icons.hexagon, Color(0xFF1D9E75)), // teal altıgen
  ];

  static SymbolGridLevelConfig get(int level) {
    const configs = [
      // KOLAY 1-5 — 3x3, 3 sembol
      SymbolGridLevelConfig(level: 1, gridSize: 3, symbolCount: 3, emptyCells: 2, difficultyLabel: 'Kolay'),
      SymbolGridLevelConfig(level: 2, gridSize: 3, symbolCount: 3, emptyCells: 2, difficultyLabel: 'Kolay'),
      SymbolGridLevelConfig(level: 3, gridSize: 3, symbolCount: 3, emptyCells: 3, difficultyLabel: 'Kolay'),
      SymbolGridLevelConfig(level: 4, gridSize: 3, symbolCount: 3, emptyCells: 3, difficultyLabel: 'Kolay'),
      SymbolGridLevelConfig(level: 5, gridSize: 3, symbolCount: 3, emptyCells: 3, difficultyLabel: 'Kolay'),
      // ORTA 6-10 — 4x4/5x5, 4-5 sembol
      SymbolGridLevelConfig(level: 6, gridSize: 4, symbolCount: 4, emptyCells: 4, difficultyLabel: 'Orta'),
      SymbolGridLevelConfig(level: 7, gridSize: 4, symbolCount: 4, emptyCells: 4, difficultyLabel: 'Orta'),
      SymbolGridLevelConfig(level: 8, gridSize: 4, symbolCount: 4, emptyCells: 5, difficultyLabel: 'Orta'),
      SymbolGridLevelConfig(level: 9, gridSize: 5, symbolCount: 5, emptyCells: 5, difficultyLabel: 'Orta'),
      SymbolGridLevelConfig(level: 10, gridSize: 5, symbolCount: 5, emptyCells: 6, difficultyLabel: 'Orta'),
      // ZOR 11-15 — 6x6, 6 sembol
      SymbolGridLevelConfig(level: 11, gridSize: 6, symbolCount: 6, emptyCells: 6, difficultyLabel: 'Zor'),
      SymbolGridLevelConfig(level: 12, gridSize: 6, symbolCount: 6, emptyCells: 7, difficultyLabel: 'Zor'),
      SymbolGridLevelConfig(level: 13, gridSize: 6, symbolCount: 6, emptyCells: 8, difficultyLabel: 'Zor'),
      SymbolGridLevelConfig(level: 14, gridSize: 6, symbolCount: 6, emptyCells: 9, difficultyLabel: 'Zor'),
      SymbolGridLevelConfig(level: 15, gridSize: 6, symbolCount: 6, emptyCells: 10, difficultyLabel: 'Zor'),
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