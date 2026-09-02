import 'package:flutter/material.dart';

import '../models/calculation_result.dart';
import '../models/electrode.dart';
import '../models/electrode_input.dart';
import '../models/experiment.dart';
import '../repository/experiment_repository.dart';
import '../sevices/calculation_service.dart';
import '../widgets/electrode_card.dart';
import 'batch_calculator_screen.dart';
import 'compare_screen.dart';
import 'electrode_screen.dart';
import '../repository/export_helper.dart';

class ExperimentDetailScreen extends StatefulWidget {
  final String experimentId;

  const ExperimentDetailScreen({
    super.key,
    required this.experimentId,
  });

  @override
  State<ExperimentDetailScreen> createState() => _ExperimentDetailScreenState();
}

class _ExperimentDetailScreenState extends State<ExperimentDetailScreen> {
  late final TextEditingController _noteController;
  DateTime? _lastSavedAt;
  final List<FocusNode> _coatedWeightFocusNodes = <FocusNode>[];
  final List<FocusNode> _coatedThicknessFocusNodes = <FocusNode>[];
  final List<FocusNode> _foilWeightFocusNodes = <FocusNode>[];
  final List<FocusNode> _foilThicknessFocusNodes = <FocusNode>[];
  final List<GlobalKey> _electrodeCardKeys = <GlobalKey>[];

  Experiment? get _experiment =>
      ExperimentRepository.instance.findById(widget.experimentId);

  @override
  void initState() {
    super.initState();
    _noteController = TextEditingController(
      text: _experiment?.memo ?? '',
    );
  }

  @override
  void dispose() {
    for (final node in _coatedWeightFocusNodes) {
      node.dispose();
    }
    for (final node in _coatedThicknessFocusNodes) {
      node.dispose();
    }
    for (final node in _foilWeightFocusNodes) {
      node.dispose();
    }
    for (final node in _foilThicknessFocusNodes) {
      node.dispose();
    }
    _noteController.dispose();
    super.dispose();
  }

  void _syncFocusInfrastructure(int count) {
    while (_coatedWeightFocusNodes.length < count) {
      _coatedWeightFocusNodes.add(FocusNode());
    }
    while (_coatedThicknessFocusNodes.length < count) {
      _coatedThicknessFocusNodes.add(FocusNode());
    }
    while (_foilWeightFocusNodes.length < count) {
      _foilWeightFocusNodes.add(FocusNode());
    }
    while (_foilThicknessFocusNodes.length < count) {
      _foilThicknessFocusNodes.add(FocusNode());
    }
    while (_electrodeCardKeys.length < count) {
      _electrodeCardKeys.add(GlobalKey());
    }

    while (_coatedWeightFocusNodes.length > count) {
      _coatedWeightFocusNodes.removeLast().dispose();
    }
    while (_coatedThicknessFocusNodes.length > count) {
      _coatedThicknessFocusNodes.removeLast().dispose();
    }
    while (_foilWeightFocusNodes.length > count) {
      _foilWeightFocusNodes.removeLast().dispose();
    }
    while (_foilThicknessFocusNodes.length > count) {
      _foilThicknessFocusNodes.removeLast().dispose();
    }
    while (_electrodeCardKeys.length > count) {
      _electrodeCardKeys.removeLast();
    }
  }

  void _focusNextElectrode(Experiment experiment, int currentIndex) {
    final nextIndex = currentIndex + 1;
    if (nextIndex >= _coatedWeightFocusNodes.length) {
      _addElectrodes(experiment, 1, focusFirstRequiredOfLast: true);
      return;
    }

    final targetContext = _electrodeCardKeys[nextIndex].currentContext;
    if (targetContext != null) {
      Scrollable.ensureVisible(
        targetContext,
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
      );
    }

    FocusScope.of(context).requestFocus(_coatedWeightFocusNodes[nextIndex]);
  }

  void _saveNote(String value) {
    final experiment = _experiment;
    if (experiment == null) return;

    experiment.memo = value;
    _persistExperiment(experiment);
  }

