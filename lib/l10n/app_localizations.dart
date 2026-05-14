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

      // Auth
      'login': 'Giriş Yap',
      'signUp': 'Kayıt Ol',
      'email': 'E-posta',
      'password': 'Şifre',
      'username': 'Kullanıcı Adı',
      'haveAccount': 'Zaten hesabın var mı?',
      'noAccount': 'Hesabın yok mu?',
      'or': 'veya',
      'continueWithGoogle': 'Google ile Devam Et',
      'continueWithApple': 'Apple ile Devam Et',

      // Online / Result
      'victory': 'Zafer!',
      'defeat': 'Yenilgi!',
      'draw': 'Berabere!',
      'victorySubtitle': 'Rakibinden önce kelimeyi buldun!',
      'defeatSubtitle': 'Rakibin bu sefer daha hızlıydı.',
      'drawSubtitle': 'İkiniz de kelimeyi bulamadı.',
      'tapToRevealWord': 'Kelimeyi görmek için dokun',
      'rematch': 'Tekrar Oyna',
      'rematchSent': 'İstek gönderildi!',
      'rematchReceived': 'Rakibin tekrar oynamak istiyor!',
      'accept': 'Kabul Et',
      'decline': 'Reddet',
      'backToHome': 'Ana Sayfa',
      'you': 'Sen',
      'opponent': 'Rakip',
      'guessCount': 'tahmin',
      'solved': 'Çözdü',
      'notSolved': 'Çözemedi',
      'streak': 'Seri',
      'played': 'Oyun',
      'winRate': 'Başarı',
      'average': 'Ortalama',
      'today': 'Bugün',
      'startStreak': 'Serini başlatmak için yarın tekrar gel!',
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

      // Auth
      'login': 'Login',
      'signUp': 'Sign Up',
      'email': 'Email',
      'password': 'Password',
      'username': 'Username',
      'haveAccount': 'Already have an account?',
      'noAccount': 'Don\'t have an account?',
      'or': 'or',
      'continueWithGoogle': 'Continue with Google',
      'continueWithApple': 'Continue with Apple',

      // Online / Result
      'victory': 'Victory!',
      'defeat': 'Defeat!',
      'draw': 'Draw!',
      'victorySubtitle': 'You found the word before your opponent!',
      'defeatSubtitle': 'Your opponent was faster this time.',
      'drawSubtitle': 'Neither of you found the word.',
      'tapToRevealWord': 'Tap to reveal the word',
      'rematch': 'Rematch',
      'rematchSent': 'Request sent!',
      'rematchReceived': 'Your opponent wants a rematch!',
      'accept': 'Accept',
      'decline': 'Decline',
      'backToHome': 'Home',
      'you': 'You',
      'opponent': 'Opponent',
      'guessCount': 'guesses',
      'solved': 'Solved',
      'notSolved': 'Failed',
      'streak': 'Streak',
      'played': 'Played',
      'winRate': 'Win Rate',
      'average': 'Average',
      'today': 'Today',
      'startStreak': 'Come back tomorrow to start your streak!',
    },
  };
}
