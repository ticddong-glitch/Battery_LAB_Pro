import 'package:flutter/material.dart';

import '../models/electrode.dart';
import '../models/experiment.dart';
import '../repository/export_helper.dart';
import '../sevices/calculation_service.dart';

class CompareScreen extends StatefulWidget {
  final Experiment experiment;

  const CompareScreen({super.key, required this.experiment});

  @override
  State<CompareScreen> createState() => _CompareScreenState();
}

class _CompareScreenState extends State<CompareScreen> {
  final Set<int> _selectedNumbers = <int>{};
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _minLoadingController = TextEditingController();
  final TextEditingController _maxLoadingController = TextEditingController();

  CompareSortKey _sortKey = CompareSortKey.electrodeNumber;
  bool _ascending = true;
  bool _onlyValid = false;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() => setState(() {}));
    _minLoadingController.addListener(() => setState(() {}));
    _maxLoadingController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _searchController.dispose();
    _minLoadingController.dispose();
    _maxLoadingController.dispose();
    super.dispose();
  }

  List<Electrode> get _selectedElectrodes {
    final selected = widget.experiment.electrodes.where((e) => _selectedNumbers.contains(e.number)).toList();
    selected.sort((a, b) => a.number.compareTo(b.number));
    return selected;
  }

  List<Electrode> get _visibleElectrodes {
    final list = widget.experiment.electrodes.where((e) {
      _ensureCalculated(e);

      final query = _searchController.text.trim().toLowerCase();
      final matchesQuery = query.isEmpty || 'electrode ${e.number}'.contains(query);
      if (!matchesQuery) return false;

      final minLoading = double.tryParse(_minLoadingController.text);
      final maxLoading = double.tryParse(_maxLoadingController.text);
      final loading = e.result.loading;

      if (minLoading != null && loading < minLoading) return false;
      if (maxLoading != null && loading > maxLoading) return false;
      if (_onlyValid && e.result.validationMessage != null) return false;

      return true;
    }).toList();

    list.sort((a, b) {
      final cmp = _compareBySortKey(a, b);
      return _ascending ? cmp : -cmp;
    });

    return list;
  }

  int _compareBySortKey(Electrode a, Electrode b) {
    switch (_sortKey) {
      case CompareSortKey.electrodeNumber:
        return a.number.compareTo(b.number);
      case CompareSortKey.coatedWeight:
        return a.input.totalMass.compareTo(b.input.totalMass);
      case CompareSortKey.thickness:
        return a.input.thickness.compareTo(b.input.thickness);
      case CompareSortKey.loading:
        return a.result.loading.compareTo(b.result.loading);
      case CompareSortKey.arealCapacity:
        return a.result.arealCapacity.compareTo(b.result.arealCapacity);
      case CompareSortKey.electrodeDensity:
        return a.result.electrodeDensity.compareTo(b.result.electrodeDensity);
      case CompareSortKey.porosity:
        return a.result.porosity.compareTo(b.result.porosity);
    }
  }

  void _selectAllVisible(bool value) {
    for (final e in _visibleElectrodes) {
      if (value) {
        _selectedNumbers.add(e.number);
      } else {
        _selectedNumbers.remove(e.number);
      }
    }
    setState(() {});
  }

  void _ensureCalculated(Electrode e) {
    // Use calculation service to fill missing results
    if (e.result.area == 0) {
      e.result = CalculationService.calculateForElectrode(
        electrode: e,
        activeMaterialRatioPercent: widget.experiment.sharedValues.activeMaterialRatio,
        specificCapacity: widget.experiment.sharedValues.specificCapacity,
        trueDensity: widget.experiment.sharedValues.trueDensity,
        foilWeightMg: widget.experiment.sharedValues.averageFoilWeight,
        foilThicknessUm: widget.experiment.sharedValues.foilThickness,
      );
    }
  }

  String _formatNum(num v, {int decimals = 2}) => v.toDouble().toStringAsFixed(decimals);

  // Export is intentionally not implemented in this sprint. This data builder
  // provides structured rows for a future exporter.
  Map<String, List<List<String>>> _buildComparisonData() {
    final selected = _selectedElectrodes;
    final inputRows = <List<String>>[
      ['Field', ...selected.map((e) => 'E${e.number}')],
      ['Coated Weight (mg)', ...selected.map((e) => _formatNum(e.input.totalMass))],
      ['Foil Weight (mg)', ...selected.map((e) => _formatNum(e.input.collectorMass))],
      ['Diameter (mm)', ...selected.map((e) => _formatNum(e.input.diameter))],
      ['Thickness (μm)', ...selected.map((e) => _formatNum(e.input.thickness))],
    ];

    final calcRows = <List<String>>[
      ['Metric', ...selected.map((e) => 'E${e.number}')],
      ['Loading (mg/cm²)', ...selected.map((e) => _formatNum(e.result.loading))],
      ['Areal Capacity (mAh/cm²)', ...selected.map((e) => _formatNum(e.result.arealCapacity))],
      ['Electrode Density (g/cm³)', ...selected.map((e) => _formatNum(e.result.electrodeDensity))],
      ['Porosity (%)', ...selected.map((e) => _formatNum(e.result.porosity))],
    ];

    return {
      'inputs': inputRows,
      'calculated': calcRows,
    };
  }

  int _bestIndex(List<double> values, {required bool higherBetter}) {
    if (values.isEmpty) return -1;
    var idx = 0;
    for (var i = 1; i < values.length; i++) {
      final better = higherBetter ? values[i] > values[idx] : values[i] < values[idx];
      if (better) idx = i;
    }
    return idx;
  }

  bool _isDifferentFromFirst(List<double> values, int index) {
    if (values.isEmpty || index < 0 || index >= values.length) return false;
    return (values[index] - values.first).abs() > 0.0001;
  }

  DataCell _valueCell({
    required double value,
    required bool highlightBest,
    required bool highlightDiff,
  }) {
    Color? bg;
    if (highlightBest) {
      bg = Colors.green.shade100;
    } else if (highlightDiff) {
      bg = Colors.amber.shade100;
    }

    return DataCell(
      Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(_formatNum(value)),
      ),
    );
  }

  DataRow _inputRow(String label, List<double> values) {
    return DataRow(
      cells: [
        DataCell(Text(label)),
        ...List.generate(values.length, (i) {
          return _valueCell(
            value: values[i],
            highlightBest: false,
            highlightDiff: _isDifferentFromFirst(values, i),
          );
        }),
      ],
    );
  }

  DataRow _resultRow(String label, List<double> values, {required bool higherBetter}) {
    final best = _bestIndex(values, higherBetter: higherBetter);
    return DataRow(
      cells: [
        DataCell(Text(label)),
        ...List.generate(values.length, (i) {
          return _valueCell(
            value: values[i],
            highlightBest: i == best,
            highlightDiff: _isDifferentFromFirst(values, i),
          );
        }),
      ],
    );
  }

  Future<void> _exportSelected(String format) async {
    final selected = _selectedElectrodes;
    if (selected.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Select electrodes first.')));
      return;
    }

    try {
      String path;
      if (format == 'csv') {
        path = await ExportHelper.instance.exportSelectedElectrodesCsv(widget.experiment, selected);
      } else if (format == 'xlsx') {
        path = await ExportHelper.instance.exportSelectedElectrodesXlsx(widget.experiment, selected);
      } else {
        path = await ExportHelper.instance.exportSelectedElectrodesPdf(widget.experiment, selected);
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Selected exported: $path')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Export failed: $e')));
    }
  }

  Future<void> _exportCompare(String format) async {
    final selected = _selectedElectrodes;
    if (selected.length < 2) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Select at least 2 electrodes.')));
      return;
    }

    try {
      String path;
      if (format == 'csv') {
        path = await ExportHelper.instance.exportCompareResultsCsv(widget.experiment, selected);
      } else if (format == 'xlsx') {
        path = await ExportHelper.instance.exportCompareResultsXlsx(widget.experiment, selected);
      } else {
        path = await ExportHelper.instance.exportCompareResultsPdf(widget.experiment, selected);
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Compare exported: $path')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Export failed: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final electrodes = _visibleElectrodes;
    final selected = _selectedElectrodes;
    final comparisonData = _buildComparisonData();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Compare Electrodes'),
        actions: [
          TextButton(onPressed: () => _selectAllVisible(true), child: const Text('All', style: TextStyle(color: Colors.white))),
          TextButton(onPressed: () => _selectAllVisible(false), child: const Text('Clear', style: TextStyle(color: Colors.white))),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(widget.experiment.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          const Text('Filter & Sort', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          TextField(
            controller: _searchController,
            decoration: const InputDecoration(
              labelText: 'Search electrode (e.g. 1)',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _minLoadingController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: 'Min Loading', border: OutlineInputBorder()),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _maxLoadingController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: 'Max Loading', border: OutlineInputBorder()),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<CompareSortKey>(
                  initialValue: _sortKey,
                  decoration: const InputDecoration(labelText: 'Sort By', border: OutlineInputBorder()),
                  items: CompareSortKey.values
                      .map((k) => DropdownMenuItem(value: k, child: Text(k.label)))
                      .toList(),
                  onChanged: (v) {
                    if (v == null) return;
                    setState(() => _sortKey = v);
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: DropdownButtonFormField<bool>(
                  initialValue: _ascending,
                  decoration: const InputDecoration(labelText: 'Order', border: OutlineInputBorder()),
                  items: const [
                    DropdownMenuItem(value: true, child: Text('Ascending')),
                    DropdownMenuItem(value: false, child: Text('Descending')),
                  ],
                  onChanged: (v) {
                    if (v == null) return;
                    setState(() => _ascending = v);
                  },
                ),
              ),
            ],
          ),
          SwitchListTile(
            value: _onlyValid,
            onChanged: (v) => setState(() => _onlyValid = v),
            title: const Text('Show valid electrodes only'),
          ),
          const SizedBox(height: 8),
          const Text('Select electrodes to compare'),
          const SizedBox(height: 8),
          if (electrodes.isEmpty) const Card(child: Padding(padding: EdgeInsets.all(16), child: Text('No electrodes')))
          else
            ...List.generate(electrodes.length, (i) {
              final e = electrodes[i];
              return CheckboxListTile(
                value: _selectedNumbers.contains(e.number),
                title: Text('Electrode ${e.number}'),
                subtitle: Text('${e.input.totalMass} mg • ${e.input.thickness} μm • Loading ${_formatNum(e.result.loading)}'),
                onChanged: (v) {
                  if (v == true) {
                    _selectedNumbers.add(e.number);
                  } else {
                    _selectedNumbers.remove(e.number);
                  }
                  setState(() {});
                },
              );
            }),
          const SizedBox(height: 16),
          ElevatedButton(onPressed: selected.length >= 2 ? () => setState(() {}) : null, child: const Text('Generate Comparison')),
          const SizedBox(height: 16),
          if (selected.length >= 2) ...[
            const Text('Inputs', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: [
                  const DataColumn(label: Text('Field')),
                  ...selected.map((e) => DataColumn(label: Text('E${e.number}'))),
                ],
                rows: [
                  _inputRow('Coated Weight (mg)', selected.map((e) => e.input.totalMass).toList()),
                  _inputRow('Foil Weight (mg)', selected.map((e) => e.input.collectorMass).toList()),
                  _inputRow('Diameter (mm)', selected.map((e) => e.input.diameter).toList()),
                  _inputRow('Thickness (μm)', selected.map((e) => e.input.thickness).toList()),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Text('Calculated', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: [
                  const DataColumn(label: Text('Metric')),
                  ...selected.map((e) => DataColumn(label: Text('E${e.number}'))),
                ],
                rows: [
                  _resultRow('Loading (mg/cm²)', selected.map((e) => e.result.loading).toList(), higherBetter: true),
                  _resultRow('Areal Capacity (mAh/cm²)', selected.map((e) => e.result.arealCapacity).toList(), higherBetter: true),
                  _resultRow('Electrode Density (g/cm³)', selected.map((e) => e.result.electrodeDensity).toList(), higherBetter: true),
                  _resultRow('Porosity (%)', selected.map((e) => e.result.porosity).toList(), higherBetter: false),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text('Comparison table rows prepared: Inputs ${comparisonData['inputs']?.length ?? 0}, Calculated ${comparisonData['calculated']?.length ?? 0}'),
            const SizedBox(height: 8),
            PopupMenuButton<String>(
              onSelected: (v) {
                if (v == 'selected_csv') _exportSelected('csv');
                if (v == 'selected_xlsx') _exportSelected('xlsx');
                if (v == 'selected_pdf') _exportSelected('pdf');
                if (v == 'compare_csv') _exportCompare('csv');
                if (v == 'compare_xlsx') _exportCompare('xlsx');
                if (v == 'compare_pdf') _exportCompare('pdf');
              },
              itemBuilder: (context) => const [
                PopupMenuItem(value: 'selected_csv', child: Text('Export Selected - CSV')),
                PopupMenuItem(value: 'selected_xlsx', child: Text('Export Selected - Excel')),
                PopupMenuItem(value: 'selected_pdf', child: Text('Export Selected - PDF')),
                PopupMenuDivider(),
                PopupMenuItem(value: 'compare_csv', child: Text('Export Compare Results - CSV')),
                PopupMenuItem(value: 'compare_xlsx', child: Text('Export Compare Results - Excel')),
                PopupMenuItem(value: 'compare_pdf', child: Text('Export Compare Results - PDF')),
              ],
              child: ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.download),
                label: const Text('Export Options'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

enum CompareSortKey {
  electrodeNumber('Electrode Number'),
  coatedWeight('Coated Weight'),
  thickness('Thickness'),
  loading('Loading'),
  arealCapacity('Areal Capacity'),
  electrodeDensity('Electrode Density'),
  porosity('Porosity');

  final String label;
  const CompareSortKey(this.label);
}
