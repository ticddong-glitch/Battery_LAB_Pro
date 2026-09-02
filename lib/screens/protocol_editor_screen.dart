import 'package:flutter/material.dart';

import '../models/presets/collector_preset.dart';
import '../models/presets/material_preset.dart';
import '../models/protocol.dart';
import '../repository/collector_preset_repository.dart';
import '../repository/material_preset_repository.dart';
import '../repository/protocol_repository.dart';

class ProtocolEditorScreen extends StatefulWidget {
  final Protocol protocol;

  const ProtocolEditorScreen({super.key, required this.protocol});

  @override
  State<ProtocolEditorScreen> createState() => _ProtocolEditorScreenState();
}

class _ProtocolEditorScreenState extends State<ProtocolEditorScreen> {
  static const String _nonePresetValue = '__none__';
  static const String _missingMaterialPresetValue = '__missing_material__';
  static const String _missingCollectorPresetValue = '__missing_collector__';

  late final TextEditingController _nameController;
  late final TextEditingController _materialController;
  late final TextEditingController _specificCapacityController;
  late final TextEditingController _trueDensityController;
  late final TextEditingController _collectorPresetController;
  late final TextEditingController _collectorThicknessController;
  late final TextEditingController _collectorDensityController;
  late final TextEditingController _averageFoilWeightController;
  late final TextEditingController _diameterController;
  late final TextEditingController _activeController;
  late final TextEditingController _conductiveController;
  late final TextEditingController _binderController;
  late final TextEditingController _targetPorosityController;
  late final TextEditingController _solidContentController;
  late final TextEditingController _dryingTemperatureController;
  late final TextEditingController _dryingTimeController;
  late final TextEditingController _rollPressPressureController;
  late final TextEditingController _notesController;
  late bool _pressEnabled;
  late String? _selectedMaterialPresetId;
  late String? _selectedCollectorPresetId;
  List<MaterialPreset> _materialPresets = const [];
  List<CollectorPreset> _collectorPresets = const [];

  final repo = ProtocolRepository.instance;
  final MaterialPresetRepository _materialPresetRepository = SQLiteMaterialPresetRepository();
  final CollectorPresetRepository _collectorPresetRepository = SQLiteCollectorPresetRepository();

  @override
  void initState() {
    super.initState();
    final p = widget.protocol;

    _nameController = TextEditingController(text: p.name);
    _materialController = TextEditingController(text: p.materialName);
    _specificCapacityController = TextEditingController(text: p.specificCapacity.toString());
    _trueDensityController = TextEditingController(text: p.trueDensity.toString());
    _collectorPresetController = TextEditingController(text: p.collectorName);
    _collectorThicknessController = TextEditingController(text: p.collectorThickness.toString());
    _collectorDensityController = TextEditingController(text: p.collectorDensity.toString());
    _averageFoilWeightController = TextEditingController(text: p.averageFoilWeight.toString());
    _diameterController = TextEditingController(text: p.diameter.toString());
    _activeController = TextEditingController(text: p.activeRatio.toString());
    _conductiveController = TextEditingController(text: p.conductiveRatio.toString());
    _binderController = TextEditingController(text: p.binderRatio.toString());
    _targetPorosityController = TextEditingController(text: p.targetPorosity.toString());
    _solidContentController = TextEditingController(text: p.solidContent.toString());
    _dryingTemperatureController = TextEditingController(text: p.dryingTemperature.toString());
    _dryingTimeController = TextEditingController(text: p.dryingTime.toString());
    _rollPressPressureController = TextEditingController(text: p.rollPressPressure.toString());
    _notesController = TextEditingController(text: p.notes);
    _pressEnabled = p.targetPorosity > 0;
    _selectedMaterialPresetId = p.materialPresetId;
    _selectedCollectorPresetId = p.collectorPresetId;
    _loadPresets();
  }

  Future<void> _loadPresets() async {
    final materials = await _materialPresetRepository.getAll();
    final collectors = await _collectorPresetRepository.getAll();

    if (!mounted) {
      return;
    }

    setState(() {
      _materialPresets = materials;
      _collectorPresets = collectors;
    });
  }

  MaterialPreset? _selectedMaterialPreset() {
    final selectedId = _selectedMaterialPresetId;
    if (selectedId == null) {
      return null;
    }

    for (final preset in _materialPresets) {
      if (preset.id == selectedId) {
        return preset;
      }
    }
    return null;
  }

