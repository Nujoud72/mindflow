import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'word_builder_config.dart';
import '../../services/firestore_service.dart';

class WordBuilderScreen extends StatefulWidget {
  final int startLevel;
  const WordBuilderScreen({super.key, required this.startLevel});

  @override
  State<WordBuilderScreen> createState() => _WordBuilderScreenState();
}

class _WordBuilderScreenState extends State<WordBuilderScreen> {
  static const List<Color> letterColors = [
    Color(0xFFE91E8C),
    Color(0xFF26C6DA),
    Color(0xFFAB47BC),
    Color(0xFFFF7043),
    Color(0xFF66BB6A),
  ];

  final FirestoreService _firestoreService = FirestoreService();
  final Random _random = Random();

  late int _currentLevel;
  late WordBuilderLevelConfig _config;

  int _round = 0;
  int _score = 0;
  int _errors = 0;

  bool _countdown = true;
  int _countdownValue = 3;

  late String _targetWord;
  late List<String> _shuffledLetters;
  List<int> _selectedIndices = [];
  int? _wrongIndex;

  int _remainingSeconds = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _currentLevel = widget.startLevel;
    _initGame();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _initGame() {
    _config = WordBuilderLevelConfig.get(_currentLevel);
    _round = 0;
    _score = 0;
    _errors = 0;
    _remainingSeconds = _config.timeLimitSeconds;
    _startCountdown();
  }

