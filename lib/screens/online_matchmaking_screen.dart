import 'dart:async';
import 'dart:ui';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/matchmaking_service.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../l10n/app_localizations.dart';
import 'online_game_screen.dart';

/// Online mod eşleşme arama ekranı.
/// Rakip bulunana kadar animasyonlu bekleme gösterir.
class OnlineMatchmakingScreen extends StatefulWidget {
  const OnlineMatchmakingScreen({super.key});

  @override
  State<OnlineMatchmakingScreen> createState() =>
      _OnlineMatchmakingScreenState();
}

class _OnlineMatchmakingScreenState extends State<OnlineMatchmakingScreen>
    with TickerProviderStateMixin {
  final MatchmakingService _matchmaking = MatchmakingService();
  final AppLocalizations _l10n = AppLocalizations();

  late AnimationController _pulseController;
  late AnimationController _rotateController;
  late Animation<double> _pulseAnimation;

  bool _isSearching = false;
  bool _matchFound = false;
  String _statusText = '';
  StreamSubscription<MatchData?>? _matchSub;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _rotateController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();

    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.08).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Otomatik eşleşme aramayı başlat
    _startSearching();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _rotateController.dispose();
    _matchSub?.cancel();
    super.dispose();
  }

  Future<void> _startSearching() async {
    if (!AuthService().isLoggedIn) {
      setState(() => _statusText = 'Lütfen önce giriş yapın');
      return;
    }

    setState(() {
      _isSearching = true;
      _statusText = 'Rakip aranıyor...';
    });

    try {
      final matchId = await _matchmaking.findOrCreateMatch(mode: 'quick');

      // Maçı dinlemeye başla
      _matchSub = _matchmaking.listenToMatch(matchId).listen((matchData) {
        if (matchData == null) return;

        if (matchData.status == MatchStatus.playing && !_matchFound) {
          setState(() {
            _matchFound = true;
            _statusText = 'Rakip bulundu!';
          });

          // Kısa animasyon sonrası oyun ekranına geç
          Future.delayed(const Duration(milliseconds: 1200), () {
            if (mounted) {
              _matchSub?.cancel();
              Navigator.of(context).pushReplacement(
                PageRouteBuilder(
                  pageBuilder: (_, __, ___) =>
                      OnlineGameScreen(matchId: matchId),
                  transitionsBuilder: (_, anim, __, child) {
                    return FadeTransition(opacity: anim, child: child);
                  },
                  transitionDuration: const Duration(milliseconds: 400),
                ),
              );
            }
          });
        }
      });
    } catch (e) {
      debugPrint('🔴 Matchmaking hatası: $e');
      if (mounted) {
        setState(() {
          _isSearching = false;
          _statusText = 'Hata: $e';
        });
      }
    }
  }

  Future<void> _cancelSearch() async {
    _matchSub?.cancel();
    await _matchmaking.leaveMatch();
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.wearth.scaffoldBg,
      body: SafeArea(
        child: Column(
          children: [
            // Üst bar
            _buildTopBar(),

            // Ana içerik
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Animasyonlu arama görseli
                    _buildSearchAnimation(),

                    const SizedBox(height: 40),

                    // Durum metni
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: Text(
                        _statusText,
                        key: ValueKey(_statusText),
                        style: GoogleFonts.outfit(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: _matchFound
                              ? const Color(0xFF10B981)
                              : context.wearth.textPrimary,
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Alt bilgi
                    if (_isSearching && !_matchFound)
                      Text(
                        'Quick Mode • 1v1',
                        style: GoogleFonts.outfit(
                          fontSize: 14,
                          color: context.wearth.textVersion,
                        ),
                      ),

                    const SizedBox(height: 48),

                    // İptal butonu
                    if (_isSearching && !_matchFound)
                      _buildCancelButton(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: GestureDetector(
              onTap: _cancelSearch,
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
            'ÇEVRİMİÇİ MOD',
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

  Widget _buildSearchAnimation() {
    return SizedBox(
      width: 200,
      height: 200,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Dönen dış halka
          _RotatingRing(controller: _rotateController),

          // İç halka (nabız efekti)
          ScaleTransition(
            scale: _matchFound
                ? const AlwaysStoppedAnimation(1.2)
                : _pulseAnimation as Animation<double>,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(80),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 400),
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _matchFound
                        ? const Color(0xFF10B981).withAlpha(30)
                        : context.wearth.glassBackground,
                    border: Border.all(
                      color: _matchFound
                          ? const Color(0xFF10B981).withAlpha(100)
                          : context.wearth.glassBorder,
                      width: 1,
                    ),
                    boxShadow: [
                      if (_matchFound)
                        BoxShadow(
                          color: const Color(0xFF10B981).withAlpha(40),
                          blurRadius: 30,
                          spreadRadius: 5,
                        ),
                    ],
                  ),
                  child: Center(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: _matchFound
                          ? const Icon(
                              Icons.check_rounded,
                              key: ValueKey('found'),
                              size: 56,
                              color: Color(0xFF10B981),
                            )
                          : Icon(
                              Icons.search_rounded,
                              key: const ValueKey('search'),
                              size: 48,
                              color: context.wearth.textSecondary,
                            ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCancelButton() {
    return GestureDetector(
      onTap: _cancelSearch,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Colors.redAccent.withAlpha(15),
          border: Border.all(
            color: Colors.redAccent.withAlpha(40),
            width: 0.5,
          ),
        ),
        child: Text(
          'Aramayı İptal Et',
          style: GoogleFonts.outfit(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: Colors.redAccent.withAlpha(200),
          ),
        ),
      ),
    );
  }
}

/// Dönen gradient halka — AnimatedWidget pattern
class _RotatingRing extends AnimatedWidget {
  const _RotatingRing({required AnimationController controller})
      : super(listenable: controller);

  @override
  Widget build(BuildContext context) {
    final controller = listenable as AnimationController;
    return Transform.rotate(
      angle: controller.value * 2 * pi,
      child: Container(
        width: 180,
        height: 180,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: SweepGradient(
            colors: [
              const Color(0xFF10B981).withAlpha(0),
              const Color(0xFF10B981).withAlpha(80),
              const Color(0xFF06B6D4).withAlpha(120),
              const Color(0xFF8B5CF6).withAlpha(80),
              const Color(0xFF10B981).withAlpha(0),
            ],
          ),
        ),
      ),
    );
  }
}
