import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../core/utils/logger.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  User? get currentUser => _auth.currentUser;
  
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<UserCredential?> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      Logger.info('Signing in with email: $email');
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      Logger.info('Sign in successful: ${credential.user?.uid}');
      return credential;
    } on FirebaseAuthException catch (e) {
      Logger.error('Sign in failed', e);
      rethrow;
    }
  }

  Future<UserCredential?> createUserWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      Logger.info('Creating user with email: $email');
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      Logger.info('User created: ${credential.user?.uid}');
      return credential;
    } on FirebaseAuthException catch (e) {
      Logger.error('User creation failed', e);
      rethrow;
    }
  }

  Future<UserCredential?> signInWithGoogle() async {
    try {
      Logger.info('Starting Google sign in');
      
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      
      if (googleUser == null) {
        Logger.info('Google sign in cancelled by user');
        return null;
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _auth.signInWithCredential(credential);
      Logger.info('Google sign in successful: ${userCredential.user?.uid}');
      return userCredential;
    } catch (e) {
      Logger.error('Google sign in failed', e);
      rethrow;
    }
  }

  Future<UserCredential?> signInAnonymously() async {
    try {
      Logger.info('Signing in anonymously');
      final credential = await _auth.signInAnonymously();
      Logger.info('Anonymous sign in successful: ${credential.user?.uid}');
      return credential;
    } catch (e) {
      Logger.error('Anonymous sign in failed', e);
      rethrow;
    }
  }

  Future<void> linkWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null || !user.isAnonymous) {
        throw Exception('No anonymous user to link');
      }

      Logger.info('Linking anonymous account with email: $email');
      final credential = EmailAuthProvider.credential(
        email: email,
        password: password,
      );

      await user.linkWithCredential(credential);
      Logger.info('Account linked successfully');
    } catch (e) {
      Logger.error('Account linking failed', e);
      rethrow;
    }
  }

  Future<void> signOut() async {
    try {
      Logger.info('Signing out');
      await Future.wait([
        _auth.signOut(),
        _googleSignIn.signOut(),
      ]);
      Logger.info('Sign out successful');
    } catch (e) {
      Logger.error('Sign out failed', e);
      rethrow;
    }
  }

  Future<void> deleteAccount() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('No user to delete');
      }

      Logger.info('Deleting user account: ${user.uid}');
      await user.delete();
      Logger.info('Account deleted successfully');
    } catch (e) {
      Logger.error('Account deletion failed', e);
      rethrow;
    }
  }

  Future<void> sendPasswordResetEmail(String email) async {
    try {
      Logger.info('Sending password reset email to: $email');
      await _auth.sendPasswordResetEmail(email: email);
      Logger.info('Password reset email sent');
    } catch (e) {
      Logger.error('Password reset email failed', e);
      rethrow;
    }
  }

  Future<void> updateDisplayName(String displayName) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('No user to update');
      }

      Logger.info('Updating display name to: $displayName');
      await user.updateDisplayName(displayName);
      await user.reload();
      Logger.info('Display name updated');
    } catch (e) {
      Logger.error('Display name update failed', e);
      rethrow;
    }
  }

  Future<void> updatePhotoURL(String photoURL) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('No user to update');
      }

      Logger.info('Updating photo URL');
      await user.updatePhotoURL(photoURL);
      await user.reload();
      Logger.info('Photo URL updated');
    } catch (e) {
      Logger.error('Photo URL update failed', e);
      rethrow;
    }
  }

  String? getErrorMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return '이메일 또는 비밀번호가 잘못되었습니다.';
      case 'wrong-password':
        return '이메일 또는 비밀번호가 잘못되었습니다.';
      case 'email-already-in-use':
        return '이미 사용 중인 이메일입니다.';
      case 'weak-password':
        return '비밀번호는 6자 이상이어야 합니다.';
      case 'invalid-email':
        return '올바른 이메일 형식이 아닙니다.';
      case 'operation-not-allowed':
        return '로그인 방법이 비활성화되어 있습니다.';
      case 'user-disabled':
        return '계정이 비활성화되었습니다.';
      default:
        return '로그인 중 오류가 발생했습니다: ${e.message}';
    }
  }
}
