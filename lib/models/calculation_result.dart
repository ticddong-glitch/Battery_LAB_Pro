enum CalculationState {
  calculated,
  manual,
  empty,
}

class CalculationResult {
  /// Electrode area (cm²)
  double area;
  CalculationState areaState;

  /// Active Material Mass (mg)
  double activeMaterialMass;
  CalculationState activeMaterialMassState;

  /// Loading (mg/cm²)
  double loading;
  CalculationState loadingState;

  /// Areal Capacity (mAh/cm²)
  double arealCapacity;
  CalculationState arealCapacityState;

  /// Electrode Density (g/cm³)
  double electrodeDensity;
  CalculationState electrodeDensityState;

  /// Porosity (%)
  double porosity;
  CalculationState porosityState;

  /// Theoretical Capacity (mAh/g)
  double theoreticalCapacity;
  CalculationState theoreticalCapacityState;

  /// Indicates whether the workflow is in skip/manual mode.
  bool skipMode;

  /// Optional validation message for invalid inputs
  String? validationMessage;

  CalculationResult({
    this.area = 0,
    this.areaState = CalculationState.empty,
    this.activeMaterialMass = 0,
    this.activeMaterialMassState = CalculationState.empty,
    this.loading = 0,
    this.loadingState = CalculationState.empty,
    this.arealCapacity = 0,
    this.arealCapacityState = CalculationState.empty,
    this.electrodeDensity = 0,
    this.electrodeDensityState = CalculationState.empty,
    this.porosity = 0,
    this.porosityState = CalculationState.empty,
    this.theoreticalCapacity = 0,
    this.theoreticalCapacityState = CalculationState.empty,
    this.skipMode = false,
    this.validationMessage,
  });

  Map<String, Object?> toMap() {
    return {
      'area': area,
      'areaState': areaState.index,
      'activeMaterialMass': activeMaterialMass,
      'activeMaterialMassState': activeMaterialMassState.index,
      'loading': loading,
      'loadingState': loadingState.index,
      'arealCapacity': arealCapacity,
      'arealCapacityState': arealCapacityState.index,
      'electrodeDensity': electrodeDensity,
      'electrodeDensityState': electrodeDensityState.index,
      'porosity': porosity,
      'porosityState': porosityState.index,
      'theoreticalCapacity': theoreticalCapacity,
      'theoreticalCapacityState': theoreticalCapacityState.index,
      'skipMode': skipMode ? 1 : 0,
      'validationMessage': validationMessage,
    };
  }

  static CalculationState _safeState(Object? raw) {
    final index = (raw as int?) ?? 0;
    if (index < 0 || index >= CalculationState.values.length) {
      return CalculationState.empty;
    }
    return CalculationState.values[index];
  }

  static CalculationResult fromMap(Map<String, Object?> m) {
    CalculationResult r = CalculationResult(
      area: (m['area'] as num?)?.toDouble() ?? 0,
      areaState: _safeState(m['areaState']),
      activeMaterialMass: (m['activeMaterialMass'] as num?)?.toDouble() ?? 0,
      activeMaterialMassState: _safeState(m['activeMaterialMassState']),
      loading: (m['loading'] as num?)?.toDouble() ?? 0,
      loadingState: _safeState(m['loadingState']),
      arealCapacity: (m['arealCapacity'] as num?)?.toDouble() ?? 0,
      arealCapacityState: _safeState(m['arealCapacityState']),
      electrodeDensity: (m['electrodeDensity'] as num?)?.toDouble() ?? 0,
      electrodeDensityState: _safeState(m['electrodeDensityState']),
      porosity: (m['porosity'] as num?)?.toDouble() ?? 0,
      porosityState: _safeState(m['porosityState']),
      theoreticalCapacity: (m['theoreticalCapacity'] as num?)?.toDouble() ?? 0,
      theoreticalCapacityState: _safeState(m['theoreticalCapacityState']),
      skipMode: (m['skipMode'] as int?) == 1,
      validationMessage: m['validationMessage'] as String?,
    );
    return r;
  }
}