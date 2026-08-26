local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local WorldConfig = require(Shared:WaitForChild("WorldConfig"))
local GameplayConfig = require(Shared:WaitForChild("GameplayConfig"))

local lastRegion = {}
local gateCooldown = {}
local boundRewards = {}
local boundTravel = {}
local accumulated = 0

local function toast(player, message)
    local remotes = ReplicatedStorage:FindFirstChild("ISLEZeroSurvival")
    local remote = remotes and remotes:FindFirstChild("Toast")
    if remote and remote:IsA("RemoteEvent") then
        remote:FireClient(player, message)
    else
        print(string.format("[ISLE//ZERO][PROGRESSION][%s] %s", player.Name, message))
    end
end

local function toolContainers(player)
    return {
        player.Character,
        player:FindFirstChildOfClass("Backpack"),
    }
end

local function hasItem(player, itemId)
    if not itemId then
        return true
    end
    for _, container in ipairs(toolContainers(player)) do
        if container then
            for _, child in ipairs(container:GetChildren()) do
                if child:IsA("Tool") and child:GetAttribute("ItemId") == itemId then
                    return true
                end
            end
        end
    end
    return player:GetAttribute("ProgressionItem_" .. itemId) == true
end

local function createProgressionTool(player, itemId)
    if hasItem(player, itemId) then
        return
    end

    local definition = GameplayConfig.Items[itemId]
    if not definition then
        return
    end

    local tool = Instance.new("Tool")
    tool.Name = definition.DisplayName or itemId
    tool.CanBeDropped = false
    tool.RequiresHandle = true
    tool:SetAttribute("ItemId", itemId)
    tool:SetAttribute("Rarity", definition.Rarity or "Progression")
    tool:SetAttribute("Description", definition.Description or "")

    local handle = Instance.new("Part")
    handle.Name = "Handle"
    handle.Anchored = false
    handle.CanCollide = false
    handle.CanTouch = false
    handle.Massless = true
    handle.Material = Enum.Material.SmoothPlastic
    handle.Color = definition.Color or Color3.fromRGB(130, 130, 130)
    handle.Size = Vector3.new(2.2, 2.8, 1.2)

    if itemId == "WinterGear" then
        handle.Size = Vector3.new(3, 3.4, 1.4)
        handle.Material = Enum.Material.Fabric
    elseif itemId == "ClimbingKit" then
        handle.Size = Vector3.new(2.4, 3, 1.5)
        handle.Material = Enum.Material.Metal
    elseif itemId == "BoatRepairKit" then
        handle.Size = Vector3.new(3.2, 1.8, 2.4)
        handle.Material = Enum.Material.WoodPlanks
    elseif itemId == "FrostheartRelic" or itemId == "ZeroCore" then
        handle.Shape = Enum.PartType.Ball
        handle.Size = Vector3.new(2.2, 2.2, 2.2)
        handle.Material = Enum.Material.Neon
        local light = Instance.new("PointLight")
        light.Brightness = 2.4
        light.Range = 16
        light.Color = handle.Color
        light.Parent = handle
    end

    handle.Parent = tool
    tool.Parent = player:WaitForChild("Backpack")
    player:SetAttribute("ProgressionItem_" .. itemId, true)
end

local function getPlayerRoot(player)
    local character = player.Character
    return character and character:FindFirstChild("HumanoidRootPart")
end

local function groundCFrame(x, z, yaw)
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.IgnoreWater = false
    local result = workspace:Raycast(Vector3.new(x, 650, z), Vector3.new(0, -900, 0), params)
    local y = result and result.Position.Y + 5 or 30
    return CFrame.new(x, y, z) * CFrame.Angles(0, math.rad(yaw or 0), 0)
end

local function movePlayer(player, target)
    local character = player.Character
    if not character then
        return
    end
    if character.PrimaryPart then
        character:PivotTo(target)
        return
    end
    local root = character:FindFirstChild("HumanoidRootPart")
    if root then
        root.CFrame = target
    end
end

local function warnGate(player, id, message, fallback)
    local now = os.clock()
    local key = tostring(player.UserId) .. "_" .. id
    if now - (gateCooldown[key] or 0) < 2.2 then
        return
    end
    gateCooldown[key] = now
    toast(player, message)
    movePlayer(player, fallback)
end

local function inHorizontalRadius(position, center, radius)
    return Vector2.new(position.X - center.X, position.Z - center.Z).Magnitude <= radius
end

local function enforceGates(player)
    local root = getPlayerRoot(player)
    if not root then
        return
    end
    local position = root.Position

    local frost = WorldConfig.Regions and WorldConfig.Regions.Frostpeak
    if frost and position.Z < -485 and inHorizontalRadius(position, frost.Center, frost.Radius + 30) and not hasItem(player, frost.Requirement) then
        warnGate(
            player,
            "Frostpeak",
            "The temperature is deadly. Find Frostpeak Winter Gear before entering the mountains.",
            groundCFrame(-110, -455, 180)
        )
        return
    end

    local stonefall = WorldConfig.Regions and WorldConfig.Regions.StonefallRuins
    if stonefall and position.X > 90 and position.Z < -405 and position.Y > 125 and inHorizontalRadius(position, stonefall.Center, stonefall.Radius + 40) and not hasItem(player, stonefall.Requirement) then
        warnGate(
            player,
            "StonefallUpper",
            "The upper Stonefall ridge needs a Climbing Kit. Clear Jungle Depths first.",
            groundCFrame(85, -385, 155)
        )
        return
    end

    local deserted = WorldConfig.Regions and WorldConfig.Regions.DesertedIsland
    if deserted and inHorizontalRadius(position, deserted.Center, deserted.Radius + 20) and not hasItem(player, deserted.Requirement) then
        warnGate(
            player,
            "DesertedIsland",
            "You need the Boat Repair Kit and the old raft to reach Deserted Island properly.",
            groundCFrame(-940, 440, 90)
        )
    end
