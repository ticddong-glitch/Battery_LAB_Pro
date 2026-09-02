import 'package:flutter/material.dart';

import '../models/electrode.dart';

class ElectrodeCard extends StatefulWidget {
	final Electrode electrode;
	final bool collectorPresetSuppliesFoilValues;
	final bool pressEnabled;
	final double? pressTargetThicknessUm;
	final double sharedFoilWeight;
	final double sharedFoilThickness;
	final VoidCallback onOpenDetails;
	final VoidCallback onDelete;
	final VoidCallback onAdvanceToNextElectrode;
	final ValueChanged<double> onCoatedWeightChanged;
	final ValueChanged<double> onCoatedThicknessChanged;
	final ValueChanged<double?> onFoilWeightOverrideChanged;
	final ValueChanged<double?> onFoilThicknessOverrideChanged;
	final FocusNode coatedWeightFocusNode;
	final FocusNode coatedThicknessFocusNode;
	final FocusNode foilWeightFocusNode;
	final FocusNode foilThicknessFocusNode;

	const ElectrodeCard({
		super.key,
		required this.electrode,
		required this.collectorPresetSuppliesFoilValues,
		required this.pressEnabled,
		required this.pressTargetThicknessUm,
		required this.sharedFoilWeight,
		required this.sharedFoilThickness,
		required this.onOpenDetails,
		required this.onDelete,
		required this.onAdvanceToNextElectrode,
		required this.onCoatedWeightChanged,
		required this.onCoatedThicknessChanged,
		required this.onFoilWeightOverrideChanged,
		required this.onFoilThicknessOverrideChanged,
		required this.coatedWeightFocusNode,
		required this.coatedThicknessFocusNode,
		required this.foilWeightFocusNode,
		required this.foilThicknessFocusNode,
	});

	@override
	State<ElectrodeCard> createState() => _ElectrodeCardState();
}

class _ElectrodeCardState extends State<ElectrodeCard> {
	late final TextEditingController _coatedWeightController;
	late final TextEditingController _coatedThicknessController;
	late final TextEditingController _foilWeightController;
	late final TextEditingController _foilThicknessController;
	late bool _showCollectorOverrides;

	@override
	void initState() {
		super.initState();
		_coatedWeightController = TextEditingController(
			text: widget.electrode.input.totalMass.toStringAsFixed(2),
		);
		_coatedThicknessController = TextEditingController(
			text: widget.electrode.input.thickness.toStringAsFixed(2),
		);
		_foilWeightController = TextEditingController(
			text: widget.electrode.input.collectorMass.toStringAsFixed(2),
		);
		_foilThicknessController = TextEditingController(
			text: (widget.electrode.valueOverrides[Electrode.keyFoilThickness] ??
					widget.sharedFoilThickness)
				.toStringAsFixed(2),
		);
		_showCollectorOverrides = !widget.collectorPresetSuppliesFoilValues ||
				widget.electrode.hasOverride(Electrode.keyAverageFoilWeight) ||
				widget.electrode.hasOverride(Electrode.keyFoilThickness);
	}

	@override
	void didUpdateWidget(covariant ElectrodeCard oldWidget) {
		super.didUpdateWidget(oldWidget);
		if (oldWidget.electrode.number != widget.electrode.number ||
				oldWidget.electrode.input.totalMass != widget.electrode.input.totalMass) {
			_coatedWeightController.text = widget.electrode.input.totalMass.toStringAsFixed(2);
		}
		if (oldWidget.electrode.number != widget.electrode.number ||
				oldWidget.electrode.input.thickness != widget.electrode.input.thickness) {
			_coatedThicknessController.text = widget.electrode.input.thickness.toStringAsFixed(2);
		}
		if (oldWidget.electrode.number != widget.electrode.number ||
				oldWidget.electrode.input.collectorMass != widget.electrode.input.collectorMass) {
			_foilWeightController.text = widget.electrode.input.collectorMass.toStringAsFixed(2);
		}
		final effectiveFoilThickness =
				widget.electrode.valueOverrides[Electrode.keyFoilThickness] ?? widget.sharedFoilThickness;
		if (double.tryParse(_foilThicknessController.text) != effectiveFoilThickness) {
			_foilThicknessController.text = effectiveFoilThickness.toStringAsFixed(2);
		}
	}

