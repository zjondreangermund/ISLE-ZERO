local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local processed = setmetatable({}, {__mode = "k"})

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

local function makePart(parent, name, size, cframe, material, color)
    local part = Instance.new("Part")
    part.Name = name
    part.Size = size
    part.CFrame = cframe
    part.Material = material
    part.Color = color
    part.Anchored = true
    part.CanTouch = false
    part.TopSurface = Enum.SurfaceType.Smooth
    part.BottomSurface = Enum.SurfaceType.Smooth
    part.Parent = parent
    part:SetAttribute("GeneratedPlaceholder", true)
    return part
end

local function addBoardText(board, text)
    local gui = Instance.new("SurfaceGui")
    gui.Name = "TreeHouseBoardGui"
    gui.Face = Enum.NormalId.Front
    gui.CanvasSize = Vector2.new(700, 360)
    gui.SizingMode = Enum.SurfaceGuiSizingMode.FixedSize
    gui.Parent = board

    local label = Instance.new("TextLabel")
    label.BackgroundTransparency = 1
    label.Size = UDim2.fromScale(1, 1)
    label.Text = text
    label.TextColor3 = Color3.fromRGB(224, 211, 174)
    label.TextStrokeTransparency = 0.55
    label.Font = Enum.Font.GothamBold
    label.TextScaled = true
    label.TextWrapped = true
    label.Parent = gui
end

local function clearVegetation(basePosition)
    local removed = 0
    for _, vegetation in ipairs(CollectionService:GetTagged("WorldVegetation")) do
        if vegetation:IsDescendantOf(workspace) then
            local position
            if vegetation:IsA("Model") then
                position = vegetation:GetPivot().Position
            elseif vegetation:IsA("BasePart") then
                position = vegetation.Position
            end
            if position and horizontalDistance(position, basePosition) < 46 then
                vegetation:Destroy()
                removed += 1
            end
        end
    end
    return removed
end

local function polish(treeHouse)
    if processed[treeHouse] or not treeHouse:IsDescendantOf(workspace) then
        return
    end
    local climbPoint = treeHouse:FindFirstChild("TreeHouseClimbPoint", true)
    if not climbPoint or not climbPoint:IsA("BasePart") then
        return
    end
    processed[treeHouse] = true

    local base = climbPoint.Position - Vector3.new(0, 2, 0)
    local removed = clearVegetation(base)

    local folder = Instance.new("Model")
    folder.Name = "TreeHouseTrailFurniture"
    folder.Parent = treeHouse.Parent

    local wood = Color3.fromRGB(91, 64, 39)
    local post = makePart(folder, "DirectionPost", Vector3.new(1.2, 10, 1.2), CFrame.new(base + Vector3.new(10, 5, -10)), Enum.Material.Wood, wood)
    post.CanCollide = true

    local sign = makePart(folder, "DirectionBoard", Vector3.new(12, 3.2, 0.8), CFrame.new(base + Vector3.new(10, 8.2, -10)) * CFrame.Angles(0, math.rad(-18), 0), Enum.Material.WoodPlanks, Color3.fromRGB(111, 79, 44))
    sign.CanCollide = false
    addBoardText(sign, "TREE HOUSE  ↑\nJUNGLE CAVE  →\nOLD DOCK  ←")

    local mapPost = makePart(folder, "MapBoardPost", Vector3.new(1.3, 8, 1.3), CFrame.new(base + Vector3.new(-8, 4, -9)), Enum.Material.Wood, wood)
    mapPost.CanCollide = true
    local mapBoard = makePart(folder, "ExpeditionMapBoard", Vector3.new(13, 8, 0.8), CFrame.new(base + Vector3.new(-8, 8, -9)) * CFrame.Angles(0, math.rad(15), 0), Enum.Material.WoodPlanks, Color3.fromRGB(105, 75, 45))
    mapBoard.CanCollide = false
    addBoardText(mapBoard, "CANOPY ROUTES\nSOUTH: Shipwreck Beach\nEAST: Ancient Circle\nNORTH: Frostpeak\nWEST: Old Mangrove Dock")

    local prompt = Instance.new("ProximityPrompt")
    prompt.ActionText = "Study routes"
    prompt.ObjectText = "Expedition map board"
    prompt.HoldDuration = 0.2
    prompt.MaxActivationDistance = 10
    prompt.RequiresLineOfSight = false
    prompt.Parent = mapBoard
    prompt.Triggered:Connect(function(player)
        toast(player, "Tree House route note: the Jungle Cave lies southeast; the Old Dock is west; Frostpeak is far north beyond Stonefall.")
    end)

    print(string.format("[ISLE//ZERO][TREE HOUSE] Canopy clearing prepared; %d vegetation objects removed", removed))
end

local function scan()
    local root = workspace:FindFirstChild("ISLE_ZERO_WORLD")
    local treeHouse = root and root:FindFirstChild("JungleTreeHouse", true)
    if treeHouse and treeHouse:IsA("Model") then
        polish(treeHouse)
    end
end

workspace.DescendantAdded:Connect(function(instance)
    if instance:IsA("Model") and instance.Name == "JungleTreeHouse" then
        task.delay(0.2, polish, instance)
    end
end)

workspace:GetAttributeChangedSignal("ISLEZeroGenerated"):Connect(function()
    if workspace:GetAttribute("ISLEZeroGenerated") == true then
        task.delay(0.5, scan)
    end
end)

if workspace:GetAttribute("ISLEZeroGenerated") == true then
    task.delay(0.5, scan)
end
