import 'package:flutter/material.dart';
import 'dart:math';
import '../models/settings.dart';
import '../models/achievement.dart';
import 'achievements_screen.dart';
import 'game_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  final List<String> categories = ['animal', 'food', 'nature'];
  final List<String> selectedCategories = [];
  bool musicEnabled = true;
  bool soundEnabled = true;
  String selectedBackground = 'default';

  final List<Map<String, List<Color>>> availableBackgrounds = [
    {
      'default': [Color(0xFFFFA726), Color(0xFFFFEE58), Color(0xFF42A5F5)],
    },
    {
      'sunset': [Color(0xFFFF7043), Color(0xFFFFAB91), Color(0xFFFFCC80)],
    },
    {
      'ocean': [Color(0xFF4FC3F7), Color(0xFF81D4FA), Color(0xFFB3E5FC)],
    },
    {
      'forest': [Color(0xFF66BB6A), Color(0xFF81C784), Color(0xFFA5D6A7)],
    },
    {
      'lavender': [Color(0xFF9575CD), Color(0xFFB39DDB), Color(0xFFD1C4E9)],
    },
    {
      'cherry': [Color(0xFFEC407A), Color(0xFFF48FB1), Color(0xFFF8BBD0)],
    },
    {
      'midnight': [Color(0xFF5C6BC0), Color(0xFF7986CB), Color(0xFF9FA8DA)],
    },
    {
      'autumn': [Color(0xFFFFA726), Color(0xFFFFB74D), Color(0xFFFFCC80)],
    },
  ];

  late AnimationController _bubbleController;
  final List<Bubble> bubbles = [];

  @override
  void initState() {
    super.initState();
    _bubbleController = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    )..repeat();
    generateBubbles();
    _loadSettings();
    _loadAchievements();
  }
  
  Future<void> _loadAchievements() async {
    await AchievementService.loadAchievements();
  }

  Future<void> _loadSettings() async {
    musicEnabled = await Settings.getMusicEnabled();
    soundEnabled = await Settings.getSoundEnabled();
    selectedBackground = await Settings.getSelectedBackground();
    setState(() {});
  }

  void generateBubbles() {
    final random = Random();
    for (int i = 0; i < 20; i++) {
      bubbles.add(
        Bubble(
          x: random.nextDouble(),
          y: random.nextDouble(),
          radius: random.nextDouble() * 30 + 10,
          color: Colors.primaries[random.nextInt(Colors.primaries.length)].withOpacity(0.3),
        ),
      );
    }
  }

  void _startNormalGame() {
    if (selectedCategories.isNotEmpty) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => GameScreen(
            selectedCategories: selectedCategories,
            isEndlessMode: false,
          ),
        ),
      );
    }
  }

  void _startEndlessMode() {
    if (selectedCategories.isNotEmpty) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => GameScreen(
            selectedCategories: selectedCategories,
            isEndlessMode: true,
          ),
        ),
      );
    }
  }

  void _showAchievements() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AchievementsScreen(),
      ),
    );
  }

  void _showSettings() {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Settings'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SwitchListTile(
                title: const Text('Music'),
                value: musicEnabled,
                onChanged: (value) {
                  setState(() => musicEnabled = value);
                  Settings.setMusicEnabled(value);
                },
              ),
              SwitchListTile(
                title: const Text('Sound Effects'),
                value: soundEnabled,
                onChanged: (value) {
                  setState(() => soundEnabled = value);
                  Settings.setSoundEnabled(value);
                },
              ),
              const SizedBox(height: 10),
              const Text('Background Theme'),
              DropdownButton<String>(
                value: selectedBackground,
                items: availableBackgrounds.map((bg) {
                  String key = bg.keys.first;
                  return DropdownMenuItem(
                    value: key,
                    child: Text(key),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => selectedBackground = value);
                    Settings.setSelectedBackground(value);
                    this.setState(() {});
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        ),
      ),
    );
  }

  void _showCredits() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Credits'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                'Development Team:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              SizedBox(height: 10),
              Text('Bora'),
              Text('Melis'),
              Text('Umut Berke'),
              Text('Burak'),
              Text('Özge'),
              SizedBox(height: 20),
              Text(
                'Resources:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              SizedBox(height: 10),
              Text('Emojis: emojiisland.com'),
              Text('Animations: Lottie'),
              Text('Sound Effects: Custom'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showHowToPlay() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('How to Play'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                'Game Rules:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              SizedBox(height: 10),
              Text('1. Match the objects with their shadows'),
              Text('2. Drag objects to move them'),
              Text('3. Double tap to rotate objects'),
              Text('4. Complete all matches before time runs out'),
              SizedBox(height: 10),
              Text(
                'Levels:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              SizedBox(height: 10),
              Text('Level 1: 5 objects, 60 seconds'),
              Text('Level 2: 8 objects, 90 seconds'),
              Text('Level 3: 10 objects, 120 seconds'),
              SizedBox(height: 10),
              Text(
                'Endless Mode:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              SizedBox(height: 10),
              Text('- Keep matching objects until time runs out'),
              Text('- Each completed set gives 15 extra seconds'),
              Text('- Try to achieve the highest score!'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it!'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _bubbleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final selectedBgColors = availableBackgrounds
        .firstWhere((bg) => bg.keys.first == selectedBackground)
        .values
        .first;

    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: selectedBgColors,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          AnimatedBuilder(
            animation: _bubbleController,
            builder: (context, child) {
              return CustomPaint(
                painter: BubblePainter(bubbles, _bubbleController.value),
                child: Container(),
              );
            },
          ),
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 30),
                const Text(
                  'Shadow Puzzle',
                  style: TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    shadows: [
                      Shadow(
                        blurRadius: 10,
                        color: Colors.black45,
                        offset: Offset(2, 2),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),
                const Text(
                  'Choose your categories',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 20),
                ...categories.map((category) => Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 8),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.8),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: CheckboxListTile(
                          title: Text(
                            category,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                              color: Colors.black87,
                            ),
                          ),
                          value: selectedCategories.contains(category),
                          onChanged: (bool? value) {
                            setState(() {
                              if (value == true) {
                                selectedCategories.add(category);
                              } else {
                                selectedCategories.remove(category);
                              }
                            });
                          },
                          activeColor: Colors.deepOrangeAccent,
                          checkboxShape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                      ),
                    )),
                const Spacer(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      onPressed: _showSettings,
                      icon: const Icon(Icons.settings, color: Colors.white, size: 30),
                    ),
                    IconButton(
                      onPressed: _showAchievements,
                      icon: const Icon(Icons.emoji_events, color: Colors.white, size: 30),
                    ),
                    IconButton(
                      onPressed: _showHowToPlay,
                      icon: const Icon(Icons.help_outline, color: Colors.white, size: 30),
                    ),
                    IconButton(
                      onPressed: _showCredits,
                      icon: const Icon(Icons.info_outline, color: Colors.white, size: 30),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton(
                      onPressed: selectedCategories.isEmpty ? null : _startNormalGame,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepOrangeAccent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                      ),
                      child: const Text(
                        'Normal Mode',
                        style: TextStyle(fontSize: 16, color: Colors.white),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: selectedCategories.isEmpty ? null : _startEndlessMode,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepPurple,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                      ),
                      child: const Text(
                        'Endless Mode',
                        style: TextStyle(fontSize: 16, color: Colors.white),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Baloncuk Modeli
class Bubble {
  double x;
  double y;
  double radius;
  Color color;

  Bubble({required this.x, required this.y, required this.radius, required this.color});
}

// Baloncuk Çizen Painter
class BubblePainter extends CustomPainter {
  final List<Bubble> bubbles;
  final double animationValue;

  BubblePainter(this.bubbles, this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    for (var bubble in bubbles) {
      final double dx = bubble.x * size.width;
      final double dy = (bubble.y + animationValue) % 1.0 * size.height;
      paint.color = bubble.color;
      canvas.drawCircle(Offset(dx, dy), bubble.radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

