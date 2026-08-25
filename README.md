# ISLE//ZERO

A semi-realistic Roblox adventure island focused on exploration, environmental discovery, mystery and eventually survival/FPS encounters.

## Current phase: World Foundation

The repository currently builds the playable island before story, combat and progression are layered on top.

### World pillars
- One dense, memorable island rather than a huge empty map.
- Strong silhouettes so players can navigate visually.
- Beach -> jungle -> river -> village -> caves -> highlands -> ruins progression without hard quest rails.
- Secrets and alternate routes are designed into the terrain from the start.
- World generation is deterministic so the same seed produces the same island.
- Generated geometry is separated into named folders so hand-built art can replace procedural placeholders later without rewriting gameplay code.

### Development
This project uses [Rojo](https://rojo.space/) style source layout. Sync `default.project.json` into Roblox Studio, then run the place. `WorldBootstrap.server.lua` creates the world if it has not already been generated for the configured world version.

See `docs/WORLD-BIBLE.md` for the map plan and `docs/ROBLOX-STUDIO.md` for setup.
