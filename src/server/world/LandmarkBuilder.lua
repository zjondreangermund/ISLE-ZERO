local CollectionService = game:GetService("CollectionService")

local LandmarkBuilder = {}

local function part(parent, name, size, cframe, material, color, transparency)
    local object = Instance.new("Part")
    object.Name = name
    object.Anchored = true
    object.Size = size
    object.CFrame = cframe
    object.Material = material
    object.Color = color
    object.Transparency = transparency or 0
    object.TopSurface = Enum.SurfaceType.Smooth
    object.BottomSurface = Enum.SurfaceType.Smooth
    object.Parent = parent
    object:SetAttribute("GeneratedPlaceholder", true)
    return object
end

local function markLandmark(model, id)
    model:SetAttribute("LandmarkId", id)
    model:SetAttribute("GeneratedPlaceholder", true)
    CollectionService:AddTag(model, "WorldLandmark")
end

local function buildCrashSite(parent, config, heightAt)
    local center = config.Locations.CrashBeach
    local y = heightAt(config, center.X, center.Z)
    local model = Instance.new("Model")
    model.Name = "CrashSite"
    model.Parent = parent
    markLandmark(model, "crash_site")

    local frame = CFrame.new(center.X - 35, y + 3, center.Z + 10) * CFrame.Angles(math.rad(4), math.rad(-24), math.rad(6))
    part(model, "Fuselage", Vector3.new(10, 9, 42), frame, Enum.Material.Metal, Color3.fromRGB(101, 106, 102))
    part(model, "BrokenWingLeft", Vector3.new(37, 1.4, 10), frame * CFrame.new(-20, -1, 3) * CFrame.Angles(0, 0, math.rad(-8)), Enum.Material.Metal, Color3.fromRGB(82, 87, 84))
    part(model, "BrokenWingRight", Vector3.new(22, 1.4, 9), frame * CFrame.new(15, 0, -4) * CFrame.Angles(0, math.rad(8), math.rad(12)), Enum.Material.Metal, Color3.fromRGB(82, 87, 84))
    part(model, "TailFragment", Vector3.new(4, 14, 13), frame * CFrame.new(2, 7, 19) * CFrame.Angles(math.rad(-12), 0, 0), Enum.Material.Metal, Color3.fromRGB(91, 96, 93))

    for i = 1, 7 do
        local offset = Vector3.new(-60 + i * 14, 0, 28 + ((i % 2) * 11))
        local py = heightAt(config, center.X + offset.X, center.Z + offset.Z)
        local debris = part(model, "Debris", Vector3.new(3 + (i % 3) * 2, 0.7, 5 + (i % 2) * 3), CFrame.new(center.X + offset.X, py + 0.5, center.Z + offset.Z) * CFrame.Angles(0, math.rad(i * 37), math.rad((i % 3 - 1) * 8)), Enum.Material.Metal, Color3.fromRGB(73, 78, 76))
        debris.CanCollide = false
    end

    return model
end

local function buildHut(parent, position, rotation, heightAt, config, index)
    local y = heightAt(config, position.X, position.Z)
    local model = Instance.new("Model")
    model.Name = string.format("Hut_%02d", index)
    model.Parent = parent
    model:SetAttribute("GeneratedPlaceholder", true)

    local base = CFrame.new(position.X, y + 3, position.Z) * CFrame.Angles(0, rotation, 0)
    part(model, "Floor", Vector3.new(24, 1, 18), base, Enum.Material.WoodPlanks, Color3.fromRGB(105, 78, 48))

    for _, offset in ipairs({Vector3.new(-10, 4, -7), Vector3.new(10, 4, -7), Vector3.new(-10, 4, 7), Vector3.new(10, 4, 7)}) do
        part(model, "Post", Vector3.new(1.3, 8, 1.3), base * CFrame.new(offset), Enum.Material.Wood, Color3.fromRGB(86, 62, 39))
    end

    part(model, "BackWall", Vector3.new(22, 7, 0.8), base * CFrame.new(0, 4.2, 8), Enum.Material.WoodPlanks, Color3.fromRGB(115, 87, 55))
    part(model, "SideWall", Vector3.new(0.8, 7, 15), base * CFrame.new(-11, 4.2, 0), Enum.Material.WoodPlanks, Color3.fromRGB(112, 84, 53))
    part(model, "RoofA", Vector3.new(26, 0.8, 12), base * CFrame.new(0, 9, -4.6) * CFrame.Angles(math.rad(-22), 0, 0), Enum.Material.WoodPlanks, Color3.fromRGB(78, 61, 42))
    part(model, "RoofB", Vector3.new(26, 0.8, 12), base * CFrame.new(0, 9, 4.6) * CFrame.Angles(math.rad(22), 0, 0), Enum.Material.WoodPlanks, Color3.fromRGB(78, 61, 42))
    return model
