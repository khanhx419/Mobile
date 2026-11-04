import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../models/app_user.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal() {
    // Mặc định khởi tạo tài khoản kiểm thử đầu tiên: Alice (Owner)
    _currentUser = testAccounts[0];
  }

  FirebaseAuth? _firebaseAuth;
  bool _isGoogleSignInInitialized = false;

  // Danh sách 3 tài khoản kiểm thử chuẩn + 1 tài khoản Unauthorized để phục vụ kiểm thử phân quyền
  static final List<AppUser> testAccounts = [
    AppUser(
      id: 'usr_alice_owner_101',
      email: 'alice.owner@student.edu.vn',
      displayName: 'Alice (Chủ sở hữu)',
      photoUrl: 'https://api.dicebear.com/7.x/bottts/png?seed=Alice',
      createdAt: DateTime(2026, 1, 1),
    ),
    AppUser(
      id: 'usr_bob_viewer_202',
      email: 'bob.viewer@student.edu.vn',
      displayName: 'Bob (Người xem - Viewer)',
      photoUrl: 'https://api.dicebear.com/7.x/bottts/png?seed=Bob',
      createdAt: DateTime(2026, 1, 2),
    ),
    AppUser(
      id: 'usr_charlie_editor_303',
      email: 'charlie.editor@student.edu.vn',
      displayName: 'Charlie (Chỉnh sửa - Editor)',
      photoUrl: 'https://api.dicebear.com/7.x/bottts/png?seed=Charlie',
      createdAt: DateTime(2026, 1, 3),
    ),
    AppUser(
      id: 'usr_dave_stranger_404',
      email: 'dave.stranger@student.edu.vn',
      displayName: 'Dave (Người lạ - Unauthorized)',
      photoUrl: 'https://api.dicebear.com/7.x/bottts/png?seed=Dave',
      createdAt: DateTime(2026, 1, 4),
    ),
  ];

  AppUser? _currentUser;
  final StreamController<AppUser?> _userController = StreamController<AppUser?>.broadcast();

  Stream<AppUser?> get authStateChanges => _userController.stream;
  AppUser? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null;

  void initialize({FirebaseAuth? auth}) {
    _firebaseAuth = auth;
  }

  Future<void> _ensureGoogleSignInInitialized() async {
    if (!_isGoogleSignInInitialized) {
      try {
        await GoogleSignIn.instance.initialize();
        _isGoogleSignInInitialized = true;
      } catch (e) {
        debugPrint('GoogleSignIn.initialize notification: $e');
      }
    }
  }

  /// Đăng nhập bằng tài khoản Google thông qua Firebase Authentication
  Future<AppUser?> signInWithGoogle() async {
    try {
      await _ensureGoogleSignInInitialized();
      final GoogleSignInAccount googleAccount = await GoogleSignIn.instance.authenticate();
      final GoogleSignInAuthentication googleAuth = googleAccount.authentication;

      final AuthCredential credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
      );

      _firebaseAuth ??= FirebaseAuth.instance;
      final UserCredential userCredential = await _firebaseAuth!.signInWithCredential(credential);
      final User? fbUser = userCredential.user;

      if (fbUser != null) {
        _currentUser = AppUser(
          id: fbUser.uid,
          email: fbUser.email ?? googleAccount.email,
          displayName: fbUser.displayName ?? googleAccount.displayName ?? 'Người dùng Google',
          photoUrl: fbUser.photoURL ?? googleAccount.photoUrl ?? '',
          createdAt: fbUser.metadata.creationTime ?? DateTime.now(),
        );
        _userController.add(_currentUser);
        return _currentUser;
      }
    } catch (e) {
      debugPrint('Lỗi xác thực Google Sign-In Firebase: $e. Sử dụng tài khoản thử nghiệm fallback.');
      // Nếu môi trường desktop/thiếu SHA-1 không thể mở popup Google, fallback sang tài khoản Alice
      _currentUser = testAccounts[0];
      _userController.add(_currentUser);
      return _currentUser;
    }
    return null;
  }

  /// Chuyển đổi giữa các tài khoản kiểm thử để xác minh quyền hạn (Checklist Mục 6)
  void switchTestAccount(AppUser targetUser) {
    _currentUser = targetUser;
    _userController.add(_currentUser);
  }

  /// Chuyển đổi bằng index (0: Alice, 1: Bob, 2: Charlie, 3: Dave)
  void switchTestAccountByIndex(int index) {
    if (index >= 0 && index < testAccounts.length) {
      switchTestAccount(testAccounts[index]);
    }
  }

  /// Đăng xuất tài khoản
  Future<void> signOut() async {
    try {
      await _firebaseAuth?.signOut();
      await GoogleSignIn.instance.signOut();
    } catch (_) {}
    _currentUser = null;
    _userController.add(null);
  }

  void dispose() {
    _userController.close();
  }
}
