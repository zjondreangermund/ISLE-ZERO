local CollectionService = game:GetService("CollectionService")

local VegetationBuilder = {}

local function makePart(parent, name, size, cframe, material, color, shape)
    local part = Instance.new("Part")
    part.Name = name
    part.Anchored = true
    part.CanCollide = name == "Trunk" or name == "Rock"
    part.CanTouch = false
    part.CanQuery = part.CanCollide
    part.Material = material
    part.Color = color
    part.Size = size
    part.CFrame = cframe
    part.TopSurface = Enum.SurfaceType.Smooth
    part.BottomSurface = Enum.SurfaceType.Smooth
    if shape then
        part.Shape = shape
    end
    part.Parent = parent
    return part
end

local function horizontalDistance(a, b)
    return Vector2.new(a.X - b.X, a.Z - b.Z).Magnitude
end

local function protectedRadius(config, position, vegetationKind)
    local crashRadius = vegetationKind == "Palm" and 72 or 105
    local protected = {
        {config.Locations.CrashBeach, crashRadius},
        {config.Locations.Village, 96},
        {config.Locations.Waterfall, 72},
        {config.Locations.BunkerApproach, 58},
        {config.Locations.RidgeRuins, 76},
        {config.Locations.Summit, 60},
        {config.Locations.EastLookout, 48},
    }

    for _, entry in ipairs(protected) do
        if horizontalDistance(position, entry[1]) < entry[2] then
            return true
        end
    end

    for _, zone in pairs(config.ScenicZones or {}) do
        local scale = vegetationKind == "Understory" and 0.5 or 0.72
        if horizontalDistance(position, zone.Position) < zone.Radius * scale then
            return true
        end
    end

    return false
end

local function createSpatialGrid(cellSize)
    local buckets = {}

    local function bucketKey(ix, iz)
        return tostring(ix) .. ":" .. tostring(iz)
    end

    local function coordinates(position)
        return math.floor(position.X / cellSize), math.floor(position.Z / cellSize)
    end

    local grid = {}

    function grid.IsFree(position, minimumDistance)
        local ix, iz = coordinates(position)
        local radius = math.max(1, math.ceil(minimumDistance / cellSize))

        for dx = -radius, radius do
            for dz = -radius, radius do
                local bucket = buckets[bucketKey(ix + dx, iz + dz)]
                if bucket then
                    for _, existing in ipairs(bucket) do
                        if horizontalDistance(existing, position) < minimumDistance then
                            return false
                        end
                    end
                end
            end
        end
        return true
    end

    function grid.Add(position)
        local ix, iz = coordinates(position)
        local key = bucketKey(ix, iz)
        local bucket = buckets[key]
        if not bucket then
            bucket = {}
            buckets[key] = bucket
        end
        table.insert(bucket, position)
    end

    return grid
end

local function tagVegetation(instance, vegetationType)
    instance:SetAttribute("GeneratedPlaceholder", true)
    instance:SetAttribute("VegetationType", vegetationType)
    CollectionService:AddTag(instance, "WorldVegetation")
end

