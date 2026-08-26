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
    CollectionService:AddTag(model, "WorldCave")
    CollectionService:AddTag(model, "ExplorationSite")
end

local function worldNode(config, node, heightAt)
    return Vector3.new(
        node.X,
        heightAt(config, node.X, node.Z) + node.Y,
        node.Z
    )
end

local function carveSegment(terrain, a, b, radius)
    local length = (b - a).Magnitude
    local samples = math.max(1, math.ceil(length / 7))

    for index = 0, samples do
        local alpha = index / samples
        local point = a:Lerp(b, alpha)
        local variation = math.sin(alpha * math.pi) * 1.6
        terrain:FillBall(point, radius + variation, Enum.Material.Air)
    end
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
        right * (radius * 0.78) + Vector3.new(0, 2.5, 0),
        -right * (radius * 0.78) + Vector3.new(0, 2.5, 0),
        right * (radius * 0.62) + Vector3.new(0, radius * 0.65, 0),
        -right * (radius * 0.62) + Vector3.new(0, radius * 0.65, 0),
        right * (radius * 0.30) + Vector3.new(0, radius * 0.92, 0),
        -right * (radius * 0.30) + Vector3.new(0, radius * 0.92, 0),
    }

    for index, offset in ipairs(offsets) do
        local size = Vector3.new(
            5 + (index % 3) * 1.7,
            6 + (index % 2) * 2.4,
            5 + ((index + 1) % 3) * 1.5
        )
        local rock = makePart(
            model,
            "EntranceRock",
            size,
            CFrame.new(entrance + offset)
                * CFrame.Angles(index * 0.13, index * 0.41, index * 0.09),
            Enum.Material.Rock,
            rockColor
        )
        rock.CanCollide = true
        rock.CanQuery = true
    end
end

local function createCrate(parent, position, rotation)
    local crate = makePart(
        parent,
        "OldCrate",
        Vector3.new(6, 5, 6),
        CFrame.new(position) * CFrame.Angles(0, rotation, 0),
        Enum.Material.WoodPlanks,
        Color3.fromRGB(93, 70, 43)
    )
    crate.CanCollide = true
    return crate
end

local function createBarrel(parent, position, rotation)
    local barrel = makePart(
        parent,
        "RustBarrel",
        Vector3.new(5.5, 4.4, 4.4),
        CFrame.new(position) * CFrame.Angles(0, rotation, math.rad(90)),
        Enum.Material.CorrodedMetal,
        Color3.fromRGB(77, 76, 68)
    )
    barrel.Shape = Enum.PartType.Cylinder
    barrel.CanCollide = true
    return barrel
end

local function createLantern(parent, position, lit)
    local base = makePart(
        parent,
        "LanternBase",
        Vector3.new(1.7, 0.5, 1.7),
        CFrame.new(position),
        Enum.Material.Metal,
        Color3.fromRGB(65, 67, 62)
    )
    base.CanCollide = false

    local glass = makePart(
        parent,
        "LanternGlow",
        Vector3.new(1.1, 1.8, 1.1),
        CFrame.new(position + Vector3.new(0, 1.1, 0)),
        lit and Enum.Material.Neon or Enum.Material.Glass,
        lit and Color3.fromRGB(222, 179, 98) or Color3.fromRGB(104, 110, 105),
        lit and 0.25 or 0.55
    )
    glass.CanCollide = false
    glass.CanQuery = false

    if lit then
        local light = Instance.new("PointLight")
        light.Name = "CaveLanternLight"
        light.Brightness = 1.2
        light.Range = 18
        light.Shadows = true
        light.Color = Color3.fromRGB(255, 205, 128)
        light.Parent = glass
    end
end

