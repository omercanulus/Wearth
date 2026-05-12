// Web platformu için Apple Sign In stub
class SignInWithApple {
  static Future<dynamic> getAppleIDCredential({List<dynamic>? scopes}) async {
    throw UnsupportedError('Apple Sign In web\'de desteklenmiyor.');
  }
}

class AppleIDAuthorizationScope {
  static const email = 'email';
  static const fullName = 'fullName';
}