end

local function buildVillage(parent, config, heightAt)
    local center = config.Locations.Village
    local model = Instance.new("Model")
    model.Name = "OldVillage"
    model.Parent = parent
    markLandmark(model, "old_village")

    local huts = {
        {Vector3.new(-58, 0, -40), math.rad(18)},
        {Vector3.new(-10, 0, -58), math.rad(-8)},
        {Vector3.new(48, 0, -35), math.rad(-28)},
        {Vector3.new(-65, 0, 25), math.rad(14)},
        {Vector3.new(4, 0, 35), math.rad(-4)},
        {Vector3.new(67, 0, 30), math.rad(23)},
    }

    for i, hut in ipairs(huts) do
        buildHut(model, center + hut[1], hut[2], heightAt, config, i)
    end

    local fireY = heightAt(config, center.X, center.Z)
    local fireRing = Instance.new("Model")
    fireRing.Name = "VillageFireRing"
    fireRing.Parent = model
    for i = 1, 9 do
        local angle = i / 9 * math.pi * 2
        local p = Vector3.new(center.X + math.cos(angle) * 6, fireY + 0.8, center.Z + math.sin(angle) * 6)
        part(fireRing, "Stone", Vector3.new(3, 1.6, 2.3), CFrame.new(p) * CFrame.Angles(0, -angle, 0), Enum.Material.Rock, Color3.fromRGB(92, 91, 84))
    end

    return model
end

local function buildBunker(parent, config, heightAt)
    local center = config.Locations.BunkerApproach
    local y = heightAt(config, center.X, center.Z)
    local model = Instance.new("Model")
    model.Name = "EastCliffBunkerEntrance"
    model.Parent = parent
    markLandmark(model, "east_bunker")

    local base = CFrame.new(center.X, y + 8, center.Z) * CFrame.Angles(0, math.rad(-72), 0)
    part(model, "ConcreteFrameTop", Vector3.new(28, 4, 7), base * CFrame.new(0, 10, 0), Enum.Material.Concrete, Color3.fromRGB(95, 99, 94))
    part(model, "ConcreteFrameL", Vector3.new(5, 20, 7), base * CFrame.new(-12, 0, 0), Enum.Material.Concrete, Color3.fromRGB(95, 99, 94))
    part(model, "ConcreteFrameR", Vector3.new(5, 20, 7), base * CFrame.new(12, 0, 0), Enum.Material.Concrete, Color3.fromRGB(95, 99, 94))
    local door = part(model, "SealedDoor", Vector3.new(19, 16, 2.2), base * CFrame.new(0, 0, -2.6), Enum.Material.Metal, Color3.fromRGB(63, 72, 68))
    door:SetAttribute("InteractableFuture", "BunkerDoor")

    return model
end

local function buildRuins(parent, config, heightAt)
    local center = config.Locations.RidgeRuins
    local y = heightAt(config, center.X, center.Z)
    local model = Instance.new("Model")
    model.Name = "RidgeRuins"
    model.Parent = parent
    markLandmark(model, "ridge_ruins")

    local stone = Color3.fromRGB(116, 113, 101)
    for i = -2, 2 do
        local x = center.X + i * 18
        local h = 16 + ((i + 2) % 3) * 7
        part(model, "BrokenColumn", Vector3.new(5, h, 5), CFrame.new(x, y + h / 2, center.Z), Enum.Material.Limestone, stone)
    end
    part(model, "LintelFragment", Vector3.new(56, 5, 6), CFrame.new(center.X - 5, y + 28, center.Z) * CFrame.Angles(0, 0, math.rad(4)), Enum.Material.Limestone, stone)
    part(model, "WallFragmentA", Vector3.new(7, 24, 42), CFrame.new(center.X - 36, y + 12, center.Z - 22) * CFrame.Angles(0, math.rad(18), 0), Enum.Material.Limestone, stone)
    part(model, "WallFragmentB", Vector3.new(7, 16, 31), CFrame.new(center.X + 42, y + 8, center.Z + 18) * CFrame.Angles(0, math.rad(-20), math.rad(5)), Enum.Material.Limestone, stone)

    return model
end

