import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state_provider.dart';
import '../widgets/task_card.dart';
import '../widgets/streak_header_icon.dart';
import '../theme/text_styles.dart';
import '../theme/colors.dart';

class TaskManagerScreen extends StatelessWidget {
  const TaskManagerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text('Daily Tasks', style: AppTextStyles.h2),
        actions: [
          Consumer<AppStateProvider>(
            builder: (context, provider, _) => StreakHeaderIcon(
              streak: provider.profile?.streakData.currentStreak ?? 0,
              isInRecovery: provider.profile?.streakData.isInRecovery ?? false,
            ),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Consumer<AppStateProvider>(
        builder: (context, provider, _) {
          if (provider.tasks.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.task_rounded, size: 64, color: theme.colorScheme.onSurface.withOpacity(0.2)),
                  const SizedBox(height: 16),
                  Text(
                    'No tasks configured',
                    style: AppTextStyles.body.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.5),
                    ),
                  ),
                ],
              ),
            );
          }

          final completedCount = provider.tasks.where((t) => t.isCompleted).length;
          final totalCount = provider.tasks.length;
          final allCompleted = completedCount == totalCount;
          final progress = totalCount > 0 ? completedCount / totalCount : 0.0;

          return Column(
            children: [
              // Progress header
              Card(
                margin: const EdgeInsets.all(16),
                elevation: 0,
                color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                allCompleted ? 'DAY COMPLETE' : 'TASK PROGRESS',
                                style: AppTextStyles.bodySmall.copyWith(
                                  letterSpacing: 1.5,
                                  fontWeight: FontWeight.bold,
                                  color: allCompleted ? AppColors.mutedGold : theme.colorScheme.onSurface.withOpacity(0.6),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '$completedCount of $totalCount Done',
                                style: theme.textTheme.headlineMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: allCompleted ? AppColors.mutedGold : null,
                                ),
                              ),
                            ],
                          ),
                          if (allCompleted)
                            const Icon(Icons.stars_rounded, color: AppColors.mutedGold, size: 48),
                        ],
                      ),
                      const SizedBox(height: 16),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 12,
                          backgroundColor: theme.colorScheme.onSurface.withOpacity(0.1),
                          valueColor: AlwaysStoppedAnimation<Color>(
                            allCompleted ? AppColors.mutedGold : AppColors.deepRed,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              // Task list
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final orientation = MediaQuery.of(context).orientation;
                    final crossAxisCount = orientation == Orientation.landscape ? 2 : 1;
                    
                    if (orientation == Orientation.landscape && constraints.maxWidth > 600) {
                      // Use grid layout for landscape on wide screens
                      return GridView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: crossAxisCount,
                          childAspectRatio: 3.0,
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
                        ),
                        itemCount: provider.tasks.length,
                        itemBuilder: (context, index) {
                          final task = provider.tasks[index];
                          return TaskCard(
                            task: task,
                            onToggle: () => provider.toggleTask(task.id),
                          );
                        },
                      );
                    } else {
                      // Use list view for portrait or narrow screens
                      return ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        itemCount: provider.tasks.length,
                        itemBuilder: (context, index) {
                          final task = provider.tasks[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: TaskCard(
                              task: task,
                              onToggle: () => provider.toggleTask(task.id),
                            ),
                          );
                        },
                      );
                    }
                  },
                ),
              ),
              
              // Info footer
              if (!provider.profile!.isFirstDay)
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    border: Border(
                      top: BorderSide(color: theme.dividerColor, width: 0.5),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline_rounded, size: 18, color: theme.colorScheme.onSurface.withOpacity(0.5)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Tasks are locked. Complete all daily to stay alive.',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: theme.colorScheme.onSurface.withOpacity(0.5),
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