  CollectorPreset? _selectedCollectorPreset() {
    final selectedId = _selectedCollectorPresetId;
    if (selectedId == null) {
      return null;
    }

    for (final preset in _collectorPresets) {
      if (preset.id == selectedId) {
        return preset;
      }
    }
    return null;
  }

  void _applyMaterialPreset(MaterialPreset preset) {
    _materialController.text = preset.name;
    _trueDensityController.text = preset.trueDensity.toString();
    if (preset.specificCapacity != null) {
      _specificCapacityController.text = preset.specificCapacity!.toString();
    }
  }

  void _applyCollectorPreset(CollectorPreset preset) {
    _collectorPresetController.text = preset.presetName;
    _collectorThicknessController.text = preset.thickness.toString();
    _averageFoilWeightController.text = preset.averageFoilWeight.toString();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _materialController.dispose();
    _specificCapacityController.dispose();
    _trueDensityController.dispose();
    _collectorPresetController.dispose();
    _collectorThicknessController.dispose();
    _collectorDensityController.dispose();
    _averageFoilWeightController.dispose();
    _diameterController.dispose();
    _activeController.dispose();
    _conductiveController.dispose();
    _binderController.dispose();
    _targetPorosityController.dispose();
    _solidContentController.dispose();
    _dryingTemperatureController.dispose();
    _dryingTimeController.dispose();
    _rollPressPressureController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  String? _validateProtocolInput() {
    if (_nameController.text.trim().isEmpty) {
      return 'Name is required.';
    }
    if (_materialController.text.trim().isEmpty) {
      return 'Active Material is required.';
    }
    if (_collectorPresetController.text.trim().isEmpty) {
      return 'Collector Preset is required.';
    }

    final active = double.tryParse(_activeController.text);
    final conductive = double.tryParse(_conductiveController.text);
    final binder = double.tryParse(_binderController.text);
    if (active == null || conductive == null || binder == null) {
      return 'Composition values must be valid numbers.';
    }
    if (active < 0 || conductive < 0 || binder < 0) {
      return 'Composition values must be greater than or equal to 0.';
    }

    final total = active + conductive + binder;
    if ((total - 100).abs() > 0.01) {
      return 'Composition must total 100%.';
    }

    if (_pressEnabled) {
      final targetPorosity = double.tryParse(_targetPorosityController.text);
      if (targetPorosity == null || targetPorosity <= 0 || targetPorosity >= 100) {
        return 'Target Porosity must be between 0 and 100 when Press is enabled.';
      }
    }

    final specificCapacity = double.tryParse(_specificCapacityController.text);
    final trueDensity = double.tryParse(_trueDensityController.text);
    final collectorThickness = double.tryParse(_collectorThicknessController.text);
    final collectorDensity = double.tryParse(_collectorDensityController.text);
    final averageFoilWeight = double.tryParse(_averageFoilWeightController.text);
    final diameter = double.tryParse(_diameterController.text);
    final solidContent = double.tryParse(_solidContentController.text);

    if (specificCapacity == null || specificCapacity < 0) {
      return 'Specific Capacity must be greater than or equal to 0.';
    }
    if (trueDensity == null || trueDensity <= 0) {
      return 'True Density must be greater than 0.';
    }
    if (collectorThickness == null || collectorThickness < 0) {
      return 'Collector Thickness must be greater than or equal to 0.';
    }
    if (collectorDensity == null || collectorDensity <= 0) {
      return 'Collector Density must be greater than 0.';
    }
    if (averageFoilWeight == null || averageFoilWeight < 0) {
      return 'Average Foil Weight must be greater than or equal to 0.';
    }
    if (diameter == null || diameter <= 0) {
      return 'Diameter must be greater than 0.';
    }
    if (solidContent == null || solidContent <= 0 || solidContent > 1) {
      return 'Solid Content must be between 0 and 1.';
    }

    return null;
  }

  void _save() {
    final validationMessage = _validateProtocolInput();
    if (validationMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(validationMessage)),
      );
      return;
    }

