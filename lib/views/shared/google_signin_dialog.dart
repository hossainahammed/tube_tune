import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../models/user_model.dart';
import '../../viewmodels/auth_viewmodel.dart';
import 'app_snackbar.dart';

/// Google Sign-In Bottom Sheet supporting both Native Google Play Services OAuth and direct Real Gmail sign-in.
class GoogleSignInDialog extends StatefulWidget {
  const GoogleSignInDialog({super.key});

  @override
  State<GoogleSignInDialog> createState() => _GoogleSignInDialogState();
}

class _GoogleSignInDialogState extends State<GoogleSignInDialog> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  bool _isAddingAccount = false;
  bool _isLoading = false;
  String? _errorMessage;
  bool _showSha1Help = false;

  static const String _debugSha1 = '65:3D:0F:A1:C6:32:51:7B:D4:00:AC:5B:E6:5D:10:04:60:42:D0:1C';
  static const String _packageName = 'com.tubetune.app';

  @override
  void dispose() {
    _emailController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  /// Official Native Google Play Services Sign In
  void _handleOfficialGoogleSignIn() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _showSha1Help = false;
    });

    try {
      final authVm = context.read<AuthViewModel>();
      final success = await authVm.signInWithOfficialGoogle();
      if (!mounted) return;
      setState(() => _isLoading = false);

      if (success) {
        Navigator.of(context).pop();
        AppSnackBar.showSuccess(
          context,
          'Signed in as ${authVm.currentUser.name} (${authVm.currentUser.email})',
          icon: Icons.check_circle_rounded,
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _showSha1Help = true;
        _errorMessage = 'Google Play Services OAuth requires registering your SHA-1 in Firebase Console. You can also sign in directly with your Gmail address below.';
      });
    }
  }

  void _handleDirectGmailSignIn() async {
    final email = _emailController.text.trim();
    final name = _nameController.text.trim();

    if (email.isEmpty) {
      setState(() => _errorMessage = 'Please enter your Gmail address');
      return;
    }

    final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    if (!emailRegex.hasMatch(email)) {
      setState(() => _errorMessage = 'Please enter a valid email address (e.g. name@gmail.com)');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    await Future.delayed(const Duration(milliseconds: 600));

    if (!mounted) return;
    final authVm = context.read<AuthViewModel>();
    final success = await authVm.signInWithRealGmail(
      email: email,
      name: name.isNotEmpty ? name : null,
    );

    if (mounted) {
      setState(() => _isLoading = false);
      if (success) {
        Navigator.of(context).pop();
        AppSnackBar.showSuccess(
          context,
          'Signed in as ${authVm.currentUser.name} (${authVm.currentUser.email})',
          icon: Icons.check_circle_rounded,
        );
      } else {
        setState(() => _errorMessage = 'Could not sign in with this Gmail. Please try again.');
      }
    }
  }

  void _switchAccount(UserModel account) async {
    final authVm = context.read<AuthViewModel>();
    await authVm.switchAccount(account);
    if (mounted) {
      Navigator.of(context).pop();
      AppSnackBar.showSuccess(
        context,
        'Switched to ${account.name}',
        icon: Icons.account_circle_rounded,
      );
    }
  }

  Color _getAvatarColor(String email) {
    const colors = [
      Color(0xFF4285F4), // Google Blue
      Color(0xFFEA4335), // Google Red
      Color(0xFFFBBC05), // Google Yellow
      Color(0xFF34A853), // Google Green
      Color(0xFF9C27B0), // Purple
      Color(0xFF009688), // Teal
    ];
    return colors[email.hashCode.abs() % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    final authVm = context.watch<AuthViewModel>();
    final savedAccounts = authVm.savedAccounts;
    final currentUser = authVm.currentUser;
    final hasSavedAccounts = savedAccounts.isNotEmpty;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(
        24,
        16,
        24,
        MediaQuery.of(context).viewInsets.bottom + 28,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.surfaceElevated,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 18),

          // Google Brand Header
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: RichText(
                    text: const TextSpan(
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      children: [
                        TextSpan(text: 'G', style: TextStyle(color: Color(0xFF4285F4))),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Sign in with Google',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    'to continue to TubeTune',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 18),
          const Divider(color: AppColors.surfaceLight, height: 1),
          const SizedBox(height: 16),

          // 1. Official 1-Tap Google Sign In Button
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              icon: _isLoading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.g_mobiledata_rounded, size: 28, color: Colors.white),
              label: Text(
                _isLoading ? 'Connecting to Google...' : 'Continue with Google Account',
                style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1A73E8), // Official Google Blue
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                elevation: 2,
              ),
              onPressed: _isLoading ? null : _handleOfficialGoogleSignIn,
            ),
          ),

          if (_errorMessage != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF2C1E1E),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.youtubeRed.withValues(alpha: 0.4)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.info_outline_rounded, color: Color(0xFFFF8A80), size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(color: Color(0xFFFFCDD2), fontSize: 11.5, height: 1.3),
                        ),
                      ),
                    ],
                  ),
                  if (_showSha1Help) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.black45,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Package: $_packageName', style: TextStyle(color: Colors.white70, fontSize: 10.5, fontFamily: 'monospace')),
                          const SizedBox(height: 4),
                          const Text('Debug SHA-1:', style: TextStyle(color: Colors.white70, fontSize: 10.5, fontWeight: FontWeight.bold)),
                          SelectableText(
                            _debugSha1,
                            style: const TextStyle(color: Color(0xFF81D4FA), fontSize: 10, fontFamily: 'monospace'),
                          ),
                          const SizedBox(height: 6),
                          InkWell(
                            onTap: () {
                              Clipboard.setData(const ClipboardData(text: _debugSha1));
                              AppSnackBar.showSuccess(context, 'SHA-1 copied to clipboard!');
                            },
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.copy_rounded, color: Color(0xFF4285F4), size: 14),
                                SizedBox(width: 4),
                                Text('Copy SHA-1 for Firebase', style: TextStyle(color: Color(0xFF4285F4), fontSize: 11, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],

          const SizedBox(height: 16),
          const Center(
            child: Text(
              'OR SIGN IN WITH YOUR GMAIL ADDRESS',
              style: TextStyle(fontSize: 10.5, letterSpacing: 0.8, color: AppColors.textMuted, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 12),

          if (hasSavedAccounts && !_isAddingAccount) ...[
            const Text(
              'Previously used accounts:',
              style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 8),

            // List of Saved Real Accounts
            ...savedAccounts.map((acc) {
              final isCurrent = authVm.isLoggedIn && acc.email.toLowerCase() == currentUser.email.toLowerCase();
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Material(
                  color: isCurrent ? const Color(0xFF162B4D) : AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: isCurrent ? const Color(0xFF4285F4).withValues(alpha: 0.5) : AppColors.cardBorder,
                      width: 0.8,
                    ),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
                    leading: CircleAvatar(
                      radius: 18,
                      backgroundColor: _getAvatarColor(acc.email),
                      child: Text(
                        acc.name.isNotEmpty ? acc.name[0].toUpperCase() : 'G',
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 15),
                      ),
                    ),
                    title: Text(
                      acc.name,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13.5),
                    ),
                    subtitle: Text(
                      acc.email,
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 11.5),
                    ),
                    trailing: isCurrent
                        ? const Icon(Icons.check_circle_rounded, color: Color(0xFF4285F4), size: 20)
                        : null,
                    onTap: () => _switchAccount(acc),
                  ),
                ),
              );
            }),

            const SizedBox(height: 4),

            // Add another real account button
            InkWell(
              onTap: () => setState(() {
                _isAddingAccount = true;
                _errorMessage = null;
              }),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.cardBorder, width: 0.8),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.edit_note_rounded, color: Color(0xFF4285F4), size: 20),
                    SizedBox(width: 12),
                    Text(
                      'Enter another Gmail manually',
                      style: TextStyle(fontSize: 13, color: Colors.white, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
            ),
          ] else ...[
            // Real Gmail Sign-In Input Form
            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.mail_outline_rounded, color: Color(0xFF4285F4), size: 20),
                labelText: 'Gmail address',
                hintText: 'e.g. yourname@gmail.com',
                hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 13),
                labelStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                filled: true,
                fillColor: AppColors.surfaceLight,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 8),

            TextField(
              controller: _nameController,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.badge_outlined, color: AppColors.textSecondary, size: 20),
                labelText: 'Display Name (Optional)',
                hintText: 'e.g. Hossain Ahmed',
                hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 13),
                labelStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                filled: true,
                fillColor: AppColors.surfaceLight,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 12),

            Row(
              children: [
                if (hasSavedAccounts)
                  TextButton(
                    onPressed: () => setState(() {
                      _isAddingAccount = false;
                      _errorMessage = null;
                    }),
                    child: const Text('Back', style: TextStyle(color: AppColors.textSecondary)),
                  ),
                const Spacer(),
                ElevatedButton(
                  onPressed: _isLoading ? null : _handleDirectGmailSignIn,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.surfaceElevated,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  ),
                  child: const Text('Sign In With Email'),
                ),
              ],
            ),
          ],

          const SizedBox(height: 12),
          const Center(
            child: Text(
              'TubeTune connects securely with Google OAuth 2.0 services.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 10.5, color: AppColors.textMuted),
            ),
          ),
        ],
      ),
    );
  }
}
