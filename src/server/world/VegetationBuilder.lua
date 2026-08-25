local CollectionService = game:GetService("CollectionService")

local VegetationBuilder = {}

local function makePart(parent, name, size, cframe, material, color, shape)
    local part = Instance.new("Part")
    part.Name = name
    part.Anchored = true
    part.CanCollide = name == "Trunk" or name == "Rock"
    part.CanTouch = false
    part.Material = material
    part.Color = color
    part.Size = size
    part.CFrame = cframe
    if shape then
        part.Shape = shape
    end
    part.Parent = parent
    return part
end

local function horizontalDistance(a, b)
    return Vector2.new(a.X - b.X, a.Z - b.Z).Magnitude
end

local function tooCloseToLandmark(config, position)
    local protected = {
        {config.Locations.CrashBeach, 145},
        {config.Locations.Village, 175},
        {config.Locations.Waterfall, 95},
        {config.Locations.BunkerApproach, 90},
        {config.Locations.RidgeRuins, 120},
        {config.Locations.Summit, 85},
        {config.Locations.EastLookout, 70},
    }
    for _, entry in ipairs(protected) do
        if horizontalDistance(position, entry[1]) < entry[2] then
            return true
        end
    end

    for _, zone in pairs(config.ScenicZones or {}) do
        if horizontalDistance(position, zone.Position) < zone.Radius then
            return true
        end
    end

    return false
end

local function createPalm(parent, position, rng)
    local model = Instance.new("Model")
    model.Name = "Palm"
    model.Parent = parent
    model:SetAttribute("GeneratedPlaceholder", true)
    CollectionService:AddTag(model, "WorldVegetation")

    local height = rng:NextNumber(18, 32)
    local leanX = rng:NextNumber(-2.8, 2.8)
    local leanZ = rng:NextNumber(-2.8, 2.8)
    local crown = position + Vector3.new(leanX, height, leanZ)

    local trunkMid = (position + crown) / 2
    local trunk = makePart(
        model,
        "Trunk",
        Vector3.new(height, 2.4, 2.4),
        CFrame.lookAt(trunkMid, crown) * CFrame.Angles(0, math.rad(90), 0),
        Enum.Material.Wood,
        Color3.fromRGB(116, 86, 53),
        Enum.PartType.Cylinder
    )
    trunk.CanCollide = true

    for i = 1, 7 do
        local angle = (i / 7) * math.pi * 2 + rng:NextNumber(-0.18, 0.18)
        local leafLength = rng:NextNumber(9, 14)
        local center = crown + Vector3.new(math.cos(angle) * leafLength * 0.42, rng:NextNumber(-1.5, 1.2), math.sin(angle) * leafLength * 0.42)
        local leaf = makePart(
            model,
            "Frond",
            Vector3.new(leafLength, 0.8, rng:NextNumber(2.2, 3.5)),
            CFrame.new(center) * CFrame.Angles(0, -angle, rng:NextNumber(-0.25, 0.12)),
            Enum.Material.Grass,
            Color3.fromRGB(55 + rng:NextInteger(0, 15), 112 + rng:NextInteger(0, 20), 55),
            Enum.PartType.Block
        )
        leaf.CanCollide = false
        leaf.CastShadow = true
    end
end

local function createJungleTree(parent, position, rng)
    local model = Instance.new("Model")
    model.Name = "JungleTree"
    model.Parent = parent
    model:SetAttribute("GeneratedPlaceholder", true)
    CollectionService:AddTag(model, "WorldVegetation")

    local height = rng:NextNumber(17, 38)
    local width = rng:NextNumber(2.2, 4.7)
    local trunk = makePart(
        model,
        "Trunk",
        Vector3.new(width, height, width),
        CFrame.new(position + Vector3.new(0, height / 2, 0)) * CFrame.Angles(0, rng:NextNumber(0, math.pi), 0),
        Enum.Material.Wood,
        Color3.fromRGB(92, 68, 43)
    )
    trunk.CanCollide = true

    local crownY = position.Y + height
    for i = 1, rng:NextInteger(2, 4) do
        local canopy = makePart(
            model,
            "Canopy",
            Vector3.new(rng:NextNumber(12, 21), rng:NextNumber(8, 15), rng:NextNumber(12, 21)),
            CFrame.new(position.X + rng:NextNumber(-4, 4), crownY + rng:NextNumber(-2, 4), position.Z + rng:NextNumber(-4, 4)),
            Enum.Material.Grass,
            Color3.fromRGB(42 + rng:NextInteger(0, 14), 91 + rng:NextInteger(0, 25), 45 + rng:NextInteger(0, 10)),
            Enum.PartType.Ball
        )
        canopy.CanCollide = false
    end
