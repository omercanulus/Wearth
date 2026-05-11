import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;

/// Wearth kelime yönetim servisi.
/// Günün kelimesi ve klasik mod için kelime seçimi,
/// geçerlilik kontrolü ve dil desteği sağlar.
class WordService {
  // Singleton pattern
  static final WordService _instance = WordService._internal();
  factory WordService() => _instance;
  WordService._internal();

  /// Dile göre çözüm kelimeleri (günlük + seviye kelimeleri)
  final Map<String, List<String>> _solutionWords = {};
  
  final Map<String, List<String>> _easyWords = {};
  final Map<String, List<String>> _mediumWords = {};
  final Map<String, List<String>> _hardWords = {};

  /// Dile göre geçerli kelimeler (kullanıcı girişi doğrulama)
  final Map<String, Set<String>> _validWords = {};

  /// Kelimelerin yüklenip yüklenmediği
  bool _isLoaded = false;
  bool get isLoaded => _isLoaded;

  /// Yüklü olan diller
  final Set<String> _loadedLocales = {};

  // ─── Kelime Yükleme ────────────────────────────────────────────

  /// Belirtilen dil için kelime listesini assets'den yükler.
  /// Birden fazla dil yüklenebilir.
  Future<void> loadWords(String locale) async {
    if (_loadedLocales.contains(locale)) return;

    try {
      final jsonString = await rootBundle.loadString(
        'assets/words/${locale}_words.json',
      );
      final data = jsonDecode(jsonString) as Map<String, dynamic>;

      final easy = (data['solutions_easy'] as List<dynamic>?)?.cast<String>().map((w) => w.toUpperCase()).toList() ?? [];
      final medium = (data['solutions_medium'] as List<dynamic>?)?.cast<String>().map((w) => w.toUpperCase()).toList() ?? [];
      final hard = (data['solutions_hard'] as List<dynamic>?)?.cast<String>().map((w) => w.toUpperCase()).toList() ?? [];
      
      final allSols = data['solutions'] != null 
          ? (data['solutions'] as List<dynamic>).cast<String>().map((w) => w.toUpperCase()).toList()
          : [...easy, ...medium, ...hard];

      _easyWords[locale] = easy.isNotEmpty ? easy : allSols;
      _mediumWords[locale] = medium.isNotEmpty ? medium : allSols;
      _hardWords[locale] = hard.isNotEmpty ? hard : allSols;
      _solutionWords[locale] = allSols;

      // Geçerli kelimeler: çözüm kelimeleri + varsa ek valid listesi
      final validSet = <String>{...allSols};
      if (data['valid'] != null && (data['valid'] as List).isNotEmpty) {
        validSet.addAll(
          (data['valid'] as List<dynamic>)
              .cast<String>()
              .map((w) => w.toUpperCase()),
        );
      }
      _validWords[locale] = validSet;

      _loadedLocales.add(locale);
      _isLoaded = true;
    } catch (e) {
      throw WordServiceException(
        'Kelime listesi yüklenemedi ($locale): $e',
      );
    }
  }

  /// Hem Türkçe hem İngilizce kelimeleri yükler.
  Future<void> loadAllWords() async {
    await Future.wait([
      loadWords('tr'),
      loadWords('en'),
    ]);
  }

  // ─── Günün Kelimesi ────────────────────────────────────────────

  /// Belirtilen tarih için günün kelimesini döndürür.
  /// Deterministik: aynı tarih her zaman aynı kelimeyi verir.
  /// Tüm kullanıcılar aynı gün aynı kelimeyi görür.
  String getDailyWord({
    required String locale,
    DateTime? date,
  }) {
    _ensureLoaded(locale);

    final words = _solutionWords[locale]!;
    final targetDate = date ?? DateTime.now();

    // Epoch'tan bu yana geçen gün sayısını hesapla
    // Bu sayede her gün farklı ama deterministik bir kelime seçilir
    final epoch = DateTime(2026, 1, 1); // Wearth başlangıç tarihi
    final daysSinceEpoch = targetDate.difference(epoch).inDays;

    // Basit hash: gün sayısı + dil bazlı offset
    final localeOffset = locale == 'tr' ? 0 : 137; // Diller farklı kelime alsın
    final index = ((daysSinceEpoch + localeOffset) % words.length).abs();

    return words[index];
  }

  /// Bugünün kelime numarasını döndürür (Wordle #123 gibi gösterim için).
  int getDailyWordNumber({DateTime? date}) {
    final targetDate = date ?? DateTime.now();
    final epoch = DateTime(2026, 1, 1);
    return targetDate.difference(epoch).inDays.abs() + 1;
  }

  // ─── Klasik Mod (Seviye Sistemi) ───────────────────────────────

