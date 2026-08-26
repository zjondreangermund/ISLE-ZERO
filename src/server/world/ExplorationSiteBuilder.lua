local CollectionService = game:GetService("CollectionService")

local ExplorationSiteBuilder = {}

local function part(parent, name, size, cframe, material, color, transparency)
    local object = Instance.new("Part")
    object.Name = name
    object.Anchored = true
    object.CanTouch = false
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

local function markSite(model, id, site)
    model:SetAttribute("DiscoveryId", id)
    model:SetAttribute("DiscoveryName", site.DiscoveryName or id)
    model:SetAttribute("SiteKind", site.Kind or "Unknown")
    model:SetAttribute("GeneratedPlaceholder", true)
    CollectionService:AddTag(model, "ExplorationSite")
end

local function addDiscoveryMarker(model, id, name, position)
    local marker = part(
        model,
        "DiscoveryMarker",
        Vector3.new(8, 8, 8),
        CFrame.new(position + Vector3.new(0, 4, 0)),
        Enum.Material.SmoothPlastic,
        Color3.fromRGB(255, 255, 255),
        1
    )
    marker.CanCollide = false
    marker.CanQuery = false
    marker:SetAttribute("DiscoveryId", id)
    marker:SetAttribute("DiscoveryName", name)
end

local function createCrate(parent, position, yaw)
    local crate = part(
        parent,
        "SupplyCrate",
        Vector3.new(6, 5, 6),
        CFrame.new(position) * CFrame.Angles(0, yaw, 0),
        Enum.Material.WoodPlanks,
        Color3.fromRGB(96, 72, 45)
    )
    crate.CanCollide = true
    return crate
end

local function createBarrel(parent, position, yaw)
    local barrel = part(
        parent,
        "OldBarrel",
        Vector3.new(5.4, 4.3, 4.3),
        CFrame.new(position) * CFrame.Angles(0, yaw, math.rad(90)),
        Enum.Material.CorrodedMetal,
        Color3.fromRGB(78, 79, 70)
    )
    barrel.Shape = Enum.PartType.Cylinder
    barrel.CanCollide = true
    return barrel
end

local function buildCamp(model, center)
    local wood = Color3.fromRGB(83, 61, 39)
    local cloth = Color3.fromRGB(72, 86, 66)

    for _, x in ipairs({-7, 7}) do
        part(model, "TentPole", Vector3.new(1, 8, 1), CFrame.new(center + Vector3.new(x, 4, 0)), Enum.Material.Wood, wood)
    end
    part(
        model,
        "TentCanvasA",
        Vector3.new(16, 0.5, 10),
        CFrame.new(center + Vector3.new(0, 5.2, -3.2)) * CFrame.Angles(math.rad(-28), 0, 0),
        Enum.Material.Fabric,
        cloth
    ).CanCollide = false
    part(
        model,
        "TentCanvasB",
        Vector3.new(16, 0.5, 10),
        CFrame.new(center + Vector3.new(0, 5.2, 3.2)) * CFrame.Angles(math.rad(28), 0, 0),
        Enum.Material.Fabric,
        cloth
    ).CanCollide = false

    createCrate(model, center + Vector3.new(13, 2.5, 5), 0.25)
    createBarrel(model, center + Vector3.new(15, 2.2, -4), -0.2)

    for index = 1, 9 do
        local angle = index / 9 * math.pi * 2
        part(
            model,
            "FireRingStone",
            Vector3.new(2.2, 1.2, 1.8),
            CFrame.new(center + Vector3.new(25 + math.cos(angle) * 4.5, 0.7, math.sin(angle) * 4.5)) * CFrame.Angles(0, -angle, 0),
            Enum.Material.Rock,
            Color3.fromRGB(87, 86, 79)
        ).CanCollide = false
    end

    local log = part(
        model,
        "FallenCampLog",
        Vector3.new(17, 2.2, 2.2),
        CFrame.new(center + Vector3.new(22, 1.3, 10)) * CFrame.Angles(0, -0.42, 0.07),
        Enum.Material.Wood,
        Color3.fromRGB(77, 55, 35)
    )
    log.CanCollide = true
end

