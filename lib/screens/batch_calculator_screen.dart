import 'dart:io';

import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/calculation_result.dart';
import '../models/electrode.dart';
import '../models/electrode_input.dart';
import '../models/experiment.dart';
import '../repository/experiment_repository.dart';
import '../sevices/calculation_service.dart';

class _ImportedMeasurementRow {
  final int electrodeId;
  final double coatedWeightMg;
  final double coatedThicknessUm;
  final double diameterMm;

  const _ImportedMeasurementRow({
    required this.electrodeId,
    required this.coatedWeightMg,
    required this.coatedThicknessUm,
    required this.diameterMm,
  });
}

class _ImportParseResult {
  final List<_ImportedMeasurementRow> rows;
  final int invalidRowCount;
  final int duplicateRowCount;
  final bool mappedByHeader;

  const _ImportParseResult({
    required this.rows,
    required this.invalidRowCount,
    required this.duplicateRowCount,
    required this.mappedByHeader,
  });
}

class BatchCalculatorScreen extends StatefulWidget {
  final Experiment experiment;

  const BatchCalculatorScreen({
    super.key,
    required this.experiment,
  });

  @override
  State<BatchCalculatorScreen> createState() => _BatchCalculatorScreenState();
}

class _BatchCalculatorScreenState extends State<BatchCalculatorScreen> {
  late final List<TextEditingController> _coatedWeightControllers;
  late final List<TextEditingController> _coatedThicknessControllers;
  final Set<int> _selectedIndexes = {};
  final TextEditingController _fastAddController = TextEditingController(text: '1');

  @override
  void initState() {
    super.initState();
    _coatedWeightControllers = List.generate(
      widget.experiment.electrodes.length,
      (index) => TextEditingController(
        text: widget.experiment.electrodes[index].input.totalMass.toStringAsFixed(2),
      ),
    );
    _coatedThicknessControllers = List.generate(
      widget.experiment.electrodes.length,
      (index) => TextEditingController(
        text: widget.experiment.electrodes[index].input.thickness.toStringAsFixed(2),
      ),
    );
    _calculateAll();
  }

