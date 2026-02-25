import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';
import '../widgets/streak_header_icon.dart';
import '../theme/text_styles.dart';
import '../theme/colors.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  Widget _buildStatRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTextStyles.body),
          Text(
            value,
            style: AppTextStyles.emphasis.copyWith(
              color: valueColor ?? AppColors.mutedGold,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text('Profile', style: AppTextStyles.h2),
        actions: [
          Consumer<AppStateProvider>(
            builder: (context, provider, _) => StreakHeaderIcon(
              streak: provider.profile?.streakData.currentStreak ?? 0,
              isInRecovery: provider.profile?.streakData.isInRecovery ?? false,
            ),
          ),
        ],
      ),
      body: Consumer3<AppStateProvider, AuthProvider, ThemeProvider>(
        builder: (context, appState, auth, themeProvider, _) {
          final profile = appState.profile!;
          
          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // User Info Header
                Center(
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundColor: AppColors.charcoal,
                        child: Icon(
                          Icons.person_rounded,
                          size: 60,
                          color: AppColors.mutedGold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        auth.currentUser?.email ?? 'User',
                        style: AppTextStyles.h2,
                      ),
                      Text(
                        'DISCIPLINE RECORD',
                        style: AppTextStyles.bodySmall.copyWith(
                          letterSpacing: 2,
                          color: AppColors.mutedGold,
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 32),
                
                // Settings Section
                Text('Settings', style: AppTextStyles.h3),
                const SizedBox(height: 8),
                Card(
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.brightness_medium_rounded),
                        title: const Text('Theme Mode'),
                        trailing: DropdownButton<ThemeMode>(
                          value: themeProvider.themeMode,
                          underline: const SizedBox(),
                          onChanged: (mode) {
                            if (mode != null) {
                              themeProvider.setThemeMode(mode);
                            }
                          },
                          items: const [
                            DropdownMenuItem(
                              value: ThemeMode.system,
                              child: Text('System'),
                            ),
                            DropdownMenuItem(
                              value: ThemeMode.light,
                              child: Text('Light'),
                            ),
                            DropdownMenuItem(
                              value: ThemeMode.dark,
                              child: Text('Dark'),
                            ),
                          ],
                        ),
                      ),
                      const Divider(height: 1, indent: 16, endIndent: 16),
                      ListTile(
                        leading: const Icon(Icons.logout_rounded, color: AppColors.cursedRed),
                        title: const Text('Sign Out', style: TextStyle(color: AppColors.cursedRed)),
                        onTap: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Sign Out'),
                              content: const Text('Are you sure you want to sign out? Your local data will remain saved.'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context, false),
                                  child: const Text('Cancel'),
                                ),
                                FilledButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  child: const Text('Sign Out'),
                                ),
                              ],
                            ),
                          );
                          
                          if (confirm == true && context.mounted) {
                            await auth.logout();
                            // AppRouter will handle navigation to login
                          }
                        },
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),
                
                // Stats Sections
                Text('Statistics', style: AppTextStyles.h3),
                const SizedBox(height: 8),
                
                // Streak stats
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildStatRow(
                          'Current Streak',
                          '${profile.streakData.currentStreak} days',
                        ),
                        _buildStatRow(
                          'Highest Streak',
                          '${profile.streakData.highestStreak} days',
                          valueColor: AppColors.gold,
                        ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Curse stats
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildStatRow(
                          'Current Cursed Marks',
                          '${profile.cursedMark.count}',
                          valueColor: profile.cursedMark.count > 0
                              ? AppColors.cursedRed
                              : AppColors.mutedGold,
                        ),
                        _buildStatRow(
                          'Total Times Cursed',
                          '${profile.cursedMark.totalTimesCursed}',
                        ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Relief day stats
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildStatRow(
                          'Available Relief Days',
                          '${profile.reliefDay.available}',
                        ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // General stats
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildStatRow(
                          'Account Created',
                          _formatDate(profile.accountCreatedDate),
                        ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 32),
                
                // Warning message
                if (profile.cursedMark.count >= 7)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.charcoal : Colors.red.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.cursedRed, width: 2),
                    ),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.warning_amber_rounded,
                          color: AppColors.cursedRed,
                          size: 32,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Account deletion at 10 cursed marks',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.cursedRed,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                
                const SizedBox(height: 48),
              ],
            ),
          );
        },
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}
