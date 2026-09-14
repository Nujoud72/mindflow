import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/firestore_service.dart';
import 'games/memory_level_select_screen.dart';
import 'games/number_sequence_level_select_screen.dart';

class DailyScreen extends StatefulWidget {
  const DailyScreen({super.key});

  @override
  State<DailyScreen> createState() => _DailyScreenState();
}

class _DailyScreenState extends State<DailyScreen> {
  final _firestoreService = FirestoreService();
  String _userName = '';
  bool _isLoading = true;

  Set<String> _playedToday = {};
  Set<DateTime> _weeklyActivity = {};

  final List<Map<String, dynamic>> _allGames = [
    {
      'name': 'Hafıza Kartları',
      'icon': Icons.style,
      'color': Colors.amber,
      'screenBuilder': (_) => const MemoryLevelSelectScreen(),
    },
    {
      'name': 'Sayı Dizisi',
      'icon': Icons.format_list_numbered,
      'color': Colors.orange,
      'screenBuilder': (_) => const NumberSequenceLevelSelectScreen(),
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      setState(() => _isLoading = false);
      return;
    }

    final profile = await _firestoreService.getUserProfile(uid);
    final playedToday = await _firestoreService.getTodayPlayedGameNames(uid);
    final weeklyActivity = await _firestoreService.getWeeklyActivityDates(uid);

    setState(() {
      _userName = profile?['name'] ?? '';
      _playedToday = playedToday;
      _weeklyActivity = weeklyActivity;
      _isLoading = false;
    });
  }

  int get _completedCount => _playedToday.length;
  double get _progress => _allGames.isEmpty ? 0 : _completedCount / _allGames.length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Günlük Antrenman',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
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
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE3F2FD),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(0xFF2196F3),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.sentiment_satisfied_alt, color: Colors.white, size: 24),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'HOŞ GELDİN!',
                                style: TextStyle(fontSize: 11, color: Color(0xFF2196F3), fontWeight: FontWeight.bold),
                              ),
                              Text(
                                'Harika gidiyorsun, $_userName!',
                                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                              ),
                              const Text('Devam et!', style: TextStyle(fontSize: 13, color: Colors.grey)),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text('Haftalık İlerleme', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
                      ),
                      child: Column(
                        children: [
                          Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: _buildWeekDays()),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Bugünkü İlerleme', style: TextStyle(fontSize: 13, color: Colors.grey)),
                              Text(
                                '$_completedCount/${_allGames.length} oyun',
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF2196F3)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: LinearProgressIndicator(
                              value: _progress,
                              minHeight: 10,
                              backgroundColor: const Color(0xFFE3F2FD),
                              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF2196F3)),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text('Bugünkü Görevler', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    ..._allGames.map((game) {
                      final isDone = _playedToday.contains(game['name']);
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _taskCard(game, isDone),
                      );
                    }),
                  ],
                ),
              ),
            ),
    );
  }

  List<Widget> _buildWeekDays() {
    const dayLabels = ['Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt', 'Paz'];
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final monday = today.subtract(Duration(days: today.weekday - 1));

    return List.generate(7, (i) {
      final date = monday.add(Duration(days: i));
      final isToday = date == today;
      final isCompleted = _weeklyActivity.contains(date);
      return _dayCircle(dayLabels[i], isCompleted, isToday);
    });
  }

  Widget _dayCircle(String day, bool completed, bool isToday) {
    return Column(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: completed ? const Color(0xFF2196F3) : const Color(0xFFE3F2FD),
            border: isToday ? Border.all(color: const Color(0xFF2196F3), width: 2) : null,
          ),
          child: Icon(
            completed ? Icons.star : Icons.circle_outlined,
            color: completed ? Colors.white : Colors.grey,
            size: 18,
          ),
        ),
        const SizedBox(height: 4),
        Text(day, style: const TextStyle(fontSize: 11, color: Colors.grey)),
      ],
    );
  }

  Widget _taskCard(Map<String, dynamic> game, bool isDone) {
    final Color color = game['color'];
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(game['icon'], color: color, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(game['name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                Text(
                  isDone ? 'Bugün Tamamlandı' : 'Henüz Oynanmadı',
                  style: TextStyle(color: isDone ? Colors.green : Colors.grey, fontSize: 12),
                ),
              ],
            ),
          ),
          isDone
              ? const Icon(Icons.check_circle, color: Colors.green, size: 28)
              : ElevatedButton(
                  onPressed: () async {
                    await Navigator.push(context, MaterialPageRoute(builder: game['screenBuilder']));
                    _loadData();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: color,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  child: const Text('Oyna', style: TextStyle(color: Colors.white, fontSize: 13)),
                ),
        ],
      ),
    );
  }
}