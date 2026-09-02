# LAB Calculation Specification

Version 2.0

This document defines every calculation implemented in LAB Calculator.

All calculation logic must follow this specification.

---

# 1. General Rules

1. Every calculator supports Skip Mode.

2. Users may manually enter calculated values.

3. Every calculation automatically performs required unit conversions.

4. Users should never enter duplicate information.

5. Values stored in Material Presets and Collector Presets are automatically used whenever available.

6. Calculation modules must never contain hardcoded laboratory values.

---

# 2. Calculation Modules

---

## 2.1 Loading Level

### Purpose

Calculate active material loading.

### Required Input

- Foil Weight (mg)
- Coated Electrode Weight (mg)
- Active Material Ratio (%)
- Electrode Diameter (mm)

### Formula

Active Material Mass

=

(Coated Weight − Foil Weight)

×

(Active Material Ratio / 100)

Radius

=

Diameter / 2

Area (mm²)

=

π × Radius²

Area (cm²)

=

Area(mm²) / 100

Loading Level

=

Active Material Mass

/

Area(cm²)

### Output

- Active Material Mass (mg)
- Area (mm²)
- Area (cm²)
- Loading Level (mg/cm²)

---

## 2.2 Areal Capacity

### Purpose

Calculate areal capacity.

### Required Input

- Loading Level (mg/cm²)
- Specific Capacity (mAh/g)

### Formula

Areal Capacity

=

Loading Level

×

Specific Capacity

/

1000

### Output

- Areal Capacity (mAh/cm²)

### Data Source

Specific Capacity

↓

Material Preset

↓

User Override (optional)

---

## 2.3 Electrode Density

### Purpose

Calculate coating density.

### Required Input

- Foil Weight (mg)
- Coated Electrode Weight (mg)
- Electrode Diameter (mm)
- Coated Thickness (μm)
- Foil Thickness (μm)

### Formula

Coating Mass

=

Coated Weight − Foil Weight

Active Coating Thickness

=

Coated Thickness − Foil Thickness

Electrode Area

=

π × (Diameter / 2)²

Electrode Density

=

Coating Mass

/

(Electrode Area × Active Coating Thickness)

### Output

- Electrode Density (g/cm³)

---

## 2.4 Porosity

### Purpose

Calculate electrode porosity.

### Required Input

- Electrode Density (g/cm³)
- Mixture True Density (g/cm³)

### Formula

Porosity

=

1 −

(Electrode Density

/

Mixture True Density)

### Output

- Porosity (%)

---

## 2.5 Press Calculator

### Purpose

Estimate the required pressed electrode thickness.

### Enabled

Only when

Press Enabled = TRUE

If FALSE

↓

This calculator is skipped.

### Required Input

- Electrode Weight
- Collector Average Weight
- Electrode Diameter
- Mixture True Density

### Optional Input

- Target Porosity

### Formula

Solid Thickness

=

Loading Level

/

Mixture True Density

×

10000

Target Thickness

=

Solid Thickness

/

(1 − Target Porosity)

### Output

- Target Thickness (μm)

### Data Source

Loading Level

↓

Loading Calculator

OR

Skip Mode

Mixture True Density

↓

Automatically calculated from

- Active Material
- Conductive Additive
- Binder

using

- Composition Ratio
- True Density

Users should never calculate Mixture True Density manually.

---

# 3. Future Calculation Modules

The following calculators are planned for future versions.

They are NOT required for Version 1.0.

---

## Slurry Mass Calculator

### Required Input

- Loading Level
- Electrode Area
- Solid Content

### Formula

Required Active Material

=

Loading × Area

Required Slurry

=

Required Active Material

/

Solid Content

---

# 4. Material Preset

Each Material Preset stores

Required

- Name
- Category
- True Density

Optional

- Specific Capacity
- Memo

Specific Capacity is required only for

Active Materials.

Conductive Additives and Binders do not require it.

---

# 5. Collector Preset

Each Collector Preset stores

Required

- Preset Name
- Collector Material
- Thickness
- Punch Diameter
- Average Foil Weight

Optional

- Memo

Collector Density is intentionally excluded.

Only information required for calculations or repeated laboratory workflows shall be stored.

---

# 6. Global Validation Rules

Loading Calculator

- Diameter > 0
- Coated Weight > Foil Weight

Electrode Density

- Coated Thickness > Foil Thickness

Porosity

- Mixture True Density > 0
- Electrode Density > 0

Press Calculator

- Loading Level > 0
- Target Porosity = 0–100%

Protocol

- Composition = 100%
- Active Material required
- Collector Preset required

Press

If Press Enabled = FALSE

↓

Target Porosity is disabled.

---

# 7. Unit Policy

## User Input

- Diameter : mm
- Thickness : μm
- Weight : mg
- Ratio : %
- Specific Capacity : mAh/g

---

## Internal Storage

- Diameter : mm
- Area : mm²
- Weight : mg

---

## Calculation Output

- Loading Level : mg/cm²
- Areal Capacity : mAh/cm²
- Electrode Density : g/cm³
- Porosity : %
- Target Thickness : μm

---

# 8. Data Dependency

Material Preset

↓

Loading Level

↓

Areal Capacity

Material Preset

↓

Mixture True Density

↓

Porosity

Material Preset

↓

Mixture True Density

↓

Press Calculator

Collector Preset

↓

Loading Level

↓

Electrode Density

Protocol

↓

Experiment Snapshot

↓

Shared Values

↓

Electrode

---

End of Specification