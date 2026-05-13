import 'dart:ui';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/auth_service.dart';
import '../services/storage_service.dart';
import '../l10n/app_localizations.dart';
import '../theme/app_theme.dart';
import '../data/world_data.dart';

class ProfileScreen extends StatefulWidget {
  final VoidCallback? onSignOut;
  const ProfileScreen({super.key, this.onSignOut});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with TickerProviderStateMixin {
  final AppLocalizations _l10n = AppLocalizations();
  final AuthService _auth = AuthService();
  final StorageService _storage = StorageService();

  late Future<Map<String, dynamic>> _profileData;
  late AnimationController _shimmerController;

  @override
  void initState() {
    super.initState();
    _profileData = _loadProfileData();
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  Future<Map<String, dynamic>> _loadProfileData() async {
    final locale = _l10n.currentLocale;
    final stats = await _storage.loadStats(locale: locale);
    final classicLevel = await _storage.loadClassicLevel(locale: locale);

    // Toplam yıldız hesapla
    int totalStars = 0;
    for (int i = 1; i < classicLevel; i++) {
      totalStars +=
          await _storage.loadLevelStars(locale: locale, level: i);
    }

    return {
      'stats': stats,
      'classicLevel': classicLevel,
      'totalStars': totalStars,
    };
  }

  String _getRankTitle(int level) {
    if (level >= 300) return 'Dünya Şampiyonu 🌍';
    if (level >= 200) return 'Kelime Ustası 🏆';
    if (level >= 100) return 'Kâşif ⭐';
    if (level >= 50) return 'Gezgin 🗺️';
    if (level >= 20) return 'Çırak 📖';
    return 'Yeni Başlayan 🌱';
  }

  Color _getRankColor(int level) {
    if (level >= 300) return const Color(0xFFFFD700);
    if (level >= 200) return const Color(0xFFE040FB);
    if (level >= 100) return const Color(0xFF00BCD4);
    if (level >= 50) return const Color(0xFF4CAF50);
    if (level >= 20) return const Color(0xFF2196F3);
    return const Color(0xFF9CA3AF);
  }

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: FutureBuilder<Map<String, dynamic>>(
        future: _profileData,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(
                color: const Color(0xFF4CAF50),
              ),
            );
          }

          final stats = snapshot.data!['stats'] as GameStats;
          final classicLevel = snapshot.data!['classicLevel'] as int;
          final totalStars = snapshot.data!['totalStars'] as int;
          final rankColor = _getRankColor(classicLevel);

          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              children: [
                // ── Hero Header ──────────────────────────────
                _buildHeroHeader(user, classicLevel, rankColor),

                // ── Content ──────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
                      const SizedBox(height: 24),

                      // Quick Stats Row
                      _buildQuickStatsRow(stats, classicLevel, totalStars),

                      const SizedBox(height: 24),

                      // Guess Distribution
                      _buildGuessDistribution(stats),

                      const SizedBox(height: 24),

                      // Level Progress
                      _buildLevelProgress(classicLevel),

                      const SizedBox(height: 24),

                      // Sign Out
                      _buildSignOutButton(),

                      const SizedBox(height: 120),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // HERO HEADER
  // ═══════════════════════════════════════════════════════════════

  Widget _buildHeroHeader(dynamic user, int level, Color rankColor) {
    final displayName = user?.displayName ??
        user?.email?.split('@')[0] ??
        'Explorer';
    final email = user?.email ?? '';

    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 30,
        bottom: 30,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            rankColor.withAlpha(40),
            context.wearth.scaffoldBg,
          ],
        ),
      ),
      child: Column(
        children: [
          // Avatar with glow
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  rankColor,
                  rankColor.withAlpha(100),
                  const Color(0xFF4CAF50),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: rankColor.withAlpha(60),
                  blurRadius: 24,
                  spreadRadius: 4,
                ),
              ],
            ),
            child: CircleAvatar(
              radius: 48,
              backgroundColor: context.wearth.scaffoldBg,
              backgroundImage: user?.photoURL != null
                  ? NetworkImage(user!.photoURL!)
                  : null,
              child: user?.photoURL == null
                  ? Text(
                      displayName[0].toUpperCase(),
                      style: GoogleFonts.outfit(
                        fontSize: 36,
                        fontWeight: FontWeight.w900,
                        color: rankColor,
                      ),
                    )
                  : null,
            ),
          ),
          const SizedBox(height: 16),

          // Username
          Text(
            displayName,
            style: GoogleFonts.outfit(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: context.wearth.textPrimary,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 4),

          // Email
          if (email.isNotEmpty)
            Text(
              email,
              style: GoogleFonts.outfit(
                fontSize: 13,
                color: context.wearth.textVersion,
              ),
            ),
          const SizedBox(height: 12),

          // Rank Badge
          AnimatedBuilder(
            animation: _shimmerController,
            builder: (context, child) {
              return Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: LinearGradient(
                    colors: [
                      rankColor.withAlpha(40),
                      rankColor.withAlpha(80),
                      rankColor.withAlpha(40),
                    ],
                    stops: [
                      0.0,
                      (0.5 + 0.5 * sin(_shimmerController.value * 2 * pi))
                          .clamp(0.0, 1.0),
                      1.0,
                    ],
                  ),
                  border: Border.all(
                    color: rankColor.withAlpha(60),
                    width: 1,
                  ),
                ),
                child: Text(
                  _getRankTitle(level),
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: rankColor,
                    letterSpacing: 0.5,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // QUICK STATS ROW
  // ═══════════════════════════════════════════════════════════════

  Widget _buildQuickStatsRow(
      GameStats stats, int classicLevel, int totalStars) {
    return Row(
      children: [
        Expanded(
          child: _buildMiniStat(
            '${stats.gamesPlayed}',
            'Oyun',
            Icons.videogame_asset_rounded,
            const Color(0xFF2196F3),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildMiniStat(
            '${stats.winPercentage.toInt()}%',
            'Kazanma',
            Icons.emoji_events_rounded,
            const Color(0xFFF59E0B),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildMiniStat(
            '${stats.maxStreak}',
            'En İyi Seri',
            Icons.local_fire_department_rounded,
            const Color(0xFFEF4444),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildMiniStat(
            '$totalStars',
            'Yıldız',
            Icons.star_rounded,
            const Color(0xFFE040FB),
          ),
        ),
      ],
    );
  }

  Widget _buildMiniStat(
      String value, String label, IconData icon, Color color) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: context.wearth.glassBackground,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: color.withAlpha(40),
              width: 0.5,
            ),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(height: 6),
              Text(
                value,
                style: GoogleFonts.outfit(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: context.wearth.textPrimary,
                ),
              ),
              Text(
                label,
                style: GoogleFonts.outfit(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: context.wearth.textVersion,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // GUESS DISTRIBUTION
  // ═══════════════════════════════════════════════════════════════

  Widget _buildGuessDistribution(GameStats stats) {
    final maxVal = stats.guessDistribution.reduce(max);

    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: context.wearth.glassBackground,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: context.wearth.glassBorder,
              width: 0.5,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.bar_chart_rounded,
                      color: const Color(0xFF4CAF50), size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Tahmin Dağılımı',
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: context.wearth.textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ...List.generate(6, (i) {
                final count = stats.guessDistribution[i];
                final ratio = maxVal > 0 ? count / maxVal : 0.0;

                // Her satıra farklı renk tonu — hızlı bulduysan sıcak, geç bulduysan soğuk
                final barColors = [
                  [const Color(0xFF10B981), const Color(0xFF34D399)], // 1. tahmin — zümrüt
                  [const Color(0xFF06B6D4), const Color(0xFF22D3EE)], // 2. tahmin — camgöbeği
                  [const Color(0xFF8B5CF6), const Color(0xFFA78BFA)], // 3. tahmin — mor
                  [const Color(0xFFF59E0B), const Color(0xFFFBBF24)], // 4. tahmin — amber
                  [const Color(0xFFF97316), const Color(0xFFFB923C)], // 5. tahmin — turuncu
                  [const Color(0xFFEF4444), const Color(0xFFF87171)], // 6. tahmin — kırmızı
                ];

                return Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: barColors[i][0].withAlpha(20),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${i + 1}',
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: barColors[i][0],
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Stack(
                            children: [
                              Container(
                                height: 28,
                                decoration: BoxDecoration(
                                  color:
                                      context.wearth.keyBackground.withAlpha(50),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              FractionallySizedBox(
                                widthFactor: max(ratio, 0.08),
                                child: Container(
                                  height: 28,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: barColors[i],
                                    ),
                                    borderRadius: BorderRadius.circular(10),
                                    boxShadow: [
                                      BoxShadow(
                                        color: barColors[i][0].withAlpha(40),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  alignment: Alignment.centerRight,
                                  padding:
                                      const EdgeInsets.symmetric(horizontal: 10),
                                  child: Text(
                                    '$count',
                                    style: GoogleFonts.outfit(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // LEVEL PROGRESS
  // ═══════════════════════════════════════════════════════════════

  Widget _buildLevelProgress(int classicLevel) {
    final continent = WorldData.getContinentForLevel(classicLevel);
    final totalLevels = WorldData.totalLevels;
    final progress = classicLevel / totalLevels;

    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: context.wearth.glassBackground,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: context.wearth.glassBorder,
              width: 0.5,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.public_rounded,
                      color: const Color(0xFF2196F3), size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Dünya Keşfi',
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: context.wearth.textPrimary,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    'Seviye $classicLevel / $totalLevels',
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: context.wearth.textVersion,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Progress bar
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Stack(
                  children: [
                    Container(
                      height: 10,
                      decoration: BoxDecoration(
                        color: context.wearth.keyBackground.withAlpha(80),
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    FractionallySizedBox(
                      widthFactor: progress.clamp(0.02, 1.0),
                      child: Container(
                        height: 10,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              Color(0xFF4CAF50),
                              Color(0xFF2196F3),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF4CAF50).withAlpha(60),
                              blurRadius: 6,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Current continent
              Row(
                children: [
                  Text(
                    '🗺️',
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Şu an: ${continent.name}',
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: context.wearth.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // SIGN OUT BUTTON
  // ═══════════════════════════════════════════════════════════════

  Widget _buildSignOutButton() {
    return GestureDetector(
      onTap: () async {
        await _auth.signOut();
        if (mounted) {
          widget.onSignOut?.call();
        }
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: Colors.redAccent.withAlpha(15),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.redAccent.withAlpha(40),
                width: 0.5,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.logout_rounded,
                    size: 18, color: Colors.redAccent.withAlpha(200)),
                const SizedBox(width: 10),
                Text(
                  'Çıkış Yap',
                  style: GoogleFonts.outfit(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Colors.redAccent.withAlpha(200),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
