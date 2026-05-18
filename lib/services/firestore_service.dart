import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Kullanıcı profili oluştur
  Future<void> createUserProfile(String uid, String name, String email) async {
    await _db.collection('users').doc(uid).set({
      'name': name,
      'email': email,
      'level': 1,
      'totalPoints': 0,
      'weeklyStreak': 0,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // Kullanıcı profilini getir
  Future<Map<String, dynamic>?> getUserProfile(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    return doc.data();
  }

  // Puan güncelle
  Future<void> updatePoints(String uid, int points) async {
    await _db.collection('users').doc(uid).update({
      'totalPoints': FieldValue.increment(points),
    });
  }

  // Oyun sonucunu kaydet
  Future<void> saveGameResult({
    required String uid,
    required String gameName,
    required int score,
    required double accuracy,
    required int errors,
    required String difficulty,
    required int level,
    required int stars,
    required String duration,
  }) async {
    await _db.collection('users').doc(uid).collection('gameResults').add({
      'gameName': gameName,
      'score': score,
      'accuracy': accuracy,
      'errors': errors,
      'difficulty': difficulty,
      'level': level,
      'stars': stars,
      'duration': duration,
      'playedAt': FieldValue.serverTimestamp(),
    });

    // Toplam puanı da güncelle
    await _db.collection('users').doc(uid).update({
      'totalPoints': FieldValue.increment(score),
    });
  }

  // Kullanıcının oyun sonuçlarını getir
  Future<List<Map<String, dynamic>>> getGameResults(String uid) async {
    final snapshot = await _db
        .collection('users')
        .doc(uid)
        .collection('gameResults')
        .orderBy('playedAt', descending: true)
        .limit(20)
        .get();

    return snapshot.docs.map((doc) => doc.data()).toList();
  }

  // Günlük görevleri getir
  Future<List<Map<String, dynamic>>> getDailyTasks(String uid) async {
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);

    final snapshot = await _db
        .collection('users')
        .doc(uid)
        .collection('dailyTasks')
        .where('date', isGreaterThanOrEqualTo: startOfDay)
        .get();

    return snapshot.docs.map((doc) => doc.data()).toList();
  }

  // Haftalık seriyi güncelle
  Future<void> updateStreak(String uid) async {
    await _db.collection('users').doc(uid).update({
      'weeklyStreak': FieldValue.increment(1),
      'lastActiveDate': FieldValue.serverTimestamp(),
    });
  }

  // Günlük seriyi hesapla
  Future<int> calculateStreak(String uid) async {
    final snapshot = await _db
        .collection('users')
        .doc(uid)
        .collection('gameResults')
        .orderBy('playedAt', descending: true)
        .get();

    if (snapshot.docs.isEmpty) return 0;

    final dates =
        snapshot.docs
            .map((doc) {
              final ts = doc.data()['playedAt'];
              if (ts == null) return null;
              final dt = (ts as dynamic).toDate() as DateTime;
              return DateTime(dt.year, dt.month, dt.day);
            })
            .whereType<DateTime>()
            .toSet()
            .toList()
          ..sort((a, b) => b.compareTo(a));

    if (dates.isEmpty) return 0;

    final today = DateTime(
      DateTime.now().year,
      DateTime.now().month,
      DateTime.now().day,
    );

    // Bugün veya dün oynamadıysa streak sıfır
    if (dates[0].isBefore(today.subtract(const Duration(days: 1)))) return 0;

    int streak = 1;
    for (int i = 0; i < dates.length - 1; i++) {
      final diff = dates[i].difference(dates[i + 1]).inDays;
      if (diff == 1) {
        streak++;
      } else {
        break;
      }
    }
    return streak;
  }

  // Bugün oynanan oyun sayısı
  Future<int> getTodayGamesCount(String uid) async {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);

    final snapshot = await _db
        .collection('users')
        .doc(uid)
        .collection('gameResults')
        .where('playedAt', isGreaterThanOrEqualTo: startOfDay)
        .get();

    return snapshot.docs.length;
  }
}
