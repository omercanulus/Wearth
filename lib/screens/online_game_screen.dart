import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_database/firebase_database.dart';
import '../services/matchmaking_service.dart';
import '../services/auth_service.dart';
import '../services/word_service.dart';
import '../services/social_service.dart';
import '../services/storage_service.dart';
import '../widgets/profile_card.dart';
import '../models/game_state.dart';
import '../theme/app_theme.dart';
import '../l10n/app_localizations.dart';

/// Online 1v1 oyun ekranı.
/// Rakibin ilerlemesini gerçek zamanlı gösterir.
class OnlineGameScreen extends StatefulWidget {
  final String matchId;

  const OnlineGameScreen({super.key, required this.matchId});

  @override
  State<OnlineGameScreen> createState() => _OnlineGameScreenState();
}

class _OnlineGameScreenState extends State<OnlineGameScreen> {
  final MatchmakingService _matchmaking = MatchmakingService();
  final WordService _wordService = WordService();
  final AppLocalizations _l10n = AppLocalizations();
  final String _myUid = AuthService().currentUser?.uid ?? '';

  late GameState _gameState;
  bool _gameInitialized = false;
  String _currentInput = '';
  String _message = '';
  bool _showMessage = false;

  // Rakip bilgileri
  String _opponentName = '';
  int _opponentGuessCount = 0;
  bool _opponentSolved = false;

  // Maç durumu
  MatchData? _matchData;
  StreamSubscription<MatchData?>? _matchSub;
  StreamSubscription? _rematchMatchSub;
  bool _gameEnded = false;

  @override
  void initState() {
    super.initState();
    _listenToMatch();
  }

