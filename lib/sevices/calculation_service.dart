import 'dart:math' as math;

import '../models/calculation_result.dart';
import '../models/electrode.dart';

class CalculationService {
  static const double _pi = math.pi;

  static double calculateCoatingMassMg({
    required double coatedWeightMg,
    required double foilWeightMg,
  }) {
    return coatedWeightMg - foilWeightMg;
  }

  static double calculateActiveCoatingThicknessUm({
    required double coatedThicknessUm,
    required double foilThicknessUm,
  }) {
    return coatedThicknessUm - foilThicknessUm;
  }

  static double calculateAreaMm2(
    double diameterMm, {
    bool skipMode = false,
    double? manualAreaCm2,
  }) {
    if (skipMode && manualAreaCm2 != null) {
      return manualAreaCm2 * 100;
    }

    if (diameterMm <= 0) {
      return 0;
    }

    final radiusMm = diameterMm / 2;
    return _pi * radiusMm * radiusMm;
  }

  static double convertAreaMm2ToCm2(double areaMm2) {
    if (areaMm2 <= 0) {
      return 0;
    }
    return areaMm2 / 100;
  }

  static String? validateInputs({
    required double coatedWeightMg,
    required double foilWeightMg,
    required double activeMaterialRatioPercent,
    required double diameterMm,
    required double coatedThicknessUm,
    required double foilThicknessUm,
    required double trueDensity,
    required double specificCapacity,
  }) {
    final messages = <String>[];

    if (diameterMm <= 0) {
      messages.add('Diameter must be greater than 0.');
    }
    if (coatedWeightMg <= foilWeightMg) {
      messages.add('Coated weight must be greater than foil weight.');
    }
    if (coatedThicknessUm <= foilThicknessUm) {
      messages.add('Coated thickness must be greater than foil thickness.');
    }
    if (activeMaterialRatioPercent < 0 || activeMaterialRatioPercent > 100) {
      messages.add('Active material ratio must be between 0 and 100.');
    }

    if (messages.isEmpty) {
      return null;
    }

    return messages.join('\n');
  }

  static double calculateArea(
    double diameterMm, {
    bool skipMode = false,
    double? manualValue,
  }) {
    final areaMm2 = calculateAreaMm2(
      diameterMm,
      skipMode: skipMode,
      manualAreaCm2: manualValue,
    );
    return convertAreaMm2ToCm2(areaMm2);
  }

  static double calculateElectrodeArea(
    double diameterMm, {
    bool skipMode = false,
    double? manualValue,
  }) {
    return calculateArea(
      diameterMm,
      skipMode: skipMode,
      manualValue: manualValue,
    );
  }

  static double calculateActiveMaterialMass({
    required double coatedWeightMg,
    required double foilWeightMg,
    required double activeMaterialRatioPercent,
    bool skipMode = false,
    double? manualValue,
  }) {
    if (skipMode && manualValue != null) {
      return manualValue;
    }

    final coatingMassMg = coatedWeightMg - foilWeightMg;
    if (coatedWeightMg <= foilWeightMg || activeMaterialRatioPercent < 0) {
      return 0;
    }
    return coatingMassMg * (activeMaterialRatioPercent / 100);
  }

  static double calculateLoading({
    required double activeMaterialMassMg,
    required double areaCm2,
    bool skipMode = false,
    double? manualValue,
  }) {
    if (skipMode && manualValue != null) {
      return manualValue;
    }

    if (areaCm2 <= 0) {
      return 0;
    }
    return activeMaterialMassMg / areaCm2;
  }

  static double calculateLoadingLevel({
    required double activeMaterialMassMg,
    required double areaCm2,
    bool skipMode = false,
    double? manualValue,
  }) {
    return calculateLoading(
      activeMaterialMassMg: activeMaterialMassMg,
      areaCm2: areaCm2,
      skipMode: skipMode,
      manualValue: manualValue,
    );
  }

  static double calculateArealCapacity({
    required double loadingLevel,
    required double specificCapacity,
    bool skipMode = false,
    double? manualValue,
  }) {
    if (skipMode && manualValue != null) {
      return manualValue;
    }

    return (loadingLevel * specificCapacity) / 1000;
  }