local function buildLookout(parent, config, heightAt)
    local center = config.Locations.EastLookout
    local y = heightAt(config, center.X, center.Z)
    local model = Instance.new("Model")
    model.Name = "EastLookout"
    model.Parent = parent
    markLandmark(model, "east_lookout")

    local base = CFrame.new(center.X, y, center.Z)
    local steel = Color3.fromRGB(73, 78, 76)
    for _, offset in ipairs({Vector3.new(-6, 22, -6), Vector3.new(6, 22, -6), Vector3.new(-6, 22, 6), Vector3.new(6, 22, 6)}) do
        part(model, "TowerLeg", Vector3.new(1.3, 44, 1.3), base * CFrame.new(offset), Enum.Material.Metal, steel)
    end
    part(model, "LookoutDeck", Vector3.new(19, 1.5, 19), base * CFrame.new(0, 43, 0), Enum.Material.DiamondPlate, steel)
    part(model, "Mast", Vector3.new(1.4, 25, 1.4), base * CFrame.new(0, 56, 0), Enum.Material.Metal, Color3.fromRGB(104, 108, 105))
    part(model, "Crossbar", Vector3.new(14, 1, 1), base * CFrame.new(0, 63, 0), Enum.Material.Metal, steel)

    return model
end

local function buildSummit(parent, config, heightAt)
    local center = config.Locations.Summit
    local y = heightAt(config, center.X, center.Z)
    local model = Instance.new("Model")
    model.Name = "ZeroPeak"
    model.Parent = parent
    markLandmark(model, "zero_peak")

    for i = 1, 7 do
        local scale = 8 - i
        part(model, "CairnStone", Vector3.new(5 + scale, 2.1, 4 + scale), CFrame.new(center.X + math.sin(i * 1.7) * 1.4, y + i * 1.7, center.Z + math.cos(i * 1.4) * 1.1) * CFrame.Angles(0, i * 0.6, 0), Enum.Material.Rock, Color3.fromRGB(91, 91, 86))
    end
    return model
end

local function buildRiver(parent, config, terrainState, heightAt)
    local model = Instance.new("Model")
    model.Name = "RiverAndWaterfall"
    model.Parent = parent
    markLandmark(model, "river_spine")

    local river = terrainState.RiverPoints
    for i = 1, #river - 1 do
        local aRaw, bRaw = river[i], river[i + 1]
        local ay = heightAt(config, aRaw.X, aRaw.Z) - 8
        local by = heightAt(config, bRaw.X, bRaw.Z) - 8
        local a = Vector3.new(aRaw.X, ay, aRaw.Z)
        local b = Vector3.new(bRaw.X, by, bRaw.Z)
        local delta = b - a
        local water = part(model, "RiverWater", Vector3.new(30, 0.55, delta.Magnitude + 4), CFrame.lookAt((a + b) / 2, b), Enum.Material.Glass, Color3.fromRGB(64, 139, 158), 0.28)
        water.CanCollide = false
        water.CastShadow = false
    end

    local pool = part(model, "WaterfallPool", Vector3.new(1, 112, 112), CFrame.new(-275, terrainState.PoolSurface, -115) * CFrame.Angles(0, 0, math.rad(90)), Enum.Material.Glass, Color3.fromRGB(56, 131, 151), 0.24)
    pool.Shape = Enum.PartType.Cylinder
    pool.CanCollide = false
    pool.CastShadow = false

    local upperY = heightAt(config, -235, -185) - 6
    local drop = math.max(18, upperY - terrainState.PoolSurface)
    local fall = part(model, "Waterfall", Vector3.new(35, drop, 1.2), CFrame.new(-252, terrainState.PoolSurface + drop / 2, -155) * CFrame.Angles(0, math.rad(24), 0), Enum.Material.Glass, Color3.fromRGB(189, 226, 231), 0.35)
    fall.CanCollide = false
    fall.CastShadow = false

    return model
end

local function buildSpawn(parent, config, heightAt)
    local center = config.Locations.CrashBeach
    local y = heightAt(config, center.X, center.Z)
    local spawn = Instance.new("SpawnLocation")
    spawn.Name = "CrashBeachSpawn"
    spawn.Size = Vector3.new(12, 1, 12)
    spawn.CFrame = CFrame.new(center.X, y + 3, center.Z)
    spawn.Anchored = true
    spawn.CanCollide = false
    spawn.Transparency = 1
    spawn.Neutral = true
    spawn.Duration = 0
    spawn.Parent = parent
    spawn:SetAttribute("SpawnId", "crash_beach")
    CollectionService:AddTag(spawn, "WorldSpawn")
end

function LandmarkBuilder.Build(config, root, terrainState, heightAt)
    local folder = Instance.new("Folder")
    folder.Name = "Landmarks"
    folder.Parent = root

    buildCrashSite(folder, config, heightAt)
    buildVillage(folder, config, heightAt)
    buildBunker(folder, config, heightAt)
    buildRuins(folder, config, heightAt)
    buildLookout(folder, config, heightAt)
    buildSummit(folder, config, heightAt)
    buildRiver(folder, config, terrainState, heightAt)
    buildSpawn(folder, config, heightAt)

    return folder
end

return LandmarkBuilder
