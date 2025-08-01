import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'firestore_user_service.dart';

/// Firebase Authentication Service
/// Handles user authentication operations including sign in, sign up, and sign out
class AuthService extends ChangeNotifier {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final FirestoreUserService _firestoreUserService = FirestoreUserService();
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;
  bool _isGoogleSignInInitialized = false;

  /// Current authenticated user
  User? get currentUser => _firebaseAuth.currentUser;

  /// Stream of authentication state changes
  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();

  /// Check if user is currently authenticated
  bool get isAuthenticated => currentUser != null;

  /// Initialize Google Sign-In
  Future<void> _initializeGoogleSignIn() async {
    if (!_isGoogleSignInInitialized) {
      try {
        await _googleSignIn.initialize();
        _isGoogleSignInInitialized = true;
      } catch (e) {
        debugPrint('Failed to initialize Google Sign-In: $e');
      }
    }
  }

  /// Sign in with email and password
  Future<UserCredential?> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      notifyListeners();
      return credential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw 'An unexpected error occurred. Please try again.';
    }
  }

  /// Create account with email and password
  Future<UserCredential?> createUserWithEmailAndPassword({
    required String email,
    required String password,
    String? displayName,
  }) async {
    try {
      final credential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Update display name if provided
      if (displayName != null && credential.user != null) {
        await credential.user!.updateDisplayName(displayName);
        await credential.user!.reload();
      }

      // Create user profile in Firestore
      if (credential.user != null) {
        await _firestoreUserService.initializeUserProfile(
          userId: credential.user!.uid,
          name: displayName ?? '',
          email: email,
          phoneNumber: credential.user!.phoneNumber,
          photoURL: credential.user!.photoURL,
        );
      }

      notifyListeners();
      return credential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw 'An unexpected error occurred. Please try again.';
    }
  }

  /// Sign in with Google
  Future<UserCredential?> signInWithGoogle() async {
    await _initializeGoogleSignIn();

    try {
      // Trigger the authentication flow
      final GoogleSignInAccount googleUser = await _googleSignIn.authenticate(
        scopeHint: ['email', 'profile'],
      );

      // Get authentication details
      final GoogleSignInAuthentication googleAuth = googleUser.authentication;

      // Get authorization for access token
      final authClient = _googleSignIn.authorizationClient;
      final authorization =
          await authClient.authorizationForScopes(['email', 'profile']);

      // Create a new credential
      final credential = GoogleAuthProvider.credential(
        accessToken: authorization?.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase with the Google credentials
      final userCredential =
          await _firebaseAuth.signInWithCredential(credential);

      // Create user profile in Firestore if this is a new user
      if (userCredential.user != null) {
        await _firestoreUserService.initializeUserProfile(
          userId: userCredential.user!.uid,
          name:
              userCredential.user!.displayName ?? googleUser.displayName ?? '',
          email: userCredential.user!.email ?? googleUser.email,
          phoneNumber: userCredential.user!.phoneNumber,
          photoURL: userCredential.user!.photoURL,
        );
      }

      notifyListeners();
      return userCredential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw 'Failed to sign in with Google. Please try again.';
    }
  }

  /// Sign out current user
  Future<void> signOut() async {
    try {
      // Sign out from Google (this will handle if user is not signed in)
      await _googleSignIn.signOut();

      // Sign out from Firebase
      await _firebaseAuth.signOut();
      notifyListeners();
    } catch (e) {
      throw 'Failed to sign out. Please try again.';
    }
  }

  /// Send password reset email
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw 'Failed to send password reset email. Please try again.';
    }
  }

  /// Delete current user account
  Future<void> deleteAccount() async {
    try {
      await currentUser?.delete();
      notifyListeners();
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw 'Failed to delete account. Please try again.';
    }
  }

  /// Handle Firebase Auth exceptions and return user-friendly messages
  String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No user found with this email address.';
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      case 'email-already-in-use':
        return 'An account already exists with this email address.';
      case 'weak-password':
        return 'Password is too weak. Please choose a stronger password.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'user-disabled':
        return 'This account has been disabled. Please contact support.';
      case 'too-many-requests':
        return 'Too many failed attempts. Please try again later.';
      case 'operation-not-allowed':
        return 'This sign-in method is not enabled. Please contact support.';
      case 'requires-recent-login':
        return 'Please sign in again to complete this action.';
      default:
        return e.message ??
            'An authentication error occurred. Please try again.';
    }
  }
}
