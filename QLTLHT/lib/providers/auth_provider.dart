import 'dart:async';
import 'package:flutter/material.dart';
import '../models/app_user.dart';
import '../services/auth_service.dart';
import '../services/supabase_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService;
  final SupabaseService _supabaseService;

  AppUser? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;
  StreamSubscription<AppUser?>? _authSubscription;

  AuthProvider({
    AuthService? authService,
    SupabaseService? supabaseService,
  })  : _authService = authService ?? AuthService(),
        _supabaseService = supabaseService ?? SupabaseService() {
    _currentUser = _authService.currentUser;
    _authSubscription = _authService.authStateChanges.listen((user) {
      _currentUser = user;
      if (user != null) {
        _supabaseService.upsertUser(user);
      }
      notifyListeners();
    });
    // Đồng bộ user ban đầu lên Supabase
    if (_currentUser != null) {
      _supabaseService.upsertUser(_currentUser!);
    }
  }

  AppUser? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<AppUser> get testAccounts => AuthService.testAccounts;

  int get currentAccountIndex {
    if (_currentUser == null) return 0;
    final idx = AuthService.testAccounts.indexWhere((u) => u.id == _currentUser!.id);
    return idx >= 0 ? idx : 0;
  }

  Future<bool> signInWithGoogle() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final user = await _authService.signInWithGoogle();
      _isLoading = false;
      if (user != null) {
        await _supabaseService.upsertUser(user);
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  void switchTestAccount(AppUser user) {
    _authService.switchTestAccount(user);
    _supabaseService.upsertUser(user);
    notifyListeners();
  }

  void switchTestAccountByIndex(int index) {
    _authService.switchTestAccountByIndex(index);
    if (_authService.currentUser != null) {
      _supabaseService.upsertUser(_authService.currentUser!);
    }
    notifyListeners();
  }

  Future<void> signOut() async {
    await _authService.signOut();
    notifyListeners();
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }
}
