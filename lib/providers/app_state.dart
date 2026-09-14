import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/app_project.dart';
import '../models/app_release.dart';
import '../models/budget.dart';
import '../models/task.dart';

class AppStateProvider extends InheritedNotifier<AppState> {
  const AppStateProvider({
    super.key,
    required AppState super.notifier,
    required super.child,
  });

  static AppState of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<AppStateProvider>()!.notifier!;
  }
}

class AppState extends ChangeNotifier {
  static const String _storageKey = 'grimm_mark_rabbitry_budgets';
  static const String _releasesKey = 'grimm_mark_app_releases';
  static const String _themeKey = 'grimm_mark_theme_mode';
  static const String _orgNameKey = 'grimm_mark_org_name';
  static const String _notificationsKey = 'grimm_mark_notifications_enabled';
  static const String _appLockEnabledKey = 'grimm_mark_app_lock_enabled';
  static const String _appPasswordKey = 'grimm_mark_app_password';

  String _currentAppId = 'my_rabbitry';
  List<Budget> _budgets = [];
  List<AppRelease> _appReleases = [];
  bool _isLoading = true;
  ThemeMode _themeMode = ThemeMode.system;
  String _organizationName = 'Élevage Grimm Mark';
  bool _notificationsEnabled = true;

  // Sécurité & Verrouillage
  bool _isAppLockEnabled = false;
  String _appPassword = '';
  bool _isUnlocked = false;

  AppState() {
    _loadFromPrefs();
  }

  String get currentAppId => _currentAppId;
  List<Budget> get budgets => _budgets;
  List<AppRelease> get appReleases => _appReleases;
  bool get isLoading => _isLoading;
  ThemeMode get themeMode => _themeMode;
  String get organizationName => _organizationName;
  bool get notificationsEnabled => _notificationsEnabled;

  bool get isAppLockEnabled => _isAppLockEnabled;
  bool get isUnlocked => !_isAppLockEnabled || _isUnlocked;

  AppProject get currentApp {
    return AppProject.defaultApps.firstWhere(
      (app) => app.id == _currentAppId,
      orElse: () => AppProject.defaultApps.first,
    );
  }

  void selectApp(String appId) {
    if (_currentAppId != appId) {
      _currentAppId = appId;
      notifyListeners();
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_themeKey, mode.index);
  }

