import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../models/user_model.dart';
import 'storage_service.dart';

/// Authentication Service managing Google & YouTube user accounts with Official Google Sign-In support.
class AuthService with ChangeNotifier {
  static AuthService? _instance;
  final StorageService storage;
  UserModel _currentUser = const UserModel();

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    serverClientId: '718728761301-qklk804a29elej8sdsur5qkktkkarp2m.apps.googleusercontent.com',
    scopes: [
      'email',
      'https://www.googleapis.com/auth/userinfo.profile',
    ],
  );

  AuthService._(this.storage) {
    _loadUser();
  }

  static Future<AuthService> getInstance(StorageService storage) async {
    _instance ??= AuthService._(storage);
    return _instance!;
  }

  UserModel get currentUser => _currentUser;
  bool get isLoggedIn => _currentUser.isLoggedIn;
  List<UserModel> get savedAccounts => storage.getSavedAccounts();
  GoogleSignIn get googleSignIn => _googleSignIn;

  void _loadUser() {
    _currentUser = storage.getUserData();
    notifyListeners();
  }

  /// Format an email username into a capitalized full name
  static String formatNameFromEmail(String email) {
    final username = email.split('@').first;
    final parts = username.split(RegExp(r'[._-]'));
    final capitalized = parts.map((p) {
      if (p.isEmpty) return '';
      return p[0].toUpperCase() + p.substring(1).toLowerCase();
    }).join(' ');
    return capitalized.isNotEmpty ? capitalized : 'Google User';
  }

  /// Sign in using official native Google Play Services OAuth dialog (Like official YouTube)
  Future<GoogleSignInAccount?> signInWithOfficialGoogle() async {
    try {
      final GoogleSignInAccount? account = await _googleSignIn.signIn();
      if (account != null) {
        final displayName = (account.displayName != null && account.displayName!.trim().isNotEmpty)
            ? account.displayName!.trim()
            : formatNameFromEmail(account.email);
        final handle = account.email.split('@').first;
        final subs = 1500 + (account.email.hashCode.abs() % 8500);

        _currentUser = UserModel(
          id: account.id,
          name: displayName,
          email: account.email.toLowerCase(),
          avatarUrl: account.photoUrl ?? '',
          channelName: '$displayName • @$handle',
          subscribersCount: subs,
          isLoggedIn: true,
        );

        await storage.saveUserData(_currentUser);
        await storage.addSavedAccount(_currentUser);
        notifyListeners();
      }
      return account;
    } catch (e) {
      rethrow;
    }
  }

  /// Sign in with a real Gmail address and optional display name
  Future<bool> signInWithRealGmail({
    required String email,
    String? name,
    String? avatarUrl,
  }) async {
    final cleanEmail = email.trim().toLowerCase();
    
    // Validate email format
    final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    if (!emailRegex.hasMatch(cleanEmail)) {
      return false;
    }

    final displayName = (name != null && name.trim().isNotEmpty)
        ? name.trim()
        : formatNameFromEmail(cleanEmail);

    final handle = cleanEmail.split('@').first;
    final subs = 1200 + (cleanEmail.hashCode.abs() % 8800);

    _currentUser = UserModel(
      id: 'g_${cleanEmail.hashCode.abs()}',
      name: displayName,
      email: cleanEmail,
      avatarUrl: avatarUrl?.isNotEmpty == true ? avatarUrl! : '',
      channelName: '$displayName • @$handle',
      subscribersCount: subs,
      isLoggedIn: true,
    );

    await storage.saveUserData(_currentUser);
    await storage.addSavedAccount(_currentUser);
    notifyListeners();
    return true;
  }

  /// Legacy support
  Future<void> signInWithGoogle({
    required String name,
    required String email,
    String? avatarUrl,
  }) async {
    await signInWithRealGmail(email: email, name: name, avatarUrl: avatarUrl);
  }

  /// Switch to a previously saved account
  Future<void> switchAccount(UserModel user) async {
    _currentUser = user.copyWith(isLoggedIn: true);
    await storage.saveUserData(_currentUser);
    await storage.addSavedAccount(_currentUser);
    notifyListeners();
  }

  /// Remove a saved account from the device
  Future<void> removeAccount(String email) async {
    await storage.removeSavedAccount(email);
    if (_currentUser.email.toLowerCase() == email.toLowerCase()) {
      await signOut();
    } else {
      notifyListeners();
    }
  }

  /// Sign out
  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
    } catch (_) {}
    _currentUser = const UserModel();
    await storage.clearUserData();
    notifyListeners();
  }
}
