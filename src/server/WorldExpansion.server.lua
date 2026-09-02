local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local TREE_HOUSE_POSITION = Vector3.new(-520, 0, 410)
local TREE_HOUSE_HEIGHT = 31
local TREE_HOUSE_SAFE_RADIUS = 34
local SNAKE_SPAWNS = {
    {Id = "snake_jungle_a", Position = Vector3.new(-560, 0, 350)},
    {Id = "snake_jungle_b", Position = Vector3.new(-675, 0, 185)},
    {Id = "snake_shrine", Position = Vector3.new(-315, 0, 120)},
    {Id = "snake_mangrove", Position = Vector3.new(-770, 0, 260)},
    {Id = "snake_treehouse", Position = Vector3.new(-485, 0, 385)},
}

local builtForRoot = setmetatable({}, {__mode = "k"})

local function toast(player, message)
    local remotes = ReplicatedStorage:FindFirstChild("ISLEZeroSurvival")
    local remote = remotes and remotes:FindFirstChild("Toast")
    if remote and remote:IsA("RemoteEvent") then
        remote:FireClient(player, message)
    end
end

local function makePart(parent, name, size, cframe, material, color, transparency)
    local object = Instance.new("Part")
    object.Name = name
    object.Size = size
    object.CFrame = cframe
    object.Material = material
    object.Color = color
    object.Transparency = transparency or 0
    object.Anchored = true
    object.CanTouch = false
    object.TopSurface = Enum.SurfaceType.Smooth
    object.BottomSurface = Enum.SurfaceType.Smooth
    object.Parent = parent
    object:SetAttribute("GeneratedPlaceholder", true)
    return object
end

local function terrainGround(position, root)
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = root and {root} or {}
    params.IgnoreWater = true

    local result = workspace:Raycast(
        Vector3.new(position.X, 650, position.Z),
        Vector3.new(0, -900, 0),
        params
    )
    if result then
        return result.Position
    end
    return position
end

