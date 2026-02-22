enum TaskDuration {
  once('once', 'Once'),
  daily('daily', 'Daily'),
  weekly('weekly', 'Weekly'),
  custom('custom', 'Custom');

  const TaskDuration(this.value, this.displayName);
  
  final String value;
  final String displayName;

  static TaskDuration fromString(String value) {
    return TaskDuration.values.firstWhere(
      (duration) => duration.value == value,
      orElse: () => TaskDuration.once,
    );
  }
}
