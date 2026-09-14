import 'games/memory_level_select_screen.dart';
import 'games/number_sequence_level_select_screen.dart';
import 'games/big_number_level_select_screen.dart';
import 'games/number_challenge_level_select_screen.dart';
import 'games/dot_connect_level_select_screen.dart';
import 'games/symbol_grid_level_select_screen.dart';
import 'games/word_color_level_select_screen.dart';
import 'games/person_match_level_select_screen.dart';
import 'games/word_builder_level_select_screen.dart';
import 'games/word_definition_level_select_screen.dart';
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
            _categorySection('Hafıza ', [
              _gameData(
                'Eşleştirmece',
                'Kolay',
                Icons.style,
                Colors.amber,
                true,
              ),
              _gameData(
                'Sayı Dizisi',
                'Orta',
                Icons.format_list_numbered,
                Colors.orange,
                true,
              ),
            ]),
            const SizedBox(height: 8),
            _categorySection('Matematik', [
              _gameData(
                'Büyük Sayı',
                'Kolay',
                Icons.calculate,
                Colors.blue,
                true,
              ),
              _gameData(
                'Sayı Mücadelesi',
                'Orta',
                Icons.trending_up,
                Colors.blue,
                true,
              ),
            ]),
            const SizedBox(height: 8),
            _categorySection('Problem Çözme', [
              _gameData(
                'Noktaları Birleştir',
                'Orta',
                Icons.timeline,
                Colors.indigo,
                true,
              ),
              _gameData(
                'Küp Bulmacası',
                'Zor',
                Icons.view_in_ar,
                Colors.indigo,
                true,
              ),
            ]),
            const SizedBox(height: 8),
            _categorySection('Dikkat', [
              _gameData(
                'Renk Tanıma',
                'Kolay',
                Icons.color_lens,
                Colors.teal,
                true,
              ),
              _gameData(
                'Kişi Benzerliği',
                'Orta',
                Icons.face,
                Colors.teal,
                true,
              ),
            ]),
            const SizedBox(height: 8),
            _categorySection('Dil', [
              _gameData(
                'Kelime Oluşturma',
                'Kolay',
                Icons.abc,
                Colors.pink,
                true,
              ),
              _gameData(
                'Kelime Tanımı',
                'Orta',
                Icons.menu_book,
                Colors.pink,
                true,
              ),
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
    bool isAvailable,
  ) {
    return {
      'name': name,
      'level': level,
      'icon': icon,
      'color': color,
      'isAvailable': isAvailable,
    };
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
              game['isAvailable'],
            ),
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _gameCard(
    String name,
    String level,
    IconData icon,
    Color color,
    bool isAvailable,
  ) {
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
            child: isAvailable
                ? ElevatedButton.icon(
                    onPressed: () {
                      if (name == 'Eşleştirmece') {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const MemoryLevelSelectScreen(),
                          ),
                        );
                      } else if (name == 'Sayı Dizisi') {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                const NumberSequenceLevelSelectScreen(),
                          ),
                        );
                      } else if (name == 'Büyük Sayı') {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const BigNumberLevelSelectScreen(),
                          ),
                        );
                      } else if (name == 'Sayı Mücadelesi') {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                const NumberChallengeLevelSelectScreen(),
                          ),
                        );
                      } else if (name == 'Noktaları Birleştir') {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const DotConnectLevelSelectScreen(),
                          ),
                        );
                      } else if (name == 'Küp Bulmacası') {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const SymbolGridLevelSelectScreen(),
                          ),
                        );
                      } else if (name == 'Renk Tanıma') {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const WordColorLevelSelectScreen(),
                          ),
                        );
                      } else if (name == 'Kişi Benzerliği') {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                const PersonMatchLevelSelectScreen(),
                          ),
                        );
                      } else if (name == 'Kelime Oluşturma') {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                const WordBuilderLevelSelectScreen(),
                          ),
                        );
                      } else if (name == 'Kelime Tanımı') {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                const WordDefinitionLevelSelectScreen(),
                          ),
                        );
                      }
                    },
                    icon: const Icon(
                      Icons.play_arrow,
                      color: Colors.white,
                      size: 18,
                    ),
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
                  )
                : ElevatedButton.icon(
                    onPressed: null,
                    icon: const Icon(
                      Icons.lock_clock,
                      color: Colors.grey,
                      size: 18,
                    ),
                    label: const Text(
                      'Yakında',
                      style: TextStyle(color: Colors.grey),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey.shade200,
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
