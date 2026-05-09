import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui';
import '../l10n/app_localizations.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final AppLocalizations _l10n = AppLocalizations();
  int _currentNavIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Main content
          SafeArea(
            bottom: false,
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(height: 80),

                        // Game Logo
                        Image.asset(
                          'assets/images/wearth_logo.png',
                          height: 300,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) {
                            return ShaderMask(
                              shaderCallback: (bounds) => const LinearGradient(
                                colors: [
                                  Color(0xFF4CAF50),
                                  Color(0xFF2196F3),
                                  Color(0xFF4CAF50),
                                ],
                              ).createShader(bounds),
                              child: Text(
                                'WEARTH',
                                style: GoogleFonts.outfit(
                                  fontSize: 48,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 12,
                                  color: Colors.white,
                                ),
                              ),
                            );
                          },
                        ),

                        const SizedBox(height: 32),

                        // Word of the Day Button
                        _buildWordOfTheDayButton(),

                        const SizedBox(height: 12),

                        // Mode Buttons
                        _buildModeButtons(),

                        const SizedBox(height: 20),

                        // Version info
                        Text(
                          _l10n.t('version'),
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            color: const Color(0xFFBDBDBD),
                          ),
                        ),

                        // Space for bottom navbar
                        const SizedBox(height: 100),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // Top-right buttons: Language + How to Play
          Positioned(
            top: MediaQuery.of(context).padding.top + 12,
            right: 16,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _buildLanguageButton(),
                const SizedBox(height: 8),
                _buildHowToPlayButton(),
              ],
            ),
          ),

          // Top-left button: Remove Ads
          Positioned(
            top: MediaQuery.of(context).padding.top + 12,
            left: 16,
            child: _buildRemoveAdsButton(),
          ),
        ],
      ),

      // Bottom Liquid Glass Navbar
      extendBody: true,
      bottomNavigationBar: _buildLiquidGlassNavbar(),
    );
  }

  Widget _buildRemoveAdsButton() {
    return GestureDetector(
      onTap: () {
        // TODO: Navigate to remove ads / premium screen
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFF5F5F5),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: const Color(0xFFE0E0E0),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.block_rounded,
              size: 18,
              color: const Color(0xFFEF4444),
            ),
            const SizedBox(width: 6),
            Text(
              _l10n.t('removeAds'),
              style: GoogleFonts.outfit(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF374151),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageButton() {
    return GestureDetector(
      onTap: () {
        setState(() {
          _l10n.toggleLocale();
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFF5F5F5),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: const Color(0xFFE0E0E0),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.language_rounded,
              size: 18,
              color: const Color(0xFF2196F3),
            ),
            const SizedBox(width: 6),
            Text(
              _l10n.currentLanguageLabel,
              style: GoogleFonts.outfit(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF374151),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHowToPlayButton() {
    return GestureDetector(
      onTap: () {
        // TODO: Navigate to how to play screen
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFF5F5F5),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: const Color(0xFFE0E0E0),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.help_outline_rounded,
              size: 18,
              color: const Color(0xFF4CAF50),
            ),
            const SizedBox(width: 6),
            Text(
              _l10n.t('howToPlay'),
              style: GoogleFonts.outfit(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF374151),
              ),
            ),
          ],
        ),
      ),
    );
  }



  Widget _buildModeButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Row(
        children: [
          // Classic Mode Button
          Expanded(
            child: _buildGlassButton(
              icon: Icons.extension_rounded,
              label: _l10n.t('classicMode'),
              accentColor: const Color(0xFF4CAF50),
              onTap: () {
                // TODO: Navigate to classic game screen
              },
            ),
          ),

          const SizedBox(width: 16),

          // Online Mode Button
          Expanded(
            child: _buildGlassButton(
              icon: Icons.public_rounded,
              label: _l10n.t('onlineMode'),
              accentColor: const Color(0xFF2196F3),
              onTap: () {
                // TODO: Navigate to online game screen
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWordOfTheDayButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: GestureDetector(
        onTap: () {
          // TODO: Navigate to word of the day screen
        },
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
            child: Container(
              height: 72,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(140),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: const Color(0xFFFFC107).withAlpha(60),
                  width: 0.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFFC107).withAlpha(20),
                    blurRadius: 16,
                    spreadRadius: 0,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.auto_awesome_rounded,
                      color: Color(0xFFF59E0B),
                      size: 24,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      _l10n.t('wordOfTheDay'),
                      style: GoogleFonts.outfit(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFFF59E0B),
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGlassButton({
    required IconData icon,
    required String label,
    required Color accentColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
          child: Container(
            height: 72,
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(140),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: accentColor.withAlpha(60),
                width: 0.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: accentColor.withAlpha(15),
                  blurRadius: 16,
                  spreadRadius: 0,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, color: accentColor, size: 24),
                  const SizedBox(height: 6),
                  Text(
                    label,
                    style: GoogleFonts.outfit(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: accentColor,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLiquidGlassNavbar() {
    final items = [
      _NavItem(icon: Icons.person_rounded, label: _l10n.t('profile')),
      _NavItem(icon: Icons.leaderboard_rounded, label: _l10n.t('ranking')),
      _NavItem(icon: Icons.settings_rounded, label: _l10n.t('settings')),
    ];

    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        bottom: bottomPadding + 12,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(40),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
          child: Container(
            height: 72,
            decoration: BoxDecoration(
              // Translucent white glass background
              color: Colors.white.withAlpha(160),
              borderRadius: BorderRadius.circular(40),
              border: Border.all(
                color: Colors.white.withAlpha(200),
                width: 0.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(15),
                  blurRadius: 20,
                  spreadRadius: 0,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(items.length, (index) {
                final isSelected = _currentNavIndex == index;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _currentNavIndex = index;
                    });
                    // TODO: Navigate to respective screens
                  },
                  behavior: HitTestBehavior.opaque,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeInOut,
                    padding: EdgeInsets.symmetric(
                      horizontal: isSelected ? 16 : 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      // Selected capsule highlight
                      color: isSelected
                          ? const Color(0xFF4CAF50).withAlpha(25)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          items[index].icon,
                          size: 24,
                          color: isSelected
                              ? const Color(0xFF4CAF50)
                              : const Color(0xFF9CA3AF),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          items[index].label,
                          style: GoogleFonts.outfit(
                            fontSize: 10,
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.w400,
                            color: isSelected
                                ? const Color(0xFF4CAF50)
                                : const Color(0xFF9CA3AF),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final String label;

  const _NavItem({required this.icon, required this.label});
}