local function createTreeHouse(root)
    local existing = root:FindFirstChild("JungleTreeHouse", true)
    if existing then
        return existing
    end

    local ground = terrainGround(TREE_HOUSE_POSITION, root)
    local platformY = ground.Y + TREE_HOUSE_HEIGHT
    local center = Vector3.new(ground.X, platformY, ground.Z)

    local model = Instance.new("Model")
    model.Name = "JungleTreeHouse"
    model:SetAttribute("GeneratedPlaceholder", true)
    model:SetAttribute("AssetKey", "TreeHouse")
    model:SetAttribute("DiscoveryId", "JungleTreeHouse")
    model:SetAttribute("DiscoveryName", "Jungle Canopy Tree House")
    model:SetAttribute("SiteKind", "SafeShelter")
    model.Parent = root
    CollectionService:AddTag(model, "ExplorationSite")

    local trunkColor = Color3.fromRGB(88, 61, 39)
    local plankColor = Color3.fromRGB(112, 82, 49)
    local ropeColor = Color3.fromRGB(143, 111, 67)

    local trunk = makePart(
        model,
        "TreeHouseTrunk",
        Vector3.new(8, TREE_HOUSE_HEIGHT + 18, 8),
        CFrame.new(ground + Vector3.new(0, (TREE_HOUSE_HEIGHT + 18) / 2 - 1, 0)) * CFrame.Angles(math.rad(2), 0, math.rad(-3)),
        Enum.Material.Wood,
        trunkColor
    )
    trunk.CanCollide = true

    local platform = makePart(
        model,
        "TreeHousePlatform",
        Vector3.new(28, 1.4, 24),
        CFrame.new(center),
        Enum.Material.WoodPlanks,
        plankColor
    )
    platform.CanCollide = true

    for _, offset in ipairs({
        Vector3.new(-11, 5, -8),
        Vector3.new(11, 5, -8),
        Vector3.new(-11, 5, 8),
        Vector3.new(11, 5, 8),
    }) do
        makePart(model, "CabinPost", Vector3.new(1, 10, 1), CFrame.new(center + offset), Enum.Material.Wood, trunkColor)
    end

    makePart(model, "CabinFloor", Vector3.new(18, 1, 15), CFrame.new(center + Vector3.new(0, 1.1, 0)), Enum.Material.WoodPlanks, plankColor).CanCollide = true
    makePart(model, "CabinBack", Vector3.new(18, 8, 1), CFrame.new(center + Vector3.new(0, 5, 7)), Enum.Material.WoodPlanks, plankColor)
    makePart(model, "CabinLeft", Vector3.new(1, 8, 14), CFrame.new(center + Vector3.new(-8.5, 5, 0)), Enum.Material.WoodPlanks, plankColor)
    makePart(model, "CabinRight", Vector3.new(1, 8, 14), CFrame.new(center + Vector3.new(8.5, 5, 0)), Enum.Material.WoodPlanks, plankColor)
    makePart(
        model,
        "CabinRoofA",
        Vector3.new(20, 0.7, 11),
        CFrame.new(center + Vector3.new(0, 10.2, -3.5)) * CFrame.Angles(math.rad(-25), 0, 0),
        Enum.Material.WoodPlanks,
        Color3.fromRGB(78, 58, 39)
    ).CanCollide = false
    makePart(
        model,
        "CabinRoofB",
        Vector3.new(20, 0.7, 11),
        CFrame.new(center + Vector3.new(0, 10.2, 3.5)) * CFrame.Angles(math.rad(25), 0, 0),
        Enum.Material.WoodPlanks,
        Color3.fromRGB(78, 58, 39)
    ).CanCollide = false

    for index = 0, 11 do
        local y = ground.Y + 3 + index * 2.25
        local rung = makePart(
            model,
            "RopeLadderRung",
            Vector3.new(5.5, 0.45, 0.7),
            CFrame.new(ground.X - 13, y, ground.Z + 7),
            Enum.Material.Wood,
            plankColor
        )
        rung.CanCollide = false
    end
    for _, x in ipairs({-15.2, -10.8}) do
        local rope = makePart(
            model,
            "RopeLadderSide",
            Vector3.new(0.35, TREE_HOUSE_HEIGHT - 2, 0.35),
            CFrame.new(x + ground.X + 13, ground.Y + TREE_HOUSE_HEIGHT / 2, ground.Z + 7),
            Enum.Material.Fabric,
            ropeColor
        )
        rope.CanCollide = false
    end

    local baseClimb = makePart(model, "TreeHouseClimbPoint", Vector3.new(6, 4, 6), CFrame.new(ground + Vector3.new(-13, 2, 7)), Enum.Material.SmoothPlastic, Color3.new(1, 1, 1), 1)
    baseClimb.CanCollide = false
    baseClimb.CanQuery = false
    local climbPrompt = Instance.new("ProximityPrompt")
    climbPrompt.ActionText = "Climb"
    climbPrompt.ObjectText = "Jungle Tree House"
    climbPrompt.HoldDuration = 0.15
    climbPrompt.MaxActivationDistance = 10
    climbPrompt.RequiresLineOfSight = false
    climbPrompt.Parent = baseClimb

    local topClimb = makePart(model, "TreeHouseDescendPoint", Vector3.new(5, 3, 5), CFrame.new(center + Vector3.new(-12, 2, 7)), Enum.Material.SmoothPlastic, Color3.new(1, 1, 1), 1)
    topClimb.CanCollide = false
    topClimb.CanQuery = false
    local descendPrompt = Instance.new("ProximityPrompt")
    descendPrompt.ActionText = "Climb down"
    descendPrompt.ObjectText = "Rope ladder"
    descendPrompt.HoldDuration = 0.1
    descendPrompt.MaxActivationDistance = 9
    descendPrompt.RequiresLineOfSight = false
    descendPrompt.Parent = topClimb

    local restPoint = makePart(model, "TreeHouseRestPoint", Vector3.new(5, 2, 5), CFrame.new(center + Vector3.new(3, 2, 2)), Enum.Material.SmoothPlastic, Color3.new(1, 1, 1), 1)
    restPoint.CanCollide = false
    restPoint.CanQuery = false
    restPoint:SetAttribute("CheckpointCFrame", center + Vector3.new(0, 4, 0))
    local restPrompt = Instance.new("ProximityPrompt")
    restPrompt.ActionText = "Rest / checkpoint"
    restPrompt.ObjectText = "Safe canopy shelter"
    restPrompt.HoldDuration = 0.35
    restPrompt.MaxActivationDistance = 10
    restPrompt.RequiresLineOfSight = false
    restPrompt.Parent = restPoint

    local safeZone = makePart(model, "TreeHouseSafeZone", Vector3.new(TREE_HOUSE_SAFE_RADIUS * 2, 18, TREE_HOUSE_SAFE_RADIUS * 2), CFrame.new(center + Vector3.new(0, 3, 0)), Enum.Material.SmoothPlastic, Color3.new(1, 1, 1), 1)
    safeZone.CanCollide = false
    safeZone.CanQuery = false
    safeZone:SetAttribute("SafeRadius", TREE_HOUSE_SAFE_RADIUS)
    CollectionService:AddTag(safeZone, "SafeCampZone")

    local lantern = makePart(model, "TreeHouseLantern", Vector3.new(1.2, 2, 1.2), CFrame.new(center + Vector3.new(-6, 7, -5)), Enum.Material.Neon, Color3.fromRGB(245, 172, 78))
    lantern.CanCollide = false
    local light = Instance.new("PointLight")
    light.Brightness = 1.8
    light.Range = 24
    light.Color = Color3.fromRGB(255, 183, 100)
    light.Shadows = true
    light.Parent = lantern

    climbPrompt.Triggered:Connect(function(player)
        local character = player.Character
        if character then
            character:PivotTo(CFrame.new(center + Vector3.new(-10, 4, 4)))
        end
    end)

    descendPrompt.Triggered:Connect(function(player)
        local character = player.Character
        if character then
            character:PivotTo(CFrame.new(ground + Vector3.new(-10, 4, 7)))
        end
    end)

    restPrompt.Triggered:Connect(function(player)
        local character = player.Character
        local humanoid = character and character:FindFirstChildOfClass("Humanoid")
        if humanoid then
            humanoid.Health = humanoid.MaxHealth
        end
        player:SetAttribute("SafeCamp", "JungleTreeHouse")
        player:SetAttribute("ISLEZeroShelterCheckpoint", center + Vector3.new(0, 4, 0))
        toast(player, "Jungle Tree House secured as your safe checkpoint. Wildlife will not enter the shelter.")
    end)

    return model