local function createJungleTree(parent, position, rng, emergent)
    local model = Instance.new("Model")
    model.Name = emergent and "EmergentTree" or "JungleTree"
    model.Parent = parent
    tagVegetation(model, emergent and "Emergent" or "JungleTree")

    local height
    local width
    if emergent then
        height = rng:NextNumber(39, 58)
        width = rng:NextNumber(3.3, 5.8)
    else
        height = rng:NextNumber(22, 42)
        width = rng:NextNumber(2.4, 4.8)
    end

    local leanX = rng:NextNumber(-1.8, 1.8)
    local leanZ = rng:NextNumber(-1.8, 1.8)
    local crown = position + Vector3.new(leanX, height, leanZ)
    local trunkMid = (position + crown) / 2

    local trunk = makePart(
        model,
        "Trunk",
        Vector3.new(width, width, height),
        CFrame.lookAt(trunkMid, crown),
        Enum.Material.Wood,
        Color3.fromRGB(82 + rng:NextInteger(0, 16), 61 + rng:NextInteger(0, 13), 39 + rng:NextInteger(0, 10))
    )
    trunk.CanCollide = true
    trunk.CanQuery = true

    local canopyWidth = emergent and rng:NextNumber(22, 30) or rng:NextNumber(16, 25)
    local canopyHeight = emergent and rng:NextNumber(12, 18) or rng:NextNumber(10, 16)
    local canopy = makePart(
        model,
        "Canopy",
        Vector3.new(canopyWidth, canopyHeight, canopyWidth * rng:NextNumber(0.88, 1.08)),
        CFrame.new(crown + Vector3.new(0, rng:NextNumber(0, 3), 0)),
        Enum.Material.Grass,
        Color3.fromRGB(37 + rng:NextInteger(0, 18), 82 + rng:NextInteger(0, 31), 39 + rng:NextInteger(0, 16)),
        Enum.PartType.Ball
    )
    canopy.CanCollide = false
    canopy.CanQuery = false

    if emergent or rng:NextNumber() < 0.26 then
        local side = makePart(
            model,
            "CanopySide",
            Vector3.new(canopyWidth * 0.62, canopyHeight * 0.75, canopyWidth * 0.64),
            CFrame.new(crown + Vector3.new(rng:NextNumber(-7, 7), rng:NextNumber(-3, 2), rng:NextNumber(-7, 7))),
            Enum.Material.Grass,
            Color3.fromRGB(42 + rng:NextInteger(0, 15), 88 + rng:NextInteger(0, 25), 43 + rng:NextInteger(0, 13)),
            Enum.PartType.Ball
        )
        side.CanCollide = false
        side.CanQuery = false
    end

    return model
end

local function createPalm(parent, position, rng)
    local model = Instance.new("Model")
    model.Name = "Palm"
    model.Parent = parent
    tagVegetation(model, "Palm")

    local height = rng:NextNumber(21, 37)
    local leanX = rng:NextNumber(-4.5, 4.5)
    local leanZ = rng:NextNumber(-4.5, 4.5)
    local crown = position + Vector3.new(leanX, height, leanZ)
    local trunkMid = (position + crown) / 2

    local trunk = makePart(
        model,
        "Trunk",
        Vector3.new(height, 2.25, 2.25),
        CFrame.lookAt(trunkMid, crown) * CFrame.Angles(0, math.rad(90), 0),
        Enum.Material.Wood,
        Color3.fromRGB(108 + rng:NextInteger(0, 15), 79 + rng:NextInteger(0, 14), 48 + rng:NextInteger(0, 10)),
        Enum.PartType.Cylinder
    )
    trunk.CanCollide = true
    trunk.CanQuery = true

    for i = 1, 5 do
        local angle = (i / 5) * math.pi * 2 + rng:NextNumber(-0.22, 0.22)
        local leafLength = rng:NextNumber(10, 15)
        local center = crown + Vector3.new(
            math.cos(angle) * leafLength * 0.42,
            rng:NextNumber(-1.4, 1.2),
            math.sin(angle) * leafLength * 0.42
        )
        local leaf = makePart(
            model,
            "Frond",
            Vector3.new(leafLength, 0.7, rng:NextNumber(2.4, 3.6)),
            CFrame.new(center) * CFrame.Angles(0, -angle, rng:NextNumber(-0.3, 0.12)),
            Enum.Material.Grass,
            Color3.fromRGB(49 + rng:NextInteger(0, 18), 103 + rng:NextInteger(0, 25), 48 + rng:NextInteger(0, 13))
        )
        leaf.CanCollide = false
        leaf.CanQuery = false
    end

    return model
end

