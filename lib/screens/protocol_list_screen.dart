import 'package:flutter/material.dart';

import '../models/protocol.dart';
import '../repository/protocol_repository.dart';
import 'protocol_editor_screen.dart';

class ProtocolListScreen extends StatefulWidget {
  const ProtocolListScreen({super.key});

  @override
  State<ProtocolListScreen> createState() => _ProtocolListScreenState();
}

class _ProtocolListScreenState extends State<ProtocolListScreen> {
  final repo = ProtocolRepository.instance;

  @override
  Widget build(BuildContext context) {
    final protocols = repo.getAll();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Protocols'),
        actions: [
          IconButton(
            onPressed: () async {
              final newProto = Protocol(
                id: DateTime.now().millisecondsSinceEpoch.toString(),
                name: 'New Protocol',
                version: 'v1.0',
                materialPresetId: null,
                materialName: '',
                specificCapacity: 300,
                trueDensity: 1.55,
                collectorPresetId: null,
                collectorName: '',
                collectorThickness: 10,
                collectorDensity: 8.96,
                averageFoilWeight: 0,
                diameter: 14,
                activeRatio: 90,
                conductiveRatio: 5,
                binderRatio: 5,
                targetPorosity: 0,
                solidContent: 0.5,
                dryingTemperature: 120,
                dryingTime: 12,
                rollPressPressure: 50,
                notes: '',
              );
              repo.add(newProto);
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ProtocolEditorScreen(protocol: newProto),
                ),
              );
              setState(() {});
            },
            icon: const Icon(Icons.add),
            tooltip: 'Create Protocol',
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: protocols.length,
        itemBuilder: (_, index) {
          final p = protocols[index];
          return ListTile(
            title: Text(p.name),
            subtitle: Text('${p.materialName} • ${p.version}\nCreated: ${p.createdAt.toLocal().toString().split('.').first}\nModified: ${p.updatedAt.toLocal().toString().split('.').first}'),
            isThreeLine: true,
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  onPressed: () async {
                    repo.duplicate(p.id);
                    setState(() {});
                  },
                  icon: const Icon(Icons.copy),
                  tooltip: 'Duplicate',
                ),
                IconButton(
                  onPressed: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ProtocolEditorScreen(protocol: p),
                      ),
                    );
                    setState(() {});
                  },
                  icon: const Icon(Icons.edit),
                  tooltip: 'Edit',
                ),
                IconButton(
                  onPressed: () async {
                    final ok = await showDialog<bool>(
                      context: context,
                      builder: (_) => AlertDialog(
                        title: const Text('Delete Protocol'),
                        content: Text('Delete ${p.name}?'),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
                        ],
                      ),
                    );
                    if (ok == true) {
                      repo.remove(p.id);
                      setState(() {});
                    }
                  },
                  icon: const Icon(Icons.delete),
                  tooltip: 'Delete',
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