  static double calculateElectrodeDensity({
    required double coatedWeightMg,
    required double foilWeightMg,
    required double diameterMm,
    required double coatedThicknessUm,
    required double foilThicknessUm,
    bool skipMode = false,
    double? manualValue,
  }) {
    if (skipMode && manualValue != null) {
      return manualValue;
    }

    final coatingMassMg = calculateCoatingMassMg(
      coatedWeightMg: coatedWeightMg,
      foilWeightMg: foilWeightMg,
    );
    final coatingThicknessUm = calculateActiveCoatingThicknessUm(
      coatedThicknessUm: coatedThicknessUm,
      foilThicknessUm: foilThicknessUm,
    );
    final areaMm2 = calculateAreaMm2(diameterMm);

    if (
        coatedWeightMg <= foilWeightMg ||
        diameterMm <= 0 ||
        areaMm2 <= 0 ||
        coatingThicknessUm <= 0) {
      return 0;
    }

    // g/cm3 = (mg * 1000) / (mm2 * um)
    return (coatingMassMg * 1000) / (areaMm2 * coatingThicknessUm);
  }

  static double calculatePorosity({
    required double electrodeDensity,
    required double trueDensity,
    bool skipMode = false,
    double? manualValue,
  }) {
    if (skipMode && manualValue != null) {
      return manualValue;
    }

    if (trueDensity <= 0) {
      return 0;
    }

    final porosityRatio = 1 - (electrodeDensity / trueDensity);
    return (porosityRatio * 100).clamp(0, 100);
  }

  /// Press Calculator (Design Mode)
  ///
  /// Given loading (mg/cm²), true density (g/cm³) and target porosity (%),
  /// compute target thickness in μm.
  /// Formula derivation:
  /// - mass per area (g/cm²) = loading(mg/cm²) / 1000
  /// - electrodeDensity = trueDensity * (1 - porosityFraction)
  /// - thickness_cm = mass_per_area / electrodeDensity
  /// - thickness_um = thickness_cm * 1e4
  /// Simplified: thickness_um = (loading * 10) / (trueDensity * (1 - porosityFraction))
  static double calculateTargetThickness({
    required double loadingMgPerCm2,
    required double trueDensity,
    required double targetPorosityPercent,
    bool skipMode = false,
    double? manualValue,
  }) {
    if (skipMode && manualValue != null) return manualValue;

    if (loadingMgPerCm2 <= 0 || trueDensity <= 0) return 0;

    final porosityFraction = (targetPorosityPercent / 100).clamp(0.0, 0.99);
    final denom = trueDensity * (1 - porosityFraction);
    if (denom <= 0) return 0;

    // thickness in μm
    final thicknessUm = (loadingMgPerCm2 * 10) / denom;
    return thicknessUm;
  }

  /// Solid thickness (no porosity) derived from loading and true density.
  /// Formula from spec: solidThickness(um) = loading/trueDensity * 10000
  static double calculateSolidThicknessUm({
    required double loadingMgPerCm2,
    required double trueDensity,
  }) {
    if (loadingMgPerCm2 <= 0 || trueDensity <= 0) return 0;
    return (loadingMgPerCm2 / trueDensity) * 10;
  }

  /// Press Calculator (Analysis Mode)
  ///
  /// Given loading (mg/cm²), true density (g/cm³) and measured thickness (μm),
  /// compute current porosity (%).
  static double calculateCurrentPorosity({
    required double loadingMgPerCm2,
    required double trueDensity,
    required double measuredThicknessUm,
    bool skipMode = false,
    double? manualValue,
  }) {
    if (skipMode && manualValue != null) return manualValue;

    if (loadingMgPerCm2 <= 0 || trueDensity <= 0 || measuredThicknessUm <= 0) return 0;

    // electrode density (g/cm3) = (loading mg/cm2 -> g/cm2) / thickness_cm
    // thickness_cm = measuredThicknessUm / 1e4
    final electrodeDensity = (loadingMgPerCm2 / 1000) / (measuredThicknessUm / 1e4);

    final porosity = 1 - (electrodeDensity / trueDensity);
    return (porosity * 100).clamp(0, 100);
  }

