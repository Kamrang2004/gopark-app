import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:gopark_app/core/api_service.dart';

class SocialAuthService {
  // Use the Web Client ID from Google Cloud Console so we receive an idToken
  static final GoogleSignIn _googleSignIn = GoogleSignIn(
    clientId: '102594647490-q4mr0ed1kcdofj0jq7u5okbk4jv33lq1.apps.googleusercontent.com',
    serverClientId:
        '102594647490-mmsstgnaoooi88t46hunp19p5cvbvqip.apps.googleusercontent.com',
    scopes: ['email', 'profile'],
  );

  /// Signs the user in with Google and calls the backend social_login.php endpoint.
  /// Returns the API response map, or null if the user cancelled.
  static Future<Map<String, dynamic>?> signInWithGoogle() async {
    try {
      // Trigger the Google Sign-In flow
      final GoogleSignInAccount? account = await _googleSignIn.signIn();
      if (account == null) return null; // user cancelled

      final GoogleSignInAuthentication auth = await account.authentication;
      final String? idToken = auth.idToken;

      if (idToken == null) {
        return {
          'status': 'error',
          'message':
              'Google did not return an ID token. Ensure the serverClientId is correct.',
        };
      }

      return await ApiService.post('social_login.php', {
        'provider': 'google',
        'token': idToken,
        'name': account.displayName ?? account.email.split('@')[0],
      });
    } catch (e) {
      debugPrint('Google Sign In Error: $e');
      return {'status': 'error', 'message': 'Google Sign In failed: $e'};
    }
  }

  /// Signs the user in with Apple and calls the backend social_login.php endpoint.
  /// Only available on iOS / macOS natively. Returns null if cancelled.
  static Future<Map<String, dynamic>?> signInWithApple() async {
    try {
      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      final String? identityToken = credential.identityToken;
      if (identityToken == null) {
        return {
          'status': 'error',
          'message': 'Apple did not return an identity token.',
        };
      }

      // Apple only provides name/email on the VERY FIRST sign-in
      final String fullName = [
        credential.givenName ?? '',
        credential.familyName ?? '',
      ].where((s) => s.isNotEmpty).join(' ');

      return await ApiService.post('social_login.php', {
        'provider': 'apple',
        'token': identityToken,
        'user_identifier': credential.userIdentifier,
        'email': credential.email,
        'full_name': fullName.isNotEmpty ? fullName : null,
      });
    } on SignInWithAppleAuthorizationException catch (e) {
      if (e.code == AuthorizationErrorCode.canceled) return null; // user cancelled
      debugPrint('Apple Sign In Error: $e');
      return {'status': 'error', 'message': 'Apple Sign In failed: ${e.message}'};
    } catch (e) {
      debugPrint('Apple Sign In Error: $e');
      return {'status': 'error', 'message': 'Apple Sign In failed: $e'};
    }
  }

  /// Returns true if Apple Sign In is available on the current device/platform.
  static Future<bool> isAppleSignInAvailable() async {
    return await SignInWithApple.isAvailable();
  }
}
