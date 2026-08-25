# ISLE//ZERO

A semi-realistic Roblox adventure island focused on exploration, environmental discovery, mystery and eventually survival/FPS encounters.

## Current phase: World Foundation

The repository currently builds and validates the playable island before story, combat and progression are layered on top.

### World pillars
- One dense, memorable island rather than a huge empty map.
- Strong silhouettes so players can navigate visually.
- Beach -> jungle -> river -> village -> caves -> highlands -> ruins progression without hard quest rails.
- Secrets and alternate routes designed into the terrain from the start.
- Deterministic generation so the same seed produces the same island.
- Stable named folders/tags so procedural placeholders can later be replaced with hand-built 3D art without rewriting gameplay systems.

### Current generated world
- Crash Beach and wreck site
- Jungle and mangrove regions
- River, waterfall pool and reserved waterfall cave
- Abandoned village
- East-cliff bunker entrance
- Ridge ruins and Zero Peak
- East lookout tower
- Offshore islets and sea stacks
- Ancient Banyan
- Blue Hole Cenote
- Mangrove Lagoon
- Wind Arch
- Main, east and west exploration trails

### Development
This project uses a Rojo source layout and a pinned Rokit toolchain. Run `rokit install`, then `rojo serve`, connect the Rojo Studio plugin and press Play.

World generation includes configuration preflight, per-phase diagnostics, safe temporary spawning, a client generation screen and a runtime integrity audit. In Studio, `/worldstatus`, `/worldaudit` and `/worldrebuild` provide quick development controls.

GitHub Actions runs Selene linting plus a Rojo place build on the newest push and stores a temporary `.rbxlx` build artifact when successful.

See `docs/WORLD-BIBLE.md` for the map plan and `docs/ROBLOX-STUDIO.md` for setup and diagnostics.
