import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../../models/user.dart' as app_models;
import '../../core/utils/logger.dart';

class AuthRepository {
  final AuthService _authService = AuthService();
  final FirestoreService _firestoreService = FirestoreService();

  User? get currentUser => _authService.currentUser;
  
  Stream<User?> get authStateChanges => _authService.authStateChanges;

  Future<app_models.User?> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _authService.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential?.user != null) {
        return await _getOrCreateUserDocument(credential!.user!);
      }
      
      return null;
    } catch (e) {
      Logger.error('Sign in failed in repository', e);
      rethrow;
    }
  }

  Future<app_models.User?> signUpWithEmailAndPassword({
    required String email,
    required String password,
    required String displayName,
  }) async {
    try {
      final credential = await _authService.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential?.user != null) {
        await _authService.updateDisplayName(displayName);
        return await _createUserDocument(
          credential!.user!,
          displayName: displayName,
        );
      }
      
      return null;
    } catch (e) {
      Logger.error('Sign up failed in repository', e);
      rethrow;
    }
  }

  Future<app_models.User?> signInWithGoogle() async {
    try {
      final credential = await _authService.signInWithGoogle();

      if (credential?.user != null) {
        return await _getOrCreateUserDocument(credential!.user!);
      }
      
      return null;
    } catch (e) {
      Logger.error('Google sign in failed in repository', e);
      rethrow;
    }
  }

  Future<app_models.User?> signInAnonymously() async {
    try {
      final credential = await _authService.signInAnonymously();

      if (credential?.user != null) {
        // 기존 문서가 있으면 가져오고, 없으면 생성
        return await _getOrCreateUserDocument(credential!.user!);
      }
      
      return null;
    } catch (e) {
      Logger.error('Anonymous sign in failed in repository', e);
      rethrow;
    }
  }

  Future<app_models.User?> linkAnonymousWithEmail({
    required String email,
    required String password,
    required String displayName,
  }) async {
    try {
      final currentFirebaseUser = currentUser;
      if (currentFirebaseUser == null || !currentFirebaseUser.isAnonymous) {
        throw Exception('현재 익명 사용자가 아닙니다.');
      }

      Logger.info('Linking anonymous account with email in repository');
      
      // 익명 계정을 이메일 계정으로 연결
      await _authService.linkWithEmailAndPassword(
        email: email,
        password: password,
      );

      // displayName 업데이트
      await _authService.updateDisplayName(displayName);

      // Firestore의 사용자 문서 업데이트
      await _firestoreService.updateDocument('users', currentFirebaseUser.uid, {
        'email': email,
        'displayName': displayName,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      Logger.info('Anonymous account linked successfully');
      
      // 업데이트된 사용자 정보 반환
      return await getCurrentUserData();
    } catch (e) {
      Logger.error('Failed to link anonymous account', e);
      rethrow;
    }
  }

  Future<app_models.User?> linkAnonymousWithGoogle() async {
    try {
      final currentFirebaseUser = currentUser;
      if (currentFirebaseUser == null || !currentFirebaseUser.isAnonymous) {
        throw Exception('현재 익명 사용자가 아닙니다.');
      }

      Logger.info('Linking anonymous account with Google in repository');

      // Google 인증 정보 가져오기
      final googleCredential = await _authService.signInWithGoogle();
      if (googleCredential == null) {
        Logger.info('Google sign in cancelled');
        return null;
      }

      // 이미 로그인되어 계정이 연결됨
      Logger.info('Anonymous account linked with Google successfully');
      
      // 사용자 문서가 이미 존재하는지 확인하고 업데이트
      return await getCurrentUserData();
    } catch (e) {
      Logger.error('Failed to link anonymous account with Google', e);
      rethrow;
    }
  }

  Future<void> signOut() async {
    await _authService.signOut();
  }

  Future<void> deleteAccount() async {
    try {
      final userId = currentUser?.uid;
      if (userId != null) {
        await _firestoreService.deleteDocument('users', userId);
      }
      await _authService.deleteAccount();
    } catch (e) {
      Logger.error('Account deletion failed in repository', e);
      rethrow;
    }
  }

  Future<void> sendPasswordResetEmail(String email) async {
    await _authService.sendPasswordResetEmail(email);
  }

  Future<void> updateProfile({
    String? displayName,
    String? photoURL,
    String? bio,
  }) async {
    try {
      final userId = currentUser?.uid;
      if (userId == null) {
        throw Exception('No user logged in');
      }

      final updates = <String, dynamic>{};
      
      if (displayName != null) {
        await _authService.updateDisplayName(displayName);
        updates['displayName'] = displayName;
      }
      
      if (photoURL != null) {
        await _authService.updatePhotoURL(photoURL);
        updates['photoURL'] = photoURL;
      }
      
      if (bio != null) {
        updates['bio'] = bio;
      }

      if (updates.isNotEmpty) {
        updates['updatedAt'] = FieldValue.serverTimestamp();
        await _firestoreService.updateDocument('users', userId, updates);
      }
    } catch (e) {
      Logger.error('Profile update failed', e);
      rethrow;
    }
  }

  Future<app_models.User?> getCurrentUserData() async {
    try {
      final userId = currentUser?.uid;
      if (userId == null) return null;

      final snapshot = await _firestoreService.getDocument('users', userId);
      
      if (!snapshot.exists) {
        return await _createUserDocument(currentUser!);
      }

      return app_models.User.fromFirestore(snapshot);
    } catch (e) {
      Logger.error('Failed to get current user data', e);
      return null;
    }
  }

  Stream<app_models.User?> streamCurrentUserData() {
    final userId = currentUser?.uid;
    if (userId == null) {
      return Stream.value(null);
    }

    return _firestoreService.streamDocument('users', userId).map((snapshot) {
      if (!snapshot.exists) return null;
      return app_models.User.fromFirestore(snapshot);
    });
  }

  Future<app_models.User> _getOrCreateUserDocument(User firebaseUser) async {
    try {
      final snapshot = await _firestoreService.getDocument('users', firebaseUser.uid);

      if (snapshot.exists) {
        return app_models.User.fromFirestore(snapshot);
      } else {
        return await _createUserDocument(firebaseUser);
      }
    } catch (e) {
      Logger.error('Failed to get or create user document', e);
      rethrow;
    }
  }

  Future<app_models.User> _createUserDocument(
    User firebaseUser, {
    String? displayName,
  }) async {
    try {
      final now = Timestamp.now();
      final userData = {
        'uid': firebaseUser.uid,
        'email': firebaseUser.email ?? '',
        'displayName': displayName ?? firebaseUser.displayName ?? '사용자',
        'photoURL': firebaseUser.photoURL ?? '',
        'bio': '',
        'followerCount': 0,
        'followingCount': 0,
        'createdRecipeCount': 0,
        'preferences': {
          'locale': 'ko-KR',
          'favoriteTags': <String>[],
          'weeklyGoal': 3,
        },
        'createdAt': now,
        'updatedAt': now,
      };

      await _firestoreService.setDocument('users', firebaseUser.uid, userData);
      
      Logger.info('User document created: ${firebaseUser.uid}');
      
      final snapshot = await _firestoreService.getDocument('users', firebaseUser.uid);
      return app_models.User.fromFirestore(snapshot);
    } catch (e) {
      Logger.error('Failed to create user document', e);
      rethrow;
    }
  }

  String? getErrorMessage(dynamic error) {
    if (error is FirebaseAuthException) {
      return _authService.getErrorMessage(error);
    }
    return error.toString();
  }

  /// Dispose 메서드 (필요시 리소스 정리)
  void dispose() {
    // Repository는 일반적으로 정리할 리소스가 없음
  }
}
