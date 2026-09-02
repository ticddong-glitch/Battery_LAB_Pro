import 'dart:io';
import 'package:path/path.dart' as p;

import '../models/experiment.dart';
import '../models/electrode.dart';
import 'preferences_repository.dart';

class ExportHelper {
  ExportHelper._();
  static final ExportHelper instance = ExportHelper._();

  Future<String> _targetDir() async {
    final preferred = PreferencesRepository.instance.current.defaultExportFolder.trim();
    if (preferred.isNotEmpty) {
      final configured = Directory(preferred);
      if (!await configured.exists()) await configured.create(recursive: true);
      return configured.path;
    }

    final home = Platform.environment['USERPROFILE'] ?? Platform.environment['HOME'] ?? Directory.current.path;
    final docs = p.join(home, 'Documents');
    final exportDir = Directory(p.join(docs, 'lab_exports'));
    if (!await exportDir.exists()) await exportDir.create(recursive: true);
    return exportDir.path;
  }

  String _safe(String s) => s.replaceAll(RegExp(r'[^A-Za-z0-9_\-]'), '_');

  String _stamp() {
    final now = DateTime.now();
    final y = now.year.toString().padLeft(4, '0');
    final m = now.month.toString().padLeft(2, '0');
    final d = now.day.toString().padLeft(2, '0');
    final hh = now.hour.toString().padLeft(2, '0');
    final mm = now.minute.toString().padLeft(2, '0');
    final ss = now.second.toString().padLeft(2, '0');
    return '$y$m$d' '_$hh$mm$ss';
  }

  Future<String> _writeTextFile({
    required String baseName,
    required String extension,
    required String content,
  }) async {
    final dir = await _targetDir();
    final path = p.join(dir, '$baseName.$extension');
    final file = File(path);
    await file.writeAsString(content);
    return path;
  }

  String _buildExperimentCsv(Experiment exp, List<Electrode> electrodes) {
    final sb = StringBuffer();
    final s = exp.sharedValues;
    sb.writeln('Experiment,${exp.name}');
    sb.writeln('Created,${exp.createdAt.toIso8601String()}');
    sb.writeln('Protocol,${exp.protocolName ?? ''}');
    sb.writeln('Protocol Version,${exp.protocolVersion ?? ''}');
    sb.writeln();
    sb.writeln('Shared Values');
    sb.writeln('Diameter (mm),${s.electrodeDiameter}');
    sb.writeln('Foil Thickness (um),${s.foilThickness}');
    sb.writeln('Current Collector,${s.collector.name}');
    sb.writeln('Average Foil Weight (mg),${s.averageFoilWeight}');
    sb.writeln('Specific Capacity (mAh/g),${s.specificCapacity}');
    sb.writeln('True Density (g/cm3),${s.trueDensity}');
    sb.writeln('Active Ratio (%),${s.activeMaterialRatio}');
    sb.writeln('Conductive Ratio (%),${s.conductiveAdditiveRatio}');
    sb.writeln('Binder Ratio (%),${s.binderRatio}');
    sb.writeln();
    sb.writeln('Electrode Number,Total Mass (mg),Collector Mass (mg),Diameter (mm),Thickness (um),Loading (mg/cm2),Areal Capacity (mAh/cm2),Density (g/cm3),Porosity (%)');
    for (final e in electrodes) {
      sb.writeln('E${e.number},${e.input.totalMass},${e.input.collectorMass},${e.input.diameter},${e.input.thickness},${e.result.loading},${e.result.arealCapacity},${e.result.electrodeDensity},${e.result.porosity}');
    }
    return sb.toString();
  }

