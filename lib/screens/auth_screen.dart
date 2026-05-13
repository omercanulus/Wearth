import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui';
import '../l10n/app_localizations.dart';
import '../theme/app_theme.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';


class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  static Route route() {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => const AuthScreen(),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        var curve = Curves.easeInOutBack;
        var tween = Tween(begin: const Offset(0.0, 0.1), end: Offset.zero)
            .chain(CurveTween(curve: curve));
        return SlideTransition(
          position: animation.drive(tween),
          child: FadeTransition(
            opacity: animation,
            child: child,
          ),
        );
      },
      transitionDuration: const Duration(milliseconds: 600),
    );
  }

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final AppLocalizations _l10n = AppLocalizations();
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _usernameController = TextEditingController(); // Sadece kayıt olurken kullanılacak

  bool _isLogin = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _usernameController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      if (_isLogin) {
        await AuthService().signInWithEmail(
          _emailController.text.trim(),
          _passwordController.text.trim(),
        );
      } else {
        final credential = await AuthService().signUpWithEmail(
          _emailController.text.trim(),
          _passwordController.text.trim(),
        );
        // Kullanıcı adını Firebase profiline kaydet
        if (credential?.user != null && _usernameController.text.trim().isNotEmpty) {
          await credential!.user!.updateDisplayName(_usernameController.text.trim());
          await credential.user!.reload();
        }
      }

      if (mounted) {
        // Başarılı giriş/kayıt sonrası ekranı kapat
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        _showError(e);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() => _isLoading = true);
    try {
      await AuthService().signInWithGoogle();
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      _showError(e);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _signInWithApple() async {
    setState(() => _isLoading = true);
    try {
      await AuthService().signInWithApple();
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      _showError(e);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _getFriendlyErrorMessage(dynamic e) {
    if (e is FirebaseAuthException) {
      switch (e.code) {
        case 'user-not-found':
          return 'Bu e-posta adresi ile kayıtlı bir kullanıcı bulunamadı.';
        case 'wrong-password':
          return 'Girdiğiniz şifre hatalı. Lütfen tekrar deneyin.';
        case 'email-already-in-use':
          return 'Bu e-posta adresi zaten başka bir hesap tarafından kullanılıyor.';
        case 'invalid-email':
          return 'Lütfen geçerli bir e-posta adresi giriniz.';
        case 'weak-password':
          return 'Şifreniz çok zayıf. Lütfen daha güçlü bir şifre belirleyin.';
        case 'network-request-failed':
          return 'İnternet bağlantısı kurulamadı. Lütfen bağlantınızı kontrol edin.';
        case 'too-many-requests':
          return 'Çok fazla deneme yaptınız. Lütfen bir süre sonra tekrar deneyin.';
        case 'operation-not-allowed':
          return 'Bu giriş yöntemi şu an aktif değil.';
        default:
          return e.message ?? 'Bir hata oluştu. Lütfen tekrar deneyin.';
      }
    }
    return e.toString().contains('popup_closed_by_user') 
        ? 'Giriş işlemi iptal edildi.' 
        : 'Beklenmedik bir hata oluştu. Lütfen tekrar deneyin.';
  }

  void _showError(dynamic e) {
    final message = _getFriendlyErrorMessage(e);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline_rounded, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.redAccent.withAlpha(230),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.wearth.scaffoldBg,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close_rounded, color: context.wearth.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Stack(
        children: [
          // Arkaplan dekorasyonu (opsiyonel parlamalar eklenebilir)
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Logo
                    Hero(
                      tag: 'auth_logo',
                      child: Image.asset(
                        'assets/images/wearth_logo.png',
                        height: 180,
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
                                fontSize: 40,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 8,
                                color: Colors.white,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 40),
                    
                    // Liquid Glass Form Kartı
                    _buildGlassFormCard(),
                    
                    const SizedBox(height: 24),
                    
                    // Geçiş Butonu (Giriş Yap <-> Kayıt Ol)
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _isLogin = !_isLogin;
                          _formKey.currentState?.reset();
                        });
                      },
                      style: TextButton.styleFrom(
                        foregroundColor: context.wearth.textSecondary,
                      ),
                      child: RichText(
                        text: TextSpan(
                          text: _isLogin 
                              ? _l10n.t('noAccount') + " " 
                              : _l10n.t('haveAccount') + " ",
                          style: GoogleFonts.outfit(
                            color: context.wearth.textSecondary,
                            fontSize: 14,
                          ),
                          children: [
                            TextSpan(
                              text: _isLogin ? _l10n.t('signUp') : _l10n.t('login'),
                              style: GoogleFonts.outfit(
                                color: const Color(0xFF2196F3),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGlassFormCard() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(32),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: context.wearth.glassBackgroundStrong,
            borderRadius: BorderRadius.circular(32),
            border: Border.all(
              color: context.wearth.glassBorder,
              width: 0.5,
            ),
            boxShadow: [
              BoxShadow(
                color: context.wearth.glassShadow,
                blurRadius: 30,
                spreadRadius: 0,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _isLogin ? _l10n.t('login') : _l10n.t('signUp'),
                  style: GoogleFonts.outfit(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: context.wearth.textPrimary,
                  ),
                ),
                const SizedBox(height: 24),
                
                // Username Field (Sadece Kayıt)
                AnimatedSize(
                  duration: const Duration(milliseconds: 300),
                  child: !_isLogin
                      ? Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: _buildGlassTextField(
                            controller: _usernameController,
                            hint: _l10n.t('username'),
                            icon: Icons.person_rounded,
                            validator: (val) => val == null || val.isEmpty 
                                ? 'Kullanıcı adı gerekli' : null,
                          ),
                        )
                      : const SizedBox.shrink(),
                ),

                // Email Field
                _buildGlassTextField(
                  controller: _emailController,
                  hint: _l10n.t('email'),
                  icon: Icons.email_rounded,
                  keyboardType: TextInputType.emailAddress,
                  validator: (val) {
                    if (val == null || val.isEmpty) return 'E-posta gerekli';
                    if (!val.contains('@')) return 'Geçerli bir e-posta girin';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                
                // Password Field
                _buildGlassTextField(
                  controller: _passwordController,
                  hint: _l10n.t('password'),
                  icon: Icons.lock_rounded,
                  obscureText: true,
                  validator: (val) {
                    if (val == null || val.isEmpty) return 'Şifre gerekli';
                    if (val.length < 6) return 'Şifre en az 6 karakter olmalı';
                    return null;
                  },
                ),
                const SizedBox(height: 32),
                
                // Submit Button
                _buildSubmitButton(),

                const SizedBox(height: 24),
                
                // Divider
                Row(
                  children: [
                    Expanded(child: Divider(color: context.wearth.textSecondary.withAlpha(50))),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        _l10n.t('or'),
                        style: GoogleFonts.outfit(
                          color: context.wearth.textSecondary.withAlpha(100),
                          fontSize: 14,
                        ),
                      ),
                    ),
                    Expanded(child: Divider(color: context.wearth.textSecondary.withAlpha(50))),
                  ],
                ),
                
                const SizedBox(height: 24),
                
                // Social Logins
                _buildSocialLogins(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSocialLogins() {
    return Column(
      children: [
        _buildSocialButton(
          label: _l10n.t('continueWithGoogle'),
          icon: Icons.g_mobiledata_rounded,
          onTap: _signInWithGoogle,
          color: Colors.white,
          textColor: const Color(0xFF1F2937),
        ),
        const SizedBox(height: 12),
        _buildSocialButton(
          label: _l10n.t('continueWithApple'),
          icon: Icons.apple,
          onTap: _signInWithApple,
          color: Colors.black,
          textColor: Colors.white,
        ),
      ],
    );
  }

  Widget _buildSocialButton({
    required String label,
    String? iconPath,
    IconData? icon,
    required VoidCallback onTap,
    required Color color,
    required Color textColor,
  }) {
    return GestureDetector(
      onTap: _isLoading ? null : onTap,
      child: Container(
        height: 52,
        width: double.infinity,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: context.wearth.glassBorder.withAlpha(100),
            width: 0.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(10),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (iconPath != null)
              Image.asset(iconPath, height: 20, errorBuilder: (_, __, ___) => Icon(Icons.g_mobiledata, color: textColor, size: 24))
            else if (icon != null)
              Icon(icon, color: textColor, size: 22),
            const SizedBox(width: 12),
            Text(
              label,
              style: GoogleFonts.outfit(
                color: textColor,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGlassTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool obscureText = false,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      validator: validator,
      style: GoogleFonts.outfit(
        color: context.wearth.textPrimary,
        fontSize: 16,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.outfit(
          color: context.wearth.textSecondary.withAlpha(150),
        ),
        prefixIcon: Icon(icon, color: context.wearth.textSecondary),
        filled: true,
        fillColor: context.wearth.keyBackground.withAlpha(100),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: const Color(0xFF2196F3).withAlpha(150), width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.redAccent.withAlpha(150), width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.redAccent.withAlpha(200), width: 1.5),
        ),
      ),
    );
  }

  Widget _buildSubmitButton() {
    return GestureDetector(
      onTap: _isLoading ? null : _submitForm,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 56,
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          color: const Color(0xFF1A1A2E),
          border: Border.all(
            color: Colors.white.withAlpha(15),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF8B5CF6).withAlpha(30),
              blurRadius: 20,
              spreadRadius: 0,
              offset: const Offset(0, 6),
            ),
            BoxShadow(
              color: const Color(0xFF06B6D4).withAlpha(20),
              blurRadius: 30,
              spreadRadius: 0,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Subtle gradient overlay
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      const Color(0xFF8B5CF6).withAlpha(30),
                      const Color(0xFF06B6D4).withAlpha(20),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            Center(
              child: _isLoading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _isLogin ? _l10n.t('login') : _l10n.t('signUp'),
                          style: GoogleFonts.outfit(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          Icons.arrow_forward_rounded,
                          color: Colors.white.withAlpha(180),
                          size: 20,
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
