import 'dart:async';
import 'dart:math';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import 'word_service.dart';
import '../l10n/app_localizations.dart';

/// Online maç durumları
enum MatchStatus { waiting, playing, finished }

/// Oyuncu verisi
class PlayerData {
  final String uid;
  final String name;
  final List<String> guesses;
  final bool solved;
  final int score;

  PlayerData({
    required this.uid,
    required this.name,
    this.guesses = const [],
    this.solved = false,
    this.score = 0,
  });

  Map<String, dynamic> toJson() => {
    'uid': uid,
    'name': name,
    'guesses': guesses,
    'solved': solved,
    'score': score,
  };

  factory PlayerData.fromJson(Map<String, dynamic> json) => PlayerData(
    uid: json['uid'] as String? ?? '',
    name: json['name'] as String? ?? 'Anonim',
    guesses: (json['guesses'] as List<dynamic>?)
        ?.map((e) => e.toString())
        .toList() ?? [],
    solved: json['solved'] as bool? ?? false,
    score: json['score'] as int? ?? 0,
  );
}

/// Maç verisi
class MatchData {
  final String matchId;
  final String mode; // "quick" | "best_of_3" | "multiplayer"
  final int maxPlayers;
  final String word;
  final int round;
  final MatchStatus status;
  final String locale;
  final Map<String, PlayerData> players;
  final String? winnerId;
  final int createdAt;

  MatchData({
    required this.matchId,
    required this.mode,
    required this.maxPlayers,
    required this.word,
    this.round = 1,
    required this.status,
    required this.locale,
    required this.players,
    this.winnerId,
    required this.createdAt,
  });

  factory MatchData.fromJson(String matchId, Map<String, dynamic> json) {
    final playersMap = <String, PlayerData>{};
    if (json['players'] != null) {
      (json['players'] as Map<dynamic, dynamic>).forEach((key, value) {
        playersMap[key.toString()] = PlayerData.fromJson(
          Map<String, dynamic>.from(value as Map),
        );
      });
    }

    return MatchData(
      matchId: matchId,
      mode: json['mode'] as String? ?? 'quick',
      maxPlayers: json['maxPlayers'] as int? ?? 2,
      word: json['word'] as String? ?? '',
      round: json['round'] as int? ?? 1,
      status: _parseStatus(json['status'] as String?),
      locale: json['locale'] as String? ?? 'tr',
      players: playersMap,
      winnerId: json['winnerId'] as String?,
      createdAt: json['createdAt'] as int? ?? 0,
    );
  }

  static MatchStatus _parseStatus(String? status) {
    switch (status) {
      case 'waiting':
        return MatchStatus.waiting;
      case 'playing':
        return MatchStatus.playing;
      case 'finished':
        return MatchStatus.finished;
      default:
        return MatchStatus.waiting;
    }
  }

  static String _statusToString(MatchStatus status) {
    switch (status) {
      case MatchStatus.waiting:
        return 'waiting';
      case MatchStatus.playing:
        return 'playing';
      case MatchStatus.finished:
        return 'finished';
    }
  }
}

/// Matchmaking ve online oyun servisi
class MatchmakingService {
  static final MatchmakingService _instance = MatchmakingService._internal();
  factory MatchmakingService() => _instance;
  MatchmakingService._internal();

  final FirebaseDatabase _db = FirebaseDatabase.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final WordService _wordService = WordService();

  StreamSubscription<DatabaseEvent>? _matchSubscription;
  String? _currentMatchId;

  /// Mevcut maç ID'si
  String? get currentMatchId => _currentMatchId;

  /// Mevcut kullanıcı
  User? get _currentUser => _auth.currentUser;

  // ─── Eşleşme Arama ─────────────────────────────────────────────

  /// Açık bir maç arar, bulamazsa yeni oluşturur.
  /// Eşleşme bulunduğunda matchId döner.
  Future<String> findOrCreateMatch({
    String mode = 'quick',
    int maxPlayers = 2,
  }) async {
    final user = _currentUser;
    if (user == null) throw Exception('Giriş yapmanız gerekiyor');

    final locale = AppLocalizations().currentLocale;
    final matchesRef = _db.ref('matches');

    // 1. Bekleyen bir maç ara (aynı mod ve dil)
    final snapshot = await matchesRef
        .orderByChild('status')
        .equalTo('waiting')
        .get();

    if (snapshot.exists) {
      final matches = snapshot.value as Map<dynamic, dynamic>;

      for (final entry in matches.entries) {
        final matchData = Map<String, dynamic>.from(entry.value as Map);
        final matchLocale = matchData['locale'] as String?;
        final matchMode = matchData['mode'] as String?;
        final players = matchData['players'] as Map<dynamic, dynamic>?;
        final matchMaxPlayers = matchData['maxPlayers'] as int? ?? 2;

        // Aynı mod, aynı dil ve dolu olmayan bir maç bul
        // Kendimizin oluşturduğu maçı atlayalım
        if (matchMode == mode &&
            matchLocale == locale &&
            players != null &&
            !players.containsKey(user.uid) &&
            players.length < matchMaxPlayers) {
          // Bu maça katıl
          await _joinMatch(entry.key.toString(), user);
          return entry.key.toString();
        }
      }
    }

    // 2. Bekleyen uygun maç bulunamadı — yeni oluştur
    return await _createMatch(
      mode: mode,
      maxPlayers: maxPlayers,
      locale: locale,
      user: user,
    );
  }