  String _buildCompareCsv(Experiment exp, List<Electrode> selected) {
    final sb = StringBuffer();
    sb.writeln('Experiment,${exp.name}');
    sb.writeln('Generated,${DateTime.now().toIso8601String()}');
    sb.writeln();
    sb.writeln('Compare Inputs');
    sb.writeln('Field,${selected.map((e) => 'E${e.number}').join(',')}');
    sb.writeln('Coated Weight (mg),${selected.map((e) => e.input.totalMass).join(',')}');
    sb.writeln('Foil Weight (mg),${selected.map((e) => e.input.collectorMass).join(',')}');
    sb.writeln('Diameter (mm),${selected.map((e) => e.input.diameter).join(',')}');
    sb.writeln('Thickness (um),${selected.map((e) => e.input.thickness).join(',')}');
    sb.writeln();
    sb.writeln('Compare Calculated');
    sb.writeln('Metric,${selected.map((e) => 'E${e.number}').join(',')}');
    sb.writeln('Loading (mg/cm2),${selected.map((e) => e.result.loading).join(',')}');
    sb.writeln('Areal Capacity (mAh/cm2),${selected.map((e) => e.result.arealCapacity).join(',')}');
    sb.writeln('Electrode Density (g/cm3),${selected.map((e) => e.result.electrodeDensity).join(',')}');
    sb.writeln('Porosity (%),${selected.map((e) => e.result.porosity).join(',')}');
    return sb.toString();
  }

  Future<String> exportExperimentCsv(Experiment exp) async {
    final baseName = '${_safe(exp.name)}_${_stamp()}';
    return _writeTextFile(
      baseName: baseName,
      extension: 'csv',
      content: _buildExperimentCsv(exp, exp.electrodes),
    );
  }

  Future<String> exportExperimentXlsx(Experiment exp) async {
    // Dependency-free fallback: spreadsheet-compatible CSV payload with .xlsx extension.
    final baseName = '${_safe(exp.name)}_${_stamp()}';
    return _writeTextFile(
      baseName: baseName,
      extension: 'xlsx',
      content: _buildExperimentCsv(exp, exp.electrodes),
    );
  }

  Future<String> exportExperimentPdf(Experiment exp) async {
    // Dependency-free fallback: text content with .pdf extension.
    final baseName = '${_safe(exp.name)}_${_stamp()}';
    final csvLike = _buildExperimentCsv(exp, exp.electrodes).replaceAll(',', ' | ');
    return _writeTextFile(
      baseName: baseName,
      extension: 'pdf',
      content: csvLike,
    );
  }

  Future<String> exportSelectedElectrodesCsv(Experiment exp, List<Electrode> selected) async {
    final baseName = '${_safe(exp.name)}_${_stamp()}_SelectedElectrodes';
    return _writeTextFile(
      baseName: baseName,
      extension: 'csv',
      content: _buildExperimentCsv(exp, selected),
    );
  }

  Future<String> exportSelectedElectrodesXlsx(Experiment exp, List<Electrode> selected) async {
    final baseName = '${_safe(exp.name)}_${_stamp()}_SelectedElectrodes';
    return _writeTextFile(
      baseName: baseName,
      extension: 'xlsx',
      content: _buildExperimentCsv(exp, selected),
    );
  }

  Future<String> exportSelectedElectrodesPdf(Experiment exp, List<Electrode> selected) async {
    final baseName = '${_safe(exp.name)}_${_stamp()}_SelectedElectrodes';
    return _writeTextFile(
      baseName: baseName,
      extension: 'pdf',
      content: _buildExperimentCsv(exp, selected).replaceAll(',', ' | '),
    );
  }

  Future<String> exportCompareResultsCsv(Experiment exp, List<Electrode> selected) async {
    final baseName = '${_safe(exp.name)}_${_stamp()}_CompareResults';
    return _writeTextFile(
      baseName: baseName,
      extension: 'csv',
      content: _buildCompareCsv(exp, selected),
    );
  }

  Future<String> exportCompareResultsXlsx(Experiment exp, List<Electrode> selected) async {
    final baseName = '${_safe(exp.name)}_${_stamp()}_CompareResults';
    return _writeTextFile(
      baseName: baseName,
      extension: 'xlsx',
      content: _buildCompareCsv(exp, selected),
    );
  }

  Future<String> exportCompareResultsPdf(Experiment exp, List<Electrode> selected) async {
    final baseName = '${_safe(exp.name)}_${_stamp()}_CompareResults';
    return _writeTextFile(
      baseName: baseName,
      extension: 'pdf',
      content: _buildCompareCsv(exp, selected).replaceAll(',', ' | '),
    );
  }
}