  Future<void> _startCountdown() async {
    setState(() => _countdown = true);
    for (int i = 3; i >= 1; i--) {
      if (!mounted) return;
      setState(() => _countdownValue = i);
      await Future.delayed(const Duration(seconds: 1));
    }
    if (!mounted) return;
    setState(() => _countdown = false);

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        _remainingSeconds--;
        if (_remainingSeconds <= 0) {
          _timer?.cancel();
          _finishGame(timeUp: true);
        }
      });
    });

    _generateRound();
  }

  void _generateRound() {
    if (_round >= _config.totalRounds) {
      _finishGame(timeUp: false);
      return;
    }

    final pool = _config.wordPool;
    _targetWord = pool[_random.nextInt(pool.length)];

    final letters = _targetWord.split('');
    final shuffled = [...letters];
    do {
      shuffled.shuffle(_random);
    } while (shuffled.length > 1 && shuffled.join() == _targetWord);

    setState(() {
      _shuffledLetters = shuffled;
      _selectedIndices = [];
      _wrongIndex = null;
    });
  }

  void _onLetterTap(int index) {
    if (_selectedIndices.contains(index) || _wrongIndex != null) return;

    final expectedLetter = _targetWord[_selectedIndices.length];
    final tappedLetter = _shuffledLetters[index];

    if (tappedLetter == expectedLetter) {
      setState(() {
        _selectedIndices.add(index);
        _score += 5 + (_currentLevel * 1);
      });

      if (_selectedIndices.length == _targetWord.length) {
        setState(() => _round++);
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) _generateRound();
        });
      }
    } else {
      setState(() {
        _errors++;
        _wrongIndex = index;
      });
      Future.delayed(const Duration(milliseconds: 350), () {
        if (!mounted) return;
        setState(() => _wrongIndex = null);
      });
    }
  }

  Future<void> _finishGame({required bool timeUp}) async {
    _timer?.cancel();

    final errors = timeUp ? _errors + (_config.totalRounds - _round) : _errors;
    final stars = timeUp ? 0 : _config.stars(errors);
    final nextLv = timeUp ? _currentLevel : _config.nextLevel(errors);

    final prefs = await SharedPreferences.getInstance();

    if (nextLv > _currentLevel) {
      final current = prefs.getInt('wordbuilder_unlocked_level') ?? 1;
      if (nextLv > current) {
        await prefs.setInt('wordbuilder_unlocked_level', nextLv);
      }
    }

    if (stars > 0) {
      final key = 'wordbuilder_stars_level_$_currentLevel';
      final oldStars = prefs.getInt(key) ?? 0;
      if (stars > oldStars) {
        await prefs.setInt(key, stars);
      }
    }

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      await _firestoreService.saveGameResult(
        uid: uid,
        gameName: 'Kelime Oluşturma',
        score: _score,
        accuracy: 0,
        errors: errors,
        difficulty: _config.difficultyLabel,
        level: _currentLevel,
        stars: stars,
        duration: '${_config.timeLimitSeconds}s',
      );
    }

    if (mounted) _showResultDialog(stars: stars, errors: errors, nextLevel: nextLv, timeUp: timeUp);
  }

  void _showResultDialog({
    required int stars,
    required int errors,
    required int nextLevel,
    required bool timeUp,
  }) {
    final isLastLevel = _currentLevel == 15;

    String message;
    if (timeUp) {
      message = 'Süre doldu! Tekrar deneyelim 💪';
    } else if (isLastLevel && stars == 3) {
      message = '🏆 Tebrikler! Tüm levelleri tamamladın!';
    } else if (stars == 3) {
      message = 'Mükemmel! Bir üst seviyeye geçiyorsun! 🚀';
    } else if (stars == 2) {
      message = 'Güzel iş! Devam et! 👍';
    } else if (stars == 1) {
      message = 'Tamamladın! Daha iyisini yapabilirsin 💪';
    } else {
      message = 'Neredeyse! Tekrar deneyelim 🔄';
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          timeUp
              ? '⏰ Süre Doldu!'
              : stars == 3
                  ? 'Tebrikler, Süpersin! 🏆'
                  : stars == 2
                      ? 'Tebrikler, Harikaydın! 🌟'
                      : stars == 1
                          ? 'Tebrikler, Başardın! 💪'
                          : 'Bir Dahaki Sefere! 🔄',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                3,
                (i) => Icon(i < stars ? Icons.star : Icons.star_border, color: Colors.amber, size: 36),
              ),
            ),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center, style: const TextStyle(fontSize: 15)),
            const SizedBox(height: 12),
            _resultRow('⭐ Puan', '$_score'),
            _resultRow('✅ Kelime', '$_round/${_config.totalRounds}'),
            _resultRow('❌ Hatalar', '$errors'),
            const SizedBox(height: 8),
            Text(
              isLastLevel && stars == 3
                  ? '🎊 Oyunu bitirdin, efsanesin!'
                  : nextLevel > _currentLevel
                      ? '➡️ Level $nextLevel\'e geçiyorsun!'
                      : '🔁 Level $_currentLevel\'i tekrar oyna',
              style: TextStyle(
                color: nextLevel > _currentLevel ? Colors.green : Colors.orange,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          if (isLastLevel && stars == 3) ...[
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('🏠 Ana Sayfaya Dön', style: TextStyle(color: Colors.white)),
            ),
          ] else ...[
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context);
              },
              child: const Text('Çıkış'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                setState(() {
                  _currentLevel = nextLevel;
                  _initGame();
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE91E8C),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(
                nextLevel > _currentLevel ? 'Sonraki Level ➡️' : 'Tekrar Oyna 🔁',
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _resultRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 14)),
          Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
        ],
      ),
    );
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
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.black87),
                      onPressed: () => Navigator.pop(context),
                    ),
                    Expanded(
                      child: Text(
                        'Kelime Oluşturma — Level $_currentLevel',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                    ),
                    const SizedBox(width: 48),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _statChip(Icons.timer, '${_remainingSeconds}s'),
                    _statChip(Icons.star, '$_score puan'),
                    _statChip(Icons.close, '$_errors hata'),
                  ],
                ),
              ),
              Expanded(
                child: Center(
                  child: _countdown
                      ? Text(
                          '$_countdownValue',
                          style: const TextStyle(fontSize: 72, fontWeight: FontWeight.bold, color: Colors.black87),
                        )
                      : _buildGameArea(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGameArea() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Üst boşluklar
        Wrap(
          spacing: 8,
          alignment: WrapAlignment.center,
          children: List.generate(_targetWord.length, (i) {
            final filled = i < _selectedIndices.length;
            return Container(
              width: 42,
              height: 48,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: filled ? const Color(0xFF66BB6A) : Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.black12),
              ),
              child: Text(
                filled ? _shuffledLetters[_selectedIndices[i]] : '',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            );
          }),
        ),
        const SizedBox(height: 40),
        const Text(
          'Bu harflerden bir kelime oluştur!',
          style: TextStyle(color: Colors.black54, fontWeight: FontWeight.w600, fontSize: 13),
        ),
        const SizedBox(height: 30),
        // Dairesel harf düzeni
        SizedBox(
          width: 260,
          height: 260,
          child: Stack(
            alignment: Alignment.center,
            children: List.generate(_shuffledLetters.length, (i) {
              final angle = (2 * pi * i) / _shuffledLetters.length - pi / 2;
              final radius = 95.0;
              final dx = radius * cos(angle);
              final dy = radius * sin(angle);
              final isUsed = _selectedIndices.contains(i);
              final isWrong = _wrongIndex == i;

              return Transform.translate(
                offset: Offset(dx, dy),
                child: GestureDetector(
                  onTap: () => _onLetterTap(i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isUsed
                          ? Colors.grey.shade300
                          : isWrong
                              ? Colors.red
                              : letterColors[i % letterColors.length],
                      boxShadow: isUsed
                          ? []
                          : [const BoxShadow(color: Colors.black26, blurRadius: 6, offset: Offset(0, 3))],
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      _shuffledLetters[i],
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: isUsed ? Colors.grey.shade500 : Colors.white,
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ],
    );
  }

  Widget _statChip(IconData icon, String label) {
    return Row(
      children: [
        Icon(icon, color: Colors.black87, size: 16),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 13)),
      ],
    );
  }
}