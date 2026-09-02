local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local HUNGER_MAX = 100
local HUNGER_TICK_SECONDS = 20
local HUNGER_DRAIN = 1
local STARVATION_DAMAGE = 2

local FOOD_DEFINITIONS = {
    Berries = {
        DisplayName = "Forest Berries",
        Restore = 16,
        Color = Color3.fromRGB(130, 48, 73),
        Size = Vector3.new(1.6, 1.6, 1.6),
    },
    Coconut = {
        DisplayName = "Coconut",
        Restore = 24,
        Color = Color3.fromRGB(105, 76, 45),
        Size = Vector3.new(2.2, 2.2, 2.2),
    },
    FoodRation = {
        DisplayName = "Expedition Food Ration",
        Restore = 38,
        Color = Color3.fromRGB(139, 124, 85),
        Size = Vector3.new(2.4, 1.3, 2.2),
    },
    CookedWildMeat = {
        DisplayName = "Cooked Wild Meat",
        Restore = 32,
        Color = Color3.fromRGB(116, 70, 48),
        Size = Vector3.new(2.4, 0.8, 1.7),
    },
}

local FOOD_SPAWNS = {
    {Id = "beach_coconut_a", FoodId = "Coconut", Position = Vector3.new(115, 0, 735)},
    {Id = "beach_coconut_b", FoodId = "Coconut", Position = Vector3.new(250, 0, 690)},
    {Id = "beach_ration", FoodId = "FoodRation", Position = Vector3.new(165, 0, 760)},
    {Id = "plains_berries_a", FoodId = "Berries", Position = Vector3.new(-45, 0, 295)},
    {Id = "plains_berries_b", FoodId = "Berries", Position = Vector3.new(175, 0, 280)},
    {Id = "village_ration", FoodId = "FoodRation", Position = Vector3.new(365, 0, 135)},
    {Id = "jungle_berries_a", FoodId = "Berries", Position = Vector3.new(-335, 0, 320)},
    {Id = "jungle_berries_b", FoodId = "Berries", Position = Vector3.new(-500, 0, 85)},
    {Id = "south_coconut", FoodId = "Coconut", Position = Vector3.new(680, 0, 610)},
    {Id = "east_ration", FoodId = "FoodRation", Position = Vector3.new(600, 0, 95)},
    {Id = "stonefall_ration", FoodId = "FoodRation", Position = Vector3.new(170, 0, -440)},
    {Id = "deserted_coconut", FoodId = "Coconut", Position = Vector3.new(-1080, 0, 430)},
}

local boundPickups = setmetatable({}, {__mode = "k"})
local warnedStage = setmetatable({}, {__mode = "k"})

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

local function inSafeCamp(position)
    for _, zone in ipairs(CollectionService:GetTagged("SafeCampZone")) do
        if zone:IsA("BasePart") and zone:IsDescendantOf(workspace) then
            local radius = zone:GetAttribute("SafeRadius") or 29
            if horizontalDistance(position, zone.Position) <= radius then
                return true
            end
        end
    end
    return false
end

local function getRoot(player)
    local character = player.Character
    return character and character:FindFirstChild("HumanoidRootPart")
end

local function createFoodTool(player, foodId)
    local definition = FOOD_DEFINITIONS[foodId]
    local backpack = player:FindFirstChildOfClass("Backpack")
    if not definition or not backpack then
        return
    end

    local tool = Instance.new("Tool")
    tool.Name = definition.DisplayName
    tool.RequiresHandle = true
    tool.CanBeDropped = false
    tool:SetAttribute("ItemId", foodId)
    tool:SetAttribute("FoodItem", true)
    tool:SetAttribute("HungerRestore", definition.Restore)

    local handle = Instance.new("Part")
    handle.Name = "Handle"
    handle.Size = definition.Size
    handle.Color = definition.Color
    handle.Material = foodId == "Coconut" and Enum.Material.Wood or Enum.Material.SmoothPlastic
    handle.CanCollide = false
    handle.CanTouch = false
    handle.Massless = true
    if foodId == "Berries" or foodId == "Coconut" then
        handle.Shape = Enum.PartType.Ball
    end
    handle.Parent = tool
    tool.Parent = backpack
end

local function groundPosition(position)
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = Players:GetPlayers()
    params.IgnoreWater = false
    local result = workspace:Raycast(
        Vector3.new(position.X, 600, position.Z),
        Vector3.new(0, -900, 0),
        params
    )
    if result then
        return result.Position
    end
    return position
end

local function createFoodPickup(parent, id, foodId, position)
    local definition = FOOD_DEFINITIONS[foodId]
    if not definition then
        return
    end

    local object = Instance.new("Part")
    object.Name = "Food_" .. id
    object.Anchored = true
    object.CanCollide = false
    object.CanTouch = false
    object.Size = definition.Size
    object.Material = foodId == "Coconut" and Enum.Material.Wood or Enum.Material.SmoothPlastic
    object.Color = definition.Color
    if foodId == "Berries" or foodId == "Coconut" then
        object.Shape = Enum.PartType.Ball
    end
    local ground = groundPosition(position)
    object.CFrame = CFrame.new(ground + Vector3.new(0, object.Size.Y / 2 + 0.3, 0))
    object:SetAttribute("FoodId", foodId)
    object:SetAttribute("FoodPickupId", id)
    object.Parent = parent
    CollectionService:AddTag(object, "FoodPickup")

    local prompt = Instance.new("ProximityPrompt")
    prompt.Name = "FoodPrompt"
    prompt.ActionText = "Take food"
    prompt.ObjectText = definition.DisplayName
    prompt.HoldDuration = 0.15
    prompt.MaxActivationDistance = 9
    prompt.RequiresLineOfSight = false
    prompt.Parent = object
