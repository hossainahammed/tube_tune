import 'package:flutter/foundation.dart';
import '../../models/user_model.dart';
import 'storage_service.dart';

/// Authentication Service managing Google & YouTube user accounts.
class AuthService with ChangeNotifier {
  static AuthService? _instance;
  final StorageService storage;
  UserModel _currentUser = const UserModel();

  AuthService._(this.storage) {
    _loadUser();
  }

  static Future<AuthService> getInstance(StorageService storage) async {
    _instance ??= AuthService._(storage);
    return _instance!;
  }

  UserModel get currentUser => _currentUser;
  bool get isLoggedIn => _currentUser.isLoggedIn;

  void _loadUser() {
    _currentUser = storage.getUserData();
    notifyListeners();
  }

  /// Sign In with Google account details
  Future<void> signInWithGoogle({
    required String name,
    required String email,
    String? avatarUrl,
  }) async {
    _currentUser = UserModel(
      id: 'g_${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      email: email,
      avatarUrl: avatarUrl?.isNotEmpty == true ? avatarUrl! : '',
      channelName: '$name Official',
      subscribersCount: 1420,
      isLoggedIn: true,
    );

    await storage.saveUserData(_currentUser);
    notifyListeners();
  }

  /// Sign out
  Future<void> signOut() async {
    _currentUser = const UserModel();
    await storage.clearUserData();
    notifyListeners();
  }
}
