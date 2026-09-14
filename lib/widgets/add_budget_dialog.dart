import 'package:flutter/material.dart';
import '../models/budget.dart';

class AddBudgetDialog extends StatefulWidget {
  final Budget? budgetToEdit;

  const AddBudgetDialog({super.key, this.budgetToEdit});

  @override
  State<AddBudgetDialog> createState() => _AddBudgetDialogState();
}

class _AddBudgetDialogState extends State<AddBudgetDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _amountController;

  int _selectedIcon = Icons.campaign.codePoint;
  int _selectedColor = Colors.teal.toARGB32();

  final List<IconData> _availableIcons = [
    Icons.campaign,
    Icons.cloud_done,
    Icons.handshake,
    Icons.palette,
    Icons.computer,
    Icons.trending_up,
    Icons.shopping_cart,
    Icons.attach_money,
    Icons.phone_iphone,
    Icons.build,
  ];

  final List<Color> _availableColors = [
    Colors.teal,
    Colors.indigo,
    Colors.orange,
    Colors.purple,
    Colors.blue,
    Colors.green,
    Colors.pink,
    Colors.amber,
    Colors.deepOrange,
    Colors.cyan,
  ];

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.budgetToEdit?.title ?? '');
    _descriptionController = TextEditingController(text: widget.budgetToEdit?.description ?? '');
    _amountController = TextEditingController(
      text: widget.budgetToEdit != null ? widget.budgetToEdit!.allocatedBudget.toStringAsFixed(0) : '',
    );
    if (widget.budgetToEdit != null) {
      _selectedIcon = widget.budgetToEdit!.iconCodePoint;
      _selectedColor = widget.budgetToEdit!.colorValue;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      final title = _titleController.text.trim();
      final description = _descriptionController.text.trim();
      final amount = double.parse(_amountController.text.trim());

      final newBudget = Budget(
        id: widget.budgetToEdit?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        title: title,
        description: description,
        allocatedBudget: amount,
        iconCodePoint: _selectedIcon,
        colorValue: _selectedColor,
        tasks: widget.budgetToEdit?.tasks ?? [],
      );

      Navigator.of(context).pop(newBudget);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.budgetToEdit != null;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(isEditing ? 'Modifier le Budget' : 'Nouveau Budget'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Nom du budget *',
                  hintText: 'ex: Marketing & Pub, Serveur...',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.label_outline),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Veuillez saisir un nom';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description (optionnelle)',
                  hintText: 'Objectif du budget...',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.notes),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Montant alloué (FCFA) *',
                  hintText: 'ex: 1500000',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.attach_money),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Veuillez saisir un montant';
                  }
                  if (double.tryParse(val.trim()) == null || double.parse(val.trim()) <= 0) {
                    return 'Veuillez saisir un montant valide';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 18),
              const Text('Icône :', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: _availableIcons.map((icon) {
                  final isSelected = _selectedIcon == icon.codePoint;
                  return InkWell(
                    onTap: () => setState(() => _selectedIcon = icon.codePoint),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isSelected ? Color(_selectedColor).withValues(alpha: 0.2) : Colors.grey.shade100,
                        border: Border.all(
                          color: isSelected ? Color(_selectedColor) : Colors.transparent,
                          width: 2,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        icon,
                        color: isSelected ? Color(_selectedColor) : Colors.grey.shade700,
                        size: 24,
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 18),
              const Text('Couleur :', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _availableColors.map((color) {
                  final isSelected = _selectedColor == color.toARGB32();
                  return GestureDetector(
                    onTap: () => setState(() => _selectedColor = color.toARGB32()),
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected ? Colors.black : Colors.white,
                          width: isSelected ? 3 : 1,
                        ),
                        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
                      ),
                      child: isSelected ? const Icon(Icons.check, color: Colors.white, size: 18) : null,
                    ),
                  );
                }).toList(),
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
            backgroundColor: Color(_selectedColor),
            foregroundColor: Colors.white,
          ),
          child: Text(isEditing ? 'Enregistrer' : 'Créer'),
        ),
      ],
    );
  }
}
