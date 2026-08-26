local CollectionService = game:GetService("CollectionService")

local CaveBuilder = {}

local function makePart(parent, name, size, cframe, material, color, transparency)
    local object = Instance.new("Part")
    object.Name = name
    object.Anchored = true
    object.CanTouch = false
    object.Material = material
    object.Color = color
    object.Transparency = transparency or 0
    object.Size = size
    object.CFrame = cframe
    object.TopSurface = Enum.SurfaceType.Smooth
    object.BottomSurface = Enum.SurfaceType.Smooth
    object.Parent = parent
    object:SetAttribute("GeneratedPlaceholder", true)
    return object
end

local function markDiscovery(model, id, displayName)
    model:SetAttribute("DiscoveryId", id)
    model:SetAttribute("DiscoveryName", displayName)
    model:SetAttribute("GeneratedPlaceholder", true)
    model:SetAttribute("GuardianDefeated", false)
    model:SetAttribute("CampBuilt", false)
    CollectionService:AddTag(model, "WorldCave")
    CollectionService:AddTag(model, "ExplorationSite")
end

local function worldNode(config, node, heightAt)
    local surface = heightAt(config, node.X, node.Z)
    local minimum = config.Island.BaseY + 18
    return Vector3.new(node.X, math.max(minimum, surface + node.Y), node.Z)
end

local function carveSegment(terrain, a, b, radius)
    local length = (b - a).Magnitude
    local samples = math.max(1, math.ceil(length / 5))

    for index = 0, samples do
        local alpha = index / samples
        local point = a:Lerp(b, alpha)
        local variation = math.sin(alpha * math.pi) * 1.7 + math.sin(alpha * math.pi * 4) * 0.45
        terrain:FillBall(point, radius + variation, Enum.Material.Air)
    end
end

local function floorSegment(parent, a, b, width)
    local delta = b - a
    if delta.Magnitude < 1 then
        return
    end

    local offset = Vector3.new(0, width * 0.58, 0)
    local from = a - offset
    local to = b - offset
    local floor = makePart(
        parent,
        "CavePath",
        Vector3.new(width * 1.45, 1.5, delta.Magnitude + 3),
        CFrame.lookAt((from + to) / 2, to),
        Enum.Material.Slate,
        Color3.fromRGB(61, 65, 62)
    )
    floor.CanCollide = true
end

local function chamberFloor(parent, center, radius)
    local floor = makePart(
        parent,
        "ChamberFloor",
        Vector3.new(2.2, radius * 1.65, radius * 1.65),
        CFrame.new(center - Vector3.new(0, radius * 0.7, 0)) * CFrame.Angles(0, 0, math.rad(90)),
        Enum.Material.Slate,
        Color3.fromRGB(57, 61, 58)
    )
    floor.Shape = Enum.PartType.Cylinder
    floor.CanCollide = true
    return floor
end

local function createEntranceRocks(model, entrance, direction, radius)
    local horizontal = Vector3.new(direction.X, 0, direction.Z)
    if horizontal.Magnitude < 0.1 then
        horizontal = Vector3.new(0, 0, -1)
    else
        horizontal = horizontal.Unit
    end
    local right = Vector3.new(-horizontal.Z, 0, horizontal.X)
    local rockColor = Color3.fromRGB(73, 77, 72)

    local offsets = {
        right * (radius * 0.95) + Vector3.new(0, 4, 0),
        -right * (radius * 0.95) + Vector3.new(0, 5, 0),
        right * (radius * 0.62) + Vector3.new(0, radius * 0.75, 0),
        -right * (radius * 0.6) + Vector3.new(0, radius * 0.82, 0),
        Vector3.new(0, radius * 1.05, 0),
    }

    for index, offset in ipairs(offsets) do
        local rock = makePart(
            model,
            "EntranceRock",
            Vector3.new(radius * 0.8, radius * (0.75 + (index % 3) * 0.14), radius * 0.7),
            CFrame.new(entrance + offset) * CFrame.Angles(index * 0.17, index * 0.72, index * 0.12),
            Enum.Material.Rock,
            rockColor
        )
        rock.CanCollide = true
    end