  // ─── Maç Oluşturma ─────────────────────────────────────────────

  Future<String> _createMatch({
    required String mode,
    required int maxPlayers,
    required String locale,
    required User user,
  }) async {
    final matchRef = _db.ref('matches').push();
    final matchId = matchRef.key!;

    // Online mod için rastgele kelime seç
    final words = _wordService.getSolutionWords(locale);
    final randomWord = words[Random().nextInt(words.length)];

    final matchData = {
      'mode': mode,
      'maxPlayers': maxPlayers,
      'word': randomWord,
      'round': 1,
      'status': 'waiting',
      'locale': locale,
      'winnerId': null,
      'createdAt': ServerValue.timestamp,
      'players': {
        user.uid: {
          'uid': user.uid,
          'name': user.displayName ?? user.email?.split('@')[0] ?? 'Anonim',
          'guesses': [],
          'solved': false,
          'score': 0,
        },
      },
    };

    await matchRef.set(matchData);
    _currentMatchId = matchId;
    return matchId;
  }

  // ─── Maça Katılma ──────────────────────────────────────────────

  Future<void> _joinMatch(String matchId, User user) async {
    final matchRef = _db.ref('matches/$matchId');

    // Oyuncuyu ekle
    await matchRef.child('players/${user.uid}').set({
      'uid': user.uid,
      'name': user.displayName ?? user.email?.split('@')[0] ?? 'Anonim',
      'guesses': [],
      'solved': false,
      'score': 0,
    });

    // Maç durumunu "playing" yap
    await matchRef.child('status').set('playing');

    _currentMatchId = matchId;
  }

  /// Belirli bir maçın detaylarını tek seferlik getirir.
  Future<MatchData?> getMatchDetails(String matchId) async {
    try {
      final snapshot = await _db.ref('matches/$matchId').get().timeout(const Duration(seconds: 5));
      if (!snapshot.exists || snapshot.value == null) return null;
      
      return MatchData.fromJson(
        matchId, 
        Map<String, dynamic>.from(snapshot.value as Map)
      );
    } catch (e) {
      debugPrint('Maç detayı getirme hatası: $e');
      return null;
    }
  }

  /// Kullanıcının maç geçmişini getirir.
  Future<List<Map<String, dynamic>>> getMatchHistory() async {
    final user = _currentUser;
    if (user == null) return [];

    try {
      final snapshot = await _db.ref('users/${user.uid}/history')
          .orderByChild('timestamp')
          .limitToLast(20)
          .get();
      
      if (!snapshot.exists || snapshot.value == null) return [];

      final data = snapshot.value as Map<dynamic, dynamic>;
      final list = data.values.map((v) => Map<String, dynamic>.from(v as Map)).toList();
      
      // En yeni en üstte olacak şekilde sırala
      list.sort((a, b) => (b['timestamp'] as int? ?? 0).compareTo(a['timestamp'] as int? ?? 0));
      return list;
    } catch (e) {
      debugPrint('Geçmiş getirme hatası: $e');
      return [];
    }
  }

  // ─── Maçı Dinleme (Realtime) ───────────────────────────────────

  /// Maç verilerini gerçek zamanlı dinler.
  Stream<MatchData?> listenToMatch(String matchId) {
    final controller = StreamController<MatchData?>.broadcast();

    _matchSubscription?.cancel();
    _matchSubscription = _db.ref('matches/$matchId').onValue.listen(
      (event) {
        if (event.snapshot.value == null) {
          controller.add(null);
          return;
        }
        final data = Map<String, dynamic>.from(
          event.snapshot.value as Map,
        );
        controller.add(MatchData.fromJson(matchId, data));
      },
      onError: (error) {
        controller.addError(error);
      },
    );

    return controller.stream;
  }

  // ─── Tahmin Gönderme ───────────────────────────────────────────