  void _listenToMatch() {
    _matchSub = _matchmaking.listenToMatch(widget.matchId).listen((data) {
      if (data == null || !mounted) return;

      setState(() {
        _matchData = data;

        // İlk veri geldiğinde oyunu başlat
        if (!_gameInitialized) {
          _initGame(data.word);
          _gameInitialized = true;
        }

        // Rakip bilgilerini güncelle
        for (final entry in data.players.entries) {
          if (entry.key != _myUid) {
            _opponentName = entry.value.name;
            _opponentGuessCount = entry.value.guesses.length;
            _opponentSolved = entry.value.solved;
          }
        }

        // Maç bittiyse
        if (data.status == MatchStatus.finished && !_gameEnded) {
          _gameEnded = true;
          _updateLocalStats(data.winnerId == _myUid);
          Future.delayed(const Duration(milliseconds: 500), () {
            if (mounted) _showGameResult(data);
          });
        }
      });
    });

    // Rematch yönlendirmesini ana ekranda da dinle (diyalog kapalıyken de çalışsın)
    _rematchMatchSub = _matchmaking.listenForRematchMatchId(widget.matchId).listen((newMatchId) {
      if (newMatchId == null || !mounted) return;
      
      // Oyuna yönlendir
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop(); // Sonuç diyaloğunu kapat
      }
      
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => OnlineGameScreen(matchId: newMatchId)),
      );
    });
  }

  void _initGame(String word) {
    final locale = _l10n.currentLocale;
    _gameState = GameState(
      mode: GameMode.daily, // Online mod olarak kullanıyoruz
      targetWord: word.toUpperCase(),
      locale: locale,
    );
  }

  @override
  void dispose() {
    _matchSub?.cancel();
    _rematchMatchSub?.cancel();
    super.dispose();
  }

  Future<void> _handleExit() async {
    if (!_gameEnded) {
      _gameEnded = true; // Tekrar çalışmasını engelle
      await _matchmaking.leaveMatch(matchId: widget.matchId);
      await _updateLocalStats(false); // Ayrıldığı için mağlup say
    }
  }

  Future<void> _updateLocalStats(bool isWin) async {
    final stats = await StorageService().loadStats(locale: _l10n.currentLocale);
    stats.gamesPlayed++;
    if (isWin) stats.gamesWon++;
    
    await StorageService().saveStats(stats: stats, locale: _l10n.currentLocale);
    
    // Firebase ile senkronize et
    SocialService().updateStats(
      gamesPlayed: stats.gamesPlayed,
      gamesWon: stats.gamesWon,
      maxStreak: stats.maxStreak,
    );
  }

  // ─── Oyun Mantığı ──────────────────────────────────────────────

  void _onKeyPressed(String key) {
    if (_gameState.isGameOver || _gameEnded) return;

    setState(() {
      if (key == 'BACKSPACE') {
        if (_currentInput.isNotEmpty) {
          _currentInput =
              _currentInput.substring(0, _currentInput.length - 1);
        }
      } else if (key == 'ENTER') {
        _submitGuess();
      } else {
        if (_currentInput.length < 5) {
          _currentInput += key;
        }
      }
    });
  }

  void _submitGuess() async {
    if (_currentInput.length < 5) {
      _showTemporaryMessage(_l10n.t('notEnoughLetters'));
      return;
    }

    final guess = _currentInput.toUpperCase();

    if (!_wordService.isValidWord(guess, _gameState.locale)) {
      _showTemporaryMessage(_l10n.t('invalidWord'));
      return;
    }

    final results = _wordService.evaluateGuess(
      guess: guess,
      target: _gameState.targetWord,
    );

    final isSolved =
        results.every((r) => r == LetterResult.correct);

    setState(() {
      _gameState.addGuess(guess, results);
      _currentInput = '';
    });

    // Firebase'e gönder
    await _matchmaking.submitGuess(
      matchId: widget.matchId,
      guess: guess,
      isSolved: isSolved,
    );

    // 6 tahmin hakkı bittiyse ve çözemediyse
    if (!isSolved && _gameState.currentAttempt >= 6) {
      await _matchmaking.playerFailed(matchId: widget.matchId);
    }
  }

  void _showTemporaryMessage(String msg) {
    setState(() {
      _message = msg;
      _showMessage = true;
    });
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _showMessage = false);
    });
  }

  void _showGameResult(MatchData data) {
    final isWinner = data.winnerId == _myUid;
    final isDraw = data.winnerId == null;

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) {
        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          insetPadding: const EdgeInsets.symmetric(horizontal: 16),
          child: _OnlineResultCard(
            isWinner: isWinner,
            isDraw: isDraw,
            matchData: data,
            myUid: _myUid,
            targetWord: _gameState.targetWord,
            opponentName: _opponentName,
            opponentGuessCount: _opponentGuessCount,
            matchId: widget.matchId,
          ),
        );
      },
    );
  }

  // ─── Arayüz ────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    // GameState henüz init olmadıysa loading göster
    if (_matchData == null) {
      return Scaffold(
        backgroundColor: context.wearth.scaffoldBg,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return PopScope(
      canPop: true,
      onPopInvoked: (didPop) async {
        if (didPop) {
          _handleExit();
        }
      },
      child: Scaffold(
        backgroundColor: context.wearth.scaffoldBg,
        body: SafeArea(
          child: Column(
            children: [
            _buildTopBar(),
            _buildMessageBanner(),

            // Rakip durumu
            _buildOpponentBar(),

            const SizedBox(height: 8),

            // Tahmin grid'i
            Expanded(
              flex: 3,
              child: Center(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: _buildGuessGrid(),
                ),
              ),
            ),

            // Klavye veya Sonuç Butonu
            if (!_gameState.isGameOver && !_gameEnded)
              FittedBox(
                fit: BoxFit.scaleDown,
                child: _buildKeyboard(),
              )
            else if (_gameEnded)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                child: GestureDetector(
                  onTap: () => _showGameResult(_matchData!),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          color: context.wearth.glassBackgroundStrong,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: context.wearth.glassBorder,
                            width: 0.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withAlpha(10),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.analytics_outlined,
                              color: context.wearth.textPrimary,
                              size: 20,
                            ),
                            const SizedBox(width: 10),
                            Text(
                              _l10n.t('viewResults').toUpperCase(),
                              style: GoogleFonts.outfit(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.2,
                                color: context.wearth.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),

            const SizedBox(height: 16),
          ],
        ),
      ),
    ),
  );
}

  // ─── Top Bar ───────────────────────────────────────────────────

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: GestureDetector(
              onTap: () => _showLeaveConfirmation(),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: context.wearth.glassBackground,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: context.wearth.glassBorder,
                        width: 0.5,
                      ),
                    ),
                    child: Icon(
                      Icons.arrow_back_ios_new_rounded,
                      size: 20,
                      color: context.wearth.textSecondary,
                    ),
                  ),
                ),
              ),
            ),
          ),
          Text(
            _l10n.t('quickMode').toUpperCase(),
            style: GoogleFonts.outfit(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              letterSpacing: 2.0,
              color: context.wearth.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  // ─── Rakip Durumu ──────────────────────────────────────────────

  Widget _buildOpponentBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: _opponentSolved
                  ? const Color(0xFFEF4444).withAlpha(15)
                  : context.wearth.glassBackground,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _opponentSolved
                    ? const Color(0xFFEF4444).withAlpha(60)
                    : context.wearth.glassBorder,
                width: 0.5,
              ),
            ),
            child: Row(
              children: [
                // Rakip avatar
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFFEF4444).withAlpha(20),
                  ),
                  child: Center(
                    child: Text(
                      _opponentName.isNotEmpty
                          ? _opponentName[0].toUpperCase()
                          : '?',
                      style: GoogleFonts.outfit(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFFEF4444),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Rakip adı
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _opponentName.isNotEmpty ? _opponentName : 'Rakip',
                        style: GoogleFonts.outfit(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: context.wearth.textPrimary,
                        ),
                      ),
                      Text(
                        _opponentSolved
                            ? 'Kelimeyi buldu!'
                            : '$_opponentGuessCount. tahminde',
                        style: GoogleFonts.outfit(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: _opponentSolved
                              ? const Color(0xFFEF4444)
                              : context.wearth.textVersion,
                        ),
                      ),
                    ],
                  ),
                ),

                // Tahmin göstergesi (6 nokta)
                Row(
                  children: List.generate(6, (i) {
                    final isUsed = i < _opponentGuessCount;
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isUsed
                              ? (_opponentSolved && i == _opponentGuessCount - 1
                                  ? const Color(0xFFEF4444)
                                  : const Color(0xFFF59E0B))
                              : context.wearth.keyBackground,
                        ),
                      ),
                    );
                  }),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─── Mesaj ─────────────────────────────────────────────────────

  Widget _buildMessageBanner() {
    return AnimatedOpacity(
      opacity: _showMessage ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 200),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 40, vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: context.wearth.messageBg,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          _message,
          textAlign: TextAlign.center,
          style: GoogleFonts.outfit(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: context.wearth.messageText,
          ),
        ),
      ),
    );
  }

  // ─── Tahmin Grid ───────────────────────────────────────────────

  Widget _buildGuessGrid() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(6, (row) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 3),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (col) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: _buildLetterTile(row, col),
                );
              }),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildLetterTile(int row, int col) {
    String letter = '';
    LetterResult? result;

    if (row < _gameState.currentAttempt) {
      final guess = _gameState.guesses[row];
      letter = guess.word[col];
      result = guess.results[col];
    } else if (row == _gameState.currentAttempt) {
      if (col < _currentInput.length) {
        letter = _currentInput[col];
      }
    }

    Color tileColor;
    Color borderColor;
    Color textColor;

    if (result != null) {
      switch (result) {
        case LetterResult.correct:
          tileColor = const Color(0xFF4CAF50).withAlpha(45);
          borderColor = const Color(0xFF4CAF50).withAlpha(100);
          textColor = const Color(0xFF2E7D32);
          break;
        case LetterResult.present:
          tileColor = const Color(0xFF06B6D4).withAlpha(45);
          borderColor = const Color(0xFF06B6D4).withAlpha(100);
          textColor = const Color(0xFF0891B2);
          break;
        case LetterResult.absent:
          tileColor = context.wearth.glassBackground.withAlpha(20);
          borderColor = context.wearth.glassBorder.withAlpha(40);
          textColor = context.wearth.textMuted;
          break;
      }
    } else {
      tileColor = letter.isNotEmpty
          ? context.wearth.tileActive
          : context.wearth.tileEmpty;
      borderColor = letter.isNotEmpty
          ? context.wearth.tileActiveBorder
          : context.wearth.tileEmptyBorder;
      textColor = context.wearth.textPrimary;
    }

    final size = MediaQuery.of(context).size.width / 7.5;
    final tileSize = size.clamp(48.0, 62.0);

    return ClipRRect(
      borderRadius: BorderRadius.circular(tileSize / 2),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          width: tileSize,
          height: tileSize,
          decoration: BoxDecoration(
            color: tileColor,
            shape: BoxShape.circle,
            border: Border.all(color: borderColor, width: 1.0),
            boxShadow: [
              if (result != null)
                BoxShadow(
                  color: borderColor.withAlpha(20),
                  blurRadius: 12,
                  offset: const Offset(0, 3),
                ),
            ],
          ),
          child: Center(
            child: AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: GoogleFonts.outfit(
                fontSize: tileSize * 0.4,
                fontWeight: FontWeight.w800,
                color: textColor,
              ),
              child: Text(letter),
            ),
          ),
        ),
      ),
    );
  }

  // ─── Klavye ────────────────────────────────────────────────────

  Widget _buildKeyboard() {
    final rows = _getKeyboardLayout();
    final keyStates = _gameState.keyboardStates;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        children: rows.map((row) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: row.map((key) {
                final isSpecial = key == 'ENTER' || key == 'BACKSPACE';
                final width = isSpecial ? 48.0 : 30.0;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: _buildKeyboardKey(
                    key: key,
                    width: width,
                    result: keyStates[key],
                  ),
                );
              }).toList(),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildKeyboardKey({
    required String key,
    required double width,
    LetterResult? result,
  }) {
    final isSpecial = key == 'ENTER' || key == 'BACKSPACE';

    Color bgColor;
    Color textColor;

    if (result != null) {
      switch (result) {
        case LetterResult.correct:
          bgColor = const Color(0xFF4CAF50).withAlpha(40);
          textColor = const Color(0xFF2E7D32);
          break;
        case LetterResult.present:
          bgColor = const Color(0xFF06B6D4).withAlpha(40);
          textColor = const Color(0xFF0891B2);
          break;
        case LetterResult.absent:
          bgColor = context.wearth.glassBackgroundStrong.withAlpha(20);
          textColor = context.wearth.textMuted;
          break;
      }
    } else {
      bgColor = context.wearth.keyBackground;
      textColor = context.wearth.keyText;
    }

    String displayText = key;
    IconData? icon;

    if (key == 'ENTER') {
      displayText = _l10n.t('submit');
    } else if (key == 'BACKSPACE') {
      icon = Icons.backspace_outlined;
      displayText = '';
    }

    return GestureDetector(
      onTap: () => _onKeyPressed(key),
      child: Container(
        width: width,
        height: 42,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: context.wearth.keyBorder,
            width: 0.5,
          ),
        ),
        child: Center(
          child: icon != null
              ? Icon(icon, size: 18, color: textColor)
              : Text(
                  displayText,
                  style: GoogleFonts.outfit(
                    fontSize: isSpecial ? 11 : 14,
                    fontWeight: FontWeight.w700,
                    color: textColor,
                  ),
                ),
        ),
      ),
    );
  }

  List<List<String>> _getKeyboardLayout() {
    if (_gameState.locale == 'tr') {
      return [
        ['E', 'R', 'T', 'Y', 'U', 'I', 'O', 'P', 'Ğ', 'Ü'],
        ['A', 'S', 'D', 'F', 'G', 'H', 'J', 'K', 'L', 'Ş', 'İ'],
        ['ENTER', 'Z', 'C', 'V', 'B', 'N', 'M', 'Ö', 'Ç', 'BACKSPACE'],
      ];
    } else {
      return [
        ['Q', 'W', 'E', 'R', 'T', 'Y', 'U', 'I', 'O', 'P'],
        ['A', 'S', 'D', 'F', 'G', 'H', 'J', 'K', 'L'],
        ['ENTER', 'Z', 'X', 'C', 'V', 'B', 'N', 'M', 'BACKSPACE'],
      ];
    }
  }

  // ─── Oyundan Ayrılma Onayı ─────────────────────────────────────

  void _showLeaveConfirmation() {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: context.wearth.scaffoldBg,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            _l10n.t('leaveMatch'),
            style: GoogleFonts.outfit(
              fontWeight: FontWeight.w700,
              color: context.wearth.textPrimary,
            ),
          ),
          content: Text(
            _l10n.t('leaveMatchWarning'),
            style: GoogleFonts.outfit(
              color: context.wearth.textSecondary,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(
                _l10n.t('no'),
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.w600,
                  color: context.wearth.textSecondary,
                ),
              ),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(ctx).pop();
                await _matchmaking.leaveMatch();
                if (mounted) Navigator.of(context).pop();
              },
              child: Text(
                _l10n.t('yes'),
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.w700,
                  color: Colors.redAccent,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // ─── Sonuç Kartı artık ayrı StatefulWidget olarak aşağıda ─────
}