end

local function createPickup(parent, caveId, itemId, amount, position)
    local colors = {
        Stone = Color3.fromRGB(103, 108, 103),
        Rope = Color3.fromRGB(143, 111, 67),
        Cloth = Color3.fromRGB(152, 150, 124),
        Herb = Color3.fromRGB(68, 126, 61),
        Wood = Color3.fromRGB(111, 77, 44),
    }
    local pickup = makePart(
        parent,
        "Pickup_" .. itemId,
        Vector3.new(2.5, 2.5, 2.5),
        CFrame.new(position),
        itemId == "Herb" and Enum.Material.Grass or Enum.Material.SmoothPlastic,
        colors[itemId] or Color3.fromRGB(125, 125, 120)
    )
    pickup.Shape = itemId == "Stone" and Enum.PartType.Ball or Enum.PartType.Block
    pickup.CanCollide = false
    pickup:SetAttribute("ItemId", itemId)
    pickup:SetAttribute("Amount", amount)
    pickup:SetAttribute("CaveId", caveId)
    CollectionService:AddTag(pickup, "WorldPickup")

    local prompt = Instance.new("ProximityPrompt")
    prompt.Name = "PickupPrompt"
    prompt.ActionText = "Pick up"
    prompt.ObjectText = itemId
    prompt.HoldDuration = 0.15
    prompt.MaxActivationDistance = 10
    prompt.RequiresLineOfSight = false
    prompt.Parent = pickup
end

local function createChest(parent, caveId, routeName, tier, position, yaw)
    local model = Instance.new("Model")
    model.Name = "Chest_" .. routeName
    model.Parent = parent
    model:SetAttribute("GeneratedPlaceholder", true)

    local body = makePart(
        model,
        "ChestBody",
        Vector3.new(7.5, 4.2, 5.2),
        CFrame.new(position) * CFrame.Angles(0, yaw, 0),
        Enum.Material.WoodPlanks,
        Color3.fromRGB(91, 63, 37)
    )
    body:SetAttribute("ChestId", caveId .. "_" .. routeName)
    body:SetAttribute("CaveId", caveId)
    body:SetAttribute("LootTier", tier)
    CollectionService:AddTag(body, "LootChest")

    makePart(
        model,
        "ChestLid",
        Vector3.new(7.7, 1.4, 5.4),
        CFrame.new(position + Vector3.new(0, 2.7, 0)) * CFrame.Angles(0, yaw, 0),
        Enum.Material.WoodPlanks,
        Color3.fromRGB(108, 74, 41)
    )
    for _, x in ipairs({-2.6, 2.6}) do
        makePart(
            model,
            "MetalBand",
            Vector3.new(0.5, 5.5, 5.5),
            CFrame.new(position + Vector3.new(x, 1.25, 0)) * CFrame.Angles(0, yaw, 0),
            Enum.Material.CorrodedMetal,
            Color3.fromRGB(68, 70, 66)
        ).CanCollide = false
    end

    local prompt = Instance.new("ProximityPrompt")
    prompt.Name = "OpenChestPrompt"
    prompt.ActionText = "Open"
    prompt.ObjectText = routeName .. " cache"
    prompt.HoldDuration = 0.5
    prompt.MaxActivationDistance = 10
    prompt.RequiresLineOfSight = false
    prompt.Enabled = false
    prompt.Parent = body
end

