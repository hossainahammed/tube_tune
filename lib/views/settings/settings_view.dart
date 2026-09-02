import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../models/timer_model.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/settings_viewmodel.dart';
import '../shared/custom_timer_dialog.dart';
import '../shared/google_signin_dialog.dart';
import '../shared/pin_dialog.dart';
import '../shared/schedule_window_dialog.dart';

/// Comprehensive Settings Hub containing Google Login, Data Filtration toggles, Category Whitelists, and Auto-Lock Timers.
class SettingsView extends StatefulWidget {
  const SettingsView({super.key});

  @override
  State<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends State<SettingsView> {
  final TextEditingController _blacklistController = TextEditingController();

  @override
  void dispose() {
    _blacklistController.dispose();
    super.dispose();
  }

  void _showSetPinDialog(BuildContext context, SettingsViewModel settingsVm) async {
    final messenger = ScaffoldMessenger.of(context);
    final newPin = await showDialog<String>(
      context: context,
      builder: (_) => const PinDialog(
        title: 'Set Security PIN',
        description: 'Set a 4-digit PIN to protect settings and timer controls.',
        isSettingNewPin: true,
      ),
    );

    if (newPin != null && newPin.length == 4) {
      settingsVm.setPinCode(newPin, true);
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Security PIN set successfully!'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  void _showCustomDurationDialog(BuildContext context, SettingsViewModel settingsVm) async {
    final currentMins = settingsVm.timerService.state.sessionDurationMinutes;
    final selectedMins = await showDialog<int>(
      context: context,
      builder: (_) => CustomTimerDialog(initialMinutes: currentMins),
    );

    if (selectedMins != null && selectedMins > 0) {
      settingsVm.setSessionDuration(selectedMins);
    }
  }

  void _showAddScheduleWindowDialog(BuildContext context, SettingsViewModel settingsVm) async {
    final newWindow = await showDialog<ScheduleWindow>(
      context: context,
      builder: (_) => const ScheduleWindowDialog(),
    );

    if (newWindow != null) {
      settingsVm.addScheduleWindow(newWindow);
    }
  }

  void _showEditScheduleWindowDialog(BuildContext context, SettingsViewModel settingsVm, ScheduleWindow window) async {
    final updated = await showDialog<ScheduleWindow>(
      context: context,
      builder: (_) => ScheduleWindowDialog(initialWindow: window),
    );

    if (updated != null) {
      settingsVm.updateScheduleWindow(updated);
    }
  }

  @override
  Widget build(BuildContext context) {
    final settingsVm = context.watch<SettingsViewModel>();
    final authVm = context.watch<AuthViewModel>();
    final timerState = settingsVm.timerService.state;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Filters & Parental Controls'),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
          // ----------------------------------------------------
          // SECTION 0: GOOGLE ACCOUNT & YOUTUBE PROFILE
          // ----------------------------------------------------
          _buildGoogleAccountCard(context, authVm),
          const SizedBox(height: 20),

          // ----------------------------------------------------
          // SECTION 1: DIGITAL WELLBEING & AUTO-LOCK / AUTO-UNLOCK TIMER
          // ----------------------------------------------------
          _buildSectionHeader(
            icon: Icons.timer_rounded,
            title: 'Screen Time & Auto-Lock Timer',
            color: AppColors.accentAmber,
          ),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Auto-Lock Master Switch
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text(
                      'Auto-Lock YouTube Timer',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                    subtitle: const Text(
                      'Automatically locks the app after your session time and auto-unlocks after the break period.',
                      style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                    value: timerState.isTimerEnabled,
                    activeThumbColor: AppColors.youtubeRed,
                    onChanged: (val) => settingsVm.setTimerEnabled(val),
                  ),

                  if (timerState.isTimerEnabled) ...[
                    const Divider(color: AppColors.surfaceLight, height: 24),

                    // Session Limit Duration Selector
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Watch Session Limit:',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.youtubeRed.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '${timerState.sessionDurationMinutes} Minutes',
                            style: const TextStyle(
                              color: AppColors.youtubeRedLight,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // Quick Chips + Custom Duration Button
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        ...[5, 15, 30, 45, 60, 90, 120].map((mins) {
                          final isSelected = timerState.sessionDurationMinutes == mins;
                          return ChoiceChip(
                            label: Text(mins == 5 ? '5m (Test)' : '$mins m'),
                            selected: isSelected,
                            onSelected: (_) => settingsVm.setSessionDuration(mins),
                            selectedColor: AppColors.youtubeRed,
                            labelStyle: TextStyle(
                              color: isSelected ? Colors.white : AppColors.textPrimary,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              fontSize: 12,
                            ),
                            showCheckmark: false,
                          );
                        }),
                        ActionChip(
                          avatar: const Icon(Icons.edit_calendar_rounded, size: 16, color: AppColors.accentCyan),
                          label: const Text('Custom Time'),
                          backgroundColor: AppColors.surfaceLight,
                          labelStyle: const TextStyle(color: AppColors.accentCyan, fontSize: 12, fontWeight: FontWeight.bold),
                          onPressed: () => _showCustomDurationDialog(context, settingsVm),
                        ),
                      ],
                    ),

                    const SizedBox(height: 18),

                    // Break / Auto-Unlock Duration Selector
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Break / Auto-Unlock After:',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.islamicGreen.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '${timerState.breakDurationMinutes} Minutes',
                            style: const TextStyle(
                              color: AppColors.islamicGreen,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [5, 10, 15, 30, 60].map((mins) {
                        final isSelected = timerState.breakDurationMinutes == mins;
                        return ChoiceChip(
                          label: Text('$mins m break'),
                          selected: isSelected,
                          onSelected: (_) => settingsVm.setBreakDuration(mins),
                          selectedColor: AppColors.islamicGreen,
                          labelStyle: TextStyle(
                            color: isSelected ? Colors.black : AppColors.textPrimary,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            fontSize: 12,
                          ),
                          showCheckmark: false,
                        );
                      }).toList(),
                    ),

                    const SizedBox(height: 16),

                    // Live Session Countdown & Reset
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceLight,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.hourglass_top_rounded, color: AppColors.accentAmber, size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Remaining in Active Session', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                                Text(
                                  timerState.sessionRemainingFormatted,
                                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                                ),
                              ],
                            ),
                          ),
                          TextButton.icon(
                            onPressed: () => settingsVm.resetSession(),
                            icon: const Icon(Icons.replay_rounded, size: 16),
                            label: const Text('Reset', style: TextStyle(fontSize: 12)),
                            style: TextButton.styleFrom(foregroundColor: AppColors.accentCyan),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const Divider(color: AppColors.surfaceLight, height: 28),

                  // ----------------------------------------------------
                  // MULTIPLE DAILY USAGE SCHEDULE WINDOWS (BEDTIME LOCK)
                  // ----------------------------------------------------
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text(
                      'Daily Usage Schedule Windows',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    subtitle: const Text(
                      'Define one or more allowed time windows. The app auto-locks outside all active windows.',
                      style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                    value: timerState.isScheduleEnabled,
                    activeThumbColor: AppColors.accentCyan,
                    onChanged: (val) => settingsVm.setScheduleEnabled(val),
                  ),

                  if (timerState.isScheduleEnabled) ...[
                    const SizedBox(height: 12),

                    // List of Schedule Windows
                    ...timerState.scheduleWindows.map((window) {
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceLight,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: window.isEnabled ? AppColors.accentCyan.withValues(alpha: 0.3) : AppColors.cardBorder,
                            width: 0.8,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              window.isEnabled ? Icons.schedule_rounded : Icons.schedule_outlined,
                              color: window.isEnabled ? AppColors.accentCyan : AppColors.textMuted,
                              size: 20,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    window.name,
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: window.isEnabled ? Colors.white : AppColors.textSecondary,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    window.timeFormatted,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: window.isEnabled ? AppColors.accentCyan : AppColors.textMuted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.edit_outlined, size: 18, color: AppColors.textSecondary),
                              tooltip: 'Edit Window',
                              onPressed: () => _showEditScheduleWindowDialog(context, settingsVm, window),
                            ),
                            if (timerState.scheduleWindows.length > 1)
                              IconButton(
                                icon: const Icon(Icons.delete_outline_rounded, size: 18, color: AppColors.error),
                                tooltip: 'Delete Window',
                                onPressed: () => settingsVm.removeScheduleWindow(window.id),
                              ),
                            Switch(
                              value: window.isEnabled,
                              activeThumbColor: AppColors.accentCyan,
                              onChanged: (val) => settingsVm.toggleScheduleWindow(window.id, val),
                            ),
                          ],
                        ),
                      );
                    }),

                    const SizedBox(height: 8),

                    // "+ Add New Schedule Window" Button
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () => _showAddScheduleWindowDialog(context, settingsVm),
                        icon: const Icon(Icons.add_rounded, size: 20, color: AppColors.accentCyan),
                        label: const Text('Add Time Window', style: TextStyle(color: AppColors.accentCyan, fontWeight: FontWeight.bold)),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppColors.accentCyan, width: 1),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 14),

                  // PIN Code Protection Setting
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.pin_outlined, color: AppColors.textSecondary),
                    title: const Text('Security PIN Lock', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                    subtitle: Text(
                      timerState.pinCode.isNotEmpty
                          ? 'PIN is active (****)'
                          : 'Set a 4-digit PIN to lock settings & break screen',
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                    trailing: OutlinedButton(
                      onPressed: () => _showSetPinDialog(context, settingsVm),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.cardBorder),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                      ),
                      child: Text(
                        timerState.pinCode.isNotEmpty ? 'Change' : 'Set PIN',
                        style: const TextStyle(fontSize: 12, color: AppColors.textPrimary),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          // ----------------------------------------------------
          // SECTION 2: REELS / SHORTS & 18+ DATA FILTRATION
          // ----------------------------------------------------
          _buildSectionHeader(
            icon: Icons.shield_rounded,
            title: 'Content & Safety Filtration',
            color: AppColors.youtubeRed,
          ),
          Card(
            child: Column(
              children: [
                // 1. Shorts / Reels Switch
                SwitchListTile(
                  title: const Text('Shorts & Reels Feed', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  subtitle: const Text(
                    'Toggle ON/OFF. When disabled, the Shorts tab and video shelves are completely removed to prevent endless scrolling.',
                    style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                  secondary: const Icon(Icons.bolt_rounded, color: AppColors.youtubeRed),
                  value: settingsVm.enableShorts,
                  activeThumbColor: AppColors.youtubeRed,
                  onChanged: (val) => settingsVm.toggleEnableShorts(val),
                ),
                const Divider(color: AppColors.surfaceLight, height: 1),

                // 2. Hide 18+ Content Switch
                SwitchListTile(
                  title: const Text('Block 18+ & NSFW Content', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  subtitle: const Text(
                    'Strictly blocks adult keywords, 18+ reels, violence, and enforces YouTube SafeSearch.',
                    style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                  secondary: const Icon(Icons.visibility_off_rounded, color: AppColors.islamicGreen),
                  value: settingsVm.block18Plus,
                  activeThumbColor: AppColors.islamicGreen,
                  onChanged: (val) => settingsVm.toggleBlock18Plus(val),
                ),
                const Divider(color: AppColors.surfaceLight, height: 1),

                // 3. Ad-Block Switch
                SwitchListTile(
                  title: const Text('Ad-Block Protection', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  subtitle: const Text(
                    'Filters out pre-roll ads, mid-roll interruptions, and sponsored banners.',
                    style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                  secondary: const Icon(Icons.block_rounded, color: AppColors.accentAmber),
                  value: settingsVm.enableAdBlock,
                  activeThumbColor: AppColors.accentAmber,
                  onChanged: (val) => settingsVm.toggleEnableAdBlock(val),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // ----------------------------------------------------
          // SECTION 3: CATEGORY FILTER & FOCUS MODES
          // ----------------------------------------------------
          _buildSectionHeader(
            icon: Icons.category_rounded,
            title: 'Category Whitelist & Focus Mode',
            color: AppColors.islamicGreen,
          ),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Preset Focus Modes',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 8),

                  // Focus Mode Chips (Using '🌟 All')
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildFocusModeChip(settingsVm, 'all', '🌟 All'),
                      _buildFocusModeChip(settingsVm, 'news', '📰 All News (National & Global)'),
                      _buildFocusModeChip(settingsVm, 'islamic_waz', '🕌 Islamic & Waz Only'),
                      _buildFocusModeChip(settingsVm, 'kids_cartoons', '👶 Kids & Cartoons Only'),
                      _buildFocusModeChip(settingsVm, 'education_tech', '🎓 Tech & Education Only'),
                    ],
                  ),

                  const Divider(color: AppColors.surfaceLight, height: 24),

                  // Strict Out-of-Category Isolation Switch
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text(
                      'Strict Category Isolation',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    subtitle: const Text(
                      'When enabled, any video or short outside your selected categories is strictly blocked from feeds, search, and up-next.',
                      style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                    value: settingsVm.strictCategoryMode,
                    activeThumbColor: AppColors.islamicGreen,
                    onChanged: (val) => settingsVm.toggleStrictCategoryMode(val),
                  ),

                  const SizedBox(height: 12),
                  const Text(
                    'Allowed Categories Individual Toggles:',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 8),

                  // List of Categories with Toggles
                  ...settingsVm.categories.map((category) {
                    return CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      secondary: Icon(category.icon, color: category.color),
                      title: Text(
                        category.name,
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(
                        category.description,
                        style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                      ),
                      value: category.isEnabled,
                      activeColor: category.color,
                      onChanged: (val) => settingsVm.toggleCategory(category.id, val ?? true),
                    );
                  }),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          // ----------------------------------------------------
          // SECTION 4: CUSTOM KEYWORD & CHANNEL BLACKLIST
          // ----------------------------------------------------
          _buildSectionHeader(
            icon: Icons.not_interested_rounded,
            title: 'Custom Keyword Blacklist',
            color: AppColors.error,
          ),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Block specific words, channels, or topics from ever appearing:',
                    style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _blacklistController,
                          style: const TextStyle(fontSize: 13, color: Colors.white),
                          decoration: InputDecoration(
                            hintText: 'Enter keyword to block (e.g. gossip)',
                            hintStyle: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                            filled: true,
                            fillColor: AppColors.surfaceLight,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () {
                          if (_blacklistController.text.isNotEmpty) {
                            settingsVm.addBlacklistKeyword(_blacklistController.text);
                            _blacklistController.clear();
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.youtubeRed,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: const Text('Add'),
                      ),
                    ],
                  ),
                  if (settingsVm.customBlacklist.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: settingsVm.customBlacklist.map((kw) {
                        return Chip(
                          label: Text(kw, style: const TextStyle(fontSize: 11, color: Colors.white)),
                          backgroundColor: AppColors.surfaceElevated,
                          deleteIcon: const Icon(Icons.close, size: 14, color: AppColors.error),
                          onDeleted: () => settingsVm.removeBlacklistKeyword(kw),
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                        );
                      }).toList(),
                    ),
                  ],
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          // ----------------------------------------------------
          // SECTION 5: DIGITAL WELLBEING & FILTER STATS
          // ----------------------------------------------------
          _buildSectionHeader(
            icon: Icons.insights_rounded,
            title: 'Filter Statistics & Protection Insights',
            color: AppColors.accentCyan,
          ),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatItem('Total Filtered', '${settingsVm.totalVideosFiltered}', AppColors.accentCyan),
                  _buildStatItem('18+ Blocked', '${settingsVm.total18PlusBlocked}', AppColors.islamicGreen),
                  _buildStatItem('Shorts Blocked', '${settingsVm.totalShortsBlocked}', AppColors.youtubeRed),
                ],
              ),
            ),
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildGoogleAccountCard(BuildContext context, AuthViewModel authVm) {
    final user = authVm.currentUser;

    if (authVm.isLoggedIn) {
      return Card(
        color: AppColors.surface,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: AppColors.surfaceElevated,
                backgroundImage: user.avatarUrl.isNotEmpty ? NetworkImage(user.avatarUrl) : null,
                child: user.avatarUrl.isEmpty
                    ? Text(user.name.isNotEmpty ? user.name[0] : 'U', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white))
                    : null,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          user.name,
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        const SizedBox(width: 6),
                        const Icon(Icons.check_circle, color: AppColors.accentCyan, size: 15),
                      ],
                    ),
                    Text(
                      user.email,
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'Google Account Linked',
                      style: TextStyle(fontSize: 10, color: AppColors.islamicGreen, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, color: AppColors.textSecondary),
                color: AppColors.surfaceElevated,
                onSelected: (val) {
                  if (val == 'signout') {
                    authVm.signOut();
                  } else if (val == 'switch') {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (_) => const GoogleSignInDialog(),
                    );
                  }
                },
                itemBuilder: (ctx) => [
                  const PopupMenuItem(
                    value: 'switch',
                    child: Row(
                      children: [
                        Icon(Icons.switch_account, size: 18, color: Colors.white),
                        SizedBox(width: 8),
                        Text('Switch Account', style: TextStyle(color: Colors.white, fontSize: 13)),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'signout',
                    child: Row(
                      children: [
                        Icon(Icons.logout, size: 18, color: AppColors.error),
                        SizedBox(width: 8),
                        Text('Sign Out', style: TextStyle(color: AppColors.error, fontSize: 13)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      color: AppColors.surface,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Row(
              children: [
                Icon(Icons.account_circle_outlined, size: 28, color: Color(0xFF4285F4)),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Google / YouTube Account',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      Text(
                        'Sign in to sync your subscriptions and history',
                        style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (_) => const GoogleSignInDialog(),
                  );
                },
                icon: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                  child: const Text('G', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF4285F4))),
                ),
                label: const Text('Sign in with Google'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.surfaceLight,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader({required IconData icon, required String title, required Color color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      child: Row(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFocusModeChip(SettingsViewModel settingsVm, String mode, String label) {
    final isSelected = settingsVm.selectedFocusMode == mode;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => settingsVm.setFocusMode(mode),
      selectedColor: AppColors.youtubeRed,
      backgroundColor: AppColors.surfaceLight,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : AppColors.textPrimary,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
        fontSize: 12,
      ),
      showCheckmark: false,
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color)),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
      ],
    );
  }
}
