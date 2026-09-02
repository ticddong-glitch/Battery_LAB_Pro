import 'package:flutter/material.dart';

import '../factories/experiment_factory.dart';
import '../repository/experiment_repository.dart';
import '../repository/protocol_repository.dart';
import '../models/protocol.dart';

class NewExperimentScreen extends StatefulWidget {
  const NewExperimentScreen({super.key});

  @override
  State<NewExperimentScreen> createState() =>
      _NewExperimentScreenState();
}

class _NewExperimentScreenState
    extends State<NewExperimentScreen> {
  final TextEditingController _nameController =
      TextEditingController();

  final protocolRepo = ProtocolRepository.instance;
  List<Protocol> _protocols = [];
  Protocol? selectedProtocol;

  int electrodeCount = 4;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _protocols = protocolRepo.getAll();
    if (_protocols.isNotEmpty) selectedProtocol = _protocols.first;
  }

  void _createExperiment() {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Experiment Name을 입력해주세요."),
        ),
      );
      return;
    }

    final protocol = selectedProtocol;
    if (protocol == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Select a protocol before creating an experiment.'),
        ),
      );
      return;
    }

    final experiment = ExperimentFactory.create(
      name: _nameController.text.trim(),
      protocol: protocol,
      electrodeCount: electrodeCount,
    );

    ExperimentRepository.instance.add(experiment);

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("New Experiment"),
      ),

      body: ListView(
        padding: const EdgeInsets.all(20),

        children: [

          const Text(
            "Experiment Name",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),

          const SizedBox(height: 8),

          TextField(
            controller: _nameController,
            decoration: InputDecoration(
              hintText: "HC_250804",
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),

          const SizedBox(height: 30),

          const Text(
            "Protocol",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),

          const SizedBox(height: 8),

          DropdownButtonFormField<Protocol>(
            initialValue: selectedProtocol,

            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            items: _protocols
                .map(
                  (p) => DropdownMenuItem(
                    value: p,
                    child: Text(p.name),
                  ),
                )
                .toList(),

            onChanged: (value) {
              setState(() {
                selectedProtocol = value;
              });
            },
          ),

          const SizedBox(height: 30),

          const Text(
            "Electrode Count",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),

          const SizedBox(height: 12),

          Row(
            children: [

              IconButton(
                onPressed: () {
                  if (electrodeCount > 1) {
                    setState(() {
                      electrodeCount--;
                    });
                  }
                },
                icon: const Icon(Icons.remove_circle_outline),
              ),

              Text(
                electrodeCount.toString(),
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),

              IconButton(
                onPressed: () {
                  setState(() {
                    electrodeCount++;
                  });
                },
                icon: const Icon(Icons.add_circle_outline),
              ),

            ],
          ),

          const SizedBox(height: 40),

          SizedBox(
            height: 55,

            child: ElevatedButton(
              onPressed: _createExperiment,

              child: const Text(
                "Create Experiment",
                style: TextStyle(fontSize: 18),
              ),
            ),
          ),

        ],
      ),
    );
  }
}