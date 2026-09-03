import 'package:flutter/foundation.dart';
import '../core/services/auth_service.dart';
import '../models/user_model.dart';

/// ViewModel managing Google & YouTube Authentication State with Official Google Sign-In support.
class AuthViewModel with ChangeNotifier {
  final AuthService authService;

  AuthViewModel({required this.authService}) {
    authService.addListener(notifyListeners);
  }

  UserModel get currentUser => authService.currentUser;
  bool get isLoggedIn => authService.isLoggedIn;
  List<UserModel> get savedAccounts => authService.savedAccounts;

  /// Sign in via official native Google Play Services popup dialog
  Future<bool> signInWithOfficialGoogle() async {
    try {
      final account = await authService.signInWithOfficialGoogle();
      return account != null;
    } catch (e) {
      rethrow;
    }
  }

  Future<bool> signInWithRealGmail({
    required String email,
    String? name,
    String? avatarUrl,
  }) async {
    return await authService.signInWithRealGmail(
      email: email,
      name: name,
      avatarUrl: avatarUrl,
    );
  }

  Future<void> signInWithGoogle({
    required String name,
    required String email,
    String? avatarUrl,
  }) async {
    await authService.signInWithGoogle(
      name: name,
      email: email,
      avatarUrl: avatarUrl,
    );
  }

  Future<void> switchAccount(UserModel user) async {
    await authService.switchAccount(user);
  }

  Future<void> removeAccount(String email) async {
    await authService.removeAccount(email);
  }

  Future<void> signOut() async {
    await authService.signOut();
  }

  @override
  void dispose() {
    authService.removeListener(notifyListeners);
    super.dispose();
  }
}
