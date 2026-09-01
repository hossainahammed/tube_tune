import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../viewmodels/auth_viewmodel.dart';

/// Google Sign-In Bottom Sheet / Dialog matching official Google & YouTube aesthetic.
class GoogleSignInDialog extends StatefulWidget {
  const GoogleSignInDialog({super.key});

  @override
  State<GoogleSignInDialog> createState() => _GoogleSignInDialogState();
}

class _GoogleSignInDialogState extends State<GoogleSignInDialog> {
  final TextEditingController _nameController = TextEditingController(text: 'Hossain Ahmed');
  final TextEditingController _emailController = TextEditingController(text: 'hossain.tube@gmail.com');
  bool _isCustomMode = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _signIn(String name, String email, [String? avatarUrl]) async {
    final authVm = context.read<AuthViewModel>();
    await authVm.signInWithGoogle(name: name, email: email, avatarUrl: avatarUrl);
    if (mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: AppColors.success),
              const SizedBox(width: 8),
              Text('Signed in as $name'),
            ],
          ),
          backgroundColor: AppColors.surfaceElevated,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag Handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.surfaceElevated,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 18),

          // Google Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: const Text(
                  'G',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF4285F4),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Sign in with Google',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                  ),
                  Text(
                    'to continue to TubeTune',
                    style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Divider(color: AppColors.surfaceLight, height: 1),
          const SizedBox(height: 16),

          if (!_isCustomMode) ...[
            // Quick Accounts List
            const Text(
              'Choose an account',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 12),

            _buildAccountTile(
              name: 'Hossain Ahmed',
              email: 'hossain.tube@gmail.com',
              avatarUrl: 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=120&auto=format&fit=crop&q=80',
              onTap: () => _signIn('Hossain Ahmed', 'hossain.tube@gmail.com'),
            ),
            const SizedBox(height: 8),
            _buildAccountTile(
              name: 'Islamic Family Learning',
              email: 'family.islamic@gmail.com',
              avatarUrl: 'https://images.unsplash.com/photo-1564769625905-50e93615e769?w=120&auto=format&fit=crop&q=80',
              onTap: () => _signIn('Islamic Family Learning', 'family.islamic@gmail.com'),
            ),
            const SizedBox(height: 12),

            // Use another account button
            InkWell(
              onTap: () => setState(() => _isCustomMode = true),
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.cardBorder, width: 0.8),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.person_add_alt_1_outlined, color: AppColors.accentCyan, size: 20),
                    SizedBox(width: 12),
                    Text('Use another Google account', style: TextStyle(fontSize: 13, color: AppColors.textPrimary)),
                  ],
                ),
              ),
            ),
          ] else ...[
            // Custom Input Mode
            const Text(
              'Enter your Google credentials:',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _nameController,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              decoration: InputDecoration(
                labelText: 'Full Name',
                labelStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                filled: true,
                fillColor: AppColors.surfaceLight,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              decoration: InputDecoration(
                labelText: 'Google / Gmail Address',
                labelStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                filled: true,
                fillColor: AppColors.surfaceLight,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                TextButton(
                  onPressed: () => setState(() => _isCustomMode = false),
                  child: const Text('Back', style: TextStyle(color: AppColors.textSecondary)),
                ),
                const Spacer(),
                ElevatedButton(
                  onPressed: () {
                    if (_nameController.text.isNotEmpty && _emailController.text.isNotEmpty) {
                      _signIn(_nameController.text.trim(), _emailController.text.trim());
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4285F4),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('Sign In'),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAccountTile({
    required String name,
    required String email,
    required String avatarUrl,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: AppColors.surfaceElevated,
              backgroundImage: NetworkImage(avatarUrl),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white)),
                  Text(email, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary, size: 20),
          ],
        ),
      ),
    );
  }
}
