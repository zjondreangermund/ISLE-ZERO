local CollectionService = game:GetService("CollectionService")

local NaturalFeatureBuilder = {}

local function makePart(parent, name, size, cframe, material, color, shape, transparency)
    local p = Instance.new("Part")
    p.Name = name
    p.Anchored = true
    p.CanCollide = true
    p.CanTouch = false
    p.Size = size
    p.CFrame = cframe
    p.Material = material
    p.Color = color
    p.Transparency = transparency or 0
    if shape then
        p.Shape = shape
    end
    p.Parent = parent
    p:SetAttribute("GeneratedPlaceholder", true)
    return p
end

local function mark(model, featureId)
    model:SetAttribute("FeatureId", featureId)
    model:SetAttribute("GeneratedPlaceholder", true)
    CollectionService:AddTag(model, "WorldNaturalFeature")
end

local function buildBanyan(config, parent, heightAt)
    local zone = config.ScenicZones.AncientBanyan
    local p = zone.Position
    local y = heightAt(config, p.X, p.Z)
    local model = Instance.new("Model")
    model.Name = "AncientBanyan"
    model.Parent = parent
    mark(model, "ancient_banyan")

    local trunkColor = Color3.fromRGB(78, 60, 40)
    local trunk = makePart(model, "MainTrunk", Vector3.new(13, 54, 13), CFrame.new(p.X, y + 27, p.Z), Enum.Material.Wood, trunkColor)
    trunk.CanCollide = true

    for i = 1, 8 do
        local angle = i / 8 * math.pi * 2
        local rootEnd = Vector3.new(p.X + math.cos(angle) * 20, y + 0.5, p.Z + math.sin(angle) * 20)
        local rootStart = Vector3.new(p.X + math.cos(angle) * 5, y + 7, p.Z + math.sin(angle) * 5)
        local delta = rootEnd - rootStart
        local root = makePart(model, "ButtressRoot", Vector3.new(3.2, 4.5, delta.Magnitude), CFrame.lookAt((rootStart + rootEnd) / 2, rootEnd), Enum.Material.Wood, trunkColor)
        root.CanCollide = true
    end

    for i = 1, 6 do
        local angle = i / 6 * math.pi * 2
        local branchStart = Vector3.new(p.X, y + 40 + (i % 2) * 5, p.Z)
        local branchEnd = branchStart + Vector3.new(math.cos(angle) * 27, 5 + (i % 3) * 4, math.sin(angle) * 27)
        local delta = branchEnd - branchStart
        makePart(model, "Branch", Vector3.new(4.2, 4.2, delta.Magnitude), CFrame.lookAt((branchStart + branchEnd) / 2, branchEnd), Enum.Material.Wood, trunkColor)
    end

    for i = 1, 7 do
        local angle = i / 7 * math.pi * 2
        local canopy = makePart(
            model,
            "Canopy",
            Vector3.new(27, 18, 27),
            CFrame.new(p.X + math.cos(angle) * 18, y + 56 + (i % 2) * 5, p.Z + math.sin(angle) * 18),
            Enum.Material.Grass,
            Color3.fromRGB(38 + (i % 3) * 6, 91 + (i % 4) * 5, 42),
            Enum.PartType.Ball
        )
        canopy.CanCollide = false
    end
end

local function createWaterDisk(parent, name, position, diameter)
    local water = makePart(
        parent,
        name,
        Vector3.new(0.8, diameter, diameter),
        CFrame.new(position) * CFrame.Angles(0, 0, math.rad(90)),
        Enum.Material.Glass,
        Color3.fromRGB(53, 134, 158),
        Enum.PartType.Cylinder,
        0.25
    )
    water.CanCollide = false
    water.CastShadow = false
    return water
end

