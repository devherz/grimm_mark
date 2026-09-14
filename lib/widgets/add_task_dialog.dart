import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/budget.dart';
import '../models/task.dart';

class AddTaskResult {
  final String budgetId;
  final Task task;

  AddTaskResult({required this.budgetId, required this.task});
}

class AddTaskDialog extends StatefulWidget {
  final Task? taskToEdit;
  final List<Budget> availableBudgets;
  final String? initialBudgetId;

  const AddTaskDialog({
    super.key,
    this.taskToEdit,
    required this.availableBudgets,
    this.initialBudgetId,
  });

  @override
  State<AddTaskDialog> createState() => _AddTaskDialogState();
}

class _AddTaskDialogState extends State<AddTaskDialog> {
  final _formKey = GlobalKey<FormState>();

  late String _selectedBudgetId;
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _allocatedController;
  late TextEditingController _spentController;
  late TextEditingController _responsibleController;
  late TextEditingController _executionResultController;
  late TextEditingController _receiptNoteController;

  late DateTime _startDate;
  late DateTime _dueDate;
  late TaskStatus _status;

  final DateFormat _dateFormat = DateFormat('dd/MM/yyyy');

  @override
  void initState() {
    super.initState();
    final task = widget.taskToEdit;

    // Sélection du budget principal
    if (widget.initialBudgetId != null && widget.availableBudgets.any((b) => b.id == widget.initialBudgetId)) {
      _selectedBudgetId = widget.initialBudgetId!;
    } else if (widget.availableBudgets.isNotEmpty) {
      _selectedBudgetId = widget.availableBudgets.first.id;
    } else {
      _selectedBudgetId = '';
    }

    _titleController = TextEditingController(text: task?.title ?? '');
    _descriptionController = TextEditingController(text: task?.description ?? '');
    _allocatedController = TextEditingController(
      text: task != null ? task.allocatedBudget.toStringAsFixed(0) : '',
    );
    _spentController = TextEditingController(
      text: task != null ? task.actualSpent.toStringAsFixed(0) : '0',
    );
    _responsibleController = TextEditingController(
      text: task?.responsible ?? '',
    );
    _executionResultController = TextEditingController(
      text: task?.executionResult ?? '',
    );
    _receiptNoteController = TextEditingController(
      text: task?.receiptNote ?? '',
    );

    _startDate = task?.startDate ?? DateTime.now();
    _dueDate = task?.dueDate ?? DateTime.now().add(const Duration(days: 7));
    _status = task?.status ?? TaskStatus.todo;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _allocatedController.dispose();
    _spentController.dispose();
    _responsibleController.dispose();
    _executionResultController.dispose();
    _receiptNoteController.dispose();
    super.dispose();
  }

