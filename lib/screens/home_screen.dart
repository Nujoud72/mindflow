import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/firestore_service.dart';
import 'games/memory_level_select_screen.dart';
import 'games/number_sequence_level_select_screen.dart';
import 'games/big_number_level_select_screen.dart';
import 'games/number_challenge_level_select_screen.dart';
import 'games/dot_connect_level_select_screen.dart';
import 'games/symbol_grid_level_select_screen.dart';
import 'games/word_color_level_select_screen.dart';
import 'games/person_match_level_select_screen.dart';
import 'games/word_builder_level_select_screen.dart';
import 'games/word_definition_level_select_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _firestoreService = FirestoreService();
  String _userName = '';
  int _totalPoints = 0;
  int _totalStars = 0;
  int _streak = 0;
  int _todayGames = 0;
  bool _isLoading = true;

  List<Map<String, dynamic>> _quickStartGames = [];

  // Tüm oyunların sabit haritası: isim -> emoji, alt başlık, renk, ekran
  static final Map<String, Map<String, dynamic>> _gameCatalog = {
    'Hafıza Kartları': {
      'emoji': '🧠',
      'subtitle': 'Eşleştirme oyunu — 15 Level',
      'color': Colors.green,
      'screenBuilder': (BuildContext _) => const MemoryLevelSelectScreen(),
    },
    'Sayı Dizisi': {
      'emoji': '🔢',
      'subtitle': 'Hafıza oyunu — 15 Level',
      'color': Colors.orange,
      'screenBuilder': (BuildContext _) => const NumberSequenceLevelSelectScreen(),
    },
    'Büyük Sayı': {
      'emoji': '🔢',
      'subtitle': 'Matematik oyunu — 15 Level',
      'color': Colors.blue,
      'screenBuilder': (BuildContext _) => const BigNumberLevelSelectScreen(),
    },
    'Sayı Mücadelesi': {
      'emoji': '🔢',
      'subtitle': 'Matematik oyunu — 15 Level',
      'color': Colors.blue,
      'screenBuilder': (BuildContext _) => const NumberChallengeLevelSelectScreen(),
    },
    'Noktaları Birleştir': {
      'emoji': '🔗',
      'subtitle': 'Problem çözme — 15 Level',
      'color': Colors.indigo,
      'screenBuilder': (BuildContext _) => const DotConnectLevelSelectScreen(),
    },
    'Küp Bulmacası': {
      'emoji': '🧩',
      'subtitle': 'Problem çözme — 15 Level',
      'color': Colors.indigo,
      'screenBuilder': (BuildContext _) => const SymbolGridLevelSelectScreen(),
    },
    'Renk Tanıma': {
      'emoji': '🎨',
      'subtitle': 'Dikkat oyunu — 15 Level',
      'color': Colors.teal,
      'screenBuilder': (BuildContext _) => const WordColorLevelSelectScreen(),
    },
    'Kişi Benzerliği': {
      'emoji': '👥',
      'subtitle': 'Dikkat oyunu — 15 Level',
      'color': Colors.teal,
      'screenBuilder': (BuildContext _) => const PersonMatchLevelSelectScreen(),
    },
    'Kelime Oluşturma': {
      'emoji': '🔤',
      'subtitle': 'Dil oyunu — 15 Level',
      'color': Colors.pink,
      'screenBuilder': (BuildContext _) => const WordBuilderLevelSelectScreen(),
    },
    'Kelime Tanımı': {
      'emoji': '📖',
      'subtitle': 'Dil oyunu — 15 Level',
      'color': Colors.pink,
      'screenBuilder': (BuildContext _) => const WordDefinitionLevelSelectScreen(),
    },
  };

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final profile = await _firestoreService.getUserProfile(uid);
    final results = await _firestoreService.getGameResults(uid);
    final streak = await _firestoreService.calculateStreak(uid);
    final todayGames = await _firestoreService.getTodayGamesCount(uid);
    final mostPlayed = await _firestoreService.getMostPlayedGames(uid);

    int totalStars = 0;
    for (var r in results) {
      totalStars += (r['stars'] ?? 0) as int;
    }

    // En çok oynanan 3 oyunu, katalogda var olanlarla eşleştir
    final quickGames = <Map<String, dynamic>>[];
    for (final entry in mostPlayed) {
      final gameInfo = _gameCatalog[entry.key];
      if (gameInfo != null) {
        quickGames.add({'name': entry.key, ...gameInfo});
      }
      if (quickGames.length >= 3) break;
    }

    // Hiç oyun oynanmamışsa varsayılan göster
    if (quickGames.isEmpty) {
      quickGames.add({'name': 'Hafıza Kartları', ..._gameCatalog['Hafıza Kartları']!});
      quickGames.add({'name': 'Sayı Dizisi', ..._gameCatalog['Sayı Dizisi']!});
    }

    setState(() {
      _userName = profile?['name'] ?? '';
      _totalPoints = profile?['totalPoints'] ?? 0;
      _totalStars = totalStars;
      _streak = streak;
      _todayGames = todayGames;
      _quickStartGames = quickGames;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'MindFlow',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 16),
            child: Icon(Icons.notifications_outlined, color: Colors.black),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF2196F3), Color(0xFF42A5F5)],
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Merhaba, $_userName! 👋',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Bugün beynini çalıştırmaya hazır mısın?',
                            style: TextStyle(color: Colors.white70, fontSize: 14),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              _badgeChip('🔥 $_streak Günlük Seri'),
                              const SizedBox(width: 8),
                              _badgeChip('⭐ $_totalPoints Puan'),
                              const SizedBox(width: 8),
                              _badgeChip('🎯 Bugün $_todayGames Oyun'),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Genel Durum',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _statCard('Toplam Puan', '$_totalPoints', Icons.star, Colors.orange),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _statCard('Toplam Yıldız', '⭐ $_totalStars', Icons.auto_awesome, Colors.amber),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _statCard('Günlük Seri', '🔥 $_streak Gün', Icons.local_fire_department, Colors.red),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _statCard('Bugün Oynanan', '$_todayGames Oyun', Icons.today, Colors.blue),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Hızlı Başlat',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const Text(
                      'En çok oynadığın oyunlar',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    const SizedBox(height: 12),
                    ..._quickStartGames.map((game) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _quickCard(
                          context,
                          '${game['emoji']} ${game['name']}',
                          game['subtitle'],
                          game['color'],
                          () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: game['screenBuilder']),
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _badgeChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _statCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 2),
          Text(title, style: const TextStyle(fontSize: 11, color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _quickCard(
    BuildContext context,
    String name,
    String subtitle,
    Color color,
    VoidCallback? onTap,
  ) {
    final isAvailable = onTap != null;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 2)),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(name.split(' ')[0], style: const TextStyle(fontSize: 24)),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name.substring(name.indexOf(' ') + 1), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  Text(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                ],
              ),
            ),
            isAvailable
                ? ElevatedButton(
                    onPressed: onTap,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: color,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('Oyna', style: TextStyle(color: Colors.white)),
                  )
                : Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Text('Yakında', style: TextStyle(color: Colors.grey, fontSize: 12)),
                  ),
          ],
        ),
      ),
    );
  }
}