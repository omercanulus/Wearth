import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui';
import '../l10n/app_localizations.dart';
import '../theme/app_theme.dart';
import '../services/storage_service.dart';
import '../main.dart';
import 'daily_game_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  final AppLocalizations _l10n = AppLocalizations();
  int _currentNavIndex = 0;
  bool _isLanguageMenuOpen = false;
  late AnimationController _languageMenuController;
  late Animation<double> _languageMenuAnimation;

  @override
  void initState() {
    super.initState();
    _languageMenuController = AnimationController(
      duration: const Duration(milliseconds: 280),
      vsync: this,
    );
    _languageMenuAnimation = CurvedAnimation(
      parent: _languageMenuController,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
  }

  @override
  void dispose() {
    _languageMenuController.dispose();
    super.dispose();
  }

  void _toggleLanguageMenu() {
    setState(() {
      _isLanguageMenuOpen = !_isLanguageMenuOpen;
    });
    if (_isLanguageMenuOpen) {
      _languageMenuController.forward();
    } else {
      _languageMenuController.reverse();
    }
  }

  void _selectLanguage(String localeCode) {
    setState(() {
      _l10n.setLocale(localeCode);
      _isLanguageMenuOpen = false;
    });
    _languageMenuController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.wearth.scaffoldBg,
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
                            color: context.wearth.textVersion,
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
                _buildLiquidGlassLanguageButton(),
                const SizedBox(height: 8),
                // Language dropdown menu (animated)
                _buildLanguageDropdown(),
                const SizedBox(height: 8),
                _buildLiquidGlassHowToPlayButton(),
              ],
            ),
          ),

          // Top-left buttons: Premium + Settings
          Positioned(
            top: MediaQuery.of(context).padding.top + 12,
            left: 16,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildPremiumButton(),
                const SizedBox(height: 8),
                _buildSettingsIconButton(),
                const SizedBox(height: 8),
                _buildThemeToggleButton(),
              ],
            ),
          ),

          // Close language menu when tapping outside
          if (_isLanguageMenuOpen)
            Positioned.fill(
              child: GestureDetector(
                onTap: _toggleLanguageMenu,
                behavior: HitTestBehavior.translucent,
                child: const SizedBox.expand(),
              ),
            ),

          // Re-position the language dropdown above the overlay detector
          if (_isLanguageMenuOpen)
            Positioned(
              top: MediaQuery.of(context).padding.top + 12 + 48 + 8,
              right: 16,
              child: _buildLanguageDropdownContent(),
            ),
        ],
      ),

      // Bottom Liquid Glass Navbar
      extendBody: true,
      bottomNavigationBar: _buildLiquidGlassNavbar(),
    );
  }

  /// Liquid glass premium button
  Widget _buildPremiumButton() {
    return GestureDetector(
      onTap: () {
        // TODO: Navigate to premium / subscription screen
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: context.wearth.glassBackground,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: const Color(0xFFFFC107).withAlpha(60),
                width: 0.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFFC107).withAlpha(15),
                  blurRadius: 16,
                  spreadRadius: 0,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                ShaderMask(
                  shaderCallback: (bounds) => const LinearGradient(
                    colors: [
                      Color(0xFFF59E0B),
                      Color(0xFFEF4444),
                      Color(0xFFF59E0B),
                    ],
                  ).createShader(bounds),
                  child: const Icon(
                    Icons.workspace_premium_rounded,
                    size: 18,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 8),
                ShaderMask(
                  shaderCallback: (bounds) => const LinearGradient(
                    colors: [
                      Color(0xFFF59E0B),
                      Color(0xFFEF4444),
                    ],
                  ).createShader(bounds),
                  child: Text(
                    _l10n.t('getPremium'),
                    style: GoogleFonts.outfit(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Liquid glass settings icon button (no label)
  Widget _buildSettingsIconButton() {
    return GestureDetector(
      onTap: () {
        // TODO: Navigate to settings screen
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: context.wearth.glassBackground,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: context.wearth.settingsBorder,
                width: 0.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: context.wearth.glassShadow,
                  blurRadius: 12,
                  spreadRadius: 0,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Icon(
              Icons.settings_rounded,
              size: 20,
              color: context.wearth.settingsIcon,
            ),
          ),
        ),
      ),
    );
  }

  /// Liquid glass theme toggle icon button
  Widget _buildThemeToggleButton() {
    final isDark = context.isDark;
    
    return GestureDetector(
      onTap: () {
        final newMode = isDark ? ThemeMode.light : ThemeMode.dark;
        themeNotifier.value = newMode;
        StorageService().saveThemeMode(isDark ? 'light' : 'dark');
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: context.wearth.glassBackground,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: context.wearth.settingsBorder,
                width: 0.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: context.wearth.glassShadow,
                  blurRadius: 12,
                  spreadRadius: 0,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Icon(
              isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
              size: 20,
              color: context.wearth.settingsIcon,
            ),
          ),
        ),
      ),
    );
  }

  /// Liquid glass style language button
  Widget _buildLiquidGlassLanguageButton() {
    return GestureDetector(
      onTap: _toggleLanguageMenu,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: _isLanguageMenuOpen
                  ? context.wearth.glassBackgroundStrong
                  : context.wearth.glassBackground,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: const Color(0xFF2196F3).withAlpha(_isLanguageMenuOpen ? 80 : 50),
                width: 0.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF2196F3).withAlpha(15),
                  blurRadius: 16,
                  spreadRadius: 0,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _l10n.currentFlag,
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(width: 8),
                Text(
                  _l10n.currentLanguageLabel,
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1E88E5),
                  ),
                ),
                const SizedBox(width: 4),
                AnimatedRotation(
                  turns: _isLanguageMenuOpen ? 0.5 : 0,
                  duration: const Duration(milliseconds: 250),
                  child: Icon(
                    Icons.keyboard_arrow_down_rounded,
                    size: 18,
                    color: const Color(0xFF1E88E5).withAlpha(180),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Empty placeholder when dropdown is shown via overlay
  Widget _buildLanguageDropdown() {
    return const SizedBox.shrink();
  }

  /// Liquid glass dropdown content for language selection
  Widget _buildLanguageDropdownContent() {
    return FadeTransition(
      opacity: _languageMenuAnimation,
      child: SizeTransition(
        sizeFactor: _languageMenuAnimation,
        axisAlignment: -1.0,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
            child: Container(
              width: 180,
              decoration: BoxDecoration(
                color: context.wearth.menuBackground,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: context.wearth.menuBorder,
                  width: 0.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: context.wearth.glassShadow,
                    blurRadius: 24,
                    spreadRadius: 0,
                    offset: const Offset(0, 8),
                  ),
                  BoxShadow(
                    color: const Color(0xFF2196F3).withAlpha(8),
                    blurRadius: 32,
                    spreadRadius: 0,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: AppLocalizations.availableLocales.map((locale) {
                  final isSelected = _l10n.currentLocale == locale['code'];
                  return GestureDetector(
                    onTap: () => _selectLanguage(locale['code']!),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFF2196F3).withAlpha(20)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        children: [
                          Text(
                            locale['flag']!,
                            style: const TextStyle(fontSize: 18),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              locale['name']!,
                              style: GoogleFonts.outfit(
                                fontSize: 14,
                                fontWeight: isSelected
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                                color: isSelected
                                    ? const Color(0xFF1E88E5)
                                    : context.wearth.textPrimary,
                              ),
                            ),
                          ),
                          if (isSelected)
                            Icon(
                              Icons.check_rounded,
                              size: 18,
                              color: const Color(0xFF1E88E5),
                            ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Liquid glass style how to play button
  Widget _buildLiquidGlassHowToPlayButton() {
    return GestureDetector(
      onTap: () {
        // TODO: Navigate to how to play screen
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: context.wearth.glassBackground,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: const Color(0xFF4CAF50).withAlpha(50),
                width: 0.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF4CAF50).withAlpha(15),
                  blurRadius: 16,
                  spreadRadius: 0,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.help_outline_rounded,
                  size: 18,
                  color: const Color(0xFF4CAF50),
                ),
                const SizedBox(width: 8),
                Text(
                  _l10n.t('howToPlay'),
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF4CAF50),
                  ),
                ),
              ],
            ),
          ),
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
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const DailyGameScreen(),
            ),
          );
        },
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
            child: Container(
              height: 72,
              width: double.infinity,
              decoration: BoxDecoration(
                color: context.wearth.glassBackground,
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
              color: context.wearth.glassBackground,
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
      _NavItem(icon: Icons.home_rounded, label: _l10n.t('home')),
      _NavItem(icon: Icons.leaderboard_rounded, label: _l10n.t('ranking')),
      _NavItem(icon: Icons.person_rounded, label: _l10n.t('profile')),
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
              color: context.wearth.glassBackgroundStrong,
              borderRadius: BorderRadius.circular(40),
              border: Border.all(
                color: context.wearth.glassBorder,
                width: 0.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: context.wearth.glassShadow,
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
                                : context.wearth.navUnselected,
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
