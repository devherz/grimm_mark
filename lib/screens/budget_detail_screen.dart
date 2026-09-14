import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/budget.dart';
import '../models/task.dart';
import '../providers/app_state.dart';
import '../widgets/add_budget_dialog.dart';
import '../widgets/add_task_dialog.dart';

class BudgetDetailScreen extends StatefulWidget {
  final String budgetId;

  const BudgetDetailScreen({super.key, required this.budgetId});

  @override
  State<BudgetDetailScreen> createState() => _BudgetDetailScreenState();
}

class _BudgetDetailScreenState extends State<BudgetDetailScreen> {
  final DateFormat _dateFormat = DateFormat('dd MMM yyyy', 'fr_FR');
  TaskStatus? _filterStatus;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ListenableBuilder(
      listenable: AppStateProvider.of(context),
      builder: (context, child) {
        final appState = AppStateProvider.of(context);
        final budget = appState.budgets.firstWhere(
          (b) => b.id == widget.budgetId,
          orElse: () => Budget(id: '', title: '', allocatedBudget: 0),
        );

        if (budget.id.isEmpty) {
          return Scaffold(
            appBar: AppBar(title: const Text('Budget non trouvé')),
            body: const Center(child: Text('Ce budget a été supprimé.')),
          );
        }

        final filteredTasks = _filterStatus == null
            ? budget.tasks
            : budget.tasks.where((t) => t.status == _filterStatus).toList();

        final currencyFormat = NumberFormat.currency(locale: 'fr_FR', symbol: 'FCFA', decimalDigits: 0);

        return Scaffold(
          appBar: AppBar(
            title: Text(
              budget.title,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            backgroundColor: budget.color,
            foregroundColor: Colors.white,
            actions: [
              IconButton(
                icon: const Icon(Icons.edit, color: Colors.white),
                tooltip: 'Modifier ce budget',
                onPressed: () async {
                  final updated = await showDialog<Budget>(
                    context: context,
                    builder: (_) => AddBudgetDialog(budgetToEdit: budget),
                  );
                  if (updated != null) {
                    await appState.updateBudget(updated);
                  }
                },
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.white),
                tooltip: 'Supprimer ce budget',
                onPressed: () => _confirmDeleteBudget(context, appState, budget),
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Carte de Synthèse du Budget
                _buildHeaderSummary(budget, currencyFormat, isDark),
                const SizedBox(height: 20),

                // Entête Tâches + Bouton Ajouter
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Tâches associées (${budget.tasks.length})',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () async {
                        final result = await showDialog<AddTaskResult>(
                          context: context,
                          builder: (_) => AddTaskDialog(
                            availableBudgets: appState.budgets,
                            initialBudgetId: budget.id,
                          ),
                        );
                        if (result != null) {
                          await appState.addTask(result.budgetId, result.task);
                        }
                      },
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Tâche'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: budget.color,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Filtres par statut
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      FilterChip(
                        label: const Text('Tous'),
                        selected: _filterStatus == null,
                        onSelected: (selected) {
                          if (selected) setState(() => _filterStatus = null);
                        },
                      ),
                      const SizedBox(width: 8),
                      FilterChip(
                        label: const Text('À faire'),
                        selected: _filterStatus == TaskStatus.todo,
                        onSelected: (selected) {
                          setState(() => _filterStatus = selected ? TaskStatus.todo : null);
                        },
                      ),
                      const SizedBox(width: 8),
                      FilterChip(
                        label: const Text('En cours'),
                        selected: _filterStatus == TaskStatus.inProgress,
                        onSelected: (selected) {
                          setState(() => _filterStatus = selected ? TaskStatus.inProgress : null);
                        },
                      ),
                      const SizedBox(width: 8),
                      FilterChip(
                        label: const Text('Terminés'),
                        selected: _filterStatus == TaskStatus.completed,
                        onSelected: (selected) {
                          setState(() => _filterStatus = selected ? TaskStatus.completed : null);
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Liste des Tâches
                if (filteredTasks.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white10 : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        Icon(Icons.assignment_outlined, size: 48, color: Colors.grey.shade400),
                        const SizedBox(height: 8),
                        Text(
                          _filterStatus != null
                              ? 'Aucune tâche trouvée pour ce filtre.'
                              : 'Aucune tâche définie dans ce budget.',
                          style: TextStyle(color: isDark ? Colors.white70 : Colors.grey.shade600),
                        ),
                      ],
                    ),
                  )
                else
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: filteredTasks.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final task = filteredTasks[index];
                      return _buildTaskCard(context, appState, budget, task, currencyFormat, isDark);
                    },
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeaderSummary(Budget budget, NumberFormat currencyFormat, bool isDark) {
    final progress = budget.allocatedBudget > 0
        ? (budget.totalSpent / budget.allocatedBudget).clamp(0.0, 1.0)
        : 0.0;

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: budget.color.withValues(alpha: 0.2),
                  child: Icon(budget.icon, color: budget.color),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        budget.title,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      if (budget.description.isNotEmpty)
                        Text(
                          budget.description,
                          style: TextStyle(
                            color: isDark ? Colors.white70 : Colors.grey.shade600,
                            fontSize: 13,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildStatItem('Alloué', currencyFormat.format(budget.allocatedBudget), isDark ? Colors.white : Colors.black87, isDark),
                _buildStatItem('Dépensé', currencyFormat.format(budget.totalSpent), Colors.orange.shade800, isDark),
                _buildStatItem(
                  'Disponible',
                  currencyFormat.format(budget.remainingBudget),
                  budget.remainingBudget >= 0 ? Colors.green.shade700 : Colors.red,
                  isDark,
                ),
              ],
            ),
            const SizedBox(height: 14),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 10,
                backgroundColor: isDark ? Colors.white12 : Colors.grey.shade200,
                color: budget.remainingBudget < 0 ? Colors.red : budget.color,
              ),
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Utilisé: ${(progress * 100).toStringAsFixed(1)}%',
                  style: TextStyle(fontSize: 12, color: isDark ? Colors.white70 : Colors.grey.shade600),
                ),
                Text(
                  'Tâches complétées: ${budget.completedTasksCount} / ${budget.tasks.length}',
                  style: TextStyle(fontSize: 12, color: isDark ? Colors.white70 : Colors.grey.shade600),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 12, color: isDark ? Colors.white70 : Colors.grey.shade600),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color),
        ),
      ],
    );
  }

  Widget _buildTaskCard(
    BuildContext context,
    AppState appState,
    Budget budget,
    Task task,
    NumberFormat currencyFormat,
    bool isDark,
  ) {
    Color statusColor;
    switch (task.status) {
      case TaskStatus.todo:
        statusColor = Colors.orange;
        break;
      case TaskStatus.inProgress:
        statusColor = Colors.blue;
        break;
      case TaskStatus.completed:
        statusColor = Colors.green;
        break;
    }

    return Card(
      elevation: 1.5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                InkWell(
                  onTap: () => appState.toggleTaskStatus(budget.id, task.id),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: statusColor.withValues(alpha: 0.5)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          task.status == TaskStatus.completed
                              ? Icons.check_circle
                              : task.status == TaskStatus.inProgress
                                  ? Icons.timelapse
                                  : Icons.radio_button_unchecked,
                          size: 14,
                          color: statusColor,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          task.status.label,
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: statusColor),
                        ),
                      ],
                    ),
                  ),
                ),
                const Spacer(),
                PopupMenuButton<String>(
                  icon: Icon(Icons.more_vert, size: 20, color: isDark ? Colors.white70 : Colors.grey.shade600),
                  onSelected: (val) async {
                    if (val == 'edit') {
                      final result = await showDialog<AddTaskResult>(
                        context: context,
                        builder: (_) => AddTaskDialog(
                          taskToEdit: task,
                          availableBudgets: appState.budgets,
                          initialBudgetId: budget.id,
                        ),
                      );
                      if (result != null) {
                        if (result.budgetId != budget.id) {
                          await appState.deleteTask(budget.id, task.id);
                          await appState.addTask(result.budgetId, result.task);
                        } else {
                          await appState.updateTask(budget.id, result.task);
                        }
                      }
                    } else if (val == 'delete') {
                      await appState.deleteTask(budget.id, task.id);
                    }
                  },
                  itemBuilder: (_) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit, size: 18),
                          SizedBox(width: 8),
                          Text('Modifier'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, size: 18, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Supprimer', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              task.title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
                decoration: task.status == TaskStatus.completed ? TextDecoration.lineThrough : null,
              ),
            ),
            if (task.description.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                task.description,
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? Colors.white70 : Colors.grey.shade700,
                ),
              ),
            ],
            const SizedBox(height: 12),
            // Responsable Badge (Saisie Libre)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: isDark ? Colors.white10 : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.person, size: 16, color: Colors.teal),
                  const SizedBox(width: 6),
                  Text(
                    'Responsable : ',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white70 : Colors.grey.shade700,
                    ),
                  ),
                  Flexible(
                    child: Text(
                      task.responsible,
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.teal),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            // Metrics & Dates Row
            Wrap(
              spacing: 16,
              runSpacing: 8,
              children: [
                _buildInfoBadge(
                  Icons.attach_money,
                  'Prévu: ${currencyFormat.format(task.allocatedBudget)}',
                  Colors.blue.shade700,
                ),
                if (task.actualSpent > 0)
                  _buildInfoBadge(
                    Icons.account_balance_wallet,
                    'Dépensé: ${currencyFormat.format(task.actualSpent)}',
                    Colors.deepOrange,
                  ),
                _buildInfoBadge(
                  Icons.calendar_today,
                  '${_dateFormat.format(task.startDate)} → ${_dateFormat.format(task.dueDate)}',
                  isDark ? Colors.white70 : Colors.grey.shade700,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoBadge(IconData icon, String text, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  void _confirmDeleteBudget(BuildContext context, AppState appState, Budget budget) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer le budget'),
        content: Text('Voulez-vous vraiment supprimer le budget "${budget.title}" et toutes ses tâches ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () async {
              Navigator.of(ctx).pop();
              await appState.deleteBudget(budget.id);
              if (context.mounted) {
                Navigator.of(context).pop();
              }
            },
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }
}