  /// Compression ratio (%): solid thickness / target(or measured) thickness * 100
  static double calculateCompressionRatioPercent({
    required double solidThicknessUm,
    required double thicknessUm,
  }) {
    if (solidThicknessUm <= 0 || thicknessUm <= 0) return 0;
    return ((solidThicknessUm / thicknessUm) * 100).clamp(0, 100);
  }

  /// Slurry Calculator: required active material mass (mg)
  /// Formula from spec: loading(mg/cm2) * area(cm2)
  static double calculateRequiredActiveMaterialForSlurry({
    required double loadingMgPerCm2,
    required double electrodeAreaCm2,
    bool skipMode = false,
    double? manualValue,
  }) {
    if (skipMode && manualValue != null) return manualValue;
    if (loadingMgPerCm2 <= 0 || electrodeAreaCm2 <= 0) return 0;
    return loadingMgPerCm2 * electrodeAreaCm2;
  }

  /// Slurry Calculator: required slurry mass (mg)
  /// Formula from spec: requiredActiveMaterial / solidContent
  /// solidContent is expected to be a fraction in range (0, 1].
  static double calculateRequiredSlurryMass({
    required double requiredActiveMaterialMg,
    required double solidContent,
    bool skipMode = false,
    double? manualValue,
  }) {
    if (skipMode && manualValue != null) return manualValue;
    if (requiredActiveMaterialMg <= 0 || solidContent <= 0) return 0;
    return requiredActiveMaterialMg / solidContent;
  }

  static String? validatePressDesign({
    required double loadingMgPerCm2,
    required double trueDensity,
    required double targetPorosityPercent,
  }) {
    final messages = <String>[];
    if (loadingMgPerCm2 <= 0) messages.add('Loading must be greater than 0.');
    if (trueDensity <= 0) messages.add('True density must be greater than 0.');
    if (targetPorosityPercent < 0 || targetPorosityPercent > 100) {
      messages.add('Target porosity must be between 0 and 100.');
    }
    if (messages.isEmpty) return null;
    return messages.join('\n');
  }

  static String? validatePressAnalysis({
    required double loadingMgPerCm2,
    required double trueDensity,
    required double measuredThicknessUm,
  }) {
    final messages = <String>[];
    if (loadingMgPerCm2 <= 0) messages.add('Loading must be greater than 0.');
    if (trueDensity <= 0) messages.add('True density must be greater than 0.');
    if (measuredThicknessUm <= 0) messages.add('Measured thickness must be greater than 0.');
    if (messages.isEmpty) return null;
    return messages.join('\n');
  }