local function buildShrine(model, center)
    local stone = Color3.fromRGB(104, 103, 93)
    local moss = Color3.fromRGB(62, 92, 50)

    part(model, "ShrineBase", Vector3.new(18, 2.5, 13), CFrame.new(center + Vector3.new(0, 1.3, 0)), Enum.Material.Limestone, stone)
    part(model, "ShrineAltar", Vector3.new(10, 5, 6), CFrame.new(center + Vector3.new(0, 4.5, -1)), Enum.Material.Limestone, stone)

    for _, x in ipairs({-9, 9}) do
        part(model, "ShrinePillar", Vector3.new(3.5, 13, 3.5), CFrame.new(center + Vector3.new(x, 6.5, 2)), Enum.Material.Limestone, stone)
    end

    for index = 1, 8 do
        local angle = index / 8 * math.pi * 2
        local radius = 15
        local marker = part(
            model,
            "ShrineStone",
            Vector3.new(3.2, 4 + index % 3, 3.2),
            CFrame.new(center + Vector3.new(math.cos(angle) * radius, 2, math.sin(angle) * radius)) * CFrame.Angles(0.1, angle, 0.07),
            Enum.Material.Rock,
            stone
        )
        marker.CanCollide = false
    end

    for index = 1, 5 do
        local patch = part(
            model,
            "ShrineMoss",
            Vector3.new(3 + index, 0.3, 2.5 + (index % 2) * 2),
            CFrame.new(center + Vector3.new(-7 + index * 3, 2.7 + (index % 2) * 2.5, -3 + (index % 3))) * CFrame.Angles(0, index * 0.6, 0),
            Enum.Material.Grass,
            moss
        )
        patch.CanCollide = false
        patch.CanQuery = false
    end
end

local function buildExpedition(model, center)
    createCrate(model, center + Vector3.new(-7, 2.5, 1), -0.24)

    local pack = part(
        model,
        "ExpeditionPack",
        Vector3.new(4.5, 5.5, 2.8),
        CFrame.new(center + Vector3.new(2, 2.8, -3)) * CFrame.Angles(0.1, 0.55, -0.12),
        Enum.Material.Fabric,
        Color3.fromRGB(74, 83, 63)
    )
    pack.CanCollide = false

    for index = 1, 6 do
        local bone = part(
            model,
            "ExpeditionBone",
            Vector3.new(0.6, 0.6, 3 + index * 0.25),
            CFrame.new(center + Vector3.new(4 + index * 0.8, 0.6, 3 + (index % 2))) * CFrame.Angles(index * 0.15, index * 0.7, index * 0.11),
            Enum.Material.SmoothPlastic,
            Color3.fromRGB(190, 182, 159)
        )
        bone.CanCollide = false
        bone.CanQuery = false
    end

    local journal = part(
        model,
        "FieldJournal",
        Vector3.new(2.2, 0.35, 2.8),
        CFrame.new(center + Vector3.new(-1, 0.7, 5)) * CFrame.Angles(0, -0.4, 0.04),
        Enum.Material.Leather,
        Color3.fromRGB(89, 61, 39)
    )
    journal.CanCollide = false
    journal:SetAttribute("InteractableFuture", "ExpeditionJournal")
end

local function buildCache(model, center)
    createCrate(model, center + Vector3.new(-5, 2.5, 0), 0.1)
    createCrate(model, center + Vector3.new(2, 2.5, 3), -0.25)
    createCrate(model, center + Vector3.new(6, 2.5, -4), 0.45)
    createBarrel(model, center + Vector3.new(-7, 2.2, -6), 0.3)

    local tarp = part(
        model,
        "WeatheredTarp",
        Vector3.new(18, 0.3, 13),
        CFrame.new(center + Vector3.new(0, 6.8, 0)) * CFrame.Angles(0.08, -0.12, 0.04),
        Enum.Material.Fabric,
        Color3.fromRGB(72, 83, 69),
        0.08
    )
    tarp.CanCollide = false
    tarp.CanQuery = false
end

local function buildDock(model, center, seaLevel)
    local dockY = math.max(seaLevel + 2.2, center.Y - 1.8)
    local wood = Color3.fromRGB(93, 67, 42)

    for index = 0, 8 do
        local z = center.Z + index * 7
        local plank = part(
            model,
            "DockPlank",
            Vector3.new(18, 1.1, 6.4),
            CFrame.new(center.X, dockY, z) * CFrame.Angles(0, math.rad((index % 3 - 1) * 1.8), 0),
            Enum.Material.WoodPlanks,
            wood
        )
        plank.CanCollide = true

        if index % 2 == 0 then
            for _, x in ipairs({-7.2, 7.2}) do
                part(
                    model,
                    "DockPost",
                    Vector3.new(1.4, 9, 1.4),
                    CFrame.new(center.X + x, dockY - 3.8, z),
                    Enum.Material.Wood,
                    Color3.fromRGB(74, 53, 34)
                )
            end
        end
    end

    local broken = part(
        model,
        "BrokenJettyBeam",
        Vector3.new(20, 1.2, 2),
        CFrame.new(center.X + 10, dockY + 0.7, center.Z + 58) * CFrame.Angles(0, 0.62, -0.08),
        Enum.Material.Wood,
        Color3.fromRGB(72, 51, 33)
    )
    broken.CanCollide = false
