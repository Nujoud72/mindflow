import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';
import 'memory_level_config.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/firestore_service.dart';

class MemoryGameScreen extends StatefulWidget {
  final int startLevel;
  const MemoryGameScreen({super.key, this.startLevel = 1});

  @override
  State<MemoryGameScreen> createState() => _MemoryGameScreenState();
}

class _MemoryGameScreenState extends State<MemoryGameScreen> {
  // Emoji havuzu — çocuklar için eğlenceli
  final List<String> _allEmojis = [
    '🐶',
    '🐱',
    '🐭',
    '🐹',
    '🐰',
    '🦊',
    '🐻',
    '🐼',
    '🐨',
    '🦁',
    '🐮',
    '🐷',
    '🐸',
    '🐙',
    '🦋',
    '🌸',
    '🍎',
    '🍓',
    '⭐',
    '🌈',
  ];

  late MemoryLevelConfig _config;
  late List<String> _cards;
  late List<bool> _flipped;
  late List<bool> _matched;

  int? _firstIndex;
  int? _secondIndex;
  bool _canFlip = false; // Önizleme bitene kadar kapalı
  bool _isPreviewing = true;

  int _currentLevel = 1;
  int _score = 0;
  int _errors = 0;
  int _moves = 0;

  late Stopwatch _stopwatch;
  Timer? _gameTimer;
  Timer? _countdownTimer;
  String _timeDisplay = '00:00';
  int _remainingSeconds = 0;

  @override
  void initState() {
    super.initState();
    _currentLevel = widget.startLevel;
    _initGame();
  }

  @override
  void dispose() {
    _gameTimer?.cancel();
    _countdownTimer?.cancel();
    _stopwatch.stop();
    super.dispose();
  }

