import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:convert';

import '../models/experiment.dart';
import '../repository/experiment_repository.dart';
import '../repository/db_helper.dart';
import '../repository/protocol_repository.dart';
import '../widgets/bottom_navigation.dart';
import '../widgets/experiment_list.dart';
import 'expeiment_screen.dart';
import 'new_experiment_screen.dart';
import 'protocol_list_screen.dart';
import 'press_calculator_screen.dart';
import 'settings_screen.dart';
import 'statistics_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ExperimentRepository repository =
      ExperimentRepository.instance;

  @override
  void initState() {
    super.initState();
    _reloadExperimentsFromDb();
  }

  Future<void> _reloadExperimentsFromDb() async {
    if (kIsWeb) {
      repository.clear();
      if (!mounted) return;
      setState(() {});
      return;
    }

    await ProtocolRepository.instance.init();
    final rows = await DBHelper.instance.getAllExperiments();
    repository.clear();
    for (final r in rows) {
      final jsonStr = r['json'] as String;
      final map = jsonDecode(jsonStr) as Map<String, dynamic>;
      repository.add(Experiment.fromMap(map));
    }
    if (!mounted) return;
    setState(() {});
  }

  Future<void> _handlePersistenceAction(String value) async {
    if (value == 'preferences') {
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const SettingsScreen()),
      );
      if (!mounted) return;
      setState(() {});
      return;
    }

    if (value == 'backup') {
      await DBHelper.instance.createBackup(label: 'manual_home_backup');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Backup completed')));
      return;
    }

    if (value == 'restore') {
      final ok = await DBHelper.instance.restoreLatestBackup();
      await ProtocolRepository.instance.init();
      await _reloadExperimentsFromDb();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ok ? 'Restore completed' : 'No backup available')),
      );
      return;
    }

    if (value == 'undo') {
      final ok = await DBHelper.instance.undoLast();
      await ProtocolRepository.instance.init();
      await _reloadExperimentsFromDb();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ok ? 'Undo completed' : 'Nothing to undo')),
      );
      return;
    }
  }

  @override
  Widget build(BuildContext context) {
    final experiments = repository.getAll();

    return Scaffold(
      backgroundColor: const Color(0xffF5F7FA),

      appBar: AppBar(
        title: const Text(
          "LAB Calculator",
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),

        actions: [
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProtocolListScreen()),
              );
            },
            icon: const Icon(Icons.dataset_outlined),
            tooltip: 'Protocols',
          ),
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PressCalculatorScreen()),
              );
            },
            icon: const Icon(Icons.compress),
            tooltip: 'Press Calculator',
          ),
          IconButton(
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const StatisticsScreen()));
            },
            icon: const Icon(Icons.bar_chart),
            tooltip: 'Statistics',
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.settings_outlined),
            onSelected: _handlePersistenceAction,
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'preferences', child: Text('Preferences')),
              PopupMenuDivider(),
              PopupMenuItem(value: 'backup', child: Text('Backup Now')),
              PopupMenuItem(value: 'restore', child: Text('Restore Latest Backup')),
              PopupMenuItem(value: 'undo', child: Text('Undo Last Change')),
            ],
          ),
        ],
      ),

      body: ExperimentList(
        experiments: experiments,

        onTap: (experiment) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  ExperimentDetailScreen(
                    experimentId: experiment.id,
                  ),
            ),
          );
        },
      ),

      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xff2563EB),

        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  const NewExperimentScreen(),
            ),
          );

          if (!mounted) return;

          setState(() {});
        },

        child: const Icon(
          Icons.add,
          color: Colors.white,
        ),
      ),

      floatingActionButtonLocation:
          FloatingActionButtonLocation.centerDocked,

      bottomNavigationBar: BottomNavigation(
        currentIndex: 0,

        onHomeTap: () {},

        onExperimentTap: () {},
      ),
    );
  }
}