import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/task_model.dart';
import '../models/task_duration.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // --- User Methods ---

  Future<void> createUser(String uid, String email) async {
    try {
      await _db.collection('users').doc(uid).set({
        'email': email,
        'createdAt': FieldValue.serverTimestamp(),
        'themeMode': 'system',
        'currentStreak': 0,
        'penalty': 0,
        'lastTaskDate': null,
      }, SetOptions(merge: true));
    } catch (e) {
      throw Exception('Failed to save user data: $e');
    }
  }

  Future<DocumentSnapshot<Map<String, dynamic>>> getUser(String uid) async {
    try {
      return await _db.collection('users').doc(uid).get();
    } catch (e) {
      throw Exception('Failed to fetch user data: $e');
    }
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>> getUserStream(String uid) {
    return _db.collection('users').doc(uid).snapshots();
  }

  Future<void> updateTheme(String uid, bool isDark) async {
    try {
      await _db.collection('users').doc(uid).update({
        'themeMode': isDark ? 'dark' : 'light',
      });
    } catch (e) {
      debugPrint('Failed to sync theme: $e');
    }
  }

  Future<void> updateUserStats(String uid, {int? streak, int? penalty, DateTime? lastTaskDate}) async {
    Map<String, dynamic> data = {};
    if (streak != null) data['currentStreak'] = streak;
    if (penalty != null) data['penalty'] = penalty;
    if (lastTaskDate != null) data['lastTaskDate'] = Timestamp.fromDate(lastTaskDate);
    
    if (data.isNotEmpty) {
       await _db.collection('users').doc(uid).update(data);
    }
  }

  // --- Task Methods ---

  Future<void> addTask(String uid, String title, String description, {
    DateTime? createdAt,
    String? duration,
    String? endDate,
  }) async {
    try {
      final taskDuration = TaskDuration.fromString(duration ?? 'once');
      final taskEndDate = endDate != null ? DateTime.parse(endDate) : null;
      
      await _db.collection('users').doc(uid).collection('tasks').add({
        'title': title,
        'description': description,
        'isCompleted': false,
        'createdAt': createdAt != null 
            ? Timestamp.fromDate(createdAt)
            : FieldValue.serverTimestamp(),
        'completedAt': null,
        'duration': taskDuration.value,
        'endDate': taskEndDate != null ? Timestamp.fromDate(taskEndDate) : null,
      });
    } catch (e) {
      throw Exception('Failed to add task: $e');
    }
  }

  Stream<List<Task>> getTasksStream(String uid) {
    return _db
        .collection('users')
        .doc(uid)
        .collection('tasks')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Task.fromMap(doc.id, doc.data()))
            .toList());
  }

  Stream<List<Task>> getTasksForDateStream(String uid, DateTime date) {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    
    return _db
        .collection('users')
        .doc(uid)
        .collection('tasks')
        .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .where('createdAt', isLessThan: Timestamp.fromDate(endOfDay))
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          final tasks = snapshot.docs
              .map((doc) => Task.fromMap(doc.id, doc.data()))
              .toList();
          
          // Add recurring tasks for this date
          final allTasks = <Task>[];
          allTasks.addAll(tasks);
          
          return _addRecurringTasksForDate(allTasks, date);
        });
  }

  Future<List<Task>> getTasksForDate(String uid, DateTime date) async {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    
    final snapshot = await _db
        .collection('users')
        .doc(uid)
        .collection('tasks')
        .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .where('createdAt', isLessThan: Timestamp.fromDate(endOfDay))
        .orderBy('createdAt', descending: true)
        .get();
    
    final tasks = snapshot.docs
        .map((doc) => Task.fromMap(doc.id, doc.data()))
        .toList();
    
    // Add recurring tasks for this date
    return _addRecurringTasksForDate(tasks, date);
  }

  List<Task> _addRecurringTasksForDate(List<Task> tasks, DateTime date) {
    final recurringTasks = <Task>[];
    final normalizedDate = DateTime(date.year, date.month, date.day);
    
    for (final task in tasks) {
      if (task.duration == TaskDuration.once) {
        recurringTasks.add(task);
      } else if (task.duration == TaskDuration.daily) {
        // Add daily task if it's on or after creation date and before end date
        final taskCreatedDate = DateTime(task.createdAt.year, task.createdAt.month, task.createdAt.day);
        if (normalizedDate.isAtSameMomentAs(taskCreatedDate) || normalizedDate.isAfter(taskCreatedDate)) {
          if (task.endDate == null || normalizedDate.isBefore(DateTime(task.endDate!.year, task.endDate!.month, task.endDate!.day))) {
            recurringTasks.add(task);
          }
        }
      } else if (task.duration == TaskDuration.weekly) {
        // Add weekly task if it's the same weekday as creation date
        final taskCreatedDate = DateTime(task.createdAt.year, task.createdAt.month, task.createdAt.day);
        if (normalizedDate.weekday == taskCreatedDate.weekday && 
            (normalizedDate.isAtSameMomentAs(taskCreatedDate) || normalizedDate.isAfter(taskCreatedDate))) {
          if (task.endDate == null || normalizedDate.isBefore(DateTime(task.endDate!.year, task.endDate!.month, task.endDate!.day))) {
            recurringTasks.add(task);
          }
        }
      } else if (task.duration == TaskDuration.custom) {
        // Add custom task if it's within the date range
        final taskCreatedDate = DateTime(task.createdAt.year, task.createdAt.month, task.createdAt.day);
        if (normalizedDate.isAtSameMomentAs(taskCreatedDate) || normalizedDate.isAfter(taskCreatedDate)) {
          if (task.endDate != null && normalizedDate.isBefore(DateTime(task.endDate!.year, task.endDate!.month, task.endDate!.day))) {
            recurringTasks.add(task);
          }
        }
      }
    }
    
    return recurringTasks;
  }

  Future<void> toggleTaskStatus(String uid, String taskId, bool isCompleted) async {
    try {
      await _db
          .collection('users')
          .doc(uid)
          .collection('tasks')
          .doc(taskId)
          .update({
        'isCompleted': isCompleted,
        'completedAt': isCompleted ? FieldValue.serverTimestamp() : null,
      });
    } catch (e) {
      throw Exception('Failed to update task: $e');
    }
  }

  Future<void> deleteTask(String uid, String taskId) async {
    try {
      await _db
          .collection('users')
          .doc(uid)
          .collection('tasks')
          .doc(taskId)
          .delete();
    } catch (e) {
      throw Exception('Failed to delete task: $e');
    }
  }
}