end

local function buildOverlook(model, center)
    local wood = Color3.fromRGB(86, 63, 40)
    local deck = part(model, "OverlookDeck", Vector3.new(24, 1.2, 18), CFrame.new(center + Vector3.new(0, 0.8, 0)), Enum.Material.WoodPlanks, wood)
    deck.CanCollide = true

    for _, offset in ipairs({Vector3.new(-11, 5, -8), Vector3.new(11, 5, -8), Vector3.new(-11, 5, 8), Vector3.new(11, 5, 8)}) do
        part(model, "RailPost", Vector3.new(1, 9, 1), CFrame.new(center + offset), Enum.Material.Wood, wood)
    end
    part(model, "FrontRail", Vector3.new(23, 1, 1), CFrame.new(center + Vector3.new(0, 8, -8)), Enum.Material.Wood, wood)
    part(model, "SideRail", Vector3.new(1, 1, 17), CFrame.new(center + Vector3.new(-11, 8, 0)), Enum.Material.Wood, wood)
    part(model, "SideRail", Vector3.new(1, 1, 17), CFrame.new(center + Vector3.new(11, 8, 0)), Enum.Material.Wood, wood)

    local scope = part(
        model,
        "OldSurveyScope",
        Vector3.new(7, 1.2, 1.2),
        CFrame.new(center + Vector3.new(0, 6.8, -2)) * CFrame.Angles(0, -0.35, 0),
        Enum.Material.Metal,
        Color3.fromRGB(72, 76, 72)
    )
    scope.CanCollide = false
    for _, offset in ipairs({Vector3.new(-1.5, 3.4, -1), Vector3.new(1.5, 3.4, -1), Vector3.new(0, 3.4, 1.5)}) do
        part(model, "ScopeTripod", Vector3.new(0.6, 6, 0.6), CFrame.new(center + offset), Enum.Material.Metal, Color3.fromRGB(65, 68, 65)).CanCollide = false
    end
end

local function buildTidePools(model, center)
    local terrain = workspace.Terrain
    local pools = {
        {Vector3.new(-15, 0, -5), 9},
        {Vector3.new(4, 0, 8), 12},
        {Vector3.new(18, 0, -7), 7},
    }

    for index, entry in ipairs(pools) do
        local offset, radius = entry[1], entry[2]
        local p = center + offset
        terrain:FillBall(Vector3.new(p.X, center.Y + 1, p.Z), radius, Enum.Material.Air)
        terrain:FillCylinder(CFrame.new(p.X, center.Y - 2, p.Z), 4, radius * 0.84, Enum.Material.Water)
        local rim = part(
            model,
            "TidePoolRock",
            Vector3.new(radius * 0.8, 2 + index, radius * 0.45),
            CFrame.new(p + Vector3.new(radius * 0.62, 0.6, 0)) * CFrame.Angles(0.2, index * 0.8, 0.12),
            Enum.Material.Rock,
            Color3.fromRGB(79, 83, 78)
        )
        rim.CanCollide = false
    end
end

local function buildOne(config, folder, id, site, heightAt)
    local y = heightAt(config, site.Position.X, site.Position.Z)
    local center = Vector3.new(site.Position.X, y, site.Position.Z)
    local model = Instance.new("Model")
    model.Name = id
    model.Parent = folder
    markSite(model, id, site)

    if site.Kind == "Camp" then
        buildCamp(model, center)
    elseif site.Kind == "Shrine" then
        buildShrine(model, center)
    elseif site.Kind == "Expedition" then
        buildExpedition(model, center)
    elseif site.Kind == "Cache" then
        buildCache(model, center)
    elseif site.Kind == "Dock" then
        buildDock(model, center, config.SeaLevel)
    elseif site.Kind == "Overlook" then
        buildOverlook(model, center)
    elseif site.Kind == "TidePools" then
        buildTidePools(model, center)
    end

    addDiscoveryMarker(model, id, site.DiscoveryName or id, center)
    return model
end

function ExplorationSiteBuilder.Build(config, worldRoot, heightAt)
    local folder = Instance.new("Folder")
    folder.Name = "ExplorationSites"
    folder.Parent = worldRoot

    local count = 0
    local sites = (config.Exploration and config.Exploration.Sites) or {}
    for id, site in pairs(sites) do
        buildOne(config, folder, id, site, heightAt)
        count += 1
    end

    folder:SetAttribute("SiteCount", count)
    print(string.format("[ISLE//ZERO][EXPLORATION] Built %d surface discovery sites", count))
    return folder
end

return ExplorationSiteBuilder
