import 'package:flutter/material.dart';

class AppProject {
  final String id;
  final String name;
  final IconData icon;
  final Color color;
  final bool isFunctional;
  final String description;

  const AppProject({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
    required this.isFunctional,
    required this.description,
  });

  static List<AppProject> defaultApps = [
    const AppProject(
      id: 'my_rabbitry',
      name: 'My Rabbitry',
      icon: Icons.pets,
      color: Colors.teal,
      isFunctional: true,
      description: 'Gestion du marketing et des finances pour My Rabbitry',
    ),
    const AppProject(
      id: 'my_poultry',
      name: 'My Poultry',
      icon: Icons.egg_alt,
      color: Colors.amber,
      isFunctional: false,
      description: 'Module marketing et finances pour My Poultry (Bientôt disponible)',
    ),
    const AppProject(
      id: 'my_piggery',
      name: 'My Piggery',
      icon: Icons.agriculture,
      color: Colors.deepOrange,
      isFunctional: false,
      description: 'Module marketing et finances pour My Piggery (Bientôt disponible)',
    ),
  ];
}