    final p = widget.protocol.copyWith(
      name: _nameController.text.trim(),
      materialPresetId: _selectedMaterialPresetId,
      materialName: _materialController.text.trim(),
      specificCapacity: double.tryParse(_specificCapacityController.text) ?? widget.protocol.specificCapacity,
      trueDensity: double.tryParse(_trueDensityController.text) ?? widget.protocol.trueDensity,
      collectorPresetId: _selectedCollectorPresetId,
      collectorName: _collectorPresetController.text.trim(),
      collectorThickness: double.tryParse(_collectorThicknessController.text) ?? widget.protocol.collectorThickness,
      collectorDensity: double.tryParse(_collectorDensityController.text) ?? widget.protocol.collectorDensity,
      averageFoilWeight: double.tryParse(_averageFoilWeightController.text) ?? widget.protocol.averageFoilWeight,
      diameter: double.tryParse(_diameterController.text) ?? widget.protocol.diameter,
      activeRatio: double.tryParse(_activeController.text) ?? widget.protocol.activeRatio,
      conductiveRatio: double.tryParse(_conductiveController.text) ?? widget.protocol.conductiveRatio,
      binderRatio: double.tryParse(_binderController.text) ?? widget.protocol.binderRatio,
      targetPorosity: _pressEnabled
          ? (double.tryParse(_targetPorosityController.text) ?? widget.protocol.targetPorosity)
          : 0,
      solidContent: double.tryParse(_solidContentController.text) ?? widget.protocol.solidContent,
      dryingTemperature: double.tryParse(_dryingTemperatureController.text) ?? widget.protocol.dryingTemperature,
      dryingTime: double.tryParse(_dryingTimeController.text) ?? widget.protocol.dryingTime,
      rollPressPressure: double.tryParse(_rollPressPressureController.text) ?? widget.protocol.rollPressPressure,
      notes: _notesController.text,
      clearMaterialPresetId: _selectedMaterialPresetId == null,
      clearCollectorPresetId: _selectedCollectorPresetId == null,
    );

    repo.update(p);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final selectedMaterialPreset = _selectedMaterialPreset();
    final selectedCollectorPreset = _selectedCollectorPreset();
    final isMaterialPresetMissing =
      _selectedMaterialPresetId != null && selectedMaterialPreset == null;
    final isCollectorPresetMissing =
      _selectedCollectorPresetId != null && selectedCollectorPreset == null;

    final materialDropdownValue = isMaterialPresetMissing
      ? _missingMaterialPresetValue
      : (_selectedMaterialPresetId ?? _nonePresetValue);
    final collectorDropdownValue = isCollectorPresetMissing
      ? _missingCollectorPresetValue
      : (_selectedCollectorPresetId ?? _nonePresetValue);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Protocol'),
        actions: [
          IconButton(onPressed: _save, icon: const Icon(Icons.save)),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('General', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 8),
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(labelText: 'Name'),
          ),
          TextField(
            controller: _notesController,
            maxLines: 2,
            decoration: const InputDecoration(labelText: 'Memo'),
          ),
          const SizedBox(height: 12),