  static CalculationResult calculateForElectrode({
    required Electrode electrode,
    required double activeMaterialRatioPercent,
    required double specificCapacity,
    required double trueDensity,
    double? foilWeightMg,
    double? foilThicknessUm,
    bool useElectrodeOverrides = true,
    bool skipMode = false,
    double? manualArea,
    double? manualActiveMaterialMass,
    double? manualLoading,
    double? manualArealCapacity,
    double? manualElectrodeDensity,
    double? manualPorosity,
  }) {
    final input = electrode.input;
    final resolvedActiveMaterialRatio = useElectrodeOverrides
      ? electrode.resolveValue('activeMaterialRatio', activeMaterialRatioPercent)
      : activeMaterialRatioPercent;
    final resolvedSpecificCapacity = useElectrodeOverrides
      ? electrode.resolveValue('specificCapacity', specificCapacity)
      : specificCapacity;
    final resolvedTrueDensity = useElectrodeOverrides
      ? electrode.resolveValue('trueDensity', trueDensity)
      : trueDensity;
    final resolvedFoilWeight = useElectrodeOverrides
      ? electrode.resolveValue('averageFoilWeight', foilWeightMg ?? input.collectorMass)
      : (foilWeightMg ?? input.collectorMass);
    final resolvedFoilThickness = useElectrodeOverrides
      ? electrode.resolveValue('foilThickness', foilThicknessUm ?? 0)
      : (foilThicknessUm ?? 0);

    final effectiveFoilWeight = resolvedFoilWeight;
    final effectiveFoilThickness = resolvedFoilThickness;

    final validationMessage = validateInputs(
      coatedWeightMg: input.totalMass,
      foilWeightMg: effectiveFoilWeight,
      activeMaterialRatioPercent: resolvedActiveMaterialRatio,
      diameterMm: input.diameter,
      coatedThicknessUm: input.thickness,
      foilThicknessUm: effectiveFoilThickness,
      trueDensity: resolvedTrueDensity,
      specificCapacity: resolvedSpecificCapacity,
    );

    final area = calculateArea(
      input.diameter,
      skipMode: skipMode,
      manualValue: manualArea,
    );
    final areaState = (skipMode && manualArea != null)
        ? CalculationState.manual
        : (input.diameter > 0 ? CalculationState.calculated : CalculationState.empty);

    final activeMaterialMass = calculateActiveMaterialMass(
      coatedWeightMg: input.totalMass,
      foilWeightMg: effectiveFoilWeight,
      activeMaterialRatioPercent: resolvedActiveMaterialRatio,
      skipMode: skipMode,
      manualValue: manualActiveMaterialMass,
    );
    final activeMaterialMassState =
        (skipMode && manualActiveMaterialMass != null)
            ? CalculationState.manual
            : (input.totalMass > effectiveFoilWeight &&
                  resolvedActiveMaterialRatio >= 0 &&
                  resolvedActiveMaterialRatio <= 100
                ? CalculationState.calculated
                : CalculationState.empty);

    final loading = calculateLoading(
      activeMaterialMassMg: activeMaterialMass,
      areaCm2: area,
      skipMode: skipMode,
      manualValue: manualLoading,
    );
    final loadingState = (skipMode && manualLoading != null)
        ? CalculationState.manual
      : (area > 0 && activeMaterialMass > 0
        ? CalculationState.calculated
        : CalculationState.empty);

    final arealCapacity = calculateArealCapacity(
      loadingLevel: loading,
      specificCapacity: resolvedSpecificCapacity,
      skipMode: skipMode,
      manualValue: manualArealCapacity,
    );
    final arealCapacityState = (skipMode && manualArealCapacity != null)
        ? CalculationState.manual
        : (loading > 0 ? CalculationState.calculated : CalculationState.empty);

    final electrodeDensity = calculateElectrodeDensity(
      coatedWeightMg: input.totalMass,
      foilWeightMg: effectiveFoilWeight,
      diameterMm: input.diameter,
      coatedThicknessUm: input.thickness,
      foilThicknessUm: effectiveFoilThickness,
      skipMode: skipMode,
      manualValue: manualElectrodeDensity,
    );
    final electrodeDensityState = (skipMode && manualElectrodeDensity != null)
      ? CalculationState.manual
      : (input.totalMass > effectiveFoilWeight &&
          input.diameter > 0 &&
          input.thickness > effectiveFoilThickness
        ? CalculationState.calculated
        : CalculationState.empty);

    final porosity = calculatePorosity(
      electrodeDensity: electrodeDensity,
      trueDensity: resolvedTrueDensity,
      skipMode: skipMode,
      manualValue: manualPorosity,
    );
    final porosityState = (skipMode && manualPorosity != null)
        ? CalculationState.manual
        : (resolvedTrueDensity > 0 && electrodeDensity >= 0
            ? CalculationState.calculated
            : CalculationState.empty);

    return CalculationResult(
      area: area,
      areaState: areaState,
      activeMaterialMass: activeMaterialMass,
      activeMaterialMassState: activeMaterialMassState,
      loading: loading,
      loadingState: loadingState,
      arealCapacity: arealCapacity,
      arealCapacityState: arealCapacityState,
      electrodeDensity: electrodeDensity,
      electrodeDensityState: electrodeDensityState,
      porosity: porosity,
      porosityState: porosityState,
      theoreticalCapacity: resolvedSpecificCapacity,
      theoreticalCapacityState: CalculationState.calculated,
      skipMode: skipMode,
      validationMessage: validationMessage,
    );
  }
}