	@override
	void dispose() {
		_coatedWeightController.dispose();
		_coatedThicknessController.dispose();
		_foilWeightController.dispose();
		_foilThicknessController.dispose();
		super.dispose();
	}

	double _effectiveFoilWeight() {
		if (_showCollectorOverrides) {
			final entered = double.tryParse(_foilWeightController.text);
			if (entered != null) return entered;
		}
		return widget.sharedFoilWeight;
	}

	double _effectiveFoilThickness() {
		if (_showCollectorOverrides) {
			final entered = double.tryParse(_foilThicknessController.text);
			if (entered != null) return entered;
		}
		return widget.sharedFoilThickness;
	}

	@override
	Widget build(BuildContext context) {
		final result = widget.electrode.result;
		final coatedWeight = double.tryParse(_coatedWeightController.text);
		final coatedThickness = double.tryParse(_coatedThicknessController.text);
		final effectiveFoilWeight = _effectiveFoilWeight();
		final effectiveFoilThickness = _effectiveFoilThickness();

		String? coatedWeightError;
		if (coatedWeight != null && coatedWeight <= effectiveFoilWeight) {
			coatedWeightError = 'Coated Weight must be greater than Foil Weight.';
		}

		String? coatedThicknessError;
		if (coatedThickness != null && coatedThickness <= effectiveFoilThickness) {
			coatedThicknessError = 'Coated Thickness must be greater than Foil Thickness.';
		}

		return Card(
			margin: const EdgeInsets.only(bottom: 12),
			child: Padding(
				padding: const EdgeInsets.all(12),
				child: Column(
					crossAxisAlignment: CrossAxisAlignment.start,
					children: [
						Row(
							children: [
								CircleAvatar(child: Text('${widget.electrode.number}')),
								const SizedBox(width: 10),
								Expanded(
									child: Text(
										'Electrode ${widget.electrode.number}',
										style: const TextStyle(fontWeight: FontWeight.w600),
									),
								),
								IconButton(
									onPressed: widget.onOpenDetails,
									icon: const Icon(Icons.open_in_new),
									tooltip: 'Open details',
								),
								IconButton(
									onPressed: widget.onDelete,
									icon: const Icon(Icons.delete_outline),
									tooltip: 'Delete',
								),
							],
						),
						const SizedBox(height: 10),
						Row(
							children: [
								Expanded(
									child: _InputField(
										label: 'Coated Weight (mg) *',
										controller: _coatedWeightController,
										focusNode: widget.coatedWeightFocusNode,
										textInputAction: TextInputAction.next,
										errorText: coatedWeightError,
										onChanged: (value) {
											if (value != null) {
												widget.onCoatedWeightChanged(value);
											}
										},
										onSubmitted: (_) {
											FocusScope.of(context).requestFocus(widget.coatedThicknessFocusNode);
										},
									),
								),
								const SizedBox(width: 8),
								Expanded(
									child: _InputField(
										label: 'Coated Thickness (μm) *',
										controller: _coatedThicknessController,
										focusNode: widget.coatedThicknessFocusNode,
										textInputAction:
												_showCollectorOverrides ? TextInputAction.next : TextInputAction.done,
										errorText: coatedThicknessError,
										onChanged: (value) {
											if (value != null) {
												widget.onCoatedThicknessChanged(value);
											}
										},
										onSubmitted: (_) {
											if (_showCollectorOverrides) {
												FocusScope.of(context).requestFocus(widget.foilWeightFocusNode);
											} else {
												widget.onAdvanceToNextElectrode();
											}
										},
									),
								),
							],
						),
						const SizedBox(height: 6),
						ExpansionTile(
							initiallyExpanded: _showCollectorOverrides,
							onExpansionChanged: (expanded) {
								setState(() {
									_showCollectorOverrides = expanded;
								});
								if (!expanded) {
									widget.onFoilWeightOverrideChanged(null);
									widget.onFoilThicknessOverrideChanged(null);
								}
							},
							title: const Text('Collector Overrides (Optional)'),
							subtitle: widget.collectorPresetSuppliesFoilValues
								? const Text('Hidden by default because Collector preset supplies values')
								: const Text('Collector preset values not supplied'),
							children: [
								Padding(
									padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
									child: Column(
										children: [
											_InputField(
												label: 'Foil Weight (mg) - Optional',
												controller: _foilWeightController,
												focusNode: widget.foilWeightFocusNode,
												textInputAction: TextInputAction.next,
												onChanged: (value) {
													widget.onFoilWeightOverrideChanged(value);
												},
												onSubmitted: (_) {
													FocusScope.of(context).requestFocus(widget.foilThicknessFocusNode);
												},
											),
											const SizedBox(height: 8),
											_InputField(
												label: 'Foil Thickness (μm) - Optional',
												controller: _foilThicknessController,
												focusNode: widget.foilThicknessFocusNode,
												textInputAction: TextInputAction.done,
												onChanged: (value) {
													widget.onFoilThicknessOverrideChanged(value);
												},
												onSubmitted: (_) {
													widget.onAdvanceToNextElectrode();
												},
											),
										],
									),
								),
							],
						),
						if (_showCollectorOverrides) ...[
							const SizedBox(height: 8),
						],
						const SizedBox(height: 10),
						Wrap(
							spacing: 8,
							runSpacing: 8,
							children: [
								_ValueChip(
									label: 'Loading',
									value: '${result.loading.toStringAsFixed(2)} mg/cm²',
								),
								_ValueChip(
									label: 'Areal Capacity',
									value: '${result.arealCapacity.toStringAsFixed(2)} mAh/cm²',
								),
								_ValueChip(
									label: 'Density',
									value: '${result.electrodeDensity.toStringAsFixed(2)} g/cm³',
								),
								if (widget.pressEnabled && widget.pressTargetThicknessUm != null)
									_ValueChip(
										label: 'Press Target',
										value: '${widget.pressTargetThicknessUm!.toStringAsFixed(2)} μm',
									),
							],
						),
					],
				),
			),
		);
	}
}