  /// Belirtilen seviye için kelimeyi döndürür.
  /// Seviyeler 1'den başlar, her seviyede farklı bir kelime.
  String getWordForLevel({
    required String locale,
    required int level,
  }) {
    _ensureLoaded(locale);

    List<String> words;
    // 1-100: Kolay, 101-250: Orta, 251-350: Zor
    if (level <= 100) {
      words = _easyWords[locale] ?? _solutionWords[locale]!;
    } else if (level <= 250) {
      words = _mediumWords[locale] ?? _solutionWords[locale]!;
    } else {
      words = _hardWords[locale] ?? _solutionWords[locale]!;
    }

    // Eğer kelime listesi bir şekilde boşsa fallback
    if (words.isEmpty) {
      return 'APPLE'; // Güvenli kelime
    }

    // Seviye numarasını karıştır ki sıralı olmasın
    // Basit ama etkili bir shuffle: seviye * asal sayı mod toplam kelime
    final shuffledIndex = ((level * 31 + 17) % words.length).abs();

    return words[shuffledIndex];
  }

  // ─── Kelime Doğrulama ──────────────────────────────────────────

  /// Girilen kelimenin geçerli bir kelime olup olmadığını kontrol eder.
  bool isValidWord(String word, String locale) {
    _ensureLoaded(locale);
    // Genişletilmiş veritabanı sayesinde artık kelimeyi gerçek sözlükte arıyoruz
    return _validWords[locale]!.contains(word.toUpperCase());
  }

  /// Kelime uzunluğunun doğru olup olmadığını kontrol eder.
  bool isCorrectLength(String word, {int expectedLength = 5}) {
    return word.length == expectedLength;
  }

  // ─── Harf Karşılaştırma ────────────────────────────────────────

  /// Tahmin edilen kelimeyi hedef kelimeyle karşılaştırır.
  /// Her harf için [LetterResult] döndürür:
  /// - correct: Doğru harf, doğru konum (yeşil)
  /// - present: Doğru harf, yanlış konum (sarı)
  /// - absent:  Yanlış harf (gri)
  List<LetterResult> evaluateGuess({
    required String guess,
    required String target,
  }) {
    final guessChars = guess.toUpperCase().split('');
    final targetChars = target.toUpperCase().split('');
    final results = List.filled(guessChars.length, LetterResult.absent);

    // Hedef kelimedeki harf kullanım sayacı
    final remainingTarget = <String, int>{};
    for (final char in targetChars) {
      remainingTarget[char] = (remainingTarget[char] ?? 0) + 1;
    }

    // İlk geçiş: Doğru konumdaki harfleri işaretle (yeşil)
    for (int i = 0; i < guessChars.length; i++) {
      if (guessChars[i] == targetChars[i]) {
        results[i] = LetterResult.correct;
        remainingTarget[guessChars[i]] =
            remainingTarget[guessChars[i]]! - 1;
      }
    }

    // İkinci geçiş: Yanlış konumdaki harfleri işaretle (sarı)
    for (int i = 0; i < guessChars.length; i++) {
      if (results[i] != LetterResult.correct) {
        final char = guessChars[i];
        if (remainingTarget.containsKey(char) &&
            remainingTarget[char]! > 0) {
          results[i] = LetterResult.present;
          remainingTarget[char] = remainingTarget[char]! - 1;
        }
      }
    }

    return results;
  }

  // ─── Yardımcı Metodlar ─────────────────────────────────────────

  /// Belirtilen dil için toplam kelime sayısını döndürür.
  int getWordCount(String locale) {
    if (!_loadedLocales.contains(locale)) return 0;
    return _solutionWords[locale]?.length ?? 0;
  }

  /// Yüklü dilleri döndürür.
  Set<String> get loadedLocales => Set.unmodifiable(_loadedLocales);

  /// Yüklenen dil için kelimelerin hazır olduğunu doğrular.
  void _ensureLoaded(String locale) {
    if (!_loadedLocales.contains(locale)) {
      throw WordServiceException(
        'Kelimeler henüz yüklenmedi ($locale). '
        'Önce loadWords("$locale") çağrılmalı.',
      );
    }
  }
}

// ─── Veri Modelleri ────────────────────────────────────────────────

/// Harf değerlendirme sonucu
enum LetterResult {
  /// Doğru harf, doğru konum (yeşil)
  correct,

  /// Doğru harf, yanlış konum (sarı)
  present,

  /// Yanlış harf (gri)
  absent,
}

/// WordService hata sınıfı
class WordServiceException implements Exception {
  final String message;
  const WordServiceException(this.message);

  @override
  String toString() => 'WordServiceException: $message';
}
