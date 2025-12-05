import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import '../data/repositories/auth_repository.dart';
import '../models/user.dart' as app_models;
import '../core/utils/logger.dart';

class AuthController extends ChangeNotifier {
  AuthRepository _repository;

  app_models.User? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;

  app_models.User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _currentUser != null;
  bool get isAnonymous => _repository.currentUser?.isAnonymous ?? false;

  AuthController(this._repository) {
    _repository.authStateChanges.listen((firebaseUser) {
      if (firebaseUser != null) {
        _loadCurrentUserData();
      } else {
        _currentUser = null;
        notifyListeners();
      }
    });

    _loadCurrentUserData();
  }

  /// Repository를 업데이트 (ProxyProvider용)
  void updateRepository(AuthRepository repository) {
    _repository = repository;
  }

  Future<void> _loadCurrentUserData() async {
    try {
      _currentUser = await _repository.getCurrentUserData();
      notifyListeners();
    } catch (e) {
      Logger.error('Failed to load current user data', e);
    }
  }

  Future<bool> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      _setLoading(true);
      _clearError();

      final user = await _repository.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (user != null) {
        _currentUser = user;
        Logger.info('User signed in: ${user.uid}');
        return true;
      }

      return false;
    } on firebase_auth.FirebaseAuthException catch (e) {
      _setError(_repository.getErrorMessage(e) ?? '로그인 실패');
      return false;
    } catch (e) {
      _setError('로그인 중 오류가 발생했습니다.');
      Logger.error('Sign in failed', e);
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> signUpWithEmail({
    required String email,
    required String password,
    required String displayName,
  }) async {
    try {
      _setLoading(true);
      _clearError();

      final user = await _repository.signUpWithEmailAndPassword(
        email: email,
        password: password,
        displayName: displayName,
      );

      if (user != null) {
        _currentUser = user;
        Logger.info('User signed up: ${user.uid}');
        return true;
      }

      return false;
    } on firebase_auth.FirebaseAuthException catch (e) {
      _setError(_repository.getErrorMessage(e) ?? '회원가입 실패');
      return false;
    } catch (e) {
      _setError('회원가입 중 오류가 발생했습니다.');
      Logger.error('Sign up failed', e);
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> signInWithGoogle() async {
    try {
      _setLoading(true);
      _clearError();

      final user = await _repository.signInWithGoogle();

      if (user != null) {
        _currentUser = user;
        Logger.info('User signed in with Google: ${user.uid}');
        return true;
      }

      return false;
    } catch (e) {
      _setError('Google 로그인 중 오류가 발생했습니다.');
      Logger.error('Google sign in failed', e);
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> signInAnonymously() async {
    try {
      _setLoading(true);
      _clearError();

      final user = await _repository.signInAnonymously();

      if (user != null) {
        _currentUser = user;
        Logger.info('User signed in anonymously: ${user.uid}');
        return true;
      }

      return false;
    } catch (e) {
      _setError('익명 로그인 중 오류가 발생했습니다.');
      Logger.error('Anonymous sign in failed', e);
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> signOut() async {
    try {
      _setLoading(true);
      await _repository.signOut();
      _currentUser = null;
      Logger.info('User signed out');
    } catch (e) {
      _setError('로그아웃 중 오류가 발생했습니다.');
      Logger.error('Sign out failed', e);
    } finally {
      _setLoading(false);
    }
  }

  Future<void> deleteAccount() async {
    try {
      _setLoading(true);
      await _repository.deleteAccount();
      _currentUser = null;
      Logger.info('Account deleted');
    } catch (e) {
      _setError('계정 삭제 중 오류가 발생했습니다.');
      Logger.error('Account deletion failed', e);
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> sendPasswordResetEmail(String email) async {
    try {
      _setLoading(true);
      _clearError();
      
      await _repository.sendPasswordResetEmail(email);
      Logger.info('Password reset email sent to: $email');
      return true;
    } catch (e) {
      _setError('비밀번호 재설정 이메일 전송에 실패했습니다.');
      Logger.error('Password reset email failed', e);
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> updateProfile({
    String? displayName,
    String? photoURL,
    String? bio,
  }) async {
    try {
      _setLoading(true);
      _clearError();

      await _repository.updateProfile(
        displayName: displayName,
        photoURL: photoURL,
        bio: bio,
      );

      await _loadCurrentUserData();
      
      Logger.info('Profile updated');
      return true;
    } catch (e) {
      _setError('프로필 업데이트에 실패했습니다.');
      Logger.error('Profile update failed', e);
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> linkAnonymousWithEmail({
    required String email,
    required String password,
    required String displayName,
  }) async {
    try {
      _setLoading(true);
      _clearError();

      final user = await _repository.linkAnonymousWithEmail(
        email: email,
        password: password,
        displayName: displayName,
      );

      if (user != null) {
        _currentUser = user;
        Logger.info('Anonymous account linked with email: ${user.uid}');
        return true;
      }

      return false;
    } on firebase_auth.FirebaseAuthException catch (e) {
      _setError(_repository.getErrorMessage(e) ?? '계정 연결 실패');
      return false;
    } catch (e) {
      _setError('계정 연결 중 오류가 발생했습니다.');
      Logger.error('Link anonymous with email failed', e);
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> linkAnonymousWithGoogle() async {
    try {
      _setLoading(true);
      _clearError();

      final user = await _repository.linkAnonymousWithGoogle();

      if (user != null) {
        _currentUser = user;
        Logger.info('Anonymous account linked with Google: ${user.uid}');
        return true;
      }

      return false;
    } catch (e) {
      _setError('Google 계정 연결 중 오류가 발생했습니다.');
      Logger.error('Link anonymous with Google failed', e);
      return false;
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String message) {
    _errorMessage = message;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void clearError() {
    _clearError();
  }
}
