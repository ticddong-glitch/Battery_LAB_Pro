import 'package:flutter/material.dart';

import '../models/calculation_result.dart';
import '../models/electrode.dart';
import '../models/experiment.dart';
import '../repository/experiment_repository.dart';
import '../sevices/calculation_service.dart';

class ElectrodeScreen extends StatefulWidget {
  final Experiment experiment;
  final Electrode electrode;

  const ElectrodeScreen({
    super.key,
    required this.experiment,
    required this.electrode,
  });

  @override
  State<ElectrodeScreen> createState() => _ElectrodeScreenState();
}

class _ElectrodeScreenState extends State<ElectrodeScreen> {
  late final TextEditingController _activeMaterialController;
  late final TextEditingController _collectorController;
  late final TextEditingController _diameterController;
  late final TextEditingController _thicknessController;

  bool _skipMode = false;
  double? _manualArea;
  double? _manualActiveMaterialMass;
  double? _manualLoading;
  double? _manualArealCapacity;
  double? _manualElectrodeDensity;
  double? _manualPorosity;
  double? _manualTargetThickness;

  @override
  void initState() {
    super.initState();
    final input = widget.electrode.input;

    _activeMaterialController = TextEditingController(
      text: input.totalMass.toString(),
    );
    _collectorController = TextEditingController(
      text: input.collectorMass.toString(),
    );
    _diameterController = TextEditingController(
      text: input.diameter.toString(),
    );
    _thicknessController = TextEditingController(
      text: input.thickness.toString(),
    );

    _recalculate();
  }

  @override
  void dispose() {
    _activeMaterialController.dispose();
    _collectorController.dispose();
    _diameterController.dispose();
    _thicknessController.dispose();
    super.dispose();
  }

  void _syncInput() {
    final input = widget.electrode.input;
    final shared = widget.experiment.sharedValues;

    input.totalMass = double.tryParse(_activeMaterialController.text) ?? input.totalMass;
    input.collectorMass = double.tryParse(_collectorController.text) ?? input.collectorMass;
    input.diameter = double.tryParse(_diameterController.text) ?? input.diameter;
    input.thickness = double.tryParse(_thicknessController.text) ?? input.thickness;

    _syncNumericOverrideFromInput(
      key: 'averageFoilWeight',
      currentValue: input.collectorMass,
      sharedValue: shared.averageFoilWeight,
    );
    _syncNumericOverrideFromInput(
      key: 'electrodeDiameter',
      currentValue: input.diameter,
      sharedValue: shared.electrodeDiameter,
    );
    _syncNumericOverrideFromInput(
      key: 'foilThickness',
      currentValue: input.thickness,
      sharedValue: shared.foilThickness,
    );
  }

  void _syncNumericOverrideFromInput({
    required String key,
    required double currentValue,
    required double sharedValue,
  }) {
    if (!currentValue.isFinite) {
      return;
    }
    if ((currentValue - sharedValue).abs() <= 1e-9) {
      widget.electrode.clearOverride(key);
    } else {
      widget.electrode.setOverride(key, currentValue);
    }
  }