  Future<void> _pickDate(bool isStart) async {
    final initialDate = isStart ? _startDate : _dueDate;
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
                  primary: Colors.teal,
                ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
          if (_dueDate.isBefore(_startDate)) {
            _dueDate = _startDate.add(const Duration(days: 1));
          }
        } else {
          _dueDate = picked;
        }
      });
    }
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      if (_selectedBudgetId.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Veuillez sélectionner un budget principal')),
        );
        return;
      }

      final title = _titleController.text.trim();
      final description = _descriptionController.text.trim();
      final allocated = double.parse(_allocatedController.text.trim());
      final spent = double.tryParse(_spentController.text.trim()) ?? 0.0;
      final responsibleText = _responsibleController.text.trim();
      final executionResult = _executionResultController.text.trim();
      final receiptNote = _receiptNoteController.text.trim();

      final newTask = Task(
        id: widget.taskToEdit?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        title: title,
        description: description,
        allocatedBudget: allocated,
        actualSpent: spent,
        startDate: _startDate,
        dueDate: _dueDate,
        responsible: responsibleText.isEmpty ? 'Non assigné' : responsibleText,
        status: _status,
        executionResult: executionResult,
        receiptNote: receiptNote,
      );

      Navigator.of(context).pop(
        AddTaskResult(budgetId: _selectedBudgetId, task: newTask),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.taskToEdit != null;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(
        isEditing ? 'Modifier la Tâche' : 'Nouvelle Tâche',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: isDark ? Colors.white : Colors.black87,
        ),
      ),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Sélection du Budget Principal
              const Text(
                'Budget Principal *',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                isExpanded: true,
                value: _selectedBudgetId.isNotEmpty ? _selectedBudgetId : null,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.pie_chart, color: Colors.teal),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
                hint: const Text('Sélectionner un budget'),
                items: widget.availableBudgets.map((b) {
                  return DropdownMenuItem<String>(
                    value: b.id,
                    child: Row(
                      children: [
                        Icon(b.icon, color: b.color, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            b.title,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
                validator: (val) {
                  if (val == null || val.isEmpty) {
                    return 'Veuillez lier la tâche à un budget principal';
                  }
                  return null;
                },
                onChanged: (val) {
                  if (val != null) {
                    setState(() {
                      _selectedBudgetId = val;
                    });
                  }
                },
              ),
              const SizedBox(height: 14),

              // Titre de la Tâche
              TextFormField(
                controller: _titleController,
                style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                decoration: const InputDecoration(
                  labelText: 'Titre de la tâche *',
                  hintText: 'ex: Campagne réseaux sociaux',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.task_alt, color: Colors.teal),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Le titre est obligatoire';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),

              // Description
              TextFormField(
                controller: _descriptionController,
                style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                decoration: const InputDecoration(
                  labelText: 'Description',
                  hintText: 'Détails des objectifs et livrables...',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.description, color: Colors.teal),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 12),

              // Budgets: Prévu & Dépensé
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _allocatedController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                      decoration: const InputDecoration(
                        labelText: 'Coût prévu (FCFA) *',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.attach_money, color: Colors.teal),
                      ),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) {
                          return 'Requis';
                        }
                        if (double.tryParse(val.trim()) == null || double.parse(val.trim()) < 0) {
                          return 'Invalide';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      controller: _spentController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                      decoration: const InputDecoration(
                        labelText: 'Dépense réelle (FCFA)',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.account_balance_wallet, color: Colors.teal),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Champ Responsable (Saisie libre de nom / rôle)
              TextFormField(
                controller: _responsibleController,
                style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                decoration: const InputDecoration(
                  labelText: 'Responsable (Nom / Rôle)',
                  hintText: 'ex: Marc Dupont - Marketeur',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person_outline, color: Colors.teal),
                  helperText: 'Saisie libre du nom/rôle de la personne assignée',
                ),
              ),
              const SizedBox(height: 12),

              // Référence de Reçu / Facture Justificative
              TextFormField(
                controller: _receiptNoteController,
                style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                decoration: const InputDecoration(
                  labelText: 'Justificatif / N° de Reçu / Facture',
                  hintText: 'ex: Reçu N° FACT-2026-084',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.receipt_long, color: Colors.teal),
                ),
              ),
              const SizedBox(height: 12),

              // Dates Début & Fin
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () => _pickDate(true),
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Date Début',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.calendar_today, size: 18, color: Colors.teal),
                        ),
                        child: Text(
                          _dateFormat.format(_startDate),
                          style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: InkWell(
                      onTap: () => _pickDate(false),
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Échéance',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.event, size: 18, color: Colors.teal),
                        ),
                        child: Text(
                          _dateFormat.format(_dueDate),
                          style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Statut
              DropdownButtonFormField<TaskStatus>(
                isExpanded: true,
                value: _status,
                decoration: const InputDecoration(
                  labelText: 'Statut de la tâche',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.flag_outlined, color: Colors.teal),
                ),
                items: TaskStatus.values.map((status) {
                  return DropdownMenuItem(
                    value: status,
                    child: Row(
                      children: [
                        Icon(
                          status == TaskStatus.completed
                              ? Icons.check_circle
                              : status == TaskStatus.inProgress
                                  ? Icons.timelapse
                                  : Icons.radio_button_unchecked,
                          size: 18,
                          color: status == TaskStatus.completed
                              ? Colors.green
                              : status == TaskStatus.inProgress
                                  ? Colors.blue
                                  : Colors.grey,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          status.label,
                          style: TextStyle(
                            color: isDark ? Colors.white : Colors.black87,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) {
                    setState(() {
                      _status = val;
                    });
                  }
                },
              ),
              const SizedBox(height: 14),

              // Résultat / Impact Obtenu après exécution
              TextFormField(
                controller: _executionResultController,
                style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                decoration: const InputDecoration(
                  labelText: 'Résultat / Impact Obtenu (Bilan)',
                  hintText: 'ex: Pack de 15 visuels livré avec succès (+25% d\'engagement)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.emoji_events_outlined, color: Colors.amber),
                  helperText: 'Bilan présenté dans l\'onglet Résultats & Bilan',
                ),
                maxLines: 2,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Annuler'),
        ),
        ElevatedButton(
          onPressed: _submit,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.teal,
            foregroundColor: Colors.white,
          ),
          child: Text(isEditing ? 'Enregistrer' : 'Créer Tâche'),
        ),
      ],
    );
  }
}
