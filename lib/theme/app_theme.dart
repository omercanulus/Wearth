import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Wearth tema sistemi.
/// Light ve Dark temayı tek bir yerden yönetir.
/// Kullanım: context.wearth.glassBackground
class AppTheme {
  AppTheme._();

  // ─── Sabit Renkler (her iki temada aynı) ──────────────────────

  static const Color primary = Color(0xFF4CAF50);
  static const Color secondary = Color(0xFF2196F3);
  static const Color accentGold = Color(0xFFF59E0B);
  static const Color accentAmber = Color(0xFFFFC107);
  static const Color accentRed = Color(0xFFEF4444);

  // Oyun renkleri
  static const Color correctGreen = Color(0xFF4CAF50);
  static const Color presentAmber = Color(0xFFFFC107);
  static const Color absentGray = Color(0xFF9CA3AF);

  // ─── Açık Tema ─────────────────────────────────────────────────

  static ThemeData get light {
    return ThemeData(
      brightness: Brightness.light,
      colorScheme: ColorScheme.light(
        primary: primary,
        secondary: secondary,
        surface: Colors.white,
      ),
      scaffoldBackgroundColor: Colors.white,
      textTheme: GoogleFonts.outfitTextTheme(
        ThemeData.light().textTheme,
      ),
      useMaterial3: true,
      extensions: const [
        WearthColors(
          // Cam efektleri
          glassBackground: Color(0x8CFFFFFF),       // white alpha 140
          glassBackgroundStrong: Color(0xB4FFFFFF),  // white alpha 180
          glassBorder: Color(0xC8FFFFFF),            // white alpha 200
          glassShadow: Color(0x0F000000),            // black alpha 15

          // Metin
          textPrimary: Color(0xFF1F2937),
          textSecondary: Color(0xFF374151),
          textMuted: Color(0xFF9CA3AF),
          textVersion: Color(0xFFBDBDBD),

          // Arka plan
          scaffoldBg: Colors.white,
          surfaceBg: Color(0xFFF9FAFB),

          // Klavye
          keyBackground: Color(0xFFF3F4F6),
          keyBorder: Color(0xFFE5E7EB),
          keyText: Color(0xFF374151),
          keyTextDisabled: Color(0xFFBDBDBD),

          // Kutucuklar
          tileEmpty: Color(0x64FFFFFF),             // white alpha 100
          tileEmptyBorder: Color(0x78D1D5DB),       // gray alpha 120
          tileActive: Color(0xA0FFFFFF),            // white alpha 160
          tileActiveBorder: Color(0x32374151),      // dark alpha 50

          // Mesaj
          messageBg: Color(0xFF1F2937),
          messageText: Colors.white,

          // Dropdown / Menü
          menuBackground: Color(0xC8FFFFFF),        // white alpha 200
          menuBorder: Color(0xDCFFFFFF),            // white alpha 220
          menuSelected: Color(0x142196F3),          // blue alpha 20

          // Nav bar
          navSelectedBg: Color(0x194CAF50),         // green alpha 25
          navUnselected: Color(0xFF9CA3AF),

          // Ayarlar ikonu
          settingsIcon: Color(0xFF6B7280),
          settingsBorder: Color(0x289CA3AF),        // gray alpha 40
        ),
      ],
    );
  }

  // ─── Koyu Tema ─────────────────────────────────────────────────

