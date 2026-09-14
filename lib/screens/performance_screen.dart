import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/firestore_service.dart';

class PerformanceScreen extends StatefulWidget {
  const PerformanceScreen({super.key});

  @override
  State<PerformanceScreen> createState() => _PerformanceScreenState();
}

class _PerformanceScreenState extends State<PerformanceScreen> {
  final _firestoreService = FirestoreService();
  List<Map<String, dynamic>> _results = [];
  bool _isLoading = true;

  // İstatistikler
  int _totalGames = 0;
  double _avgAccuracy = 0;
  int _totalStars = 0;
  int _bestLevel = 0;

  // Haftalık oyun sayısı (Pzt-Paz)
  List<int> _weeklyGames = List.filled(7, 0);

  @override
  void initState() {
    super.initState();
    _loadResults();
  }

  Future<void> _loadResults() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final results = await _firestoreService.getGameResults(uid);

    if (results.isNotEmpty) {
      double totalAccuracy = 0;
      int totalStars = 0;
      int bestLevel = 0;
      final weeklyGames = List.filled(7, 0);
      final now = DateTime.now().toLocal();
      final weekStart = now.subtract(Duration(days: now.weekday - 1));

      for (var r in results) {
        totalAccuracy += (r['accuracy'] ?? 0).toDouble();
        totalStars += (r['stars'] ?? 0) as int;
        final level = (r['level'] ?? 0) as int;
        if (level > bestLevel) bestLevel = level;

        // Haftalık dağılım
        final playedAt = r['playedAt'];
        if (playedAt != null) {
          final date = ((playedAt as dynamic).toDate() as DateTime).toLocal();
          final diff = DateTime(date.year, date.month, date.day).difference(DateTime(weekStart.year, weekStart.month, weekStart.day)).inDays;
          if (diff >= 0 && diff < 7) {
            weeklyGames[diff]++;
          }
        }
      }

      setState(() {
        _results = results;
        _totalGames = results.length;
        _avgAccuracy = totalAccuracy / results.length;
        _totalStars = totalStars;
        _bestLevel = bestLevel;
        _weeklyGames = weeklyGames;
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Performans',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Üst istatistik kartları
                  Row(
                    children: [
                      Expanded(
                        child: _statCard(
                          'Toplam Oyun',
                          '$_totalGames',
                          Icons.sports_esports,
                          Colors.blue,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _statCard(
                          'Ortalama\nDoğruluk',
                          '%${_avgAccuracy.toStringAsFixed(0)}',
                          Icons.track_changes,
                          Colors.green,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _statCard(
                          'Toplam Yıldız',
                          '⭐ $_totalStars',
                          Icons.star,
                          Colors.amber,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _statCard(
                          'En Yüksek\nLevel',
                          'Level $_bestLevel',
                          Icons.emoji_events,
                          Colors.purple,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Haftalık grafik
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'HAFTALIK AKTİVİTE',
                          style: TextStyle(fontSize: 11, color: Colors.grey),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Bu Hafta Oynanan Oyunlar',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _totalGames == 0
                            ? const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(20),
                                  child: Text(
                                    'Henüz oyun oynamadınız.\nOyun oynayarak performansınızı görün!',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(color: Colors.grey),
                                  ),
                                ),
                              )
                            : SizedBox(
                                height: 100,
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceAround,
                                  children: List.generate(7, (i) {
                                    final max = _weeklyGames
                                        .reduce((a, b) => a > b ? a : b)
                                        .toDouble();
                                    final h = max > 0
                                        ? _weeklyGames[i] / max
                                        : 0.0;
                                    final isToday =
                                        i ==DateTime.now().toLocal().weekday - 1;
                                    return Column(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        if (_weeklyGames[i] > 0)
                                          Text(
                                            '${_weeklyGames[i]}',
                                            style: const TextStyle(
                                              fontSize: 10,
                                              color: Colors.grey,
                                            ),
                                          ),
                                        const SizedBox(height: 2),
                                        Container(
                                          width: 32,
                                          height: h > 0 ? 80 * h : 4,
                                          decoration: BoxDecoration(
                                            color: isToday
                                                ? const Color(0xFF2196F3)
                                                : const Color(0xFFBBDEFB),
                                            borderRadius: BorderRadius.circular(
                                              6,
                                            ),
                                          ),
                                        ),
                                      ],
                                    );
                                  }),
                                ),
                              ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: const [
                            Text(
                              'Pzt',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey,
                              ),
                            ),
                            Text(
                              'Sal',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey,
                              ),
                            ),
                            Text(
                              'Çar',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey,
                              ),
                            ),
                            Text(
                              'Per',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey,
                              ),
                            ),
                            Text(
                              'Cum',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey,
                              ),
                            ),
                            Text(
                              'Cmt',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey,
                              ),
                            ),
                            Text(
                              'Paz',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Son oyunlar listesi
                  const Text(
                    'Son Oyunlar',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),

                  _results.isEmpty
                      ? const Center(
                          child: Text(
                            'Henüz oyun yok',
                            style: TextStyle(color: Colors.grey),
                          ),
                        )
                      : ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _results.length,
                          itemBuilder: (context, index) {
                            final r = _results[index];
                            final stars = (r['stars'] ?? 0) as int;
                            final accuracy = (r['accuracy'] ?? 0).toInt();
                            final level = r['level'] ?? 1;
                            final difficulty = r['difficulty'] ?? '';
                            final duration = r['duration'] ?? '--';

                            return Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(14),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.05),
                                    blurRadius: 8,
                                  ),
                                ],
                              ),
                              child: Row(
                                children: [
                                  // Oyun ikonu
                                  Container(
                                    width: 44,
                                    height: 44,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFE3F2FD),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Center(
                                      child: Text(
                                        '🧠',
                                        style: TextStyle(fontSize: 22),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  // Bilgiler
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          '${r['gameName'] ?? 'Oyun'} — Level $level',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          '$difficulty  •  %$accuracy doğruluk  •  $duration',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  // Yıldızlar
                                  Column(
                                    children: [
                                      Row(
                                        children: List.generate(
                                          3,
                                          (i) => Icon(
                                            i < stars
                                                ? Icons.star
                                                : Icons.star_border,
                                            color: Colors.amber,
                                            size: 16,
                                          ),
                                        ),
                                      ),
                                      Text(
                                        '${r['score'] ?? 0} puan',
                                        style: const TextStyle(
                                          fontSize: 11,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                ],
              ),
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
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 8),
          Text(title, style: const TextStyle(fontSize: 11, color: Colors.grey)),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
