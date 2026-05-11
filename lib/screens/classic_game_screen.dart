import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../l10n/app_localizations.dart';
import '../services/word_service.dart';
import '../services/storage_service.dart';
import '../models/game_state.dart';
import '../theme/app_theme.dart';
import '../data/world_data.dart';
import '../models/continent.dart';
import '../models/city.dart';
import '../services/life_service.dart';

class ClassicGameScreen extends StatefulWidget {
  final int level;

  const ClassicGameScreen({super.key, required this.level});

  @override
  State<ClassicGameScreen> createState() => _ClassicGameScreenState();
}

class _ClassicGameScreenState extends State<ClassicGameScreen> {
  final AppLocalizations _l10n = AppLocalizations();
  final WordService _wordService = WordService();

  late GameState _gameState;
  String _currentInput = '';
  String _message = '';
  bool _showMessage = false;
  late Continent _continent;

  @override
  void initState() {
    super.initState();
    _continent = WorldData.getContinentForLevel(widget.level);
    _initGame();
  }

  void _initGame() {
    final locale = _l10n.currentLocale;
    final targetWord = _wordService.getWordForLevel(locale: locale, level: widget.level);

    _gameState = GameState(
      mode: GameMode.classic,
      targetWord: targetWord,
      locale: locale,
    );
  }

  // ─── Oyun Mantığı ──────────────────────────────────────────────

