import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsService extends ChangeNotifier {
  double _temperature = 0.7;
  int _maxTokens = 2048;

  double get temperature => _temperature;
  int get maxTokens => _maxTokens;

  SettingsService() {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _temperature = prefs.getDouble('temperature') ?? 0.7;
    _maxTokens = prefs.getInt('max_tokens') ?? 2048;
    notifyListeners();
  }

  Future<void> setTemperature(double value) async {
    _temperature = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('temperature', value);
    notifyListeners();
  }

  Future<void> setMaxTokens(int value) async {
    _maxTokens = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('max_tokens', value);
    notifyListeners();
  }
}