end

local function bindFoodPickup(object)
    if boundPickups[object] then
        return
    end
    local prompt = object:FindFirstChildOfClass("ProximityPrompt")
    if not prompt then
        return
    end
    boundPickups[object] = true

    prompt.Triggered:Connect(function(player)
        if not object.Parent then
            return
        end

        local foodId = object:GetAttribute("FoodId")
        if foodId == "RawMeat" then
            local amount = object:GetAttribute("Amount") or 1
            player:SetAttribute("RawMeat", (player:GetAttribute("RawMeat") or 0) + amount)
            toast(player, string.format("Raw wild meat x%d collected. Cook it at a campfire.", amount))
            object:Destroy()
            return
        end

        local definition = foodId and FOOD_DEFINITIONS[foodId]
        if not definition then
            return
        end
        createFoodTool(player, foodId)
        toast(player, definition.DisplayName .. " added to your backpack.")
        object:Destroy()
    end)
end

local function seedFoodWorld()
    local root = workspace:FindFirstChild("ISLE_ZERO_WORLD")
    if not root then
        return
    end

    local old = root:FindFirstChild("FoodAndForage")
    if old then
        old:Destroy()
    end

    local folder = Instance.new("Folder")
    folder.Name = "FoodAndForage"
    folder.Parent = root

    for _, entry in ipairs(FOOD_SPAWNS) do
        createFoodPickup(folder, entry.Id, entry.FoodId, entry.Position)
    end
end

local function equippedFood(player, itemId)
    local character = player.Character
    if not character then
        return nil
    end
    for _, child in ipairs(character:GetChildren()) do
        if child:IsA("Tool")
            and child:GetAttribute("FoodItem") == true
            and child:GetAttribute("ItemId") == itemId then
            return child
        end
    end
    return nil
end

local function setHunger(player, value)
    player:SetAttribute("Hunger", math.clamp(math.floor(value + 0.5), 0, HUNGER_MAX))
end

local function playerAdded(player)
    if player:GetAttribute("Hunger") == nil then
        player:SetAttribute("Hunger", HUNGER_MAX)
    end
    if player:GetAttribute("RawMeat") == nil then
        player:SetAttribute("RawMeat", 0)
    end
    warnedStage[player] = 0
end

Players.PlayerAdded:Connect(playerAdded)
Players.PlayerRemoving:Connect(function(player)
    warnedStage[player] = nil
end)
for _, player in ipairs(Players:GetPlayers()) do
    playerAdded(player)
end

CollectionService:GetInstanceAddedSignal("FoodPickup"):Connect(function(object)
    task.defer(bindFoodPickup, object)
end)
for _, object in ipairs(CollectionService:GetTagged("FoodPickup")) do
    bindFoodPickup(object)
end

local remotes = ReplicatedStorage:WaitForChild("ISLEZeroSurvival")
local actionRemote = remotes:WaitForChild("Action")
actionRemote.OnServerEvent:Connect(function(player, actionName, itemId)
    if actionName ~= "EatFood" then
        return
    end
    local tool = equippedFood(player, itemId)
    if not tool then
        return
    end
    local restore = tool:GetAttribute("HungerRestore") or 0
    if restore <= 0 then
        return
    end

    setHunger(player, (player:GetAttribute("Hunger") or HUNGER_MAX) + restore)
    tool:Destroy()
    warnedStage[player] = 0
    toast(player, string.format("You ate %s. Hunger %d%%.", tool.Name, player:GetAttribute("Hunger") or HUNGER_MAX))
end)

workspace:GetAttributeChangedSignal("ISLEZeroGenerated"):Connect(function()
    if workspace:GetAttribute("ISLEZeroGenerated") == true then
        task.defer(seedFoodWorld)
    end
end)
if workspace:GetAttribute("ISLEZeroGenerated") == true then
    task.defer(seedFoodWorld)
end

task.spawn(function()
    while true do
        task.wait(HUNGER_TICK_SECONDS)
        for _, player in ipairs(Players:GetPlayers()) do
            local root = getRoot(player)
            if root and not inSafeCamp(root.Position) then
                local hunger = math.max(0, (player:GetAttribute("Hunger") or HUNGER_MAX) - HUNGER_DRAIN)
                setHunger(player, hunger)

                if hunger <= 0 then
                    local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
                    if humanoid and humanoid.Health > 0 then
                        humanoid:TakeDamage(STARVATION_DAMAGE)
                    end
                    if warnedStage[player] ~= 3 then
                        warnedStage[player] = 3
                        toast(player, "You are starving. Find food or return to a safe camp.")
                    end
                elseif hunger <= 20 and warnedStage[player] ~= 2 then
                    warnedStage[player] = 2
                    toast(player, "Food is getting low, but you still have time to forage.")
                elseif hunger <= 45 and warnedStage[player] == 0 then
                    warnedStage[player] = 1
                    toast(player, "You are getting hungry. Berries, coconuts and rations are scattered around the island.")
                end
            end
        end
    end
end)
