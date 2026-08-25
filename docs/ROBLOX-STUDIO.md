# Roblox Studio Setup

## Recommended workflow
1. Install Rojo 7.x.
2. Clone this repository.
3. Run `rojo serve` in the repository root.
4. Open a new Baseplate place in Roblox Studio.
5. Connect the Rojo Studio plugin to the running project.
6. Sync the project.
7. Press Play. The server bootstrap removes the untouched default Baseplate/SpawnLocation and generates the island in `Workspace/ISLE_ZERO_WORLD`.

## Studio-only world settings
A few Roblox environment properties cannot be changed by ordinary runtime scripts and should be set once in Studio:
- `Workspace.Terrain.Decoration` = **true** for animated terrain grass when desired.
- `Workspace.FallenPartsDestroyHeight` = approximately **-500**.
- Enable instance streaming later when the art-pass model count becomes heavy; do not rely on a runtime script to toggle Studio-only streaming configuration.

If you intentionally keep a custom object named `Baseplate` or `SpawnLocation`, add the Boolean attribute `PreserveForISLEZero = true` so the world bootstrap leaves it alone.

## Important
The generator intentionally rebuilds only when `WorldConfig.WorldVersion` changes or the generated world is missing. During Play Solo, the runtime world is temporary. If you want to preserve a generated snapshot for art pass work, generate it in Studio and save a separate `.rbxl` working place locally; do not commit the binary place file to this repository.

## Regenerating after map code changes
Increment `WorldConfig.WorldVersion` and start a fresh Play session.

## Replacing placeholders with real assets
The procedural world uses stable folders, tags and attributes. Replace models inside `Landmarks`, `Vegetation` or `CoastAndIslets` gradually. Keep landmark names and `LandmarkId` attributes if later gameplay systems reference them.

## World audit
Every successful generation runs `WorldAudit.lua`. Check Studio Output for `[ISLE//ZERO][WORLD AUDIT] PASS`. The generated root also exposes `AuditErrors`, `AuditWarnings` and `GeneratedDescendants` attributes for quick inspection.

## Performance notes
The first generation pass is intentionally moderate in density. Do not increase vegetation counts blindly. Prefer fewer high-quality grouped meshes later and enable Roblox streaming in the final place settings once the island art pass becomes heavier.
