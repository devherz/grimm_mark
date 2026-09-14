import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/app_release.dart';
import '../models/budget.dart';
import '../models/task.dart';
import '../providers/app_state.dart';
import '../theme/app_theme.dart';
import '../services/pdf_export_service.dart';
import '../widgets/add_budget_dialog.dart';
import '../widgets/add_release_dialog.dart';
import '../widgets/add_task_dialog.dart';
import '../widgets/budget_charts.dart';
import '../widgets/roi_calculator_card.dart';
import 'budget_detail_screen.dart';

class RabbitryFinanceScreen extends StatefulWidget {
  const RabbitryFinanceScreen({super.key});

  @override
  State<RabbitryFinanceScreen> createState() => _RabbitryFinanceScreenState();
}

class _RabbitryFinanceScreenState extends State<RabbitryFinanceScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final NumberFormat _currencyFormat = NumberFormat.currency(locale: 'fr_FR', symbol: 'FCFA', decimalDigits: 0);
  final DateFormat _dateFormat = DateFormat('dd/MM/yyyy');
  String _searchQuery = '';
  TaskStatus? _selectedTaskFilter;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appState = AppStateProvider.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (appState.isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppTheme.primaryEmerald),
      );
    }

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Header Executive Pro Chic
            Container(
              decoration: AppTheme.headerGradientDecoration.copyWith(
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(24),
                  bottomRight: Radius.circular(24),
                ),
              ),
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white24,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Colors.white30),
                        ),
                        child: const Icon(Icons.pets, color: Colors.white, size: 24),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'My Rabbitry - Dashboard Pro',
                              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            Text(
                              'Finances (FCFA) & Performance (${appState.organizationName})',
                              style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.picture_as_pdf, color: AppTheme.goldAccent),
                        tooltip: 'Exporter Bilan PDF',
                        onPressed: () async {
                          await PdfExportService.exportExecutiveReport(
                            appTitle: appState.currentApp.name,
                            organizationName: appState.organizationName,
                            budgets: appState.budgets,
                            appReleases: appState.appReleases,
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  // TabBar 5 Onglets Chic
                  Container(
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: TabBar(
                      controller: _tabController,
                      isScrollable: true,
                      indicator: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppTheme.goldAccent, Color(0xFFFFD700)],
                        ),
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)],
                      ),
                      labelColor: Colors.black,
                      unselectedLabelColor: Colors.white,
                      labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                      tabs: const [
                        Tab(icon: Icon(Icons.dashboard_customize_outlined, size: 16), text: 'Tableau de Bord'),
                        Tab(icon: Icon(Icons.pie_chart_outline, size: 16), text: 'Budgets'),
                        Tab(icon: Icon(Icons.checklist, size: 16), text: 'Tâches'),
                        Tab(icon: Icon(Icons.emoji_events_outlined, size: 16), text: 'Résultats & Bilan'),
                        Tab(icon: Icon(Icons.system_update_alt, size: 16), text: 'Mises à Jour Mobile'),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Contenu des 5 Onglets
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildExecutiveDashboardTab(context, appState, isDark),
                  _buildBudgetsTab(context, appState, isDark),
                  _buildAllTasksTab(context, appState, isDark),
                  _buildExecutionResultsTab(context, appState, isDark),
                  _buildAppReleasesTab(context, appState, isDark),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          _showQuickActionMenu(context, appState);
        },
        backgroundColor: AppTheme.primaryEmerald,
        foregroundColor: Colors.white,
        elevation: 4,
        icon: const Icon(Icons.add_circle_outline),
        label: const Text('Action Rapide', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }

  // --- ONGLET 1 : TABLEAU DE BORD PRO ---
  Widget _buildExecutiveDashboardTab(BuildContext context, AppState appState, bool isDark) {
    final totalAllocated = appState.totalAllocatedBudget;
    final totalSpent = appState.totalSpent;
    final remaining = appState.totalRemainingBudget;
    final progress = appState.overallProgress;

    List<Map<String, dynamic>> upcomingTasks = [];
    for (var b in appState.budgets) {
      for (var t in b.tasks) {
        if (t.status != TaskStatus.completed) {
          upcomingTasks.add({'budget': b, 'task': t});
        }
      }
    }
    upcomingTasks.sort((a, b) {
      final taskA = a['task'] as Task;
      final taskB = b['task'] as Task;
      return taskA.dueDate.compareTo(taskB.dueDate);
    });

    Set<String> responsibles = {};
    for (var b in appState.budgets) {
      for (var t in b.tasks) {
        if (t.responsible.isNotEmpty && t.responsible != 'Non assigné') {
          responsibles.add(t.responsible);
        }
      }
    }
    for (var r in appState.appReleases) {
      if (r.responsible.isNotEmpty && r.responsible != 'Non assigné') {
        responsibles.add(r.responsible);
      }
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // KPI Grid 4 Cartes Métriques
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.5,
            children: [
              _buildKpiCard(
                'Budget Total',
                _currencyFormat.format(totalAllocated),
                Icons.account_balance_wallet,
                AppTheme.primaryEmerald,
                isDark,
              ),
              _buildKpiCard(
                'Dépenses Réelles',
                _currencyFormat.format(totalSpent),
                Icons.trending_up,
                Colors.orange.shade800,
                isDark,
              ),
              _buildKpiCard(
                'Solde Disponible',
                _currencyFormat.format(remaining),
                Icons.savings,
                remaining >= 0 ? Colors.green.shade700 : Colors.red,
                isDark,
              ),
              _buildKpiCard(
                'Taux d\'Exécution',
                '${(progress * 100).toStringAsFixed(1)}%',
                Icons.speed,
                AppTheme.goldAccent,
                isDark,
              ),
            ],
          ),
          const SizedBox(height: 20),

          // GRAPHIQUE 1 : Camembert / Donut de Répartition des Budgets (Visual Donut Chart)
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            const Icon(Icons.pie_chart, color: AppTheme.primaryEmerald, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Répartition des Budgets',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  color: isDark ? Colors.white : Colors.black87,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppTheme.goldAccent.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '${appState.budgets.length} Catégories',
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.goldAccent),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  BudgetDonutChart(budgets: appState.budgets),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // GRAPHIQUE 2 : Histogramme de Comparaison (Alloué vs Dépensé par Catégorie en FCFA)
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.bar_chart, color: Colors.teal, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Comparatif Budgets Alloués vs Dépensés',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  BudgetBarChart(budgets: appState.budgets),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // PROCHAINE RELEASE BANNER
          if (appState.appReleases.isNotEmpty) ...[
            _buildUpcomingReleaseBanner(context, appState, isDark),
            const SizedBox(height: 20),
          ],

          // DÉTAIL FINANCIER PAR CATÉGORIE
          Text(
            'Détail Financier des Catégories (${appState.budgets.length})',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
          ),
          const SizedBox(height: 12),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: appState.budgets.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final budget = appState.budgets[index];
              return _buildDashboardCategoryDetailCard(context, budget, isDark);
            },
          ),
          const SizedBox(height: 20),

          // CALCULATEUR DE ROI & CAC
          RoiCalculatorCard(initialSpent: totalSpent),
          const SizedBox(height: 20),

          // Tâches Prioritaires
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.upcoming, color: Colors.orange, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Tâches Prioritaires à Venir',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                          ),
                        ],
                      ),
                      TextButton(
                        onPressed: () => _tabController.animateTo(2),
                        child: const Text('Voir Tout'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (upcomingTasks.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(16),
                      child: const Center(
                        child: Text(
                          'Toutes les tâches sont terminées ! 🎉',
                          style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                        ),
                      ),
                    )
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: upcomingTasks.take(3).length,
                      separatorBuilder: (_, __) => const Divider(height: 12),
                      itemBuilder: (context, idx) {
                        final budget = upcomingTasks[idx]['budget'] as Budget;
                        final task = upcomingTasks[idx]['task'] as Task;

                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: CircleAvatar(
                            backgroundColor: budget.color.withValues(alpha: 0.15),
                            child: Icon(budget.icon, color: budget.color, size: 18),
                          ),
                          title: Text(
                            task.title,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                          ),
                          subtitle: Text(
                            '${budget.title} • Responsable: ${task.responsible}',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? Colors.white70 : Colors.grey.shade700,
                            ),
                          ),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                _currencyFormat.format(task.allocatedBudget),
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  color: isDark ? Colors.white : Colors.black87,
                                ),
                              ),
                              Text(
                                _dateFormat.format(task.dueDate),
                                style: const TextStyle(fontSize: 11, color: Colors.orange, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Équipe & Responsables
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.people_outline, color: Colors.teal, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Équipe & Responsables Assignés',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (responsibles.isEmpty)
                    Text(
                      'Aucun responsable assigné.',
                      style: TextStyle(color: isDark ? Colors.white70 : Colors.grey.shade700),
                    )
                  else
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: responsibles.map((name) {
                        return Chip(
                          avatar: const CircleAvatar(
                            backgroundColor: Colors.teal,
                            child: Icon(Icons.person, size: 12, color: Colors.white),
                          ),
                          label: Text(
                            name,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                          ),
                          backgroundColor: isDark ? Colors.teal.shade900.withValues(alpha: 0.4) : Colors.teal.shade50,
                          side: BorderSide(color: Colors.teal.shade300),
                        );
                      }).toList(),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildDashboardCategoryDetailCard(BuildContext context, Budget budget, bool isDark) {
    final progress = budget.allocatedBudget > 0
        ? (budget.totalSpent / budget.allocatedBudget).clamp(0.0, 1.0)
        : 0.0;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => BudgetDetailScreen(budgetId: budget.id)),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(14.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 14,
                    backgroundColor: budget.color.withValues(alpha: 0.2),
                    child: Icon(budget.icon, color: budget.color, size: 16),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      budget.title,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                  ),
                  Icon(Icons.chevron_right, color: isDark ? Colors.white54 : Colors.grey.shade400),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 16,
                runSpacing: 6,
                alignment: WrapAlignment.spaceBetween,
                children: [
                  Text(
                    'Alloué: ${_currencyFormat.format(budget.allocatedBudget)}',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: isDark ? Colors.white70 : Colors.black87),
                  ),
                  Text(
                    'Dépensé: ${_currencyFormat.format(budget.totalSpent)}',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.orange.shade800),
                  ),
                  Text(
                    'Solde: ${_currencyFormat.format(budget.remainingBudget)}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: budget.remainingBudget >= 0 ? Colors.green.shade700 : Colors.red,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 7,
                  backgroundColor: isDark ? Colors.white12 : Colors.grey.shade200,
                  color: budget.remainingBudget < 0 ? Colors.red : budget.color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUpcomingReleaseBanner(BuildContext context, AppState appState, bool isDark) {
    final activeRelease = appState.appReleases.firstWhere(
      (r) => r.status != AppReleaseStatus.deployed,
      orElse: () => appState.appReleases.first,
    );

    Color statusColor;
    switch (activeRelease.status) {
      case AppReleaseStatus.planned:
        statusColor = Colors.orange;
        break;
      case AppReleaseStatus.inDevelopment:
        statusColor = Colors.blue;
        break;
      case AppReleaseStatus.inTesting:
        statusColor = Colors.purple;
        break;
      case AppReleaseStatus.deployed:
        statusColor = Colors.green;
        break;
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.teal.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.teal.shade300),
                  ),
                  child: Text(
                    activeRelease.version,
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.teal, fontSize: 13),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    activeRelease.title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    activeRelease.status.label,
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: statusColor),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'Publication prévue: ${_dateFormat.format(activeRelease.targetDate)}',
                    style: TextStyle(fontSize: 12, color: isDark ? Colors.white70 : Colors.grey.shade700),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                TextButton(
                  onPressed: () => _tabController.animateTo(4),
                  child: const Text('Programmes Mobile →'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKpiCard(String title, String value, IconData icon, Color color, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.4), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 14,
                backgroundColor: color.withValues(alpha: 0.15),
                child: Icon(icon, size: 16, color: color),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? Colors.white70 : Colors.grey.shade700,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color),
            ),
          ),
        ],
      ),
    );
  }

  // --- ONGLET 2 : VUE BUDGETS ---
  Widget _buildBudgetsTab(BuildContext context, AppState appState, bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Catégories Budgétaires (${appState.budgets.length})',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: () async {
                  final newBudget = await showDialog<Budget>(
                    context: context,
                    builder: (_) => const AddBudgetDialog(),
                  );
                  if (newBudget != null) {
                    await appState.addBudget(newBudget);
                  }
                },
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Nouveau Budget'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryEmerald,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          if (appState.budgets.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(36),
              decoration: BoxDecoration(
                color: isDark ? AppTheme.darkCard : Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: isDark ? Colors.white10 : Colors.grey.shade200),
              ),
              child: Column(
                children: [
                  Icon(Icons.account_balance_wallet_outlined, size: 54, color: Colors.grey.shade400),
                  const SizedBox(height: 12),
                  Text(
                    'Aucun budget alloué pour le moment.',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Cliquez sur le bouton "Nouveau Budget" pour allouer un budget marketing en FCFA.',
                    style: TextStyle(fontSize: 13, color: isDark ? Colors.white70 : Colors.grey.shade600),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: appState.budgets.length,
              separatorBuilder: (_, __) => const SizedBox(height: 14),
              itemBuilder: (context, index) {
                final budget = appState.budgets[index];
                return _buildBudgetCategoryCard(context, budget, isDark);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildBudgetCategoryCard(BuildContext context, Budget budget, bool isDark) {
    final progress = budget.allocatedBudget > 0
        ? (budget.totalSpent / budget.allocatedBudget).clamp(0.0, 1.0)
        : 0.0;

    return Card(
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => BudgetDetailScreen(budgetId: budget.id),
            ),
          );
        },
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: budget.color.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                      border: Border.all(color: budget.color.withValues(alpha: 0.3)),
                    ),
                    child: Icon(budget.icon, color: budget.color, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          budget.title,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                        if (budget.description.isNotEmpty)
                          Text(
                            budget.description,
                            style: TextStyle(fontSize: 12, color: isDark ? Colors.white70 : Colors.grey.shade600),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                  Icon(Icons.arrow_forward_ios, size: 16, color: isDark ? Colors.white54 : Colors.grey.shade400),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Alloué: ${_currencyFormat.format(budget.allocatedBudget)}',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  Text(
                    'Dépensé: ${_currencyFormat.format(budget.totalSpent)}',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: budget.remainingBudget < 0 ? Colors.red : Colors.orange.shade800,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 8,
                  backgroundColor: isDark ? Colors.white12 : Colors.grey.shade200,
                  color: budget.remainingBudget < 0 ? Colors.red : budget.color,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white10 : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '${budget.tasks.length} tâche(s)',
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? Colors.white70 : Colors.grey.shade700,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Text(
                    'Disponible: ${_currencyFormat.format(budget.remainingBudget)}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: budget.remainingBudget >= 0 ? Colors.green.shade700 : Colors.red,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- ONGLET 3 : VUE GLOBALE DES TÂCHES ---
  Widget _buildAllTasksTab(BuildContext context, AppState appState, bool isDark) {
    List<Map<String, dynamic>> allTaskItems = [];
    for (var budget in appState.budgets) {
      for (var task in budget.tasks) {
        allTaskItems.add({
          'budget': budget,
          'task': task,
        });
      }
    }

    final filtered = allTaskItems.where((item) {
      final task = item['task'] as Task;
      final matchesSearch = _searchQuery.isEmpty ||
          task.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          task.responsible.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesStatus = _selectedTaskFilter == null || task.status == _selectedTaskFilter;
      return matchesSearch && matchesStatus;
    }).toList();

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          color: isDark ? AppTheme.darkSurface : Colors.white,
          child: Column(
            children: [
              TextField(
                style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                decoration: InputDecoration(
                  hintText: 'Rechercher une tâche, un responsable...',
                  hintStyle: TextStyle(color: isDark ? Colors.white60 : Colors.grey.shade600),
                  prefixIcon: const Icon(Icons.search, color: Colors.teal),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                onChanged: (val) => setState(() => _searchQuery = val.trim()),
              ),
              const SizedBox(height: 8),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    FilterChip(
                      label: const Text('Tous'),
                      selected: _selectedTaskFilter == null,
                      onSelected: (_) => setState(() => _selectedTaskFilter = null),
                    ),
                    const SizedBox(width: 6),
                    FilterChip(
                      label: const Text('À faire'),
                      selected: _selectedTaskFilter == TaskStatus.todo,
                      onSelected: (_) => setState(() => _selectedTaskFilter = TaskStatus.todo),
                    ),
                    const SizedBox(width: 6),
                    FilterChip(
                      label: const Text('En cours'),
                      selected: _selectedTaskFilter == TaskStatus.inProgress,
                      onSelected: (_) => setState(() => _selectedTaskFilter = TaskStatus.inProgress),
                    ),
                    const SizedBox(width: 6),
                    FilterChip(
                      label: const Text('Terminés'),
                      selected: _selectedTaskFilter == TaskStatus.completed,
                      onSelected: (_) => setState(() => _selectedTaskFilter = TaskStatus.completed),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: filtered.isEmpty
              ? Center(
                  child: Text(
                    'Aucune tâche trouvée.',
                    style: TextStyle(color: isDark ? Colors.white70 : Colors.grey.shade600),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final budget = filtered[index]['budget'] as Budget;
                    final task = filtered[index]['task'] as Task;
                    return _buildGlobalTaskCard(context, appState, budget, task, isDark);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildGlobalTaskCard(BuildContext context, AppState appState, Budget budget, Task task, bool isDark) {
    return Card(
      elevation: 1.5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: budget.color.withValues(alpha: 0.15),
          child: Icon(budget.icon, color: budget.color, size: 20),
        ),
        title: Text(
          task.title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black87,
            decoration: task.status == TaskStatus.completed ? TextDecoration.lineThrough : null,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: budget.color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    budget.title,
                    style: TextStyle(fontSize: 10, color: budget.color, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.person, size: 12, color: Colors.teal),
                const SizedBox(width: 2),
                Expanded(
                  child: Text(
                    task.responsible,
                    style: const TextStyle(fontSize: 11, color: Colors.teal, fontWeight: FontWeight.w600),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Échéance: ${_dateFormat.format(task.dueDate)} • ${_currencyFormat.format(task.allocatedBudget)}',
              style: TextStyle(fontSize: 11, color: isDark ? Colors.white70 : Colors.grey.shade600),
            ),
          ],
        ),
        trailing: Checkbox(
          value: task.status == TaskStatus.completed,
          activeColor: Colors.green,
          onChanged: (_) async {
            await appState.toggleTaskStatus(budget.id, task.id);
          },
        ),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => BudgetDetailScreen(budgetId: budget.id),
            ),
          );
        },
      ),
    );
  }

  // --- ONGLET 4 : VUE RÉSULTATS & BILAN DES TÂCHES EXÉCUTÉES ---
  Widget _buildExecutionResultsTab(BuildContext context, AppState appState, bool isDark) {
    List<Map<String, dynamic>> completedTaskItems = [];
    double totalAllocatedCompleted = 0.0;
    double totalSpentCompleted = 0.0;

    for (var budget in appState.budgets) {
      for (var task in budget.tasks) {
        if (task.status == TaskStatus.completed) {
          completedTaskItems.add({
            'budget': budget,
            'task': task,
          });
          totalAllocatedCompleted += task.allocatedBudget;
          totalSpentCompleted += (task.actualSpent > 0 ? task.actualSpent : task.allocatedBudget);
        }
      }
    }

    final totalSaved = totalAllocatedCompleted - totalSpentCompleted;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Synthèse des Performances d'Exécution
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppTheme.goldAccent.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.emoji_events, color: AppTheme.goldAccent, size: 24),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Bilan & Performance d\'Exécution',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: isDark ? Colors.white : Colors.black87,
                              ),
                            ),
                            Text(
                              'Synthèse des tâches réalisées et impact obtenu',
                              style: TextStyle(fontSize: 12, color: isDark ? Colors.white70 : Colors.grey.shade600),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 20),
                  Wrap(
                    spacing: 12,
                    runSpacing: 8,
                    alignment: WrapAlignment.spaceBetween,
                    children: [
                      _buildResultKpi('Exécutées', '${completedTaskItems.length} tâches', Colors.green, isDark),
                      _buildResultKpi('Coût Alloué', _currencyFormat.format(totalAllocatedCompleted), Colors.blue.shade700, isDark),
                      _buildResultKpi('Dépense Réelle', _currencyFormat.format(totalSpentCompleted), Colors.orange.shade800, isDark),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: totalSaved >= 0 ? Colors.green.shade50 : Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: totalSaved >= 0 ? Colors.green.shade300 : Colors.red.shade300),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            totalSaved >= 0 ? 'Économie / Optimisation Réalisée :' : 'Dépassement de Budget :',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              color: totalSaved >= 0 ? Colors.green.shade900 : Colors.red.shade900,
                            ),
                          ),
                        ),
                        Text(
                          '${totalSaved >= 0 ? '+' : ''}${_currencyFormat.format(totalSaved)}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: totalSaved >= 0 ? Colors.green.shade800 : Colors.red.shade800,
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

          Text(
            'Tâches Réalisées & Impact (${completedTaskItems.length})',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
          ),
          const SizedBox(height: 12),

          if (completedTaskItems.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(36),
              decoration: BoxDecoration(
                color: isDark ? AppTheme.darkCard : Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: isDark ? Colors.white10 : Colors.grey.shade200),
              ),
              child: Column(
                children: [
                  Icon(Icons.assignment_turned_in_outlined, size: 54, color: Colors.grey.shade400),
                  const SizedBox(height: 12),
                  Text(
                    'Aucune tâche terminée pour le moment.',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Cochez une tâche comme "Terminé" pour afficher son bilan et ses résultats.',
                    style: TextStyle(fontSize: 13, color: isDark ? Colors.white70 : Colors.grey.shade600),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: completedTaskItems.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final budget = completedTaskItems[index]['budget'] as Budget;
                final task = completedTaskItems[index]['task'] as Task;
                return _buildCompletedTaskCard(context, appState, budget, task, isDark);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildResultKpi(String label, String value, Color color, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 11, color: isDark ? Colors.white70 : Colors.grey.shade600),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: color),
        ),
      ],
    );
  }

  Widget _buildCompletedTaskCard(BuildContext context, AppState appState, Budget budget, Task task, bool isDark) {
    final variance = task.allocatedBudget - (task.actualSpent > 0 ? task.actualSpent : task.allocatedBudget);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.green, size: 22),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    task.title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                ),
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
                    } else if (val == 'reopen') {
                      await appState.toggleTaskStatus(budget.id, task.id);
                    }
                  },
                  itemBuilder: (_) => [
                    const PopupMenuItem(value: 'edit', child: Text('Modifier résultat & détails')),
                    const PopupMenuItem(value: 'reopen', child: Text('Rouvrir la tâche')),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: budget.color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    budget.title,
                    style: TextStyle(fontSize: 11, color: budget.color, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.person, size: 14, color: Colors.teal),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    'Responsable : ${task.responsible}',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.teal),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            if (task.receiptNote.isNotEmpty) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(Icons.receipt_long, size: 14, color: Colors.indigo),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      'Justificatif: ${task.receiptNote}',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.indigo),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 12),

            // Encadré Résultat & Impact Obtenu 🏆
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? Colors.amber.shade900.withValues(alpha: 0.2) : Colors.amber.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.amber.shade400.withValues(alpha: 0.5)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.emoji_events, size: 16, color: Colors.amber),
                      SizedBox(width: 6),
                      Text(
                        'Résultat / Impact Obtenu :',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.amber),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    task.executionResult.isNotEmpty
                        ? task.executionResult
                        : 'Aucun résultat explicite renseigné (cliquez sur les 3 points pour ajouter des notes d\'impact).',
                    style: TextStyle(
                      fontSize: 12,
                      fontStyle: task.executionResult.isEmpty ? FontStyle.italic : FontStyle.normal,
                      color: isDark ? Colors.white70 : Colors.black87,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            Wrap(
              spacing: 12,
              runSpacing: 6,
              alignment: WrapAlignment.spaceBetween,
              children: [
                Text(
                  'Prévu: ${_currencyFormat.format(task.allocatedBudget)}',
                  style: TextStyle(fontSize: 12, color: isDark ? Colors.white70 : Colors.grey.shade700),
                ),
                Text(
                  'Réel: ${_currencyFormat.format(task.actualSpent > 0 ? task.actualSpent : task.allocatedBudget)}',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.orange.shade800),
                ),
                Text(
                  variance >= 0 ? 'Économie: +${_currencyFormat.format(variance)}' : 'Surcoût: ${_currencyFormat.format(variance)}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: variance >= 0 ? Colors.green.shade700 : Colors.red,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // --- ONGLET 5 : VUE PROGRAMMES DE MISE À JOUR MOBILE ---
  Widget _buildAppReleasesTab(BuildContext context, AppState appState, bool isDark) {
    final releases = appState.appReleases;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Mises à Jour & Releases (${releases.length})',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: () async {
                  final newRelease = await showDialog<AppRelease>(
                    context: context,
                    builder: (_) => AddReleaseDialog(availableBudgets: appState.budgets),
                  );
                  if (newRelease != null) {
                    await appState.addAppRelease(newRelease);
                  }
                },
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Nouvelle Release'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryEmerald,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          if (releases.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(36),
              decoration: BoxDecoration(
                color: isDark ? AppTheme.darkCard : Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: isDark ? Colors.white10 : Colors.grey.shade200),
              ),
              child: Column(
                children: [
                  Icon(Icons.system_update, size: 54, color: Colors.grey.shade400),
                  const SizedBox(height: 12),
                  Text(
                    'Aucune version de l\'application planifiée.',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Cliquez sur "Nouvelle Release" pour programmer une version mobile.',
                    style: TextStyle(fontSize: 13, color: isDark ? Colors.white70 : Colors.grey.shade600),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: releases.length,
              separatorBuilder: (_, __) => const SizedBox(height: 14),
              itemBuilder: (context, index) {
                final release = releases[index];
                final linkedBudget = appState.budgets.firstWhere(
                  (b) => b.id == release.budgetId,
                  orElse: () => Budget(id: '', title: '', allocatedBudget: 0),
                );
                return _buildReleaseCard(context, appState, release, linkedBudget, isDark);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildReleaseCard(
    BuildContext context,
    AppState appState,
    AppRelease release,
    Budget linkedBudget,
    bool isDark,
  ) {
    Color statusColor;
    switch (release.status) {
      case AppReleaseStatus.planned:
        statusColor = Colors.orange;
        break;
      case AppReleaseStatus.inDevelopment:
        statusColor = Colors.blue;
        break;
      case AppReleaseStatus.inTesting:
        statusColor = Colors.purple;
        break;
      case AppReleaseStatus.deployed:
        statusColor = Colors.green;
        break;
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryEmerald.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppTheme.primaryEmerald.withValues(alpha: 0.4)),
                  ),
                  child: Text(
                    release.version,
                    style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryEmerald, fontSize: 14),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        release.title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        release.type.label,
                        style: TextStyle(fontSize: 12, color: isDark ? Colors.white70 : Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  icon: Icon(Icons.more_vert, size: 20, color: isDark ? Colors.white70 : Colors.grey.shade600),
                  onSelected: (val) async {
                    if (val == 'edit') {
                      final updatedRelease = await showDialog<AppRelease>(
                        context: context,
                        builder: (_) => AddReleaseDialog(
                          releaseToEdit: release,
                          availableBudgets: appState.budgets,
                        ),
                      );
                      if (updatedRelease != null) {
                        await appState.updateAppRelease(updatedRelease);
                      }
                    } else if (val == 'delete') {
                      await appState.deleteAppRelease(release.id);
                    }
                  },
                  itemBuilder: (_) => [
                    const PopupMenuItem(value: 'edit', child: Text('Modifier')),
                    const PopupMenuItem(value: 'delete', child: Text('Supprimer', style: TextStyle(color: Colors.red))),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Statut Badge & Date Target
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: statusColor.withValues(alpha: 0.4)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        release.status == AppReleaseStatus.deployed
                            ? Icons.check_circle
                            : release.status == AppReleaseStatus.inTesting
                                ? Icons.bug_report
                                : Icons.schedule,
                        size: 14,
                        color: statusColor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        release.status.label,
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: statusColor),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                const Icon(Icons.calendar_today, size: 14, color: Colors.teal),
                const SizedBox(width: 4),
                Text(
                  'Publication: ${_dateFormat.format(release.targetDate)}',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: isDark ? Colors.white70 : Colors.grey.shade800),
                ),
              ],
            ),

            if (release.description.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white10 : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Notes de version / Changelog :',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.teal),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      release.description,
                      style: TextStyle(fontSize: 12, color: isDark ? Colors.white70 : Colors.grey.shade800, height: 1.3),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 12),
            Row(
              children: [
                if (linkedBudget.id.isNotEmpty) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: linkedBudget.color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(linkedBudget.icon, size: 12, color: linkedBudget.color),
                        const SizedBox(width: 4),
                        Text(
                          linkedBudget.title,
                          style: TextStyle(fontSize: 11, color: linkedBudget.color, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                const Icon(Icons.person, size: 14, color: Colors.teal),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    'Lead: ${release.responsible}',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.teal),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showQuickActionMenu(BuildContext context, AppState appState) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
              ),
              const SizedBox(height: 16),
              const Text('Actions Rapides Pro', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              const SizedBox(height: 16),
              ListTile(
                leading: const CircleAvatar(backgroundColor: Colors.teal, child: Icon(Icons.add_chart, color: Colors.white)),
                title: const Text('Nouveau Budget Principal', style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: const Text('Créer une nouvelle catégorie budgétaire (FCFA)'),
                onTap: () async {
                  Navigator.of(ctx).pop();
                  final newBudget = await showDialog<Budget>(
                    context: context,
                    builder: (_) => const AddBudgetDialog(),
                  );
                  if (newBudget != null) {
                    await appState.addBudget(newBudget);
                  }
                },
              ),
              if (appState.budgets.isNotEmpty) ...[
                const Divider(),
                ListTile(
                  leading: const CircleAvatar(backgroundColor: Colors.amber, child: Icon(Icons.add_task, color: Colors.black)),
                  title: const Text('Nouvelle Tâche', style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: const Text('Ajouter une tâche et choisir son budget principal'),
                  onTap: () async {
                    Navigator.of(ctx).pop();
                    final result = await showDialog<AddTaskResult>(
                      context: context,
                      builder: (_) => AddTaskDialog(availableBudgets: appState.budgets),
                    );
                    if (result != null) {
                      await appState.addTask(result.budgetId, result.task);
                    }
                  },
                ),
              ],
              const Divider(),
              ListTile(
                leading: const CircleAvatar(backgroundColor: Colors.purple, child: Icon(Icons.system_update_alt, color: Colors.white)),
                title: const Text('Nouvelle Release / Version Mobile', style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: const Text('Programmer une version mobile et son changelog'),
                onTap: () async {
                  Navigator.of(ctx).pop();
                  final newRelease = await showDialog<AppRelease>(
                    context: context,
                    builder: (_) => AddReleaseDialog(availableBudgets: appState.budgets),
                  );
                  if (newRelease != null) {
                    await appState.addAppRelease(newRelease);
                  }
                },
              ),
              const Divider(),
              ListTile(
                leading: const CircleAvatar(backgroundColor: Colors.red, child: Icon(Icons.picture_as_pdf, color: Colors.white)),
                title: const Text('Exporter Rapport Financier (PDF)', style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: const Text('Générer et télécharger le bilan complet en PDF'),
                onTap: () async {
                  Navigator.of(ctx).pop();
                  await PdfExportService.exportExecutiveReport(
                    appTitle: appState.currentApp.name,
                    organizationName: appState.organizationName,
                    budgets: appState.budgets,
                    appReleases: appState.appReleases,
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
