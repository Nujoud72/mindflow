class UserModel {
  final String uid;
  final String name;
  final String email;
  final int level;
  final int totalPoints;
  final int weeklyStreak;

  UserModel({
    required this.uid,
    required this.name,
    required this.email,
    this.level = 1,
    this.totalPoints = 0,
    this.weeklyStreak = 0,
  });

  factory UserModel.fromMap(String uid, Map<String, dynamic> map) {
    return UserModel(
      uid: uid,
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      level: map['level'] ?? 1,
      totalPoints: map['totalPoints'] ?? 0,
      weeklyStreak: map['weeklyStreak'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'level': level,
      'totalPoints': totalPoints,
      'weeklyStreak': weeklyStreak,
    };
  }

  String get rankTitle {
    if (level >= 10) return 'Zihin Ustası';
    if (level >= 7) return 'Zihin Kaşifi';
    if (level >= 5) return 'Zihin Gezgini';
    if (level >= 3) return 'Zihin Yolcusu';
    return 'Zihin Yeni Başlayanı';
  }
}
