import '../services/word_service.dart';

/// Wordle oyun durumu modeli.
/// Bir oyun oturumunun tüm verilerini tutar.
class GameState {
  /// Oyun modu
  final GameMode mode;

  /// Hedef kelime (doğru cevap)
  final String targetWord;

  /// Dil kodu
  final String locale;

  /// Maksimum tahmin hakkı
  final int maxAttempts;

  /// Yapılan tahminler ve sonuçları
  final List<GuessEntry> guesses;

  /// Oyun durumu
  GameStatus status;

  /// Günün kelimesi numarası (sadece daily mod için)
  final int? dailyNumber;

  GameState({
    required this.mode,
    required this.targetWord,
    required this.locale,
    this.maxAttempts = 6,
    this.dailyNumber,
  })  : guesses = [],
        status = GameStatus.playing;

  /// Mevcut deneme sayısı
  int get currentAttempt => guesses.length;

  /// Kalan deneme hakkı
  int get remainingAttempts => maxAttempts - currentAttempt;

  /// Oyun bitti mi?
  bool get isGameOver =>
      status == GameStatus.won || status == GameStatus.lost;

  /// Yeni bir tahmin ekler ve sonuçları değerlendirir.
  /// Oyun bitmişse false döndürür.
  bool addGuess(String word, List<LetterResult> results) {
    if (isGameOver) return false;

    guesses.add(GuessEntry(word: word, results: results));

    // Tüm harfler doğru mu?
    if (results.every((r) => r == LetterResult.correct)) {
      status = GameStatus.won;
    } else if (currentAttempt >= maxAttempts) {
      status = GameStatus.lost;
    }

    return true;
  }

  /// Klavye harf durumlarını hesaplar.
  /// Her harf için en iyi sonucu döndürür
  /// (correct > present > absent).
  Map<String, LetterResult> get keyboardStates {
    final states = <String, LetterResult>{};

    for (final guess in guesses) {
      for (int i = 0; i < guess.word.length; i++) {
        final char = guess.word[i];
        final result = guess.results[i];
        final current = states[char];

        // Öncelik: correct > present > absent
        if (current == null ||
            result == LetterResult.correct ||
            (result == LetterResult.present &&
                current == LetterResult.absent)) {
          states[char] = result;
        }
      }
    }

    return states;
  }
}

/// Tek bir tahmin girişi
class GuessEntry {
  final String word;
  final List<LetterResult> results;

  const GuessEntry({
    required this.word,
    required this.results,
  });
}

/// Oyun durumu
enum GameStatus {
  /// Oyun devam ediyor
  playing,

  /// Oyuncu kelimeyi buldu
  won,

  /// Tahmin hakkı bitti
  lost,
}

/// Oyun modları
enum GameMode {
  /// Günün kelimesi — günde 1 kelime, herkes aynı
  daily,

  /// Klasik mod — seviye bazlı ilerleme
  classic,

  /// Online mod — çevrimiçi eşleşme
  online,
}