          const Divider(),
          const Text('Materials', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 8),
          InputDecorator(
            decoration: const InputDecoration(labelText: 'Material Preset'),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                isExpanded: true,
                value: materialDropdownValue,
                items: [
                  const DropdownMenuItem<String>(
                    value: _nonePresetValue,
                    child: Text('None (Manual Input)'),
                  ),
                  if (isMaterialPresetMissing)
                    const DropdownMenuItem<String>(
                      value: _missingMaterialPresetValue,
                      child: Text('Preset not found'),
                    ),
                  ..._materialPresets.map(
                    (preset) => DropdownMenuItem<String>(
                      value: preset.id,
                      child: Text(preset.name),
                    ),
                  ),
                ],
                onChanged: (value) {
                  if (value == null || value == _missingMaterialPresetValue) {
                    return;
                  }

                  setState(() {
                    if (value == _nonePresetValue) {
                      _selectedMaterialPresetId = null;
                      return;
                    }

                    _selectedMaterialPresetId = value;
                    final preset = _selectedMaterialPreset();
                    if (preset != null) {
                      _applyMaterialPreset(preset);
                    }
                  });
                },
              ),
            ),
          ),
          if (isMaterialPresetMissing)
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: Text('Preset not found', style: TextStyle(color: Colors.red)),
            ),
          const SizedBox(height: 8),
          TextField(
            controller: _materialController,
            decoration: const InputDecoration(labelText: 'Active Material'),
          ),
          TextField(
            controller: _conductiveController,
            decoration: const InputDecoration(labelText: 'Conductive Additive (%)'),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
          ),
          TextField(
            controller: _binderController,
            decoration: const InputDecoration(labelText: 'Binder (%)'),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
          ),
          TextField(
            controller: _activeController,
            decoration: const InputDecoration(labelText: 'Composition - Active Material (%)'),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
          ),
          Builder(
            builder: (_) {
              final active = double.tryParse(_activeController.text) ?? 0;
              final conductive = double.tryParse(_conductiveController.text) ?? 0;
              final binder = double.tryParse(_binderController.text) ?? 0;
              final total = active + conductive + binder;
              return Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text('Composition Total: ${total.toStringAsFixed(2)}%'),
              );
            },
          ),
          const SizedBox(height: 12),

          const Divider(),
          const Text('Collector', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 8),
          InputDecorator(
            decoration: const InputDecoration(labelText: 'Collector Preset'),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                isExpanded: true,
                value: collectorDropdownValue,
                items: [
                  const DropdownMenuItem<String>(
                    value: _nonePresetValue,
                    child: Text('None (Manual Input)'),
                  ),
                  if (isCollectorPresetMissing)
                    const DropdownMenuItem<String>(
                      value: _missingCollectorPresetValue,
                      child: Text('Preset not found'),
                    ),
                  ..._collectorPresets.map(
                    (preset) => DropdownMenuItem<String>(
                      value: preset.id,
                      child: Text(preset.presetName),
                    ),
                  ),
                ],
                onChanged: (value) {
                  if (value == null || value == _missingCollectorPresetValue) {
                    return;
                  }

                  setState(() {
                    if (value == _nonePresetValue) {
                      _selectedCollectorPresetId = null;
                      return;
                    }

                    _selectedCollectorPresetId = value;
                    final preset = _selectedCollectorPreset();
                    if (preset != null) {
                      _applyCollectorPreset(preset);
                    }
                  });
                },
              ),
            ),
          ),
          if (isCollectorPresetMissing)
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: Text('Preset not found', style: TextStyle(color: Colors.red)),
            ),
          const SizedBox(height: 8),
          TextField(
            controller: _collectorPresetController,
            decoration: const InputDecoration(labelText: 'Collector Preset'),
          ),
          const SizedBox(height: 12),

          const Divider(),
          const Text('Press', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: _pressEnabled,
            title: const Text('Enable Press'),
            onChanged: (value) {
              setState(() {
                _pressEnabled = value;
                if (!value) {
                  _targetPorosityController.text = '0';
                }
              });
            },
          ),
          if (_pressEnabled)
            TextField(
              controller: _targetPorosityController,
              decoration: const InputDecoration(labelText: 'Target Porosity (%)'),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),
          const SizedBox(height: 12),

          const Divider(),
          const Text('Calculation', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 8),
          TextField(
            controller: _specificCapacityController,
            decoration: const InputDecoration(labelText: 'Specific Capacity (mAh/g)'),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
          ),
          TextField(
            controller: _trueDensityController,
            decoration: const InputDecoration(labelText: 'True Density (g/cm3)'),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
          ),
          TextField(
            controller: _collectorThicknessController,
            decoration: const InputDecoration(labelText: 'Collector Thickness (um)'),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
          ),
          TextField(
            controller: _collectorDensityController,
            decoration: const InputDecoration(labelText: 'Collector Density (g/cm3)'),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
          ),
          TextField(
            controller: _averageFoilWeightController,
            decoration: const InputDecoration(labelText: 'Average Foil Weight (mg)'),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
          ),
          TextField(
            controller: _diameterController,
            decoration: const InputDecoration(labelText: 'Diameter (mm)'),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
          ),
          TextField(
            controller: _solidContentController,
            decoration: const InputDecoration(labelText: 'Solid Content (0-1)'),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
          ),
          const SizedBox(height: 12),

          const Divider(),
          const Text('Experimental Record (Optional)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 8),
          TextField(
            controller: _dryingTemperatureController,
            decoration: const InputDecoration(labelText: 'Drying Temperature (C)'),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
          ),
          TextField(
            controller: _dryingTimeController,
            decoration: const InputDecoration(labelText: 'Drying Time (hour)'),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
          ),
          TextField(
            controller: _rollPressPressureController,
            decoration: const InputDecoration(labelText: 'Roll Press Pressure (MPa)'),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
          ),
          const SizedBox(height: 4),
          const Text('Memo is stored in General > Memo to avoid duplicate input.'),
          const SizedBox(height: 20),
          ElevatedButton(onPressed: _save, child: const Text('Save')),
        ],
      ),
    );
  }
}
