import 'package:flutter/material.dart';
import 'dart:math';

class AchievementsScreen extends StatelessWidget {
  final List<String> completedAchievements;
  final Function(String) onAchievementCompleted;

  AchievementsScreen({
    super.key,
    required this.completedAchievements,
    required this.onAchievementCompleted,
  });

  List<Map<String, dynamic>> get _achievements {
    final List<Map<String, dynamic>> achievements = [
      {'name': 'Ver 10 películas', 'progress': 7, 'target': 10},
      {'name': 'Escribir 3 comentarios', 'progress': 2, 'target': 3},
      {'name': 'Dar 10 likes', 'progress': 5, 'target': 10},
      {'name': 'Añadir 10 favoritos', 'progress': 8, 'target': 10},
    ];
    for (int i = 5; i <= 250; i++) {
      achievements.add({
        'name': 'Logro $i',
        'progress': Random().nextInt(10) + 1,
        'target': 10,
      });
    }
    return achievements;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Logros'),
        backgroundColor: const Color.fromARGB(255, 10, 10, 31),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        physics: const BouncingScrollPhysics(),
        itemCount: _achievements.length,
        itemBuilder: (context, index) {
          final achievement = _achievements[index];
          final isCompleted = completedAchievements.contains(achievement['name']);
          final progress = (achievement['progress'] / achievement['target']).clamp(0.0, 1.0);
          return Card(
            color: Colors.black87,
            margin: const EdgeInsets.symmetric(vertical: 8),
            child: ListTile(
              title: Text(
                achievement['name'],
                style: TextStyle(
                  color: isCompleted ? Colors.green : Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: progress,
                    backgroundColor: Colors.grey[700],
                    color: Colors.deepOrangeAccent,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${achievement['progress']}/${achievement['target']}',
                    style: const TextStyle(color: Colors.white70),
                  ),
                ],
              ),
              trailing: isCompleted
                  ? const Icon(Icons.check_circle, color: Colors.green)
                  : IconButton(
                icon: const Icon(Icons.star_border, color: Colors.white70),
                onPressed: () {
                  onAchievementCompleted(achievement['name']);
                },
              ),
            ),
          );
        },
      ),
    );
  }
}