class _InputField extends StatelessWidget {
	final String label;
	final TextEditingController controller;
	final FocusNode focusNode;
	final TextInputAction textInputAction;
	final String? errorText;
	final ValueChanged<double?> onChanged;
	final ValueChanged<String>? onSubmitted;

	const _InputField({
		required this.label,
		required this.controller,
		required this.focusNode,
		required this.textInputAction,
		this.errorText,
		required this.onChanged,
		this.onSubmitted,
	});

	@override
	Widget build(BuildContext context) {
		return TextField(
			controller: controller,
			focusNode: focusNode,
			textInputAction: textInputAction,
			keyboardType: const TextInputType.numberWithOptions(decimal: true),
			onChanged: (text) => onChanged(double.tryParse(text)),
			onSubmitted: onSubmitted,
			decoration: InputDecoration(
				labelText: label,
				errorText: errorText,
				isDense: true,
				border: OutlineInputBorder(
					borderRadius: BorderRadius.circular(10),
				),
			),
		);
	}
}

class _ValueChip extends StatelessWidget {
	final String label;
	final String value;

	const _ValueChip({
		required this.label,
		required this.value,
	});

	@override
	Widget build(BuildContext context) {
		return Container(
			padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
			decoration: BoxDecoration(
				color: Colors.blue.shade50,
				borderRadius: BorderRadius.circular(10),
			),
			child: Text('$label: $value'),
		);
	}
}
