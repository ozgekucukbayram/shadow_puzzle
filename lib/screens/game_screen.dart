import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/game_item.dart';
import '../services/level_generator.dart';
import '../models/settings.dart';
import '../models/achievement.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({
    super.key, 
    required this.selectedCategories, 
    this.isEndlessMode = false,
  });

  final List<String> selectedCategories;
  final bool isEndlessMode;

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  int score = 0;
  int timeLeft = 60;
  int level = 1;
  int selectedObjIndex = 0;
  bool levelCompleted = false;
  late Timer timer;
  int objectCount = 5;
  final double tolerance = 25;
  int totalMatches = 0;
  int highScore = 0;
  bool mistakeMade = false;
  String? lastAchievement;
  bool showAchievement = false;

  List<Offset> objectPositions = [];
  List<Offset> shadowPositions = [];
  List<bool> matched = [];
  List<double> rotationAngles = [];
  List<double> shadowRotations = [];
  List<GameItem> selectedItems = [];

  bool _showAnimation = true;
  bool _showGameOverAnimation = false;

  final AudioPlayer backgroundMusicPlayer = AudioPlayer();
  final AudioPlayer effectPlayer = AudioPlayer();

  @override
  void initState() {
    super.initState();
    // Endless mode settings
    if (widget.isEndlessMode) {
      timeLeft = 120; // 2 minutes for endless mode
      objectCount = 5; // Start with 5 objects in endless mode
      _loadHighScore();
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      initializeGame();
      startTimer();
    });
    _initializeAudio();
    _startLevelAnimation();
    _loadAchievements();
  }

  Future<void> _loadAchievements() async {
    await AchievementService.loadAchievements();
  }

  Future<void> _loadHighScore() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      highScore = prefs.getInt('endless_high_score') ?? 0;
    });
  }

  Future<void> _saveHighScore() async {
    final prefs = await SharedPreferences.getInstance();
    if (score > highScore) {
      await prefs.setInt('endless_high_score', score);
    }
  }

  Future<void> _checkAndUnlockAchievement(String key) async {
    final achievements = AchievementService.getAll();
    final achievement = achievements.firstWhere((a) => a.key == key);
    if (!achievement.unlocked) {
      await AchievementService.unlock(key);
      setState(() {
        lastAchievement = achievement.title;
        showAchievement = true;
      });
      Future.delayed(Duration(seconds: 3), () {
        setState(() {
          showAchievement = false;
        });
      });
    }
  }

  Future<void> _initializeAudio() async {
    bool musicEnabled = await Settings.getMusicEnabled();
    bool soundEnabled = await Settings.getSoundEnabled();

    if (musicEnabled) {
      await backgroundMusicPlayer.setReleaseMode(ReleaseMode.loop);
      await backgroundMusicPlayer.play(AssetSource('sounds/arka_plan_muzik.mp3'));
    }
  }

  Future<void> playEffect(String effectName) async {
    bool soundEnabled = await Settings.getSoundEnabled();
    if (soundEnabled) {
      await effectPlayer.play(AssetSource('sounds/$effectName'));
    }
  }

  void _startLevelAnimation() {
    setState(() => _showAnimation = true);
    Future.delayed(const Duration(seconds: 2), () {
      setState(() => _showAnimation = false);
    });
  }

  void _startGameOverAnimation() {
    setState(() => _showGameOverAnimation = true);
    Future.delayed(const Duration(seconds: 2), () {
      setState(() => _showGameOverAnimation = false);
      showEndDialog(false);
    });
  }

  void pickRandomItems() {
    final List<GameItem> allSelected = [];
    final random = Random();

    for (var category in widget.selectedCategories) {
      if (emojiData.containsKey(category)) {
        allSelected.addAll(emojiData[category]!);
      }
    }

    allSelected.shuffle(random);
    selectedItems = allSelected.take(objectCount).toList();
  }

  void initializeGame() {
    pickRandomItems();

    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;

    int count = selectedItems.length;
    double spacing = screenWidth / (count + 1);

    objectPositions = List.generate(
      count,
      (i) => Offset(spacing * (i + 1) - 40, 100),
    );

    rotationAngles = List.filled(count, 0);
    matched = List.filled(count, false);
    mistakeMade = false;

    final random = Random();
    shadowRotations = [];
    shadowPositions = [];

    List<Offset> possiblePositions = [];
    double gridWidth = screenWidth / 4;
    double gridHeight = (screenHeight - 250) / 3;

    for (int row = 0; row < 3; row++) {
      for (int col = 0; col < 4; col++) {
        double dx = 40 + col * gridWidth;
        double dy = 250 + row * gridHeight;
        possiblePositions.add(Offset(dx, dy));
      }
    }

    possiblePositions.shuffle(random);

    for (int i = 0; i < count; i++) {
      shadowRotations.add((random.nextInt(7) + 1) * 0.2);
      shadowPositions.add(possiblePositions[i]);
    }
  }

  void restartCurrentLevel() {
    timer.cancel();
    setState(() {
      score = 0;
      selectedObjIndex = 0;
      levelCompleted = false;
    });
    initializeGame();
    startTimer();
    _startLevelAnimation();
  }

  void startTimer() {
    timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        timeLeft--;
        if (timeLeft <= 0) {
          timer.cancel();
          
          if (widget.isEndlessMode) {
            _saveHighScore();
            _checkForEndlessAchievements();
          }
          
          _startGameOverAnimation();
        }
      });
    });
  }

  void _checkForEndlessAchievements() {
    if (score >= 100) {
      _checkAndUnlockAchievement('endless_100');
    }
  }

  void goToNextLevel() {
    timer.cancel();
    setState(() {
      level++;
      score = 0;
      selectedObjIndex = 0;
      levelCompleted = false;
      objectCount = level == 1 ? 5 : level == 2 ? 8 : 10;
      timeLeft = level == 1 ? 60 : level == 2 ? 90 : 120;
    });
    initializeGame();
    startTimer();
    _startLevelAnimation();
  }

  void showEndDialog(bool isSuccess) {
    if (widget.isEndlessMode) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => AlertDialog(
          title: const Text("Time's Up!"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("Total Score: $score"),
              Text("High Score: $highScore"),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                restartCurrentLevel();
              },
              child: const Text("Try Again"),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context);
              },
              child: const Text("Main Menu"),
            ),
          ],
        ),
      );
    } else {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => AlertDialog(
          title: Text(isSuccess ? (level == 3 ? "Game Completed!" : "Level Completed!") : "Time's Up!"),
          content: Text(isSuccess
              ? (level == 3
                  ? "Congratulations! You've completed all levels."
                  : "Great job! All objects matched.")
              : "You ran out of time."),
          actions: [
            if (!isSuccess)
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  restartCurrentLevel();
                },
                child: const Text("Try Again"),
              ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context);
              },
              child: const Text("Main Menu"),
            ),
          ],
        ),
      );
    }
  }

  double smallestAngleDifference(double angle1, double angle2) {
    double diff = (angle1 - angle2) % (2 * pi);
    if (diff > pi) diff -= 2 * pi;
    if (diff < -pi) diff += 2 * pi;
    return diff.abs();
  }

  void checkMatch(int index) async {
    Offset pos = objectPositions[index];
    double angle = rotationAngles[index];
    Offset target = shadowPositions[index];
    double targetAngle = shadowRotations[index];

    if ((pos - target).distance > tolerance || 
        smallestAngleDifference(angle, targetAngle) >= 0.5) {
      // A mistake was made if trying to place object far from target
      if ((pos - target).distance < 100) {
        mistakeMade = true;
      }
    }

    if (!matched[index] &&
        (pos - target).distance < tolerance &&
        smallestAngleDifference(angle, targetAngle) < 0.5) {
      setState(() {
        matched[index] = true;
        score++;
        totalMatches++;
      });
      await playEffect('click.mp3');

      // First match achievement
      if (totalMatches == 1) {
        _checkAndUnlockAchievement('first_match');
      }

      // Ten matches achievement
      if (totalMatches == 10) {
        _checkAndUnlockAchievement('ten_matches');
      }

      // Check if all objects are matched
      if (matched.every((e) => e)) {
        timer.cancel();
        
        // For endless mode, generate new objects
        if (widget.isEndlessMode) {
          // Add bonus time for completing a set
          setState(() {
            timeLeft += 15; // Add 15 seconds as bonus
            levelCompleted = false; // Keep playing
          });
          initializeGame(); // Generate new objects
          startTimer(); // Continue timer
        } else {
          setState(() => levelCompleted = true);
          await playEffect('win.mp3');

          // Check for perfect level achievement
          if (!mistakeMade) {
            _checkAndUnlockAchievement('no_mistake_level');
          }

          // Check for all levels completed achievement
          if (level == 3) {
            _checkAndUnlockAchievement('all_levels');
            showEndDialog(true);
          }
        }
      }
    }
  }

  Widget buildObject(int index) {
    return Positioned(
      left: objectPositions[index].dx,
      top: objectPositions[index].dy,
      child: Visibility(
        visible: !matched[index],
        child: GestureDetector(
          onTap: () => setState(() => selectedObjIndex = index),
          onPanUpdate: (details) {
            if (matched[index]) return;
            setState(() {
              objectPositions[index] += details.delta;
              checkMatch(index);
            });
          },
          onDoubleTap: () {
            if (matched[index]) return;
            setState(() {
              rotationAngles[index] += 0.4;
              checkMatch(index);
            });
          },
          child: Transform.rotate(
            angle: rotationAngles[index],
            child: Image.asset(
              selectedItems[index].imagePath,
              width: 80,
              height: 80,
            ),
          ),
        ),
      ),
    );
  }

  Widget buildShadow(int index) {
    return Positioned(
      left: shadowPositions[index].dx,
      top: shadowPositions[index].dy,
      child: Visibility(
        visible: !matched[index],
        child: Transform.rotate(
          angle: shadowRotations[index],
          child: Image.asset(
            selectedItems[index].shadowPath,
            width: 80,
            height: 80,
          ),
        ),
      ),
    );
  }

  Widget buildHeader() {
    if (widget.isEndlessMode) {
      return Positioned(
        top: 40,
        left: 20,
        right: 20,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.6),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            children: [
              Text(
                "Endless Mode",
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.deepOrange),
              ),
              const SizedBox(height: 4),
              Text(
                "Score: $score | High Score: $highScore | Time: $timeLeft",
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
              ),
            ],
          ),
        ),
      );
    } else {
      return Positioned(
        top: 40,
        left: 20,
        right: 20,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.6),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            "Level $level | Score: $score | Time: $timeLeft",
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
          ),
        ),
      );
    }
  }

  @override
  void dispose() {
    timer.cancel();
    backgroundMusicPlayer.dispose();
    effectPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFFFB347), Color(0xFFFFE873), Color(0xFF6EC6FF)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Stack(
          children: [
            const BubblesBackground(),
            buildHeader(),
            ...List.generate(selectedItems.length, (index) => buildShadow(index)),
            ...List.generate(selectedItems.length, (index) => buildObject(index)),
            if (levelCompleted && level < 3 && !widget.isEndlessMode)
              Center(
                child: ElevatedButton(
                  onPressed: goToNextLevel,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.deepOrangeAccent),
                  child: const Text("Next Level"),
                ),
              ),
            if (_showAnimation)
              Container(
                color: Colors.black38,
                child: Center(
                  child: Lottie.asset('assets/animations/level_start.json', width: 200, height: 200),
                ),
              ),
            if (_showGameOverAnimation)
              Container(
                color: Colors.black38,
                child: Center(
                  child: Lottie.asset('assets/animations/game_over.json', width: 200, height: 200),
                ),
              ),
            if (showAchievement)
              Positioned(
                top: 100,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.amber.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.emoji_events, color: Colors.white, size: 30),
                        const SizedBox(width: 8),
                        Text(
                          "Achievement Unlocked: $lastAchievement",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class BubblesBackground extends StatefulWidget {
  const BubblesBackground({super.key});

  @override
  State<BubblesBackground> createState() => _BubblesBackgroundState();
}

class _BubblesBackgroundState extends State<BubblesBackground> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<_Bubble> bubbles = List.generate(
    20,
    (index) => _Bubble(
      position: Offset(Random().nextDouble(), Random().nextDouble()),
      size: Random().nextDouble() * 60 + 20,
      speed: Random().nextDouble() * 0.0005 + 0.0002,
    ),
  );

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: const Duration(seconds: 100), vsync: this)..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          painter: _BubblePainter(bubbles, _controller.value),
          size: Size.infinite,
        );
      },
    );
  }
}

class _Bubble {
  Offset position;
  double size;
  double speed;

  _Bubble({required this.position, required this.size, required this.speed});
}

class _BubblePainter extends CustomPainter {
  final List<_Bubble> bubbles;
  final double animationValue;

  _BubblePainter(this.bubbles, this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()..style = PaintingStyle.stroke;

    for (final bubble in bubbles) {
      final dy = bubble.position.dy - bubble.speed * animationValue * 10000;
      final newPosition = Offset(bubble.position.dx * size.width, (dy % 1.2) * size.height);

      paint.color = Colors.white.withOpacity(0.2 + Random().nextDouble() * 0.3);
      paint.strokeWidth = 2;
      canvas.drawCircle(newPosition, bubble.size / 2, paint);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}
