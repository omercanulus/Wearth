// Wearth çoklu dil desteği
// TR ve EN çevirilerini yönetir.

class AppLocalizations {
  // Singleton pattern
  static final AppLocalizations _instance = AppLocalizations._internal();
  factory AppLocalizations() => _instance;
  AppLocalizations._internal();

  String _currentLocale = 'tr';

  String get currentLocale => _currentLocale;

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
    return _currentLocale == 'tr' ? 'Turkish' : 'English';
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
      'removeAds': 'Reklamları Kaldır',

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
      'removeAds': 'Remove Ads',

      // Language
      'language': 'Language',
      'turkish': 'Turkish',
      'english': 'English',
    },
  };
}
