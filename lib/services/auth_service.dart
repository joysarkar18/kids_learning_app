import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:kids_learning/services/logger_service.dart';
import 'package:kids_learning/services/notification_service.dart';
import 'package:kids_learning/services/user_service.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  static AuthService get instance => _instance;

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  User? get currentUser => _auth.currentUser;

  bool get isLoggedIn => _auth.currentUser != null;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<User?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        LoggerService.logInfo('Google Sign-In cancelled by user');
        return null;
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential = await _auth.signInWithCredential(
        credential,
      );

      LoggerService.logInfo(
        'Google Sign-In successful: ${userCredential.user?.email}',
      );

      // Save user data with FCM token
      if (userCredential.user != null) {
        await UserService.instance.saveUserData(userCredential.user!);
      }

      return userCredential.user;
    } on FirebaseAuthException catch (e) {
      LoggerService.logError('Firebase Auth Error: ${e.message}');
      rethrow;
    } catch (e) {
      LoggerService.logError('Google Sign-In Error: $e');
      rethrow;
    }
  }

  Future<User?> signInWithApple() async {
    if (!Platform.isIOS) {
      LoggerService.logError('Apple Sign-In is only available on iOS');
      return null;
    }

    try {
      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      final oauthCredential = OAuthProvider('apple.com').credential(
        idToken: appleCredential.identityToken,
        accessToken: appleCredential.authorizationCode,
      );

      final UserCredential userCredential = await _auth.signInWithCredential(
        oauthCredential,
      );

      // Apple only provides name on first sign-in, update profile if available
      final user = userCredential.user;
      if (user != null &&
          appleCredential.givenName != null &&
          (user.displayName == null || user.displayName!.isEmpty)) {
        final displayName =
            '${appleCredential.givenName ?? ''} ${appleCredential.familyName ?? ''}'
                .trim();
        if (displayName.isNotEmpty) {
          await user.updateDisplayName(displayName);
          await user.reload();
        }
      }

      LoggerService.logInfo(
        'Apple Sign-In successful: ${userCredential.user?.email}',
      );

      // Save user data with FCM token
      if (userCredential.user != null) {
        await UserService.instance.saveUserData(userCredential.user!);
      }

      return _auth.currentUser;
    } catch (e) {
      if (e is SignInWithAppleAuthorizationException &&
          e.code == AuthorizationErrorCode.canceled) {
        LoggerService.logInfo('Apple Sign-In cancelled by user');
        return null;
      }
      LoggerService.logError('Apple Sign-In Error: $e');
      rethrow;
    }
  }

  Future<void> signOut() async {
    try {
      // Delete FCM token from Firestore before signing out
      await UserService.instance.deleteFCMToken();

      // Delete FCM token from device
      await NotificationService.instance.deleteFCMToken();

      await Future.wait([_auth.signOut(), _googleSignIn.signOut()]);
      LoggerService.logInfo('User signed out');
    } catch (e) {
      LoggerService.logError('Sign-Out Error: $e');
    }
  }
}
