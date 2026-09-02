import 'package:flutter/material.dart';

import '../models/app_preferences.dart';
import '../models/presets/collector_preset.dart';
import '../models/presets/material_preset.dart';
import '../repository/preferences_repository.dart';
import 'material_preset_screen.dart';

class SettingsScreen extends StatefulWidget {
	const SettingsScreen({super.key});

	@override
	State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
	final _repo = PreferencesRepository.instance;

	late UnitPreference _units;
	late int _decimalPlaces;
	late List<MaterialPreset> _materials;
	late List<CollectorPreset> _collectors;
	late ThemePreference _theme;
	late String _languageCode;
	late TextEditingController _exportFolderController;

	@override
	void initState() {
		super.initState();
		final p = _repo.current;
		_units = p.units;
		_decimalPlaces = p.decimalPlaces;
		_materials = [...p.materialPresets];
		_collectors = [...p.collectorPresets];
		_theme = p.theme;
		_languageCode = p.languageCode;
		_exportFolderController = TextEditingController(text: p.defaultExportFolder);
	}

	@override
	void dispose() {
		_exportFolderController.dispose();
		super.dispose();
	}

	Future<void> _save() async {
		final next = _repo.current.copyWith(
			units: _units,
			decimalPlaces: _decimalPlaces,
			materialPresets: _materials,
			collectorPresets: _collectors,
			defaultExportFolder: _exportFolderController.text.trim(),
			theme: _theme,
			languageCode: _languageCode,
		);
		await _repo.save(next);
		if (!mounted) return;
		ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Preferences saved')));
	}

	Future<void> _editMaterial({MaterialPreset? existing, bool duplicate = false}) async {
		final base = existing;
		final name = TextEditingController(text: duplicate ? '${base?.name ?? ''} (copy)' : (base?.name ?? ''));
		final density = TextEditingController(text: base == null ? '' : base.trueDensity.toString());
		final specificCapacity = TextEditingController(text: base?.specificCapacity?.toString() ?? '');
		final memo = TextEditingController(text: base?.memo ?? '');
		var category = base?.category ?? MaterialCategory.activeMaterial;
		var isCustom = base?.isCustom ?? true;

		final ok = await showDialog<bool>(
			context: context,
			builder: (_) => StatefulBuilder(
				builder: (context, setDialogState) => AlertDialog(
					title: Text(existing == null ? 'Create Material Preset' : (duplicate ? 'Duplicate Material Preset' : 'Edit Material Preset')),
					content: SingleChildScrollView(
						child: Column(
							mainAxisSize: MainAxisSize.min,
							children: [
								TextField(controller: name, decoration: const InputDecoration(labelText: 'Name')),
								const SizedBox(height: 8),
								DropdownButtonFormField<MaterialCategory>(
									initialValue: category,
									decoration: const InputDecoration(labelText: 'Category'),
									items: MaterialCategory.values
										.map((c) => DropdownMenuItem(value: c, child: Text(c.name)))
										.toList(),
									onChanged: (v) {
										if (v == null) return;
										setDialogState(() {
											category = v;
										});
									},
								),
								const SizedBox(height: 8),
								TextField(controller: density, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'True Density')),
								const SizedBox(height: 8),
								TextField(controller: specificCapacity, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Specific Capacity (optional)')),
								const SizedBox(height: 8),
								TextField(controller: memo, maxLines: 2, decoration: const InputDecoration(labelText: 'Memo')),
								const SizedBox(height: 8),
								SwitchListTile(
									value: isCustom,
									onChanged: (v) => setDialogState(() => isCustom = v),
									title: const Text('Custom Preset'),
								),
							],
						),
					),
					actions: [
						TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
						ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Save')),
					],
				),
			),
		);

		if (ok != true || name.text.trim().isEmpty) {
			return;
		}

		final next = MaterialPreset(
			id: (existing == null || duplicate)
				? DateTime.now().microsecondsSinceEpoch.toString()
				: existing.id,
			name: name.text.trim(),
			category: category,
			trueDensity: double.tryParse(density.text) ?? 0,
			specificCapacity: specificCapacity.text.trim().isEmpty
				? null
				: double.tryParse(specificCapacity.text),
			memo: memo.text.trim(),
			isCustom: isCustom,
		);

		setState(() {
			if (existing == null || duplicate) {
				_materials.insert(0, next);
			} else {
				final index = _materials.indexWhere((m) => m.id == existing.id);
				if (index != -1) {
					_materials[index] = next;
				}
			}
		});
	}

