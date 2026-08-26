local CollectionService = game:GetService("CollectionService")

local RegionBuilder = {}

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

local function addBoardText(board, text, face, color)
    local gui = Instance.new("SurfaceGui")
    gui.Face = face or Enum.NormalId.Front
    gui.AlwaysOnTop = false
    gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
    gui.PixelsPerStud = 35
    gui.Parent = board

    local label = Instance.new("TextLabel")
    label.BackgroundTransparency = 1
    label.Size = UDim2.fromScale(1, 1)
    label.Text = text
    label.TextWrapped = true
    label.TextScaled = true
    label.Font = Enum.Font.GothamBold
    label.TextColor3 = color or Color3.fromRGB(226, 215, 183)
    label.TextStrokeTransparency = 0.5
    label.Parent = gui
end

local function groundY(config, heightAt, position)
    return heightAt(config, position.X, position.Z)
end

local function createExpeditionBoard(config, folder, heightAt)
    local position = Vector3.new(185, 0, 745)
    local y = groundY(config, heightAt, position)
    local model = Instance.new("Model")
    model.Name = "ExpeditionProgressBoard"
    model.Parent = folder

    local base = CFrame.new(position.X, y, position.Z) * CFrame.Angles(0, math.rad(-20), 0)
    local wood = Color3.fromRGB(79, 56, 35)
    part(model, "PostA", Vector3.new(1.5, 12, 1.5), base * CFrame.new(-8, 6, 0), Enum.Material.Wood, wood)
    part(model, "PostB", Vector3.new(1.5, 12, 1.5), base * CFrame.new(8, 6, 0), Enum.Material.Wood, wood)
    local board = part(model, "MapBoard", Vector3.new(22, 12, 1), base * CFrame.new(0, 11, 0), Enum.Material.WoodPlanks, Color3.fromRGB(91, 66, 42))
    addBoardText(
        board,
        "ISLE//ZERO EXPEDITION ROUTE\n\n1  SOUTHERN CLIFFS\n   defeat guardian -> BOAT KIT\n\n2  JUNGLE DEPTHS\n   defeat guardian -> CLIMBING KIT\n\n3  EASTERN FOREST\n   defeat guardian -> WINTER GEAR\n\n4  FROSTPEAK\n   WINTER GEAR REQUIRED\n   LEGENDARY REWARD",
        Enum.NormalId.Front
    )
end

local function createGate(config, folder, heightAt, id, position, yaw, title, requirement)
    local y = groundY(config, heightAt, position)
    local model = Instance.new("Model")
    model.Name = id .. "Gate"
    model.Parent = folder
    model:SetAttribute("RegionId", id)
    model:SetAttribute("RequirementItem", requirement)

    local base = CFrame.new(position.X, y, position.Z) * CFrame.Angles(0, math.rad(yaw), 0)
    local wood = Color3.fromRGB(74, 52, 34)
    part(model, "GatePostA", Vector3.new(2, 16, 2), base * CFrame.new(-12, 8, 0), Enum.Material.Wood, wood)
    part(model, "GatePostB", Vector3.new(2, 16, 2), base * CFrame.new(12, 8, 0), Enum.Material.Wood, wood)
    local beam = part(model, "GateBeam", Vector3.new(28, 2, 2), base * CFrame.new(0, 15, 0), Enum.Material.Wood, wood)
    beam.CanCollide = false
    local board = part(model, "RequirementBoard", Vector3.new(20, 6, 0.8), base * CFrame.new(0, 11, -0.3), Enum.Material.WoodPlanks, Color3.fromRGB(92, 66, 40))
    addBoardText(board, title .. "\n" .. requirement .. " REQUIRED", Enum.NormalId.Front, Color3.fromRGB(235, 219, 183))

    local marker = part(model, "GateMarker", Vector3.new(34, 18, 12), base * CFrame.new(0, 8, 0), Enum.Material.SmoothPlastic, Color3.new(1, 1, 1), 1)
    marker.CanCollide = false
    marker.CanQuery = false
    marker:SetAttribute("RegionId", id)
    marker:SetAttribute("RequirementItem", requirement)
    CollectionService:AddTag(marker, "ProgressionGate")