local function createMangrove(parent, position, rng)
    local model = Instance.new("Model")
    model.Name = "Mangrove"
    model.Parent = parent
    tagVegetation(model, "Mangrove")

    local trunkHeight = rng:NextNumber(11, 20)
    local trunk = makePart(
        model,
        "Trunk",
        Vector3.new(2.5, trunkHeight, 2.5),
        CFrame.new(position + Vector3.new(0, trunkHeight / 2, 0)),
        Enum.Material.Wood,
        Color3.fromRGB(81, 61, 41)
    )
    trunk.CanCollide = true
    trunk.CanQuery = true

    for i = 1, 3 do
        local angle = i / 3 * math.pi * 2 + rng:NextNumber(-0.25, 0.25)
        local rootEnd = position + Vector3.new(
            math.cos(angle) * rng:NextNumber(4, 7),
            0,
            math.sin(angle) * rng:NextNumber(4, 7)
        )
        local rootMid = (position + rootEnd) / 2 + Vector3.new(0, 2.1, 0)
        local length = (rootEnd - position).Magnitude
        local root = makePart(
            model,
            "Root",
            Vector3.new(0.85, 0.85, length),
            CFrame.lookAt(rootMid, rootEnd),
            Enum.Material.Wood,
            Color3.fromRGB(77, 56, 37)
        )
        root.CanCollide = false
        root.CanQuery = false
    end

    local canopy = makePart(
        model,
        "Canopy",
        Vector3.new(rng:NextNumber(12, 17), rng:NextNumber(8, 11), rng:NextNumber(12, 17)),
        CFrame.new(position + Vector3.new(rng:NextNumber(-2, 2), trunkHeight + 2, rng:NextNumber(-2, 2))),
        Enum.Material.Grass,
        Color3.fromRGB(43 + rng:NextInteger(0, 12), 91 + rng:NextInteger(0, 22), 46 + rng:NextInteger(0, 12)),
        Enum.PartType.Ball
    )
    canopy.CanCollide = false
    canopy.CanQuery = false

    return model
end

local function createUnderstory(parent, position, rng)
    local size = rng:NextNumber(4.5, 9.5)
    local shrub = makePart(
        parent,
        "Understory",
        Vector3.new(size, rng:NextNumber(2.8, 6.5), size * rng:NextNumber(0.8, 1.15)),
        CFrame.new(position + Vector3.new(0, rng:NextNumber(1.4, 2.6), 0)),
        Enum.Material.Grass,
        Color3.fromRGB(35 + rng:NextInteger(0, 16), 78 + rng:NextInteger(0, 30), 36 + rng:NextInteger(0, 13)),
        Enum.PartType.Ball
    )
    shrub.CanCollide = false
    shrub.CanQuery = false
    shrub:SetAttribute("GeneratedPlaceholder", true)
    shrub:SetAttribute("VegetationType", "Understory")
    CollectionService:AddTag(shrub, "WorldVegetation")
    return shrub
end

local function createRock(parent, position, rng)
    local size = Vector3.new(rng:NextNumber(3, 10), rng:NextNumber(2, 7), rng:NextNumber(3, 10))
    local rock = makePart(
        parent,
        "Rock",
        size,
        CFrame.new(position + Vector3.new(0, size.Y * 0.3, 0))
            * CFrame.Angles(
                rng:NextNumber(-0.32, 0.32),
                rng:NextNumber(0, math.pi),
                rng:NextNumber(-0.32, 0.32)
            ),
        Enum.Material.Slate,
        Color3.fromRGB(
            80 + rng:NextInteger(0, 17),
            80 + rng:NextInteger(0, 17),
            75 + rng:NextInteger(0, 13)
        )
    )
    rock.CanCollide = true
    rock.CanQuery = true
    rock:SetAttribute("GeneratedPlaceholder", true)
    CollectionService:AddTag(rock, "WorldSetDressing")
    return rock
end

local function forestScore(config, x, z)
    local settings = config.Vegetation or {}
    local scale = settings.ForestNoiseScale or 185
    local seed = config.Seed
    local broad = math.noise(x / scale, z / scale, seed * 0.00071)
    local detail = math.noise(x / 76, z / 76, seed * 0.00137)
    return broad * 0.74 + detail * 0.26
end

