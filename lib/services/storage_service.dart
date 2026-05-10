import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Yerel depolama servisi.
/// Günlük ilerleme, istatistikler ve ayarları yönetir.
class StorageService {
  // Singleton pattern
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  SharedPreferences? _prefs;

  /// SharedPreferences'ı başlatır.
  Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  // ─── Tema ───────────────────────────────────────────────────────

  Future<void> saveThemeMode(String mode) async {
    await init();
    await _prefs!.setString('theme_mode', mode);
  }

  Future<String?> loadThemeMode() async {
    await init();
    return _prefs!.getString('theme_mode');
  }

  // ─── Günlük İlerleme ──────────────────────────────────────────

  /// Bugünün oyun durumunu kaydeder.
  Future<void> saveDailyProgress({
    required String locale,
    required String date, // "2026-05-10" formatında
    required List<String> guesses,
    required bool solved,
  }) async {
    await init();
    final key = 'daily_${locale}_$date';
    final data = jsonEncode({
      'guesses': guesses,
      'solved': solved,
      'timestamp': DateTime.now().toIso8601String(),
    });
    await _prefs!.setString(key, data);
  }

  /// Bugünün oyun durumunu yükler. Oynanmamışsa null döner.
  Future<Map<String, dynamic>?> loadDailyProgress({
    required String locale,
    required String date,
  }) async {
    await init();
    final key = 'daily_${locale}_$date';
    final data = _prefs!.getString(key);
    if (data == null) return null;
    return jsonDecode(data) as Map<String, dynamic>;
  }

  /// Bugün oynanmış mı kontrol eder.
  Future<bool> hasPlayedToday({
    required String locale,
    required String date,
  }) async {
    final progress = await loadDailyProgress(
      locale: locale,
      date: date,
    );
    return progress != null;
  }

  // ─── İstatistikler ────────────────────────────────────────────

  /// İstatistikleri kaydeder.
  Future<void> saveStats({
    required String locale,
    required GameStats stats,
  }) async {
    await init();
    final key = 'stats_$locale';
    await _prefs!.setString(key, jsonEncode(stats.toJson()));
  }

  /// İstatistikleri yükler.
  Future<GameStats> loadStats({required String locale}) async {
    await init();
    final key = 'stats_$locale';
    final data = _prefs!.getString(key);
    if (data == null) return GameStats.empty();
    return GameStats.fromJson(jsonDecode(data) as Map<String, dynamic>);
  }

  // ─── Klasik Mod Seviye ────────────────────────────────────────

  /// Klasik modda mevcut seviyeyi kaydeder.
  Future<void> saveClassicLevel({
    required String locale,
    required int level,
  }) async {
    await init();
    await _prefs!.setInt('classic_level_$locale', level);
  }

  /// Klasik modda mevcut seviyeyi yükler.
  Future<int> loadClassicLevel({required String locale}) async {
    await init();
    return _prefs!.getInt('classic_level_$locale') ?? 1;
  }

  /// Seviye yıldız puanını kaydeder (1-3).
  Future<void> saveLevelStars({
    required String locale,
    required int level,
    required int stars,
  }) async {
    await init();
    final key = 'classic_stars_${locale}_$level';
    // Sadece daha yüksek puan varsa güncelle
    final current = _prefs!.getInt(key) ?? 0;
    if (stars > current) {
      await _prefs!.setInt(key, stars);
    }
  }

  /// Seviye yıldız puanını yükler.
  Future<int> loadLevelStars({
    required String locale,
    required int level,
  }) async {
    await init();
    return _prefs!.getInt('classic_stars_${locale}_$level') ?? 0;
  }
}

// ─── İstatistik Modeli ──────────────────────────────────────────

/// Oyuncu istatistikleri
class GameStats {
  int gamesPlayed;
  int gamesWon;
  int currentStreak;
  int maxStreak;

  /// Deneme sayısına göre dağılım [1, 2, 3, 4, 5, 6]
  List<int> guessDistribution;

  GameStats({
    required this.gamesPlayed,
    required this.gamesWon,
    required this.currentStreak,
    required this.maxStreak,
    required this.guessDistribution,
  });

  factory GameStats.empty() => GameStats(
        gamesPlayed: 0,
        gamesWon: 0,
        currentStreak: 0,
        maxStreak: 0,
        guessDistribution: List.filled(6, 0),
      );

  /// Kazanma yüzdesi
  double get winPercentage =>
      gamesPlayed > 0 ? (gamesWon / gamesPlayed) * 100 : 0;

  /// Yeni bir oyun sonucunu ekler.
  void addResult({required bool won, int? attempts}) {
    gamesPlayed++;
    if (won && attempts != null) {
      gamesWon++;
      currentStreak++;
      if (currentStreak > maxStreak) maxStreak = currentStreak;
      if (attempts >= 1 && attempts <= 6) {
        guessDistribution[attempts - 1]++;
      }
    } else {
      currentStreak = 0;
    }
  }

  Map<String, dynamic> toJson() => {
        'gamesPlayed': gamesPlayed,
        'gamesWon': gamesWon,
        'currentStreak': currentStreak,
        'maxStreak': maxStreak,
        'guessDistribution': guessDistribution,
      };

  factory GameStats.fromJson(Map<String, dynamic> json) => GameStats(
        gamesPlayed: json['gamesPlayed'] as int? ?? 0,
        gamesWon: json['gamesWon'] as int? ?? 0,
        currentStreak: json['currentStreak'] as int? ?? 0,
        maxStreak: json['maxStreak'] as int? ?? 0,
        guessDistribution: (json['guessDistribution'] as List<dynamic>?)
                ?.cast<int>()
                .toList() ??
            List.filled(6, 0),
      );
}
