class WordDefinitionEntry {
  final String word;
  final String hint;
  const WordDefinitionEntry(this.word, this.hint);
}

class WordDefinitionLevelConfig {
  final int level;
  final int totalRounds;
  final int timeLimitSeconds;
  final int decoyCount;
  final String difficultyLabel;

  const WordDefinitionLevelConfig({
    required this.level,
    required this.totalRounds,
    required this.timeLimitSeconds,
    required this.decoyCount,
    required this.difficultyLabel,
  });

 // Kelime + tanım havuzları — zorluk seviyesine göre gruplu
  static const List<WordDefinitionEntry> easyWords = [
    WordDefinitionEntry('ELMA', 'Kırmızı ve tatlı bir meyve'),
    WordDefinitionEntry('KEDİ', 'Miyavlayan evcil hayvan'),
    WordDefinitionEntry('TOP', 'Oyun oynanan yuvarlak nesne'),
    WordDefinitionEntry('SU', 'İçtiğimiz hayat kaynağı'),
    WordDefinitionEntry('AY', 'Gece gökyüzünde parlayan'),
    WordDefinitionEntry('KUŞ', 'Uçan, kanatlı hayvan'),
    WordDefinitionEntry('EV', 'İçinde yaşadığımız yer'),
    WordDefinitionEntry('ARI', 'Bal yapan böcek'),
    WordDefinitionEntry('BAL', 'Arıların yaptığı tatlı besin'),
    WordDefinitionEntry('YOL', 'Üzerinde yürünen veya araç geçen yer'),
    WordDefinitionEntry('KÖPEK', 'Havlayan sevimli hayvan'),
    WordDefinitionEntry('İNEK', 'Süt veren çiftlik hayvanı'),
    WordDefinitionEntry('TAVUK', 'Yumurta veren çiftlik hayvanı'),
    WordDefinitionEntry('KOYUN', 'Yünü olan çiftlik hayvanı'),
    WordDefinitionEntry('FARE', 'Küçük, peynir seven hayvan'),
    WordDefinitionEntry('YILAN', 'Bacaksız, sürünerek giden hayvan'),
    WordDefinitionEntry('ASLAN', 'Ormanlar kralı olarak bilinen hayvan'),
    WordDefinitionEntry('FİL', 'Uzun hortumu olan büyük hayvan'),
    WordDefinitionEntry('DAĞ', 'Çok yüksek toprak yığını'),
    WordDefinitionEntry('GÖL', 'Etrafı karayla çevrili durgun su'),
    WordDefinitionEntry('TAŞ', 'Sert ve doğal katı madde'),
    WordDefinitionEntry('BURUN', 'Koku almamızı sağlayan organ'),
    WordDefinitionEntry('DİŞ', 'Ağzımızda yemek çiğnememizi sağlayan'),
    WordDefinitionEntry('SAAT', 'Zamanı gösteren alet'),
    WordDefinitionEntry('KAPI', 'Bir yere girip çıkmamızı sağlayan açıklık'),
    WordDefinitionEntry('ATEŞ', 'Yanan ve ısı veren şey'),
    WordDefinitionEntry('BULUT', 'Gökyüzünde uçan beyaz veya gri kütle'),
    WordDefinitionEntry('YILDIZ', 'Gece gökyüzünde parlayan ışıklı nokta'),
    WordDefinitionEntry('KUZU', 'Koyunun yavrusu'),
    WordDefinitionEntry('AYI', 'Kışın uyuyan büyük orman hayvanı'),
  ];
  static const List<WordDefinitionEntry> mediumWords = [
    WordDefinitionEntry('GÜNEŞ', 'Gökyüzündeki sıcak yıldız'),
    WordDefinitionEntry('ÇİÇEK', 'Bahçede açan renkli bitki'),
    WordDefinitionEntry('BALIK', 'Suda yaşayan hayvan'),
    WordDefinitionEntry('KALEM', 'Yazı yazmak için kullanılır'),
    WordDefinitionEntry('DENİZ', 'Büyük ve tuzlu su kütlesi'),
    WordDefinitionEntry('ORMAN', 'Çok ağaç olan yer'),
    WordDefinitionEntry('MASAL', 'Uyumadan önce anlatılan hikaye'),
    WordDefinitionEntry('KUTLU', 'Mutlu ve şanslı anlamına gelir'),
    WordDefinitionEntry('BAHÇE', 'Çiçek ve ağaç dikilen alan'),
    WordDefinitionEntry('KUMSAL', 'Deniz kenarındaki kumlu alan'),
    WordDefinitionEntry('YAPRAK', 'Ağaçların üzerindeki yeşil parça'),
    WordDefinitionEntry('KÖPRÜ', 'Nehir üzerinden geçmeyi sağlayan yapı'),
    WordDefinitionEntry('MEYVE', 'Ağaçlarda yetişen tatlı yiyecek'),
    WordDefinitionEntry('SEBZE', 'Toprakta yetişen besleyici yiyecek'),
    WordDefinitionEntry('TATLI', 'Şekerli, hoş lezzetli yiyecek'),
    WordDefinitionEntry('YEMEK', 'Karnımızı doyurmak için yediğimiz şey'),
    WordDefinitionEntry('TABAK', 'Yemek koyduğumuz kap'),
    WordDefinitionEntry('GÖZLÜK', 'Görmemizi kolaylaştıran alet'),
    WordDefinitionEntry('ŞEMSİYE', 'Yağmurdan korunmak için kullanılır'),
    WordDefinitionEntry('PENCERE', 'Evde dışarıyı görmemizi sağlayan açıklık'),
    WordDefinitionEntry('TELEFON', 'Konuşmak için kullandığımız alet'),
    WordDefinitionEntry('SANDALYE', 'Üzerine oturduğumuz eşya'),
    WordDefinitionEntry('MERDİVEN', 'Yukarı çıkmamızı sağlayan basamaklar'),
    WordDefinitionEntry('PATATES', 'Toprak altında yetişen sebze'),
    WordDefinitionEntry('DOMATES', 'Kırmızı, salatalarda kullanılan sebze'),
  ];
  static const List<WordDefinitionEntry> hardWords = [
    WordDefinitionEntry('KELEBEK', 'Renkli kanatlı, çiçeklerde uçan böcek'),
    WordDefinitionEntry('DENİZCİ', 'Gemide çalışan kişi'),
    WordDefinitionEntry('ÖĞRETMEN', 'Okulda ders anlatan kişi'),
    WordDefinitionEntry('BAHÇIVAN', 'Bahçeyle ilgilenen kişi'),
    WordDefinitionEntry('KÜTÜPHANE', 'Kitapların bulunduğu yer'),
    WordDefinitionEntry('HASTANE', 'Hastaların tedavi edildiği yer'),
    WordDefinitionEntry('DOKTOR', 'Hastaları tedavi eden kişi'),
    WordDefinitionEntry('MÜHENDİS', 'Bina ve makine tasarlayan kişi'),
    WordDefinitionEntry('GAZETECİ', 'Haber yazan ve araştıran kişi'),
    WordDefinitionEntry('BELEDİYE', 'Şehir işlerini yöneten kurum'),
    WordDefinitionEntry('BUZDOLABI', 'Yiyecekleri soğuk tutan alet'),
    WordDefinitionEntry('TELEVİZYON', 'Görüntü izlediğimiz alet'),
    WordDefinitionEntry('BİLGİSAYAR', 'Yazı yazıp oyun oynadığımız alet'),
    WordDefinitionEntry('PORTAKAL', 'Turuncu renkli ekşi meyve'),
    WordDefinitionEntry('KARPUZ', 'Yazın yenen büyük, yeşil meyve'),
    WordDefinitionEntry('ÇİLEK', 'Kırmızı, küçük ve tatlı meyve'),
    WordDefinitionEntry('ÜZÜM', 'Salkım halinde yetişen küçük meyve'),
    WordDefinitionEntry('ARMUT', 'Yeşil veya sarı renkli tatlı meyve'),
    WordDefinitionEntry('ANANAS', 'Dikenli kabuklu tropikal meyve'),
  ];

  static WordDefinitionLevelConfig get(int level) {
    final label = level <= 5 ? 'Kolay' : level <= 10 ? 'Orta' : 'Zor';
    final rounds = level <= 5 ? 6 : level <= 10 ? 7 : 8;
    final time = level <= 5 ? 60 : level <= 10 ? 75 : 90;
    final decoys = level <= 5 ? 1 : 2;
    return WordDefinitionLevelConfig(
      level: level,
      totalRounds: rounds,
      timeLimitSeconds: time,
      decoyCount: decoys,
      difficultyLabel: label,
    );
  }

  List<WordDefinitionEntry> get wordPool {
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