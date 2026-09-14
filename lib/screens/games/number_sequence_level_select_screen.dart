import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'number_sequence_screen.dart';

class NumberSequenceLevelSelectScreen extends StatefulWidget {
  const NumberSequenceLevelSelectScreen({super.key});

  @override
  State<NumberSequenceLevelSelectScreen> createState() =>
      _NumberSequenceLevelSelectScreenState();
}

class _NumberSequenceLevelSelectScreenState extends State<NumberSequenceLevelSelectScreen> {
  int _unlockedLevel = 1;
  Map<int, int> _levelStars = {};

  @override
  void initState() {
    super.initState();
    _loadProgress();
  }

  Future<void> _loadProgress() async {
    final prefs = await SharedPreferences.getInstance();
    final stars = <int, int>{};
    for (int i = 1; i <= 15; i++) {
      stars[i] = prefs.getInt('sequence_stars_level_$i') ?? 0;
    }
    setState(() {
      _unlockedLevel = prefs.getInt('sequence_unlocked_level') ?? 1;
      _levelStars = stars;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          '🔢 Sayı Dizisi',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSection(context, 'Kolay', 1, 5, Colors.green, const Color(0xFFE8F5E9)),
            const SizedBox(height: 24),
            _buildSection(context, 'Orta', 6, 10, Colors.orange, const Color(0xFFFFF3E0)),
            const SizedBox(height: 24),
            _buildSection(context, 'Zor', 11, 15, Colors.red, const Color(0xFFFFEBEE)),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(BuildContext context, String label, int from, int to, Color color, Color bgColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color.withOpacity(0.4)),
          ),
          child: Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 14)),
        ),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 5,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 1,
          ),
          itemCount: to - from + 1,
          itemBuilder: (context, index) {
            final level = from + index;
            final isUnlocked = level <= _unlockedLevel;
            final isCompleted = level < _unlockedLevel;
            final stars = _levelStars[level] ?? 0;

            return GestureDetector(
              onTap: isUnlocked
                  ? () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => NumberSequenceScreen(startLevel: level)),
                      );
                      _loadProgress();
                    }
                  : null,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  color: isUnlocked ? color : Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(16),
                  border: isCompleted && stars == 3 ? Border.all(color: Colors.amber, width: 2) : null,
                  boxShadow: isUnlocked
                      ? [BoxShadow(color: color.withOpacity(0.4), blurRadius: 8, offset: const Offset(0, 4))]
                      : [],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (!isUnlocked)
                      Icon(Icons.lock_rounded, color: Colors.grey.shade400, size: 24)
                    else ...[
                      Text('$level', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                      if (isCompleted) ...[
                        const SizedBox(height: 3),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(
                            3,
                            (i) => Icon(i < stars ? Icons.star : Icons.star_border, color: Colors.amber, size: 11),
                          ),
                        ),
                      ],
                    ],
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}