  @override
  void dispose() {
    for (final controller in _coatedWeightControllers) {
      controller.dispose();
    }
    for (final controller in _coatedThicknessControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _calculateAll() {
    final experiment = widget.experiment;
    final shared = experiment.sharedValues;

    for (var index = 0; index < experiment.electrodes.length; index++) {
      final electrode = experiment.electrodes[index];

      electrode.input.totalMass =
          double.tryParse(_coatedWeightControllers[index].text) ?? electrode.input.totalMass;
      electrode.input.thickness =
          double.tryParse(_coatedThicknessControllers[index].text) ?? electrode.input.thickness;

      electrode.result = CalculationService.calculateForElectrode(
        electrode: electrode,
        activeMaterialRatioPercent: shared.activeMaterialRatio,
        specificCapacity: shared.specificCapacity,
        trueDensity: shared.trueDensity,
        foilWeightMg: shared.averageFoilWeight,
        foilThicknessUm: shared.foilThickness,
      );
    }

    ExperimentRepository.instance.update(experiment);
    if (mounted) {
      setState(() {});
    }
  }

  void _addElectrode({int count = 1}) {
    final experiment = widget.experiment;
    final startingIndex = experiment.electrodes.length + 1;

    for (var i = 0; i < count; i++) {
      final electrodeNumber = startingIndex + i;
      final electrode = Electrode(
        number: electrodeNumber,
        input: ElectrodeInput(
          totalMass: 0,
          collectorMass: experiment.sharedValues.averageFoilWeight,
          diameter: experiment.sharedValues.electrodeDiameter,
          thickness: experiment.sharedValues.foilThickness,
        ),
        result: CalculationResult(),
      );

      electrode.result = CalculationService.calculateForElectrode(
        electrode: electrode,
        activeMaterialRatioPercent: experiment.sharedValues.activeMaterialRatio,
        specificCapacity: experiment.sharedValues.specificCapacity,
        trueDensity: experiment.sharedValues.trueDensity,
        foilWeightMg: experiment.sharedValues.averageFoilWeight,
        foilThicknessUm: experiment.sharedValues.foilThickness,
      );

      experiment.electrodes.add(electrode);
      _coatedWeightControllers.add(
        TextEditingController(text: electrode.input.totalMass.toStringAsFixed(2)),
      );
      _coatedThicknessControllers.add(
        TextEditingController(text: electrode.input.thickness.toStringAsFixed(2)),
      );
    }

    ExperimentRepository.instance.update(experiment);
    if (mounted) {
      setState(() {});
    }
  }

  void _deleteSelected() {
    final experiment = widget.experiment;
    final indexes = _selectedIndexes.toList()..sort((a, b) => b.compareTo(a));
    for (final idx in indexes) {
      experiment.electrodes.removeAt(idx);
      _coatedWeightControllers.removeAt(idx).dispose();
      _coatedThicknessControllers.removeAt(idx).dispose();
    }
    _selectedIndexes.clear();
    // renumber
    for (var i = 0; i < experiment.electrodes.length; i++) {
      experiment.electrodes[i].number = i + 1;
    }
    ExperimentRepository.instance.update(experiment);
    if (mounted) setState(() {});
  }

  void _duplicateSelected() {
    final experiment = widget.experiment;
    final indexes = _selectedIndexes.toList()..sort();
    // duplicate in order after each selected index
    for (var offset = 0; offset < indexes.length; offset++) {
      final idx = indexes[offset] + offset;
      final src = experiment.electrodes[idx];
      final dup = Electrode(
        number: idx + 2,
        input: ElectrodeInput(
          totalMass: src.input.totalMass,
          collectorMass: src.input.collectorMass,
          diameter: src.input.diameter,
          thickness: src.input.thickness,
        ),
        result: CalculationResult(),
      );
      dup.result = CalculationService.calculateForElectrode(
        electrode: dup,
        activeMaterialRatioPercent: experiment.sharedValues.activeMaterialRatio,
        specificCapacity: experiment.sharedValues.specificCapacity,
        trueDensity: experiment.sharedValues.trueDensity,
        foilWeightMg: experiment.sharedValues.averageFoilWeight,
        foilThicknessUm: experiment.sharedValues.foilThickness,
      );
      experiment.electrodes.insert(idx + 1, dup);
      _coatedWeightControllers.insert(idx + 1, TextEditingController(text: dup.input.totalMass.toStringAsFixed(2)));
      _coatedThicknessControllers.insert(idx + 1, TextEditingController(text: dup.input.thickness.toStringAsFixed(2)));
    }
    // renumber
    for (var i = 0; i < experiment.electrodes.length; i++) {
      experiment.electrodes[i].number = i + 1;
    }
    ExperimentRepository.instance.update(experiment);
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _pasteFromClipboard() async {
    final data = await Clipboard.getData('text/plain');
    if (data == null) {
      return;
    }
    final text = data.text ?? '';
    if (text.trim().isEmpty) {
      return;
    }
    final grid = _parseDelimitedText(text);
    final parsed = _parseImportGrid(grid);

    if (parsed.rows.isNotEmpty) {
      _applyImportedRows(parsed, source: 'Clipboard');
      return;
    }

    // Fallback mode: if plain numeric values are pasted, treat them as coated weights.
    final values = <double>[];
    final lines = text.split(RegExp(r'\r?\n'));
    for (final line in lines) {
      if (line.trim().isEmpty) {
        continue;
      }
      final parts = line.split(RegExp(r'[\t,; ]+'));
      for (final p in parts) {
        final v = _parseDoubleToken(p);
        if (v != null) {
          values.add(v);
        }
      }
    }
    if (values.isEmpty) {
      _showImportSummary('Clipboard import failed: no valid rows detected.');
      return;
    }

    final experiment = widget.experiment;
    if (_selectedIndexes.isNotEmpty) {
      final idxs = _selectedIndexes.toList()..sort();
      for (var i = 0; i < idxs.length && i < values.length; i++) {
        final idx = idxs[i];
        experiment.electrodes[idx].input.totalMass = values[i];
      }
      _rebuildControllersFromElectrodes();
      _calculateAll();
      _showImportSummary('Clipboard import applied as coated weight values.');
      return;
    }

    for (final v in values) {
      final next = experiment.electrodes.length + 1;
      experiment.electrodes.add(
        Electrode(
          number: next,
          input: ElectrodeInput(
            totalMass: v,
            collectorMass: experiment.sharedValues.averageFoilWeight,
            diameter: experiment.sharedValues.electrodeDiameter,
            thickness: experiment.sharedValues.foilThickness,
          ),
          result: CalculationResult(),
        ),
      );
    }

    _rebuildControllersFromElectrodes();
    _calculateAll();
    _showImportSummary('Clipboard import added ${values.length} electrodes as weight-only data.');
  }

  Future<void> _importCsvFile() async {
    final picked = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['csv', 'txt'],
      withData: false,
    );
    if (picked == null || picked.files.isEmpty) {
      return;
    }

    final path = picked.files.single.path;
    if (path == null || path.isEmpty) {
      _showImportSummary('CSV import failed: file path is missing.');
      return;
    }

    final text = await File(path).readAsString();
    final parsed = _parseImportGrid(_parseDelimitedText(text));
    _applyImportedRows(parsed, source: 'CSV');
  }

  Future<void> _importExcelFile() async {
    final picked = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['xlsx', 'xls'],
      withData: true,
    );
    if (picked == null || picked.files.isEmpty) {
      return;
    }

    final file = picked.files.single;
    Uint8List? bytes = file.bytes;
    if (bytes == null && file.path != null && file.path!.isNotEmpty) {
      bytes = await File(file.path!).readAsBytes();
    }

    if (bytes == null || bytes.isEmpty) {
      _showImportSummary('Excel import failed: file is empty.');
      return;
    }

    final grid = _parseExcelGrid(bytes);
    final parsed = _parseImportGrid(grid);
    _applyImportedRows(parsed, source: 'Excel');
  }

  List<List<String>> _parseDelimitedText(String text) {
    final lines = text.split(RegExp(r'\r?\n')).where((line) => line.trim().isNotEmpty).toList();
    if (lines.isEmpty) {
      return const [];
    }

    final probe = lines.first;
    String delimiter;
    if (probe.contains('\t')) {
      delimiter = '\t';
    } else {
      final semicolonCount = ';'.allMatches(probe).length;
      final commaCount = ','.allMatches(probe).length;
      delimiter = semicolonCount > commaCount ? ';' : ',';
    }

    return lines
        .map(
          (line) => line
              .split(delimiter)
              .map((cell) => cell.trim().replaceAll('"', ''))
              .toList(),
        )
        .toList();
  }

  List<List<String>> _parseExcelGrid(Uint8List bytes) {
    final workbook = Excel.decodeBytes(bytes);
    for (final table in workbook.tables.values) {
      final rows = <List<String>>[];
      for (final row in table.rows) {
        rows.add(row.map((cell) => cell?.value?.toString().trim() ?? '').toList());
      }
      if (rows.any((r) => r.any((v) => v.isNotEmpty))) {
        return rows;
      }
    }
    return const [];
  }

  _ImportParseResult _parseImportGrid(List<List<String>> grid) {
    if (grid.isEmpty) {
      return const _ImportParseResult(
        rows: [],
        invalidRowCount: 0,
        duplicateRowCount: 0,
        mappedByHeader: false,
      );
    }

    final first = grid.first;
    final normalizedHeader = first.map(_normalizeHeader).toList();

    int mapIndex(Set<String> aliases) {
      for (var i = 0; i < normalizedHeader.length; i++) {
        if (aliases.contains(normalizedHeader[i])) return i;
      }
      return -1;
    }

    final idCol = mapIndex({
      'electrodeid',
      'electrode',
      'electrodenumber',
      'id',
      'sampleid',
      'sample',
      'electrode#',
      'electrode no',
    });
    final weightCol = mapIndex({
      'coatedweight',
      'coatedmass',
      'weight',
      'totalmass',
      'coatedweightmg',
      'massmg',
    });
    final thicknessCol = mapIndex({
      'coatedthickness',
      'thickness',
      'coatedthicknessum',
      'thicknessum',
    });
    final diameterCol = mapIndex({
      'diameter',
      'diametermm',
      'electrodediameter',
    });

    final hasHeaderMapping = idCol >= 0 && weightCol >= 0 && thicknessCol >= 0 && diameterCol >= 0;

    final rows = <_ImportedMeasurementRow>[];
    final seenIds = <int>{};
    var invalidRowCount = 0;
    var duplicateRowCount = 0;

    final startRow = hasHeaderMapping ? 1 : 0;
    for (var i = startRow; i < grid.length; i++) {
      final row = grid[i];
      if (row.every((v) => v.trim().isEmpty)) {
        continue;
      }

      final colId = hasHeaderMapping ? idCol : 0;
      final colWeight = hasHeaderMapping ? weightCol : 1;
      final colThickness = hasHeaderMapping ? thicknessCol : 2;
      final colDiameter = hasHeaderMapping ? diameterCol : 3;

      if (row.length <= colDiameter) {
        invalidRowCount += 1;
        continue;
      }

      final electrodeId = _parseElectrodeIdToken(row[colId]);
      final coatedWeight = _parseDoubleToken(row[colWeight]);
      final coatedThickness = _parseDoubleToken(row[colThickness]);
      final diameter = _parseDoubleToken(row[colDiameter]);

      if (electrodeId == null || coatedWeight == null || coatedThickness == null || diameter == null) {
        invalidRowCount += 1;
        continue;
      }

      if (electrodeId <= 0 || coatedWeight <= 0 || coatedThickness <= 0 || diameter <= 0) {
        invalidRowCount += 1;
        continue;
      }

      if (seenIds.contains(electrodeId)) {
        duplicateRowCount += 1;
        continue;
      }
      seenIds.add(electrodeId);

      rows.add(
        _ImportedMeasurementRow(
          electrodeId: electrodeId,
          coatedWeightMg: coatedWeight,
          coatedThicknessUm: coatedThickness,
          diameterMm: diameter,
        ),
      );
    }

    return _ImportParseResult(
      rows: rows,
      invalidRowCount: invalidRowCount,
      duplicateRowCount: duplicateRowCount,
      mappedByHeader: hasHeaderMapping,
    );
  }

  int? _parseElectrodeIdToken(String raw) {
    final s = raw.trim();
    if (s.isEmpty) {
      return null;
    }
    final direct = int.tryParse(s);
    if (direct != null) {
      return direct;
    }

    final match = RegExp(r'\d+').firstMatch(s);
    if (match == null) {
      return null;
    }
    return int.tryParse(match.group(0)!);
  }

  double? _parseDoubleToken(String raw) {
    final s = raw.trim();
    if (s.isEmpty) {
      return null;
    }

    final commaDecimal = RegExp(r'^-?\d+,\d+$');
    final normalized = commaDecimal.hasMatch(s) ? s.replaceAll(',', '.') : s;
    return double.tryParse(normalized);
  }

  String _normalizeHeader(String header) {
    return header.toLowerCase().replaceAll(RegExp(r'[^a-z0-9#]+'), '');
  }

  void _applyImportedRows(_ImportParseResult parsed, {required String source}) {
    if (parsed.rows.isEmpty) {
      _showImportSummary(
        '$source import: no valid rows found. '
        'Invalid rows: ${parsed.invalidRowCount}, duplicates: ${parsed.duplicateRowCount}.',
      );
      return;
    }

    final experiment = widget.experiment;
    final existingById = <int, Electrode>{
      for (final electrode in experiment.electrodes) electrode.number: electrode,
    };

    var updated = 0;
    var added = 0;

    for (final row in parsed.rows) {
      final existing = existingById[row.electrodeId];
      if (existing != null) {
        existing.input.totalMass = row.coatedWeightMg;
        existing.input.thickness = row.coatedThicknessUm;
        existing.input.diameter = row.diameterMm;
        updated += 1;
        continue;
      }

      final newElectrode = Electrode(
        number: row.electrodeId,
        input: ElectrodeInput(
          totalMass: row.coatedWeightMg,
          collectorMass: experiment.sharedValues.averageFoilWeight,
          diameter: row.diameterMm,
          thickness: row.coatedThicknessUm,
        ),
        result: CalculationResult(),
      );
      experiment.electrodes.add(newElectrode);
      added += 1;
    }

    experiment.electrodes.sort((a, b) => a.number.compareTo(b.number));
    _rebuildControllersFromElectrodes();
    _calculateAll();

    final summary = StringBuffer()
      ..write('$source import completed. Added: $added, updated: $updated')
      ..write(', invalid rows: ${parsed.invalidRowCount}')
      ..write(', duplicate rows: ${parsed.duplicateRowCount}');
    if (!parsed.mappedByHeader) {
      summary.write('. Header map not found; positional mapping used (ID, Weight, Thickness, Diameter).');
    }

    _showImportSummary(summary.toString());
  }

  void _rebuildControllersFromElectrodes() {
    for (final controller in _coatedWeightControllers) {
      controller.dispose();
    }
    for (final controller in _coatedThicknessControllers) {
      controller.dispose();
    }
    _coatedWeightControllers
      ..clear()
      ..addAll(
        widget.experiment.electrodes.map(
          (e) => TextEditingController(text: e.input.totalMass.toStringAsFixed(2)),
        ),
      );
    _coatedThicknessControllers
      ..clear()
      ..addAll(
        widget.experiment.electrodes.map(
          (e) => TextEditingController(text: e.input.thickness.toStringAsFixed(2)),
        ),
      );
  }

  void _showImportSummary(String message) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _applyToSelected({required bool applyWeight}) async {
    if (_selectedIndexes.isEmpty) {
      return;
    }
    final controller = TextEditingController();
    final result = await showDialog<double?>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(applyWeight ? 'Apply Coated Weight' : 'Apply Coated Thickness'),
        content: TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(hintText: 'Value'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, double.tryParse(controller.text)),
            child: const Text('Apply'),
          ),
        ],
      ),
    );

    if (result == null) {
      return;
    }
    final idxs = _selectedIndexes.toList();
    for (final idx in idxs) {
      if (applyWeight) {
        widget.experiment.electrodes[idx].input.totalMass = result;
        _coatedWeightControllers[idx].text = result.toStringAsFixed(2);
      } else {
        widget.experiment.electrodes[idx].input.thickness = result;
        _coatedThicknessControllers[idx].text = result.toStringAsFixed(2);
      }
    }
    _calculateAll();
  }

  @override
  Widget build(BuildContext context) {
    final experiment = widget.experiment;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Batch Calculator'),
        actions: [
          TextButton.icon(
            onPressed: _calculateAll,
            icon: const Icon(Icons.calculate_rounded),
            label: const Text('Calculate All'),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _SharedValueSummary(
              values: {
                'Active Material': '${widget.experiment.sharedValues.activeMaterialRatio} %',
                'Specific Capacity': '${widget.experiment.sharedValues.specificCapacity} mAh/g',
                'True Density': '${widget.experiment.sharedValues.trueDensity} g/cm³',
                'Diameter': '${widget.experiment.sharedValues.electrodeDiameter} mm',
                'Foil Weight': '${widget.experiment.sharedValues.averageFoilWeight} mg',
                'Foil Thickness': '${widget.experiment.sharedValues.foilThickness} μm',
              },
            ),
            const SizedBox(height: 16),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                ElevatedButton.icon(
                  onPressed: () => _addElectrode(count: 1),
                  icon: const Icon(Icons.add),
                  label: const Text('Add Electrode'),
                ),
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  onPressed: () => _addElectrode(count: 5),
                  icon: const Icon(Icons.queue),
                  label: const Text('Add 5'),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: 100,
                  child: TextField(
                    controller: _fastAddController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: false),
                    decoration: const InputDecoration(isDense: true, labelText: 'Fast Add'),
                    onSubmitted: (s) {
                      final n = int.tryParse(s) ?? 1;
                      _addElectrode(count: n);
                    },
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: _duplicateSelected,
                  icon: const Icon(Icons.copy),
                  label: const Text('Duplicate'),
                ),
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  onPressed: _deleteSelected,
                  icon: const Icon(Icons.delete),
                  label: const Text('Delete'),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: () => _applyToSelected(applyWeight: true),
                  icon: const Icon(Icons.arrow_forward_ios),
                  label: const Text('Apply Weight'),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: () => _applyToSelected(applyWeight: false),
                  icon: const Icon(Icons.arrow_forward_ios),
                  label: const Text('Apply Thickness'),
                ),
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  onPressed: _pasteFromClipboard,
                  icon: const Icon(Icons.paste),
                  label: const Text('Paste'),
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: _importCsvFile,
                  icon: const Icon(Icons.file_open),
                  label: const Text('Import CSV'),
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: _importExcelFile,
                  icon: const Icon(Icons.table_view),
                  label: const Text('Import Excel'),
                ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: const [
                  DataColumn(label: Text('Electrode')),
                  DataColumn(label: Text('Coated Weight\n(mg)')),
                  DataColumn(label: Text('Coated Thickness\n(μm)')),
                  DataColumn(label: Text('Loading\n(mg/cm²)')),
                  DataColumn(label: Text('Areal Capacity\n(mAh/cm²)')),
                  DataColumn(label: Text('Density\n(g/cm³)')),
                  DataColumn(label: Text('Porosity\n(%)')),
                ],
                rows: List<DataRow>.generate(
                  experiment.electrodes.length,
                  (index) {
                    final electrode = experiment.electrodes[index];
                    final result = electrode.result;

                    return DataRow(
                      selected: _selectedIndexes.contains(index),
                      onSelectChanged: (v) {
                        if (v == true) {
                          _selectedIndexes.add(index);
                        } else {
                          _selectedIndexes.remove(index);
                        }
                        if (mounted) {
                          setState(() {});
                        }
                      },
                      cells: [
                        DataCell(Text('E${electrode.number}')),
                        DataCell(
                          SizedBox(
                            width: 110,
                            child: TextField(
                              controller: _coatedWeightControllers[index],
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              onChanged: (_) {
                                _calculateAll();
                              },
                              decoration: const InputDecoration(
                                isDense: true,
                              ),
                            ),
                          ),
                        ),
                        DataCell(
                          SizedBox(
                            width: 110,
                            child: TextField(
                              controller: _coatedThicknessControllers[index],
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              onChanged: (_) {
                                _calculateAll();
                              },
                              decoration: const InputDecoration(
                                isDense: true,
                              ),
                            ),
                          ),
                        ),
                        DataCell(Text(result.loading.toStringAsFixed(2))),
                        DataCell(Text(result.arealCapacity.toStringAsFixed(2))),
                        DataCell(Text(result.electrodeDensity.toStringAsFixed(2))),
                        DataCell(Text(result.porosity.toStringAsFixed(2))),
                      ],
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SharedValueSummary extends StatelessWidget {
  final Map<String, String> values;

  const _SharedValueSummary({required this.values});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Shared Values',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: values.entries
                .map(
                  (entry) => Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text('${entry.key}: ${entry.value}'),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }
}