/// Modern online sonuç kartı
class _OnlineResultCard extends StatefulWidget {
  final bool isWinner;
  final bool isDraw;
  final MatchData matchData;
  final String myUid;
  final String targetWord;
  final String opponentName;
  final int opponentGuessCount;
  final String matchId;

  const _OnlineResultCard({
    required this.isWinner,
    required this.isDraw,
    required this.matchData,
    required this.myUid,
    required this.targetWord,
    required this.opponentName,
    required this.opponentGuessCount,
    required this.matchId,
  });

  @override
  State<_OnlineResultCard> createState() => _OnlineResultCardState();
}

class _OnlineResultCardState extends State<_OnlineResultCard> {
  final AppLocalizations _l10n = AppLocalizations();
  final MatchmakingService _matchmaking = MatchmakingService();
  bool _wordRevealed = false;
  bool _rematchSent = false;
  bool _opponentWantsRematch = false;
  String _friendshipStatus = 'none'; // none, sent, received, friend
  StreamSubscription? _rematchSub;

  @override
  void initState() {
    super.initState();
    if (widget.isWinner) _wordRevealed = true;
    _checkFriendship();
    _listenRematch();
  }

  void _checkFriendship() async {
    final opponentUid = widget.matchData.players.entries
        .firstWhere((e) => e.key != widget.myUid)
        .key;
    final status = await SocialService().getRelationshipStatus(opponentUid);
    if (mounted) setState(() => _friendshipStatus = status);
  }