	Future<void> _editCollector({CollectorPreset? existing, bool duplicate = false}) async {
		final base = existing;
		final presetName = TextEditingController(text: duplicate ? '${base?.presetName ?? ''} (copy)' : (base?.presetName ?? ''));
		final collectorMaterial = TextEditingController(text: base?.collectorMaterial ?? '');
		final thickness = TextEditingController(text: base == null ? '' : base.thickness.toString());
		final density = TextEditingController(text: base == null ? '' : base.density.toString());
		final punchDiameter = TextEditingController(text: base == null ? '' : base.punchDiameter.toString());
		final averageFoilWeight = TextEditingController(text: base == null ? '' : base.averageFoilWeight.toString());
		final memo = TextEditingController(text: base?.memo ?? '');
		var isCustom = base?.isCustom ?? true;

		final ok = await showDialog<bool>(
			context: context,
			builder: (_) => StatefulBuilder(
				builder: (context, setDialogState) => AlertDialog(
					title: Text(existing == null ? 'Create Collector Preset' : (duplicate ? 'Duplicate Collector Preset' : 'Edit Collector Preset')),
					content: SingleChildScrollView(
						child: Column(
							mainAxisSize: MainAxisSize.min,
							children: [
								TextField(controller: presetName, decoration: const InputDecoration(labelText: 'Preset Name')),
								const SizedBox(height: 8),
								TextField(controller: collectorMaterial, decoration: const InputDecoration(labelText: 'Collector Material')),
								const SizedBox(height: 8),
								TextField(controller: thickness, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Thickness')),
								const SizedBox(height: 8),
								TextField(controller: density, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Density')),
								const SizedBox(height: 8),
								TextField(controller: punchDiameter, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Punch Diameter')),
								const SizedBox(height: 8),
								TextField(controller: averageFoilWeight, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Average Foil Weight')),
								const SizedBox(height: 8),
								TextField(controller: memo, maxLines: 2, decoration: const InputDecoration(labelText: 'Memo')),
								const SizedBox(height: 8),
								SwitchListTile(
									value: isCustom,
									onChanged: (v) => setDialogState(() => isCustom = v),
									title: const Text('Custom Preset'),
								),
							],
						),
					),
					actions: [
						TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
						ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Save')),
					],
				),
			),
		);

		if (ok != true || presetName.text.trim().isEmpty || collectorMaterial.text.trim().isEmpty) {
			return;
		}

		final next = CollectorPreset(
			id: (existing == null || duplicate)
				? DateTime.now().microsecondsSinceEpoch.toString()
				: existing.id,
			presetName: presetName.text.trim(),
			collectorMaterial: collectorMaterial.text.trim(),
			thickness: double.tryParse(thickness.text) ?? 0,
			density: double.tryParse(density.text) ?? 0,
			punchDiameter: double.tryParse(punchDiameter.text) ?? 0,
			averageFoilWeight: double.tryParse(averageFoilWeight.text) ?? 0,
			memo: memo.text.trim(),
			isCustom: isCustom,
		);

		setState(() {
			if (existing == null || duplicate) {
				_collectors.insert(0, next);
			} else {
				final index = _collectors.indexWhere((c) => c.id == existing.id);
				if (index != -1) {
					_collectors[index] = next;
				}
			}
		});
	}

	@override
	Widget build(BuildContext context) {
		return Scaffold(
			appBar: AppBar(
				title: const Text('Preferences'),
				actions: [
					IconButton(onPressed: _save, icon: const Icon(Icons.save)),
				],
			),
			body: ListView(
				padding: const EdgeInsets.all(16),
				children: [
					const Text('Units', style: TextStyle(fontWeight: FontWeight.bold)),
					DropdownButtonFormField<UnitPreference>(
						initialValue: _units,
						items: UnitPreference.values.map((u) => DropdownMenuItem(value: u, child: Text(u.name))).toList(),
						onChanged: (v) => setState(() => _units = v ?? _units),
						decoration: const InputDecoration(border: OutlineInputBorder()),
					),
					const SizedBox(height: 16),
					Text('Decimal Places: $_decimalPlaces', style: const TextStyle(fontWeight: FontWeight.bold)),
					Slider(
						value: _decimalPlaces.toDouble(),
						min: 0,
						max: 6,
						divisions: 6,
						label: _decimalPlaces.toString(),
						onChanged: (v) => setState(() => _decimalPlaces = v.round()),
					),
					const SizedBox(height: 16),
					const Text('Default Export Folder', style: TextStyle(fontWeight: FontWeight.bold)),
					TextField(
						controller: _exportFolderController,
						decoration: const InputDecoration(border: OutlineInputBorder(), hintText: 'C:/Users/.../Documents/lab_exports'),
					),
					const SizedBox(height: 16),
					Card(
						child: ListTile(
							leading: const Icon(Icons.inventory_2_outlined),
							title: const Text('Material Presets'),
							subtitle: const Text('Manage reusable material presets'),
							trailing: const Icon(Icons.chevron_right),
							onTap: () {
								Navigator.push(
									context,
									MaterialPageRoute(builder: (_) => const MaterialPresetScreen()),
								);
							},
						),
					),
					const SizedBox(height: 16),
					const Text('Theme', style: TextStyle(fontWeight: FontWeight.bold)),
					DropdownButtonFormField<ThemePreference>(
						initialValue: _theme,
						items: ThemePreference.values.map((t) => DropdownMenuItem(value: t, child: Text(t.name))).toList(),
						onChanged: (v) => setState(() => _theme = v ?? _theme),
						decoration: const InputDecoration(border: OutlineInputBorder()),
					),
					const SizedBox(height: 16),
					const Text('Language', style: TextStyle(fontWeight: FontWeight.bold)),
					DropdownButtonFormField<String>(
						initialValue: _languageCode,
						items: const [
							DropdownMenuItem(value: 'en', child: Text('English')),
							DropdownMenuItem(value: 'ko', child: Text('Korean')),
						],
						onChanged: (v) => setState(() => _languageCode = v ?? _languageCode),
						decoration: const InputDecoration(border: OutlineInputBorder()),
					),
					const SizedBox(height: 20),
					Row(
						mainAxisAlignment: MainAxisAlignment.spaceBetween,
						children: [
							const Text('Preset Manager - Material Library', style: TextStyle(fontWeight: FontWeight.bold)),
							TextButton.icon(onPressed: () => _editMaterial(), icon: const Icon(Icons.add), label: const Text('Create')),
						],
					),
					..._materials.asMap().entries.map(
						(entry) => ListTile(
							title: Text(entry.value.name),
							subtitle: Text(
								'${entry.value.category.name} • Density ${entry.value.trueDensity}'
								'${entry.value.specificCapacity == null ? '' : ' • Capacity ${entry.value.specificCapacity}'}\n'
								'Custom: ${entry.value.isCustom ? 'Yes' : 'No'}${entry.value.memo.isEmpty ? '' : ' • ${entry.value.memo}'}',
							),
							isThreeLine: true,
							trailing: Wrap(
								spacing: 4,
								children: [
									IconButton(
										icon: const Icon(Icons.copy),
										onPressed: () => _editMaterial(existing: entry.value, duplicate: true),
									),
									IconButton(
										icon: const Icon(Icons.edit_outlined),
										onPressed: () => _editMaterial(existing: entry.value),
									),
									IconButton(
										icon: const Icon(Icons.delete_outline),
										onPressed: () => setState(() => _materials.removeAt(entry.key)),
									),
								],
							),
						),
					),
					const SizedBox(height: 12),
					Row(
						mainAxisAlignment: MainAxisAlignment.spaceBetween,
						children: [
							const Text('Preset Manager - Collector Library', style: TextStyle(fontWeight: FontWeight.bold)),
							TextButton.icon(onPressed: () => _editCollector(), icon: const Icon(Icons.add), label: const Text('Create')),
						],
					),
					..._collectors.asMap().entries.map(
						(entry) => ListTile(
							title: Text(entry.value.presetName),
							subtitle: Text(
								'${entry.value.collectorMaterial} • Thickness ${entry.value.thickness} • Density ${entry.value.density}\n'
								'Diameter ${entry.value.punchDiameter} • Foil Weight ${entry.value.averageFoilWeight}'
								'${entry.value.memo.isEmpty ? '' : ' • ${entry.value.memo}'}',
							),
							isThreeLine: true,
							trailing: Wrap(
								spacing: 4,
								children: [
									IconButton(
										icon: const Icon(Icons.copy),
										onPressed: () => _editCollector(existing: entry.value, duplicate: true),
									),
									IconButton(
										icon: const Icon(Icons.edit_outlined),
										onPressed: () => _editCollector(existing: entry.value),
									),
									IconButton(
										icon: const Icon(Icons.delete_outline),
										onPressed: () => setState(() => _collectors.removeAt(entry.key)),
									),
								],
							),
						),
					),
					const SizedBox(height: 20),
					ElevatedButton(onPressed: _save, child: const Text('Save Preferences')),
				],
			),
		);
	}
}

