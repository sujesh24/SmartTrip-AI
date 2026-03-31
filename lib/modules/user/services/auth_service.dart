import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:smarttrip_ai/modules/user/common/auth_error_mapper.dart';
import 'package:smarttrip_ai/modules/user/models/auth_result.dart';

class AuthService {
  AuthService({FirebaseAuth? firebaseAuth, GoogleSignIn? googleSignIn})
    : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
      _googleSignIn = googleSignIn ?? GoogleSignIn();

  final FirebaseAuth _firebaseAuth;
  final GoogleSignIn _googleSignIn;

  User? get currentUser => _firebaseAuth.currentUser;

  Stream<User?> authStateChanges() => _firebaseAuth.authStateChanges();

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

  Future<void> signOut() async {
    await Future.wait(<Future<void>>[
      _firebaseAuth.signOut(),
      _googleSignIn.signOut(),
    ]);
  }
}
