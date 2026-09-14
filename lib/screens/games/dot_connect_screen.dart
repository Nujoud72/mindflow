import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dot_connect_config.dart';
import '../../services/firestore_service.dart';

class DotConnectScreen extends StatefulWidget {
  final int startLevel;
  const DotConnectScreen({super.key, required this.startLevel});

  @override
  State<DotConnectScreen> createState() => _DotConnectScreenState();
}

class _DotConnectScreenState extends State<DotConnectScreen> {
  final FirestoreService _firestoreService = FirestoreService();

  late int _currentLevel;
  late DotConnectLevelConfig _config;
  late DotPuzzle _puzzle;

  int _score = 0;
  int _resets = 0; // parmağını erken kaldırma sayısı
  Set<int> _usedEdges = {};
  int? _currentNode;
  bool _started = false;

  late Stopwatch _stopwatch;
  String _timeDisplay = '00:00';
  Timer? _clockTimer;

  Size _boardSize = const Size(320, 400);

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
    _config = DotConnectLevelConfig.get(_currentLevel);
    _puzzle = _config.randomPuzzle(_currentLevel);
    _score = 0;
    _resets = 0;
    _usedEdges = {};
    _currentNode = null;
    _started = false;
    _timeDisplay = '00:00';

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

  Offset _nodePixelPos(int index) {
    final p = _puzzle.nodePositions[index];
    return Offset(p[0] * _boardSize.width, p[1] * _boardSize.height);
  }

  int? _findNearestNode(Offset pos, {double tolerance = 26}) {
    int? closest;
    double closestDist = tolerance;
    for (int i = 0; i < _puzzle.nodePositions.length; i++) {
      final dist = (pos - _nodePixelPos(i)).distance;
      if (dist < closestDist) {
        closestDist = dist;
        closest = i;
      }
    }
    return closest;
  }

  // currentNode'dan çıkan, henüz kullanılmamış kenarlardan hangisine dokunuluyor
  int? _findTraversableEdge(Offset pos, {double tolerance = 24}) {
    if (_currentNode == null) return null;
    int? bestEdge;
    double bestDist = tolerance;

    for (int i = 0; i < _puzzle.edges.length; i++) {
      if (_usedEdges.contains(i)) continue;
      final edge = _puzzle.edges[i];
      if (edge.fromIndex != _currentNode && edge.toIndex != _currentNode) continue;

      final otherIndex = edge.fromIndex == _currentNode ? edge.toIndex : edge.fromIndex;
      final a = _nodePixelPos(_currentNode!);
      final b = _nodePixelPos(otherIndex);
      final dist = _distanceToSegment(pos, a, b);

      // parmağın diğer uca daha yakın olması, o kenara doğru ilerlendiğini gösterir
      final distToOther = (pos - b).distance;
      final distToCurrent = (pos - a).distance;

      if (dist < bestDist && distToOther < distToCurrent) {
        bestDist = dist;
        bestEdge = i;
      }
    }
    return bestEdge;
  }

  double _distanceToSegment(Offset p, Offset a, Offset b) {
    final ab = b - a;
    final ap = p - a;
    final abLenSq = ab.dx * ab.dx + ab.dy * ab.dy;
    double t = abLenSq == 0 ? 0 : (ap.dx * ab.dx + ap.dy * ab.dy) / abLenSq;
    t = t.clamp(0.0, 1.0);
    final closest = Offset(a.dx + ab.dx * t, a.dy + ab.dy * t);
    return (p - closest).distance;
  }

  void _onPanStart(DragStartDetails details) {
    if (_usedEdges.length == _puzzle.edges.length) return;
    final node = _findNearestNode(details.localPosition);
    if (node == null) return;

    if (!_started) {
      // İlk başlangıç: geçerli başlangıç noktalarından biri olmalı
      if (!_puzzle.validStartNodes.contains(node)) return;
      setState(() {
        _started = true;
        _currentNode = node;
      });
    } else {
      // Devam ediyor: sadece kaldığı düğümden devam edebilir
      if (node != _currentNode) return;
    }
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (_currentNode == null) return;
    final edgeIndex = _findTraversableEdge(details.localPosition);
    if (edgeIndex == null) return;

    final edge = _puzzle.edges[edgeIndex];
    final otherNode = edge.fromIndex == _currentNode ? edge.toIndex : edge.fromIndex;

    setState(() {
      _usedEdges.add(edgeIndex);
      _currentNode = otherNode;
      _score += 10 + (_currentLevel * 2);
    });

    if (_usedEdges.length == _puzzle.edges.length) {
      _finishGame();
    }
  }

  void _onPanEnd(DragEndDetails details) {
    if (_usedEdges.length == _puzzle.edges.length) return;
    if (!_started) return;
    // Bitirmeden parmağını kaldırdı — sıfırla
    setState(() {
      _resets++;
      _usedEdges = {};
      _currentNode = null;
      _started = false;
      _score = 0;
    });
  }

