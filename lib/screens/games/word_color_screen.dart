import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'word_color_config.dart';
import '../../services/firestore_service.dart';

class WordColorScreen extends StatefulWidget {
  final int startLevel;
  const WordColorScreen({super.key, required this.startLevel});

  @override
  State<WordColorScreen> createState() => _WordColorScreenState();
}

class _WordColorScreenState extends State<WordColorScreen> {
  static const Color navyDark = Color(0xFF161B4D);
  static const Color navyLight = Color(0xFF2E3A9C);

  final FirestoreService _firestoreService = FirestoreService();
  final Random _random = Random();

  late int _currentLevel;
  late WordColorLevelConfig _config;
  late List<ColorWordOption> _activeColors;

  int _round = 0;
  int _score = 0;
  int _errors = 0;

  bool _countdown = true;
  int _countdownValue = 3;

  late ColorWordOption _topWord; // üstteki kelime (anlamı)
  late ColorWordOption _bottomWordMeaning; // alttaki kelimenin anlamı
  late Color _bottomWordColor; // alttaki kelimenin yazı rengi
  late bool _correctAnswer; // gerçek doğru cevap (eşleşiyor mu)

  bool _answered = false;
  bool? _lastAnswerCorrect;

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
    _config = WordColorLevelConfig.get(_currentLevel);
    _activeColors = WordColorLevelConfig.allColors.sublist(0, _config.colorCount);
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

    // Üst kelime: rastgele bir renk adı (siyah yazılır, sadece anlamı önemli)
    final top = _activeColors[_random.nextInt(_activeColors.length)];

    // Alt kelime: rastgele bir renk adı (anlamı)
    final bottomMeaning = _activeColors[_random.nextInt(_activeColors.length)];

    // %50 ihtimalle alt kelimenin yazı rengi = üst kelimenin anlamı (doğru cevap: Evet)
    final shouldMatch = _random.nextBool();
    Color bottomColor;
    if (shouldMatch) {
      bottomColor = top.color;
    } else {
      final others = _activeColors.where((c) => c.color != top.color).toList();
      bottomColor = others[_random.nextInt(others.length)].color;
    }

    setState(() {
      _topWord = top;
      _bottomWordMeaning = bottomMeaning;
      _bottomWordColor = bottomColor;
      _correctAnswer = bottomColor == top.color;
      _answered = false;
      _lastAnswerCorrect = null;
    });
  }

  void _onAnswer(bool userSaidYes) {
    if (_countdown || _answered) return;

    final isCorrect = userSaidYes == _correctAnswer;

    setState(() {
      _answered = true;
      _lastAnswerCorrect = isCorrect;
      if (isCorrect) {
        _score += 10 + (_currentLevel * 2);
      } else {
        _errors++;
      }
      _round++;
    });

    Future.delayed(const Duration(milliseconds: 350), () {
      if (mounted) _generateRound();
    });
  }

  Future<void> _finishGame({required bool timeUp}) async {
    _timer?.cancel();

    final errors = timeUp ? _errors + (_config.totalRounds - _round) : _errors;
    final total = _config.totalRounds;
    final accuracy = total == 0 ? 0 : (((total - errors).clamp(0, total) / total) * 100).round();
    final stars = timeUp ? 0 : _config.stars(errors);
    final nextLv = timeUp ? _currentLevel : _config.nextLevel(errors);

    final prefs = await SharedPreferences.getInstance();

    if (nextLv > _currentLevel) {
      final current = prefs.getInt('wordcolor_unlocked_level') ?? 1;
      if (nextLv > current) {
        await prefs.setInt('wordcolor_unlocked_level', nextLv);
      }
    }

    if (stars > 0) {
      final key = 'wordcolor_stars_level_$_currentLevel';
      final oldStars = prefs.getInt(key) ?? 0;
      if (stars > oldStars) {
        await prefs.setInt(key, stars);
      }
    }

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      await _firestoreService.saveGameResult(
        uid: uid,
        gameName: 'Kelime ve Renk',
        score: _score,
        accuracy: accuracy.toDouble(),
        errors: errors,
        difficulty: _config.difficultyLabel,
        level: _currentLevel,
        stars: stars,
        duration: '${_config.timeLimitSeconds}s',
      );
    }

    if (mounted) _showResultDialog(stars: stars, accuracy: accuracy, errors: errors, nextLevel: nextLv, timeUp: timeUp);
  }

  void _showResultDialog({
    required int stars,
    required int accuracy,
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
                backgroundColor: navyDark,
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
            colors: [navyDark, navyLight],
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
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                    Expanded(
                      child: Text(
                        'Kelime ve Renk — Level $_currentLevel',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
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
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: LinearProgressIndicator(
                    value: _round / _config.totalRounds,
                    minHeight: 6,
                    backgroundColor: Colors.white12,
                    color: Colors.blueAccent,
                  ),
                ),
              Expanded(
                child: Center(
                  child: _countdown
                      ? Text(
                          '$_countdownValue',
                          style: const TextStyle(fontSize: 72, fontWeight: FontWeight.bold, color: Colors.white),
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
          _pillLabel('Kelime Anlamı'),
          const SizedBox(height: 10),
          _wordCard(_topWord.label, Colors.black),
          const SizedBox(height: 24),
          _wordCard(_bottomWordMeaning.label, _bottomWordColor),
          const SizedBox(height: 10),
          _pillLabel('Yazı Rengi'),
          const SizedBox(height: 30),
          Row(
            children: [
              Expanded(
                child: _answerButton(
                  'Hayır',
                  Colors.white24,
                  () => _onAnswer(false),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _answerButton(
                  'Evet',
                  const Color(0xFF2196F3),
                  () => _onAnswer(true),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _pillLabel(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white24,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _wordCard(String text, Color textColor) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 22),
      decoration: BoxDecoration(
        color: _answered
            ? (_lastAnswerCorrect == true ? Colors.green.shade100 : Colors.red.shade100)
            : Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: textColor),
      ),
    );
  }

  Widget _answerButton(String label, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(30),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _statChip(IconData icon, String label) {
    return Row(
      children: [
        Icon(icon, color: Colors.white, size: 16),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
      ],
    );
  }
}