local function decorateSmuggler(model, floorPosition)
    createCrate(model, floorPosition + Vector3.new(-7, 1.9, -4), 0.28)
    createCrate(model, floorPosition + Vector3.new(-1, 1.9, -8), -0.16)
    createCrate(model, floorPosition + Vector3.new(6, 1.9, -5), 0.52)
    createBarrel(model, floorPosition + Vector3.new(8, 2.2, 4), 0.2)
    createBarrel(model, floorPosition + Vector3.new(4, 2.2, 8), -0.4)
    createLantern(model, floorPosition + Vector3.new(-3, 0.4, 5), true)

    local plank = makePart(
        model,
        "BrokenPlank",
        Vector3.new(15, 0.7, 2.2),
        CFrame.new(floorPosition + Vector3.new(0, 0.8, 2)) * CFrame.Angles(0, 0.44, 0.05),
        Enum.Material.WoodPlanks,
        Color3.fromRGB(81, 60, 38)
    )
    plank.CanCollide = false
end

local function decorateExpedition(model, floorPosition)
    createCrate(model, floorPosition + Vector3.new(-6, 1.9, 3), 0.22)
    createLantern(model, floorPosition + Vector3.new(3, 0.4, 3), false)

    local bedroll = makePart(
        model,
        "AbandonedBedroll",
        Vector3.new(7, 0.6, 3),
        CFrame.new(floorPosition + Vector3.new(5, 0.7, -4)) * CFrame.Angles(0, -0.3, 0),
        Enum.Material.Fabric,
        Color3.fromRGB(77, 88, 69)
    )
    bedroll.CanCollide = false

    for index = 1, 5 do
        local bone = makePart(
            model,
            "ExpeditionBone",
            Vector3.new(0.55, 0.55, 2.8 + index * 0.22),
            CFrame.new(floorPosition + Vector3.new(-1 + index * 0.8, 0.8, -5 + (index % 2)))
                * CFrame.Angles(index * 0.2, index * 0.7, index * 0.12),
            Enum.Material.SmoothPlastic,
            Color3.fromRGB(188, 181, 158)
        )
        bone.CanCollide = false
        bone.CanQuery = false
    end
end

local function decorateTemple(model, floorPosition)
    local stone = Color3.fromRGB(105, 104, 94)
    makePart(
        model,
        "UndercroftAltar",
        Vector3.new(12, 3.2, 7),
        CFrame.new(floorPosition + Vector3.new(0, 1.7, -7)),
        Enum.Material.Limestone,
        stone
    )
    for _, x in ipairs({-9, 9}) do
        makePart(
            model,
            "BuriedColumn",
            Vector3.new(3.5, 11, 3.5),
            CFrame.new(floorPosition + Vector3.new(x, 5.5, 2)),
            Enum.Material.Limestone,
            stone
        )
    end
    for index = 1, 6 do
        local rubble = makePart(
            model,
            "TempleRubble",
            Vector3.new(3 + index % 3, 1.4 + index % 2, 3.5),
            CFrame.new(floorPosition + Vector3.new(-10 + index * 3.2, 0.9, 7 - (index % 2) * 4))
                * CFrame.Angles(0.1 * index, 0.48 * index, 0.08 * index),
            Enum.Material.Limestone,
            stone
        )
        rubble.CanCollide = false
    end
end

local function decorateBunker(model, floorPosition)
    local concrete = Color3.fromRGB(91, 96, 91)
    makePart(
        model,
        "ServiceWallLeft",
        Vector3.new(3, 13, 12),
        CFrame.new(floorPosition + Vector3.new(-7, 6.5, -5)),
        Enum.Material.Concrete,
        concrete
    )
    makePart(
        model,
        "ServiceWallRight",
        Vector3.new(3, 13, 12),
        CFrame.new(floorPosition + Vector3.new(7, 6.5, -5)),
        Enum.Material.Concrete,
        concrete
    )
    local door = makePart(
        model,
        "InnerServiceDoor",
        Vector3.new(11, 11, 1.8),
        CFrame.new(floorPosition + Vector3.new(0, 5.5, -10.5)),
        Enum.Material.DiamondPlate,
        Color3.fromRGB(57, 65, 62)
    )
    door:SetAttribute("InteractableFuture", "BunkerServiceDoor")
    createLantern(model, floorPosition + Vector3.new(-4, 0.4, 4), true)
end