local function signText(board, text)
    local gui = Instance.new("SurfaceGui")
    gui.Name = "CaveRouteLabel"
    gui.Face = Enum.NormalId.Front
    gui.AlwaysOnTop = false
    gui.Parent = board

    local label = Instance.new("TextLabel")
    label.BackgroundTransparency = 1
    label.Size = UDim2.fromScale(1, 1)
    label.Text = text
    label.TextScaled = true
    label.TextWrapped = true
    label.TextColor3 = Color3.fromRGB(226, 210, 170)
    label.TextStrokeTransparency = 0.55
    label.Font = Enum.Font.GothamBold
    label.Parent = gui
end

local function createRouteSign(parent, position, lookAt, text)
    local horizontalTarget = Vector3.new(lookAt.X, position.Y, lookAt.Z)
    local board = makePart(
        parent,
        "RouteSign",
        Vector3.new(8, 3, 0.55),
        CFrame.lookAt(position, horizontalTarget),
        Enum.Material.WoodPlanks,
        Color3.fromRGB(83, 58, 35)
    )
    board.CanCollide = false
    signText(board, text)
end

local function createGuardianMarker(parent, caveId, guardianType, position)
    local marker = makePart(
        parent,
        "GuardianSpawn",
        Vector3.new(4, 1, 4),
        CFrame.new(position),
        Enum.Material.SmoothPlastic,
        Color3.fromRGB(255, 255, 255),
        1
    )
    marker.CanCollide = false
    marker.CanQuery = false
    marker:SetAttribute("CaveId", caveId)
    marker:SetAttribute("GuardianType", guardianType)
    CollectionService:AddTag(marker, "CaveGuardianSpawn")
end

local function createCampSpot(parent, caveId, position)
    local pad = makePart(
        parent,
        "CampBuildSpot",
        Vector3.new(13, 0.8, 11),
        CFrame.new(position),
        Enum.Material.Slate,
        Color3.fromRGB(72, 78, 69),
        0.18
    )
    pad.CanCollide = true
    pad:SetAttribute("CaveId", caveId)
    CollectionService:AddTag(pad, "CampBuildSpot")

    local prompt = Instance.new("ProximityPrompt")
    prompt.Name = "CampPrompt"
    prompt.ActionText = "Build safe tent"
    prompt.ObjectText = "Clear the cave first"
    prompt.HoldDuration = 0.75
    prompt.MaxActivationDistance = 11
    prompt.RequiresLineOfSight = false
    prompt.Enabled = false
    prompt.Parent = pad
end

local function createGuideLight(parent, position, index)
    local crystal = makePart(
        parent,
        "CaveGlow",
        Vector3.new(1.1, 2.4 + index % 2, 1.1),
        CFrame.new(position),
        Enum.Material.Neon,
        Color3.fromRGB(76, 139, 144),
        0.12
    )
    crystal.CanCollide = false
    crystal.CanQuery = false
    local light = Instance.new("PointLight")
    light.Brightness = 0.75
    light.Range = 16
    light.Color = Color3.fromRGB(95, 168, 169)
    light.Parent = crystal
end