local function buildBlueHole(config, parent, heightAt)
    local zone = config.ScenicZones.BlueHole
    local p = zone.Position
    local y = heightAt(config, p.X, p.Z)
    local model = Instance.new("Model")
    model.Name = "BlueHoleCenote"
    model.Parent = parent
    mark(model, "blue_hole")

    workspace.Terrain:FillBall(Vector3.new(p.X, y + 8, p.Z), 34, Enum.Material.Air)
    createWaterDisk(model, "CenoteWater", Vector3.new(p.X, y - 12, p.Z), 55)

    local rng = Random.new(config.Seed + 445)
    for i = 1, 14 do
        local angle = i / 14 * math.pi * 2 + rng:NextNumber(-0.08, 0.08)
        local distance = rng:NextNumber(31, 39)
        local rockPos = Vector3.new(p.X + math.cos(angle) * distance, y - 1 + rng:NextNumber(-2, 3), p.Z + math.sin(angle) * distance)
        local size = Vector3.new(rng:NextNumber(5, 10), rng:NextNumber(5, 11), rng:NextNumber(5, 10))
        makePart(model, "CenoteRock", size, CFrame.new(rockPos) * CFrame.Angles(rng:NextNumber(-0.25, 0.25), rng:NextNumber(0, math.pi), rng:NextNumber(-0.25, 0.25)), Enum.Material.Rock, Color3.fromRGB(78, 84, 82))
    end
end

local function buildMangroveLagoon(config, parent, heightAt)
    local zone = config.ScenicZones.MangroveLagoon
    local p = zone.Position
    local y = heightAt(config, p.X, p.Z)
    local model = Instance.new("Model")
    model.Name = "MangroveLagoon"
    model.Parent = parent
    mark(model, "mangrove_lagoon")

    workspace.Terrain:FillBall(Vector3.new(p.X, y + 5, p.Z), 31, Enum.Material.Air)
    createWaterDisk(model, "LagoonWater", Vector3.new(p.X, math.max(config.SeaLevel + 1.5, y - 8), p.Z), 52)

    for i = 1, 9 do
        local angle = i / 9 * math.pi * 2
        local distance = 35 + (i % 3) * 4
        local x = p.X + math.cos(angle) * distance
        local z = p.Z + math.sin(angle) * distance
        local groundY = heightAt(config, x, z)
        local stump = makePart(model, "RootStump", Vector3.new(2.4, 9 + (i % 3) * 2, 2.4), CFrame.new(x, groundY + 4, z) * CFrame.Angles(0, angle, 0), Enum.Material.Wood, Color3.fromRGB(79, 61, 43))
        stump.CanCollide = true
    end
end

local function buildWindArch(config, parent, heightAt)
    local zone = config.ScenicZones.WindArch
    local p = zone.Position
    local y = heightAt(config, p.X, p.Z)
    local model = Instance.new("Model")
    model.Name = "WindArch"
    model.Parent = parent
    mark(model, "wind_arch")

    local rockColor = Color3.fromRGB(82, 87, 84)
    local base = CFrame.new(p.X, y, p.Z) * CFrame.Angles(0, math.rad(-18), 0)
    makePart(model, "ArchPillarA", Vector3.new(17, 43, 22), base * CFrame.new(-23, 21, 0) * CFrame.Angles(0, 0, math.rad(-5)), Enum.Material.Rock, rockColor)
    makePart(model, "ArchPillarB", Vector3.new(16, 36, 21), base * CFrame.new(23, 18, 0) * CFrame.Angles(0, 0, math.rad(6)), Enum.Material.Rock, rockColor)
    makePart(model, "ArchCrown", Vector3.new(58, 14, 22), base * CFrame.new(0, 39, 0) * CFrame.Angles(0, 0, math.rad(3)), Enum.Material.Rock, rockColor)
    makePart(model, "ArchShelf", Vector3.new(26, 8, 29), base * CFrame.new(-34, 7, 5) * CFrame.Angles(math.rad(4), 0, math.rad(-8)), Enum.Material.Slate, Color3.fromRGB(74, 78, 77))
end

function NaturalFeatureBuilder.Build(config, root, heightAt)
    local folder = Instance.new("Folder")
    folder.Name = "NaturalFeatures"
    folder.Parent = root

    buildBanyan(config, folder, heightAt)
    buildBlueHole(config, folder, heightAt)
    buildMangroveLagoon(config, folder, heightAt)
    buildWindArch(config, folder, heightAt)

    return folder
end

return NaturalFeatureBuilder
