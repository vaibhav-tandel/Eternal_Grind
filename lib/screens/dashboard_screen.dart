import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/app_state_provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/streak_header_icon.dart';
import '../widgets/curse_warning_modal.dart';
import '../widgets/milestone_message.dart';
import '../widgets/cursed_overlay.dart';
import '../theme/text_styles.dart';
import '../theme/colors.dart';
import '../services/curse_service.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkForWarnings();
    });
  }

  void _checkForWarnings() {
    final provider = context.read<AppStateProvider>();
    
    // Show curse warning if cursed
    if (provider.isCursed) {
      final curseService = CurseService();
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => CurseWarningModal(
          curseCount: provider.profile!.cursedMark.count,
          warningMessage: curseService.getCurseWarningMessage(
            provider.profile!.cursedMark.count,
          ),
          onDismiss: () => Navigator.of(context).pop(),
        ),
      );
    }
    
    // Show milestone message if available
    if (provider.milestoneMessage != null) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => MilestoneMessage(
          message: provider.milestoneMessage!,
          onDismiss: () {
            provider.clearMilestoneMessage();
            Navigator.of(context).pop();
          },
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Consumer2<AppStateProvider, AuthProvider>(
      builder: (context, provider, auth, _) {
        if (provider.isLoading) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final profile = provider.profile!;
        final isCursed = profile.cursedMark.isCursed;

        Widget content = Scaffold(
          appBar: AppBar(
            title: Text('ETERNAL GRIND', style: AppTextStyles.h2.copyWith(letterSpacing: 2)),
            actions: [
              StreakHeaderIcon(
                streak: profile.streakData.currentStreak,
                isInRecovery: profile.streakData.isInRecovery,
              ),
              const SizedBox(width: 8),
              IconButton.filledTonal(
                icon: const Icon(Icons.person_rounded),
                onPressed: () => Navigator.of(context).pushNamed('/profile'),
              ),
              const SizedBox(width: 16),
            ],
          ),
          body: SingleChildScrollView(
            padding: EdgeInsets.only(
              left: MediaQuery.of(context).size.width * 0.05,
              right: MediaQuery.of(context).size.width * 0.05,
              top: MediaQuery.of(context).padding.top + (MediaQuery.of(context).size.height * 0.02),
              bottom: MediaQuery.of(context).padding.bottom + (MediaQuery.of(context).size.height * 0.02),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Greeting and Date
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome back, ${auth.currentUser ?? 'User'}',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      DateFormat('EEEE, MMMM d').format(DateTime.now()),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 32),
                
                // Cursed mark indicator
                if (isCursed) ...[
                  Card(
                    color: isDark ? AppColors.charcoal : Colors.red.shade50,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(color: AppColors.cursedRed, width: 2),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline_rounded, color: AppColors.cursedRed, size: 40),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'CURSED MARKS: ${profile.cursedMark.count}',
                                  style: AppTextStyles.emphasis.copyWith(
                                    color: AppColors.cursedRed,
                                  ),
                                ),
                                Text(
                                  'Complete tasks for ${profile.streakData.recoveryRequired} days to lift the curse.',
                                  style: AppTextStyles.bodySmall.copyWith(
                                    color: isDark ? AppColors.crimson : Colors.red.shade900,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                
                // Relief days
                if (profile.reliefDay.available > 0) ...[
                  Card(
                    color: isDark ? AppColors.charcoal : Colors.amber.shade50,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(color: AppColors.mutedGold, width: 1),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          const Icon(Icons.shield_rounded, color: AppColors.mutedGold, size: 32),
                          const SizedBox(width: 16),
                          Text(
                            'Relief Days Available: ${profile.reliefDay.available}',
                            style: AppTextStyles.emphasis.copyWith(
                              color: isDark ? AppColors.mutedGold : Colors.amber.shade900,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                
                // Task summary
                Card(
                  elevation: 0,
                  color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
                    child: Column(
                      children: [
                        Text(
                          'TODAY\'S DISCIPLINE',
                          style: AppTextStyles.bodySmall.copyWith(
                            letterSpacing: 2,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildStatItem(
                              context,
                              provider.tasks.where((t) => t.isCompleted).length.toString(),
                              'COMPLETED',
                              color: AppColors.mutedGold,
                            ),
                            Container(width: 1, height: 40, color: theme.dividerColor),
                            _buildStatItem(
                              context,
                              provider.tasks.length.toString(),
                              'TOTAL',
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 32),
                
                // Navigate to tasks button
                FilledButton.icon(
                  onPressed: () => Navigator.of(context).pushNamed('/tasks'),
                  icon: const Icon(Icons.task_alt_rounded),
                  label: const Text('MANAGE TASKS'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.all(20),
                    textStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );

        // Apply cursed overlay if cursed
        if (isCursed) {
          content = CursedOverlay(child: content);
        }

        return content;
      },
    );
  }

  Widget _buildStatItem(BuildContext context, String value, String label, {Color? color}) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Text(
          value,
          style: theme.textTheme.displaySmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            letterSpacing: 1,
            color: theme.colorScheme.onSurface.withOpacity(0.6),
          ),
        ),
      ],
    );
  }
}
