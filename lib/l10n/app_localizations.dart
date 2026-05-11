// Wearth çoklu dil desteği
// TR ve EN çevirilerini yönetir.

class AppLocalizations {
  // Singleton pattern
  static final AppLocalizations _instance = AppLocalizations._internal();
  factory AppLocalizations() => _instance;
  AppLocalizations._internal();

  String _currentLocale = 'tr';

  String get currentLocale => _currentLocale;

  /// Desteklenen dillerin listesi
  static const List<Map<String, String>> availableLocales = [
    {'code': 'tr', 'name': 'Türkçe', 'flag': '🇹🇷'},
    {'code': 'en', 'name': 'English', 'flag': '🇬🇧'},
  ];

  void setLocale(String locale) {
    if (_translations.containsKey(locale)) {
      _currentLocale = locale;
    }
  }

  void toggleLocale() {
    _currentLocale = _currentLocale == 'tr' ? 'en' : 'tr';
  }

  String t(String key) {
    return _translations[_currentLocale]?[key] ?? key;
  }

  /// Mevcut dilin görünen adını döndürür (buton için)
  String get currentLanguageLabel {
    final locale = availableLocales.firstWhere(
      (l) => l['code'] == _currentLocale,
      orElse: () => availableLocales.first,
    );
    return locale['name']!;
  }

  /// Mevcut dilin bayrak emojisini döndürür
  String get currentFlag {
    final locale = availableLocales.firstWhere(
      (l) => l['code'] == _currentLocale,
      orElse: () => availableLocales.first,
    );
    return locale['flag']!;
  }

  /// Diğer dilin görünen adını döndürür (geçiş bilgisi için)
  String get otherLanguageLabel {
    return _currentLocale == 'tr' ? 'English' : 'Turkish';
  }

  static const Map<String, Map<String, String>> _translations = {
    'tr': {
      // App
      'appTitle': 'WEARTH',
      'version': 'v1.0.0',

      // Home Screen
      'play': 'OYNA',
      'classicMode': 'Klasik Mod',
      'onlineMode': 'Çevrimiçi Mod',
      'wordOfTheDay': 'Günün Kelimesi',
      'howToPlay': 'Nasıl Oynanır',
      'ranking': 'Sıralama',
      'settings': 'Ayarlar',
      'profile': 'Profil',
      'home': 'Anasayfa',
      'getPremium': 'Premium Ol',
      'removeAds': 'Reklamları Kaldır',

      // Game Screen
      'dailyWordTitle': 'Günün Kelimesi',
      'enterGuess': 'Tahmininizi girin',
      'notEnoughLetters': 'Yeterli harf yok',
      'invalidWord': 'Geçersiz kelime',
      'congratulations': 'Tebrikler!',
      'gameOver': 'Oyun Bitti',
      'correctWord': 'Doğru kelime:',
      'tryAgainTomorrow': 'Yarın tekrar deneyin!',
      'attempt': 'Deneme',
      'submit': 'GİR',
      'delete': 'SİL',
      'streakMotivation': 'Serini başlatmak için kelimeyi bul! 🔥',

      // Classic Map
      'level': 'Seviye',
      'locked': 'Kilitli',
      'playLevel': 'Oyna',
      'unlockedCity': 'Şehri Keşfettin!',
      
      // Continents
      'europe': 'Avrupa',
      'africa': 'Afrika',
      'asia': 'Asya',
      'north_america': 'Kuzey Amerika',
      'south_america': 'Güney Amerika',
      'oceania': 'Okyanusya',
      'antarctica': 'Antarktika',
      
      // Game UI
      'levelComplete': 'SEVİYE TAMAMLANDI!',
      'levelFailed': 'BÖLÜM GEÇİLEMEDİ',
      'map': 'HARİTA',
      'next': 'SIRADAKİ',
      'retry': 'TEKRAR DENE',
      'noLives': 'Canın yok!',
      'wait': 'beklemen gerekiyor.',
      'city': 'Şehri',
      'currentLevel': 'MEVCUT\nSEVİYE',

      // Language
      'language': 'Dil',
      'turkish': 'Türkçe',
      'english': 'İngilizce',
    },
    'en': {
      // App
      'appTitle': 'WEARTH',
      'version': 'v1.0.0',

      // Home Screen
      'play': 'PLAY',
      'classicMode': 'Classic Mode',
      'onlineMode': 'Online Mode',
      'wordOfTheDay': 'Word of the Day',
      'howToPlay': 'How to Play',
      'ranking': 'Ranking',
      'settings': 'Settings',
      'profile': 'Profile',
      'home': 'Home',
      'getPremium': 'Get Premium',
      'removeAds': 'Remove Ads',

      // Game Screen
      'dailyWordTitle': 'Word of the Day',
      'enterGuess': 'Enter your guess',
      'notEnoughLetters': 'Not enough letters',
      'invalidWord': 'Invalid word',
      'congratulations': 'Congratulations!',
      'gameOver': 'Game Over',
      'correctWord': 'Correct word:',
      'tryAgainTomorrow': 'Try again tomorrow!',
      'attempt': 'Attempt',
      'submit': 'ENTER',
      'delete': 'DEL',
      'streakMotivation': 'Find the word to start your streak! 🔥',

      // Classic Map
      'level': 'Level',
      'locked': 'Locked',
      'playLevel': 'Play',
      'unlockedCity': 'City Unlocked!',
      
      // Continents
      'europe': 'Europe',
      'africa': 'Africa',
      'asia': 'Asia',
      'north_america': 'North America',
      'south_america': 'South America',
      'oceania': 'Oceania',
      'antarctica': 'Antarctica',
      
      // Game UI
      'levelComplete': 'LEVEL COMPLETE!',
      'levelFailed': 'LEVEL FAILED',
      'map': 'MAP',
      'next': 'NEXT',
      'retry': 'RETRY',
      'noLives': 'No lives!',
      'wait': 'to wait.',
      'city': 'City',
      'currentLevel': 'CURRENT\nLEVEL',

      // Language
      'language': 'Language',
      'turkish': 'Turkish',
      'english': 'English',
    },
  };
}
