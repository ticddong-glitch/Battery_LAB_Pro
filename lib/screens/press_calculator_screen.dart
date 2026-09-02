import 'package:flutter/material.dart';

import '../sevices/calculation_service.dart';

class PressCalculatorScreen extends StatefulWidget {
  const PressCalculatorScreen({super.key});

  @override
  State<PressCalculatorScreen> createState() => _PressCalculatorScreenState();
}

class _PressCalculatorScreenState extends State<PressCalculatorScreen> {
  final TextEditingController _loadingController = TextEditingController(text: '5.0');
  final TextEditingController _trueDensityController = TextEditingController(text: '1.55');
  final TextEditingController _targetPorosityController = TextEditingController(text: '40');
  final TextEditingController _measuredThicknessController = TextEditingController(text: '50');
  final TextEditingController _manualResultController = TextEditingController();

  bool _designMode = true;
  bool _skipMode = false;
  double? _manualResult;

  double _result = 0;
  double _solidThickness = 0;
  double _compressionRatio = 0;
  String? _validationMessage;

  @override
  void dispose() {
    _loadingController.dispose();
    _trueDensityController.dispose();
    _targetPorosityController.dispose();
    _measuredThicknessController.dispose();
    _manualResultController.dispose();
    super.dispose();
  }

  void _calculate() {
    final loading = double.tryParse(_loadingController.text) ?? 0;
    final trueDensity = double.tryParse(_trueDensityController.text) ?? 0;

    _solidThickness = CalculationService.calculateSolidThicknessUm(
      loadingMgPerCm2: loading,
      trueDensity: trueDensity,
    );

    if (_designMode) {
      final targetPorosity = double.tryParse(_targetPorosityController.text) ?? 0;
      _validationMessage = _skipMode
          ? null
          : CalculationService.validatePressDesign(
              loadingMgPerCm2: loading,
              trueDensity: trueDensity,
              targetPorosityPercent: targetPorosity,
            );
      _result = CalculationService.calculateTargetThickness(
        loadingMgPerCm2: loading,
        trueDensity: trueDensity,
        targetPorosityPercent: targetPorosity,
        skipMode: _skipMode,
        manualValue: _manualResult,
      );
      _compressionRatio = CalculationService.calculateCompressionRatioPercent(
        solidThicknessUm: _solidThickness,
        thicknessUm: _result,
      );
    } else {
      final measuredThickness = double.tryParse(_measuredThicknessController.text) ?? 0;
      _validationMessage = _skipMode
          ? null
          : CalculationService.validatePressAnalysis(
              loadingMgPerCm2: loading,
              trueDensity: trueDensity,
              measuredThicknessUm: measuredThickness,
            );
      _result = CalculationService.calculateCurrentPorosity(
        loadingMgPerCm2: loading,
        trueDensity: trueDensity,
        measuredThicknessUm: measuredThickness,
        skipMode: _skipMode,
        manualValue: _manualResult,
      );
      _compressionRatio = CalculationService.calculateCompressionRatioPercent(
        solidThicknessUm: _solidThickness,
        thicknessUm: measuredThickness,
      );
    }

    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    _calculate();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Press Calculator'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          RadioGroup<bool>(
            groupValue: _designMode,
            onChanged: (v) {
              if (v == null) {
                return;
              }
              setState(() {
                _designMode = v;
                _validationMessage = null;
              });
              _calculate();
            },
            child: Row(
              children: [
                Expanded(
                  child: RadioListTile<bool>(
                    title: const Text('Design Mode'),
                    value: true,
                  ),
                ),
                Expanded(
                  child: RadioListTile<bool>(
                    title: const Text('Analysis Mode'),
                    value: false,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _loadingController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(labelText: 'Loading (mg/cm²)'),
            onChanged: (_) => _calculate(),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _trueDensityController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(labelText: 'True Density (g/cm³)'),
            onChanged: (_) => _calculate(),
          ),
          const SizedBox(height: 12),
          if (_designMode) ...[
            TextField(
              controller: _targetPorosityController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Target Porosity (%)'),
              onChanged: (_) => _calculate(),
            ),
          ] else ...[
            TextField(
              controller: _measuredThicknessController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Measured Thickness (μm)'),
              onChanged: (_) => _calculate(),
            ),
          ],
          const SizedBox(height: 12),
          SwitchListTile(
            value: _skipMode,
            onChanged: (v) {
              setState(() {
                _skipMode = v;
                if (!v) {
                  _manualResult = null;
                  _manualResultController.clear();
                }
              });
              _calculate();
            },
            title: const Text('Skip Mode (manual result)'),
          ),
          if (_skipMode) ...[
            const SizedBox(height: 8),
            TextField(
              controller: _manualResultController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(labelText: _designMode ? 'Manual Thickness (μm)' : 'Manual Porosity (%)'),
              onChanged: (t) {
                _manualResult = double.tryParse(t);
                _calculate();
              },
            ),
          ],
          if (_validationMessage != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                _validationMessage!,
                style: TextStyle(color: Colors.red.shade800),
              ),
            ),
          ],
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _calculate,
            child: const Text('Calculate'),
          ),
          const SizedBox(height: 20),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _designMode ? 'Target Thickness (μm)' : 'Current Porosity (%)',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _result.toStringAsFixed(2),
                    style: const TextStyle(fontSize: 20),
                  ),
                  const SizedBox(height: 12),
                  Text('Solid Thickness (μm): ${_solidThickness.toStringAsFixed(2)}'),
                  const SizedBox(height: 4),
                  Text('Compression Ratio (%): ${_compressionRatio.toStringAsFixed(2)}'),
                  const SizedBox(height: 4),
                  Text('Mode: ${_skipMode ? 'Manual (Skip)' : 'Calculated'}'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
