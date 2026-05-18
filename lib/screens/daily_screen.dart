import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/firestore_service.dart';

class DailyScreen extends StatefulWidget {
  const DailyScreen({super.key});

  @override
  State<DailyScreen> createState() => _DailyScreenState();
}

class _DailyScreenState extends State<DailyScreen> {
  final _firestoreService = FirestoreService();
  String _userName = '';
  bool _isLoading = true;

  final List<Map<String, dynamic>> _tasks = [
    {
      'name': 'Hafıza Kartları',
      'status': 'Tamamlandı',
      'icon': Icons.style,
      'color': Colors.green,
      'taskStatus': TaskStatus.done,
    },
    {
      'name': 'Odaklanma Akışı',
      'status': 'Devam Ediyor',
      'icon': Icons.remove_red_eye,
      'color': Colors.blue,
      'taskStatus': TaskStatus.inProgress,
    },
    {
      'name': 'Mantık Bulmacası',
      'status': 'Henüz Başlamadı',
      'icon': Icons.psychology,
      'color': Colors.orange,
      'taskStatus': TaskStatus.locked,
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final data = await _firestoreService.getUserProfile(uid);
    if (data != null) {
      setState(() {
        _userName = data['name'] ?? '';
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
    }
  }

  int get _completedTasks =>
      _tasks.where((t) => t['taskStatus'] == TaskStatus.done).length;

  double get _progress => _completedTasks / _tasks.length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Günlük Antrenman',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 16),
            child: Icon(Icons.tune, color: Colors.black),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE3F2FD),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2196F3),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.sentiment_satisfied_alt,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'HOŞ GELDİN!',
                              style: TextStyle(
                                fontSize: 11,
                                color: Color(0xFF2196F3),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Harika gidiyorsun, $_userName!',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Text(
                              'Devam et!',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Haftalık İlerleme',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _dayCircle('Pzt', true, false),
                            _dayCircle('Sal', true, false),
                            _dayCircle('Çar', true, false),
                            _dayCircle('Per', true, true),
                            _dayCircle('Cum', false, false),
                            _dayCircle('Cmt', false, false),
                            _dayCircle('Paz', false, false),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Bugünkü İlerleme',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey,
                              ),
                            ),
                            Text(
                              '%${(_progress * 100).toInt()}',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF2196F3),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: LinearProgressIndicator(
                            value: _progress,
                            minHeight: 10,
                            backgroundColor: const Color(0xFFE3F2FD),
                            valueColor: const AlwaysStoppedAnimation<Color>(
                              Color(0xFF2196F3),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Bugünkü Görevler',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  ..._tasks.map(
                    (task) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _taskCard(
                        task['name'],
                        task['status'],
                        task['icon'],
                        task['color'],
                        task['taskStatus'],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _dayCircle(String day, bool completed, bool isToday) {
    return Column(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: completed
                ? const Color(0xFF2196F3)
                : const Color(0xFFE3F2FD),
            border: isToday
                ? Border.all(color: const Color(0xFF2196F3), width: 2)
                : null,
          ),
          child: Icon(
            completed ? Icons.star : Icons.circle_outlined,
            color: completed ? Colors.white : Colors.grey,
            size: 18,
          ),
        ),
        const SizedBox(height: 4),
        Text(day, style: const TextStyle(fontSize: 11, color: Colors.grey)),
      ],
    );
  }

  Widget _taskCard(
    String name,
    String status,
    IconData icon,
    Color color,
    TaskStatus taskStatus,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                Text(status, style: TextStyle(color: color, fontSize: 12)),
              ],
            ),
          ),
          _taskAction(taskStatus),
        ],
      ),
    );
  }

  Widget _taskAction(TaskStatus status) {
    switch (status) {
      case TaskStatus.done:
        return const Icon(Icons.check_circle, color: Colors.green, size: 28);
      case TaskStatus.inProgress:
        return ElevatedButton(
          onPressed: () {},
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF2196F3),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
          child: const Text(
            'Başlat',
            style: TextStyle(color: Colors.white, fontSize: 13),
          ),
        );
      case TaskStatus.locked:
        return const Icon(Icons.lock_outline, color: Colors.grey, size: 24);
    }
  }
}

enum TaskStatus { done, inProgress, locked }
