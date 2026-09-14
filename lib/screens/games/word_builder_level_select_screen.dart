import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'word_builder_screen.dart';

class WordBuilderLevelSelectScreen extends StatefulWidget {
  const WordBuilderLevelSelectScreen({super.key});

  @override
  State<WordBuilderLevelSelectScreen> createState() =>
      _WordBuilderLevelSelectScreenState();
}

class _WordBuilderLevelSelectScreenState
    extends State<WordBuilderLevelSelectScreen> {
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
      stars[i] = prefs.getInt('wordbuilder_stars_level_$i') ?? 0;
    }
    setState(() {
      _unlockedLevel = prefs.getInt('wordbuilder_unlocked_level') ?? 1;
      _levelStars = stars;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFFB74D), Color(0xFFF5EFE0)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.black87),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const Text(
                      '🔤 Kelime Oluşturma',
                      style: TextStyle(
                        color: Colors.black87,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSection('Kolay', 1, 5),
                      const SizedBox(height: 24),
                      _buildSection('Orta', 6, 10),
                      const SizedBox(height: 24),
                      _buildSection('Zor', 11, 15),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection(String label, int from, int to) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.08),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.black87,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
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
                        MaterialPageRoute(
                          builder: (_) => WordBuilderScreen(startLevel: level),
                        ),
                      );
                      _loadProgress();
                    }
                  : null,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  color: isUnlocked
                      ? Colors.white
                      : Colors.white.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(16),
                  border: isCompleted && stars == 3
                      ? Border.all(color: Colors.amber, width: 2)
                      : null,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (!isUnlocked)
                      const Icon(
                        Icons.lock_rounded,
                        color: Colors.black38,
                        size: 24,
                      )
                    else ...[
                      Text(
                        '$level',
                        style: const TextStyle(
                          color: Color(0xFFE91E8C),
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (isCompleted) ...[
                        const SizedBox(height: 3),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(
                            3,
                            (i) => Icon(
                              i < stars ? Icons.star : Icons.star_border,
                              color: Colors.amber,
                              size: 11,
                            ),
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
