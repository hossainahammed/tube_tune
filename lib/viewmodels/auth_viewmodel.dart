import 'package:flutter/foundation.dart';
import '../core/services/auth_service.dart';
import '../models/user_model.dart';

/// ViewModel managing Google & YouTube Authentication State.
class AuthViewModel with ChangeNotifier {
  final AuthService authService;

  AuthViewModel({required this.authService}) {
    authService.addListener(notifyListeners);
  }

  UserModel get currentUser => authService.currentUser;
  bool get isLoggedIn => authService.isLoggedIn;

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

  Future<void> signOut() async {
    await authService.signOut();
  }

  @override
  void dispose() {
    authService.removeListener(notifyListeners);
    super.dispose();
  }
}
