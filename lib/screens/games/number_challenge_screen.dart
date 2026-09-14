import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'number_challenge_config.dart';
import '../../services/firestore_service.dart';

class _Bubble {
  final int value;
  final Offset position;
  final Color color;
  bool cleared;

  _Bubble({
    required this.value,
    required this.position,
    required this.color,
    this.cleared = false,
  });
}

class NumberChallengeScreen extends StatefulWidget {
  final int startLevel;
  const NumberChallengeScreen({super.key, required this.startLevel});

  @override
  State<NumberChallengeScreen> createState() => _NumberChallengeScreenState();
}

class _NumberChallengeScreenState extends State<NumberChallengeScreen> {
  static const Color purpleDark = Color(0xFF3C3489);
  static const Color purpleLight = Color(0xFF378ADD);

  final FirestoreService _firestoreService = FirestoreService();
  final Random _random = Random();

  late int _currentLevel;
  late NumberChallengeLevelConfig _config;

  int _score = 0;
  int _errors = 0;
  int _nextIndex =
      0; // sırada beklenen doğru sıradaki indeks (sorted list içinde)

  bool _countdown = true;
  int _countdownValue = 3;

  List<_Bubble> _bubbles = [];
  List<int> _sortedValues = [];
  int? _wrongTapValue;

  int _remainingSeconds = 0;
  int _elapsedSeconds = 0;
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
    _config = NumberChallengeLevelConfig.get(_currentLevel);
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

    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        _remainingSeconds--;
        _elapsedSeconds++;
        if (_remainingSeconds <= 0) {
          _timer?.cancel();
          _finishGame(timeUp: true);
        }
      });
    });

    _generateRound();
  }

  void _generateRound() {
    final numbers = _config.generateNumbers(_random);
    _sortedValues = [...numbers]..sort();
    _nextIndex = 0;

    final colors = [...NumberChallengeLevelConfig.bubbleColors]
      ..shuffle(_random);
    final positions = _generatePositions(numbers.length);

    setState(() {
      _bubbles = List.generate(numbers.length, (i) {
        return _Bubble(
          value: numbers[i],
          position: positions[i],
          color: colors[i % colors.length],
        );
      });
      _wrongTapValue = null;
    });
  }

  List<Offset> _generatePositions(int count) {
    final positions = <Offset>[];
    const areaWidth = 320.0;
    const areaHeight = 380.0;
    const bubbleSize = 76.0;
    int attempts = 0;

    while (positions.length < count && attempts < 300) {
      attempts++;
      final candidate = Offset(
        _random.nextDouble() * (areaWidth - bubbleSize),
        _random.nextDouble() * (areaHeight - bubbleSize),
      );
      final overlaps = positions.any(
        (p) => (p - candidate).distance < bubbleSize,
      );
      if (!overlaps) positions.add(candidate);
    }
    while (positions.length < count) {
      positions.add(
        Offset(
          _random.nextDouble() * (areaWidth - bubbleSize),
          _random.nextDouble() * (areaHeight - bubbleSize),
        ),
      );
    }
    return positions;
  }

  void _onBubbleTap(_Bubble bubble) {
    if (bubble.cleared || _wrongTapValue != null) return;

    final expectedValue = _sortedValues[_nextIndex];

    if (bubble.value == expectedValue) {
      setState(() {
        bubble.cleared = true;
        _score += 10 + (_currentLevel * 2);
        _nextIndex++;
      });

      if (_nextIndex >= _sortedValues.length) {
        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted) _generateRound();
        });
      }
    } else {
      setState(() {
        _errors++;
        _wrongTapValue = bubble.value;
      });
      Future.delayed(const Duration(milliseconds: 350), () {
        if (!mounted) return;
        setState(() => _wrongTapValue = null);
      });
    }
  }

  Future<void> _finishGame({required bool timeUp}) async {
    final errors = timeUp
        ? _errors + (_sortedValues.length - _nextIndex)
        : _errors;
    final totalAttempts = _nextIndex + errors;
    final accuracy = totalAttempts == 0
        ? 100
        : ((_nextIndex / totalAttempts) * 100).round();
    final stars = _config.stars(errors);
    final nextLv = _config.nextLevel(errors);

    final prefs = await SharedPreferences.getInstance();

    if (nextLv > _currentLevel) {
      final current = prefs.getInt('numberchallenge_unlocked_level') ?? 1;
      if (nextLv > current) {
        await prefs.setInt('numberchallenge_unlocked_level', nextLv);
      }
    }

    if (stars > 0) {
      final key = 'numberchallenge_stars_level_$_currentLevel';
      final oldStars = prefs.getInt(key) ?? 0;
      if (stars > oldStars) {
        await prefs.setInt(key, stars);
      }
    }

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      await _firestoreService.saveGameResult(
        uid: uid,
        gameName: 'Sayı Mücadelesi',
        score: _score,
        accuracy: accuracy.toDouble(),
        errors: errors,
        difficulty: _config.difficultyLabel,
        level: _currentLevel,
        stars: stars,
        duration: '${_config.timeLimitSeconds}s',
      );
    }

    if (mounted)
      _showResultDialog(
        stars: stars,
        errors: errors,
        nextLevel: nextLv,
        timeUp: timeUp,
        accuracy: accuracy,
      );
  }

  void _showResultDialog({
    required int stars,
    required int errors,
    required int nextLevel,
    required bool timeUp,
    required int accuracy,
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
                (i) => Icon(
                  i < stars ? Icons.star : Icons.star_border,
                  color: Colors.amber,
                  size: 36,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 15),
            ),
            const SizedBox(height: 12),
            _resultRow('⏱ Süre', '${_elapsedSeconds}s'),
            _resultRow('⭐ Puan', '$_score'),
            _resultRow('🎯 Doğruluk', '%$accuracy'),
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
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                '🏠 Ana Sayfaya Dön',
                style: TextStyle(color: Colors.white),
              ),
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
                backgroundColor: purpleDark,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                nextLevel > _currentLevel
                    ? 'Sonraki Level ➡️'
                    : 'Tekrar Oyna 🔁',
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
          Text(
            value,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
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
            colors: [purpleDark, purpleLight],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                    Expanded(
                      child: Text(
                        'Sayı Mücadelesi — Level $_currentLevel',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
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
              if (!_countdown)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 10),
                  child: Text(
                    'Rakamlara küçükten büyüğe dokun!',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              Expanded(
                child: Center(
                  child: _countdown
                      ? Text(
                          '$_countdownValue',
                          style: const TextStyle(
                            fontSize: 72,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        )
                      : _buildBubbleArea(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBubbleArea() {
    return SizedBox(
      width: 320,
      height: 380,
      child: Stack(
        children: _bubbles.map((bubble) {
          final isWrong = _wrongTapValue == bubble.value;
          if (bubble.cleared) return const SizedBox.shrink();
          return Positioned(
            left: bubble.position.dx,
            top: bubble.position.dy,
            child: GestureDetector(
              onTap: () => _onBubbleTap(bubble),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: 76,
                height: 76,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isWrong ? Colors.redAccent : bubble.color,
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 6,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: Text(
                  '${bubble.value}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _statChip(IconData icon, String label) {
    return Row(
      children: [
        Icon(icon, color: Colors.white, size: 16),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
      ],
    );
  }
}