  void _listenRematch() {
    _rematchSub = _matchmaking.listenForRematch(widget.matchId).listen((data) {
      if (data == null || !mounted) return;
      for (final key in data.keys) {
        if (key != widget.myUid) {
          setState(() => _opponentWantsRematch = true);
        }
      }
    });
  }

  @override
  void dispose() {
    _rematchSub?.cancel();
    super.dispose();
  }

  void _onRematchTap() async {
    if (_opponentWantsRematch) {
      // Rakip zaten istedi, kabul et → yeni maç oluştur
      try {
        final opponentEntry = widget.matchData.players.entries
            .firstWhere((e) => e.key != widget.myUid);
        final newMatchId = await _matchmaking.acceptRematch(
          oldMatchId: widget.matchId,
          opponentUid: opponentEntry.key,
          opponentName: opponentEntry.value.name,
        );
        if (mounted) {
          Navigator.of(context).pop(); // dialog
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => OnlineGameScreen(matchId: newMatchId)),
          );
        }
      } catch (_) {}
    } else {
      // İlk istek gönder
      await _matchmaking.sendRematchRequest(widget.matchId);
      setState(() => _rematchSent = true);
    }
  }

  void _onDeclineRematch() {
    Navigator.of(context).pop();
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final accent = widget.isWinner
        ? const Color(0xFF10B981)
        : widget.isDraw
            ? const Color(0xFFF59E0B)
            : const Color(0xFFEF4444);

    final myData = widget.matchData.players[widget.myUid];
    final myGuesses = myData?.guesses.length ?? 0;

    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
        child: Container(
          decoration: BoxDecoration(
            color: context.isDark
                ? const Color(0xFF1A1A2E)
                : const Color(0xFFF8F9FC),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: accent.withAlpha(40), width: 1),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Gradient başlık alanı ──
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      accent.withAlpha(35),
                      accent.withAlpha(10),
                    ],
                  ),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                ),
                child: Column(
                  children: [
                    // Kapatma butonu
                    Align(
                      alignment: Alignment.topRight,
                      child: GestureDetector(
                        onTap: () => Navigator.of(context).pop(),
                        child: Icon(Icons.close_rounded, size: 22,
                            color: context.wearth.textSecondary),
                      ),
                    ),
                    // İkon
                    Container(
                      width: 56, height: 56,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: accent.withAlpha(25),
                        border: Border.all(color: accent.withAlpha(60), width: 2),
                      ),
                      child: Icon(
                        widget.isWinner ? Icons.emoji_events_rounded
                            : widget.isDraw ? Icons.handshake_rounded
                            : Icons.sentiment_dissatisfied_rounded,
                        size: 28, color: accent,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      widget.isWinner ? _l10n.t('victory')
                          : widget.isDraw ? _l10n.t('draw')
                          : _l10n.t('defeat'),
                      style: GoogleFonts.outfit(
                        fontSize: 24, fontWeight: FontWeight.w900, color: accent,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.isWinner ? _l10n.t('victorySubtitle')
                          : widget.isDraw ? _l10n.t('drawSubtitle')
                          : _l10n.t('defeatSubtitle'),
                      textAlign: TextAlign.center,
                      style: GoogleFonts.outfit(fontSize: 12, color: context.wearth.textSecondary),
                    ),
                  ],
                ),
              ),

              // ── Alt içerik ──
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 20),
                child: Column(
                  children: [
                    // Kelime
                    _wordRevealed
                        ? Container(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                            decoration: BoxDecoration(
                              color: accent.withAlpha(12),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: accent.withAlpha(30)),
                            ),
                            child: Text(
                              widget.targetWord,
                              style: GoogleFonts.outfit(
                                fontSize: 22, fontWeight: FontWeight.w900,
                                letterSpacing: 6, color: accent,
                              ),
                            ),
                          )
                        : GestureDetector(
                            onTap: () => setState(() => _wordRevealed = true),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                              decoration: BoxDecoration(
                                color: context.wearth.keyBackground.withAlpha(60),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: context.wearth.glassBorder),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.visibility_outlined, size: 16, color: context.wearth.textSecondary),
                                  const SizedBox(width: 8),
                                  Text(_l10n.t('tapToRevealWord'),
                                    style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w600, color: context.wearth.textSecondary)),
                                ],
                              ),
                            ),
                          ),
                    const SizedBox(height: 18),

                    // İstatistik karşılaştırma
                    Row(
                      children: [
                        Expanded(child: _playerStat(_l10n.t('you'), '$myGuesses ${_l10n.t('guessCount')}',
                            myData?.solved == true, const Color(0xFF2196F3))),
                        Container(width: 1, height: 44, color: context.wearth.glassBorder),
                        Expanded(
                          child: GestureDetector(
                            onTap: () async {
                              final opponentUid = widget.matchData.players.entries
                                  .firstWhere((e) => e.key != widget.myUid).key;
                              final profile = await SocialService().getUserProfile(opponentUid);
                              if (profile != null && mounted) {
                                ProfileCard.show(context, profile);
                              }
                            },
                            child: _playerStat(
                                widget.opponentName.isNotEmpty ? widget.opponentName : _l10n.t('opponent'),
                                '${widget.opponentGuessCount} ${_l10n.t('guessCount')}',
                                 widget.matchData.players.entries.where((e) => e.key != widget.myUid).firstOrNull?.value.solved == true,
                                const Color(0xFFEF4444)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Arkadaş Ekle / İptal Et Butonu
                    if (_friendshipStatus != 'friend' && _friendshipStatus != 'blocked')
                      GestureDetector(
                        onTap: () async {
                          final opponentUid = widget.matchData.players.entries
                              .firstWhere((e) => e.key != widget.myUid).key;
                          if (_friendshipStatus == 'none') {
                            await SocialService().sendFriendRequest(opponentUid);
                          } else if (_friendshipStatus == 'sent') {
                            await SocialService().cancelFriendRequest(opponentUid);
                          }
                          _checkFriendship();
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: _friendshipStatus == 'sent' 
                                ? const Color(0xFFEF4444).withAlpha(20) 
                                : const Color(0xFF3B82F6).withAlpha(20),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: _friendshipStatus == 'sent' 
                                  ? const Color(0xFFEF4444).withAlpha(50) 
                                  : const Color(0xFF3B82F6).withAlpha(50),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _friendshipStatus == 'sent' ? Icons.close_rounded : Icons.person_add_rounded,
                                size: 16,
                                color: _friendshipStatus == 'sent' ? const Color(0xFFEF4444) : const Color(0xFF3B82F6),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _friendshipStatus == 'sent' ? _l10n.t('cancelRequest') : _l10n.t('addFriend'),
                                style: GoogleFonts.outfit(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: _friendshipStatus == 'sent' ? const Color(0xFFEF4444) : const Color(0xFF3B82F6),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    const SizedBox(height: 18),

                    // Rematch bildirimi
                    if (_opponentWantsRematch && !_rematchSent)
                      Container(
                        width: double.infinity,
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF8B5CF6).withAlpha(12),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFF8B5CF6).withAlpha(35)),
                        ),
                        child: Text(_l10n.t('rematchReceived'),
                          textAlign: TextAlign.center,
                          style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFF8B5CF6))),
                      ),

                    if (_rematchSent && !_opponentWantsRematch)
                      Container(
                        width: double.infinity,
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: accent.withAlpha(10),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: accent.withAlpha(30)),
                        ),
                        child: Text(_l10n.t('rematchSent'),
                          textAlign: TextAlign.center,
                          style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w600, color: accent)),
                      ),

                    // Butonlar
                    if (_opponentWantsRematch && !_rematchSent)
                      // Kabul / Reddet
                      Row(children: [
                        Expanded(child: GestureDetector(
                          onTap: _onDeclineRematch,
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            decoration: BoxDecoration(
                              color: context.wearth.keyBackground,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Center(child: Text(_l10n.t('decline'),
                                style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w700, color: context.wearth.textPrimary))),
                          ),
                        )),
                        const SizedBox(width: 12),
                        Expanded(child: GestureDetector(
                          onTap: _onRematchTap,
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            decoration: BoxDecoration(
                              color: const Color(0xFF10B981).withAlpha(20),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: const Color(0xFF10B981).withAlpha(50)),
                            ),
                            child: Center(child: Text(_l10n.t('accept'),
                                style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w700, color: const Color(0xFF10B981)))),
                          ),
                        )),
                      ])
                    else
                      // Ana Sayfa / Tekrar Oyna
                      Row(children: [
                        Expanded(child: GestureDetector(
                          onTap: () { Navigator.of(context).pop(); Navigator.of(context).pop(); },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            decoration: BoxDecoration(
                              color: context.wearth.keyBackground,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Center(child: Text(_l10n.t('backToHome'),
                                style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w700, color: context.wearth.textPrimary))),
                          ),
                        )),
                        const SizedBox(width: 12),
                        Expanded(child: GestureDetector(
                          onTap: _rematchSent ? null : _onRematchTap,
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            decoration: BoxDecoration(
                              color: _rematchSent ? accent.withAlpha(8) : accent.withAlpha(20),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: accent.withAlpha(50)),
                            ),
                            child: Center(child: Text(
                                _rematchSent ? _l10n.t('rematchSent') : _l10n.t('rematch'),
                                style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w700, color: accent))),
                          ),
                        )),
                      ]),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _playerStat(String name, String stat, bool? solved, Color color) {
    return Column(
      children: [
        Text(name, overflow: TextOverflow.ellipsis,
            style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w700, color: color)),
        const SizedBox(height: 2),
        Text(stat, style: GoogleFonts.outfit(fontSize: 12, color: context.wearth.textSecondary)),
        Text(solved == true ? _l10n.t('solved') : _l10n.t('notSolved'),
            style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.w600,
                color: solved == true ? const Color(0xFF10B981) : const Color(0xFFEF4444))),
      ],
    );
  }
}
