import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui';
import '../l10n/app_localizations.dart';
import '../services/word_service.dart';
import '../services/storage_service.dart';
import '../models/game_state.dart';
import '../theme/app_theme.dart';

/// Günün Kelimesi oyun ekranı.
/// Yuvarlak liquid glass harf kutucukları ve
/// dil bazlı klavye ile Wordle deneyimi sunar.
class DailyGameScreen extends StatefulWidget {
  const DailyGameScreen({super.key});

  @override
  State<DailyGameScreen> createState() => _DailyGameScreenState();
}

class _DailyGameScreenState extends State<DailyGameScreen> {
  final AppLocalizations _l10n = AppLocalizations();
  final WordService _wordService = WordService();

  late GameState _gameState;
  String _currentInput = '';
  String _message = '';
  bool _showMessage = false;
  int _currentStreak = 0;

  @override
  void initState() {
    super.initState();
    _initGame();
  }

  void _initGame() {
    final locale = _l10n.currentLocale;
    final targetWord = _wordService.getDailyWord(locale: locale);

    _gameState = GameState(
      mode: GameMode.daily,
      targetWord: targetWord,
      locale: locale,
      dailyNumber: _wordService.getDailyWordNumber(),
    );

    _loadProgress();
  }

  Future<void> _loadProgress() async {
    final todayStr = DateTime.now().toIso8601String().split('T').first;
    final progress = await StorageService().loadDailyProgress(
      locale: _gameState.locale,
      date: todayStr,
    );

    final stats = await StorageService().loadStats(locale: _gameState.locale);

    if (mounted) {
      setState(() {
        _currentStreak = stats.currentStreak;
        if (progress != null) {
          final savedGuesses = (progress['guesses'] as List).cast<String>();
          for (final guess in savedGuesses) {
            final results = _wordService.evaluateGuess(
              guess: guess,
              target: _gameState.targetWord,
            );
            _gameState.addGuess(guess, results);
          }
        }
      });
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  // ─── Oyun Mantığı ──────────────────────────────────────────────

  void _onKeyPressed(String key) {
    if (_gameState.isGameOver) return;

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
      _shakeCurrentRow();
      return;
    }

    final guess = _currentInput.toUpperCase();

    // Geçerli kelime kontrolü
    if (!_wordService.isValidWord(guess, _gameState.locale)) {
      _showTemporaryMessage(_l10n.t('invalidWord'));
      _shakeCurrentRow();
      return;
    }

    // Harfleri değerlendir
    final results = _wordService.evaluateGuess(
      guess: guess,
      target: _gameState.targetWord,
    );

    setState(() {
      _gameState.addGuess(guess, results);
      _currentInput = '';
    });

    // İlerlemeyi kaydet
    final todayStr = DateTime.now().toIso8601String().split('T').first;
    await StorageService().saveDailyProgress(
      locale: _gameState.locale,
      date: todayStr,
      guesses: _gameState.guesses.map((e) => e.word).toList(),
      solved: _gameState.status == GameStatus.won,
    );

    // Oyun bittiyse istatistikleri güncelle
    if (_gameState.isGameOver) {
      final stats = await StorageService().loadStats(locale: _gameState.locale);
      stats.addResult(
        won: _gameState.status == GameStatus.won,
        attempts: _gameState.currentAttempt,
      );
      await StorageService().saveStats(locale: _gameState.locale, stats: stats);
      
      // UI üzerinde seri değerini anında güncelle
      if (mounted) {
        setState(() {
          _currentStreak = stats.currentStreak;
        });
        
        // Popup şeklinde tebrikler / oyun bitti mesajını göster
        _showGameOverDialog();
      }
    }
  }

  void _showGameOverDialog() {
    showDialog(
      context: context,
      barrierDismissible: true, // Kullanıcı dışarı tıklayarak kapatabilsin
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          insetPadding: const EdgeInsets.symmetric(horizontal: 16),
          child: _buildGameOverBanner(),
        );
      },
    );
  }

  void _shakeCurrentRow() {
    // Şimdilik sadece mesaj gösteriyoruz
    // İleride animasyon eklenebilir
  }

  void _showTemporaryMessage(String msg) {
    setState(() {
      _message = msg;
      _showMessage = true;
    });

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() => _showMessage = false);
      }
    });
  }

  // ─── Arayüz ────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.wearth.scaffoldBg,
      body: SafeArea(
        child: Column(
          children: [
            // Üst bar
            _buildTopBar(),

            // Mesaj bildirimi
            _buildMessageBanner(),

            // Tahmin grid'i (Biraz daha boşluk ekleyerek aşağı alıyoruz)
            const SizedBox(height: 16),
            Expanded(
              flex: 3, // Izgaraya daha fazla alan
              child: Center(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: _buildGuessGrid(),
                ),
              ),
            ),

            // Klavye (Sadece oyun devam ediyorsa veya bitmişse de klavye yerinde kalabilir, banner popup oldu)
            // Ama klavyeyi gizlemek istersen yine isGameOver kontrolü kalabilir. Şimdilik gizliyoruz.
            if (!_gameState.isGameOver) 
              FittedBox(
                fit: BoxFit.scaleDown,
                child: _buildKeyboard(),
              ),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  /// Üst bar: geri butonu + başlık
  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Geri butonu (liquid glass)
          Align(
            alignment: Alignment.centerLeft,
            child: GestureDetector(
              onTap: () => Navigator.of(context).pop(),
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
          
          // Oyun Modu Başlığı
          Text(
            _l10n.t('dailyWordTitle').toUpperCase(),
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

  /// Bildirim mesajı
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

  /// Tahmin grid'i — 6 satır × 5 yuvarlak harf kutucuğu
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

  /// Tek bir yuvarlak liquid glass harf kutucuğu
  Widget _buildLetterTile(int row, int col) {
    String letter = '';
    LetterResult? result;

    if (row < _gameState.currentAttempt) {
      // Önceki tahminler
      final guess = _gameState.guesses[row];
      letter = guess.word[col];
      result = guess.results[col];
    } else if (row == _gameState.currentAttempt) {
      // Şu anki giriş satırı
      if (col < _currentInput.length) {
        letter = _currentInput[col];
      }
    }

    // Renk belirleme
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
          tileColor = const Color(0xFFFFC107).withAlpha(45);
          borderColor = const Color(0xFFFFC107).withAlpha(100);
          textColor = const Color(0xFFF57F17);
          break;
        case LetterResult.absent:
          tileColor = const Color(0xFF9CA3AF).withAlpha(35);
          borderColor = const Color(0xFF9CA3AF).withAlpha(70);
          textColor = const Color(0xFF6B7280);
          break;
      }
    } else {
      // Boş veya aktif kutucuk — hafif gri border ile görünür
      tileColor = letter.isNotEmpty
          ? context.wearth.tileActive
          : context.wearth.tileEmpty;
      borderColor = letter.isNotEmpty
          ? context.wearth.tileActiveBorder
          : context.wearth.tileEmptyBorder;
      textColor = context.wearth.textPrimary;
    }

    final size = MediaQuery.of(context).size.width / 7.5; // Bir miktar küçültüldü
    final tileSize = size.clamp(48.0, 62.0); // Kutu boyut aralığı hafif düşürüldü

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
            border: Border.all(
              color: borderColor,
              width: 1.0,
            ),
            boxShadow: [
              if (result != null)
                BoxShadow(
                  color: borderColor.withAlpha(20),
                  blurRadius: 12,
                  spreadRadius: 0,
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

  /// Oyun bitti bildirimi
  Widget _buildGameOverBanner() {
    final won = _gameState.status == GameStatus.won;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            decoration: BoxDecoration(
              color: context.wearth.glassBackgroundStrong,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: (won ? const Color(0xFF4CAF50) : const Color(0xFFEF4444))
                    .withAlpha(60),
                width: 0.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: (won
                          ? const Color(0xFF4CAF50)
                          : const Color(0xFFEF4444))
                      .withAlpha(15),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                Icon(
                  won ? Icons.celebration_rounded : Icons.sentiment_dissatisfied_rounded,
                  size: 36,
                  color: won
                      ? const Color(0xFF4CAF50)
                      : const Color(0xFFEF4444),
                ),
                const SizedBox(height: 8),
                Text(
                  won
                      ? _l10n.t('congratulations')
                      : _l10n.t('gameOver'),
                  style: GoogleFonts.outfit(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: won
                        ? const Color(0xFF2E7D32)
                        : const Color(0xFFB71C1C),
                  ),
                ),
                const SizedBox(height: 4),
                if (won)
                  Text(
                    '${_l10n.t('attempt')}: ${_gameState.currentAttempt}/6',
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: context.wearth.textMuted,
                    ),
                  ),
                if (!won) ...[
                  Text(
                    '${_l10n.t('correctWord')} ${_gameState.targetWord}',
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: context.wearth.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _l10n.t('tryAgainTomorrow'),
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      color: context.wearth.textMuted,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─── Klavye ─────────────────────────────────────────────────────

  /// Dil bazlı klavye
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
                final isSpecial =
                    key == 'ENTER' || key == 'BACKSPACE';
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

  /// Tek bir klavye tuşu
  Widget _buildKeyboardKey({
    required String key,
    required double width,
    LetterResult? result,
  }) {
    final isSpecial = key == 'ENTER' || key == 'BACKSPACE';

    // Tuş renkleri
    Color bgColor;
    Color textColor;

    if (result != null) {
      switch (result) {
        case LetterResult.correct:
          bgColor = const Color(0xFF4CAF50).withAlpha(40);
          textColor = const Color(0xFF2E7D32);
          break;
        case LetterResult.present:
          bgColor = const Color(0xFFFFC107).withAlpha(40);
          textColor = const Color(0xFFF57F17);
          break;
        case LetterResult.absent:
          bgColor = context.wearth.glassBackgroundStrong;
          textColor = context.wearth.keyTextDisabled;
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

  /// Dil bazlı klavye düzeni
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
}
