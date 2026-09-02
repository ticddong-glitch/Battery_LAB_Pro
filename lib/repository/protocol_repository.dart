import '../models/protocol.dart';
import 'db_helper.dart';
import 'dart:convert';
import 'dart:async';

class ProtocolRepository {
  ProtocolRepository._();

  static final ProtocolRepository instance = ProtocolRepository._();

  final List<Protocol> _protocols = [];

  /// Initialize repository from DB
  Future<void> init() async {
    final rows = await DBHelper.instance.getAllProtocols();
    _protocols.clear();

    if (rows.isEmpty) {
      return;
    }

    for (final r in rows) {
      final jsonStr = r['json'] as String;
      final map = jsonDecode(jsonStr) as Map<String, dynamic>;
      _protocols.add(Protocol.fromMap(map));
    }
  }

  List<Protocol> getAll() => List.unmodifiable(_protocols);

  void add(Protocol protocol) {
    final now = DateTime.now();
    final p = protocol.copyWith(createdAt: now, updatedAt: now);
    unawaited(DBHelper.instance.pushUndoSnapshot(reason: 'protocol_add'));
    _protocols.insert(0, p);
    unawaited(DBHelper.instance.upsertProtocol(p.id, p.toMap()));
  }

  void remove(String id) {
    unawaited(DBHelper.instance.pushUndoSnapshot(reason: 'protocol_remove'));
    _protocols.removeWhere((p) => p.id == id);
    unawaited(DBHelper.instance.deleteProtocol(id));
  }

  void update(Protocol protocol) {
    final updated = protocol.copyWith(updatedAt: DateTime.now(), version: _nextVersion(protocol.version));
    final index = _protocols.indexWhere((p) => p.id == protocol.id);
    if (index != -1) _protocols[index] = updated;
    unawaited(DBHelper.instance.pushUndoSnapshot(reason: 'protocol_update'));
    unawaited(DBHelper.instance.upsertProtocol(updated.id, updated.toMap()));
  }

  Protocol? findById(String id) {
    try {
      return _protocols.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  Protocol duplicate(String id) {
    final proto = findById(id);
    if (proto == null) throw StateError('Protocol not found');
    final now = DateTime.now();
    final copy = proto.copyWith(
      id: '${proto.id}_${now.millisecondsSinceEpoch}',
      name: '${proto.name} (copy)',
      version: 'v1.0',
      createdAt: now,
      updatedAt: now,
    );
    add(copy);
    return copy;
  }

  String _nextVersion(String version) {
    final clean = version.trim().toLowerCase().startsWith('v') ? version.substring(1) : version;
    final parts = clean.split('.');
    final major = int.tryParse(parts.isNotEmpty ? parts[0] : '1') ?? 1;
    final minor = int.tryParse(parts.length > 1 ? parts[1] : '0') ?? 0;
    return 'v$major.${minor + 1}';
  }
}
