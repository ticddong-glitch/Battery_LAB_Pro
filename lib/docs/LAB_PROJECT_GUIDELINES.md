# LAB Calculator Project Guidelines

Version: 1.0

This document defines the design philosophy, architecture principles, and development rules of the LAB Calculator project.

Every future implementation must follow these guidelines.

---

# 1. Project Goal

LAB Calculator is NOT simply a calculator.

It is an experiment workflow platform for battery research laboratories.

Primary goals:

- Reduce repetitive work.
- Reduce human input errors.
- Standardize laboratory workflows.
- Minimize user input.
- Automate calculations.

---

# 2. Design Philosophy

## 2.1 Input Only Once

A value must never be entered twice.

If information already exists,
reuse it.

Example

Collector Preset

↓

Protocol

↓

Experiment

↓

Electrode

The user should never re-enter the same value.

---

## 2.2 Minimal Input

Only request values that satisfy one of these conditions.

① Required for calculations.

or

② Required as an experimental record.

Everything else should be removed.

---

## 2.3 Calculation First

The application exists to support laboratory calculations.

UI must never require unnecessary information.

---

# 3. Data Hierarchy

Preset

↓

Protocol

↓

Experiment

↓

Shared Values

↓

Electrode

Data always flows downward.

Never upward.

---

# 4. Snapshot Principle

Protocols are templates.

Creating an Experiment must create a snapshot.

Protocol

↓

Copy

↓

Experiment

Existing Experiments must never change when Protocols are edited later.

---

# 5. Shared Values

Shared Values contain values common to multiple electrodes.

Examples

- Collector
- Punch Diameter
- Active Material
- Conductive Additive
- Binder
- Composition
- Press Enabled
- Target Porosity

Electrodes inherit Shared Values.

Electrodes may override individual values.

---

# 6. Preset Philosophy

Everything repeatedly used in a laboratory should become a Preset.

Examples

Material Library

Collector Library

Future additions

Electrolyte Library

Separator Library

Coin Cell Library

Users create their own presets.

The application should never contain hardcoded laboratory data.

---

# 7. Material Rules

Each material stores

- Name
- Category
- True Density
- Specific Capacity (optional)
- Memo

Categories

- Active Material
- Conductive Additive
- Binder

---

# 8. Collector Rules

Collector Presets store

- Preset Name
- Material
- Thickness
- Punch Diameter
- Average Foil Weight
- Memo

Collector Density is NOT stored.

Only information actually required for calculations or repeated workflows should exist.

---

# 9. Press Philosophy

Press is optional.

Many laboratories do not use roll pressing.

Examples

Hard Carbon

↓

Press

Silicon

↓

No Press

BPOE

↓

No Press

If Press is disabled

Target Porosity must be disabled automatically.

---

# 10. Calculation Rules

Every calculation must follow

LAB_Calculation_Specification.md

No calculation may be implemented without documentation.

---

# 11. Record vs Calculation

Separate these concepts.

Calculation Data

↓

Used in formulas.

Experimental Record

↓

Stored only.

Never mix them.

---

# 12. Validation

The application should prevent invalid experiments.

Examples

Composition ≠ 100%

↓

Error

Missing Active Material

↓

Error

Target Porosity enabled while Press disabled

↓

Error

---

# 13. Repository Rule

UI

↓

Repository

↓

Storage

Never allow UI to access database code directly.

---

# 14. Future Compatibility

The application must support

- Windows
- Web
- Android (future)

Storage implementations may differ.

Business logic must remain identical.

---

# 15. Development Principles

Prefer

Small Sprint

Small Commit

Small Pull Request

Avoid large architectural changes.

---

# 16. Code Philosophy

Simple

Readable

Maintainable

No duplicated logic.

No duplicated input.

No unnecessary complexity.

---

# 17. Ultimate Goal

The application should become the standard laboratory workflow platform for battery electrode research.

The user should spend time performing experiments,

not entering data.

---

# 18. Workflow First

LAB Calculator is designed around laboratory workflows.

Features should reduce repetitive laboratory work rather than simply perform calculations.

Every new feature must satisfy at least one of the following:

- Reduce repeated user input.
- Reduce human error.
- Standardize laboratory workflows.
- Save experiment time.

Features that do not improve workflow should not be added.

---

# 19. Preset Philosophy

Repeated laboratory information must be stored as reusable Presets.

Examples

- Materials
- Collectors

Users define their own Presets.

The application must never assume a laboratory's standard values.

No hardcoded presets.

---

# 20. Collector Preset Rules

Collector Presets store only information required by calculations or repeated workflows.

Required

- Preset Name
- Collector Material
- Thickness
- Punch Diameter
- Average Foil Weight

Optional

- Memo

Collector Density is intentionally excluded.

---

# 21. Material Preset Rules

Material Presets store

Required

- Name
- Category
- True Density

Optional

- Specific Capacity
- Memo

Specific Capacity is only required for Active Materials.

Conductive Additives and Binders do not require Specific Capacity.

---

# 22. Workflow Priority

Whenever multiple implementation choices exist,

choose the option that minimizes user input.

The application should automatically inherit information whenever possible.

Users should never enter the same information twice.