local function createProps(model, cave, chamber, floorY)
    if cave.Props == "Expedition" then
        makePart(model, "BrokenCrate", Vector3.new(6, 4, 6), CFrame.new(chamber + Vector3.new(10, floorY - chamber.Y + 2, 4)) * CFrame.Angles(0.2, 0.4, 0.1), Enum.Material.WoodPlanks, Color3.fromRGB(88, 64, 39))
        local journal = makePart(model, "OldJournal", Vector3.new(2.4, 0.35, 3), CFrame.new(chamber + Vector3.new(5, floorY - chamber.Y + 1, -8)), Enum.Material.Fabric, Color3.fromRGB(83, 59, 40))
        journal.CanCollide = false
    elseif cave.Props == "Smuggler" then
        for index = 1, 3 do
            local barrel = makePart(model, "SmugglerBarrel", Vector3.new(5.5, 4.2, 4.2), CFrame.new(chamber + Vector3.new(index * 5 - 9, floorY - chamber.Y + 2.2, 10)) * CFrame.Angles(0, index * 0.5, math.rad(90)), Enum.Material.CorrodedMetal, Color3.fromRGB(76, 77, 67))
            barrel.Shape = Enum.PartType.Cylinder
        end
    elseif cave.Props == "Temple" then
        for _, x in ipairs({-10, 10}) do
            makePart(model, "UndercroftColumn", Vector3.new(4, 15, 4), CFrame.new(chamber + Vector3.new(x, floorY - chamber.Y + 7.5, 8)), Enum.Material.Limestone, Color3.fromRGB(103, 102, 91))
        end
        makePart(model, "UndercroftAltar", Vector3.new(9, 4, 6), CFrame.new(chamber + Vector3.new(0, floorY - chamber.Y + 2, 12)), Enum.Material.Limestone, Color3.fromRGB(105, 103, 91))
    elseif cave.Props == "Bunker" then
        makePart(model, "ServiceFrame", Vector3.new(18, 2, 2), CFrame.new(chamber + Vector3.new(0, floorY - chamber.Y + 10, 8)), Enum.Material.Metal, Color3.fromRGB(68, 72, 69))
        for _, x in ipairs({-8, 8}) do
            makePart(model, "ServicePost", Vector3.new(2, 18, 2), CFrame.new(chamber + Vector3.new(x, floorY - chamber.Y + 9, 8)), Enum.Material.Metal, Color3.fromRGB(68, 72, 69))
        end
    else
        for index = 1, 5 do
            local rock = makePart(model, "DeepCaveRock", Vector3.new(4 + index, 3 + index % 2, 5), CFrame.new(chamber + Vector3.new(-14 + index * 6, floorY - chamber.Y + 1.5, 10 + (index % 2) * 4)) * CFrame.Angles(index * 0.1, index * 0.7, 0), Enum.Material.Rock, Color3.fromRGB(70, 74, 71))
            rock.CanCollide = false
        end
    end
end

local function buildBranches(terrain, model, caveId, chamber, previous, radius)
    local horizontal = Vector3.new(chamber.X - previous.X, 0, chamber.Z - previous.Z)
    if horizontal.Magnitude < 0.1 then
        horizontal = Vector3.new(0, 0, -1)
    else
        horizontal = horizontal.Unit
    end
    local right = Vector3.new(-horizontal.Z, 0, horizontal.X)

    local branches = {
        {
            Name = "SUPPLIES",
            Tier = "Supplies",
            Mid = chamber + right * 28 + horizontal * 20 + Vector3.new(0, -3, 0),
            Target = chamber + right * 62 + horizontal * 42 + Vector3.new(0, -5, 0),
        },
        {
            Name = "RELIC",
            Tier = "Relic",
            Mid = chamber - right * 30 + horizontal * 18 + Vector3.new(0, -4, 0),
            Target = chamber - right * 66 + horizontal * 40 + Vector3.new(0, -8, 0),
        },
        {
            Name = "DEEP CACHE",
            Tier = "Deep",
            Mid = chamber + horizontal * 46 + Vector3.new(0, -6, 0),
            Target = chamber + horizontal * 92 + right * 7 + Vector3.new(0, -12, 0),
        },
    }

    for index, branch in ipairs(branches) do
        carveSegment(terrain, chamber, branch.Mid, radius * 0.82)
        carveSegment(terrain, branch.Mid, branch.Target, radius * 0.86)
        terrain:FillBall(branch.Target, radius * 1.15, Enum.Material.Air)
        floorSegment(model, chamber, branch.Mid, radius * 0.8)
        floorSegment(model, branch.Mid, branch.Target, radius * 0.8)
        chamberFloor(model, branch.Target, radius * 0.85)

        local chestY = branch.Target.Y - radius * 0.58 + 2.2
        createChest(model, caveId, branch.Name, branch.Tier, Vector3.new(branch.Target.X, chestY, branch.Target.Z), index * 0.65)

        local signPosition = chamber + horizontal * 8 + (index == 1 and right * 6 or index == 2 and -right * 6 or Vector3.zero) + Vector3.new(0, -radius * 0.48 + 5, 0)
        createRouteSign(model, signPosition, branch.Target, branch.Name)

        if index == 1 then
            createPickup(model, caveId, "Rope", 1, branch.Mid - Vector3.new(0, radius * 0.5, 0))
        elseif index == 2 then
            createPickup(model, caveId, "Herb", 1, branch.Mid - Vector3.new(0, radius * 0.5, 0))
        else
            createPickup(model, caveId, "Stone", 2, branch.Mid - Vector3.new(0, radius * 0.5, 0))
        end
    end
