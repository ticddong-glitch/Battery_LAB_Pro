import 'package:flutter/material.dart';
import 'dart:math';

import '../sevices/statistics_service.dart';
import '../models/experiment.dart';
import '../repository/experiment_repository.dart';
import '../widgets/stats_chart.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  Experiment? _selected;
  StatisticsMetric _xMetric = StatisticsMetric.loading;
  StatisticsMetric _yMetric = StatisticsMetric.arealCapacity;
  StatisticsChartType _chartType = StatisticsChartType.histogram;
  double _bins = 8;

  @override
  void initState() {
    super.initState();
    final exps = ExperimentRepository.instance.getAll();
    if (exps.isNotEmpty) _selected = exps.first;
  }

  @override
  Widget build(BuildContext context) {
    final exps = ExperimentRepository.instance.getAll();
    final experiment = _selected;
    final xValues = experiment == null ? <double>[] : StatisticsService.instance.valuesForMetric(experiment, _xMetric);
    final yValues = experiment == null ? <double>[] : StatisticsService.instance.valuesForMetric(experiment, _yMetric);
    final mean = StatisticsService.instance.mean(xValues);
    final sd = StatisticsService.instance.stddev(xValues);
    final corr = StatisticsService.instance.correlation(xValues, yValues);
    final histogram = StatisticsService.instance.histogram(xValues, bins: _bins.round());
    final box = StatisticsService.instance.boxPlot(xValues);
    final scatter = experiment == null
        ? <Point<double>>[]
        : StatisticsService.instance.scatterPoints(experiment: experiment, xMetric: _xMetric, yMetric: _yMetric);

    return Scaffold(
      appBar: AppBar(title: const Text('Statistics')),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: ListView(
          children: [
            DropdownButtonFormField<Experiment>(
              initialValue: _selected,
              hint: const Text('Select experiment'),
              items: exps.map((e) => DropdownMenuItem(value: e, child: Text(e.name))).toList(),
              onChanged: (v) => setState(() => _selected = v),
              decoration: const InputDecoration(border: OutlineInputBorder(), labelText: 'Experiment'),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<StatisticsChartType>(
              initialValue: _chartType,
              items: StatisticsChartType.values
                  .map((t) => DropdownMenuItem(value: t, child: Text(_chartLabel(t))))
                  .toList(),
              onChanged: (t) {
                if (t == null) return;
                setState(() => _chartType = t);
              },
              decoration: const InputDecoration(border: OutlineInputBorder(), labelText: 'Chart Type'),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<StatisticsMetric>(
                    initialValue: _xMetric,
                    items: StatisticsMetric.values
                        .map((m) => DropdownMenuItem(value: m, child: Text(m.label)))
                        .toList(),
                    onChanged: (m) {
                      if (m == null) return;
                      setState(() => _xMetric = m);
                    },
                    decoration: const InputDecoration(border: OutlineInputBorder(), labelText: 'Metric X'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: DropdownButtonFormField<StatisticsMetric>(
                    initialValue: _yMetric,
                    items: StatisticsMetric.values
                        .map((m) => DropdownMenuItem(value: m, child: Text(m.label)))
                        .toList(),
                    onChanged: (m) {
                      if (m == null) return;
                      setState(() => _yMetric = m);
                    },
                    decoration: const InputDecoration(border: OutlineInputBorder(), labelText: 'Metric Y'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_chartType == StatisticsChartType.histogram) ...[
              Text('Histogram Bins: ${_bins.round()}'),
              Slider(
                value: _bins,
                min: 4,
                max: 20,
                divisions: 16,
                label: _bins.round().toString(),
                onChanged: (v) => setState(() => _bins = v),
              ),
            ],
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _StatChip(label: 'Average (${_xMetric.label})', value: mean),
                _StatChip(label: 'Std Dev (${_xMetric.label})', value: sd),
                _StatChip(label: 'Correlation (${_xMetric.label} vs ${_yMetric.label})', value: corr),
              ],
            ),
            const SizedBox(height: 16),
            if (experiment == null || xValues.isEmpty)
              const Center(child: Padding(
                padding: EdgeInsets.only(top: 40),
                child: Text('No statistics data available'),
              ))
            else
              StatisticsChart(
                type: _chartType,
                histogram: histogram,
                scatter: scatter,
                boxPlot: box,
              ),
          ],
        ),
      ),
    );
  }

  String _chartLabel(StatisticsChartType t) {
    switch (t) {
      case StatisticsChartType.histogram:
        return 'Histogram';
      case StatisticsChartType.scatterPlot:
        return 'Scatter Plot';
      case StatisticsChartType.boxPlot:
        return 'Box Plot';
    }
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final double value;

  const _StatChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text('$label: ${value.toStringAsFixed(4)}'),
    );
  }
}
