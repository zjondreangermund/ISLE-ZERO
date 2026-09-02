local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local SAFE_RADIUS = 29
local CLEAR_RADIUS = 18
local watched = setmetatable({}, {__mode = "k"})

local function toast(player, message)
    local remotes = ReplicatedStorage:FindFirstChild("ISLEZeroSurvival")
    local remote = remotes and remotes:FindFirstChild("Toast")
    if remote and remote:IsA("RemoteEvent") then
        remote:FireClient(player, message)
    end
end

local function horizontalDistance(a, b)
    return Vector2.new(a.X - b.X, a.Z - b.Z).Magnitude
end

local function findCave(caveId)
    local root = workspace:FindFirstChild("ISLE_ZERO_WORLD")
    local caves = root and root:FindFirstChild("Caves")
    return caves and caves:FindFirstChild(caveId)
end

local function makePart(parent, name, size, cframe, material, color, transparency)
    local part = Instance.new("Part")
    part.Name = name
    part.Anchored = true
    part.CanCollide = false
    part.CanTouch = false
    part.CanQuery = false
    part.Size = size
    part.CFrame = cframe
    part.Material = material
    part.Color = color
    part.Transparency = transparency or 0
    part.TopSurface = Enum.SurfaceType.Smooth
    part.BottomSurface = Enum.SurfaceType.Smooth
    part.Parent = parent
    return part
end

local function clearTerrainGrass(position)
    local min = position - Vector3.new(CLEAR_RADIUS, 8, CLEAR_RADIUS)
    local max = position + Vector3.new(CLEAR_RADIUS, 6, CLEAR_RADIUS)
    local region = Region3.new(min, max):ExpandToGrid(4)
    local terrain = workspace.Terrain

    pcall(function()
        terrain:ReplaceMaterial(region, 4, Enum.Material.Grass, Enum.Material.Ground)
    end)
    pcall(function()
        terrain:ReplaceMaterial(region, 4, Enum.Material.LeafyGrass, Enum.Material.Ground)
    end)
end

local function vegetationPosition(instance)
    if instance:IsA("BasePart") then
        return instance.Position
    elseif instance:IsA("Model") then
        return instance:GetPivot().Position
    end
    return nil
end

local function clearUnderstory(position)
    for _, vegetation in ipairs(CollectionService:GetTagged("WorldVegetation")) do
        if vegetation.Parent and vegetation:GetAttribute("VegetationType") == "Understory" then
            local at = vegetationPosition(vegetation)
            if at and horizontalDistance(at, position) <= CLEAR_RADIUS + 3 then
                vegetation:Destroy()
            end
        end
    end
end

local function createSafeZone(parent, position, caveId)
    local existing = parent:FindFirstChild("SafeCampZone")
    if existing and existing:IsA("BasePart") then
        return existing
    end

    local zone = makePart(
        parent,
        "SafeCampZone",
        Vector3.new(SAFE_RADIUS * 2, 12, SAFE_RADIUS * 2),
        CFrame.new(position + Vector3.new(0, 4, 0)),
        Enum.Material.SmoothPlastic,
        Color3.new(1, 1, 1),
        1
    )
    zone:SetAttribute("SafeRadius", SAFE_RADIUS)
    zone:SetAttribute("CaveId", caveId)
    CollectionService:AddTag(zone, "SafeCampZone")
    return zone
end

local function createFoodTool(player)
    local backpack = player:FindFirstChildOfClass("Backpack")
    if not backpack then
        return
    end

    local tool = Instance.new("Tool")
    tool.Name = "Cooked Wild Meat"
    tool.RequiresHandle = true
    tool.CanBeDropped = false
    tool:SetAttribute("ItemId", "CookedWildMeat")
    tool:SetAttribute("FoodItem", true)
    tool:SetAttribute("HungerRestore", 32)

    local handle = Instance.new("Part")
    handle.Name = "Handle"
    handle.Size = Vector3.new(2.4, 0.8, 1.7)
    handle.Color = Color3.fromRGB(116, 70, 48)
    handle.Material = Enum.Material.SmoothPlastic
    handle.CanCollide = false
    handle.CanTouch = false
    handle.Massless = true
    handle.Parent = tool

    tool.Parent = backpack
end