  static ThemeData get dark {
    return ThemeData(
      brightness: Brightness.dark,
      colorScheme: ColorScheme.dark(
        primary: primary,
        secondary: secondary,
        surface: const Color(0xFF1A1A2E),
      ),
      scaffoldBackgroundColor: const Color(0xFF0F0F1A),
      textTheme: GoogleFonts.outfitTextTheme(
        ThemeData.dark().textTheme,
      ),
      useMaterial3: true,
      extensions: const [
        WearthColors(
          // Cam efektleri — koyu modda beyaz yerine hafif parlak
          glassBackground: Color(0x1AFFFFFF),       // white alpha 26
          glassBackgroundStrong: Color(0x28FFFFFF),  // white alpha 40
          glassBorder: Color(0x1EFFFFFF),            // white alpha 30
          glassShadow: Color(0x28000000),            // black alpha 40

          // Metin — açık renkler
          textPrimary: Color(0xFFF9FAFB),
          textSecondary: Color(0xFFE5E7EB),
          textMuted: Color(0xFF6B7280),
          textVersion: Color(0xFF4B5563),

          // Arka plan
          scaffoldBg: Color(0xFF0F0F1A),
          surfaceBg: Color(0xFF1A1A2E),

          // Klavye
          keyBackground: Color(0xFF1E1E32),
          keyBorder: Color(0xFF2D2D44),
          keyText: Color(0xFFE5E7EB),
          keyTextDisabled: Color(0xFF4B5563),

          // Kutucuklar
          tileEmpty: Color(0x14FFFFFF),             // white alpha 20
          tileEmptyBorder: Color(0x2EFFFFFF),       // white alpha 46
          tileActive: Color(0x28FFFFFF),            // white alpha 40
          tileActiveBorder: Color(0x3CFFFFFF),      // white alpha 60

          // Mesaj
          messageBg: Color(0xFFF9FAFB),
          messageText: Color(0xFF0F0F1A),

          // Dropdown / Menü
          menuBackground: Color(0xE61A1A2E),        // dark alpha 230
          menuBorder: Color(0x28FFFFFF),             // white alpha 40
          menuSelected: Color(0x1E2196F3),           // blue alpha 30

          // Nav bar
          navSelectedBg: Color(0x284CAF50),          // green alpha 40
          navUnselected: Color(0xFF6B7280),

          // Ayarlar ikonu
          settingsIcon: Color(0xFF9CA3AF),
          settingsBorder: Color(0x1EFFFFFF),         // white alpha 30
        ),
      ],
    );
  }
}

// ─── Wearth Özel Renk Sistemi ────────────────────────────────────

/// Tüm Wearth'e özel renkleri tek bir yerde toplar.
/// ThemeExtension sayesinde Theme.of(context) ile erişilebilir.
@immutable
class WearthColors extends ThemeExtension<WearthColors> {
  // Cam (glass) efekti
  final Color glassBackground;
  final Color glassBackgroundStrong;
  final Color glassBorder;
  final Color glassShadow;

  // Metin renkleri
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;
  final Color textVersion;

  // Arka planlar
  final Color scaffoldBg;
  final Color surfaceBg;

  // Klavye
  final Color keyBackground;
  final Color keyBorder;
  final Color keyText;
  final Color keyTextDisabled;

  // Kutucuklar (boş hali)
  final Color tileEmpty;
  final Color tileEmptyBorder;
  final Color tileActive;
  final Color tileActiveBorder;

  // Mesaj bildirimi
  final Color messageBg;
  final Color messageText;

  // Dropdown menü
  final Color menuBackground;
  final Color menuBorder;
  final Color menuSelected;

  // Alt navigasyon
  final Color navSelectedBg;
  final Color navUnselected;

  // Ayarlar
  final Color settingsIcon;
  final Color settingsBorder;

  const WearthColors({
    required this.glassBackground,
    required this.glassBackgroundStrong,
    required this.glassBorder,
    required this.glassShadow,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.textVersion,
    required this.scaffoldBg,
    required this.surfaceBg,
    required this.keyBackground,
    required this.keyBorder,
    required this.keyText,
    required this.keyTextDisabled,
    required this.tileEmpty,
    required this.tileEmptyBorder,
    required this.tileActive,
    required this.tileActiveBorder,
    required this.messageBg,
    required this.messageText,
    required this.menuBackground,
    required this.menuBorder,
    required this.menuSelected,
    required this.navSelectedBg,
    required this.navUnselected,
    required this.settingsIcon,
    required this.settingsBorder,
  });

