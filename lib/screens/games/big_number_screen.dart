import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'big_number_config.dart';
import '../../services/firestore_service.dart';

class BigNumberScreen extends StatefulWidget {
  final int startLevel;
  const BigNumberScreen({super.key, required this.startLevel});

  @override
  State<BigNumberScreen> createState() => _BigNumberScreenState();
}

class _BigNumberScreenState extends State<BigNumberScreen> {
  static const Color purpleDark = Color(0xFF3C3489);
  static const Color purpleLight = Color(0xFF9C6FE0);
  static const Color cardNavy = Color(0xFF1E2140);

  final FirestoreService _firestoreService = FirestoreService();
  final Random _random = Random();

  late int _currentLevel;
  late BigNumberLevelConfig _config;

  int _round = 0;
  int _score = 0;
  int _errors = 0;
  int _streak = 0;

  bool _countdown = true;
  int _countdownValue = 3;

  late NumberCard _cardA;
  late NumberCard _cardB;
  String? _flashResult; // 'correct' | 'wrong' | null

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
    _config = BigNumberLevelConfig.get(_currentLevel);
    _round = 0;
    _score = 0;
    _errors = 0;
    _streak = 0;
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
      _timer?.cancel();
      _finishGame(timeUp: false);
      return;
    }
    setState(() {
      _cardA = _config.generateCard(_random);
      _cardB = _config.generateCard(_random);
      _flashResult = null;
    });
  }

  void _onAnswer(bool pickedA, {bool pickedEqual = false}) {
    if (_flashResult != null) return;

    bool isCorrect;
    if (pickedEqual) {
      isCorrect = _cardA.value == _cardB.value;
    } else if (pickedA) {
      isCorrect = _cardA.value > _cardB.value;
    } else {
      isCorrect = _cardB.value > _cardA.value;
    }

    setState(() {
      if (isCorrect) {
        _score += 10 + (_currentLevel * 2);
        _streak++;
        _flashResult = 'correct';
        if (_streak % 5 == 0) {
          _remainingSeconds += 10;
        }
      } else {
        _errors++;
        _streak = 0;
        _flashResult = 'wrong';
      }
      _round++;
    });

    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) _generateRound();
    });
  }

  Future<void> _finishGame({required bool timeUp}) async {
    final errors = timeUp ? _errors + (_config.totalRounds - _round) : _errors;
    final stars = _config.stars(errors);
    final nextLv = _config.nextLevel(errors);

    final prefs = await SharedPreferences.getInstance();

    if (nextLv > _currentLevel) {
      final current = prefs.getInt('bignumber_unlocked_level') ?? 1;
      if (nextLv > current) {
        await prefs.setInt('bignumber_unlocked_level', nextLv);
      }
    }

    if (stars > 0) {
      final key = 'bignumber_stars_level_$_currentLevel';
      final oldStars = prefs.getInt(key) ?? 0;
      if (stars > oldStars) {
        await prefs.setInt(key, stars);
      }
    }

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      final accuracy = _round == 0
          ? 0
          : (((_round - errors).clamp(0, _round) / _round) * 100).round();
      await _firestoreService.saveGameResult(
        uid: uid,
        gameName: 'Büyük Sayı',
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
      );
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
            _resultRow('⭐ Puan', '$_score'),
            _resultRow('✅ Tur', '$_round/${_config.totalRounds}'),
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
            colors: [purpleLight, purpleDark],
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
                        'Büyük Sayı — Level $_currentLevel',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
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
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (i) {
                  final filled =
                      (_streak % 5) > i ||
                      (_streak > 0 && _streak % 5 == 0 && i < 5);
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: filled ? Colors.orangeAccent : Colors.white24,
                    ),
                  );
                }),
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 30),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Büyük sayıya dokun!',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 20),
          _numberCard(_cardA.expression, () => _onAnswer(true)),
          const SizedBox(height: 16),
          _numberCard(_cardB.expression, () => _onAnswer(false)),
          const SizedBox(height: 24),
          GestureDetector(
            onTap: () => _onAnswer(false, pickedEqual: true),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: Colors.orange,
                borderRadius: BorderRadius.circular(30),
              ),
              child: const Text(
                'Eşit',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _numberCard(String text, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: const [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 30,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1E2140),
          ),
        ),
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
