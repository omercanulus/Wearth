import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LifeService extends ChangeNotifier {
  static final LifeService _instance = LifeService._internal();
  factory LifeService() => _instance;
  LifeService._internal();

  static const int maxLives = 5;
  static const int regenTimeMinutes = 30;

  int _lives = maxLives;
  DateTime? _lastRegenTime;
  Timer? _timer;

  int get lives => _lives;

  /// Returns remaining duration for the next life
  Duration get timeUntilNextLife {
    if (_lives >= maxLives || _lastRegenTime == null) return Duration.zero;
    final now = DateTime.now();
    final nextLifeTime = _lastRegenTime!.add(const Duration(minutes: regenTimeMinutes));
    final diff = nextLifeTime.difference(now);
    return diff.isNegative ? Duration.zero : diff;
  }

  /// Returns formatted "MM:SS"
  String get formattedTimeUntilNext {
    final dur = timeUntilNextLife;
    if (dur.inSeconds <= 0) return "Dolu";
    final m = dur.inMinutes.toString().padLeft(2, '0');
    final s = (dur.inSeconds % 60).toString().padLeft(2, '0');
    return "$m:$s";
  }

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _lives = prefs.getInt('lives') ?? maxLives;
    final timeStr = prefs.getString('last_regen_time');
    
    if (timeStr != null) {
      _lastRegenTime = DateTime.parse(timeStr);
    }
    
    _calculateRegen();

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_lives < maxLives) {
        _calculateRegen();
        notifyListeners();
      }
    });
  }

  void _calculateRegen() {
    if (_lastRegenTime == null || _lives >= maxLives) return;
    
    final now = DateTime.now();
    final diff = now.difference(_lastRegenTime!);
    final earnedLives = diff.inMinutes ~/ regenTimeMinutes;

    if (earnedLives > 0) {
      _lives += earnedLives;
      if (_lives >= maxLives) {
        _lives = maxLives;
        _lastRegenTime = null;
      } else {
        // İleri sarıyoruz
        _lastRegenTime = _lastRegenTime!.add(Duration(minutes: earnedLives * regenTimeMinutes));
      }
      _save();
    } else if (diff.isNegative) {
       // Cihaz saati geri alınmışsa hile koruması
       _lastRegenTime = now;
       _save();
    }
  }

  Future<bool> consumeLife() async {
    if (_lives > 0) {
      if (_lives == maxLives) {
        _lastRegenTime = DateTime.now();
      }
      _lives--;
      await _save();
      notifyListeners();
      return true;
    }
    return false;
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('lives', _lives);
    if (_lastRegenTime != null) {
      await prefs.setString('last_regen_time', _lastRegenTime!.toIso8601String());
    } else {
      await prefs.remove('last_regen_time');
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
