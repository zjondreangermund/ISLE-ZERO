# ISLE//ZERO authored asset library

The procedural parts are gameplay placeholders. Put finished visual models under `ReplicatedStorage > ISLEZeroAssets`; never put permanent art inside `Workspace > ISLE_ZERO_WORLD` because the world is regenerated.

## Structures

Folder: `ISLEZeroAssets > Structures`

Use for complete buildings and large landmarks. Names are case/space insensitive.

Supported/current examples:

- `TreeHouse` or `Tree House` - Jungle Canopy Tree House
- `SafeTent` - built player camp tent
- `AbandonedCamp` - optional full replacement for the abandoned camp site
- `AncientCircle` - optional full shrine replacement
- `ExpeditionRemains`
- `SupplyCache`
- `MangroveDock`
- `CliffOverlook`
- `TidePools`

Whole-site replacement models should have their pivot near the centre/base of the structure. Add `ISLEZeroYOffset` (Number) or `ISLEZeroYaw` (Number degrees) if a model needs alignment correction.

## Nature

Folder: `ISLEZeroAssets > Nature`

You can use multiple variants. The generator mixes them deterministically.

Recognised prefixes:

- `Palm`, `PalmTree`, `Palmtree`, `CoconutPalm`
- `JungleTree`, `TropicalTree`, `BroadleafTree`
- `EmergentTree`, `GiantJungleTree`, `CanopyTree`
- `Mangrove`

Examples: `Palmtree01`, `Palmtree02`, `JungleTree01`, `JungleTree02`.

## Creatures

Folder: `ISLEZeroAssets > Creatures`

Current roaming animals:

- `WildBoar` / `Boar`
- `MarshCroc` / `Crocodile`
- `TimberWolf` / `Wolf`
- `JungleStalker` / `Jaguar` / `Panther`
- `IceWolf` / `FrostWolf`
- `JungleSnake` / `Snake` / `Viper` / `Cobra`

Current cave guardians:

- `CaveBoar`
- `SaltwaterCroc`
- `RidgeWolf`
- `BlackJaguar`
- `FeralHound`
- `IceBear` / `PolarBear`

Scripts and Humanoids inside visual models are removed at runtime. Existing joints/bones are preserved. If the model is rigged, optional animations can be supplied as `Animation` objects named `Idle`, `Walk`, `Run`, `Attack`, and `Death`, or as model attributes `IdleAnimationId`, `WalkAnimationId`, `RunAnimationId`, `AttackAnimationId`, `DeathAnimationId`.

## Props

Folder: `ISLEZeroAssets > Props`

Whole chest visuals:

- `WorldChest`
- `CaveChest`

Reusable site props:

- `SupplyCrate`
- `OldBarrel`
- `ExpeditionPack`
- `FieldJournal`
- `OldSurveyScope`
- `FireRingStone`
- `TidePoolRock`
- `Campfire`

The code can replace each matching placeholder without requiring a full site model.

## Furniture

Folder: `ISLEZeroAssets > Furniture`

Currently recognised:

- `Bedroll`

This folder is intended for benches, beds, tables, shelves and other reusable shelter/village furniture as those slots are added.

## Tools

Folder: `ISLEZeroAssets > Tools`

Name the model by ItemId. Examples:

- `Machete`
- `Torch`
- `Medkit`
- `Bandage`
- `HunterSpear`
- `SteelAxe`
- `IcePick`
- `AncientCompass`
- `BoatRepairKit`
- `ClimbingKit`
- `WinterGear`
- `ExplorerRelic`
- `FrostheartRelic`
- `ZeroCore`

For a held tool model, put the model pivot at the point that should line up with the invisible Roblox Tool Handle. Fine tune with attributes `ISLEZeroToolOffset` (Vector3), `ISLEZeroYaw`, `ISLEZeroPitch`, `ISLEZeroRoll`, and optionally `ISLEZeroScale`.

## WorldItems

Folder: `ISLEZeroAssets > WorldItems`

Subfolders exist only for organisation; the loader searches recursively.

### Resources

Put ground pickup models here:

- `Wood`
- `Cloth`
- `Rope`
- `Stone`
- `Herb`

### Food

- `Berries`
- `Coconut`
- `FoodRation`
- `RawMeat`
- `CookedWildMeat`

### Treasure

- `AncientCoin`
- `Ruby`
- `Emerald`
- `Sapphire`
- `Pearl`
- `GoldBar`
- `RelicShard`
- `MapFragment`

### Equipment

Use for the world/pickup version of tools and supplies, for example:

- `Machete`
- `Torch`
- `Medkit`
- `Bandage`
- `BoatRepairKit`
- `ClimbingKit`
- `WinterGear`

The `Tools` folder controls the model in the player's hand; `WorldItems` controls the object lying in the world before pickup. You can use the same source model in both if desired.

## Effects

Folder: `ISLEZeroAssets > Effects`

Reserved for authored particle/effect packages such as fire, waterfall mist, snow, poison, chest glow, cave dust and fireflies.

## Safe import rules

1. Insert/import the model into Studio.
2. Remove unnecessary or suspicious scripts. Runtime also strips scripts from visual clones.
3. Move the clean source model into the correct `ISLEZeroAssets` folder.
4. Remove the original Workspace copy after confirming the stored copy exists.
5. Stop and Play again.
6. If placement is wrong, tune `ISLEZeroYOffset`, `ISLEZeroYaw`, or the model pivot instead of editing generated Workspace copies.