  Future<void> _finishGame() async {
    _clockTimer?.cancel();
    _stopwatch.stop();

    final elapsedSeconds = _stopwatch.elapsed.inSeconds;
    final stars = _config.stars(elapsedSeconds);
    final nextLv = _config.nextLevel(elapsedSeconds);

    final prefs = await SharedPreferences.getInstance();

    if (nextLv > _currentLevel) {
      final current = prefs.getInt('dotconnect_unlocked_level') ?? 1;
      if (nextLv > current) {
        await prefs.setInt('dotconnect_unlocked_level', nextLv);
      }
    }

    if (stars > 0) {
      final key = 'dotconnect_stars_level_$_currentLevel';
      final oldStars = prefs.getInt(key) ?? 0;
      if (stars > oldStars) {
        await prefs.setInt(key, stars);
      }
    }

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      await _firestoreService.saveGameResult(
        uid: uid,
        gameName: 'Noktaları Birleştir',
        score: _score,
        accuracy: 100,
        errors: _resets,
        difficulty: _config.difficultyLabel,
        level: _currentLevel,
        stars: stars,
        duration: _timeDisplay,
      );
    }

    if (mounted) _showResultDialog(stars: stars, nextLevel: nextLv);
  }

  void _showResultDialog({required int stars, required int nextLevel}) {
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
            _resultRow('🔄 Tekrar Dene', '$_resets kez'),
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
                backgroundColor: const Color(0xFF2196F3),
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

  void _resetPuzzle() {
    setState(() {
      _usedEdges = {};
      _currentNode = null;
      _started = false;
      _score = 0;
    });
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
          'Noktaları Birleştir — Level $_currentLevel',
          style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 15),
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
                _statChip(
                  Icons.linear_scale,
                  '${_usedEdges.length}/${_puzzle.edges.length}',
                  Colors.indigo,
                ),
                IconButton(
                  icon: const Icon(Icons.refresh, color: Colors.grey),
                  onPressed: _resetPuzzle,
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 20),
            child: Text(
              _started
                  ? 'Parmağını kaldırmadan çiz!'
                  : 'Yeşil (yanıp sönen) noktadan başla, parmağını kaldırmadan çiz!',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.w600, fontSize: 13),
            ),
          ),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                _boardSize = Size(constraints.maxWidth - 40, constraints.maxHeight - 20);
                return Center(
                  child: GestureDetector(
                    onPanStart: _onPanStart,
                    onPanUpdate: _onPanUpdate,
                    onPanEnd: _onPanEnd,
                    child: SizedBox(
                      width: _boardSize.width,
                      height: _boardSize.height,
                      child: CustomPaint(
                        painter: _DotConnectPainter(
                          puzzle: _puzzle,
                          usedEdges: _usedEdges,
                          boardSize: _boardSize,
                          currentNode: _currentNode,
                          started: _started,
                        ),
                      ),
                    ),
                  ),
                );
              },
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
        Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13)),
      ],
    );
  }
}

class _DotConnectPainter extends CustomPainter {
  final DotPuzzle puzzle;
  final Set<int> usedEdges;
  final Size boardSize;
  final int? currentNode;
  final bool started;

  _DotConnectPainter({
    required this.puzzle,
    required this.usedEdges,
    required this.boardSize,
    required this.currentNode,
    required this.started,
  });

  Offset _pos(int index) {
    final p = puzzle.nodePositions[index];
    return Offset(p[0] * boardSize.width, p[1] * boardSize.height);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final grayPaint = Paint()
      ..color = Colors.grey.shade400
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    final greenPaint = Paint()
      ..color = const Color(0xFF43A047)
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;

    for (int i = 0; i < puzzle.edges.length; i++) {
      final edge = puzzle.edges[i];
      final a = _pos(edge.fromIndex);
      final b = _pos(edge.toIndex);
      canvas.drawLine(a, b, usedEdges.contains(i) ? greenPaint : grayPaint);
    }

    final normalNodePaint = Paint()..color = const Color(0xFF43A047);
    final startNodePaint = Paint()..color = Colors.orange;
    final currentNodePaint = Paint()..color = const Color(0xFF2196F3);

    for (int i = 0; i < puzzle.nodePositions.length; i++) {
      Paint paint = normalNodePaint;
      if (!started && puzzle.validStartNodes.length < puzzle.nodePositions.length && puzzle.validStartNodes.contains(i)) {
        paint = startNodePaint;
      }
      if (started && i == currentNode) {
        paint = currentNodePaint;
      }
      canvas.drawCircle(_pos(i), 14, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _DotConnectPainter oldDelegate) {
    return oldDelegate.usedEdges.length != usedEdges.length ||
        oldDelegate.currentNode != currentNode ||
        oldDelegate.started != started;
  }
}