  @override
  WearthColors copyWith({
    Color? glassBackground,
    Color? glassBackgroundStrong,
    Color? glassBorder,
    Color? glassShadow,
    Color? textPrimary,
    Color? textSecondary,
    Color? textMuted,
    Color? textVersion,
    Color? scaffoldBg,
    Color? surfaceBg,
    Color? keyBackground,
    Color? keyBorder,
    Color? keyText,
    Color? keyTextDisabled,
    Color? tileEmpty,
    Color? tileEmptyBorder,
    Color? tileActive,
    Color? tileActiveBorder,
    Color? messageBg,
    Color? messageText,
    Color? menuBackground,
    Color? menuBorder,
    Color? menuSelected,
    Color? navSelectedBg,
    Color? navUnselected,
    Color? settingsIcon,
    Color? settingsBorder,
  }) {
    return WearthColors(
      glassBackground: glassBackground ?? this.glassBackground,
      glassBackgroundStrong: glassBackgroundStrong ?? this.glassBackgroundStrong,
      glassBorder: glassBorder ?? this.glassBorder,
      glassShadow: glassShadow ?? this.glassShadow,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textMuted: textMuted ?? this.textMuted,
      textVersion: textVersion ?? this.textVersion,
      scaffoldBg: scaffoldBg ?? this.scaffoldBg,
      surfaceBg: surfaceBg ?? this.surfaceBg,
      keyBackground: keyBackground ?? this.keyBackground,
      keyBorder: keyBorder ?? this.keyBorder,
      keyText: keyText ?? this.keyText,
      keyTextDisabled: keyTextDisabled ?? this.keyTextDisabled,
      tileEmpty: tileEmpty ?? this.tileEmpty,
      tileEmptyBorder: tileEmptyBorder ?? this.tileEmptyBorder,
      tileActive: tileActive ?? this.tileActive,
      tileActiveBorder: tileActiveBorder ?? this.tileActiveBorder,
      messageBg: messageBg ?? this.messageBg,
      messageText: messageText ?? this.messageText,
      menuBackground: menuBackground ?? this.menuBackground,
      menuBorder: menuBorder ?? this.menuBorder,
      menuSelected: menuSelected ?? this.menuSelected,
      navSelectedBg: navSelectedBg ?? this.navSelectedBg,
      navUnselected: navUnselected ?? this.navUnselected,
      settingsIcon: settingsIcon ?? this.settingsIcon,
      settingsBorder: settingsBorder ?? this.settingsBorder,
    );
  }

  @override
  WearthColors lerp(WearthColors? other, double t) {
    if (other is! WearthColors) return this;
    return WearthColors(
      glassBackground: Color.lerp(glassBackground, other.glassBackground, t)!,
      glassBackgroundStrong: Color.lerp(glassBackgroundStrong, other.glassBackgroundStrong, t)!,
      glassBorder: Color.lerp(glassBorder, other.glassBorder, t)!,
      glassShadow: Color.lerp(glassShadow, other.glassShadow, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textMuted: Color.lerp(textMuted, other.textMuted, t)!,
      textVersion: Color.lerp(textVersion, other.textVersion, t)!,
      scaffoldBg: Color.lerp(scaffoldBg, other.scaffoldBg, t)!,
      surfaceBg: Color.lerp(surfaceBg, other.surfaceBg, t)!,
      keyBackground: Color.lerp(keyBackground, other.keyBackground, t)!,
      keyBorder: Color.lerp(keyBorder, other.keyBorder, t)!,
      keyText: Color.lerp(keyText, other.keyText, t)!,
      keyTextDisabled: Color.lerp(keyTextDisabled, other.keyTextDisabled, t)!,
      tileEmpty: Color.lerp(tileEmpty, other.tileEmpty, t)!,
      tileEmptyBorder: Color.lerp(tileEmptyBorder, other.tileEmptyBorder, t)!,
      tileActive: Color.lerp(tileActive, other.tileActive, t)!,
      tileActiveBorder: Color.lerp(tileActiveBorder, other.tileActiveBorder, t)!,
      messageBg: Color.lerp(messageBg, other.messageBg, t)!,
      messageText: Color.lerp(messageText, other.messageText, t)!,
      menuBackground: Color.lerp(menuBackground, other.menuBackground, t)!,
      menuBorder: Color.lerp(menuBorder, other.menuBorder, t)!,
      menuSelected: Color.lerp(menuSelected, other.menuSelected, t)!,
      navSelectedBg: Color.lerp(navSelectedBg, other.navSelectedBg, t)!,
      navUnselected: Color.lerp(navUnselected, other.navUnselected, t)!,
      settingsIcon: Color.lerp(settingsIcon, other.settingsIcon, t)!,
      settingsBorder: Color.lerp(settingsBorder, other.settingsBorder, t)!,
    );
  }
}

// ─── Kolay Erişim Extension'ı ─────────────────────────────────────

/// context.wearth.glassBackground şeklinde kısa erişim sağlar.
extension WearthThemeExtension on BuildContext {
  WearthColors get wearth =>
      Theme.of(this).extension<WearthColors>()!;

  bool get isDark =>
      Theme.of(this).brightness == Brightness.dark;
}
