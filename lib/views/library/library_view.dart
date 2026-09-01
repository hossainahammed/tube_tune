import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/player_viewmodel.dart';
import '../home/widgets/video_card_widget.dart';
import '../settings/settings_view.dart';
import '../shared/custom_app_bar.dart';
import '../shared/google_signin_dialog.dart';
import '../shared/timer_status_bar.dart';

/// Library View displaying Google Profile header, Watch History, and Saved Watch Later videos.
class LibraryView extends StatelessWidget {
  const LibraryView({super.key});

  @override
  Widget build(BuildContext context) {
    final playerVm = context.watch<PlayerViewModel>();
    final authVm = context.watch<AuthViewModel>();
    final user = authVm.currentUser;

    return Scaffold(
      appBar: const CustomAppBar(),
      body: Column(
        children: [
          const TimerStatusBar(),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // 1. Google Account Header Banner
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.cardBorder, width: 0.8),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 26,
                        backgroundColor: authVm.isLoggedIn ? const Color(0xFF4285F4) : AppColors.surfaceLight,
                        backgroundImage: authVm.isLoggedIn && user.avatarUrl.isNotEmpty
                            ? NetworkImage(user.avatarUrl)
                            : null,
                        child: !authVm.isLoggedIn
                            ? const Icon(Icons.person, size: 30, color: AppColors.textSecondary)
                            : (user.avatarUrl.isEmpty
                                ? Text(user.name.isNotEmpty ? user.name[0] : 'U', style: const TextStyle(fontSize: 18, color: Colors.white))
                                : null),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              authVm.isLoggedIn ? user.name : 'Sign In with Google',
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              authVm.isLoggedIn ? user.email : 'Sync history, playlists & likes',
                              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          if (authVm.isLoggedIn) {
                            Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => const SettingsView()),
                            );
                          } else {
                            showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              backgroundColor: Colors.transparent,
                              builder: (_) => const GoogleSignInDialog(),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: authVm.isLoggedIn ? AppColors.surfaceLight : const Color(0xFF4285F4),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        ),
                        child: Text(authVm.isLoggedIn ? 'Manage' : 'Sign In'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // 2. Quick Shortcuts Row
                Row(
                  children: [
                    Expanded(
                      child: _buildTile(
                        icon: Icons.history_rounded,
                        title: 'History',
                        subtitle: '${playerVm.watchHistory.length} videos',
                        color: AppColors.youtubeRed,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildTile(
                        icon: Icons.watch_later_outlined,
                        title: 'Watch Later',
                        subtitle: '${playerVm.watchLater.length} saved',
                        color: AppColors.accentCyan,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // 3. Watch History Section
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Recent Watch History',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                    ),
                    if (playerVm.watchHistory.isNotEmpty)
                      TextButton(
                        onPressed: () => playerVm.clearHistory(),
                        child: const Text('Clear', style: TextStyle(color: AppColors.error, fontSize: 13)),
                      ),
                  ],
                ),
                const SizedBox(height: 8),

                if (playerVm.watchHistory.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Center(
                      child: Text(
                        'No watch history yet. Videos you watch will appear here.',
                        style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  )
                else
                  ...playerVm.watchHistory.take(5).map((v) => VideoCardWidget(video: v)),

                const SizedBox(height: 24),

                // 4. Saved Watch Later Section
                const Text(
                  'Watch Later',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                ),
                const SizedBox(height: 8),

                if (playerVm.watchLater.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Center(
                      child: Text(
                        'No videos saved to Watch Later.',
                        style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  )
                else
                  ...playerVm.watchLater.map((v) => VideoCardWidget(video: v)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder, width: 0.5),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 2),
                Text(subtitle, style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
