import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';
import '../services/firestore_service.dart';
import '../models/task_model.dart';
import '../widgets/add_task_dialog.dart';
import '../utils/streak_logic.dart';
import '../theme/colors.dart';
import 'calendar_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  DateTime _selectedDate = DateTime.now();

  @override
  Widget build(BuildContext context) {
    debugPrint("Building HomeScreen");
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final firestoreService = FirestoreService();
    final user = authProvider.currentUser;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    debugPrint("User: ${user?.uid}");
    debugPrint("Theme: ${theme.brightness}");

    if (user == null) {
      debugPrint("User is null, returning to login");
      return const Scaffold(
        body: Center(
          child: Text('User not found, redirecting to login...'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'ETERNAL GRIND',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
            color: isDark ? AppColors.mutedGold : AppColors.deepRed,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(
              Icons.date_range_rounded,
              color: isDark ? AppColors.mutedGold : AppColors.deepRed,
            ),
            onPressed: () async {
              final DateTime? picked = await showDatePicker(
                context: context,
                initialDate: _selectedDate,
                firstDate: DateTime(2020),
                lastDate: DateTime.now().add(const Duration(days: 365)),
              );
              if (picked != null && picked != _selectedDate) {
                setState(() {
                  _selectedDate = picked;
                });
              }
            },
          ),
          IconButton(
            icon: Icon(
              Icons.calendar_month_rounded,
              color: isDark ? AppColors.mutedGold : AppColors.deepRed,
            ),
            onPressed: () async {
              final DateTime? picked = await Navigator.of(context).push<DateTime>(
                MaterialPageRoute(
                  builder: (_) => CalendarScreen(initialDate: _selectedDate),
                ),
              );
              if (picked != null && picked != _selectedDate) {
                setState(() {
                  _selectedDate = picked;
                });
              }
            },
          ),
          IconButton(
            icon: Icon(
              themeProvider.themeMode == ThemeMode.dark 
                  ? Icons.light_mode 
                  : Icons.dark_mode,
              color: isDark ? AppColors.mutedGold : AppColors.deepRed,
            ),
            onPressed: () {
              final newIsDark = themeProvider.themeMode != ThemeMode.dark;
              themeProvider.toggleTheme(newIsDark);
              firestoreService.updateTheme(user.uid, newIsDark);
            },
          ),
          IconButton(
             icon: Icon(
               Icons.logout,
               color: isDark ? AppColors.offWhite : Colors.grey[700],
             ),
             onPressed: () => authProvider.signOut(),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // --- User Stats Header ---
          Container(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: MediaQuery.of(context).padding.top + 16,
              bottom: 16,
            ),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: isDark 
                    ? [AppColors.charcoal, AppColors.pureBlack]
                    : [Colors.grey.shade100, Colors.white],
              ),
            ),
            child: Column(
              children: [
                // Date selector
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _formatDate(_selectedDate),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isDark ? AppColors.mutedGold : AppColors.deepRed,
                      ),
                    ),
                    Row(
                      children: [
                        IconButton(
                          icon: Icon(
                            Icons.chevron_left,
                            color: isDark ? AppColors.mutedGold : AppColors.deepRed,
                          ),
                          onPressed: () {
                            setState(() {
                              _selectedDate = _selectedDate.subtract(const Duration(days: 1));
                            });
                          },
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.today_rounded,
                            color: isDark ? AppColors.mutedGold : AppColors.deepRed,
                          ),
                          onPressed: () {
                            setState(() {
                              _selectedDate = DateTime.now();
                            });
                          },
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.chevron_right,
                            color: isDark ? AppColors.mutedGold : AppColors.deepRed,
                          ),
                          onPressed: () {
                            setState(() {
                              _selectedDate = _selectedDate.add(const Duration(days: 1));
                            });
                          },
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Stats row
                StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                  stream: firestoreService.getUserStream(user.uid),
                  builder: (context, snapshot) {
                    int streak = 0;
                    int penalty = 0;
                    if (snapshot.hasData && snapshot.data!.exists) {
                      final data = snapshot.data!.data();
                      streak = data?['currentStreak'] ?? 0;
                      penalty = data?['penalty'] ?? 0;
                    }
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildStatCard(
                          context, 
                          'Streak', 
                          streak, 
                          '🔥', 
                          isDark ? AppColors.mutedGold : Colors.orange,
                          isDark,
                        ),
                        Container(
                          width: 1,
                          height: 60,
                          color: isDark ? AppColors.charcoalLight : Colors.grey.shade300,
                        ),
                        _buildStatCard(
                          context, 
                          'Penalty', 
                          penalty, 
                          '💀', 
                          isDark ? AppColors.cursedRed : Colors.red,
                          isDark,
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
          
          // --- Task List ---
          Expanded(
            child: StreamBuilder<List<Task>>(
              stream: firestoreService.getTasksForDateStream(user.uid, _selectedDate),
              builder: (context, snapshot) {
                debugPrint("StreamBuilder state: ${snapshot.connectionState}");
                debugPrint("StreamBuilder hasError: ${snapshot.hasError}");
                debugPrint("StreamBuilder hasData: ${snapshot.hasData}");
                
                // Show loading only on initial connection, not when data is available
                if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
                   debugPrint("StreamBuilder waiting for initial data...");
                   return const Center(child: CircularProgressIndicator());
                }
                
                if (snapshot.hasError) {
                   debugPrint("StreamBuilder encountered an error: ${snapshot.error}");
                   return Center(
                     child: Column(
                       mainAxisAlignment: MainAxisAlignment.center,
                       children: [
                         const Icon(Icons.error_outline, size: 64, color: Colors.red),
                         const SizedBox(height: 16),
                         Text(
                           'Error loading tasks',
                           style: TextStyle(color: AppColors.cursedRed),
                         ),
                         const SizedBox(height: 8),
                         Text(
                           '${snapshot.error}',
                           style: const TextStyle(fontSize: 12),
                           textAlign: TextAlign.center,
                         ),
                       ],
                     ),
                   );
                }
                
                final tasks = snapshot.data ?? [];
                debugPrint("StreamBuilder received data. Tasks count: ${tasks.length}");
                
                // Always show the UI, even if tasks are empty
                return Column(
                  children: [
                    // Progress indicator
                    Container(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "TODAY'S DISCIPLINE",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.5,
                                  color: isDark ? AppColors.offWhite : Colors.grey.shade800,
                                ),
                              ),
                              Text(
                                '${tasks.where((t) => t.isCompleted).length} / ${tasks.length}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? AppColors.mutedGold : AppColors.deepRed,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          LinearProgressIndicator(
                            value: tasks.isEmpty ? 0.0 : tasks.where((t) => t.isCompleted).length / tasks.length,
                            minHeight: 8,
                            backgroundColor: isDark ? AppColors.charcoalLight : Colors.grey.shade300,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              tasks.isEmpty || (tasks.where((t) => t.isCompleted).length / tasks.length) != 1.0 
                                  ? (isDark ? AppColors.deepRed : AppColors.deepRed)
                                  : (isDark ? AppColors.mutedGold : Colors.green),
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // Task list or empty state
                    Expanded(
                      child: tasks.isEmpty 
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.fitness_center_rounded,
                                    size: 80,
                                    color: isDark ? AppColors.charcoalLight : Colors.grey.shade400,
                                  ),
                                  const SizedBox(height: 24),
                                  Text(
                                    'NO TASKS FOR THIS DATE',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 2,
                                      color: isDark ? AppColors.mutedGold : AppColors.deepRed,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Add tasks or select a different date',
                                    style: TextStyle(
                                      color: isDark ? AppColors.dimWhite : Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              itemCount: tasks.length,
                              itemBuilder: (context, index) {
                                final task = tasks[index];
                                return Dismissible(
                                  key: Key(task.id),
                                  direction: DismissDirection.endToStart,
                                  background: Container(
                                    alignment: Alignment.centerRight,
                                    padding: const EdgeInsets.only(right: 20),
                                    margin: const EdgeInsets.symmetric(vertical: 4),
                                    decoration: BoxDecoration(
                                      color: AppColors.cursedRed,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Icon(
                                      Icons.delete_rounded,
                                      color: Colors.white,
                                    ),
                                  ),
                                  confirmDismiss: (direction) async {
                                    return await showDialog(
                                      context: context,
                                      builder: (ctx) => AlertDialog(
                                        title: const Text('Delete Task'),
                                        content: Text('Delete "${task.title}"?'),
                                        actions: [
                                          TextButton(
                                            onPressed: () => Navigator.of(ctx).pop(false),
                                            child: const Text('Cancel'),
                                          ),
                                          TextButton(
                                            onPressed: () => Navigator.of(ctx).pop(true),
                                            style: TextButton.styleFrom(
                                              foregroundColor: AppColors.cursedRed,
                                            ),
                                            child: const Text('Delete'),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                  onDismissed: (direction) async {
                                    await firestoreService.deleteTask(user.uid, task.id);
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text('Task "${task.title}" deleted'),
                                          backgroundColor: isDark ? AppColors.charcoal : null,
                                        ),
                                      );
                                    }
                                  },
                                  child: Card(
                                    margin: const EdgeInsets.symmetric(vertical: 4),
                                    child: ListTile(
                                      leading: Checkbox(
                                        value: task.isCompleted,
                                        activeColor: isDark ? AppColors.mutedGold : AppColors.deepRed,
                                        onChanged: (val) async {
                                          await firestoreService.toggleTaskStatus(
                                            user.uid, 
                                            task.id, 
                                            val ?? false,
                                          );
                                          
                                          if (val == true) {
                                            final userDoc = await firestoreService.getUser(user.uid);
                                            final data = userDoc.data();
                                            final currentStreak = data?['currentStreak'] ?? 0;
                                            DateTime? lastTaskDate;
                                            if (data != null && data['lastTaskDate'] != null) {
                                               lastTaskDate = (data['lastTaskDate'] as Timestamp).toDate();
                                            }
                                            
                                            final (newStreak, changed) = StreakLogic.calculateNewStreak(
                                              currentStreak, 
                                              lastTaskDate,
                                            );
                                            
                                            if (changed) {
                                               await firestoreService.updateUserStats(
                                                 user.uid, 
                                                 streak: newStreak, 
                                                 lastTaskDate: DateTime.now(),
                                               );
                                                
                                               // Show milestone message
                                               if (context.mounted && _isMilestone(newStreak)) {
                                                 ScaffoldMessenger.of(context).showSnackBar(
                                                   SnackBar(
                                                     content: Text(
                                                       _getMilestoneMessage(newStreak),
                                                       style: const TextStyle(fontWeight: FontWeight.bold),
                                                     ),
                                                     backgroundColor: isDark ? AppColors.mutedGold : Colors.orange,
                                                     duration: const Duration(seconds: 4),
                                                   ),
                                                 );
                                               }
                                            } else {
                                               await firestoreService.updateUserStats(
                                                 user.uid, 
                                                 lastTaskDate: DateTime.now(),
                                               );
                                            }
                                          }
                                        },
                                      ),
                                      title: Text(
                                        task.title,
                                        style: TextStyle(
                                          decoration: task.isCompleted 
                                              ? TextDecoration.lineThrough 
                                              : null,
                                          color: task.isCompleted 
                                              ? (isDark ? AppColors.dimWhite : Colors.grey) 
                                              : null,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      subtitle: task.description.isNotEmpty 
                                          ? Text(
                                              task.description,
                                              style: TextStyle(
                                                color: isDark ? AppColors.dimWhite : Colors.grey.shade600,
                                              ),
                                            ) 
                                          : null,
                                      trailing: task.isCompleted
                                          ? Icon(
                                              Icons.check_circle_rounded,
                                              color: isDark ? AppColors.mutedGold : Colors.green,
                                            )
                                          : null,
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await showDialog<Map<String, dynamic>>(
            context: context,
            builder: (_) => const AddTaskDialog(),
          );
          
          if (result != null) {
            await firestoreService.addTask(
              user.uid,
              result['title']!,
              result['description']!,
              createdAt: _selectedDate,
              duration: result['duration'],
              endDate: result['endDate'],
            );
          }
        },
        backgroundColor: isDark ? AppColors.deepRed : AppColors.deepRed,
        foregroundColor: Colors.white,
        label: const Text(
          'ADD TASK',
          style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1),
        ),
        icon: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context, 
    String label, 
    int value, 
    String emoji, 
    Color color,
    bool isDark,
  ) {
    final screenWidth = MediaQuery.of(context).size.width;
    final fontSize = screenWidth < 360 ? 28.0 : 36.0; // Smaller font for small screens
    final emojiSize = screenWidth < 360 ? 20.0 : 28.0;
    
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$value',
              style: TextStyle(
                fontSize: fontSize,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(width: 8),
            Text(emoji, style: TextStyle(fontSize: emojiSize)),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          label.toUpperCase(),
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.5,
            color: isDark ? AppColors.dimWhite : Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  bool _isMilestone(int streak) {
    return streak == 10 || streak == 20 || streak == 50 || streak == 100 || streak == 150;
  }

  String _getMilestoneMessage(int streak) {
    switch (streak) {
      case 10:
        return '🔥 10 days! Your discipline grows stronger!';
      case 20:
        return '⚔️ 20 days! A warrior emerges!';
      case 50:
        return '🛡️ 50 days! You have earned a Relief Day!';
      case 100:
        return '👑 100 days! A legend in the making!';
      case 150:
        return '🌟 150 days! You have achieved mastery!';
      default:
        return '🔥 Milestone achieved!';
    }
  }

  String _formatDate(DateTime date) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}