  /// Bir tahmin gönderir ve çözüldüyse günceller.
  Future<void> submitGuess({
    required String matchId,
    required String guess,
    required bool isSolved,
  }) async {
    final user = _currentUser;
    if (user == null) return;

    final playerRef = _db.ref('matches/$matchId/players/${user.uid}');

    // Mevcut tahminleri al ve yenisini ekle
    final snapshot = await playerRef.child('guesses').get();
    final List<String> currentGuesses = [];
    if (snapshot.exists && snapshot.value != null) {
      currentGuesses.addAll(
        (snapshot.value as List<dynamic>).map((e) => e.toString()),
      );
    }
    currentGuesses.add(guess.toUpperCase());

    // Güncelle
    await playerRef.update({
      'guesses': currentGuesses,
      'solved': isSolved,
    });

    // Eğer çözdüyse ve ilk çözen buysa → kazanan yap
    if (isSolved) {
      final matchRef = _db.ref('matches/$matchId');
      final matchSnapshot = await matchRef.get();
      if (matchSnapshot.exists) {
        final data = Map<String, dynamic>.from(matchSnapshot.value as Map);
        if (data['winnerId'] == null) {
          await matchRef.update({
            'winnerId': user.uid,
            'status': 'finished',
          });
          // Geçmişe kaydet
          final playerIds = (data['players'] as Map).keys.cast<String>().toList();
          _saveMatchToHistory(matchId, playerIds);
        }
      }
    }
  }

  /// Maç ID'lerini oyuncuların geçmişine kaydeder.
  Future<void> _saveMatchToHistory(String matchId, List<String> playerIds) async {
    for (final uid in playerIds) {
      await _db.ref('users/$uid/history').push().set({
        'matchId': matchId,
        'timestamp': ServerValue.timestamp,
      });
    }
  }

  // ─── 6 Tahmin Hakkı Bitti (Kaybetti) ───────────────────────────

  /// Oyuncu 6 tahmini bitirdi ve çözemedi.
  Future<void> playerFailed({required String matchId}) async {
    final user = _currentUser;
    if (user == null) return;

    // Rakibin durumunu kontrol et
    final matchRef = _db.ref('matches/$matchId');
    final snapshot = await matchRef.get();
    if (!snapshot.exists) return;

    final data = Map<String, dynamic>.from(snapshot.value as Map);
    final players = data['players'] as Map<dynamic, dynamic>;

    // Tüm oyuncuların çözüp çözmediğini veya bitirip bitirmediğini kontrol et
    bool allDone = true;
    String? solvedPlayerId;

    for (final entry in players.entries) {
      final pData = Map<String, dynamic>.from(entry.value as Map);
      final guesses = pData['guesses'] as List<dynamic>? ?? [];
      final solved = pData['solved'] as bool? ?? false;

      if (solved) {
        solvedPlayerId = entry.key.toString();
      }
      if (!solved && guesses.length < 6 && entry.key.toString() != user.uid) {
        allDone = false;
      }
    }

    // Eğer herkes bittiyse maçı sonlandır
    if (allDone) {
      await matchRef.update({
        'winnerId': solvedPlayerId, // null olabilir (berabere)
        'status': 'finished',
      });
      // Geçmişe kaydet
      _saveMatchToHistory(matchId, players.keys.cast<String>().toList());
    }
  }

  // ─── Maçtan Ayrılma ────────────────────────────────────────────

  /// Maçtan ayrılır ve temizlik yapar.
  Future<void> leaveMatch({String? matchId}) async {
    final targetMatchId = matchId ?? _currentMatchId;
    if (targetMatchId == null) return;

    final user = _currentUser;
    if (user != null) {
      final matchRef = _db.ref('matches/$targetMatchId');
      final snapshot = await matchRef.get();

      if (snapshot.exists) {
        final data = Map<String, dynamic>.from(snapshot.value as Map);
        final status = data['status'] as String?;

        if (status == 'waiting') {
          await matchRef.remove();
        } else if (status == 'playing') {
          final players = data['players'] as Map<dynamic, dynamic>;
          final opponentId = players.keys
              .firstWhere((k) => k.toString() != user.uid,
                  orElse: () => null)
              ?.toString();

          if (opponentId != null) {
            await matchRef.update({
              'winnerId': opponentId,
              'status': 'finished',
            });
            await _saveMatchToHistory(targetMatchId, [user.uid, opponentId]);
          }
        }
      }
    }

    if (targetMatchId == _currentMatchId) {
      _matchSubscription?.cancel();
      _matchSubscription = null;
      _currentMatchId = null;
    }
  }

  /// Tüm dinleyicileri temizler.
  void dispose() {
    _matchSubscription?.cancel();
    _matchSubscription = null;
    _currentMatchId = null;
  }

  // ─── Rematch (Tekrar Oynama) ───────────────────────────────────

  /// Rematch isteği gönderir.
  Future<void> sendRematchRequest(String matchId) async {
    final user = _currentUser;
    if (user == null) return;

    await _db.ref('matches/$matchId/rematch/${user.uid}').set({
      'uid': user.uid,
      'name': user.displayName ?? user.email?.split('@')[0] ?? 'Anonim',
      'ready': true,
    });
  }

