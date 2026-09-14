import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'word_definition_config.dart';
import '../../services/firestore_service.dart';

class WordDefinitionScreen extends StatefulWidget {
  final int startLevel;
  const WordDefinitionScreen({super.key, required this.startLevel});

  @override
  State<WordDefinitionScreen> createState() => _WordDefinitionScreenState();
}

class _WordDefinitionScreenState extends State<WordDefinitionScreen> {
  static const List<String> alphabet = [
    'A', 'B', 'C', 'Ç', 'D', 'E', 'F', 'G', 'Ğ', 'H', 'I', 'İ', 'J', 'K', 'L',
    'M', 'N', 'O', 'Ö', 'P', 'R', 'S', 'Ş', 'T', 'U', 'Ü', 'V', 'Y', 'Z',
  ];

  final FirestoreService _firestoreService = FirestoreService();
  final Random _random = Random();

  late int _currentLevel;
  late WordDefinitionLevelConfig _config;

  int _round = 0;
  int _score = 0;
  int _errors = 0;

  bool _countdown = true;
  int _countdownValue = 3;

  late WordDefinitionEntry _entry;
  List<String> _revealedLetters = [];
  int _nextBlankIndex = 0;
  List<String> _currentOptions = [];
  String? _wrongOption;

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
    _config = WordDefinitionLevelConfig.get(_currentLevel);
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
    _entry = pool[_random.nextInt(pool.length)];
    _revealedLetters = List.filled(_entry.word.length, '');
    _nextBlankIndex = 0;
    _generateOptionsForCurrentBlank();
  }

  void _generateOptionsForCurrentBlank() {
    final correctLetter = _entry.word[_nextBlankIndex];
    final decoys = alphabet.where((l) => l != correctLetter).toList()..shuffle(_random);
    final options = [correctLetter, ...decoys.take(_config.decoyCount)]..shuffle(_random);
    setState(() {
      _currentOptions = options;
      _wrongOption = null;
    });
  }

  void _onOptionTap(String letter) {
    if (_wrongOption != null) return;

    final correctLetter = _entry.word[_nextBlankIndex];

    if (letter == correctLetter) {
      setState(() {
        _revealedLetters[_nextBlankIndex] = letter;
        _score += 5 + (_currentLevel * 1);
        _nextBlankIndex++;
      });

      if (_nextBlankIndex >= _entry.word.length) {
        setState(() => _round++);
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) _generateRound();
        });
      } else {
        _generateOptionsForCurrentBlank();
      }
    } else {
      setState(() {
        _errors++;
        _wrongOption = letter;
      });
      Future.delayed(const Duration(milliseconds: 350), () {
        if (!mounted) return;
        setState(() => _wrongOption = null);
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
      final current = prefs.getInt('worddefinition_unlocked_level') ?? 1;
      if (nextLv > current) {
        await prefs.setInt('worddefinition_unlocked_level', nextLv);
      }
    }

    if (stars > 0) {
      final key = 'worddefinition_stars_level_$_currentLevel';
      final oldStars = prefs.getInt(key) ?? 0;
      if (stars > oldStars) {
        await prefs.setInt(key, stars);
      }
    }

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      await _firestoreService.saveGameResult(
        uid: uid,
        gameName: 'Kelime Tanımı',
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
                backgroundColor: const Color(0xFF9C27B0),
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
            colors: [Color(0xFFE8A2C0), Color(0xFF6A4C9C)],
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
                        'Kelime Tanımı — Level $_currentLevel',
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
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              _entry.hint,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: Color(0xFF6A4C9C)),
            ),
          ),
          const SizedBox(height: 24),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              color: Colors.black87,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Wrap(
              alignment: WrapAlignment.center,
              spacing: 6,
              children: List.generate(_entry.word.length, (i) {
                final letter = _revealedLetters[i];
                return Text(
                  letter.isEmpty ? '_' : letter,
                  style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold),
                );
              }),
            ),
          ),
          const SizedBox(height: 36),
          Wrap(
            spacing: 14,
            runSpacing: 14,
            alignment: WrapAlignment.center,
            children: _currentOptions.map((letter) {
              final isWrong = _wrongOption == letter;
              return GestureDetector(
                onTap: () => _onOptionTap(letter),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: isWrong ? Colors.red : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 6, offset: Offset(0, 3))],
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    letter,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: isWrong ? Colors.white : const Color(0xFF6A4C9C),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
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