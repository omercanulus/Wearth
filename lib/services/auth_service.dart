import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart';

// Apple sign in sadece mobile'da import edilsin
import 'package:sign_in_with_apple/sign_in_with_apple.dart'
    if (dart.library.html) 'package:wearth/services/apple_stub.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Web'de clientId gereklidir; Android/iOS kendi config dosyalarından otomatik alır
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    clientId: kIsWeb
        ? "535905372792-7mkjlpf8q9melsh5ph6qkbg0oc1vpfkh.apps.googleusercontent.com"
        : null,
    scopes: ['email', 'profile'],
  );

  User? get currentUser => _auth.currentUser;
  bool get isLoggedIn => currentUser != null;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<UserCredential?> signInWithEmail(String email, String password) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      print('Giriş hatası: $e');
      rethrow;
    }
  }

  Future<UserCredential?> signUpWithEmail(String email, String password) async {
    try {
      return await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      print('Kayıt hatası: $e');
      rethrow;
    }
  }

  Future<UserCredential?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null;

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      return await _auth.signInWithCredential(credential);
    } catch (e) {
      print('Google giriş hatası: $e');
      rethrow;
    }
  }

  Future<UserCredential?> signInWithApple() async {
    // Web'de Apple sign in desteklenmiyor
    if (kIsWeb) {
      throw UnsupportedError('Apple ile giriş web\'de desteklenmiyor.');
    }

    try {
      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScope.email,
          AppleIDAuthorizationScope.fullName,
        ],
      );

      final OAuthProvider oAuthProvider = OAuthProvider('apple.com');
      final AuthCredential credential = oAuthProvider.credential(
        idToken: appleCredential.identityToken,
        accessToken: appleCredential.authorizationCode,
      );

      return await _auth.signInWithCredential(credential);
    } catch (e) {
      print('Apple giriş hatası: $e');
      rethrow;
    }
  }

  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
    } catch (_) {}
    await _auth.signOut();
  }
}