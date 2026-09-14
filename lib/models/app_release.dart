enum AppReleaseType {
  major,
  feature,
  patch,
  maintenance,
}

extension AppReleaseTypeExtension on AppReleaseType {
  String get label {
    switch (this) {
      case AppReleaseType.major:
        return 'Mise à jour majeure';
      case AppReleaseType.feature:
        return 'Nouvelle fonctionnalité';
      case AppReleaseType.patch:
        return 'Correctif (Bugfix)';
      case AppReleaseType.maintenance:
        return 'Maintenance infra';
    }
  }

  String get code {
    switch (this) {
      case AppReleaseType.major:
        return 'major';
      case AppReleaseType.feature:
        return 'feature';
      case AppReleaseType.patch:
        return 'patch';
      case AppReleaseType.maintenance:
        return 'maintenance';
    }
  }

  static AppReleaseType fromCode(String code) {
    switch (code) {
      case 'major':
        return AppReleaseType.major;
      case 'patch':
        return AppReleaseType.patch;
      case 'maintenance':
        return AppReleaseType.maintenance;
      case 'feature':
      default:
        return AppReleaseType.feature;
    }
  }
}

enum AppReleaseStatus {
  planned,
  inDevelopment,
  inTesting,
  deployed,
}

extension AppReleaseStatusExtension on AppReleaseStatus {
  String get label {
    switch (this) {
      case AppReleaseStatus.planned:
        return 'Planifié';
      case AppReleaseStatus.inDevelopment:
        return 'En développement';
      case AppReleaseStatus.inTesting:
        return 'En test (Beta)';
      case AppReleaseStatus.deployed:
        return 'Déployé en ligne';
    }
  }

  String get code {
    switch (this) {
      case AppReleaseStatus.planned:
        return 'planned';
      case AppReleaseStatus.inDevelopment:
        return 'in_development';
      case AppReleaseStatus.inTesting:
        return 'in_testing';
      case AppReleaseStatus.deployed:
        return 'deployed';
    }
  }

  static AppReleaseStatus fromCode(String code) {
    switch (code) {
      case 'in_development':
        return AppReleaseStatus.inDevelopment;
      case 'in_testing':
        return AppReleaseStatus.inTesting;
      case 'deployed':
        return AppReleaseStatus.deployed;
      case 'planned':
      default:
        return AppReleaseStatus.planned;
    }
  }
}

class AppRelease {
  final String id;
  final String version; // ex: v1.1.0
  final String title;
  final String description; // Changelog / Notes de version
  final AppReleaseType type;
  final AppReleaseStatus status;
  final DateTime targetDate;
  final String responsible;
  final String budgetId; // Budget lié (ex: Maintenance Serveur)

  AppRelease({
    required this.id,
    required this.version,
    required this.title,
    this.description = '',
    required this.type,
    required this.status,
    required this.targetDate,
    required this.responsible,
    this.budgetId = '',
  });

  AppRelease copyWith({
    String? id,
    String? version,
    String? title,
    String? description,
    AppReleaseType? type,
    AppReleaseStatus? status,
    DateTime? targetDate,
    String? responsible,
    String? budgetId,
  }) {
    return AppRelease(
      id: id ?? this.id,
      version: version ?? this.version,
      title: title ?? this.title,
      description: description ?? this.description,
      type: type ?? this.type,
      status: status ?? this.status,
      targetDate: targetDate ?? this.targetDate,
      responsible: responsible ?? this.responsible,
      budgetId: budgetId ?? this.budgetId,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'version': version,
      'title': title,
      'description': description,
      'type': type.code,
      'status': status.code,
      'targetDate': targetDate.toIso8601String(),
      'responsible': responsible,
      'budgetId': budgetId,
    };
  }

  factory AppRelease.fromJson(Map<String, dynamic> json) {
    return AppRelease(
      id: json['id'] as String,
      version: json['version'] as String,
      title: json['title'] as String,
      description: json['description'] as String? ?? '',
      type: AppReleaseTypeExtension.fromCode(json['type'] as String? ?? 'feature'),
      status: AppReleaseStatusExtension.fromCode(json['status'] as String? ?? 'planned'),
      targetDate: DateTime.parse(json['targetDate'] as String),
      responsible: json['responsible'] as String? ?? 'Non assigné',
      budgetId: json['budgetId'] as String? ?? '',
    );
  }
}
