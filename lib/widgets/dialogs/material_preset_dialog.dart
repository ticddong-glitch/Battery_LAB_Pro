import 'package:flutter/material.dart';

import '../../models/presets/material_preset.dart';

Future<MaterialPreset?> showMaterialPresetDialog(
  BuildContext context, {
  MaterialPreset? preset,
}) {
  return showDialog<MaterialPreset>(
    context: context,
    builder: (_) => _MaterialPresetDialog(preset: preset),
  );
}

class _MaterialPresetDialog extends StatefulWidget {
  final MaterialPreset? preset;

  const _MaterialPresetDialog({this.preset});

  @override
  State<_MaterialPresetDialog> createState() => _MaterialPresetDialogState();
}

class _MaterialPresetDialogState extends State<_MaterialPresetDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _trueDensityController;
  late final TextEditingController _specificCapacityController;
  late final TextEditingController _memoController;
  late MaterialCategory _category;

  @override
  void initState() {
    super.initState();
    final preset = widget.preset;
    _nameController = TextEditingController(text: preset?.name ?? '');
    _trueDensityController = TextEditingController(text: preset?.trueDensity.toString() ?? '');
    _specificCapacityController = TextEditingController(text: preset?.specificCapacity?.toString() ?? '');
    _memoController = TextEditingController(text: preset?.memo ?? '');
    _category = preset?.category ?? MaterialCategory.activeMaterial;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _trueDensityController.dispose();
    _specificCapacityController.dispose();
    _memoController.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final specificCapacity = _category == MaterialCategory.activeMaterial
        ? (_specificCapacityController.text.trim().isEmpty
            ? null
            : double.tryParse(_specificCapacityController.text.trim()))
        : null;

    final result = MaterialPreset(
      id: widget.preset?.id ?? DateTime.now().microsecondsSinceEpoch.toString(),
      name: _nameController.text.trim(),
      category: _category,
      trueDensity: double.parse(_trueDensityController.text.trim()),
      specificCapacity: specificCapacity,
      memo: _memoController.text.trim(),
    );

    Navigator.pop(context, result);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return AlertDialog(
      title: Text(widget.preset == null ? 'Add Material Preset' : 'Edit Material Preset'),
      content: SizedBox(
        width: 420,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Name',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Name is required';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<MaterialCategory>(
                  initialValue: _category,
                  decoration: const InputDecoration(
                    labelText: 'Category',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: MaterialCategory.activeMaterial,
                      child: Text('Active Material'),
                    ),
                    DropdownMenuItem(
                      value: MaterialCategory.conductiveAdditive,
                      child: Text('Conductive Additive'),
                    ),
                    DropdownMenuItem(
                      value: MaterialCategory.binder,
                      child: Text('Binder'),
                    ),
                  ],
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() {
                      _category = value;
                    });
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _trueDensityController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'True Density',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    final parsed = double.tryParse((value ?? '').trim());
                    if (parsed == null || parsed <= 0) {
                      return 'True Density must be greater than 0';
                    }
                    return null;
                  },
                ),
                if (_category == MaterialCategory.activeMaterial) ...[
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _specificCapacityController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Specific Capacity',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                TextFormField(
                  controller: _memoController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Memo',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _save,
          style: FilledButton.styleFrom(
            backgroundColor: colorScheme.primary,
            foregroundColor: colorScheme.onPrimary,
          ),
          child: const Text('Save'),
        ),
      ],
    );
  }
}
