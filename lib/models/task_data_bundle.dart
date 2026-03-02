import 'task.dart';

class TaskDataBundle {
  final int schemaVersion;
  final List<Task> tasks;
  final List<Task> deletedTasks;

  const TaskDataBundle({
    required this.schemaVersion,
    required this.tasks,
    this.deletedTasks = const [],
  });
}