local function insideMainIsland(config, x, z, margin)
    local island = config.Island
    local nx = x / math.max(1, island.HalfX - margin)
    local nz = z / math.max(1, island.HalfZ - margin)
    return nx * nx + nz * nz < 1
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

    local understory = Instance.new("Folder")
    understory.Name = "Understory"
    understory.Parent = folder

    local dressing = Instance.new("Folder")
    dressing.Name = "RocksAndDressing"
    dressing.Parent = folder

    local rng = Random.new(config.Seed + 9041)
    local island = config.Island
    local settings = config.Vegetation or {}
    local density = config.Generation.VegetationDensity or 1
    local maxAttemptsMultiplier = settings.MaxAttemptsMultiplier or 7
    local pathClearance = settings.PathClearance or 9
    local maxElevation = settings.MaxTreeElevation or 235
    local forestBias = settings.ForestNoiseBias or -0.34

    local treeGrid = createSpatialGrid(math.max(6, settings.TreeSpacing or 8.5))
    local understoryGrid = createSpatialGrid(5)

    local counts = {
        JungleTrees = 0,
        EmergentTrees = 0,
        Palms = 0,
        Mangroves = 0,
        Understory = 0,
        Rocks = 0,
    }

    local function yieldMaybe(attempt)
        if attempt % 55 == 0 then
            task.wait()
        end
    end

    local jungleTarget = math.floor((settings.JungleTreeTarget or 1800) * density)
    local jungleMaxAttempts = math.max(jungleTarget * maxAttemptsMultiplier, jungleTarget)
    for attempt = 1, jungleMaxAttempts do
        if counts.JungleTrees >= jungleTarget then
            break
        end

        local x = rng:NextNumber(-island.HalfX + 45, island.HalfX - 45)
        local z = rng:NextNumber(-island.HalfZ + 45, island.HalfZ - 45)
        local y = heightAt(config, x, z)
        local position = Vector3.new(x, y, z)
        local spacing = settings.TreeSpacing or 8.5

        local westMangrove = x < -535 and z > -145 and z < 455 and y < 30
        local valid = insideMainIsland(config, x, z, 28)
            and y > config.SeaLevel + 15
            and y < maxElevation
            and not westMangrove
            and not protectedRadius(config, position, "JungleTree")
            and distanceToPath(config, position) > pathClearance
            and treeGrid.IsFree(position, spacing)

        if valid then
            local score = forestScore(config, x, z)
            local elevationPenalty = y > 180 and 0.24 or 0
            local edge = math.sqrt((x / island.HalfX) ^ 2 + (z / island.HalfZ) ^ 2)
            local edgePenalty = edge > 0.78 and 0.2 or 0
            local threshold = forestBias + elevationPenalty + edgePenalty

            if score >= threshold or rng:NextNumber() < 0.13 then
                local emergent = rng:NextNumber() < 0.085
                createJungleTree(trees, position, rng, emergent)
                treeGrid.Add(position)
                counts.JungleTrees += 1
                if emergent then
                    counts.EmergentTrees += 1
                end
            end
        end

        yieldMaybe(attempt)
    end

    local palmTarget = math.floor((settings.PalmTarget or 320) * density)
    local palmMaxAttempts = math.max(palmTarget * maxAttemptsMultiplier * 2, palmTarget)
    for attempt = 1, palmMaxAttempts do
        if counts.Palms >= palmTarget then
            break
        end

        local x = rng:NextNumber(-island.HalfX + 18, island.HalfX - 18)
        local z = rng:NextNumber(-island.HalfZ + 18, island.HalfZ - 18)
        local y = heightAt(config, x, z)
        local position = Vector3.new(x, y, z)
        local edge = math.sqrt((x / island.HalfX) ^ 2 + (z / island.HalfZ) ^ 2)
        local coastal = y < 34 and edge > 0.62

        if coastal
            and insideMainIsland(config, x, z, 10)
            and not protectedRadius(config, position, "Palm")
            and distanceToPath(config, position) > math.max(7, pathClearance - 2)
            and treeGrid.IsFree(position, settings.PalmSpacing or 10)
        then
            createPalm(palms, position, rng)
            treeGrid.Add(position)
            counts.Palms += 1
        end

        yieldMaybe(attempt)
    end

    local mangroveTarget = math.floor((settings.MangroveTarget or 220) * density)
    local mangroveMaxAttempts = math.max(mangroveTarget * maxAttemptsMultiplier * 2, mangroveTarget)
    for attempt = 1, mangroveMaxAttempts do
        if counts.Mangroves >= mangroveTarget then
            break
        end

        local x = rng:NextNumber(-1010, -535)
        local z = rng:NextNumber(-145, 455)
        local y = heightAt(config, x, z)
        local position = Vector3.new(x, y, z)

        if y > config.SeaLevel + 1
            and y < 31
            and insideMainIsland(config, x, z, 5)
            and not protectedRadius(config, position, "Mangrove")
            and distanceToPath(config, position) > math.max(6, pathClearance - 2)
            and treeGrid.IsFree(position, settings.MangroveSpacing or 7.5)
        then
            createMangrove(mangroves, position, rng)
            treeGrid.Add(position)
            counts.Mangroves += 1
        end

        yieldMaybe(attempt)
    end

    local understoryTarget = math.floor((settings.UnderstoryTarget or 900) * density)
    local understoryMaxAttempts = math.max(understoryTarget * maxAttemptsMultiplier, understoryTarget)
    for attempt = 1, understoryMaxAttempts do
        if counts.Understory >= understoryTarget then
            break
        end

        local x = rng:NextNumber(-island.HalfX + 42, island.HalfX - 42)
        local z = rng:NextNumber(-island.HalfZ + 42, island.HalfZ - 42)
        local y = heightAt(config, x, z)
        local position = Vector3.new(x, y, z)

        if insideMainIsland(config, x, z, 25)
            and y > config.SeaLevel + 13
            and y < maxElevation
            and not protectedRadius(config, position, "Understory")
            and distanceToPath(config, position) > 4.5
            and understoryGrid.IsFree(position, 5.5)
            and forestScore(config, x, z) > forestBias - 0.1
        then
            createUnderstory(understory, position, rng)
            understoryGrid.Add(position)
            counts.Understory += 1
        end

        yieldMaybe(attempt)
    end

    local rockTarget = math.floor((settings.RockTarget or 180) * density)
    local rockMaxAttempts = rockTarget * 6
    for attempt = 1, rockMaxAttempts do
        if counts.Rocks >= rockTarget then
            break
        end

        local x = rng:NextNumber(-island.HalfX + 25, island.HalfX - 25)
        local z = rng:NextNumber(-island.HalfZ + 25, island.HalfZ - 25)
        local y = heightAt(config, x, z)
        local position = Vector3.new(x, y, z)

        if insideMainIsland(config, x, z, 15)
            and y > config.SeaLevel + 4
            and y < 250
            and not protectedRadius(config, position, "Rock")
            and distanceToPath(config, position) > 6
            and rng:NextNumber() < 0.45
        then
            createRock(dressing, position, rng)
            counts.Rocks += 1
        end

        yieldMaybe(attempt)
    end

    local totalTrees = counts.JungleTrees + counts.Palms + counts.Mangroves
    folder:SetAttribute("JungleTrees", counts.JungleTrees)
    folder:SetAttribute("EmergentTrees", counts.EmergentTrees)
    folder:SetAttribute("Palms", counts.Palms)
    folder:SetAttribute("Mangroves", counts.Mangroves)
    folder:SetAttribute("Understory", counts.Understory)
    folder:SetAttribute("Rocks", counts.Rocks)
    folder:SetAttribute("TotalTrees", totalTrees)

    print(string.format(
        "[ISLE//ZERO][VEGETATION] %d trees (%d jungle, %d emergent, %d palms, %d mangroves), %d understory, %d rocks",
        totalTrees,
        counts.JungleTrees,
        counts.EmergentTrees,
        counts.Palms,
        counts.Mangroves,
        counts.Understory,
        counts.Rocks
    ))

    return folder
end

return VegetationBuilder
