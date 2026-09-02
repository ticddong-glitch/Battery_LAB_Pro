import 'dart:math';

import '../models/electrode.dart';
import '../models/experiment.dart';

enum StatisticsMetric { loading, density, porosity, arealCapacity }

extension StatisticsMetricLabel on StatisticsMetric {
  String get label {
    switch (this) {
      case StatisticsMetric.loading:
        return 'Loading';
      case StatisticsMetric.density:
        return 'Density';
      case StatisticsMetric.porosity:
        return 'Porosity';
      case StatisticsMetric.arealCapacity:
        return 'Areal Capacity';
    }
  }
}

class HistogramSummary {
  final List<int> counts;
  final List<double> edges;

  const HistogramSummary({required this.counts, required this.edges});
}

class BoxPlotSummary {
  final double min;
  final double q1;
  final double median;
  final double q3;
  final double max;

  const BoxPlotSummary({
    required this.min,
    required this.q1,
    required this.median,
    required this.q3,
    required this.max,
  });
}

class StatisticsService {
  StatisticsService._();
  static final StatisticsService instance = StatisticsService._();

  List<double> valuesForMetric(Experiment experiment, StatisticsMetric metric) {
    final values = <double>[];
    for (final e in experiment.electrodes) {
      final v = _metricValue(e, metric);
      if (v.isFinite) values.add(v);
    }
    return values;
  }

  List<Point<double>> scatterPoints({
    required Experiment experiment,
    required StatisticsMetric xMetric,
    required StatisticsMetric yMetric,
  }) {
    final points = <Point<double>>[];
    for (final e in experiment.electrodes) {
      final x = _metricValue(e, xMetric);
      final y = _metricValue(e, yMetric);
      if (x.isFinite && y.isFinite) {
        points.add(Point<double>(x, y));
      }
    }
    return points;
  }

  double mean(List<double> values) {
    if (values.isEmpty) return 0;
    return values.reduce((a, b) => a + b) / values.length;
  }

  double stddev(List<double> values) {
    if (values.length < 2) return 0;
    final m = mean(values);
    final variance = values.map((v) => pow(v - m, 2).toDouble()).reduce((a, b) => a + b) / (values.length - 1);
    return sqrt(variance);
  }

  double correlation(List<double> x, List<double> y) {
    final n = min(x.length, y.length);
    if (n < 2) return 0;

    final xValues = x.take(n).toList();
    final yValues = y.take(n).toList();
    final mx = mean(xValues);
    final my = mean(yValues);

    var cov = 0.0;
    var sx = 0.0;
    var sy = 0.0;
    for (var i = 0; i < n; i++) {
      final dx = xValues[i] - mx;
      final dy = yValues[i] - my;
      cov += dx * dy;
      sx += dx * dx;
      sy += dy * dy;
    }

    if (sx <= 0 || sy <= 0) return 0;
    return cov / sqrt(sx * sy);
  }

  HistogramSummary histogram(List<double> values, {int bins = 8}) {
    if (bins <= 0) bins = 1;
    final counts = List<int>.filled(bins, 0);
    if (values.isEmpty) return HistogramSummary(counts: counts, edges: const []);

    final minV = values.reduce(min);
    final maxV = values.reduce(max);
    final range = maxV - minV;
    if (range == 0) {
      counts[bins ~/ 2] = values.length;
      return HistogramSummary(
        counts: counts,
        edges: List<double>.filled(bins + 1, minV),
      );
    }

    final edges = List<double>.generate(bins + 1, (i) => minV + (range * i / bins));
    for (final v in values) {
      var idx = ((v - minV) / range * bins).floor();
      if (idx < 0) idx = 0;
      if (idx >= bins) idx = bins - 1;
      counts[idx]++;
    }
    return HistogramSummary(counts: counts, edges: edges);
  }

  BoxPlotSummary? boxPlot(List<double> values) {
    if (values.isEmpty) return null;
    final sorted = [...values]..sort();
    return BoxPlotSummary(
      min: sorted.first,
      q1: _percentile(sorted, 0.25),
      median: _percentile(sorted, 0.5),
      q3: _percentile(sorted, 0.75),
      max: sorted.last,
    );
  }

  double _metricValue(Electrode e, StatisticsMetric metric) {
    switch (metric) {
      case StatisticsMetric.loading:
        return e.result.loading;
      case StatisticsMetric.density:
        return e.result.electrodeDensity;
      case StatisticsMetric.porosity:
        return e.result.porosity;
      case StatisticsMetric.arealCapacity:
        return e.result.arealCapacity;
    }
  }

  double _percentile(List<double> sorted, double p) {
    if (sorted.isEmpty) return 0;
    final idx = (sorted.length - 1) * p;
    final lo = idx.floor();
    final hi = idx.ceil();
    if (lo == hi) return sorted[lo];
    final w = idx - lo;
    return sorted[lo] * (1 - w) + sorted[hi] * w;
  }
}
