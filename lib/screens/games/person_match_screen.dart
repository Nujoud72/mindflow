import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'person_match_config.dart';
import '../../services/firestore_service.dart';

class PersonMatchScreen extends StatefulWidget {
  final int startLevel;
  const PersonMatchScreen({super.key, required this.startLevel});

  @override
  State<PersonMatchScreen> createState() => _PersonMatchScreenState();
}

class _PersonMatchScreenState extends State<PersonMatchScreen> {
  static const Color cream = Color(0xFFF5EFE0);
  static const Color orangeDark = Color(0xFFD35400);

  // 6 sabit daire pozisyonu (oranlı, kutuya göre ölçeklenir)
  static const List<List<double>> circlePositions = [
    [0.5, 0.05],
    [0.85, 0.28],
    [0.7, 0.7],
    [0.3, 0.7],
    [0.15, 0.28],
    [0.5, 0.45],
  ];

  final FirestoreService _firestoreService = FirestoreService();
  final Random _random = Random();

  late int _currentLevel;
  late PersonMatchLevelConfig _config;
  late List<String> _activeAvatars;

  int _round = 0;
  int _score = 0;
  int _errors = 0;

  bool _countdown = true;
  int _countdownValue = 3;

  List<String> _sequence = [];
  String _currentAvatar = '';
  int _currentPosition = 0;
  bool _correctAnswer = false;
  bool _answered = false;
  bool? _lastCorrect;
  bool _hasEnoughHistory = false;

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
    _config = PersonMatchLevelConfig.get(_currentLevel);
    _activeAvatars = ([...PersonMatchLevelConfig.avatarPool]..shuffle(_random)).sublist(0, _config.avatarPoolSize);
    _round = 0;
    _score = 0;
    _errors = 0;
    _sequence = [];
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

    final avatar = _activeAvatars[_random.nextInt(_activeAvatars.length)];
    _sequence.add(avatar);

    final hasEnoughHistory = _sequence.length > _config.nBack;
    final matchTarget = hasEnoughHistory ? _sequence[_sequence.length - 1 - _config.nBack] : null;

    setState(() {
      _currentAvatar = avatar;
      _currentPosition = _random.nextInt(circlePositions.length);
      _correctAnswer = hasEnoughHistory && matchTarget == avatar;
      _hasEnoughHistory = hasEnoughHistory;
      _answered = false;
      _lastCorrect = null;
    });
  }

  void _onAnswer(bool userSaidYes) {
    if (_countdown || _answered) return;

    bool isCorrect = true;
    if (_hasEnoughHistory) {
      isCorrect = userSaidYes == _correctAnswer;
    }

    setState(() {
      _answered = true;
      _lastCorrect = isCorrect;
      if (_hasEnoughHistory) {
        if (isCorrect) {
          _score += 10 + (_currentLevel * 2);
        } else {
          _errors++;
        }
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
    final total = _config.totalRounds - _config.nBack;
    final accuracy = total <= 0 ? 0 : (((total - errors).clamp(0, total) / total) * 100).round();
    final stars = timeUp ? 0 : _config.stars(errors);
    final nextLv = timeUp ? _currentLevel : _config.nextLevel(errors);

    final prefs = await SharedPreferences.getInstance();

    if (nextLv > _currentLevel) {
      final current = prefs.getInt('personmatch_unlocked_level') ?? 1;
      if (nextLv > current) {
        await prefs.setInt('personmatch_unlocked_level', nextLv);
      }
    }

    if (stars > 0) {
      final key = 'personmatch_stars_level_$_currentLevel';
      final oldStars = prefs.getInt(key) ?? 0;
      if (stars > oldStars) {
        await prefs.setInt(key, stars);
      }
    }

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      await _firestoreService.saveGameResult(
        uid: uid,
        gameName: 'Kişi Benzerliği',
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
                backgroundColor: orangeDark,
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
      backgroundColor: cream,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: orangeDark),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Expanded(
                    child: Text(
                      'Kişi Benzerliği — Level $_currentLevel',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: orangeDark, fontWeight: FontWeight.bold, fontSize: 15),
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
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                child: Text(
                  _hasEnoughHistory
                      ? '${_config.nBack} adım önceki kişiyle aynı mı?'
                      : 'Kişileri iyi hatırla!',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: orangeDark, fontWeight: FontWeight.w600, fontSize: 14),
                ),
              ),
            Expanded(
              child: Center(
                child: _countdown
                    ? Text(
                        '$_countdownValue',
                        style: const TextStyle(fontSize: 72, fontWeight: FontWeight.bold, color: orangeDark),
                      )
                    : _buildCircleArea(),
              ),
            ),
            if (!_countdown)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                child: Row(
                  children: [
                    Expanded(child: _answerButton('Hayır', Colors.grey.shade400, () => _onAnswer(false))),
                    const SizedBox(width: 16),
                    Expanded(child: _answerButton('Evet', Colors.green, () => _onAnswer(true))),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCircleArea() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final boardSize = min(constraints.maxWidth, constraints.maxHeight) - 20;
        return SizedBox(
          width: boardSize,
          height: boardSize,
          child: Stack(
            children: List.generate(circlePositions.length, (i) {
              final pos = circlePositions[i];
              final isActive = i == _currentPosition;
              return Positioned(
                left: pos[0] * boardSize - 45,
                top: pos[1] * boardSize - 45,
                child: Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isActive
                        ? (_answered
                            ? (_lastCorrect == true ? Colors.green.shade100 : Colors.red.shade100)
                            : Colors.white)
                        : Colors.white,
                    boxShadow: const [
                      BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 3)),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: isActive ? Text(_currentAvatar, style: const TextStyle(fontSize: 42)) : null,
                ),
              );
            }),
          ),
        );
      },
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
        Icon(icon, color: orangeDark, size: 16),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(color: orangeDark, fontWeight: FontWeight.bold, fontSize: 13)),
      ],
    );
  }
}