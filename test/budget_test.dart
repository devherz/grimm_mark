import 'package:flutter_test/flutter_test.dart';
import 'package:grimm_mark/models/app_release.dart';
import 'package:grimm_mark/models/budget.dart';
import 'package:grimm_mark/models/task.dart';
import 'package:grimm_mark/providers/app_state.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Tests Budgets, Tâches & Sécurité - Grimm Mark', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('Calcul correct des totaux de dépenses et budget restant', () {
      final task1 = Task(
        id: 't1',
        title: 'Campagne Pub Facebook',
        allocatedBudget: 500000.0,
        actualSpent: 350000.0,
        startDate: DateTime.now(),
        dueDate: DateTime.now().add(const Duration(days: 7)),
        responsible: 'Marc - Marketeur',
        status: TaskStatus.inProgress,
      );

      final task2 = Task(
        id: 't2',
        title: 'Design Logo',
        allocatedBudget: 300000.0,
        actualSpent: 300000.0,
        startDate: DateTime.now(),
        dueDate: DateTime.now(),
        responsible: 'Sophie - UI/UX',
        status: TaskStatus.completed,
      );

      final budget = Budget(
        id: 'b1',
        title: 'Marketing',
        allocatedBudget: 1000000.0,
        tasks: [task1, task2],
      );

      expect(budget.allocatedBudget, equals(1000000.0));
      expect(budget.totalSpent, equals(650000.0));
      expect(budget.remainingBudget, equals(350000.0));
      expect(budget.completedTasksCount, equals(1));
      expect(budget.completionPercentage, equals(0.5));
    });

    test('Sérialisation et désérialisation JSON d\'une tâche avec responsable libre', () {
      final task = Task(
        id: 't99',
        title: 'Maintenance Serveur GCP',
        description: 'Mise à niveau base de données',
        allocatedBudget: 450000.0,
        actualSpent: 200000.0,
        startDate: DateTime(2026, 9, 1),
        dueDate: DateTime(2026, 9, 15),
        responsible: 'Jean Dupont - Lead DevOps',
        status: TaskStatus.inProgress,
      );

      final json = task.toJson();
      expect(json['responsible'], equals('Jean Dupont - Lead DevOps'));
      expect(json['allocatedBudget'], equals(450000.0));
      expect(json['status'], equals('in_progress'));

      final restored = Task.fromJson(json);
      expect(restored.id, equals('t99'));
      expect(restored.responsible, equals('Jean Dupont - Lead DevOps'));
      expect(restored.status, equals(TaskStatus.inProgress));
    });

    test('Sérialisation et désérialisation JSON d\'une Release / Version Mobile', () {
      final release = AppRelease(
        id: 'rel_test',
        version: 'v1.2.0',
        title: 'Mise à jour majeure - Module Finance',
        description: '- Ajout des rapports PDF\n- Notifications Push',
        type: AppReleaseType.major,
        status: AppReleaseStatus.inTesting,
        targetDate: DateTime(2026, 10, 15),
        responsible: 'Jean - Lead Dev',
        budgetId: 'b1',
      );

      final json = release.toJson();
      expect(json['version'], equals('v1.2.0'));
      expect(json['status'], equals('in_testing'));

      final restored = AppRelease.fromJson(json);
      expect(restored.id, equals('rel_test'));
      expect(restored.version, equals('v1.2.0'));
      expect(restored.type, equals(AppReleaseType.major));
      expect(restored.status, equals(AppReleaseStatus.inTesting));
    });

    test('Activation, vérification et désactivation du mot de passe de protection', () async {
      final appState = AppState();
      expect(appState.isAppLockEnabled, isFalse);
      expect(appState.isUnlocked, isTrue);

      await appState.enableAppLock('2026PIN');
      expect(appState.isAppLockEnabled, isTrue);

      appState.lockApp();
      expect(appState.isUnlocked, isFalse);

      final wrongResult = appState.verifyPassword('0000');
      expect(wrongResult, isFalse);
      expect(appState.isUnlocked, isFalse);

      final correctResult = appState.verifyPassword('2026PIN');
      expect(correctResult, isTrue);
      expect(appState.isUnlocked, isTrue);

      await appState.disableAppLock();
      expect(appState.isAppLockEnabled, isFalse);
      expect(appState.isUnlocked, isTrue);
    });
  });
}
