# ISLE//ZERO Authored Asset Slots

The world generator keeps simple generated Parts as invisible gameplay/collision scaffolding and can overlay finished Roblox models automatically.

## Where to put models in Roblox Studio

With Rojo connected, open:

`ReplicatedStorage > ISLEZeroAssets`

The project creates these folders and intentionally preserves models you insert into them:

- `Structures`
- `Nature`
- `Creatures`
- `Props`
- `Tools`

Do not put scripts from Toolbox models into these assets. The runtime replacement system strips Scripts, LocalScripts and ModuleScripts from cloned authored visuals as an additional safety measure.

## Current automatic asset names

### Structures

- `SafeTent` — replaces the generated safe-camp tent visual.
- Exact generated model names can also be used for landmarks/structures. If the generated Model is called `AncientCircle`, an authored Model called `AncientCircle` can replace its visible placeholder geometry.

### Props

- `WorldChest` — visual used by all surface world chests.
- `CaveChest` — visual used by cave branch chests.

### Nature

- `JungleTree`
- `EmergentTree`
- `Palm`
- `Mangrove`

### Creatures

Name creature visual models exactly after the GuardianType:

Cave/guardian examples:
- `CaveBoar`
- `SaltwaterCroc`
- `RidgeWolf`
- `BlackJaguar`
- `FeralHound`
- `IceBear`

Roaming wildlife:
- `WildBoar`
- `MarshCroc`
- `TimberWolf`
- `JungleStalker`
- `IceWolf`

The current creature overlay moves as one welded visual. Full custom skeletal animations can be added later without changing combat/progression logic.

## Model setup

1. Insert/import the finished Model or MeshPart.
2. Name it exactly as one of the asset names above.
3. Put it in the correct `ISLEZeroAssets` folder.
4. Set the Model pivot where you want its world placement origin to be.
5. Optional attributes on the authored asset:
   - `ISLEZeroYOffset` (number, studs)
   - `ISLEZeroYaw` (number, degrees)
6. Stop Play and start Play again.

The authored visual is cloned over the generated placeholder. The original generated objects remain invisible for collision, prompts and gameplay, so replacing art does not break chests, camps or AI.

## Why keep placeholders underneath?

This separates art from gameplay. We can replace a temporary Part-built chest with a polished MeshPart chest without rewriting loot code, prompts, rarity logic, saves or collision rules.

## Code-generated structures

Many structures can be created entirely in Luau: camps, buildings, ruins, bridges, caves, docks, fences, towers and modular villages. Procedural code is especially useful for layout and variation.

For high-detail organic art such as realistic animals, rock sculpts, tree trunks and detailed props, custom MeshParts made in Blender/Roblox Studio generally produce better visuals than assembling hundreds of primitive Parts. A strong production workflow uses code for systems/layout/procedural assembly and authored meshes for final visual quality.