  void _initGame() {
    _config = MemoryLevelConfig.get(_currentLevel);

    // Kartları hazırla
    final selected = (_allEmojis..shuffle(Random())).sublist(0, _config.pairs);
    _cards = [...selected, ...selected]..shuffle(Random());
    _flipped = List.filled(_cards.length, true); // Önizleme: hepsi açık
    _matched = List.filled(_cards.length, false);

    _firstIndex = null;
    _secondIndex = null;
    _canFlip = false;
    _isPreviewing = true;
    _score = 0;
    _errors = 0;
    _moves = 0;
    _timeDisplay = '00:00';
    _remainingSeconds = _config.timeLimitSeconds;

    _stopwatch = Stopwatch()..start();

    // Süre sayacı
    _gameTimer?.cancel();
    _gameTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        final elapsed = _stopwatch.elapsed;
        _timeDisplay =
            '${elapsed.inMinutes.toString().padLeft(2, '0')}:${(elapsed.inSeconds % 60).toString().padLeft(2, '0')}';

        // Geri sayım varsa
        if (_config.timeLimitSeconds > 0 && !_isPreviewing) {
          _remainingSeconds--;
          if (_remainingSeconds <= 0) {
            _gameTimer?.cancel();
            _stopwatch.stop();
            _showResultDialog(timeUp: true);
          }
        }
      });
    });

    // Önizleme bitti → kartları kapat
    _countdownTimer?.cancel();
    _countdownTimer = Timer(
      Duration(milliseconds: (_config.previewSeconds * 1000).toInt()),
      () {
        if (!mounted) return;
        setState(() {
          _flipped = List.filled(_cards.length, false);
          _canFlip = true;
          _isPreviewing = false;
          _remainingSeconds = _config.timeLimitSeconds;
        });
      },
    );
  }

  void _onCardTap(int index) {
    if (!_canFlip || _flipped[index] || _matched[index]) return;

    setState(() => _flipped[index] = true);

    if (_firstIndex == null) {
      _firstIndex = index;
    } else {
      _secondIndex = index;
      _canFlip = false;
      _moves++;

      if (_cards[_firstIndex!] == _cards[_secondIndex!]) {
        // Eşleşti!
        setState(() {
          _matched[_firstIndex!] = true;
          _matched[_secondIndex!] = true;
          _score += 10 + (_currentLevel * 2); // Level'a göre bonus puan
          _firstIndex = null;
          _secondIndex = null;
          _canFlip = true;
        });

        if (_matched.every((m) => m)) {
          _gameTimer?.cancel();
          _stopwatch.stop();
          _showResultDialog(timeUp: false);
        }
      } else {
        // Eşleşmedi
        _errors++;
        Future.delayed(const Duration(milliseconds: 900), () {
          if (!mounted) return;
          setState(() {
            _flipped[_firstIndex!] = false;
            _flipped[_secondIndex!] = false;
            _firstIndex = null;
            _secondIndex = null;
            _canFlip = true;
          });
        });
      }
    }
  }

  void _showResultDialog({required bool timeUp}) async {
    final accuracy = _moves > 0
        ? ((_config.pairs / _moves) * 100).clamp(0, 100).toInt()
        : 100;
    final stars = timeUp ? 0 : _config.stars(accuracy, _errors);
    final nextLevel = timeUp
        ? _currentLevel
        : _config.nextLevel(accuracy, _errors);

    // Kazanılan leveli kaydet
    final prefs = await SharedPreferences.getInstance();
    final nextLv = _config.nextLevel(accuracy, _errors);

    // Firebase'e kaydet
    final user = FirebaseAuth.instance.currentUser;
    if (user != null && !timeUp) {
      await FirestoreService().saveGameResult(
        uid: user.uid,
        gameName: 'Hafıza Kartları',
        score: _score,
        accuracy: accuracy.toDouble(),
        errors: _errors,
        difficulty: _config.difficultyLabel,
        level: _currentLevel,
        stars: stars,
        duration: _timeDisplay,
      );
    }

    // Sonraki leveli aç (level geçildiyse)
    if (!timeUp && nextLv > _currentLevel) {
      final current = prefs.getInt('memory_unlocked_level') ?? 1;
      if (nextLv > current) {
        await prefs.setInt('memory_unlocked_level', nextLv);
      }
    }

    // Bu levelin yıldızını kaydet (daha iyisi varsa güncelle)
    if (!timeUp && stars > 0) {
      final key = 'memory_stars_level_$_currentLevel';
      final oldStars = prefs.getInt(key) ?? 0;
      if (stars > oldStars) {
        await prefs.setInt(key, stars);
      }
    }

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
            // Yıldızlar
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
            _resultRow('⏱ Süre', _timeDisplay),
            _resultRow('⭐ Puan', '$_score'),
            _resultRow('🎯 Doğruluk', '%$accuracy'),
            _resultRow('🔄 Tekrar Dene', '$_errors kez'),
            const SizedBox(height: 8),
            Text(
              isLastLevel && stars == 3
                  ? '🎊 Oyunu bitirdin, efsanesin!'
                  : nextLevel > _currentLevel
                  ? '➡️ Level ${nextLevel}\'e geçiyorsun!'
                  : nextLevel < _currentLevel
                  ? '⬅️ Level ${nextLevel}\'de tekrar deneyelim'
                  : '🔁 Level ${nextLevel}\'i tekrar oyna',
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
                Navigator.pop(context); // Ana sayfaya dön
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
                backgroundColor: const Color(0xFF2196F3),
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
    final isCountdown = _config.timeLimitSeconds > 0 && !_isPreviewing;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Hafıza Kartları — Level $_currentLevel',
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
      body: Column(
        children: [
          // Üst bilgi çubuğu
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: Colors.white,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _statChip(
                  Icons.timer,
                  isCountdown ? '${_remainingSeconds}s' : _timeDisplay,
                  isCountdown && _remainingSeconds <= 30
                      ? Colors.red
                      : Colors.blue,
                ),
                _statChip(Icons.star, '$_score puan', Colors.orange),
                _statChip(Icons.refresh, '$_errors tekrar', Colors.purple),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: _config.difficultyLabel == 'Kolay'
                        ? const Color(0xFFE8F5E9)
                        : _config.difficultyLabel == 'Orta'
                        ? const Color(0xFFFFF3E0)
                        : const Color(0xFFFFEBEE),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _config.difficultyLabel,
                    style: TextStyle(
                      color: _config.difficultyLabel == 'Kolay'
                          ? Colors.green
                          : _config.difficultyLabel == 'Orta'
                          ? Colors.orange
                          : Colors.red,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Önizleme banner
          if (_isPreviewing)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 8),
              color: const Color(0xFF2196F3),
              child: Text(
                '👀 Kartları ezberle! ${_config.previewSeconds.toStringAsFixed(1)} saniye...',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

          // Kart grid
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: GridView.builder(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: _config.gridCols,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                ),
                itemCount: _cards.length,
                itemBuilder: (context, index) {
                  return GestureDetector(
                    onTap: () => _onCardTap(index),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      decoration: BoxDecoration(
                        color: _matched[index]
                            ? const Color(0xFFE8F5E9)
                            : _flipped[index]
                            ? Colors.white
                            : const Color(0xFF2196F3),
                        borderRadius: BorderRadius.circular(16),
                        border: _matched[index]
                            ? Border.all(color: Colors.green, width: 2)
                            : null,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Center(
                        child: _flipped[index] || _matched[index]
                            ? Text(
                                _cards[index],
                                style: const TextStyle(fontSize: 32),
                              )
                            : const Icon(
                                Icons.psychology,
                                color: Colors.white,
                                size: 30,
                              ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statChip(IconData icon, String label, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
      ],
    );
  }
}
