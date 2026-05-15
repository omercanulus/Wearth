import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../l10n/app_localizations.dart';
import '../services/storage_service.dart';
import '../data/world_data.dart';
import '../models/continent.dart';
import '../services/life_service.dart';
import 'classic_game_screen.dart';
import '../services/social_service.dart';
import 'friends_screen.dart';
import '../widgets/profile_card.dart';
import 'dart:async';

class ClassicMapScreen extends StatefulWidget {
  const ClassicMapScreen({super.key});

  @override
  State<ClassicMapScreen> createState() => _ClassicMapScreenState();
}

class _ClassicMapScreenState extends State<ClassicMapScreen> {
  final AppLocalizations _l10n = AppLocalizations();
  final StorageService _storage = StorageService();
  int _currentLevel = 10;
  bool _isLoading = true;
  List<UserProfile> _friends = [];
  StreamSubscription? _friendsSubscription;
  late Continent _visibleContinent;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _visibleContinent = WorldData.continents.first;
    _loadProgress();
    _listenToFriends();
  }

  void _listenToFriends() {
    _friendsSubscription = SocialService().listenFriends().listen((friends) {
      if (mounted) {
        setState(() => _friends = friends);
      }
    });
  }

  Future<void> _loadProgress() async {
    final level = await _storage.loadClassicLevel(locale: _l10n.currentLocale);
    setState(() {
      _currentLevel = level;
      _visibleContinent = WorldData.getContinentForLevel(_currentLevel);
      _isLoading = false;
    });

    // Firebase ile senkronize et
    SocialService().updateClassicLevel(level);
    
    // Yükleme bittikten sonra haritayı mevcut seviyeye kaydır
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToCurrentLevel(animate: false);
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _friendsSubscription?.cancel();
    super.dispose();
  }

  void _scrollToCurrentLevel({bool animate = true}) {
    if (!_scrollController.hasClients) return;
    double offset = 0.0;
    // reverse:true olduğu için alttan üste hesaplıyoruz
    for (int i = 1; i < _currentLevel; i++) {
      offset += _getItemHeight(i);
    }
    
    // Biraz aşağıda dursun diye -100 ekliyoruz
    final target = (offset - 100).clamp(0.0, _scrollController.position.maxScrollExtent);
    
    if (animate) {
      _scrollController.animateTo(
        target,
        duration: const Duration(milliseconds: 800),
        curve: Curves.easeInOutCubic,
      );
    } else {
      _scrollController.jumpTo(target);
    }
  }

  bool _onScroll(ScrollNotification notification) {
    // Estimate level based on scroll offset (pixels from bottom)
    // Average item height is ~150.
    int estimatedLevel = (notification.metrics.pixels / 150).floor() + 1;
    estimatedLevel = estimatedLevel.clamp(1, WorldData.totalLevels);
    
    final newContinent = WorldData.getContinentForLevel(estimatedLevel);
    if (_visibleContinent.id != newContinent.id) {
      setState(() {
        _visibleContinent = newContinent;
      });
    }
    return false;
  }

  double _getOffsetX(int level, double screenWidth) {
    return sin(level * 0.6) * (screenWidth * 0.25);
  }

  double _getItemHeight(int level) {
    if (level % 10 == 0) return 220.0; // Milestone every 10 levels
    return 140.0;
  }

  void _showFriendsBottomSheet(bool isLight) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.4,
        minChildSize: 0.2,
        maxChildSize: 0.8,
        expand: false,
        builder: (context, scrollController) => Container(
          decoration: BoxDecoration(
            color: isLight ? Colors.white : const Color(0xFF1F1A1B),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(50),
                blurRadius: 20,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isLight ? Colors.black12 : Colors.white12,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'ARKADAŞLARIN',
                      style: GoogleFonts.outfit(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.5,
                        color: isLight ? Colors.black87 : Colors.white,
                      ),
                    ),
                    _buildCircleBtn(Icons.person_add_alt_1_rounded, () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const FriendsScreen()),
                      );
                    }, isLight),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: _friends.isEmpty
                    ? Center(
                        child: Text(
                          'Henüz arkadaşın yok.',
                          style: GoogleFonts.outfit(color: isLight ? Colors.black38 : Colors.white38),
                        ),
                      )
                    : ListView.builder(
                        controller: scrollController,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _friends.length,
                        itemBuilder: (context, index) {
                          final friend = _friends[index];
                          return GestureDetector(
                            onTap: () => ProfileCard.show(context, friend),
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: isLight ? Colors.black.withAlpha(5) : Colors.white.withAlpha(5),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: isLight ? Colors.black.withAlpha(10) : Colors.white.withAlpha(10)),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 44,
                                    height: 44,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient: LinearGradient(
                                        colors: [
                                          Colors.primaries[friend.uid.hashCode % Colors.primaries.length],
                                          Colors.primaries[(friend.uid.hashCode + 1) % Colors.primaries.length],
                                        ],
                                      ),
                                    ),
                                    child: Center(
                                      child: Text(
                                        friend.username[0].toUpperCase(),
                                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          friend.username,
                                          style: GoogleFonts.outfit(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w700,
                                            color: isLight ? Colors.black87 : Colors.white,
                                          ),
                                        ),
                                        Text(
                                          'Seviye ${friend.classicLevel}',
                                          style: GoogleFonts.outfit(
                                            fontSize: 13,
                                            color: isLight ? Colors.black54 : Colors.white54,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF3B82F6).withAlpha(20),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      '${friend.classicLevel}. LVL',
                                      style: GoogleFonts.outfit(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w800,
                                        color: const Color(0xFF3B82F6),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final screenWidth = MediaQuery.of(context).size.width;
    final isLight = Theme.of(context).brightness == Brightness.light;

    // Theme colors
    final bgGradientColors = isLight
        ? [const Color(0xFFFDF8F5), const Color(0xFFEFE5E0), const Color(0xFFFDF8F5)]
        : [const Color(0xFF180A0A), const Color(0xFF381F21), const Color(0xFF180A0A)];
    
    final bgImageUrl = isLight ? _visibleContinent.lightBgUrl : _visibleContinent.darkBgUrl;

    return Scaffold(
      body: Stack(
        children: [
          // 1. Fallback Gradient Background
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: bgGradientColors,
              ),
            ),
          ),
          
          // 2. Dynamic Continent Background with AnimatedSwitcher
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 800),
            child: Container(
              key: ValueKey(_visibleContinent.id),
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: NetworkImage(bgImageUrl),
                  fit: BoxFit.cover,
                  colorFilter: ColorFilter.mode(
                    isLight ? Colors.white.withAlpha(150) : Colors.black.withAlpha(150),
                    isLight ? BlendMode.lighten : BlendMode.darken,
                  ),
                ),
              ),
            ),
          ),
          
          // 3. Scrolling Map
          SafeArea(
            child: NotificationListener<ScrollNotification>(
              onNotification: _onScroll,
              child: ListView.builder(
                controller: _scrollController,
                reverse: true,
                padding: const EdgeInsets.only(top: 120, bottom: 120),
                itemCount: WorldData.totalLevels,
                itemBuilder: (context, index) {
                  final level = index + 1;
                  final isCompleted = level < _currentLevel;
                  final isCurrent = level == _currentLevel;
                  final isLocked = level > _currentLevel;

                  final currentHeight = _getItemHeight(level);
                  final nextHeight = level < WorldData.totalLevels ? _getItemHeight(level + 1) : 0.0;

                  final currentOffsetX = _getOffsetX(level, screenWidth);
                  final nextOffsetX = level < WorldData.totalLevels ? _getOffsetX(level + 1, screenWidth) : 0.0;

                  return SizedBox(
                    height: currentHeight,
                    width: screenWidth,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        // Path to next node
                        if (level < WorldData.totalLevels)
                          Positioned.fill(
                            child: CustomPaint(
                              painter: PathPainter(
                                start: Offset(screenWidth / 2 + currentOffsetX, currentHeight / 2),
                                end: Offset(screenWidth / 2 + nextOffsetX, -nextHeight / 2),
                                isCompleted: isCompleted,
                                isLight: isLight,
                              ),
                            ),
                          ),
                        
                        // Node itself
                        Positioned.fill(
                          child: Center(
                            child: Transform.translate(
                              offset: Offset(currentOffsetX, 0),
                              child: Stack(
                                clipBehavior: Clip.none,
                                alignment: Alignment.center,
                                children: [
                                  GestureDetector(
                                    onTap: isLocked ? null : () {
                                      if (LifeService().lives <= 0) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text('${_l10n.t("noLives")} ${LifeService().formattedTimeUntilNext} ${_l10n.t("wait")}')),
                                        );
                                        return;
                                      }
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => ClassicGameScreen(level: level),
                                        ),
                                      ).then((_) => _loadProgress());
                                    },
                                    child: _buildNode(level, isCompleted, isCurrent, isLocked, isLight),
                                  ),
                                  
                                  // Arkadaşların avatarlarını göster
                                  ..._buildFriendAvatars(level, isLight),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),

          // Top Left Overlay: BACK BUTTON
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            left: 16,
            child: _buildCircleBtn(Icons.arrow_back_rounded, () => Navigator.pop(context), isLight),
          ),

          // Top Right Overlay: Pills
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            right: 16,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                ListenableBuilder(
                  listenable: LifeService(),
                  builder: (context, _) {
                    final lives = LifeService().lives;
                    final text = lives > 0 ? '$lives' : LifeService().formattedTimeUntilNext;
                    return _buildPillBtn(Icons.favorite_border_rounded, Colors.pinkAccent, text, isLight);
                  },
                ),
                const SizedBox(height: 12),
                _buildPillBtn(Icons.diamond_outlined, Colors.lightBlueAccent, '500', isLight),
              ],
            ),
          ),

          // Bottom Overlay
          Positioned(
            bottom: MediaQuery.of(context).padding.bottom + 16,
            left: 16,
            right: 16,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    _buildCircleBtn(Icons.storefront_rounded, () {}, isLight),
                    const SizedBox(width: 12),
                    _buildCircleBtn(Icons.people_alt_outlined, () => _showFriendsBottomSheet(isLight), isLight),
                  ],
                ),
                _buildLargeMapBtn(isLight, _scrollToCurrentLevel),
              ],
            ),
          ),
          
          // Continent Label
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            left: 0,
            right: 0,
            child: Center(
              child: IgnorePointer(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: isLight ? Colors.white.withAlpha(200) : Colors.black.withAlpha(150),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _l10n.t(_visibleContinent.id).toUpperCase(),
                    style: GoogleFonts.outfit(
                      color: isLight ? Colors.black87 : Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
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
  List<Widget> _buildFriendAvatars(int level, bool isLight) {
    final friendsAtThisLevel = _friends.where((f) => f.classicLevel == level).toList();
    if (friendsAtThisLevel.isEmpty) return [];

    return [
      Positioned(
        right: -30,
        child: SizedBox(
          width: 32,
          height: 32,
          child: Stack(
            children: List.generate(friendsAtThisLevel.length.clamp(0, 3), (i) {
              final friend = friendsAtThisLevel[i];
              return Positioned(
                left: i * 8.0,
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 1.5),
                    color: Colors.primaries[friend.uid.hashCode % Colors.primaries.length],
                  ),
                  child: Center(
                    child: Text(
                      friend.username[0].toUpperCase(),
                      style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      )
    ];
  }

  Widget _buildNode(int level, bool isCompleted, bool isCurrent, bool isLocked, bool isLight) {
    if (level % 10 == 0) {
      return _buildMilestoneNode(level, isLocked, isLight);
    }
    
    if (isCurrent) {
      return _buildCurrentNode(level, isLight);
    } else if (isCompleted) {
      return _buildCompletedNode(level, isLight);
    } else {
      return _buildLockedNode(level, isLight);
    }
  }

  Widget _buildCompletedNode(int level, bool isLight) {
    final color = isLight ? const Color(0xFF68C291) : const Color(0xFF9DE0BB);
    final textColor = isLight ? Colors.black54 : Colors.white54;
    
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: color.withAlpha(100),
                blurRadius: 20,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Icon(Icons.check_rounded, color: isLight ? Colors.white : Colors.black87, size: 28),
        ),
        const SizedBox(height: 8),
        Text(
          'LVL $level',
          style: GoogleFonts.outfit(
            color: textColor,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildCurrentNode(int level, bool isLight) {
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: [
        // Outer glowing ring
        Container(
          width: 96,
          height: 96,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFFD6777D).withAlpha(50), width: 2),
          ),
        ),
        // Main button
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              colors: [Color(0xFFEAA2A6), Color(0xFFA14953)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFA14953).withAlpha(150),
                blurRadius: 24,
                spreadRadius: 4,
              ),
            ],
          ),
          child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 36),
        ),
        // Current Level Tag
        Positioned(
          top: -15,
          left: -40,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF8A303B),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFD6777D).withAlpha(100), width: 1),
              boxShadow: isLight ? [const BoxShadow(color: Colors.black12, blurRadius: 4)] : null,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 4,
                  height: 4,
                  decoration: const BoxDecoration(
                    color: Colors.white70,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  _l10n.t('currentLevel'),
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    height: 1.1,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLockedNode(int level, bool isLight) {
    final bgColor = isLight ? Colors.white : const Color(0xFF2A2021);
    final borderColor = isLight ? Colors.black12 : Colors.white12;
    final iconColor = isLight ? Colors.black26 : Colors.white24;
    final textColor = isLight ? Colors.black38 : Colors.white24;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: bgColor,
            shape: BoxShape.circle,
            border: Border.all(color: borderColor, width: 2),
            boxShadow: isLight ? [const BoxShadow(color: Colors.black12, blurRadius: 8)] : null,
          ),
          child: Icon(Icons.lock_rounded, color: iconColor, size: 20),
        ),
        const SizedBox(height: 8),
        Text(
          'LVL $level',
          style: GoogleFonts.outfit(
            color: textColor,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildMilestoneNode(int level, bool isLocked, bool isLight) {
    final city = WorldData.getCityUnlockedAt(level);
    final continent = WorldData.getContinentForLevel(level);
    
    // In production, each city would have its own image. Here we use the continent bg as a placeholder.
    final String imageUrl = isLight ? continent.lightBgUrl : continent.darkBgUrl;

    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              boxShadow: isLight ? [const BoxShadow(color: Colors.black12, blurRadius: 10)] : null,
              image: DecorationImage(
                image: NetworkImage(imageUrl),
                fit: BoxFit.cover,
                colorFilter: ColorFilter.mode(
                  isLight 
                    ? Colors.white.withAlpha(isLocked ? 180 : 50)
                    : Colors.black.withAlpha(isLocked ? 180 : 80),
                  isLight ? BlendMode.lighten : BlendMode.darken,
                ),
              ),
            ),
          ),
        ),
        if (isLocked)
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isLight ? Colors.black12 : Colors.white.withAlpha(20),
                  border: Border.all(color: isLight ? Colors.black26 : Colors.white24, width: 1),
                ),
                child: Icon(Icons.lock_rounded, color: isLight ? Colors.black54 : Colors.white70, size: 24),
              ),
              const SizedBox(height: 8),
              Text(
                'LVL $level',
                style: GoogleFonts.outfit(
                  color: isLight ? Colors.black54 : Colors.white54,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
            ],
          )
        else
          Positioned(
            bottom: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: isLight ? Colors.white.withAlpha(200) : Colors.black.withAlpha(150),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${_l10n.t(continent.id)} ${_l10n.t("city")} ${level ~/ 10}',
                style: GoogleFonts.outfit(
                  color: isLight ? Colors.black87 : Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
      ],
    );
  }

  // UI Components for Overlays

  Widget _buildCircleBtn(IconData icon, VoidCallback onTap, bool isLight) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: isLight ? Colors.white : const Color(0xFF1F1A1B),
          shape: BoxShape.circle,
          boxShadow: isLight ? [const BoxShadow(color: Colors.black12, blurRadius: 8)] : null,
        ),
        child: Icon(icon, color: isLight ? Colors.black87 : Colors.white70, size: 22),
      ),
    );
  }

  Widget _buildLargeMapBtn(bool isLight, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          color: isLight ? Colors.white : const Color(0xFF2B313F),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: isLight ? Colors.black12 : Colors.black.withAlpha(100),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Icon(Icons.map_outlined, color: isLight ? const Color(0xFF4A75C2) : const Color(0xFF8BA5D2), size: 28),
      ),
    );
  }

  Widget _buildPillBtn(IconData icon, Color iconColor, String text, bool isLight) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: isLight ? Colors.white : const Color(0xFF1F1A1B),
        borderRadius: BorderRadius.circular(24),
        boxShadow: isLight ? [const BoxShadow(color: Colors.black12, blurRadius: 8)] : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: iconColor, size: 18),
          const SizedBox(width: 8),
          Text(
            text,
            style: GoogleFonts.outfit(
              color: isLight ? Colors.black87 : Colors.white70,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// Painter for the dashed line
class PathPainter extends CustomPainter {
  final Offset start;
  final Offset end;
  final bool isCompleted;
  final bool isLight;

  PathPainter({required this.start, required this.end, required this.isCompleted, required this.isLight});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = isCompleted 
          ? (isLight ? Colors.black54 : Colors.white54)
          : (isLight ? Colors.black12 : Colors.white24)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = ui.Path();
    path.moveTo(start.dx, start.dy);

    final controlPoint1 = Offset(start.dx, start.dy - (start.dy - end.dy).abs() / 2);
    final controlPoint2 = Offset(end.dx, end.dy + (start.dy - end.dy).abs() / 2);
    
    path.cubicTo(
      controlPoint1.dx, controlPoint1.dy,
      controlPoint2.dx, controlPoint2.dy,
      end.dx, end.dy,
    );

    final dashWidth = 8.0;
    final dashSpace = 8.0;
    double distance = 0.0;
    
    for (ui.PathMetric pathMetric in path.computeMetrics()) {
      while (distance < pathMetric.length) {
        canvas.drawPath(
          pathMetric.extractPath(distance, distance + dashWidth),
          paint,
        );
        distance += dashWidth + dashSpace;
      }
      distance = 0.0;
    }
  }

  @override
  bool shouldRepaint(covariant PathPainter oldDelegate) {
    return oldDelegate.start != start ||
           oldDelegate.end != end ||
           oldDelegate.isCompleted != isCompleted ||
           oldDelegate.isLight != isLight;
  }
}
