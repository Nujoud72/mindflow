class WordBuilderLevelConfig {
  final int level;
  final int totalRounds;
  final int timeLimitSeconds;
  final String difficultyLabel;

  const WordBuilderLevelConfig({
    required this.level,
    required this.totalRounds,
    required this.timeLimitSeconds,
    required this.difficultyLabel,
  });

  // Kelime havuzları — zorluk seviyesine göre gruplu
  static const List<String> easyWords = [
    'MASA', 'KEDİ', 'ELMA', 'KUŞ', 'SU', 'AY', 'EV', 'KİTAP', 'ARI', 'BAL',
    'YOL', 'DAĞ', 'GÖL', 'TAŞ', 'KOL', 'BURUN', 'DİŞ', 'SAAT', 'TOP', 'KAPI',
    'MASA', 'ATEŞ', 'RÜZGAR', 'BULUT', 'YILDIZ', 'GÜNEŞ', 'TAVUK', 'KOYUN',
    'İNEK', 'KUZU', 'FARE', 'YILAN', 'KURT', 'AYI', 'ASLAN', 'FİL', 'ZÜRAFA',
  ];
  static const List<String> mediumWords = [
    'ÇİÇEK', 'BALIK', 'KUTLU', 'MASAL', 'KALEM', 'ORMAN', 'YAZAR', 'DENİZ',
    'BAHÇE', 'MERDİVEN', 'SANDALYE', 'PENCERE', 'TELEFON', 'BİLEZİK', 'KUMSAL',
    'YAPRAK', 'KÖPRÜ', 'YILDIRIM', 'MEYVE', 'SEBZE', 'PATATES', 'DOMATES',
    'ŞEMSİYE', 'GÖZLÜK', 'KUTLAMA', 'PAZARTESİ', 'TATLI', 'YEMEK', 'TABAK',
  ];
  static const List<String> hardWords = [
    'KELEBEK', 'ARABALAR', 'BAHÇIVAN', 'DENİZCİ', 'ÖĞRETMEN', 'BİLGİSAYAR',
    'KÜTÜPHANE', 'HASTANE', 'BELEDİYE', 'ÜNİVERSİTE', 'MÜHENDİS', 'DOKTOR',
    'GAZETECİ', 'FOTOĞRAF', 'TELEVİZYON', 'BUZDOLABI', 'ÇAMAŞIR', 'ELEKTRİK',
    'PORTAKAL', 'KARPUZ', 'ANANAS', 'ÇİLEK', 'MANDALİNA', 'ARMUT', 'ÜZÜM',
  ];

  static WordBuilderLevelConfig get(int level) {
    final label = level <= 5 ? 'Kolay' : level <= 10 ? 'Orta' : 'Zor';
    final rounds = level <= 5 ? 6 : level <= 10 ? 7 : 8;
    final time = level <= 5 ? 60 : level <= 10 ? 70 : 80;
    return WordBuilderLevelConfig(
      level: level,
      totalRounds: rounds,
      timeLimitSeconds: time,
      difficultyLabel: label,
    );
  }

  List<String> get wordPool {
    if (level <= 5) return easyWords;
    if (level <= 10) return mediumWords;
    return hardWords;
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