end

local function createRaftDock(config, folder, heightAt)
    local position = Vector3.new(-955, 0, 455)
    local y = math.max(4, groundY(config, heightAt, position))
    local model = Instance.new("Model")
    model.Name = "DesertedIslandRaftDock"
    model.Parent = folder

    local wood = Color3.fromRGB(89, 65, 40)
    for index = 0, 5 do
        part(model, "DockPlank", Vector3.new(7, 0.7, 6), CFrame.new(position.X - index * 5.8, y + 0.5, position.Z), Enum.Material.WoodPlanks, wood)
    end

    local raft = part(model, "OldRaft", Vector3.new(15, 1.2, 9), CFrame.new(position.X - 38, 4.5, position.Z), Enum.Material.WoodPlanks, Color3.fromRGB(101, 75, 45))
    raft:SetAttribute("TravelId", "DesertedIsland")
    raft:SetAttribute("RequirementItem", "BoatRepairKit")
    CollectionService:AddTag(raft, "ProgressionTravel")

    local prompt = Instance.new("ProximityPrompt")
    prompt.Name = "TravelPrompt"
    prompt.ActionText = "Repair raft / sail"
    prompt.ObjectText = "Deserted Island - Boat Repair Kit required"
    prompt.HoldDuration = 0.8
    prompt.MaxActivationDistance = 12
    prompt.RequiresLineOfSight = false
    prompt.Parent = raft

    local sail = part(model, "BrokenSail", Vector3.new(0.4, 8, 9), CFrame.new(position.X - 39, 9, position.Z) * CFrame.Angles(0, 0, math.rad(-10)), Enum.Material.Fabric, Color3.fromRGB(151, 143, 116))
    sail.CanCollide = false
end

local function createReturnPoint(config, folder)
    local center = config.Locations.DesertedIsland
    if not center then
        return
    end

    local marker = part(folder, "DesertedIslandReturnRaft", Vector3.new(14, 1.2, 9), CFrame.new(center.X + 108, 8, center.Z + 20), Enum.Material.WoodPlanks, Color3.fromRGB(101, 75, 45))
    marker:SetAttribute("TravelId", "ReturnMainIsland")
    CollectionService:AddTag(marker, "ProgressionTravel")

    local prompt = Instance.new("ProximityPrompt")
    prompt.ActionText = "Sail back"
    prompt.ObjectText = "Return to main island"
    prompt.HoldDuration = 0.55
    prompt.MaxActivationDistance = 12
    prompt.RequiresLineOfSight = false
    prompt.Parent = marker
end

local function createRewardCache(folder, cave, caveId, reward)
    local x = cave:GetAttribute("MainChamberX")
    local y = cave:GetAttribute("MainChamberY")
    local z = cave:GetAttribute("MainChamberZ")
    if not x or not y or not z then
        return
    end

    local model = Instance.new("Model")
    model.Name = caveId .. "GuardianReward"
    model.Parent = folder

    local position = Vector3.new(x - 12, y - 12, z + 12)
    local rarity = reward.Rarity or "Rare"
    local rarityColors = {
        Uncommon = Color3.fromRGB(93, 153, 86),
        Rare = Color3.fromRGB(74, 119, 181),
        Epic = Color3.fromRGB(132, 77, 172),
        Legendary = Color3.fromRGB(215, 166, 56),
    }
    local accent = rarityColors[rarity] or rarityColors.Rare

    local base = part(model, "RewardChest", Vector3.new(8, 4.5, 6), CFrame.new(position), Enum.Material.WoodPlanks, Color3.fromRGB(76, 52, 33))
    base:SetAttribute("CaveId", caveId)
    base:SetAttribute("RewardItem", reward.ItemId)
    base:SetAttribute("RewardName", reward.DisplayName or reward.ItemId)
    base:SetAttribute("Rarity", rarity)
    CollectionService:AddTag(base, "GuardianRewardCache")

    part(model, "RewardLid", Vector3.new(8.2, 1.5, 6.2), CFrame.new(position + Vector3.new(0, 3, 0)), Enum.Material.Metal, accent)
    local glow = part(model, "RewardGlow", Vector3.new(5, 0.35, 3), CFrame.new(position + Vector3.new(0, 4.1, 0)), Enum.Material.Neon, accent, 0.15)
    glow.CanCollide = false

    local light = Instance.new("PointLight")
    light.Brightness = rarity == "Legendary" and 2.5 or 1.4
    light.Range = rarity == "Legendary" and 22 or 15
    light.Color = accent
    light.Parent = glow

    local prompt = Instance.new("ProximityPrompt")
    prompt.Name = "GuardianRewardPrompt"
    prompt.ActionText = "Claim " .. rarity .. " reward"
    prompt.ObjectText = "Defeat the cave guardian first"
    prompt.HoldDuration = 0.65
    prompt.MaxActivationDistance = 11
    prompt.RequiresLineOfSight = false
    prompt.Enabled = false
    prompt.Parent = base