end

local function createSnakeMarkers(root)
    local folder = root:FindFirstChild("ExpansionEncounters")
    if not folder then
        folder = Instance.new("Folder")
        folder.Name = "ExpansionEncounters"
        folder.Parent = root
    end

    local created = 0
    for _, entry in ipairs(SNAKE_SPAWNS) do
        if not folder:FindFirstChild(entry.Id) then
            local ground = terrainGround(entry.Position, root)
            local marker = Instance.new("Part")
            marker.Name = entry.Id
            marker.Size = Vector3.new(2, 1, 2)
            marker.CFrame = CFrame.new(ground + Vector3.new(0, 0.6, 0))
            marker.Transparency = 1
            marker.Anchored = true
            marker.CanCollide = false
            marker.CanTouch = false
            marker.CanQuery = false
            marker:SetAttribute("EncounterId", entry.Id)
            marker:SetAttribute("GuardianType", "JungleSnake")
            marker.Parent = folder
            CollectionService:AddTag(marker, "WorldEnemySpawn")
            created += 1
        end
    end
    return created
end

local function buildExpansion()
    local root = workspace:FindFirstChild("ISLE_ZERO_WORLD")
    if not root or root:GetAttribute("BuildComplete") ~= true or builtForRoot[root] then
        return
    end
    builtForRoot[root] = true

    createTreeHouse(root)
    local snakes = createSnakeMarkers(root)
    print(string.format("[ISLE//ZERO][EXPANSION] Jungle Tree House active; %d snake encounters added", snakes))
end

local function bindPlayer(player)
    player:GetAttributeChangedSignal("SafeCamp"):Connect(function()
        if player:GetAttribute("SafeCamp") ~= "JungleTreeHouse" then
            player:SetAttribute("ISLEZeroShelterCheckpoint", nil)
        end
    end)

    player.CharacterAdded:Connect(function(character)
        task.wait(0.7)
        local checkpoint = player:GetAttribute("ISLEZeroShelterCheckpoint")
        if typeof(checkpoint) == "Vector3" and player:GetAttribute("SafeCamp") == "JungleTreeHouse" and character.Parent then
            character:PivotTo(CFrame.new(checkpoint))
        end
    end)
end

Players.PlayerAdded:Connect(bindPlayer)
for _, player in ipairs(Players:GetPlayers()) do
    bindPlayer(player)
end

workspace:GetAttributeChangedSignal("ISLEZeroGenerated"):Connect(function()
    if workspace:GetAttribute("ISLEZeroGenerated") == true then
        task.delay(0.2, buildExpansion)
    end
end)

if workspace:GetAttribute("ISLEZeroGenerated") == true then
    task.delay(0.2, buildExpansion)
end