local function decorateNatural(model, floorPosition)
    for index = 1, 8 do
        local angle = index / 8 * math.pi * 2
        local distance = 7 + (index % 3) * 3
        local rock = makePart(
            model,
            "CaveBoulder",
            Vector3.new(3 + index % 4, 2 + index % 3, 4 + ((index + 1) % 4)),
            CFrame.new(floorPosition + Vector3.new(math.cos(angle) * distance, 1.2, math.sin(angle) * distance))
                * CFrame.Angles(index * 0.16, index * 0.51, index * 0.1),
            Enum.Material.Rock,
            Color3.fromRGB(67, 72, 69)
        )
        rock.CanCollide = false
    end
end

local function buildOneCave(config, root, caveId, cave, heightAt)
    local terrain = workspace.Terrain
    local model = Instance.new("Model")
    model.Name = caveId
    model.Parent = root
    markDiscovery(model, caveId, cave.DiscoveryName or caveId)

    local nodes = {}
    for _, node in ipairs(cave.Nodes) do
        table.insert(nodes, worldNode(config, node, heightAt))
    end

    if #nodes < 2 then
        return model
    end

    local radius = cave.TunnelRadius or 12
    terrain:FillBall(nodes[1], radius * 1.12, Enum.Material.Air)

    for index = 1, #nodes - 1 do
        carveSegment(terrain, nodes[index], nodes[index + 1], radius)
    end

    local chamberRadius = cave.ChamberRadius or radius * 1.8
    local chamber = nodes[#nodes]
    terrain:FillBall(chamber, chamberRadius, Enum.Material.Air)
    terrain:FillBall(chamber + Vector3.new(chamberRadius * 0.34, 2, 0), chamberRadius * 0.64, Enum.Material.Air)

    local floorPosition = chamber - Vector3.new(0, chamberRadius * 0.47, 0)
    local floor = makePart(
        model,
        "CaveFloor",
        Vector3.new(chamberRadius * 1.55, 1.2, chamberRadius * 1.45),
        CFrame.new(floorPosition),
        Enum.Material.Slate,
        Color3.fromRGB(61, 66, 64)
    )
    floor.CanCollide = true

    local direction = nodes[2] - nodes[1]
    createEntranceRocks(model, nodes[1], direction, radius)

    local marker = makePart(
        model,
        "DiscoveryMarker",
        Vector3.new(5, 7, 5),
        CFrame.new(nodes[1]),
        Enum.Material.SmoothPlastic,
        Color3.fromRGB(255, 255, 255),
        1
    )
    marker.CanCollide = false
    marker.CanQuery = false
    marker:SetAttribute("DiscoveryId", caveId)
    marker:SetAttribute("DiscoveryName", cave.DiscoveryName or caveId)

    local props = cave.Props or "Natural"
    if props == "Smuggler" then
        decorateSmuggler(model, floorPosition)
    elseif props == "Expedition" then
        decorateExpedition(model, floorPosition)
    elseif props == "Temple" then
        decorateTemple(model, floorPosition)
    elseif props == "Bunker" then
        decorateBunker(model, floorPosition)
    else
        decorateNatural(model, floorPosition)
    end

    model:SetAttribute("EntranceX", nodes[1].X)
    model:SetAttribute("EntranceY", nodes[1].Y)
    model:SetAttribute("EntranceZ", nodes[1].Z)
    model:SetAttribute("ChamberX", chamber.X)
    model:SetAttribute("ChamberY", chamber.Y)
    model:SetAttribute("ChamberZ", chamber.Z)
    return model
end

function CaveBuilder.Build(config, worldRoot, heightAt)
    local folder = Instance.new("Folder")
    folder.Name = "Caves"
    folder.Parent = worldRoot

    local caveCount = 0
    local caves = (config.Exploration and config.Exploration.Caves) or {}
    for caveId, cave in pairs(caves) do
        buildOneCave(config, folder, caveId, cave, heightAt)
        caveCount += 1
        task.wait()
    end

    folder:SetAttribute("CaveCount", caveCount)
    print(string.format("[ISLE//ZERO][CAVES] Built %d exploration caves", caveCount))
    return folder
end

return CaveBuilder