  Future<void> _editSharedOverride({
    required String key,
    required String title,
    required double sharedValue,
  }) async {
    final initial = widget.electrode.resolveValue(key, sharedValue);
    final controller = TextEditingController(text: initial.toString());

    final value = await showDialog<double>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            labelText: 'Shared default: ${sharedValue.toStringAsFixed(2)}',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context, double.tryParse(controller.text));
            },
            child: const Text('Apply'),
          ),
        ],
      ),
    );

    if (value == null || !value.isFinite) {
      return;
    }

    if ((value - sharedValue).abs() <= 1e-9) {
      widget.electrode.clearOverride(key);
    } else {
      widget.electrode.setOverride(key, value);
    }
    _recalculate();
  }

  void _toggleSkipMode(bool value) {
    setState(() {
      _skipMode = value;
      if (!value) {
        _manualArea = null;
        _manualActiveMaterialMass = null;
        _manualLoading = null;
        _manualArealCapacity = null;
        _manualElectrodeDensity = null;
        _manualPorosity = null;
        _manualTargetThickness = null;
      }
    });
    _recalculate();
  }

  void _recalculate() {
    _syncInput();
    final result = CalculationService.calculateForElectrode(
      electrode: widget.electrode,
      activeMaterialRatioPercent: widget.experiment.sharedValues.activeMaterialRatio,
      specificCapacity: widget.experiment.sharedValues.specificCapacity,
      trueDensity: widget.experiment.sharedValues.trueDensity,
      foilWeightMg: widget.experiment.sharedValues.averageFoilWeight,
      foilThicknessUm: widget.experiment.sharedValues.foilThickness,
      skipMode: _skipMode,
      manualArea: _manualArea,
      manualActiveMaterialMass: _manualActiveMaterialMass,
      manualLoading: _manualLoading,
      manualArealCapacity: _manualArealCapacity,
      manualElectrodeDensity: _manualElectrodeDensity,
      manualPorosity: _manualPorosity,
    );

    widget.electrode.result = result;
    ExperimentRepository.instance.update(widget.experiment);

    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final result = widget.electrode.result;
    final shared = widget.experiment.sharedValues;
    final pressEnabled = widget.electrode.resolveSharedBool(
      Electrode.keyPressEnabled,
      shared,
    );
    final resolvedTargetPorosity = widget.electrode.resolveSharedNumber(
      Electrode.keyTargetPorosity,
      shared,
    );
    final resolvedTrueDensity = widget.electrode.resolveSharedNumber(
      Electrode.keyTrueDensity,
      shared,
    );
    final resolvedLoading = result.loading;
    final pressValidationMessage = CalculationService.validatePressDesign(
      loadingMgPerCm2: resolvedLoading,
      trueDensity: resolvedTrueDensity,
      targetPorosityPercent: resolvedTargetPorosity,
    );
    final solidThicknessUm = CalculationService.calculateSolidThicknessUm(
      loadingMgPerCm2: resolvedLoading,
      trueDensity: resolvedTrueDensity,
    );
    final targetThicknessUm = CalculationService.calculateTargetThickness(
      loadingMgPerCm2: resolvedLoading,
      trueDensity: resolvedTrueDensity,
      targetPorosityPercent: resolvedTargetPorosity,
      skipMode: _skipMode,
      manualValue: _manualTargetThickness,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text('Electrode ${widget.electrode.number}'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Electrode Number',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text('${widget.electrode.number}'),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Status',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  result.validationMessage == null ? 'Calculated' : 'Invalid',
                ),
              ],
            ),
            const SizedBox(height: 28),
            SwitchListTile(
              value: _skipMode,
              title: const Text('Skip Mode'),
              subtitle: const Text('Use manual values when enabled'),
              onChanged: _toggleSkipMode,
            ),
            const SizedBox(height: 8),
            const Text(
              'Input Section',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _LabeledField(
              label: 'Active Material Weight (mg)',
              controller: _activeMaterialController,
              onChanged: (_) => _recalculate(),
            ),
            const SizedBox(height: 16),
            // Current collector weight with override indicator
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Expanded(child: Text('Current Collector Weight (mg)')),
                    if (widget.electrode.hasOverride('averageFoilWeight'))
                      IconButton(
                        icon: const Icon(Icons.restore),
                        tooltip: 'Restore shared value',
                        onPressed: () {
                          widget.electrode.clearOverride('averageFoilWeight');
                          widget.electrode.input.collectorMass = widget.experiment.sharedValues.averageFoilWeight;
                          _collectorController.text = widget.experiment.sharedValues.averageFoilWeight.toStringAsFixed(2);
                          _recalculate();
                        },
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _collectorController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  onChanged: (_) => _recalculate(),
                  decoration: InputDecoration(
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Expanded(child: Text('Electrode Diameter (mm)')),
                    if (widget.electrode.hasOverride('electrodeDiameter'))
                      IconButton(
                        icon: const Icon(Icons.restore),
                        tooltip: 'Restore shared value',
                        onPressed: () {
                          widget.electrode.clearOverride('electrodeDiameter');
                          widget.electrode.input.diameter = widget.experiment.sharedValues.electrodeDiameter;
                          _diameterController.text = widget.experiment.sharedValues.electrodeDiameter.toStringAsFixed(2);
                          _recalculate();
                        },
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _diameterController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  onChanged: (_) => _recalculate(),
                  decoration: InputDecoration(
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Expanded(child: Text('Thickness (µm)')),
                    if (widget.electrode.hasOverride('foilThickness'))
                      IconButton(
                        icon: const Icon(Icons.restore),
                        tooltip: 'Restore shared value',
                        onPressed: () {
                          widget.electrode.clearOverride('foilThickness');
                          widget.electrode.input.thickness = widget.experiment.sharedValues.foilThickness;
                          _thicknessController.text = widget.experiment.sharedValues.foilThickness.toStringAsFixed(2);
                          _recalculate();
                        },
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _thicknessController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  onChanged: (_) => _recalculate(),
                  decoration: InputDecoration(
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Text(
              'Shared Parameter Overrides',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            // List common shared params and allow restoring
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Active Material Ratio (%)'),
                Row(children: [
                  IconButton(
                    icon: const Icon(Icons.edit_outlined),
                    tooltip: 'Set override',
                    onPressed: () => _editSharedOverride(
                      key: 'activeMaterialRatio',
                      title: 'Active Material Ratio (%) Override',
                      sharedValue: widget.experiment.sharedValues.activeMaterialRatio,
                    ),
                  ),
                  if (widget.electrode.hasOverride('activeMaterialRatio'))
                    IconButton(
                      icon: const Icon(Icons.restore),
                      tooltip: 'Restore shared value',
                      onPressed: () {
                        widget.electrode.clearOverride('activeMaterialRatio');
                        // no direct input field to restore; just recalc
                        _recalculate();
                      },
                    ),
                ]),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Specific Capacity (mAh/g)'),
                Row(children: [
                  IconButton(
                    icon: const Icon(Icons.edit_outlined),
                    tooltip: 'Set override',
                    onPressed: () => _editSharedOverride(
                      key: 'specificCapacity',
                      title: 'Specific Capacity Override',
                      sharedValue: widget.experiment.sharedValues.specificCapacity,
                    ),
                  ),
                  if (widget.electrode.hasOverride('specificCapacity'))
                    IconButton(
                      icon: const Icon(Icons.restore),
                      tooltip: 'Restore shared value',
                      onPressed: () {
                        widget.electrode.clearOverride('specificCapacity');
                        _recalculate();
                      },
                    ),
                ]),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('True Density (g/cm³)'),
                Row(children: [
                  IconButton(
                    icon: const Icon(Icons.edit_outlined),
                    tooltip: 'Set override',
                    onPressed: () => _editSharedOverride(
                      key: 'trueDensity',
                      title: 'True Density Override',
                      sharedValue: widget.experiment.sharedValues.trueDensity,
                    ),
                  ),
                  if (widget.electrode.hasOverride('trueDensity'))
                    IconButton(
                      icon: const Icon(Icons.restore),
                      tooltip: 'Restore shared value',
                      onPressed: () {
                        widget.electrode.clearOverride('trueDensity');
                        _recalculate();
                      },
                    ),
                ]),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Target Porosity (%)'),
                Row(children: [
                  IconButton(
                    icon: const Icon(Icons.edit_outlined),
                    tooltip: pressEnabled ? 'Set override' : 'Press disabled',
                    onPressed: pressEnabled
                        ? () => _editSharedOverride(
                              key: Electrode.keyTargetPorosity,
                              title: 'Target Porosity (%) Override',
                              sharedValue: shared.targetPorosity,
                            )
                        : null,
                  ),
                  if (widget.electrode.hasOverride(Electrode.keyTargetPorosity))
                    IconButton(
                      icon: const Icon(Icons.restore),
                      tooltip: 'Restore shared value',
                      onPressed: () {
                        widget.electrode.clearOverride(Electrode.keyTargetPorosity);
                        _recalculate();
                      },
                    ),
                ]),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Press Calculator',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            if (!pressEnabled)
              const Text('Press is disabled. Target Porosity override is disabled.')
            else ...[
              if (pressValidationMessage != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    pressValidationMessage,
                    style: const TextStyle(color: Colors.orange),
                  ),
                )
              else
                Column(
                  children: [
                    _ResultTile(
                      label: 'Solid Thickness',
                      value: solidThicknessUm,
                      unit: 'μm',
                      state: CalculationState.calculated,
                    ),
                    if (_skipMode)
                      _ManualResultField(
                        label: 'Target Thickness',
                        value: targetThicknessUm,
                        unit: 'μm',
                        state: _manualTargetThickness != null
                            ? CalculationState.manual
                            : CalculationState.calculated,
                        onChanged: (value) {
                          _manualTargetThickness = value;
                          _recalculate();
                        },
                      )
                    else
                      _ResultTile(
                        label: 'Target Thickness',
                        value: targetThicknessUm,
                        unit: 'μm',
                        state: CalculationState.calculated,
                      ),
                  ],
                ),
            ],
            if (result.validationMessage != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  result.validationMessage!,
                  style: const TextStyle(color: Colors.red),
                ),
              )
            else
              const SizedBox.shrink(),
            const SizedBox(height: 20),
            const Text(
              'Calculated Values',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            if (_skipMode)
              _ManualEntrySection(
                areaValue: result.area,
                areaState: result.areaState,
                onAreaChanged: (value) {
                  _manualArea = value;
                  _recalculate();
                },
                activeMaterialMassValue: result.activeMaterialMass,
                activeMaterialMassState: result.activeMaterialMassState,
                onActiveMaterialMassChanged: (value) {
                  _manualActiveMaterialMass = value;
                  _recalculate();
                },
                loadingValue: result.loading,
                loadingState: result.loadingState,
                onLoadingChanged: (value) {
                  _manualLoading = value;
                  _recalculate();
                },
                arealCapacityValue: result.arealCapacity,
                arealCapacityState: result.arealCapacityState,
                onArealCapacityChanged: (value) {
                  _manualArealCapacity = value;
                  _recalculate();
                },
                electrodeDensityValue: result.electrodeDensity,
                electrodeDensityState: result.electrodeDensityState,
                onElectrodeDensityChanged: (value) {
                  _manualElectrodeDensity = value;
                  _recalculate();
                },
                porosityValue: result.porosity,
                porosityState: result.porosityState,
                onPorosityChanged: (value) {
                  _manualPorosity = value;
                  _recalculate();
                },
              )
            else
              Column(
                children: [
                  _ResultTile(
                    label: 'Area',
                    value: result.area,
                    unit: 'cm²',
                    state: result.areaState,
                  ),
                  _ResultTile(
                    label: 'Active Material Mass',
                    value: result.activeMaterialMass,
                    unit: 'mg',
                    state: result.activeMaterialMassState,
                  ),
                  _ResultTile(
                    label: 'Loading Level',
                    value: result.loading,
                    unit: 'mg/cm²',
                    state: result.loadingState,
                  ),
                  _ResultTile(
                    label: 'Areal Capacity',
                    value: result.arealCapacity,
                    unit: 'mAh/cm²',
                    state: result.arealCapacityState,
                  ),
                  _ResultTile(
                    label: 'Density',
                    value: result.electrodeDensity,
                    unit: 'g/cm³',
                    state: result.electrodeDensityState,
                  ),
                  _ResultTile(
                    label: 'Porosity',
                    value: result.porosity,
                    unit: '%',
                    state: result.porosityState,
                  ),
                ],
              ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _ManualEntrySection extends StatelessWidget {
  final double areaValue;
  final CalculationState areaState;
  final ValueChanged<double?> onAreaChanged;
  final double activeMaterialMassValue;
  final CalculationState activeMaterialMassState;
  final ValueChanged<double?> onActiveMaterialMassChanged;
  final double loadingValue;
  final CalculationState loadingState;
  final ValueChanged<double?> onLoadingChanged;
  final double arealCapacityValue;
  final CalculationState arealCapacityState;
  final ValueChanged<double?> onArealCapacityChanged;
  final double electrodeDensityValue;
  final CalculationState electrodeDensityState;
  final ValueChanged<double?> onElectrodeDensityChanged;
  final double porosityValue;
  final CalculationState porosityState;
  final ValueChanged<double?> onPorosityChanged;

  const _ManualEntrySection({
    required this.areaValue,
    required this.areaState,
    required this.onAreaChanged,
    required this.activeMaterialMassValue,
    required this.activeMaterialMassState,
    required this.onActiveMaterialMassChanged,
    required this.loadingValue,
    required this.loadingState,
    required this.onLoadingChanged,
    required this.arealCapacityValue,
    required this.arealCapacityState,
    required this.onArealCapacityChanged,
    required this.electrodeDensityValue,
    required this.electrodeDensityState,
    required this.onElectrodeDensityChanged,
    required this.porosityValue,
    required this.porosityState,
    required this.onPorosityChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _ManualResultField(
          label: 'Area',
          value: areaValue,
          unit: 'cm²',
          state: areaState,
          onChanged: onAreaChanged,
        ),
        _ManualResultField(
          label: 'Active Material Mass',
          value: activeMaterialMassValue,
          unit: 'mg',
          state: activeMaterialMassState,
          onChanged: onActiveMaterialMassChanged,
        ),
        _ManualResultField(
          label: 'Loading Level',
          value: loadingValue,
          unit: 'mg/cm²',
          state: loadingState,
          onChanged: onLoadingChanged,
        ),
        _ManualResultField(
          label: 'Areal Capacity',
          value: arealCapacityValue,
          unit: 'mAh/cm²',
          state: arealCapacityState,
          onChanged: onArealCapacityChanged,
        ),
        _ManualResultField(
          label: 'Density',
          value: electrodeDensityValue,
          unit: 'g/cm³',
          state: electrodeDensityState,
          onChanged: onElectrodeDensityChanged,
        ),
        _ManualResultField(
          label: 'Porosity',
          value: porosityValue,
          unit: '%',
          state: porosityState,
          onChanged: onPorosityChanged,
        ),
      ],
    );
  }
}

class _ManualResultField extends StatelessWidget {
  final String label;
  final double value;
  final String unit;
  final CalculationState state;
  final ValueChanged<double?> onChanged;

  const _ManualResultField({
    required this.label,
    required this.value,
    required this.unit,
    required this.state,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label),
                if (state == CalculationState.manual)
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'Manual',
                      style: TextStyle(fontSize: 11),
                    ),
                  ),
              ],
            ),
          ),
          SizedBox(
            width: 120,
            child: TextFormField(
              initialValue: value.toStringAsFixed(2),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              textAlign: TextAlign.end,
              decoration: InputDecoration(
                suffixText: unit,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onChanged: (text) => onChanged(double.tryParse(text)),
            ),
          ),
        ],
      ),
    );
  }
}

class _LabeledField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final ValueChanged<String>? onChanged;

  const _LabeledField({
    required this.label,
    required this.controller,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          onChanged: onChanged,
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ],
    );
  }
}

class _ResultTile extends StatelessWidget {
  final String label;
  final double value;
  final String unit;
  final CalculationState state;

  const _ResultTile({
    required this.label,
    required this.value,
    required this.unit,
    required this.state,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Text(label),
              if (state == CalculationState.manual)
                Container(
                  margin: const EdgeInsets.only(left: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'Manual',
                    style: TextStyle(fontSize: 11),
                  ),
                ),
            ],
          ),
          Text('${value.toStringAsFixed(2)} $unit'),
        ],
      ),
    );
  }
}