  /// Rematch isteklerini dinler.
  Stream<Map<String, dynamic>?> listenForRematch(String matchId) {
    final controller = StreamController<Map<String, dynamic>?>.broadcast();

    _db.ref('matches/$matchId/rematch').onValue.listen((event) {
      if (event.snapshot.value == null) {
        controller.add(null);
        return;
      }
      controller.add(Map<String, dynamic>.from(event.snapshot.value as Map));
    });

    return controller.stream;
  }

  /// Rematch sonucu oluşan yeni maç ID'sini dinler.
  Stream<String?> listenForRematchMatchId(String matchId) {
    return _db.ref('matches/$matchId/rematchMatchId').onValue.map((event) {
      return event.snapshot.value?.toString();
    });
  }

  /// Rematch kabul eder — yeni bir maç oluşturur ve iki oyuncuyu ekler.
  Future<String> acceptRematch({
    required String oldMatchId,
    required String opponentUid,
    required String opponentName,
  }) async {
    final user = _currentUser;
    if (user == null) throw Exception('Giriş yapmanız gerekiyor');

    final locale = AppLocalizations().currentLocale;
    final words = _wordService.getSolutionWords(locale);
    final randomWord = words[Random().nextInt(words.length)];

    final matchRef = _db.ref('matches').push();
    final matchId = matchRef.key!;

    final matchData = {
      'mode': 'quick',
      'maxPlayers': 2,
      'word': randomWord,
      'round': 1,
      'status': 'playing',
      'locale': locale,
      'winnerId': null,
      'createdAt': ServerValue.timestamp,
      'players': {
        user.uid: {
          'uid': user.uid,
          'name': user.displayName ?? user.email?.split('@')[0] ?? 'Anonim',
          'guesses': [],
          'solved': false,
          'score': 0,
        },
        opponentUid: {
          'uid': opponentUid,
          'name': opponentName,
          'guesses': [],
          'solved': false,
          'score': 0,
        },
      },
    };

    await matchRef.set(matchData);

    // Eski maça yeni matchId'yi yaz ki rakip de yönlendirilsin
    await _db.ref('matches/$oldMatchId/rematchMatchId').set(matchId);

    _currentMatchId = matchId;
    return matchId;
  }

  // ─── Arkadaşa Meydan Okuma (Direct Invite) ────────────────────

  /// Bir arkadaşa doğrudan oyun isteği gönderir.
  Future<String> challengeFriend(String friendUid, String friendName) async {
    final user = _currentUser;
    if (user == null) throw Exception('Giriş yapmanız gerekiyor');

    final locale = AppLocalizations().currentLocale;
    
    // 1. Bekleyen bir maç oluştur
    final words = _wordService.getSolutionWords(locale);
    final randomWord = words[Random().nextInt(words.length)];

    final matchRef = _db.ref('matches').push();
    final matchId = matchRef.key!;

    final myName = user.displayName ?? user.email?.split('@')[0] ?? 'Anonim';

    debugPrint('🔵 Challenge gönderiliyor: $matchId, Hedef: $friendUid');

    final matchData = {
      'mode': 'challenge',
      'maxPlayers': 2,
      'word': randomWord,
      'round': 1,
      'status': 'waiting',
      'locale': locale,
      'createdAt': ServerValue.timestamp,
      'players': {
        user.uid: {
          'uid': user.uid,
          'name': myName,
          'guesses': [],
          'solved': false,
          'score': 0,
        },
      },
    };

    await matchRef.set(matchData);

    // 2. Arkadaşa davet gönder
    await _db.ref('users/$friendUid/game_invites/${user.uid}').set({
      'matchId': matchId,
      'challengerName': myName,
      'createdAt': ServerValue.timestamp,
    });

    _currentMatchId = matchId;
    return matchId;
  }

  /// Gelen oyun davetlerini dinler.
  Stream<Map<String, dynamic>?> listenToGameInvites() {
    final user = _currentUser;
    if (user == null) return Stream.value(null);

    return _db.ref('users/${user.uid}/game_invites').onValue.map((event) {
      if (event.snapshot.value == null) return null;
      return Map<String, dynamic>.from(event.snapshot.value as Map);
    });
  }

  /// Oyun davetine yanıt verir.
  Future<void> respondToGameInvite({
    required String challengerUid,
    required String matchId,
    required bool accept,
  }) async {
    final user = _currentUser;
    if (user == null) return;

    if (accept) {
      // Maça katıl
      await _joinMatch(matchId, user);
    } else {
      // Maçı ve daveti sil
      await _db.ref('matches/$matchId').remove();
    }

    // Daveti her durumda sil
    await _db.ref('users/${user.uid}/game_invites/$challengerUid').remove();
  }
}
