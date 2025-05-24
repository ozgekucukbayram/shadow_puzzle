import 'package:shared_preferences/shared_preferences.dart';

class Achievement {
  final String key;
  final String title;
  final String description;
  bool unlocked;

  Achievement({
    required this.key,
    required this.title,
    required this.description,
    this.unlocked = false,
  });
}

class AchievementService {
  static final List<Achievement> achievements = [
    Achievement(
      key: 'first_match',
      title: 'First Match',
      description: 'Make your first match!',
    ),
    Achievement(
      key: 'no_mistake_level',
      title: 'Perfect Level',
      description: 'Complete a level without making any mistakes!',
    ),
    Achievement(
      key: 'all_levels',
      title: 'All Levels',
      description: 'Complete all 3 levels!',
    ),
    Achievement(
      key: 'ten_matches',
      title: '10 Matches',
      description: 'Make 10 correct matches!',
    ),
    Achievement(
      key: 'endless_100',
      title: 'Endless 100',
      description: 'Score 100 points in Endless mode!',
    ),
  ];

  static Future<void> loadAchievements() async {
    final prefs = await SharedPreferences.getInstance();
    for (var ach in achievements) {
      ach.unlocked = prefs.getBool('ach_${ach.key}') ?? false;
    }
  }

  static Future<void> unlock(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final ach = achievements.firstWhere((a) => a.key == key, orElse: () => throw Exception('Achievement not found'));
    ach.unlocked = true;
    await prefs.setBool('ach_$key', true);
  }

  static List<Achievement> getAll() {
    return achievements;
  }
} 