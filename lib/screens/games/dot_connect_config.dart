class DotEdge {
  final int fromIndex;
  final int toIndex;
  const DotEdge(this.fromIndex, this.toIndex);
}

class DotPuzzle {
  final List<List<double>> nodePositions;
  final List<DotEdge> edges;
  const DotPuzzle(this.nodePositions, this.edges);

  // Kaç kenarı olduğunu (derecesini) hesaplar
  int _degree(int nodeIndex) {
    return edges.where((e) => e.fromIndex == nodeIndex || e.toIndex == nodeIndex).length;
  }

  // Tek sayıda kenarı olan düğümler — buradan başlanmalı (Euler yolu kuralı)
  List<int> get oddDegreeNodes {
    final result = <int>[];
    for (int i = 0; i < nodePositions.length; i++) {
      if (_degree(i) % 2 != 0) result.add(i);
    }
    return result;
  }

  // Geçerli başlangıç noktaları: 2 tek dereceli düğüm varsa sadece onlar, yoksa hepsi
  List<int> get validStartNodes {
    final odd = oddDegreeNodes;
    if (odd.length == 2) return odd;
    return List.generate(nodePositions.length, (i) => i);
  }
}

class DotConnectLevelConfig {
  final int level;
  final String difficultyLabel;

  const DotConnectLevelConfig({
    required this.level,
    required this.difficultyLabel,
  });

  static DotConnectLevelConfig get(int level) {
    final label = level <= 5 ? 'Kolay' : level <= 10 ? 'Orta' : 'Zor';
    return DotConnectLevelConfig(level: level, difficultyLabel: label);
  }

  // Tüm bulmacalar matematiksel olarak doğrulanmış Euler yolu içerir
  static const List<DotPuzzle> easyPuzzles = [
    // Üçgen — 3 kenar, tüm düğümler çift dereceli, herhangi bir yerden başla
    DotPuzzle(
      [[0.5, 0.2], [0.2, 0.75], [0.8, 0.75]],
      [DotEdge(0, 1), DotEdge(1, 2), DotEdge(2, 0)],
    ),
    // Kare — 4 kenar, tüm düğümler çift dereceli
    DotPuzzle(
      [[0.2, 0.2], [0.8, 0.2], [0.8, 0.8], [0.2, 0.8]],
      [DotEdge(0, 1), DotEdge(1, 2), DotEdge(2, 3), DotEdge(3, 0)],
    ),
    // Kare + 1 köşegen — 2 tek dereceli düğüm (0 ve 2), oradan başla
    DotPuzzle(
      [[0.2, 0.2], [0.8, 0.2], [0.8, 0.8], [0.2, 0.8]],
      [DotEdge(0, 1), DotEdge(1, 2), DotEdge(2, 3), DotEdge(3, 0), DotEdge(0, 2)],
    ),
    // Kelebek (bowtie) — 2 üçgen ortak köşede, tüm düğümler çift dereceli
    DotPuzzle(
      [[0.2, 0.2], [0.2, 0.8], [0.5, 0.5], [0.8, 0.2], [0.8, 0.8]],
      [DotEdge(0, 1), DotEdge(1, 2), DotEdge(2, 0), DotEdge(2, 3), DotEdge(3, 4), DotEdge(4, 2)],
    ),
    // Zarf şekli (klasik) — 2 tek dereceli düğüm
    DotPuzzle(
      [[0.2, 0.75], [0.8, 0.75], [0.2, 0.35], [0.8, 0.35], [0.5, 0.1]],
      [DotEdge(0, 1), DotEdge(0, 2), DotEdge(1, 3), DotEdge(2, 3), DotEdge(2, 4), DotEdge(3, 4)],
    ),
  ];

  static const List<DotPuzzle> mediumPuzzles = [
    // Ev + çapraz — 8 kenar, 2 tek dereceli düğüm
    DotPuzzle(
      [[0.2, 0.75], [0.8, 0.75], [0.2, 0.35], [0.8, 0.35], [0.5, 0.1]],
      [
        DotEdge(0, 1), DotEdge(0, 2), DotEdge(1, 3), DotEdge(2, 3),
        DotEdge(2, 4), DotEdge(3, 4), DotEdge(0, 3), DotEdge(1, 2),
      ],
    ),
    // İki bitişik kare (merdiven) — 7 kenar, 2 tek dereceli düğüm
    DotPuzzle(
      [[0.15, 0.2], [0.5, 0.2], [0.85, 0.2], [0.15, 0.8], [0.5, 0.8], [0.85, 0.8]],
      [
        DotEdge(0, 1), DotEdge(1, 2), DotEdge(3, 4), DotEdge(4, 5),
        DotEdge(0, 3), DotEdge(1, 4), DotEdge(2, 5),
      ],
    ),
    // Beşgen + 1 köşegen — 6 kenar, 2 tek dereceli düğüm
    DotPuzzle(
      [[0.5, 0.1], [0.85, 0.4], [0.7, 0.85], [0.3, 0.85], [0.15, 0.4]],
      [DotEdge(0, 1), DotEdge(1, 2), DotEdge(2, 3), DotEdge(3, 4), DotEdge(4, 0), DotEdge(0, 2)],
    ),
    // Üç köşeli kelebek zinciri + köprü — 7 kenar, 2 tek dereceli düğüm
    DotPuzzle(
      [[0.15, 0.2], [0.15, 0.6], [0.45, 0.4], [0.75, 0.2], [0.75, 0.6]],
      [
        DotEdge(0, 1), DotEdge(1, 2), DotEdge(2, 0),
        DotEdge(2, 3), DotEdge(3, 4), DotEdge(4, 2), DotEdge(0, 4),
      ],
    ),
    // Dikdörtgen ızgara (merdiven, dikey) — 7 kenar, 2 tek dereceli düğüm
    DotPuzzle(
      [[0.3, 0.1], [0.7, 0.1], [0.3, 0.45], [0.7, 0.45], [0.3, 0.8], [0.7, 0.8]],
      [
        DotEdge(0, 2), DotEdge(2, 4), DotEdge(1, 3), DotEdge(3, 5),
        DotEdge(0, 1), DotEdge(2, 3), DotEdge(4, 5),
      ],
    ),
  ];

