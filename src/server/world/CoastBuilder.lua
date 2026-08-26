local CollectionService = game:GetService("CollectionService")

local CoastBuilder = {}

local function makePart(parent, name, size, cframe, material, color)
    local object = Instance.new("Part")
    object.Name = name
    object.Anchored = true
    object.CanCollide = true
    object.CanTouch = false
    object.Material = material
    object.Color = color
    object.Size = size
    object.CFrame = cframe
    object.Parent = parent
    object:SetAttribute("GeneratedPlaceholder", true)
    CollectionService:AddTag(object, "WorldSetDressing")
    return object
end

local function buildDesertedIsland(config, folder)
    local terrain = workspace.Terrain
    local center = config.Locations.DesertedIsland or Vector3.new(-1260, 12, 690)

    -- Layered terrain creates a real explorable southwest island rather than a
    -- decorative sea rock. It is intentionally unreachable by normal trails.
    terrain:FillBall(Vector3.new(center.X, -32, center.Z), 155, Enum.Material.Rock)
    terrain:FillBall(Vector3.new(center.X, 0, center.Z), 137, Enum.Material.Sand)
    terrain:FillBall(Vector3.new(center.X + 8, 17, center.Z - 8), 94, Enum.Material.Grass)
    terrain:FillBall(Vector3.new(center.X - 42, 9, center.Z + 36), 58, Enum.Material.Sand)

    local island = Instance.new("Model")
    island.Name = "DesertedIsland"
    island.Parent = folder
    island:SetAttribute("RegionId", "DesertedIsland")
    island:SetAttribute("GeneratedPlaceholder", true)

    local wood = Color3.fromRGB(86, 62, 38)
    local rock = Color3.fromRGB(88, 91, 86)

    -- Broken jetty where the repaired raft arrives.
    for index = 0, 5 do
        local plank = makePart(
            island,
            "OldJettyPlank",
            Vector3.new(8, 0.7, 5.5),
            CFrame.new(center.X + 118 + index * 5, 5 + (index % 2) * 0.25, center.Z + 8),
            Enum.Material.WoodPlanks,
            wood
        )
        plank.CanCollide = true
    end
    for _, x in ipairs({center.X + 118, center.X + 144}) do
        makePart(island, "JettyPost", Vector3.new(1.3, 8, 1.3), CFrame.new(x, 2, center.Z + 4), Enum.Material.Wood, wood)
        makePart(island, "JettyPost", Vector3.new(1.3, 8, 1.3), CFrame.new(x, 2, center.Z + 12), Enum.Material.Wood, wood)
    end

    -- Small abandoned stone shelter provides a visible objective from the raft.
    makePart(island, "ShelterFloor", Vector3.new(24, 1, 18), CFrame.new(center.X - 15, 26, center.Z - 18), Enum.Material.Rock, rock)
    for _, offset in ipairs({
        Vector3.new(-10, 5, -7),
        Vector3.new(10, 5, -7),
        Vector3.new(-10, 5, 7),
        Vector3.new(10, 5, 7),
    }) do
        makePart(island, "ShelterColumn", Vector3.new(2.5, 10, 2.5), CFrame.new(center.X - 15, 31, center.Z - 18) * CFrame.new(offset), Enum.Material.Rock, rock)
    end
    makePart(island, "CollapsedRoof", Vector3.new(19, 1.8, 8), CFrame.new(center.X - 15, 37, center.Z - 22) * CFrame.Angles(0.08, 0.25, 0.18), Enum.Material.Rock, rock)

    local marker = makePart(island, "DesertedIslandArrival", Vector3.new(8, 1, 8), CFrame.new(center.X + 105, 12, center.Z + 8), Enum.Material.SmoothPlastic, Color3.new(1, 1, 1))
    marker.Transparency = 1
    marker.CanCollide = false
    marker.CanQuery = false
    marker:SetAttribute("TravelPoint", "DesertedIsland")
    CollectionService:AddTag(marker, "WorldTravelPoint")
end

function CoastBuilder.Build(config, root, heightAt)
    local folder = Instance.new("Folder")
    folder.Name = "CoastAndIslets"
    folder.Parent = root

    local terrain = workspace.Terrain
    local islets = {
        {Vector3.new(1260, -15, 520), 62},
        {Vector3.new(1320, -18, -330), 48},
        {Vector3.new(980, -20, -1040), 54},
        {Vector3.new(-1260, -16, -410), 58},
        {Vector3.new(-1450, -20, 300), 43},
    }

    for index, entry in ipairs(islets) do
        local center, radius = entry[1], entry[2]
        terrain:FillBall(center, radius, Enum.Material.Rock)
        if index == 1 then
            terrain:FillBall(center + Vector3.new(0, radius * 0.45, 0), radius * 0.62, Enum.Material.Sand)
        end
    end

    buildDesertedIsland(config, folder)

    local rng = Random.new(config.Seed + 3321)
    local crash = config.Locations.CrashBeach

    for _ = 1, 22 do
        local x = crash.X + rng:NextNumber(-320, 320)
        local z = crash.Z + rng:NextNumber(-110, 140)
        local y = heightAt(config, x, z)
        if y < 22 then
            local length = rng:NextNumber(8, 22)
            local log = makePart(
                folder,
                "Driftwood",
                Vector3.new(length, rng:NextNumber(1.1, 2.2), rng:NextNumber(1.1, 2.2)),
                CFrame.new(x, y + 0.9, z) * CFrame.Angles(rng:NextNumber(-0.12, 0.12), rng:NextNumber(0, math.pi), rng:NextNumber(-0.2, 0.2)),
                Enum.Material.Wood,
                Color3.fromRGB(91, 73, 54)
            )
            log.CanCollide = false
            log.CanQuery = false
        end
    end

    for _ = 1, 11 do
        local x = rng:NextNumber(1080, 1360)
        local z = rng:NextNumber(-780, 360)
        local size = Vector3.new(rng:NextNumber(14, 35), rng:NextNumber(20, 65), rng:NextNumber(14, 34))
        makePart(
            folder,
            "SeaStack",
            size,
            CFrame.new(x, -8 + size.Y / 2, z) * CFrame.Angles(rng:NextNumber(-0.2, 0.2), rng:NextNumber(0, math.pi), rng:NextNumber(-0.15, 0.15)),
            Enum.Material.Rock,
            Color3.fromRGB(76, 80, 78)
        )
    end

    return folder
end

return CoastBuilder
