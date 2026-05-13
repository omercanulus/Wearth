import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../l10n/app_localizations.dart';
import '../theme/app_theme.dart';
import '../services/storage_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final AppLocalizations _l10n = AppLocalizations();
  bool _soundEnabled = true;
  bool _hapticEnabled = true;

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;

    return Scaffold(
      backgroundColor: context.wearth.scaffoldBg,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  _buildSectionTitle(_l10n.t('settings')),
                  _buildSettingsGroup([
                    _buildToggleTile(
                      icon: Icons.volume_up_rounded,
                      label: 'Ses Efektleri',
                      value: _soundEnabled,
                      onChanged: (v) => setState(() => _soundEnabled = v),
                    ),
                    _buildToggleTile(
                      icon: Icons.vibration_rounded,
                      label: 'Titreşim',
                      value: _hapticEnabled,
                      onChanged: (v) => setState(() => _hapticEnabled = v),
                    ),
                  ]),
                  const SizedBox(height: 32),
                  _buildSectionTitle('Hakkında'),
                  _buildSettingsGroup([
                    _buildActionTile(
                      icon: Icons.info_outline_rounded,
                      label: 'Nasıl Oynanır?',
                      onTap: () {},
                    ),
                    _buildActionTile(
                      icon: Icons.privacy_tip_outlined,
                      label: 'Gizlilik Politikası',
                      onTap: () {},
                    ),
                    _buildActionTile(
                      icon: Icons.description_outlined,
                      label: 'Kullanım Koşulları',
                      onTap: () {},
                    ),
                  ]),
                  const SizedBox(height: 40),
                  Center(
                    child: Text(
                      'Wearth v1.0.0 ',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        color: context.wearth.textVersion,
                      ),
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

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: context.wearth.glassBackground,
                    shape: BoxShape.circle,
                    border: Border.all(color: context.wearth.glassBorder, width: 0.5),
                  ),
                  child: Icon(Icons.close_rounded, color: context.wearth.textPrimary),
                ),
              ),
            ),
          ),
          const Spacer(),
          Text(
            _l10n.t('settings').toUpperCase(),
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              letterSpacing: 2,
              color: context.wearth.textPrimary,
            ),
          ),
          const Spacer(),
          const SizedBox(width: 48), // Balancing back button
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 12),
      child: Text(
        title.toUpperCase(),
        style: GoogleFonts.outfit(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.5,
          color: context.wearth.textVersion,
        ),
      ),
    );
  }

  Widget _buildSettingsGroup(List<Widget> children) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          decoration: BoxDecoration(
            color: context.wearth.glassBackground,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: context.wearth.glassBorder, width: 0.5),
          ),
          child: Column(
            children: children,
          ),
        ),
      ),
    );
  }

  Widget _buildToggleTile({
    required IconData icon,
    required String label,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          Icon(icon, color: context.wearth.textPrimary.withAlpha(180), size: 22),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.outfit(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: context.wearth.textPrimary,
              ),
            ),
          ),
          Switch.adaptive(
            value: value,
            onChanged: onChanged,
            activeColor: const Color(0xFF4CAF50),
          ),
        ],
      ),
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        child: Row(
          children: [
            Icon(icon, color: context.wearth.textPrimary.withAlpha(180), size: 22),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: context.wearth.textPrimary,
                ),
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: context.wearth.textVersion),
          ],
        ),
      ),
    );
  }
}
