import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'number_sequence_config.dart';
import '../../services/firestore_service.dart';

class NumberSequenceScreen extends StatefulWidget {
  final int startLevel;
  const NumberSequenceScreen({super.key, required this.startLevel});

  @override
  State<NumberSequenceScreen> createState() => _NumberSequenceScreenState();
}

class _NumberSequenceScreenState extends State<NumberSequenceScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final Random _random = Random();

  late int _currentLevel;
  late NumberSequenceLevelConfig _config;

  List<int> _sequence = [];
  List<int> _choices = [];
  List<int> _userInput = [];

  int _score = 0;
  int _errors = 0;

  bool _countdown = true;
  int _countdownValue = 3;
  bool _isShowingSequence = false;
  int _displayIndex = -1; // gösterilen sayının sırası, -1 = hiçbiri
  bool _canAnswer = false;
  int? _wrongTapNumber; // yanlış dokunulan sayı, kısa süre kırmızı gösterilecek

  late Stopwatch _stopwatch;
  String _timeDisplay = '00:00';
  Timer? _clockTimer;

  @override
  void initState() {
    super.initState();
    _currentLevel = widget.startLevel;
    _initGame();
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    super.dispose();
  }

  void _initGame() {
    _config = NumberSequenceLevelConfig.get(_currentLevel);
    _score = 0;
    _errors = 0;
    _userInput = [];
    _timeDisplay = '00:00';

    // Diziyi oluştur (1-9 arası, tekrarsız)
    final pool = List.generate(9, (i) => i + 1)..shuffle(_random);
    _sequence = pool.sublist(0, _config.sequenceLength);

    // Çeldiricileri oluştur (diziye dahil olmayan sayılardan)
    final remaining = List.generate(
      9,
      (i) => i + 1,
    ).where((n) => !_sequence.contains(n)).toList()..shuffle(_random);
    final decoys = remaining.sublist(
      0,
      min(_config.decoyCount, remaining.length),
    );

    _choices = [..._sequence, ...decoys]..shuffle(_random);

    _stopwatch = Stopwatch()..start();
    _clockTimer?.cancel();
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        final elapsed = _stopwatch.elapsed;
        _timeDisplay =
            '${elapsed.inMinutes.toString().padLeft(2, '0')}:${(elapsed.inSeconds % 60).toString().padLeft(2, '0')}';
      });
    });

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
    _showSequence();
  }

  Future<void> _showSequence() async {
    setState(() {
      _isShowingSequence = true;
      _canAnswer = false;
    });

    for (int i = 0; i < _sequence.length; i++) {
      if (!mounted) return;
      setState(() => _displayIndex = i);
      await Future.delayed(Duration(milliseconds: _config.digitDisplayMs));
      if (!mounted) return;
      setState(() => _displayIndex = -1);
      await Future.delayed(
        const Duration(milliseconds: 250),
      ); // sayılar arası boşluk
    }

    if (!mounted) return;
    setState(() {
      _isShowingSequence = false;
      _canAnswer = true;
    });
  }

  void _onChoiceTap(int number) {
    if (!_canAnswer || _wrongTapNumber != null) return;

    final expectedIndex = _userInput.length;
    final expectedNumber = _sequence[expectedIndex];

    if (number == expectedNumber) {
      // Doğru sıradaki doğru sayı
      setState(() {
        _userInput.add(number);
        _score += 10 + (_currentLevel * 2);
      });

      if (_userInput.length == _sequence.length) {
        // Dizi tamamlandı
        setState(() => _canAnswer = false);
        _finishGame();
      }
    } else {
      // Yanlış sayı ya da yanlış sıra — kırmızı yanıp söner
      setState(() {
        _errors++;
        _wrongTapNumber = number;
      });
      Future.delayed(const Duration(milliseconds: 350), () {
        if (!mounted) return;
        setState(() => _wrongTapNumber = null);
      });
    }
  }

  Future<void> _finishGame() async {
    _clockTimer?.cancel();
    _stopwatch.stop();

    final errors = _errors;
    final totalAttempts = _sequence.length + errors;
    final accuracy = totalAttempts == 0
        ? 100
        : ((_sequence.length / totalAttempts) * 100).round();
    final stars = _config.stars(errors);
    final nextLv = _config.nextLevel(errors);

    final prefs = await SharedPreferences.getInstance();

    if (nextLv > _currentLevel) {
      final current = prefs.getInt('sequence_unlocked_level') ?? 1;
      if (nextLv > current) {
        await prefs.setInt('sequence_unlocked_level', nextLv);
      }
    }

    if (stars > 0) {
      final key = 'sequence_stars_level_$_currentLevel';
      final oldStars = prefs.getInt(key) ?? 0;
      if (stars > oldStars) {
        await prefs.setInt(key, stars);
      }
    }

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      await _firestoreService.saveGameResult(
        uid: uid,
        gameName: 'Sayı Dizisi',
        score: _score,
        accuracy: accuracy.toDouble(),
        errors: errors,
        difficulty: _config.difficultyLabel,
        level: _currentLevel,
        stars: stars,
        duration: _timeDisplay,
      );
    }

    if (mounted)
      _showResultDialog(
        stars: stars,
        accuracy: accuracy,
        errors: errors,
        nextLevel: nextLv,
      );
  }

  void _showResultDialog({
    required int stars,
    required int accuracy,
    required int errors,
    required int nextLevel,
  }) {
    final isLastLevel = _currentLevel == 15;

    String message;
    if (isLastLevel && stars == 3) {
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
          stars == 3
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
            _resultRow('⏱ Süre', _timeDisplay),
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
          'Sayı Dizisi — Level $_currentLevel',
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: Colors.white,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _statChip(Icons.timer, _timeDisplay, Colors.blue),
                _statChip(Icons.star, '$_score puan', Colors.orange),
                _statChip(Icons.close, '$_errors hata', Colors.purple),
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
          Expanded(
            child: Center(
              child: _countdown
                  ? Text(
                      '$_countdownValue',
                      style: const TextStyle(
                        fontSize: 72,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  : _isShowingSequence
                  ? Text(
                      _displayIndex >= 0 ? '${_sequence[_displayIndex]}' : '',
                      style: const TextStyle(
                        fontSize: 96,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2196F3),
                      ),
                    )
                  : _buildAnswerArea(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnswerArea() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Kullanıcının şu ana kadar seçtiği sayılar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Wrap(
            spacing: 8,
            children: List.generate(
              _sequence.length,
              (i) => Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: i < _userInput.length
                      ? const Color(0xFF4CAF50)
                      : Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  i < _userInput.length ? '${_userInput[i]}' : '',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 40),
        const Text(
          'Gördüğün sırayla dokun!',
          style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 20),
        Wrap(
          spacing: 14,
          runSpacing: 14,
          alignment: WrapAlignment.center,
          children: _choices.map((n) {
            final isWrong = _wrongTapNumber == n;
            return GestureDetector(
              onTap: () => _onChoiceTap(n),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: 64,
                height: 64,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isWrong ? Colors.red : const Color(0xFF2196F3),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  '$n',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
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
