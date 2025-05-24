import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Settings {
  static const String _musicKey = 'music_enabled';
  static const String _soundKey = 'sound_enabled';
  static const String _selectedBackgroundKey = 'selected_background';

  static Future<bool> getMusicEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_musicKey) ?? true;
  }

  static Future<bool> getSoundEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_soundKey) ?? true;
  }

  static Future<String> getSelectedBackground() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_selectedBackgroundKey) ?? 'default';
  }

  static Future<void> setMusicEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_musicKey, value);
  }

  static Future<void> setSoundEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_soundKey, value);
  }

  static Future<void> setSelectedBackground(String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_selectedBackgroundKey, value);
  }
} 