end

local function createDesertedIslandPalms(config, folder)
    local center = config.Locations.DesertedIsland
    if not center then
        return
    end

    local palms = Instance.new("Folder")
    palms.Name = "DesertedIslandPalms"
    palms.Parent = folder
    local positions = {
        Vector3.new(-45, 0, -45), Vector3.new(40, 0, -48), Vector3.new(-65, 0, 25),
        Vector3.new(52, 0, 34), Vector3.new(-12, 0, 55), Vector3.new(72, 0, -5),
        Vector3.new(-80, 0, -8), Vector3.new(15, 0, -70),
    }
    for index, offset in ipairs(positions) do
        local base = Vector3.new(center.X + offset.X, 22 + (index % 3) * 2, center.Z + offset.Z)
        local trunk = part(palms, "IslandPalmTrunk", Vector3.new(2.5, 22 + (index % 4) * 2, 2.5), CFrame.new(base), Enum.Material.Wood, Color3.fromRGB(101, 70, 44))
        trunk.CFrame *= CFrame.Angles(math.rad((index % 2) * 4), 0, math.rad((index % 3) - 1) * 0.06)
        local top = trunk.Position + Vector3.new(0, trunk.Size.Y / 2, 0)
        for leaf = 1, 6 do
            local angle = leaf / 6 * math.pi * 2
            local frond = part(palms, "IslandPalmLeaf", Vector3.new(1.2, 0.45, 13), CFrame.new(top) * CFrame.Angles(math.rad(-18), angle, 0) * CFrame.new(0, 0, -5), Enum.Material.Grass, Color3.fromRGB(53, 112, 60))
            frond.CanCollide = false
        end
    end
end

function RegionBuilder.Build(config, root, heightAt, gameplayConfig)
    local folder = Instance.new("Folder")
    folder.Name = "RegionsAndProgression"
    folder.Parent = root

    createExpeditionBoard(config, folder, heightAt)
    createGate(config, folder, heightAt, "StonefallUpper", Vector3.new(120, 0, -430), 10, "STONEFALL UPPER RIDGE", "CLIMBING KIT")
    createGate(config, folder, heightAt, "Frostpeak", Vector3.new(-115, 0, -485), 0, "FROSTPEAK MOUNTAINS", "WINTER GEAR")
    createRaftDock(config, folder, heightAt)
    createReturnPoint(config, folder)
    createDesertedIslandPalms(config, folder)

    local caves = root:FindFirstChild("Caves")
    if caves and gameplayConfig and gameplayConfig.CaveRewards then
        for caveId, reward in pairs(gameplayConfig.CaveRewards) do
            local cave = caves:FindFirstChild(caveId)
            if cave then
                createRewardCache(folder, cave, caveId, reward)
            end
        end
    end

    folder:SetAttribute("ProgressionGateCount", 3)
    folder:SetAttribute("RegionCount", config.Regions and 8 or 0)
    print("[ISLE//ZERO][REGIONS] Map regions, gear gates, raft route and guardian rewards built")
    return folder
end

return RegionBuilder
