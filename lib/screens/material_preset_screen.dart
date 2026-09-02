import 'package:flutter/material.dart';

import '../models/presets/material_preset.dart';
import '../widgets/dialogs/material_preset_dialog.dart';

class MaterialPresetScreen extends StatefulWidget {
  const MaterialPresetScreen({super.key});

  @override
  State<MaterialPresetScreen> createState() => _MaterialPresetScreenState();
}

class _MaterialPresetScreenState extends State<MaterialPresetScreen> {
  final _store = _MaterialPresetStore.instance;
  late List<MaterialPreset> _presets;

  @override
  void initState() {
    super.initState();
    _presets = _store.items;
  }

  void _refresh() {
    setState(() {
      _presets = _store.items;
    });
  }

  Future<void> _addPreset() async {
    final preset = await showMaterialPresetDialog(context);
    if (preset == null) return;
    _store.save(preset);
    _refresh();
  }

  Future<void> _editPreset(MaterialPreset preset) async {
    final updated = await showMaterialPresetDialog(context, preset: preset);
    if (updated == null) return;
    _store.save(updated);
    _refresh();
  }

  Future<void> _deletePreset(MaterialPreset preset) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Material Preset'),
        content: Text('Delete ${preset.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (ok == true) {
      _store.delete(preset.id);
      _refresh();
    }
  }

  String _categoryLabel(MaterialCategory category) {
    switch (category) {
      case MaterialCategory.activeMaterial:
        return 'Active Material';
      case MaterialCategory.conductiveAdditive:
        return 'Conductive Additive';
      case MaterialCategory.binder:
        return 'Binder';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Material Presets'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addPreset,
        child: const Icon(Icons.add),
      ),
      body: _presets.isEmpty
          ? const Center(
              child: Text('No Material Presets yet'),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: _presets.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final preset = _presets[index];
                return Card(
                  child: ListTile(
                    title: Text(preset.name),
                    subtitle: Text(
                      '${_categoryLabel(preset.category)} • Density ${preset.trueDensity}'
                      '${preset.specificCapacity == null ? '' : ' • Capacity ${preset.specificCapacity}'}'
                      '${preset.memo.isEmpty ? '' : '\n${preset.memo}'}',
                    ),
                    isThreeLine: preset.memo.isNotEmpty,
                    trailing: Wrap(
                      spacing: 4,
                      children: [
                        IconButton(
                          tooltip: 'Edit',
                          icon: const Icon(Icons.edit_outlined),
                          onPressed: () => _editPreset(preset),
                        ),
                        IconButton(
                          tooltip: 'Delete',
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () => _deletePreset(preset),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}

class _MaterialPresetStore {
  _MaterialPresetStore._();

  static final _MaterialPresetStore instance = _MaterialPresetStore._();

  final List<MaterialPreset> _items = [];

  List<MaterialPreset> get items => List.unmodifiable(_items);

  void save(MaterialPreset preset) {
    final index = _items.indexWhere((item) => item.id == preset.id);
    if (index == -1) {
      _items.insert(0, preset);
    } else {
      _items[index] = preset;
    }
  }

  void delete(String id) {
    _items.removeWhere((item) => item.id == id);
  }
}
