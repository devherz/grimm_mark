enum TaskStatus {
  todo,
  inProgress,
  completed,
}

extension TaskStatusExtension on TaskStatus {
  String get label {
    switch (this) {
      case TaskStatus.todo:
        return 'À faire';
      case TaskStatus.inProgress:
        return 'En cours';
      case TaskStatus.completed:
        return 'Terminé';
    }
  }

  String get code {
    switch (this) {
      case TaskStatus.todo:
        return 'todo';
      case TaskStatus.inProgress:
        return 'in_progress';
      case TaskStatus.completed:
        return 'completed';
    }
  }

  static TaskStatus fromCode(String code) {
    switch (code) {
      case 'in_progress':
        return TaskStatus.inProgress;
      case 'completed':
        return TaskStatus.completed;
      case 'todo':
      default:
        return TaskStatus.todo;
    }
  }
}

class Task {
  final String id;
  final String title;
  final String description;
  final double allocatedBudget;
  final double actualSpent;
  final DateTime startDate;
  final DateTime dueDate;
  final String responsible; // Saisie libre du nom/rôle du responsable
  final TaskStatus status;
  final String executionResult; // Résultat / Impact obtenu après exécution
  final String receiptNote; // Référence de facture / Reçu justificatif

  Task({
    required this.id,
    required this.title,
    this.description = '',
    required this.allocatedBudget,
    this.actualSpent = 0.0,
    required this.startDate,
    required this.dueDate,
    required this.responsible,
    this.status = TaskStatus.todo,
    this.executionResult = '',
    this.receiptNote = '',
  });

  Task copyWith({
    String? id,
    String? title,
    String? description,
    double? allocatedBudget,
    double? actualSpent,
    DateTime? startDate,
    DateTime? dueDate,
    String? responsible,
    TaskStatus? status,
    String? executionResult,
    String? receiptNote,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      allocatedBudget: allocatedBudget ?? this.allocatedBudget,
      actualSpent: actualSpent ?? this.actualSpent,
      startDate: startDate ?? this.startDate,
      dueDate: dueDate ?? this.dueDate,
      responsible: responsible ?? this.responsible,
      status: status ?? this.status,
      executionResult: executionResult ?? this.executionResult,
      receiptNote: receiptNote ?? this.receiptNote,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'allocatedBudget': allocatedBudget,
      'actualSpent': actualSpent,
      'startDate': startDate.toIso8601String(),
      'dueDate': dueDate.toIso8601String(),
      'responsible': responsible,
      'status': status.code,
      'executionResult': executionResult,
      'receiptNote': receiptNote,
    };
  }

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String? ?? '',
      allocatedBudget: (json['allocatedBudget'] as num).toDouble(),
      actualSpent: (json['actualSpent'] as num?)?.toDouble() ?? 0.0,
      startDate: DateTime.parse(json['startDate'] as String),
      dueDate: DateTime.parse(json['dueDate'] as String),
      responsible: json['responsible'] as String? ?? 'Non assigné',
      status: TaskStatusExtension.fromCode(json['status'] as String? ?? 'todo'),
      executionResult: json['executionResult'] as String? ?? '',
      receiptNote: json['receiptNote'] as String? ?? '',
    );
  }
}
