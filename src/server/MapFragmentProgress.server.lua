local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local boundPickups = setmetatable({}, {__mode = "k"})
local explorerCache = nil

local function toast(player, message)
    local remotes = ReplicatedStorage:FindFirstChild("ISLEZeroSurvival")
    local remote = remotes and remotes:FindFirstChild("Toast")
    if remote and remote:IsA("RemoteEvent") then
        remote:FireClient(player, message)
    end
end

local function findExplorerCache()
    for _, cache in ipairs(CollectionService:GetTagged("SpecialWorldCache")) do
        if cache:GetAttribute("RewardItem") == "ExplorerRelic" then
            return cache
        end
    end
    return nil
end

local function anyPlayerCompletedMap()
    for _, player in ipairs(Players:GetPlayers()) do
        if (player:GetAttribute("MapFragmentsFound") or 0) >= 4 then
            return true
        end
    end
    return false
end

local function refreshCache()
    explorerCache = explorerCache or findExplorerCache()
    if not explorerCache then
        return
    end
    local prompt = explorerCache:FindFirstChildOfClass("ProximityPrompt")
    if not prompt then
        return
    end

    local unlocked = anyPlayerCompletedMap()
    prompt.Enabled = unlocked
    if unlocked then
        prompt.ObjectText = "LEGENDARY - Lost Explorer Relic"
        prompt.ActionText = "Claim completed-map reward"
    else
        prompt.ObjectText = "Collect all 4 expedition map fragments"
        prompt.ActionText = "Map incomplete"
    end
end

local function bindMapPickup(object)
    if boundPickups[object] or object:GetAttribute("ItemId") ~= "MapFragment" then
        return
    end
    local prompt = object:FindFirstChildOfClass("ProximityPrompt")
    if not prompt then
        return
    end
    boundPickups[object] = true

    prompt.Triggered:Connect(function(player)
        local pickupId = object:GetAttribute("PickupId") or object:GetFullName()
        local claimedKey = "MapFragment_" .. tostring(pickupId)
        if player:GetAttribute(claimedKey) then
            return
        end
        player:SetAttribute(claimedKey, true)
        local count = math.min(4, (player:GetAttribute("MapFragmentsFound") or 0) + 1)
        player:SetAttribute("MapFragmentsFound", count)
        if count < 4 then
            toast(player, string.format("Expedition map fragment %d/4 found.", count))
        else
            toast(player, "EXPEDITION MAP COMPLETE! The Lost Explorer Relic cache is now unlocked at the Ancient Circle.")
        end
        refreshCache()
    end)
end

CollectionService:GetInstanceAddedSignal("WorldPickup"):Connect(function(object)
    task.defer(bindMapPickup, object)
end)

local function bindExisting()
    for _, object in ipairs(CollectionService:GetTagged("WorldPickup")) do
        bindMapPickup(object)
    end
    task.delay(1, refreshCache)
end

workspace:GetAttributeChangedSignal("ISLEZeroGenerated"):Connect(function()
    if workspace:GetAttribute("ISLEZeroGenerated") == true then
        task.defer(bindExisting)
    end
end)

Players.PlayerAdded:Connect(function(player)
    player:GetAttributeChangedSignal("MapFragmentsFound"):Connect(refreshCache)
end)
for _, player in ipairs(Players:GetPlayers()) do
    player:GetAttributeChangedSignal("MapFragmentsFound"):Connect(refreshCache)
end

if workspace:GetAttribute("ISLEZeroGenerated") == true then
    task.defer(bindExisting)
end