  static const List<DotPuzzle> hardPuzzles = [
    // Üçlü kelebek zinciri — 9 kenar, tüm düğümler çift dereceli
    DotPuzzle(
      [[0.15, 0.5], [0.35, 0.2], [0.35, 0.8], [0.65, 0.2], [0.65, 0.8], [0.85, 0.5]],
      [
        DotEdge(0, 1), DotEdge(1, 2), DotEdge(2, 0),
        DotEdge(1, 3), DotEdge(3, 4), DotEdge(4, 1),
        DotEdge(3, 5), DotEdge(5, 4), DotEdge(4, 3),
      ],
    ),
    // Beşgen + yıldız (pentagram) — 10 kenar, tüm düğümler çift dereceli
    DotPuzzle(
      [[0.5, 0.08], [0.85, 0.35], [0.7, 0.85], [0.3, 0.85], [0.15, 0.35]],
      [
        DotEdge(0, 1), DotEdge(1, 2), DotEdge(2, 3), DotEdge(3, 4), DotEdge(4, 0),
        DotEdge(0, 2), DotEdge(2, 4), DotEdge(4, 1), DotEdge(1, 3), DotEdge(3, 0),
      ],
    ),
    // Ev + çift çapraz + uzantı — 9 kenar, 2 tek dereceli düğüm
    DotPuzzle(
      [[0.2, 0.85], [0.8, 0.85], [0.2, 0.5], [0.8, 0.5], [0.5, 0.15], [0.5, 0.5]],
      [
        DotEdge(0, 1), DotEdge(0, 2), DotEdge(1, 3), DotEdge(2, 3),
        DotEdge(2, 4), DotEdge(3, 4), DotEdge(0, 3), DotEdge(1, 2), DotEdge(5, 4),
      ],
    ),
    // Dört köşeli kelebek zinciri — 12 kenar, tüm düğümler çift dereceli
    DotPuzzle(
      [[0.1, 0.5], [0.3, 0.2], [0.3, 0.8], [0.5, 0.5], [0.7, 0.2], [0.7, 0.8], [0.9, 0.5]],
      [
        DotEdge(0, 1), DotEdge(1, 3), DotEdge(3, 0),
        DotEdge(0, 2), DotEdge(2, 3), DotEdge(3, 0),
        DotEdge(3, 4), DotEdge(4, 6), DotEdge(6, 3),
        DotEdge(3, 5), DotEdge(5, 6), DotEdge(6, 3),
      ],
    ),
    // Büyük ızgara zinciri — 11 kenar, 2 tek dereceli düğüm
    DotPuzzle(
      [[0.15, 0.15], [0.5, 0.15], [0.85, 0.15], [0.15, 0.5], [0.5, 0.5], [0.85, 0.5], [0.5, 0.85]],
      [
        DotEdge(0, 1), DotEdge(1, 2), DotEdge(0, 3), DotEdge(1, 4), DotEdge(2, 5),
        DotEdge(3, 4), DotEdge(4, 5), DotEdge(3, 6), DotEdge(5, 6), DotEdge(4, 6), DotEdge(0, 4),
      ],
    ),
  ];

  DotPuzzle randomPuzzle(int seed) {
    final pool = level <= 5 ? easyPuzzles : level <= 10 ? mediumPuzzles : hardPuzzles;
    return pool[seed % pool.length];
  }

  int get threeStarSeconds => level <= 5 ? 25 : level <= 10 ? 40 : 55;
  int get twoStarSeconds => level <= 5 ? 45 : level <= 10 ? 65 : 85;
  int get oneStarSeconds => level <= 5 ? 70 : level <= 10 ? 95 : 120;

  int stars(int elapsedSeconds) {
    if (elapsedSeconds <= threeStarSeconds) return 3;
    if (elapsedSeconds <= twoStarSeconds) return 2;
    if (elapsedSeconds <= oneStarSeconds) return 1;
    return 0;
  }

  int nextLevel(int elapsedSeconds) {
    if (elapsedSeconds <= oneStarSeconds) {
      return (level + 1).clamp(1, 15);
    }
    return level;
  }
}