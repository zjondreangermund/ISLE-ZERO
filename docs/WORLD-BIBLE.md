# ISLE//ZERO World Bible

## Phase 1 goal
Build a believable, readable adventure island before quests, enemies, weapons or progression are added. The island should be enjoyable to walk through even when nothing is chasing the player.

## Scale
- Approximate playable footprint: 2,400 x 2,000 studs.
- Sea level: Y = 0.
- Highest summit: roughly 260-320 studs depending on noise.
- Designed for 1-6 players later.
- Dense points of interest are preferred over long empty travel.

## Primary silhouette
From the crash beach the player should immediately read three distant shapes:
1. The northern mountain/summit.
2. A broken stone ruin on the high ridge.
3. A radio/lookout structure on the eastern cliff.

These landmarks give orientation without a minimap.

## Regions

### 01 - Southshore / Crash Beach
Wide crescent beach, palms, driftwood, rocks and the wreckage staging area. This is the safest visual introduction and the default spawn.

### 02 - Greenwall Jungle
Dense central jungle with narrow sightlines, giant trees, fallen trunks, boulders and branching footpaths. It should feel much larger than it is because the player cannot see across it.

### 03 - West Mangroves
Low, wet terrain with roots, shallow water, reeds and small channels. This becomes an alternate route around the central jungle.

### 04 - River Spine
A river cuts from the northern interior toward the south-west basin. It is a natural navigation line and leads players toward the waterfall.

### 05 - Waterfall Basin
A memorable central landmark. The upper river drops into a pool; a cave mouth sits behind/alongside the falls as a future secret route.

### 06 - Old Village
An abandoned settlement on relatively flat central-east ground. Primitive huts and docks are placeholders at first; later this becomes one of the first major story spaces.

### 07 - East Cliffs
Rockier, windier coast with fewer trees and strong ocean views. A bunker/service entrance is embedded in the cliff face. The approach road/trail is deliberately visible from several places.

### 08 - North Highlands
Steeper grass and rock, fewer tropical trees, switchback trail and dramatic views over the full island.

### 09 - Ridge Ruins
Broken stone structures on a high saddle below the summit. They must be visible from the south as a distant curiosity.

### 10 - Summit / Zero Peak
Highest accessible point in the world foundation. Future story content can use it, but Phase 1 only establishes the climb and vista.

### 11 - Offshore Islets
Several small rocks/islands create coastline depth and future diving/boat locations. They should not compete with the main island.

## Route design
The main route is not a quest rail. It is a sequence of natural visual pulls:
Crash Beach -> Jungle Gate -> Village -> River/Waterfall -> Highlands -> Ruins -> Summit.

Alternate loops:
- Crash Beach -> west coastal trail -> Mangroves -> River Basin.
- Village -> east cliff trail -> Bunker Approach -> Highlands.
- Waterfall -> cave entrance -> future underground route.

## World rules
- No long straight roads.
- No building should sit perfectly isolated in an empty field.
- Every major landmark needs foreground clutter and a believable reason for its placement.
- Paths should curve around terrain instead of cutting through it unnaturally.
- Cliffs and steep slopes gate movement visually before invisible walls are considered.
- Use fog/atmosphere to hide the far edge of the ocean.
- Keep the southern beach brighter and the deep jungle slightly cooler/darker.
- Generated assets are placeholders with stable names/tags so they can be replaced by custom meshes later.

## Asset replacement strategy
Generated folders are separated into Terrain, Landmarks, Paths, Vegetation and SetDressing. Custom 3D models can replace any placeholder model as long as the landmark folder/name remains stable. Gameplay systems should bind to tags/attributes, not individual primitive parts.

## Future phases (not part of Phase 1)
1. Traversal and interaction polish.
2. Discovery/collectible framework.
3. Inventory and tools.
4. Wildlife and ambient AI.
5. Combat/FPS systems.
6. Story, mysteries and progression.
7. Co-op persistence and live-ops expansions.
