# LAB Data Model

Version 1.0

This document defines the data structure used throughout LAB Calculator.

---

# Data Hierarchy

MaterialPreset
        │
CollectorPreset
        │
        ▼
Protocol
        │
        ▼
Experiment
        │
        ▼
SharedValues
        │
        ▼
Electrode

Data always flows downward.

Protocols create snapshots.

Experiments never modify Protocols.

---

# MaterialPreset

Purpose

Store reusable material information.

Fields

- id
- name
- category
- trueDensity
- specificCapacity (optional)
- memo

Category

- Active Material
- Conductive Additive
- Binder

---

# CollectorPreset

Purpose

Store reusable collector information.

Fields

- id
- presetName
- collectorMaterial
- thickness
- punchDiameter
- averageFoilWeight
- memo

---

# Protocol

Purpose

Reusable experiment template.

Fields

General

- id
- name
- memo

Materials

- activeMaterialPresetId
- conductivePresetId
- binderPresetId

Composition

- activeRatio
- conductiveRatio
- binderRatio

Collector

- collectorPresetId

Press

- pressEnabled
- targetPorosity (optional)

Experimental Record

- dryingTemperature (optional)
- dryingTime (optional)
- rollPressPressure (optional)

---

# Experiment

Purpose

A snapshot created from a Protocol.

Fields

- id
- name
- createdAt
- updatedAt

Protocol Snapshot

Shared Values

Electrode List

Memo

Experiments never reference Protocols.

---

# Shared Values

Purpose

Store values shared by all electrodes.

Fields

- activeMaterial
- conductive
- binder

- composition

- collectorPreset

- punchDiameter

- pressEnabled

- targetPorosity

Override is allowed.

---

# Electrode

Purpose

Store measurements for a single electrode.

Fields

Input

- coatedWeight
- coatedThickness

Calculated

- loadingLevel
- arealCapacity
- electrodeDensity
- porosity
- targetThickness

Override

Optional override for Shared Values.

---

# Data Ownership

MaterialPreset

↓

Protocol

↓

Experiment Snapshot

↓

Shared Values

↓

Electrode

No upward references.

No duplicated data.

No duplicated user input.

---

# Storage

Repository

↓

SQLite (Windows)

↓

Web Storage (Web)

Business logic must remain identical.

---

# Material Preset

id : String

name : String

category : MaterialCategory

trueDensity : double

specificCapacity : double?

memo : String

---

End of Document