end

local function buildOne(config, folder, caveId, cave, heightAt)
    local terrain = workspace.Terrain
    local model = Instance.new("Model")
    model.Name = caveId
    model.Parent = folder
    markDiscovery(model, caveId, cave.DiscoveryName or caveId)

    local nodes = {}
    for _, node in ipairs(cave.Nodes) do
        table.insert(nodes, worldNode(config, node, heightAt))
    end

    if #nodes < 2 then
        return model
    end

    local radius = cave.TunnelRadius or 13
    for index = 1, #nodes - 1 do
        carveSegment(terrain, nodes[index], nodes[index + 1], radius)
        floorSegment(model, nodes[index], nodes[index + 1], radius)
        if index % 2 == 0 then
            local glowPosition = nodes[index]:Lerp(nodes[index + 1], 0.45) - Vector3.new(0, radius * 0.4, 0)
            createGuideLight(model, glowPosition, index)
        end
    end

    local entrance = nodes[1]
    local entranceDirection = nodes[2] - nodes[1]
    terrain:FillBall(entrance, radius * 1.15, Enum.Material.Air)
    createEntranceRocks(model, entrance, entranceDirection, radius)

    local chamber = nodes[#nodes]
    local chamberRadius = cave.ChamberRadius or radius * 2
    terrain:FillBall(chamber, chamberRadius, Enum.Material.Air)
    chamberFloor(model, chamber, chamberRadius)

    local chamberFloorY = chamber.Y - chamberRadius * 0.68
    createProps(model, cave, chamber, chamberFloorY)
    buildBranches(terrain, model, caveId, chamber, nodes[#nodes - 1], radius)

    local guardianPosition = Vector3.new(chamber.X, chamberFloorY + 4, chamber.Z - 4)
    createGuardianMarker(model, caveId, cave.Guardian or "CaveBoar", guardianPosition)
    createCampSpot(model, caveId, Vector3.new(chamber.X + 12, chamberFloorY + 0.6, chamber.Z + 12))

    if #nodes >= 4 then
        createPickup(model, caveId, "Stone", 2, nodes[3] - Vector3.new(0, radius * 0.48, 0))
        createPickup(model, caveId, "Cloth", 1, nodes[4] - Vector3.new(0, radius * 0.48, 0))
    end

    model:SetAttribute("TunnelNodeCount", #nodes)
    model:SetAttribute("BranchCount", 3)
    model:SetAttribute("GuardianType", cave.Guardian or "CaveBoar")
    model:SetAttribute("MainChamberX", chamber.X)
    model:SetAttribute("MainChamberY", chamber.Y)
    model:SetAttribute("MainChamberZ", chamber.Z)
    return model
end

function CaveBuilder.Build(config, root, heightAt)
    local folder = Instance.new("Folder")
    folder.Name = "Caves"
    folder.Parent = root

    local count = 0
    for caveId, cave in pairs((config.Exploration and config.Exploration.Caves) or {}) do
        buildOne(config, folder, caveId, cave, heightAt)
        count += 1
    end

    folder:SetAttribute("CaveCount", count)
    print(string.format("[ISLE//ZERO][CAVES] Built %d deep branching cave dungeons", count))
    return folder
end

return CaveBuilder
