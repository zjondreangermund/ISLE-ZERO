# Roblox Studio Setup

## Recommended workflow
1. Install Rojo 7.x.
2. Clone this repository.
3. Run `rojo serve` in the repository root.
4. Open a new Baseplate place in Roblox Studio.
5. Connect the Rojo Studio plugin to the running project.
6. Sync the project.
7. Press Play. The server bootstrap generates the island in `Workspace/ISLE_ZERO_WORLD`.

## Important
The generator intentionally rebuilds only when `WorldConfig.WorldVersion` changes or the generated world is missing. During Play Solo, the runtime world is temporary. If you want to preserve a generated snapshot for art pass work, generate it in Studio and save a separate `.rbxl` working place locally; do not commit the binary place file to this repository.

## Regenerating after map code changes
Increment `WorldConfig.WorldVersion` and start a fresh Play session.

## Replacing placeholders with real assets
The procedural world uses stable folders and attributes. Replace models inside `Landmarks`, `Vegetation` or `SetDressing` gradually. Keep landmark names and `LandmarkId` attributes if later gameplay systems reference them.

## Performance notes
The first generation pass is intentionally moderate in density. Do not increase vegetation counts blindly. Prefer fewer high-quality grouped meshes later and enable Roblox streaming in the final place settings once the island art pass becomes heavier.
