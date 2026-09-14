import 'package:flutter/material.dart';
import 'task.dart';

class Budget {
  final String id;
  final String title;
  final String description;
  final double allocatedBudget;
  final int iconCodePoint;
  final int colorValue;
  final List<Task> tasks;

  Budget({
    required this.id,
    required this.title,
    this.description = '',
    required this.allocatedBudget,
    int? iconCodePoint,
    int? colorValue,
    List<Task>? tasks,
  })  : iconCodePoint = iconCodePoint ?? Icons.campaign.codePoint,
        colorValue = colorValue ?? 0xFF00796B,
        tasks = tasks ?? [];

  static IconData getIconFromCodePoint(int codePoint) {
    if (codePoint == Icons.campaign.codePoint) return Icons.campaign;
    if (codePoint == Icons.cloud_done.codePoint) return Icons.cloud_done;
    if (codePoint == Icons.handshake.codePoint) return Icons.handshake;
    if (codePoint == Icons.palette.codePoint) return Icons.palette;
    if (codePoint == Icons.computer.codePoint) return Icons.computer;
    if (codePoint == Icons.trending_up.codePoint) return Icons.trending_up;
    if (codePoint == Icons.shopping_cart.codePoint) return Icons.shopping_cart;
    if (codePoint == Icons.attach_money.codePoint) return Icons.attach_money;
    if (codePoint == Icons.phone_iphone.codePoint) return Icons.phone_iphone;
    if (codePoint == Icons.build.codePoint) return Icons.build;
    return Icons.campaign;
  }

  IconData get icon => getIconFromCodePoint(iconCodePoint);
  Color get color => Color(colorValue);

  // Somme totale dépensée réellement sur les tâches de ce budget
  double get totalSpent {
    double total = 0.0;
    for (var task in tasks) {
      if (task.actualSpent > 0) {
        total += task.actualSpent;
      } else if (task.status == TaskStatus.completed) {
        total += task.allocatedBudget;
      }
    }
    return total;
  }

  // Budget encore disponible
  double get remainingBudget => allocatedBudget - totalSpent;

  // Somme des budgets alloués à chacune des tâches
  double get totalTasksAllocated {
    return tasks.fold(0.0, (sum, task) => sum + task.allocatedBudget);
  }

  int get completedTasksCount {
    return tasks.where((t) => t.status == TaskStatus.completed).length;
  }

  double get completionPercentage {
    if (tasks.isEmpty) return 0.0;
    return completedTasksCount / tasks.length;
  }

  Budget copyWith({
    String? id,
    String? title,
    String? description,
    double? allocatedBudget,
    int? iconCodePoint,
    int? colorValue,
    List<Task>? tasks,
  }) {
    return Budget(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      allocatedBudget: allocatedBudget ?? this.allocatedBudget,
      iconCodePoint: iconCodePoint ?? this.iconCodePoint,
      colorValue: colorValue ?? this.colorValue,
      tasks: tasks ?? List.from(this.tasks),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'allocatedBudget': allocatedBudget,
      'iconCodePoint': iconCodePoint,
      'colorValue': colorValue,
      'tasks': tasks.map((t) => t.toJson()).toList(),
    };
  }

  factory Budget.fromJson(Map<String, dynamic> json) {
    var rawTasks = json['tasks'] as List<dynamic>? ?? [];
    List<Task> loadedTasks = rawTasks
        .map((t) => Task.fromJson(t as Map<String, dynamic>))
        .toList();

    return Budget(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String? ?? '',
      allocatedBudget: (json['allocatedBudget'] as num).toDouble(),
      iconCodePoint: json['iconCodePoint'] as int? ?? Icons.campaign.codePoint,
      colorValue: json['colorValue'] as int? ?? 0xFF00796B,
      tasks: loadedTasks,
    );
  }
}