  void _onKeyPressed(String key) {
    if (_gameState.isGameOver) return;

    setState(() {
      if (key == 'BACKSPACE') {
        if (_currentInput.isNotEmpty) {
          _currentInput = _currentInput.substring(0, _currentInput.length - 1);
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

    setState(() {
      _gameState.addGuess(guess, results);
      _currentInput = '';
    });

    if (_gameState.isGameOver) {
      if (_gameState.status == GameStatus.won) {
        // İlerlemeyi kaydet
        final currentMax = await StorageService().loadClassicLevel(locale: _gameState.locale);
        if (widget.level >= currentMax) {
          await StorageService().saveClassicLevel(locale: _gameState.locale, level: widget.level + 1);
        }
        
        // Yıldız hesabı (1-6 tahmin = 3-1 yıldız)
        int stars = 1;
        if (_gameState.currentAttempt <= 3) stars = 3;
        else if (_gameState.currentAttempt <= 5) stars = 2;
        
        await StorageService().saveLevelStars(locale: _gameState.locale, level: widget.level, stars: stars);
        
        _showLevelCompleteDialog(stars);
      } else {
        await LifeService().consumeLife();
        _showLevelFailedDialog();
      }
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

  // ─── Dialoglar ──────────────────────────────────────────────────

  void _showLevelCompleteDialog(int stars) {
    final isMilestone = widget.level % 10 == 0;
    final City? city = isMilestone ? WorldData.getCityUnlockedAt(widget.level) : null;
    final isLight = Theme.of(context).brightness == Brightness.light;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          insetPadding: const EdgeInsets.symmetric(horizontal: 20),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: isLight ? Colors.white.withAlpha(230) : const Color(0xFF1E2433).withAlpha(230),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: isLight ? Colors.white : Colors.white24, width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(100),
                  blurRadius: 30,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Yıldızlar
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(3, (index) {
                    final isActive = index < stars;
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Icon(
                        Icons.star_rounded,
                        size: isActive ? 48 : 40,
                        color: isActive ? Colors.amber : (isLight ? Colors.black12 : Colors.white24),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 16),
                Text(
                  _l10n.t('levelComplete'),
                  style: GoogleFonts.outfit(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF4CAF50),
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 24),
                
                // Şehir Keşfedildi Bildirimi
                if (isMilestone && city != null) ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2196F3).withAlpha(30),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFF2196F3).withAlpha(100)),
                    ),
                    child: Column(
                      children: [
                        const Icon(Icons.public_rounded, color: Color(0xFF2196F3), size: 36),
                        const SizedBox(height: 8),
                        Text(
                          _l10n.t('unlockedCity').toUpperCase(),
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF2196F3),
                          ),
                        ),
                        Text(
                          '${_l10n.t(_continent.id)} ${_l10n.t("city")} ${widget.level ~/ 10}',
                          style: GoogleFonts.outfit(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: isLight ? Colors.black87 : Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                // Ödüller
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.diamond_rounded, color: Colors.lightBlueAccent, size: 24),
                    const SizedBox(width: 8),
                    Text(
                      '+10',
                      style: GoogleFonts.outfit(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: isLight ? Colors.black87 : Colors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                // Butonlar
                Row(
                  children: [
                    Expanded(
                      child: _buildDialogBtn(
                        icon: Icons.map_rounded,
                        label: _l10n.t('map'),
                        color: Colors.grey,
                        onTap: () {
                          Navigator.pop(context); // close dialog
                          Navigator.pop(context); // go back to map
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: _buildDialogBtn(
                        icon: Icons.play_arrow_rounded,
                        label: _l10n.t('next'),
                        color: const Color(0xFF4CAF50),
                        onTap: () {
                          Navigator.pop(context); // close dialog
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ClassicGameScreen(level: widget.level + 1),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showLevelFailedDialog() {
    final isLight = Theme.of(context).brightness == Brightness.light;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          insetPadding: const EdgeInsets.symmetric(horizontal: 20),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: isLight ? Colors.white.withAlpha(230) : const Color(0xFF1E2433).withAlpha(230),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: isLight ? Colors.white : Colors.white24, width: 1.5),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.heart_broken_rounded, color: Colors.pinkAccent, size: 56),
                const SizedBox(height: 16),
                Text(
                  _l10n.t('levelFailed'),
                  style: GoogleFonts.outfit(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: Colors.pinkAccent,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: _buildDialogBtn(
                        icon: Icons.map_rounded,
                        label: _l10n.t('map'),
                        color: Colors.grey,
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.pop(context);
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: _buildDialogBtn(
                        icon: Icons.refresh_rounded,
                        label: _l10n.t('retry'),
                        color: Colors.pinkAccent,
                        onTap: () {
                          Navigator.pop(context);
                          setState(() {
                            _initGame();
                          });
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDialogBtn({required IconData icon, required String label, required Color color, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: color.withAlpha(40),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withAlpha(150), width: 1),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.outfit(
                color: color,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Arayüz ────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    final bgImageUrl = isLight ? _continent.lightBgUrl : _continent.darkBgUrl;

    return Scaffold(
      backgroundColor: isLight ? Colors.white : Colors.black,
      body: Stack(
        children: [
          // Background Continent Image with heavy blur
          Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: NetworkImage(bgImageUrl),
                fit: BoxFit.cover,
                colorFilter: ColorFilter.mode(
                  isLight ? Colors.white.withAlpha(200) : Colors.black.withAlpha(180),
                  isLight ? BlendMode.lighten : BlendMode.darken,
                ),
              ),
            ),
          ),
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
            child: Container(color: Colors.transparent),
          ),

          SafeArea(
            child: Column(
              children: [
                _buildTopBar(isLight),
                _buildMessageBanner(),
                
                const SizedBox(height: 16),
                Expanded(
                  flex: 3,
                  child: Center(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: _buildGuessGrid(),
                    ),
                  ),
                ),

                if (!_gameState.isGameOver)
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: _buildKeyboard(),
                  ),
                  
                const SizedBox(height: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar(bool isLight) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Geri butonu
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isLight ? Colors.white.withAlpha(150) : Colors.black.withAlpha(100),
                shape: BoxShape.circle,
                border: Border.all(color: isLight ? Colors.black12 : Colors.white24),
              ),
              child: Icon(Icons.arrow_back_rounded, size: 20, color: isLight ? Colors.black87 : Colors.white),
            ),
          ),
          
          // Seviye Başlığı
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${_l10n.t('level').toUpperCase()} ${widget.level}',
                style: GoogleFonts.outfit(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2.0,
                  color: isLight ? Colors.black87 : Colors.white,
                ),
              ),
              Text(
                _l10n.t(_continent.id).toUpperCase(),
                style: GoogleFonts.outfit(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 3.0,
                  color: (isLight ? Colors.black54 : Colors.white54),
                ),
              ),
            ],
          ),

          // Kalp
          ListenableBuilder(
            listenable: LifeService(),
            builder: (context, _) {
              final lives = LifeService().lives;
              final text = lives > 0 ? '$lives' : LifeService().formattedTimeUntilNext;
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isLight ? Colors.white.withAlpha(150) : Colors.black.withAlpha(100),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: isLight ? Colors.black12 : Colors.white24),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.favorite_rounded, color: Colors.pinkAccent, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      text,
                      style: GoogleFonts.outfit(
                        color: isLight ? Colors.black87 : Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              );
            }
          ),
        ],
      ),
    );
  }

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

  Widget _buildGuessGrid() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(6, (row) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
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

    final isLight = Theme.of(context).brightness == Brightness.light;
    Color tileColor;
    Color borderColor;
    Color textColor;

    if (result != null) {
      switch (result) {
        case LetterResult.correct:
          tileColor = const Color(0xFF4CAF50).withAlpha(isLight ? 150 : 60);
          borderColor = const Color(0xFF4CAF50);
          textColor = isLight ? Colors.white : const Color(0xFF4CAF50);
          break;
        case LetterResult.present:
          tileColor = const Color(0xFFFFC107).withAlpha(isLight ? 150 : 60);
          borderColor = const Color(0xFFFFC107);
          textColor = isLight ? Colors.white : const Color(0xFFFFC107);
          break;
        case LetterResult.absent:
          tileColor = isLight ? Colors.black.withAlpha(20) : Colors.white.withAlpha(20);
          borderColor = isLight ? Colors.black12 : Colors.white24;
          textColor = isLight ? Colors.black38 : Colors.white54;
          break;
      }
    } else {
      tileColor = letter.isNotEmpty ? (isLight ? Colors.white.withAlpha(200) : Colors.white.withAlpha(40)) : (isLight ? Colors.white.withAlpha(100) : Colors.black.withAlpha(40));
      borderColor = letter.isNotEmpty ? (isLight ? Colors.black26 : Colors.white54) : (isLight ? Colors.black12 : Colors.white24);
      textColor = isLight ? Colors.black87 : Colors.white;
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          width: 58,
          height: 62,
          decoration: BoxDecoration(
            color: tileColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor, width: 1.5),
            boxShadow: [
              if (result != null && result != LetterResult.absent)
                BoxShadow(color: borderColor.withAlpha(100), blurRadius: 10, offset: const Offset(0, 2)),
            ],
          ),
          child: Center(
            child: AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: GoogleFonts.outfit(
                fontSize: 28,
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

  Widget _buildKeyboard() {
    final rows = _getKeyboardLayout();
    final keyStates = _gameState.keyboardStates;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        children: rows.map((row) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 3),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: row.map((key) {
                final isSpecial = key == 'ENTER' || key == 'BACKSPACE';
                final width = isSpecial ? 52.0 : 32.0;

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2.5),
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
    final isLight = Theme.of(context).brightness == Brightness.light;
    final isSpecial = key == 'ENTER' || key == 'BACKSPACE';

    Color bgColor;
    Color textColor;
    Color borderColor;

    if (result != null) {
      switch (result) {
        case LetterResult.correct:
          bgColor = const Color(0xFF4CAF50);
          textColor = Colors.white;
          borderColor = const Color(0xFF4CAF50);
          break;
        case LetterResult.present:
          bgColor = const Color(0xFFFFC107);
          textColor = Colors.white;
          borderColor = const Color(0xFFFFC107);
          break;
        case LetterResult.absent:
          bgColor = isLight ? Colors.black12 : Colors.white12;
          textColor = isLight ? Colors.black38 : Colors.white38;
          borderColor = Colors.transparent;
          break;
      }
    } else {
      bgColor = isLight ? Colors.white.withAlpha(200) : Colors.white.withAlpha(30);
      textColor = isLight ? Colors.black87 : Colors.white;
      borderColor = isLight ? Colors.black12 : Colors.white24;
    }

    String displayText = key;
    IconData? icon;

    if (key == 'ENTER') {
      icon = Icons.check_rounded;
      displayText = '';
    } else if (key == 'BACKSPACE') {
      icon = Icons.backspace_rounded;
      displayText = '';
    }

    return GestureDetector(
      onTap: () => _onKeyPressed(key),
      child: Container(
        width: width,
        height: 48,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor, width: 1),
          boxShadow: [
            if (result == null && isLight) const BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
          ],
        ),
        child: Center(
          child: icon != null
              ? Icon(icon, size: 20, color: textColor)
              : Text(
                  displayText,
                  style: GoogleFonts.outfit(
                    fontSize: isSpecial ? 12 : 15,
                    fontWeight: FontWeight.bold,
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
}