local function addFireWood(parent, firePosition)
    local existing = parent:FindFirstChild("CampFirePolish")
    if existing then
        return existing
    end

    local model = Instance.new("Model")
    model.Name = "CampFirePolish"
    model.Parent = parent

    local woodColor = Color3.fromRGB(86, 55, 31)
    for index, yaw in ipairs({45, -45, 0}) do
        local log = makePart(
            model,
            "FireLog",
            Vector3.new(0.85, 0.85, 5.2),
            CFrame.new(firePosition + Vector3.new(0, -0.45 + (index - 1) * 0.18, 0)) * CFrame.Angles(0, math.rad(yaw), 0),
            Enum.Material.Wood,
            woodColor
        )
        log.CanCollide = false
    end

    for index = 1, 8 do
        local angle = (index / 8) * math.pi * 2
        makePart(
            model,
            "FireRingStone",
            Vector3.new(1.35, 0.75, 1.1),
            CFrame.new(firePosition + Vector3.new(math.cos(angle) * 3.0, -0.55, math.sin(angle) * 3.0)),
            Enum.Material.Rock,
            Color3.fromRGB(82, 82, 77)
        )
    end

    local cookPromptPart = makePart(
        model,
        "CookingSpot",
        Vector3.new(3.2, 0.5, 3.2),
        CFrame.new(firePosition + Vector3.new(0, 0.25, 0)),
        Enum.Material.SmoothPlastic,
        Color3.new(1, 1, 1),
        1
    )
    local prompt = Instance.new("ProximityPrompt")
    prompt.Name = "CookPrompt"
    prompt.ActionText = "Cook wild meat"
    prompt.ObjectText = "Campfire"
    prompt.HoldDuration = 0.55
    prompt.MaxActivationDistance = 9
    prompt.RequiresLineOfSight = false
    prompt.Parent = cookPromptPart

    prompt.Triggered:Connect(function(player)
        local raw = player:GetAttribute("RawMeat") or 0
        if raw <= 0 then
            toast(player, "You need raw meat from wildlife before you can cook here.")
            return
        end
        player:SetAttribute("RawMeat", raw - 1)
        createFoodTool(player)
        toast(player, "Cooked wild meat added to your backpack.")
    end)

    local pileBase = firePosition + Vector3.new(7.2, -0.15, 3.5)
    for index = 1, 7 do
        local row = math.floor((index - 1) / 3)
        local column = (index - 1) % 3
        makePart(
            model,
            "FirewoodPile",
            Vector3.new(0.85, 0.85, 4.5),
            CFrame.new(pileBase + Vector3.new(column * 1.05 - 1.05, row * 0.85, 0)) * CFrame.Angles(0, math.rad(90), 0),
            Enum.Material.Wood,
            Color3.fromRGB(91, 60, 35)
        )
    end

    return model
end

local function decorateCamp(marker)
    if marker:GetAttribute("CampEnvironmentReady") == true then
        return
    end

    local caveId = marker:GetAttribute("CaveId")
    local cave = caveId and findCave(caveId)
    if not cave or cave:GetAttribute("CampBuilt") ~= true then
        return
    end

    marker:SetAttribute("CampEnvironmentReady", true)
    clearTerrainGrass(marker.Position)
    clearUnderstory(marker.Position)

    local decor = Instance.new("Model")
    decor.Name = "CampEnvironment"
    decor.Parent = marker.Parent
    decor:SetAttribute("CaveId", caveId)

    local clearing = makePart(
        decor,
        "ClearedCampGround",
        Vector3.new(27, 0.45, 23),
        CFrame.new(marker.Position - Vector3.new(0, 0.42, 0)),
        Enum.Material.Ground,
        Color3.fromRGB(89, 84, 64),
        0.03
    )
    clearing.CanCollide = false

    createSafeZone(decor, marker.Position, caveId)

    local existingFire = cave:FindFirstChild("Campfire", true)
    local firePosition
    if existingFire and existingFire:IsA("BasePart") then
        firePosition = existingFire.Position
    else
        firePosition = marker.Position + Vector3.new(8.5, 1.2, 0)
        local flame = makePart(
            decor,
            "Campfire",
            Vector3.new(1.2, 1.7, 1.2),
            CFrame.new(firePosition),
            Enum.Material.Neon,
            Color3.fromRGB(238, 132, 62)
        )
        local light = Instance.new("PointLight")
        light.Brightness = 1.8
        light.Range = 22
        light.Color = Color3.fromRGB(255, 176, 98)
        light.Parent = flame
    end
    addFireWood(decor, firePosition)

    print(string.format("[ISLE//ZERO][CAMP] Cleared grass, stocked firewood and secured %s", tostring(caveId)))
end

local function watchMarker(marker)
    if watched[marker] then
        return
    end
    watched[marker] = true

    local caveId = marker:GetAttribute("CaveId")
    local cave = caveId and findCave(caveId)
    if not cave then
        task.delay(1, function()
            watched[marker] = nil
            if marker.Parent then
                watchMarker(marker)
            end
        end)
        return
    end

    cave:GetAttributeChangedSignal("CampBuilt"):Connect(function()
        if cave:GetAttribute("CampBuilt") == true then
            task.defer(decorateCamp, marker)
        end
    end)

    if cave:GetAttribute("CampBuilt") == true then
        task.defer(decorateCamp, marker)
    end
end

local function bindWorld()
    for _, marker in ipairs(CollectionService:GetTagged("CampBuildSpot")) do
        if marker:IsDescendantOf(workspace) then
            watchMarker(marker)
        end
    end
end

CollectionService:GetInstanceAddedSignal("CampBuildSpot"):Connect(function(marker)
    task.defer(watchMarker, marker)
end)

workspace:GetAttributeChangedSignal("ISLEZeroGenerated"):Connect(function()
    if workspace:GetAttribute("ISLEZeroGenerated") == true then
        task.defer(bindWorld)
    end
end)

if workspace:GetAttribute("ISLEZeroGenerated") == true then
    task.defer(bindWorld)
end
