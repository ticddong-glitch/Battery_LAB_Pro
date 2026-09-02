# Development Rules

1. UI must never contain formulas.

2. Every formula must be defined inside
LAB_Calculation_Specification.md.

3. Every calculation belongs to CalculationService.

4. Never duplicate calculation logic.

5. Shared Values are the single source of experiment defaults.

6. Protocols are templates.

Experiments store snapshots.

7. Every calculator supports Skip Mode when applicable.

8. Manual values must never be overwritten.

9. Every new calculator requires at least one unit test.

10. Every Sprint must compile successfully before starting the next Sprint.

## Recovery Rule

When compile errors exist,

DO NOT implement new features.

Always restore the project to a compiling state first.

Fix only:

- broken imports
- invalid file names
- missing references
- duplicate models

Resume feature development only after

flutter analyze

reports zero compile errors.