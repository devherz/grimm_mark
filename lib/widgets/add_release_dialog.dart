import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/app_release.dart';
import '../models/budget.dart';

class AddReleaseDialog extends StatefulWidget {
  final AppRelease? releaseToEdit;
  final List<Budget> availableBudgets;

  const AddReleaseDialog({
    super.key,
    this.releaseToEdit,
    required this.availableBudgets,
  });

  @override
  State<AddReleaseDialog> createState() => _AddReleaseDialogState();
}

class _AddReleaseDialogState extends State<AddReleaseDialog> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _versionController;
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _responsibleController;

  late AppReleaseType _type;
  late AppReleaseStatus _status;
  late DateTime _targetDate;
  late String _selectedBudgetId;

  final DateFormat _dateFormat = DateFormat('dd/MM/yyyy');

  @override
  void initState() {
    super.initState();
    final r = widget.releaseToEdit;

    _versionController = TextEditingController(text: r?.version ?? 'v1.1.0');
    _titleController = TextEditingController(text: r?.title ?? '');
    _descriptionController = TextEditingController(text: r?.description ?? '');
    _responsibleController = TextEditingController(text: r?.responsible ?? '');

    _type = r?.type ?? AppReleaseType.feature;
    _status = r?.status ?? AppReleaseStatus.planned;
    _targetDate = r?.targetDate ?? DateTime.now().add(const Duration(days: 14));

    if (r != null && widget.availableBudgets.any((b) => b.id == r.budgetId)) {
      _selectedBudgetId = r.budgetId;
    } else if (widget.availableBudgets.isNotEmpty) {
      _selectedBudgetId = widget.availableBudgets.first.id;
    } else {
      _selectedBudgetId = '';
    }
  }

  @override
  void dispose() {
    _versionController.dispose();
    _titleController.dispose();
    _descriptionController.dispose();
    _responsibleController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _targetDate,
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
      setState(() => _targetDate = picked);
    }
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      final newRelease = AppRelease(
        id: widget.releaseToEdit?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        version: _versionController.text.trim(),
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        type: _type,
        status: _status,
        targetDate: _targetDate,
        responsible: _responsibleController.text.trim().isEmpty ? 'Non assigné' : _responsibleController.text.trim(),
        budgetId: _selectedBudgetId,
      );

      Navigator.of(context).pop(newRelease);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.releaseToEdit != null;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(
        isEditing ? 'Modifier la Mise à Jour' : 'Nouvelle Version / Release Mobile',
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
              // Version & Titre
              Row(
                children: [
                  SizedBox(
                    width: 90,
                    child: TextFormField(
                      controller: _versionController,
                      style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                      decoration: const InputDecoration(
                        labelText: 'Version *',
                        hintText: 'v1.1.0',
                        border: OutlineInputBorder(),
                      ),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) return 'Requis';
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      controller: _titleController,
                      style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                      decoration: const InputDecoration(
                        labelText: 'Titre de la mise à jour *',
                        hintText: 'ex: Module Finance v1',
                        border: OutlineInputBorder(),
                      ),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) return 'Titre requis';
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Type & Statut Dropdowns
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<AppReleaseType>(
                      isExpanded: true,
                      value: _type,
                      decoration: const InputDecoration(
                        labelText: 'Type',
                        border: OutlineInputBorder(),
                      ),
                      items: AppReleaseType.values.map((type) {
                        return DropdownMenuItem(
                          value: type,
                          child: Text(
                            type.label,
                            style: TextStyle(fontSize: 12, color: isDark ? Colors.white : Colors.black87),
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _type = val);
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: DropdownButtonFormField<AppReleaseStatus>(
                      isExpanded: true,
                      value: _status,
                      decoration: const InputDecoration(
                        labelText: 'Statut',
                        border: OutlineInputBorder(),
                      ),
                      items: AppReleaseStatus.values.map((status) {
                        return DropdownMenuItem(
                          value: status,
                          child: Text(
                            status.label,
                            style: TextStyle(fontSize: 12, color: isDark ? Colors.white : Colors.black87),
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _status = val);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Date & Budget lié
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: _pickDate,
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Date de sortie',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.event, color: Colors.teal, size: 18),
                        ),
                        child: Text(
                          _dateFormat.format(_targetDate),
                          style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      isExpanded: true,
                      value: _selectedBudgetId.isNotEmpty ? _selectedBudgetId : null,
                      decoration: const InputDecoration(
                        labelText: 'Budget lié',
                        border: OutlineInputBorder(),
                      ),
                      hint: const Text('Sélectionner'),
                      items: widget.availableBudgets.map((b) {
                        return DropdownMenuItem(
                          value: b.id,
                          child: Text(
                            b.title,
                            style: TextStyle(fontSize: 12, color: isDark ? Colors.white : Colors.black87),
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedBudgetId = val);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Responsable
              TextFormField(
                controller: _responsibleController,
                style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                decoration: const InputDecoration(
                  labelText: 'Responsable de la release',
                  hintText: 'ex: Jean - Lead Dev Mobile',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person_outline, color: Colors.teal),
                ),
              ),
              const SizedBox(height: 12),

              // Description / Changelog
              TextFormField(
                controller: _descriptionController,
                style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                decoration: const InputDecoration(
                  labelText: 'Notes de version / Changelog',
                  hintText: '- Ajout du module budget FCFA\n- Correctifs de performance...',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.notes, color: Colors.teal),
                ),
                maxLines: 3,
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
          child: Text(isEditing ? 'Enregistrer' : 'Planifier'),
        ),
      ],
    );
  }
}