end

local function createRock(parent, position, rng)
    local size = Vector3.new(rng:NextNumber(3, 11), rng:NextNumber(2, 8), rng:NextNumber(3, 11))
    local rock = makePart(
        parent,
        "Rock",
        size,
        CFrame.new(position + Vector3.new(0, size.Y * 0.25, 0)) * CFrame.Angles(rng:NextNumber(-0.35, 0.35), rng:NextNumber(0, math.pi), rng:NextNumber(-0.35, 0.35)),
        Enum.Material.Slate,
        Color3.fromRGB(83 + rng:NextInteger(0, 18), 83 + rng:NextInteger(0, 18), 78 + rng:NextInteger(0, 14))
    )
    rock.CanCollide = true
    rock:SetAttribute("GeneratedPlaceholder", true)
    CollectionService:AddTag(rock, "WorldSetDressing")
end

local function createMangrove(parent, position, rng)
    local model = Instance.new("Model")
    model.Name = "Mangrove"
    model.Parent = parent
    model:SetAttribute("GeneratedPlaceholder", true)
    CollectionService:AddTag(model, "WorldVegetation")

    local trunkHeight = rng:NextNumber(10, 18)
    makePart(model, "Trunk", Vector3.new(2.4, trunkHeight, 2.4), CFrame.new(position + Vector3.new(0, trunkHeight / 2, 0)), Enum.Material.Wood, Color3.fromRGB(88, 67, 45))
    for i = 1, 5 do
        local angle = i / 5 * math.pi * 2
        local rootEnd = position + Vector3.new(math.cos(angle) * rng:NextNumber(4, 7), 0, math.sin(angle) * rng:NextNumber(4, 7))
        local rootMid = (position + rootEnd) / 2 + Vector3.new(0, 2.2, 0)
        local length = (rootEnd - position).Magnitude
        local root = makePart(model, "Root", Vector3.new(0.9, 0.9, length), CFrame.lookAt(rootMid, rootEnd), Enum.Material.Wood, Color3.fromRGB(82, 60, 39))
        root.CanCollide = false
    end
    for i = 1, 2 do
        local canopy = makePart(model, "Canopy", Vector3.new(13, 8, 13), CFrame.new(position + Vector3.new(rng:NextNumber(-3, 3), trunkHeight + i * 2, rng:NextNumber(-3, 3))), Enum.Material.Grass, Color3.fromRGB(48, 100, 52), Enum.PartType.Ball)
        canopy.CanCollide = false
    end
end

function VegetationBuilder.Build(config, root, heightAt, distanceToPath)
    local folder = Instance.new("Folder")
    folder.Name = "Vegetation"
    folder.Parent = root

    local trees = Instance.new("Folder")
    trees.Name = "Trees"
    trees.Parent = folder

    local palms = Instance.new("Folder")
    palms.Name = "Palms"
    palms.Parent = folder

    local mangroves = Instance.new("Folder")
    mangroves.Name = "Mangroves"
    mangroves.Parent = folder

    local dressing = Instance.new("Folder")
    dressing.Name = "RocksAndDressing"
    dressing.Parent = folder

    local rng = Random.new(config.Seed + 9041)
    local density = config.Generation.VegetationDensity
    local island = config.Island

    local attempts = math.floor(760 * density)
    for i = 1, attempts do
        local x = rng:NextNumber(-island.HalfX, island.HalfX)
        local z = rng:NextNumber(-island.HalfZ, island.HalfZ)
        local y = heightAt(config, x, z)
        local position = Vector3.new(x, y, z)

        if y > config.SeaLevel + 3 and y < 190 and not tooCloseToLandmark(config, position) and distanceToPath(config, position) > 15 then
            local nx = x / island.HalfX
            local nz = z / island.HalfZ
            local radius = math.sqrt(nx * nx + nz * nz)

            if x < -560 and z > -100 and z < 430 and y < 24 then
                if rng:NextNumber() < 0.55 then
                    createMangrove(mangroves, position, rng)
                end
            elseif radius > 0.74 or y < 20 then
                if rng:NextNumber() < 0.48 then
                    createPalm(palms, position, rng)
                elseif rng:NextNumber() < 0.38 then
                    createRock(dressing, position, rng)
                end
            else
                local roll = rng:NextNumber()
                if roll < 0.63 then
                    createJungleTree(trees, position, rng)
                elseif roll < 0.79 then
                    createRock(dressing, position, rng)
                end
            end
        end

        if i % 35 == 0 then
            task.wait()
        end
    end

    return folder
end

return VegetationBuilder
