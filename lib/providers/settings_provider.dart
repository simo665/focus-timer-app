import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TimerSettings extends ChangeNotifier {
  static const String keyFocus = "focus_duration";
  static const String keyChill = "chill_duration";
  static const String keyMusic = "music_enabled";
  static const String keyVolume = "music_volume";

  // Focus (Work) Settings - Default 25 minutes
  int _focusDuration = 25 * 60;

  // Relax (Chill) Settings - Default 5 minutes
  int _chillDuration = 5 * 60;

  // Audio Settings
  bool _isBackgroundMusicEnabled = true;
  double _volume = 0.5;

  // Getters
  int get focusDuration => _focusDuration;
  int get chillDuration => _chillDuration;
  bool get isBackgroundMusicEnabled => _isBackgroundMusicEnabled;
  double get volume => _volume;

  TimerSettings() {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _focusDuration = prefs.getInt(keyFocus) ?? 25 * 60;
    _chillDuration = prefs.getInt(keyChill) ?? 5 * 60;
    _isBackgroundMusicEnabled = prefs.getBool(keyMusic) ?? true;
    _volume = prefs.getDouble(keyVolume) ?? 0.5;
    notifyListeners();
  }

  // Setters
  Future<void> setFocusDuration(int minutes) async {
    _focusDuration = minutes * 60;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(keyFocus, _focusDuration);
    notifyListeners();
  }

  Future<void> setChillDuration(int minutes) async {
    _chillDuration = minutes * 60;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(keyChill, _chillDuration);
    notifyListeners();
  }

  Future<void> toggleBackgroundMusic(bool isEnabled) async {
    _isBackgroundMusicEnabled = isEnabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(keyMusic, _isBackgroundMusicEnabled);
    notifyListeners();
  }

  Future<void> setVolume(double value) async {
    _volume = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(keyVolume, _volume);
    notifyListeners();
  }
}
