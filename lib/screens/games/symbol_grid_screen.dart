import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'symbol_grid_config.dart';
import '../../services/firestore_service.dart';

class SymbolGridScreen extends StatefulWidget {
  final int startLevel;
  const SymbolGridScreen({super.key, required this.startLevel});

  @override
  State<SymbolGridScreen> createState() => _SymbolGridScreenState();
}

class _SymbolGridScreenState extends State<SymbolGridScreen> {
  static const Color purpleDark = Color(0xFF3C2F63);
  static const Color purpleLight = Color(0xFF9C4FC7);

  final FirestoreService _firestoreService = FirestoreService();
  final Random _random = Random();

  late int _currentLevel;
  late SymbolGridLevelConfig _config;

  int _score = 0;
  int _errors = 0;

  late List<List<int>> _solution;
  late List<List<int?>> _board;
  late List<SymbolOption> _activeSymbols;
  List<int> _trayPieces = [];
  int? _wrongCellRow, _wrongCellCol;

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
    _config = SymbolGridLevelConfig.get(_currentLevel);
    _score = 0;
    _errors = 0;
    _timeDisplay = '00:00';

    _generatePuzzle();

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
  }

  void _generatePuzzle() {
    final n = _config.gridSize;
    final pool = [...SymbolGridLevelConfig.allSymbols]..shuffle(_random);
    _activeSymbols = pool.sublist(0, _config.symbolCount);

    final rowOrder = List.generate(n, (i) => i)..shuffle(_random);
    final colOrder = List.generate(n, (i) => i)..shuffle(_random);
    final symbolOrder = List.generate(n, (i) => i)..shuffle(_random);

    _solution = List.generate(n, (r) {
      return List.generate(n, (c) {
        final base = (rowOrder[r] + colOrder[c]) % n;
        return symbolOrder[base];
      });
    });

    final allCells = <Point<int>>[];
    for (int r = 0; r < n; r++) {
      for (int c = 0; c < n; c++) {
        allCells.add(Point(r, c));
      }
    }
    allCells.shuffle(_random);
    final emptyCells = allCells.take(_config.emptyCells).toList();

    _board = List.generate(n, (r) => List.generate(n, (c) => _solution[r][c]));
    _trayPieces = [];
    for (final cell in emptyCells) {
      _trayPieces.add(_board[cell.x][cell.y]!);
      _board[cell.x][cell.y] = null;
    }
    _trayPieces.shuffle(_random);
  }

  bool get _isComplete => _board.every((row) => row.every((cell) => cell != null));

  void _onPieceDropped(int symbolIndex, int row, int col) {
    if (_board[row][col] != null) return;

    if (_solution[row][col] == symbolIndex) {
      setState(() {
        _board[row][col] = symbolIndex;
        _trayPieces.remove(symbolIndex);
        _score += 10 + (_currentLevel * 2);
      });
      if (_isComplete) _finishGame();
    } else {
      setState(() {
        _errors++;
        _wrongCellRow = row;
        _wrongCellCol = col;
      });
      Future.delayed(const Duration(milliseconds: 400), () {
        if (!mounted) return;
        setState(() {
          _wrongCellRow = null;
          _wrongCellCol = null;
        });
      });
    }
  }

  Future<void> _finishGame() async {
    _clockTimer?.cancel();
    _stopwatch.stop();

    final errors = _errors;
    final stars = _config.stars(errors);
    final nextLv = _config.nextLevel(errors);

    final prefs = await SharedPreferences.getInstance();

    if (nextLv > _currentLevel) {
      final current = prefs.getInt('symbolgrid_unlocked_level') ?? 1;
      if (nextLv > current) {
        await prefs.setInt('symbolgrid_unlocked_level', nextLv);
      }
    }

    if (stars > 0) {
      final key = 'symbolgrid_stars_level_$_currentLevel';
      final oldStars = prefs.getInt(key) ?? 0;
      if (stars > oldStars) {
        await prefs.setInt(key, stars);
      }
    }

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      await _firestoreService.saveGameResult(
        uid: uid,
        gameName: 'Sembol Tablosu',
        score: _score,
        accuracy: 100,
        errors: errors,
        difficulty: _config.difficultyLabel,
        level: _currentLevel,
        stars: stars,
        duration: _timeDisplay,
      );
    }

    if (mounted) _showResultDialog(stars: stars, errors: errors, nextLevel: nextLv);
  }

  void _showResultDialog({required int stars, required int errors, required int nextLevel}) {
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
                (i) => Icon(i < stars ? Icons.star : Icons.star_border, color: Colors.amber, size: 36),
              ),
            ),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center, style: const TextStyle(fontSize: 15)),
            const SizedBox(height: 12),
            _resultRow('⏱ Süre', _timeDisplay),
            _resultRow('⭐ Puan', '$_score'),
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
                backgroundColor: purpleDark,
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
    final n = _config.gridSize;

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
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                    Expanded(
                      child: Text(
                        'Sembol Tablosu — Level $_currentLevel',
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
                    _statChip(Icons.timer, _timeDisplay),
                    _statChip(Icons.star, '$_score puan'),
                    _statChip(Icons.close, '$_errors hata'),
                  ],
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 10),
                child: Text(
                  'Parçaları, satır ve sütunda tekrar olmayacak şekilde yerleştir!',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w600, fontSize: 12),
                ),
              ),
              Expanded(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: AspectRatio(
                      aspectRatio: 1,
                      child: GridView.builder(
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: n,
                          crossAxisSpacing: 6,
                          mainAxisSpacing: 6,
                        ),
                        itemCount: n * n,
                        itemBuilder: (context, index) {
                          final row = index ~/ n;
                          final col = index % n;
                          final filled = _board[row][col];
                          final isWrong = _wrongCellRow == row && _wrongCellCol == col;

                          return DragTarget<int>(
                            onWillAcceptWithDetails: (details) => filled == null,
                            onAcceptWithDetails: (details) => _onPieceDropped(details.data, row, col),
                            builder: (context, candidateData, rejectedData) {
                              return AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                decoration: BoxDecoration(
                                  color: isWrong
                                      ? Colors.red.shade400
                                      : filled != null
                                          ? _activeSymbols[filled].color
                                          : candidateData.isNotEmpty
                                              ? Colors.white24
                                              : Colors.black26,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: filled != null
                                    ? Icon(
                                        _activeSymbols[filled].icon,
                                        color: Colors.white,
                                        size: 26,
                                      )
                                    : null,
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
                child: Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  alignment: WrapAlignment.center,
                  children: _trayPieces.asMap().entries.map((entry) {
                    final symbolIndex = entry.value;
                    final symbol = _activeSymbols[symbolIndex];
                    return Draggable<int>(
                      data: symbolIndex,
                      feedback: Material(
                        color: Colors.transparent,
                        child: Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: symbol.color,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(symbol.icon, color: Colors.white, size: 28),
                        ),
                      ),
                      childWhenDragging: Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: Colors.white12,
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: symbol.color,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: const [
                            BoxShadow(color: Colors.black26, blurRadius: 6, offset: Offset(0, 3)),
                          ],
                        ),
                        child: Icon(symbol.icon, color: Colors.white, size: 28),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
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
        Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
      ],
    );
  }
}