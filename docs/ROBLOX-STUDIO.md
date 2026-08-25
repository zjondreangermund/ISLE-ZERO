# Roblox Studio Setup

## Recommended workflow
1. Install Rokit, or use the Rojo VS Code extension.
2. Clone this repository.
3. If using Rokit, run `rokit install` in the repository root. This installs the pinned Rojo, Selene and StyLua versions from `rokit.toml`.
4. Start Rojo with `rojo serve`, or use **Rojo: Open Menu** from the VS Code Command Palette.
5. Open a new Baseplate place in Roblox Studio.
6. Connect the Rojo Studio plugin to the running project.
7. Sync the project.
8. Press Play. The server bootstrap removes the untouched default Baseplate/SpawnLocation and generates the island in `Workspace/ISLE_ZERO_WORLD`.

The client displays an **ISLE//ZERO** generation screen while the server moves through Atmosphere, Terrain, Coast, NaturalFeatures, Paths, Landmarks, Vegetation, Audit and SpawnRelease.

## Studio-only world settings
A few Roblox environment properties cannot be changed by ordinary runtime scripts and should be set once in Studio:
- `Workspace.Terrain.Decoration` = **true** for animated terrain grass when desired.
- `Workspace.FallenPartsDestroyHeight` = approximately **-500**.
- Enable instance streaming later when the art-pass model count becomes heavy; do not rely on a runtime script to toggle Studio-only streaming configuration.

If you intentionally keep a custom object named `Baseplate` or `SpawnLocation`, add the Boolean attribute `PreserveForISLEZero = true` so the world bootstrap leaves it alone.

## Important
The generator rebuilds when the generated world is missing, its `WorldVersion` differs from `WorldConfig.WorldVersion`, or the previous build did not reach `BuildComplete = true`. A failed partial world therefore does not masquerade as a valid current build.

During Play Solo, the runtime world is temporary. If you want to preserve a generated snapshot for art-pass work, generate it in Studio and save a separate `.rbxl` working place locally; do not commit the binary place file to this repository.

## Studio development commands
These commands only exist while running inside Roblox Studio:

- `/worldstatus` — prints world version, seed, phase, audit totals, path grade and terrain metrics.
- `/worldaudit` — reruns the full non-destructive world audit against the current generated island.
- `/worldrebuild` — performs a full safe regeneration without requiring Studio to be restarted.

The rebuild command is guarded so a second generation cannot start while one is already running.

## Regenerating after map code changes
For normal Studio iteration, use `/worldrebuild` during a Play test. When geometry/config meaning changes, also increment `WorldConfig.WorldVersion` so fresh sessions clearly identify the revision.

## Replacing placeholders with real assets
The procedural world uses stable folders, tags and attributes. Replace models inside `Landmarks`, `NaturalFeatures`, `Vegetation` or `CoastAndIslets` gradually. Keep landmark names and `LandmarkId`/`FeatureId` attributes if later gameplay systems reference them.

## World preflight and audit
Before the place is mutated, `WorldPreflight.lua` validates world size, terrain settings, paths, scenic zones, spawn configuration and generation/audit thresholds. A preflight error stops before terrain is cleared.

Every successful generation then runs `WorldAudit.lua`. Check Studio Output for:

`[ISLE//ZERO][WORLD AUDIT] PASS`

The audit also reports:
- missing required world folders and landmarks;
- path points outside playable land;
- steepest sampled trail grade;
- crash-spawn solid clearance;
- landmark spacing warnings;
- generated descendant count and performance budget warnings;
- world seed and version.

The generated root exposes the same important values as attributes, including `AuditErrors`, `AuditWarnings`, `GeneratedDescendants`, `WorstPathGrade`, `TerrainSampledCells` and `TerrainFilledColumns`.

## GitHub validation
Pushes and pull requests run the **Rojo Build Check** workflow. It installs the pinned Rokit toolchain, runs `selene src`, builds `default.project.json` with Rojo and uploads the resulting `.rbxlx` as a temporary workflow artifact.

The workflow uses concurrency cancellation so only the newest commit on a branch needs to finish when several world edits are pushed quickly.

## Performance notes
The first generation pass is intentionally moderate in density. Do not increase vegetation counts blindly. Decorative path pieces and driftwood have unnecessary touch/query work disabled, and the runtime audit warns if generated descendants rise beyond the configured budget. Prefer fewer high-quality grouped meshes later and enable Roblox streaming in the final place settings once the island art pass becomes heavier.
