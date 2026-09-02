import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:lab_calculator/sevices/calculation_service.dart';

void main() {
  group('LAB formula verification', () {
    test('Area formula matches specification', () {
      const diameterMm = 14.0;
      final areaCm2 = CalculationService.calculateArea(diameterMm);

      final expectedAreaCm2 = (math.pi * math.pow(diameterMm / 2, 2)) / 100;
      expect(areaCm2, closeTo(expectedAreaCm2, 1e-12));
    });

    test('Active Material Mass formula matches specification', () {
      const coatedWeightMg = 25.0;
      const foilWeightMg = 5.0;
      const activeMaterialRatioPercent = 94.0;

      final actual = CalculationService.calculateActiveMaterialMass(
        coatedWeightMg: coatedWeightMg,
        foilWeightMg: foilWeightMg,
        activeMaterialRatioPercent: activeMaterialRatioPercent,
      );

      const expected = (coatedWeightMg - foilWeightMg) * (activeMaterialRatioPercent / 100);
      expect(actual, closeTo(expected, 1e-12));
    });

    test('Loading formula matches specification', () {
      const activeMaterialMassMg = 18.8;
      const areaCm2 = 1.5393804002589986;

      final actual = CalculationService.calculateLoading(
        activeMaterialMassMg: activeMaterialMassMg,
        areaCm2: areaCm2,
      );

      const expected = activeMaterialMassMg / areaCm2;
      expect(actual, closeTo(expected, 1e-12));
    });

    test('Areal Capacity formula matches specification', () {
      const loadingMgPerCm2 = 12.212067189819845;
      const specificCapacityMahPerG = 180.0;

      final actual = CalculationService.calculateArealCapacity(
        loadingLevel: loadingMgPerCm2,
        specificCapacity: specificCapacityMahPerG,
      );

      const expected = loadingMgPerCm2 * specificCapacityMahPerG / 1000;
      expect(actual, closeTo(expected, 1e-12));
    });

    test('Electrode Density formula matches specification', () {
      const coatedWeightMg = 25.0;
      const foilWeightMg = 5.0;
      const diameterMm = 14.0;
      const coatedThicknessUm = 80.0;
      const foilThicknessUm = 20.0;

      final actual = CalculationService.calculateElectrodeDensity(
        coatedWeightMg: coatedWeightMg,
        foilWeightMg: foilWeightMg,
        diameterMm: diameterMm,
        coatedThicknessUm: coatedThicknessUm,
        foilThicknessUm: foilThicknessUm,
      );

      final coatingMassMg = coatedWeightMg - foilWeightMg;
      final coatingThicknessUm = coatedThicknessUm - foilThicknessUm;
      final electrodeAreaMm2 = math.pi * math.pow(diameterMm / 2, 2);
      final expected = (coatingMassMg * 1000) / (electrodeAreaMm2 * coatingThicknessUm);

      expect(actual, closeTo(expected, 1e-12));
    });

    test('Porosity formula matches specification and is in range', () {
      const electrodeDensity = 1.082992923894429;
      const trueDensity = 2.1;

      final actual = CalculationService.calculatePorosity(
        electrodeDensity: electrodeDensity,
        trueDensity: trueDensity,
      );

      const expected = (1 - (electrodeDensity / trueDensity)) * 100;
      expect(actual, closeTo(expected, 1e-12));
      expect(actual, inInclusiveRange(0, 100));
    });

    test('Press calculator formulas match specification (design mode)', () {
      const loadingMgPerCm2 = 12.0;
      const trueDensity = 2.0;
      const targetPorosityPercent = 40.0;

      final solidThicknessUm = CalculationService.calculateSolidThicknessUm(
        loadingMgPerCm2: loadingMgPerCm2,
        trueDensity: trueDensity,
      );

      final targetThicknessUm = CalculationService.calculateTargetThickness(
        loadingMgPerCm2: loadingMgPerCm2,
        trueDensity: trueDensity,
        targetPorosityPercent: targetPorosityPercent,
      );

      const expectedSolidThickness = (loadingMgPerCm2 / trueDensity) * 10;
      const expectedTargetThickness = expectedSolidThickness / (1 - (targetPorosityPercent / 100));

      expect(solidThicknessUm, closeTo(expectedSolidThickness, 1e-12));
      expect(targetThicknessUm, closeTo(expectedTargetThickness, 1e-12));
    });

    test('Press calculator formulas match specification (analysis mode)', () {
      const loadingMgPerCm2 = 12.0;
      const trueDensity = 2.0;
      const measuredThicknessUm = 100.0;

      final currentPorosityPercent = CalculationService.calculateCurrentPorosity(
        loadingMgPerCm2: loadingMgPerCm2,
        trueDensity: trueDensity,
        measuredThicknessUm: measuredThicknessUm,
      );

      final electrodeDensity = (loadingMgPerCm2 / 1000) / (measuredThicknessUm / 10000);
      final expectedPorosityPercent = (1 - (electrodeDensity / trueDensity)) * 100;

      expect(currentPorosityPercent, closeTo(expectedPorosityPercent, 1e-12));
      expect(currentPorosityPercent, inInclusiveRange(0, 100));
    });

    test('Slurry calculator formulas match specification', () {
      const loadingMgPerCm2 = 12.0;
      const areaCm2 = 1.54;
      const solidContent = 0.6;

      final requiredActiveMaterialMg = CalculationService.calculateRequiredActiveMaterialForSlurry(
        loadingMgPerCm2: loadingMgPerCm2,
        electrodeAreaCm2: areaCm2,
      );

      final requiredSlurryMg = CalculationService.calculateRequiredSlurryMass(
        requiredActiveMaterialMg: requiredActiveMaterialMg,
        solidContent: solidContent,
      );

      const expectedActiveMaterialMg = loadingMgPerCm2 * areaCm2;
      const expectedSlurryMg = expectedActiveMaterialMg / solidContent;

      expect(requiredActiveMaterialMg, closeTo(expectedActiveMaterialMg, 1e-12));
      expect(requiredSlurryMg, closeTo(expectedSlurryMg, 1e-12));
    });
  });
}
