import 'games/memory_level_select_screen.dart';
import 'games/memory_game_screen.dart';
import 'package:flutter/material.dart';

class GamesScreen extends StatefulWidget {
  const GamesScreen({super.key});

  @override
  State<GamesScreen> createState() => _GamesScreenState();
}

class _GamesScreenState extends State<GamesScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Oyunlar',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 16),
            child: Icon(Icons.notifications_outlined, color: Colors.black),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _categorySection('Hafıza Oyunları', [
              _gameData('Eşleştirmece', 'Kolay', Icons.style, Colors.amber),
              _gameData(
                'Sayı Dizisi',
                'Orta',
                Icons.format_list_numbered,
                Colors.orange,
              ),
            ]),
            const SizedBox(height: 8),
            _categorySection('Dikkat Oyunları', [
              _gameData(
                'Odaklanma Akışı',
                'Orta',
                Icons.remove_red_eye,
                Colors.green,
              ),
              _gameData('Renk Tanıma', 'Kolay', Icons.color_lens, Colors.teal),
            ]),
            const SizedBox(height: 8),
            _categorySection('Problem Çözme', [
              _gameData('Bulmaca Yolu', 'Zor', Icons.psychology, Colors.purple),
              _gameData('Mantık Zinciri', 'Orta', Icons.link, Colors.indigo),
            ]),
          ],
        ),
      ),
    );
  }

  Map<String, dynamic> _gameData(
    String name,
    String level,
    IconData icon,
    Color color,
  ) {
    return {'name': name, 'level': level, 'icon': icon, 'color': color};
  }

  Widget _categorySection(String title, List<Map<String, dynamic>> games) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        ...games.map(
          (game) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _gameCard(
              game['name'],
              game['level'],
              game['icon'],
              game['color'],
            ),
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _gameCard(String name, String level, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.bar_chart, size: 14, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(
                        level,
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                if (name == 'Eşleştirmece') {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const MemoryLevelSelectScreen(),
                    ),
                  );
                }
              },
              icon: const Icon(Icons.play_arrow, color: Colors.white, size: 18),
              label: const Text(
                'Hemen Oyna',
                style: TextStyle(color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2196F3),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