end

local function regionFor(position)
    local bestId = nil
    local bestRegion = nil
    local bestScore = math.huge
    for regionId, region in pairs(WorldConfig.Regions or {}) do
        local radius = region.Radius or 100
        local distance = Vector2.new(position.X - region.Center.X, position.Z - region.Center.Z).Magnitude
        local score = distance / radius
        if score <= 1 and score < bestScore then
            bestScore = score
            bestId = regionId
            bestRegion = region
        end
    end
    return bestId, bestRegion
end

local function announceRegion(player)
    local root = getPlayerRoot(player)
    if not root then
        return
    end
    local id, region = regionFor(root.Position)
    if id and lastRegion[player] ~= id then
        lastRegion[player] = id
        local difficulty = region.Difficulty or 1
        local suffix = difficulty >= 4 and "  DANGER" or ""
        toast(player, string.format("%s  |  DIFFICULTY %d/5%s", region.DisplayName or id, difficulty, suffix))
    end
end

local function enableRewardWhenReady(cache)
    local caveId = cache:GetAttribute("CaveId")
    local root = workspace:FindFirstChild("ISLE_ZERO_WORLD")
    local caves = root and root:FindFirstChild("Caves")
    local cave = caves and caves:FindFirstChild(caveId)
    local prompt = cache:FindFirstChildOfClass("ProximityPrompt")
    if not cave or not prompt then
        return
    end

    local function refresh()
        local cleared = cave:GetAttribute("GuardianDefeated") == true
        prompt.Enabled = cleared
        if cleared then
            local rarity = cache:GetAttribute("Rarity") or "Rare"
            local rewardName = cache:GetAttribute("RewardName") or "reward"
            prompt.ObjectText = rarity .. " - " .. rewardName
        end
    end
    refresh()
    cave:GetAttributeChangedSignal("GuardianDefeated"):Connect(refresh)
end

local function bindReward(cache)
    if boundRewards[cache] then
        return
    end
    boundRewards[cache] = true
    enableRewardWhenReady(cache)

    local prompt = cache:FindFirstChildOfClass("ProximityPrompt")
    if not prompt then
        return
    end

    prompt.Triggered:Connect(function(player)
        local caveId = cache:GetAttribute("CaveId")
        local itemId = cache:GetAttribute("RewardItem")
        local rewardName = cache:GetAttribute("RewardName") or itemId
        local rarity = cache:GetAttribute("Rarity") or "Rare"
        if not caveId or not itemId then
            return
        end
        if player:GetAttribute("ClaimedGuardianReward_" .. caveId) == true then
            toast(player, "You already claimed this guardian reward.")
            return
        end

        local root = workspace:FindFirstChild("ISLE_ZERO_WORLD")
        local caves = root and root:FindFirstChild("Caves")
        local cave = caves and caves:FindFirstChild(caveId)
        if not cave or cave:GetAttribute("GuardianDefeated") ~= true then
            toast(player, "Defeat this cave's guardian first.")
            return
        end

        createProgressionTool(player, itemId)
        player:SetAttribute("ClaimedGuardianReward_" .. caveId, true)
        toast(player, string.format("%s REWARD: %s acquired!", string.upper(rarity), rewardName))
    end)
end

local function findTravelPoint(id)
    for _, marker in ipairs(CollectionService:GetTagged("WorldTravelPoint")) do
        if marker:GetAttribute("TravelPoint") == id then
            return marker
        end
    end
    return nil
end

local function bindTravel(object)
    if boundTravel[object] then
        return
    end
    boundTravel[object] = true
    local prompt = object:FindFirstChildOfClass("ProximityPrompt")
    if not prompt then
        return
    end

    prompt.Triggered:Connect(function(player)
        local travelId = object:GetAttribute("TravelId")
        if travelId == "DesertedIsland" then
            if not hasItem(player, "BoatRepairKit") then
                toast(player, "The raft is broken. Defeat the Southern Cliffs guardian to get a Boat Repair Kit.")
                return
            end
            local target = findTravelPoint("DesertedIsland")
            if target then
                movePlayer(player, target.CFrame + Vector3.new(0, 5, 0))
                toast(player, "You repaired the raft and sailed to DESERTED ISLAND.")
            end
        elseif travelId == "ReturnMainIsland" then
            movePlayer(player, groundCFrame(-930, 445, -90))
            toast(player, "Returned to the main island.")
        end
    end)
end

local function bindWorld()
    for _, cache in ipairs(CollectionService:GetTagged("GuardianRewardCache")) do
        bindReward(cache)
    end
    for _, object in ipairs(CollectionService:GetTagged("ProgressionTravel")) do
        bindTravel(object)
    end
    print("[ISLE//ZERO][PROGRESSION] Gear gates, region discovery, travel and guardian rewards are live")
end

workspace:GetAttributeChangedSignal("ISLEZeroGenerated"):Connect(function()
    if workspace:GetAttribute("ISLEZeroGenerated") == true then
        task.defer(bindWorld)
    end
end)

if workspace:GetAttribute("ISLEZeroGenerated") == true then
    task.defer(bindWorld)
end

RunService.Heartbeat:Connect(function(deltaTime)
    accumulated += deltaTime
    if accumulated < 0.45 then
        return
    end
    accumulated = 0
    for _, player in ipairs(Players:GetPlayers()) do
        enforceGates(player)
        announceRegion(player)
    end
end)

Players.PlayerRemoving:Connect(function(player)
    lastRegion[player] = nil
end)
