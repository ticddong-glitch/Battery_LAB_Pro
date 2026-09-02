import 'package:flutter/material.dart';

import '../models/experiment.dart';
import 'experiment_card.dart';

class ExperimentList extends StatelessWidget {
  final List<Experiment> experiments;
  final Function(Experiment)? onTap;

  const ExperimentList({
    super.key,
    required this.experiments,
    this.onTap,
  });

  Color _statusColor(ExperimentStatus status) {
    switch (status) {
      case ExperimentStatus.active:
        return Colors.green;
      case ExperimentStatus.completed:
        return Colors.blue;
      case ExperimentStatus.archived:
        return Colors.grey;
    }
  }

  String _statusLabel(ExperimentStatus status) {
    switch (status) {
      case ExperimentStatus.active:
        return 'Active';
      case ExperimentStatus.completed:
        return 'Completed';
      case ExperimentStatus.archived:
        return 'Archived';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (experiments.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.only(top: 80),
          child: Column(
            children: [
              Icon(
                Icons.science_outlined,
                size: 70,
                color: Colors.grey,
              ),
              SizedBox(height: 20),
              Text(
                "No Experiments",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8),
              Text(
                "Tap the + button to create\nyour first experiment.",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    final sortedExperiments = [...experiments]
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return ListView.builder(
      itemCount: sortedExperiments.length,
      itemBuilder: (context, index) {
        final experiment = sortedExperiments[index];

        return ExperimentCard(
          title: experiment.name,
          protocolName: experiment.protocolName ?? 'Unknown Protocol',
          electrodeCount: experiment.electrodes.length,
          statusLabel: _statusLabel(experiment.status),
          statusColor: _statusColor(experiment.status),
          onTap: () {
            onTap?.call(experiment);
          },
        );
      },
    );
  }
}