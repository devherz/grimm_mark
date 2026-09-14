import 'package:flutter/material.dart';
import '../providers/app_state.dart';
import '../theme/app_theme.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = AppStateProvider.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Paramètres & Configuration'),
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Carte de Profil & Organisation Chic
            _buildProfileCard(context, appState, isDark),
            const SizedBox(height: 20),

            // Section Sécurité & Protection
            _buildSectionHeader(context, 'Sécurité & Protection', Icons.security_outlined),
            const SizedBox(height: 10),
            Card(
              child: Column(
                children: [
                  SwitchListTile(
                    secondary: CircleAvatar(
                      backgroundColor: Colors.teal.shade50,
                      child: const Icon(Icons.lock_outline, color: Colors.teal),
                    ),
                    title: const Text(
                      'Protection par mot de passe',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      appState.isAppLockEnabled
                          ? 'Application verrouillée au démarrage'
                          : 'Protéger l\'accès à l\'application avec un code PIN',
                    ),
                    value: appState.isAppLockEnabled,
                    onChanged: (enabled) {
                      if (enabled) {
                        _showSetPasswordDialog(context, appState);
                      } else {
                        _showDisablePasswordDialog(context, appState);
                      }
                    },
                  ),
                  if (appState.isAppLockEnabled) ...[
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.key, color: Colors.teal),
                      title: const Text('Modifier le mot de passe'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => _showSetPasswordDialog(context, appState, isChanging: true),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Section Apparence & Thème
            _buildSectionHeader(context, 'Apparence & Thème', Icons.palette_outlined),
            const SizedBox(height: 10),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Mode d\'affichage',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Choisissez l\'apparence visuelle de l\'interface Grimm Mark',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    ),
                    const SizedBox(height: 14),
                    SegmentedButton<ThemeMode>(
                      segments: const [
                        ButtonSegment(
                          value: ThemeMode.light,
                          label: Text('Clair'),
                          icon: Icon(Icons.light_mode_outlined),
                        ),
                        ButtonSegment(
                          value: ThemeMode.dark,
                          label: Text('Sombre'),
                          icon: Icon(Icons.dark_mode_outlined),
                        ),
                        ButtonSegment(
                          value: ThemeMode.system,
                          label: Text('Système'),
                          icon: Icon(Icons.settings_suggest_outlined),
                        ),
                      ],
                      selected: {appState.themeMode},
                      onSelectionChanged: (Set<ThemeMode> newSelection) {
                        appState.setThemeMode(newSelection.first);
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Section Configuration Financière
            _buildSectionHeader(context, 'Configuration Financière', Icons.account_balance_outlined),
            const SizedBox(height: 10),
            Card(
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppTheme.goldAccent.withValues(alpha: 0.2),
                  child: const Icon(Icons.monetization_on, color: AppTheme.goldAccent),
                ),
                title: const Text(
                  'Devise Principale',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: const Text('Devise unique utilisée pour tous les budgets et tâches'),
                trailing: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.teal.shade50,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.teal.shade300),
                  ),
                  child: const Text(
                    'FCFA',
                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.teal, fontSize: 13),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Section Notifications & Alertes
            _buildSectionHeader(context, 'Notifications & Alertes', Icons.notifications_outlined),
            const SizedBox(height: 10),
            Card(
              child: SwitchListTile(
                secondary: CircleAvatar(
                  backgroundColor: Colors.blue.shade50,
                  child: Icon(Icons.notifications_active, color: Colors.blue.shade700),
                ),
                title: const Text(
                  'Rappels d\'échéance',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: const Text('Recevoir des alertes pour les tâches arrivant à terme'),
                value: appState.notificationsEnabled,
                onChanged: (val) {
                  appState.setNotificationsEnabled(val);
                },
              ),
            ),
            const SizedBox(height: 20),

            // Section Données & Stockage
            _buildSectionHeader(context, 'Données & Stockage', Icons.storage_outlined),
            const SizedBox(height: 10),
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.green.shade50,
                      child: Icon(Icons.check_circle_outline, color: Colors.green.shade700),
                    ),
                    title: const Text(
                      'Persistance Locale',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: const Text('Sauvegarde automatique sécurisée via SharedPreferences'),
                    trailing: const Chip(
                      label: Text('Actif', style: TextStyle(fontSize: 11, color: Colors.green)),
                      backgroundColor: Colors.greenAccent,
                      padding: EdgeInsets.zero,
                    ),
                  ),
                  ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.red.shade50,
                      child: Icon(Icons.delete_forever_outlined, color: Colors.red.shade700),
                    ),
                    title: const Text(
                      'Vider toutes les données (0 FCFA)',
                      style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
                    ),
                    subtitle: const Text('Effacer tous les budgets, tâches et mises à jour pour repartir de zéro'),
                    onTap: () => _confirmClearDataDialog(context, appState),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Section À Propos
            _buildSectionHeader(context, 'À Propos de Grimm Mark', Icons.info_outline),
            const SizedBox(height: 10),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.teal.shade700,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(Icons.markunread_mailbox, color: Colors.white, size: 28),
                        ),
                        const SizedBox(width: 14),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Grimm Mark Multi-App',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                              Text(
                                'Version 1.0.0 (Sécurisé Pro Edition)',
                                style: TextStyle(fontSize: 12, color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'Grimm Mark est la plateforme centrale de gestion financière et marketing conçue pour piloter la croissance des 3 applications : My Rabbitry, My Poultry et My Piggery.',
                      style: TextStyle(fontSize: 13, height: 1.4),
                    ),
                    const Divider(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Support Technologique', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                        const Text('GRIMM', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.teal),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ],
    );
  }

  Widget _buildProfileCard(BuildContext context, AppState appState, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: AppTheme.headerGradientDecoration,
      child: Column(
        children: [
          Row(
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppTheme.goldAccent, width: 2),
                ),
                child: const CircleAvatar(
                  radius: 28,
                  backgroundColor: Colors.white24,
                  child: Icon(Icons.person, size: 32, color: Colors.white),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      appState.organizationName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Text(
                          'Administrateur Marketing',
                          style: TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                        if (appState.isAppLockEnabled) ...[
                          const SizedBox(width: 6),
                          const Icon(Icons.lock, size: 12, color: AppTheme.goldAccent),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.edit, color: Colors.white),
                tooltip: 'Modifier l\'organisation',
                onPressed: () => _editOrgNameDialog(context, appState),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showSetPasswordDialog(BuildContext context, AppState appState, {bool isChanging = false}) {
    final passwordController = TextEditingController();
    final confirmController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isChanging ? 'Modifier le Mot de Passe' : 'Créer un Mot de Passe'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Mot de passe / PIN *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.key),
                ),
                validator: (val) {
                  if (val == null || val.trim().length < 4) {
                    return 'Saisissez au moins 4 caractères';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: confirmController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Confirmer le mot de passe *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.check_circle_outline),
                ),
                validator: (val) {
                  if (val != passwordController.text) {
                    return 'Les mots de passe ne correspondent pas';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                await appState.enableAppLock(passwordController.text.trim());
                if (context.mounted) {
                  Navigator.of(ctx).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Mot de passe de protection activé !')),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, foregroundColor: Colors.white),
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    );
  }

  void _showDisablePasswordDialog(BuildContext context, AppState appState) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Désactiver la Protection'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Veuillez saisir votre mot de passe actuel pour désactiver la protection :'),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Mot de passe actuel',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (appState.verifyPassword(controller.text.trim())) {
                await appState.disableAppLock();
                if (context.mounted) {
                  Navigator.of(ctx).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Protection par mot de passe désactivée.')),
                  );
                }
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Mot de passe incorrect.')),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('Désactiver'),
          ),
        ],
      ),
    );
  }

  void _editOrgNameDialog(BuildContext context, AppState appState) {
    final controller = TextEditingController(text: appState.organizationName);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Nom de l\'Organisation / Élevage'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Nom',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (controller.text.trim().isNotEmpty) {
                await appState.setOrganizationName(controller.text.trim());
              }
              if (context.mounted) Navigator.of(ctx).pop();
            },
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    );
  }

  void _confirmClearDataDialog(BuildContext context, AppState appState) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Vider toutes les données'),
        content: const Text('Voulez-vous supprimer tous les budgets, tâches et mises à jour pour repartir de zéro à 0 FCFA ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () async {
              Navigator.of(ctx).pop();
              await appState.clearAllData();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Toutes les données ont été réinitialisées à zéro (0 FCFA) !')),
                );
              }
            },
            child: const Text('Supprimer Tout'),
          ),
        ],
      ),
    );
  }
}