  Future<void> setOrganizationName(String name) async {
    _organizationName = name;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_orgNameKey, name);
  }

  Future<void> setNotificationsEnabled(bool enabled) async {
    _notificationsEnabled = enabled;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_notificationsKey, enabled);
  }

  // --- SÉCURITÉ & MOT DE PASSE ---
  Future<void> enableAppLock(String password) async {
    _isAppLockEnabled = true;
    _appPassword = password;
    _isUnlocked = true; // Unlocked for current session
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_appLockEnabledKey, true);
    await prefs.setString(_appPasswordKey, password);
  }

  Future<void> disableAppLock() async {
    _isAppLockEnabled = false;
    _appPassword = '';
    _isUnlocked = true;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_appLockEnabledKey, false);
    await prefs.remove(_appPasswordKey);
  }

  bool verifyPassword(String input) {
    if (_appPassword == input) {
      _isUnlocked = true;
      notifyListeners();
      return true;
    }
    return false;
  }

  void lockApp() {
    if (_isAppLockEnabled) {
      _isUnlocked = false;
      notifyListeners();
    }
  }

  // --- COMPUTES DE SYNTHÈSE FINANCIÈRE ---
  double get totalAllocatedBudget {
    return _budgets.fold(0.0, (sum, b) => sum + b.allocatedBudget);
  }

  double get totalSpent {
    return _budgets.fold(0.0, (sum, b) => sum + b.totalSpent);
  }

  double get totalRemainingBudget {
    return totalAllocatedBudget - totalSpent;
  }

  double get overallProgress {
    if (totalAllocatedBudget == 0) return 0.0;
    final progress = totalSpent / totalAllocatedBudget;
    return progress.clamp(0.0, 1.0);
  }

  int get totalTasksCount {
    return _budgets.fold(0, (sum, b) => sum + b.tasks.length);
  }

  int get completedTasksCount {
    return _budgets.fold(0, (sum, b) => sum + b.completedTasksCount);
  }

  // --- GESTION DES BUDGETS ---
  Future<void> addBudget(Budget budget) async {
    _budgets.add(budget);
    notifyListeners();
    await _saveToPrefs();
  }

  Future<void> updateBudget(Budget updatedBudget) async {
    final index = _budgets.indexWhere((b) => b.id == updatedBudget.id);
    if (index != -1) {
      _budgets[index] = updatedBudget;
      notifyListeners();
      await _saveToPrefs();
    }
  }

  Future<void> deleteBudget(String budgetId) async {
    _budgets.removeWhere((b) => b.id == budgetId);
    notifyListeners();
    await _saveToPrefs();
  }

  // --- GESTION DES TÂCHES ---
  Future<void> addTask(String budgetId, Task task) async {
    final budgetIndex = _budgets.indexWhere((b) => b.id == budgetId);
    if (budgetIndex != -1) {
      final updatedTasks = List<Task>.from(_budgets[budgetIndex].tasks)..add(task);
      _budgets[budgetIndex] = _budgets[budgetIndex].copyWith(tasks: updatedTasks);
      notifyListeners();
      await _saveToPrefs();
    }
  }

  Future<void> updateTask(String budgetId, Task updatedTask) async {
    final budgetIndex = _budgets.indexWhere((b) => b.id == budgetId);
    if (budgetIndex != -1) {
      final tasks = List<Task>.from(_budgets[budgetIndex].tasks);
      final taskIndex = tasks.indexWhere((t) => t.id == updatedTask.id);
      if (taskIndex != -1) {
        tasks[taskIndex] = updatedTask;
        _budgets[budgetIndex] = _budgets[budgetIndex].copyWith(tasks: tasks);
        notifyListeners();
        await _saveToPrefs();
      }
    }
  }

  Future<void> deleteTask(String budgetId, String taskId) async {
    final budgetIndex = _budgets.indexWhere((b) => b.id == budgetId);
    if (budgetIndex != -1) {
      final updatedTasks = List<Task>.from(_budgets[budgetIndex].tasks)..removeWhere((t) => t.id == taskId);
      _budgets[budgetIndex] = _budgets[budgetIndex].copyWith(tasks: updatedTasks);
      notifyListeners();
      await _saveToPrefs();
    }
  }

  Future<void> toggleTaskStatus(String budgetId, String taskId) async {
    final budgetIndex = _budgets.indexWhere((b) => b.id == budgetId);
    if (budgetIndex != -1) {
      final tasks = List<Task>.from(_budgets[budgetIndex].tasks);
      final taskIndex = tasks.indexWhere((t) => t.id == taskId);
      if (taskIndex != -1) {
        final currentTask = tasks[taskIndex];
        final nextStatus = currentTask.status == TaskStatus.completed
            ? TaskStatus.todo
            : TaskStatus.completed;
        tasks[taskIndex] = currentTask.copyWith(status: nextStatus);
        _budgets[budgetIndex] = _budgets[budgetIndex].copyWith(tasks: tasks);
        notifyListeners();
        await _saveToPrefs();
      }
    }
  }

  // --- GESTION DES RELEASES / VERSIONS MOBILE ---
  Future<void> addAppRelease(AppRelease release) async {
    _appReleases.add(release);
    notifyListeners();
    await _saveToPrefs();
  }

  Future<void> updateAppRelease(AppRelease updatedRelease) async {
    final index = _appReleases.indexWhere((r) => r.id == updatedRelease.id);
    if (index != -1) {
      _appReleases[index] = updatedRelease;
      notifyListeners();
      await _saveToPrefs();
    }
  }

  Future<void> deleteAppRelease(String releaseId) async {
    _appReleases.removeWhere((r) => r.id == releaseId);
    notifyListeners();
    await _saveToPrefs();
  }

  // --- PERSISTANCE SHAREDPREFERENCES ---
  Future<void> _loadFromPrefs() async {
    _isLoading = true;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? jsonData = prefs.getString(_storageKey);
      final String? releasesData = prefs.getString(_releasesKey);
      final int? themeIndex = prefs.getInt(_themeKey);
      final String? orgName = prefs.getString(_orgNameKey);
      final bool? notifs = prefs.getBool(_notificationsKey);
      final bool? lockEnabled = prefs.getBool(_appLockEnabledKey);
      final String? savedPassword = prefs.getString(_appPasswordKey);

      if (themeIndex != null && themeIndex < ThemeMode.values.length) {
        _themeMode = ThemeMode.values[themeIndex];
      }
      if (orgName != null && orgName.isNotEmpty) {
        _organizationName = orgName;
      }
      if (notifs != null) {
        _notificationsEnabled = notifs;
      }
      if (lockEnabled != null) {
        _isAppLockEnabled = lockEnabled;
      }
      if (savedPassword != null) {
        _appPassword = savedPassword;
      }
      _isUnlocked = !_isAppLockEnabled;

      if (jsonData != null && jsonData.isNotEmpty) {
        final List<dynamic> decoded = jsonDecode(jsonData);
        _budgets = decoded.map((b) => Budget.fromJson(b as Map<String, dynamic>)).toList();
      } else {
        _budgets = [];
      }

      if (releasesData != null && releasesData.isNotEmpty) {
        final List<dynamic> decodedReleases = jsonDecode(releasesData);
        _appReleases = decodedReleases.map((r) => AppRelease.fromJson(r as Map<String, dynamic>)).toList();
      } else {
        _appReleases = [];
      }

      await _saveToPrefs();
    } catch (e) {
      debugPrint('Erreur lors du chargement des préférences: $e');
      _budgets = [];
      _appReleases = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _saveToPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String encodedBudgets = jsonEncode(_budgets.map((b) => b.toJson()).toList());
      final String encodedReleases = jsonEncode(_appReleases.map((r) => r.toJson()).toList());

      await prefs.setString(_storageKey, encodedBudgets);
      await prefs.setString(_releasesKey, encodedReleases);
    } catch (e) {
      debugPrint('Erreur lors de la sauvegarde: $e');
    }
  }

  Future<void> clearAllData() async {
    _budgets = [];
    _appReleases = [];
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_storageKey);
      await prefs.remove(_releasesKey);
    } catch (e) {
      debugPrint('Erreur lors de la suppression des données: $e');
    }
  }
}
