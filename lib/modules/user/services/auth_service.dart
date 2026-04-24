import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:smarttrip_ai/modules/user/common/auth_error_mapper.dart';
import 'package:smarttrip_ai/modules/user/models/auth_result.dart';
import 'package:smarttrip_ai/modules/user/models/delete_account_result.dart';

abstract class AuthServiceBase {
  Stream<User?> authStateChanges();

  bool get isSignedIn;
  String? get currentUserEmail;
  String get currentUserProviderLabel;

  Future<AuthResult> signUpWithEmail({
    required String email,
    required String password,
  });

  Future<AuthResult> signInWithEmail({
    required String email,
    required String password,
  });

  Future<AuthResult> sendPasswordResetEmail(String email);
  Future<AuthResult> signInWithGoogle();

  Future<void> signOut();
  Future<DeleteAccountResult> deleteCurrentUser();
}

class AuthService implements AuthServiceBase {
  AuthService({FirebaseAuth? firebaseAuth, GoogleSignIn? googleSignIn})
    : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
      _googleSignIn = googleSignIn ?? GoogleSignIn();

  final FirebaseAuth _firebaseAuth;
  final GoogleSignIn _googleSignIn;

  @override
  Stream<User?> authStateChanges() => _firebaseAuth.authStateChanges();

  @override
  bool get isSignedIn => _firebaseAuth.currentUser != null;

  @override
  String? get currentUserEmail => _firebaseAuth.currentUser?.email;

  @override
  String get currentUserProviderLabel {
    final User? user = _firebaseAuth.currentUser;
    if (user == null) {
      return 'Not signed in';
    }

    final Set<String> providerIds = user.providerData
        .map((UserInfo userInfo) => userInfo.providerId)
        .where((String providerId) => providerId.isNotEmpty)
        .toSet();

    if (providerIds.contains(GoogleAuthProvider.PROVIDER_ID)) {
      return 'Google';
    }

    if (providerIds.contains('password') || user.email != null) {
      return 'Email';
    }

    return 'Unknown';
  }

  @override
  Future<AuthResult> signUpWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      await _firebaseAuth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      return AuthResult.success;
    } on FirebaseAuthException catch (error) {
      return AuthResult.failure(mapFirebaseAuthErrorCode(error.code));
    } catch (_) {
      return AuthResult.failure('Unable to create account right now.');
    }
  }

  @override
  Future<AuthResult> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      await _firebaseAuth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      return AuthResult.success;
    } on FirebaseAuthException catch (error) {
      return AuthResult.failure(mapFirebaseAuthErrorCode(error.code));
    } catch (_) {
      return AuthResult.failure('Unable to log in right now.');
    }
  }

  @override
  Future<AuthResult> sendPasswordResetEmail(String email) async {
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email.trim());
      return AuthResult.success;
    } on FirebaseAuthException catch (error) {
      return AuthResult.failure(mapFirebaseAuthErrorCode(error.code));
    } catch (_) {
      return AuthResult.failure('Unable to send reset email.');
    }
  }

  @override
  Future<AuthResult> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        return AuthResult.failure('Google sign-in was canceled.');
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      await _firebaseAuth.signInWithCredential(credential);
      return AuthResult.success;
    } on FirebaseAuthException catch (error) {
      return AuthResult.failure(mapFirebaseAuthErrorCode(error.code));
    } catch (error) {
      return AuthResult.failure(mapGoogleSignInError(error));
    }
  }

  @override
  Future<void> signOut() async {
    await Future.wait(<Future<void>>[
      _firebaseAuth.signOut(),
      _googleSignIn.signOut(),
    ]);
  }

  @override
  Future<DeleteAccountResult> deleteCurrentUser() async {
    final User? user = _firebaseAuth.currentUser;
    if (user == null) {
      return DeleteAccountResult.noUser(
        message: 'No account is currently signed in.',
      );
    }

    try {
      await user.delete();
      await _googleSignIn.signOut();
      return DeleteAccountResult.success();
    } on FirebaseAuthException catch (error) {
      if (error.code == 'requires-recent-login') {
        return DeleteAccountResult.requiresRecentLogin(
          message:
              'Please log in again to verify your identity before deleting your account.',
        );
      }
      return DeleteAccountResult.failure(mapFirebaseAuthErrorCode(error.code));
    } catch (_) {
      return DeleteAccountResult.failure(
        'Unable to delete account right now. Please try again.',
      );
    }
  }
}
