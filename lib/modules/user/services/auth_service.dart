import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:smarttrip_ai/modules/admin/common/admin_constants.dart';
import 'package:smarttrip_ai/modules/user/common/auth_error_mapper.dart';
import 'package:smarttrip_ai/modules/user/models/auth_result.dart';
import 'package:smarttrip_ai/modules/user/models/delete_account_result.dart';

abstract class AuthServiceBase {
  Stream<User?> authStateChanges();

  bool get isSignedIn;
  String? get currentUserId;
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
  AuthService({
    FirebaseAuth? firebaseAuth,
    GoogleSignIn? googleSignIn,
    FirebaseFirestore? firestore,
  }) : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
       _googleSignIn = googleSignIn ?? GoogleSignIn(),
       _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _firebaseAuth;
  final GoogleSignIn _googleSignIn;
  final FirebaseFirestore _firestore;

  @override
  Stream<User?> authStateChanges() => _firebaseAuth.authStateChanges();

  @override
  bool get isSignedIn => _firebaseAuth.currentUser != null;

  @override
  String? get currentUserId => _firebaseAuth.currentUser?.uid;

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
      final UserCredential credential = await _firebaseAuth
          .createUserWithEmailAndPassword(
            email: email.trim(),
            password: password,
          );
      await _saveUserDocumentIfNeeded(credential.user);
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
      final UserCredential credential = await _firebaseAuth
          .signInWithEmailAndPassword(email: email.trim(), password: password);
      await _saveUserDocumentIfNeeded(credential.user);
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

      final UserCredential userCredential = await _firebaseAuth
          .signInWithCredential(credential);
      await _saveUserDocumentIfNeeded(userCredential.user);
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

  Future<void> _saveUserDocumentIfNeeded(User? user) async {
    final String? email = user?.email?.trim();
    if (user == null || email == null || email.isEmpty) {
      return;
    }
    if (AdminCredentials.isAdminEmail(email)) {
      return;
    }

    try {
      final DocumentReference<Map<String, dynamic>> document = _firestore
          .collection('users')
          .doc(user.uid);
      final DocumentSnapshot<Map<String, dynamic>> snapshot = await document
          .get();
      final String displayName = user.displayName?.trim().isNotEmpty == true
          ? user.displayName!.trim()
          : email.split('@').first;

      final Map<String, Object?> data = <String, Object?>{
        'name': displayName,
        'email': email,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (snapshot.exists) {
        if (!snapshot.data()!.containsKey('createdAt')) {
          data['createdAt'] = FieldValue.serverTimestamp();
        }
        await document.set(data, SetOptions(merge: true));
        return;
      }

      await document.set(<String, Object?>{
        ...data,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (_) {
      // Authentication should not fail because profile metadata could not save.
    }
  }
}
