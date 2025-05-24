import 'package:flutter/material.dart';
import 'package:shadow_puzzle/screens/splash_screen.dart';
import 'package:shadow_puzzle/screens/home_screen.dart';

void main() {
  runApp(const ShadowPuzzleApp());
}

class ShadowPuzzleApp extends StatelessWidget {
  const ShadowPuzzleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SHADOW PUZZLE',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(),
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/home': (context) => const HomeScreen(),
      },
    );
  }
}
