import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/social_service.dart';
import '../theme/app_theme.dart';

class ProfileCard extends StatelessWidget {
  final UserProfile profile;

  const ProfileCard({super.key, required this.profile});

  static void show(BuildContext context, UserProfile profile) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withAlpha(150),
      builder: (context) => Center(
        child: ProfileCard(profile: profile),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final winRate = profile.gamesPlayed > 0 
        ? (profile.gamesWon / profile.gamesPlayed * 100).toStringAsFixed(1) 
        : '0';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: context.wearth.glassBackgroundStrong,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: context.wearth.glassBorder, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(50),
            blurRadius: 40,
            spreadRadius: 10,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Üst Alan (Avatar ve İsim)
              Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    height: 140,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.primaries[profile.uid.hashCode % Colors.primaries.length].withAlpha(100),
                          Colors.primaries[(profile.uid.hashCode + 2) % Colors.primaries.length].withAlpha(50),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                  ),
                  Positioned(
                    top: 16,
                    right: 16,
                    child: IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close_rounded, color: Colors.white70),
                    ),
                  ),
                  Column(
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 3),
                          gradient: LinearGradient(
                            colors: [
                              Colors.primaries[profile.uid.hashCode % Colors.primaries.length],
                              Colors.primaries[(profile.uid.hashCode + 1) % Colors.primaries.length],
                            ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withAlpha(30),
                              blurRadius: 15,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            profile.username[0].toUpperCase(),
                            style: GoogleFonts.outfit(
                              fontSize: 32,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        profile.username,
                        style: GoogleFonts.outfit(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          shadows: [
                            const Shadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 2)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              // İstatistikler
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Row(
                      children: [
                        _buildStatItem(context, 'Maç', profile.gamesPlayed.toString(), Icons.play_arrow_rounded),
                        _buildStatItem(context, 'Kazanç', profile.gamesWon.toString(), Icons.emoji_events_rounded),
                        _buildStatItem(context, 'Oran', '%$winRate', Icons.analytics_rounded),
                      ],
                    ),
                    const SizedBox(height: 24),
                    const Divider(color: Colors.white10, height: 1),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        _buildBadgeItem(context, 'En Yüksek Seri', profile.maxStreak.toString(), Icons.local_fire_department_rounded, Colors.orangeAccent),
                        _buildBadgeItem(context, 'Klasik Seviye', profile.classicLevel.toString(), Icons.map_rounded, Colors.blueAccent),
                      ],
                    ),
                    const SizedBox(height: 32),
                    // Kapat Butonu
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha(20),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white.withAlpha(40), width: 1),
                        ),
                        child: Center(
                          child: Text(
                            'KAPAT',
                            style: GoogleFonts.outfit(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 2,
                              color: Colors.white.withAlpha(200),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(BuildContext context, String label, String value, IconData icon) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, size: 20, color: context.wearth.textSecondary.withAlpha(150)),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: context.wearth.textPrimary,
            ),
          ),
          Text(
            label.toUpperCase(),
            style: GoogleFonts.outfit(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: context.wearth.textSecondary,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBadgeItem(BuildContext context, String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 6),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withAlpha(20),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withAlpha(50)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withAlpha(30),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 18, color: color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: context.wearth.textPrimary,
                    ),
                  ),
                  Text(
                    label,
                    style: GoogleFonts.outfit(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: context.wearth.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