  void _persistExperiment(Experiment experiment) {
    ExperimentRepository.instance.update(experiment);
    _lastSavedAt = DateTime.now();
  }

  void _openElectrodeScreen(Experiment experiment, Electrode electrode) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ElectrodeScreen(
          experiment: experiment,
          electrode: electrode,
        ),
      ),
    );
  }

  void _recalculateElectrode(Experiment experiment, Electrode electrode) {
    electrode.result = CalculationService.calculateForElectrode(
      electrode: electrode,
      activeMaterialRatioPercent: experiment.sharedValues.activeMaterialRatio,
      specificCapacity: experiment.sharedValues.specificCapacity,
      trueDensity: experiment.sharedValues.trueDensity,
      foilWeightMg: experiment.sharedValues.averageFoilWeight,
      foilThicknessUm: experiment.sharedValues.foilThickness,
      skipMode: false,
    );
  }

  void _recalculateAllElectrodes(Experiment experiment) {
    for (final electrode in experiment.electrodes) {
      _recalculateElectrode(experiment, electrode);
    }
  }

  void _addElectrodes(
    Experiment experiment,
    int count, {
    bool focusFirstRequiredOfLast = false,
  }) {
    final safeCount = count < 1 ? 1 : count;
    final start = experiment.electrodes.length;

    for (var i = 0; i < safeCount; i++) {
      final electrode = Electrode(
        number: start + i + 1,
        input: ElectrodeInput(
          diameter: experiment.sharedValues.electrodeDiameter,
          thickness: experiment.sharedValues.foilThickness,
          collectorMass: experiment.sharedValues.averageFoilWeight,
        ),
        result: CalculationResult(),
      );
      _recalculateElectrode(experiment, electrode);
      experiment.electrodes.add(electrode);
    }

    _persistExperiment(experiment);
    setState(() {});

    if (focusFirstRequiredOfLast) {
      final targetIndex = experiment.electrodes.length - 1;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _syncFocusInfrastructure(experiment.electrodes.length);
        if (targetIndex >= 0 && targetIndex < _coatedWeightFocusNodes.length) {
          final targetContext = _electrodeCardKeys[targetIndex].currentContext;
          if (targetContext != null) {
            Scrollable.ensureVisible(
              targetContext,
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOut,
            );
          }
          FocusScope.of(context).requestFocus(_coatedWeightFocusNodes[targetIndex]);
        }
      });
    }
  }

  void _deleteElectrode(Experiment experiment, int index) {
    if (index < 0 || index >= experiment.electrodes.length) return;
    experiment.electrodes.removeAt(index);

    for (var i = 0; i < experiment.electrodes.length; i++) {
      experiment.electrodes[i].number = i + 1;
    }

    _persistExperiment(experiment);
    setState(() {});
  }

  Future<void> _showAddElectrodesBottomSheet(Experiment experiment) async {
    final countController = TextEditingController(text: '5');

    await showModalBottomSheet<void>(
      context: context,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Add Electrodes',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        _addElectrodes(experiment, 1);
                      },
                      icon: const Icon(Icons.add),
                      label: const Text('Add 1'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        _addElectrodes(experiment, 5);
                      },
                      icon: const Icon(Icons.queue),
                      label: const Text('Add 5'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: countController,
                keyboardType: const TextInputType.numberWithOptions(decimal: false),
                decoration: InputDecoration(
                  labelText: 'Custom Count',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    final parsed = int.tryParse(countController.text) ?? 1;
                    Navigator.pop(context);
                    _addElectrodes(experiment, parsed);
                  },
                  child: const Text('Add'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final experiment = _experiment;

    if (experiment == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Experiment')),
        body: const Center(child: Text('-')),
      );
    }

    _syncFocusInfrastructure(experiment.electrodes.length);

    return Scaffold(
      appBar: AppBar(
        title: Text(experiment.name),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => BatchCalculatorScreen(
                    experiment: experiment,
                  ),
                ),
              );
            },
            icon: const Icon(Icons.calculate_outlined),
            tooltip: 'Batch Calculator',
          ),
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => CompareScreen(experiment: experiment),
                ),
              );
            },
            icon: const Icon(Icons.bar_chart),
            tooltip: 'Compare',
          ),
          PopupMenuButton<String>(
            onSelected: (value) async {
              try {
                String path = '';
                if (value == 'csv') {
                  path = await ExportHelper.instance.exportExperimentCsv(experiment);
                } else if (value == 'xlsx') {
                  path = await ExportHelper.instance.exportExperimentXlsx(experiment);
                } else if (value == 'pdf') {
                  path = await ExportHelper.instance.exportExperimentPdf(experiment);
                }
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Exported: $path')));
              } catch (e) {
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Export failed: $e')));
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'csv', child: Text('Export CSV')),
              const PopupMenuItem(value: 'xlsx', child: Text('Export Excel')),
              const PopupMenuItem(value: 'pdf', child: Text('Export PDF')),
            ],
            icon: const Icon(Icons.download),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Align(
            alignment: Alignment.centerRight,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                _lastSavedAt == null
                    ? 'Saved'
                    : 'Saved ${_lastSavedAt!.hour.toString().padLeft(2, '0')}:${_lastSavedAt!.minute.toString().padLeft(2, '0')}:${_lastSavedAt!.second.toString().padLeft(2, '0')}',
                style: const TextStyle(fontSize: 12, color: Colors.green),
              ),
            ),
          ),
          const SizedBox(height: 8),
          _SummaryCard(title: 'Experiment Name', value: experiment.name),
          const SizedBox(height: 12),
          _SummaryCard(
            title: 'Protocol',
            value: experiment.protocolName ?? '-',
          ),
          const SizedBox(height: 12),
          _SummaryCard(
            title: 'Created Date',
            value: experiment.createdAt.toLocal().toString().split('.').first,
          ),
          const SizedBox(height: 12),
          _SummaryCard(
            title: 'Status',
            value: experiment.status.name,
          ),
          const SizedBox(height: 24),
          const Text(
            'Experiment Note',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _noteController,
            maxLines: 5,
            onChanged: _saveNote,
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Shared Values',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          _NumericSharedValueCard(
            title: 'Electrode Diameter (mm)',
            value: experiment.sharedValues.electrodeDiameter,
            onChanged: (value) {
              experiment.sharedValues.electrodeDiameter = value;
              for (final electrode in experiment.electrodes) {
                if (!electrode.hasOverride('electrodeDiameter')) {
                  electrode.input.diameter = value;
                }
              }
              _recalculateAllElectrodes(experiment);
              _persistExperiment(experiment);
              setState(() {});
            },
          ),
          _TextSharedValueCard(
            title: 'Collector Preset',
            value: experiment.sharedValues.collectorPreset,
            onChanged: (value) {
              if (value.trim().isEmpty) return;
              experiment.sharedValues.collectorPreset = value.trim();
              experiment.sharedValues.collector = experiment.sharedValues.collector.copyWith(
                name: value.trim(),
              );
              _persistExperiment(experiment);
              setState(() {});
            },
          ),
          _TextSharedValueCard(
            title: 'Active Material',
            value: experiment.sharedValues.activeMaterial,
            onChanged: (value) {
              if (value.trim().isEmpty) return;
              experiment.sharedValues.activeMaterial = value.trim();
              _persistExperiment(experiment);
              setState(() {});
            },
          ),
          _NumericSharedValueCard(
            title: 'Foil Thickness (μm)',
            value: experiment.sharedValues.foilThickness,
            onChanged: (value) {
              experiment.sharedValues.foilThickness = value;
              for (final electrode in experiment.electrodes) {
                if (!electrode.hasOverride('foilThickness')) {
                  electrode.input.thickness = value;
                }
              }
              _recalculateAllElectrodes(experiment);
              _persistExperiment(experiment);
              setState(() {});
            },
          ),
          _NumericSharedValueCard(
            title: 'Average Foil Weight (mg)',
            value: experiment.sharedValues.averageFoilWeight,
            onChanged: (value) {
              experiment.sharedValues.averageFoilWeight = value;
              for (final electrode in experiment.electrodes) {
                if (!electrode.hasOverride('averageFoilWeight')) {
                  electrode.input.collectorMass = value;
                }
              }
              _recalculateAllElectrodes(experiment);
              _persistExperiment(experiment);
              setState(() {});
            },
          ),
          _NumericSharedValueCard(
            title: 'Active Material Ratio (%)',
            value: experiment.sharedValues.activeMaterialRatio,
            onChanged: (value) {
              experiment.sharedValues.activeMaterialRatio = value;
              _recalculateAllElectrodes(experiment);
              _persistExperiment(experiment);
              setState(() {});
            },
          ),
          _NumericSharedValueCard(
            title: 'Conductive Additive Ratio (%)',
            value: experiment.sharedValues.conductiveAdditiveRatio,
            onChanged: (value) {
              experiment.sharedValues.conductiveAdditiveRatio = value;
              _persistExperiment(experiment);
              setState(() {});
            },
          ),
          _NumericSharedValueCard(
            title: 'Binder Ratio (%)',
            value: experiment.sharedValues.binderRatio,
            onChanged: (value) {
              experiment.sharedValues.binderRatio = value;
              _persistExperiment(experiment);
              setState(() {});
            },
          ),
          _NumericSharedValueCard(
            title: 'Specific Capacity (mAh/g)',
            value: experiment.sharedValues.specificCapacity,
            onChanged: (value) {
              experiment.sharedValues.specificCapacity = value;
              _recalculateAllElectrodes(experiment);
              _persistExperiment(experiment);
              setState(() {});
            },
          ),
          _NumericSharedValueCard(
            title: 'True Density (g/cm³)',
            value: experiment.sharedValues.trueDensity,
            onChanged: (value) {
              experiment.sharedValues.trueDensity = value;
              _recalculateAllElectrodes(experiment);
              _persistExperiment(experiment);
              setState(() {});
            },
          ),
          SwitchListTile(
            value: experiment.sharedValues.pressEnabled,
            title: const Text('Press Enabled'),
            onChanged: (value) {
              experiment.sharedValues.pressEnabled = value;
              if (!value) {
                experiment.sharedValues.targetPorosity = 0;
              }
              _recalculateAllElectrodes(experiment);
              _persistExperiment(experiment);
              setState(() {});
            },
          ),
          if (experiment.sharedValues.pressEnabled)
            _NumericSharedValueCard(
              title: 'Target Porosity (%)',
              value: experiment.sharedValues.targetPorosity,
              onChanged: (value) {
                experiment.sharedValues.targetPorosity = value;
                _recalculateAllElectrodes(experiment);
                _persistExperiment(experiment);
                setState(() {});
              },
            ),
          const SizedBox(height: 24),
          const Text(
            'Electrodes',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          if (experiment.electrodes.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(18),
                child: Center(child: Text('No Electrode')),
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: experiment.electrodes.length,
              itemBuilder: (context, index) {
                final electrode = experiment.electrodes[index];
                final pressEnabled = electrode.resolveSharedBool(
                  Electrode.keyPressEnabled,
                  experiment.sharedValues,
                );
                final targetPorosity = electrode.resolveSharedNumber(
                  Electrode.keyTargetPorosity,
                  experiment.sharedValues,
                );
                final trueDensity = electrode.resolveSharedNumber(
                  Electrode.keyTrueDensity,
                  experiment.sharedValues,
                );
                final pressTargetThickness = pressEnabled
                    ? CalculationService.calculateTargetThickness(
                        loadingMgPerCm2: electrode.result.loading,
                        trueDensity: trueDensity,
                        targetPorosityPercent: targetPorosity,
                      )
                    : null;

                return RepaintBoundary(
                  child: Container(
                    key: _electrodeCardKeys[index],
                    child: ElectrodeCard(
                      electrode: electrode,
                      collectorPresetSuppliesFoilValues:
                          experiment.sharedValues.averageFoilWeight > 0 &&
                          experiment.sharedValues.foilThickness > 0,
                      pressEnabled: pressEnabled,
                      pressTargetThicknessUm: pressTargetThickness,
                      sharedFoilWeight: experiment.sharedValues.averageFoilWeight,
                      sharedFoilThickness: experiment.sharedValues.foilThickness,
                      coatedWeightFocusNode: _coatedWeightFocusNodes[index],
                      coatedThicknessFocusNode: _coatedThicknessFocusNodes[index],
                      foilWeightFocusNode: _foilWeightFocusNodes[index],
                      foilThicknessFocusNode: _foilThicknessFocusNodes[index],
                      onOpenDetails: () => _openElectrodeScreen(experiment, electrode),
                      onDelete: () => _deleteElectrode(experiment, index),
                      onAdvanceToNextElectrode: () => _focusNextElectrode(experiment, index),
                      onCoatedWeightChanged: (value) {
                        electrode.input.totalMass = value;
                        _recalculateElectrode(experiment, electrode);
                        _persistExperiment(experiment);
                        setState(() {});
                      },
                      onCoatedThicknessChanged: (value) {
                        electrode.input.thickness = value;
                        _recalculateElectrode(experiment, electrode);
                        _persistExperiment(experiment);
                        setState(() {});
                      },
                      onFoilWeightOverrideChanged: (value) {
                        if (value == null) {
                          electrode.clearOverride(Electrode.keyAverageFoilWeight);
                          electrode.input.collectorMass = experiment.sharedValues.averageFoilWeight;
                        } else {
                          electrode.input.collectorMass = value;
                          _syncNumericOverride(
                            electrode: electrode,
                            key: Electrode.keyAverageFoilWeight,
                            currentValue: value,
                            sharedValue: experiment.sharedValues.averageFoilWeight,
                          );
                        }
                        _recalculateElectrode(experiment, electrode);
                        _persistExperiment(experiment);
                        setState(() {});
                      },
                      onFoilThicknessOverrideChanged: (value) {
                        if (value == null) {
                          electrode.clearOverride(Electrode.keyFoilThickness);
                        } else {
                          _syncNumericOverride(
                            electrode: electrode,
                            key: Electrode.keyFoilThickness,
                            currentValue: value,
                            sharedValue: experiment.sharedValues.foilThickness,
                          );
                        }
                        _recalculateElectrode(experiment, electrode);
                        _persistExperiment(experiment);
                        setState(() {});
                      },
                    ),
                  ),
                );
              },
            ),
        ],
      ),
          floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          _showAddElectrodesBottomSheet(experiment);
        },
        icon: const Icon(Icons.add),
        label: const Text('Add Electrodes'),
      ),
    );
  }

  void _syncNumericOverride({
    required Electrode electrode,
    required String key,
    required double currentValue,
    required double sharedValue,
  }) {
    if (!currentValue.isFinite) return;
    if ((currentValue - sharedValue).abs() <= 1e-9) {
      electrode.clearOverride(key);
    } else {
      electrode.setOverride(key, currentValue);
    }
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final String value;

  const _SummaryCard({
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
            ),
          ),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}

class _NumericSharedValueCard extends StatelessWidget {
  final String title;
  final double value;
  final ValueChanged<double> onChanged;

  const _NumericSharedValueCard({
    required this.title,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final controller = TextEditingController(text: value.toStringAsFixed(2));

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(title),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: controller,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              onSubmitted: (text) {
                final parsed = double.tryParse(text);
                if (parsed != null) {
                  onChanged(parsed);
                }
              },
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TextSharedValueCard extends StatelessWidget {
  final String title;
  final String value;
  final ValueChanged<String> onChanged;

  const _TextSharedValueCard({
    required this.title,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final controller = TextEditingController(text: value);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(title),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: controller,
              onSubmitted: (text) {
                onChanged(text);
              },
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
