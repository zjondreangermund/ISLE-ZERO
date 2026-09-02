local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local shared = ReplicatedStorage:WaitForChild("Shared")
local GameplayConfig = require(shared:WaitForChild("GameplayConfig"))
local WorldConfig = require(shared:WaitForChild("WorldConfig"))

local remotes = ReplicatedStorage:WaitForChild("ISLEZeroSurvival")
local actionRemote = remotes:WaitForChild("Action")
local toastRemote = remotes:WaitForChild("Toast")

local attackTimes = {}

local function equippedTool(player, itemId)
    local character = player.Character
    if not character then
        return nil
    end
    for _, child in ipairs(character:GetChildren()) do
        if child:IsA("Tool") and child:GetAttribute("ItemId") == itemId then
            return child
        end
    end
    return nil
end

local function nearestEnemy(position, range)
    local nearestModel = nil
    local nearestDistance = range
    for _, enemy in ipairs(CollectionService:GetTagged("CaveGuardian")) do
        if enemy:IsA("Model") then
            local root = enemy:FindFirstChild("HumanoidRootPart")
            local humanoid = enemy:FindFirstChildOfClass("Humanoid")
            if root and humanoid and humanoid.Health > 0 then
                local distance = (root.Position - position).Magnitude
                if distance <= nearestDistance then
                    nearestDistance = distance
                    nearestModel = enemy
                end
            end
        end
    end
    return nearestModel
end

local function cardinal(from, to)
    local delta = Vector2.new(to.X - from.X, to.Z - from.Z)
    if delta.Magnitude < 5 then
        return "HERE"
    end
    local angle = math.deg(math.atan2(delta.X, -delta.Y))
    if angle < 0 then
        angle += 360
    end
    local directions = {"N", "NE", "E", "SE", "S", "SW", "W", "NW"}
    local index = math.floor((angle + 22.5) / 45) % 8 + 1
    return directions[index]
end

local function compassMessage(player)
    local character = player.Character
    local root = character and character:FindFirstChild("HumanoidRootPart")
    if not root then
        return
    end

    local targets = {
        {Name = "Jungle Depths", Position = Vector3.new(-620, 0, 205)},
        {Name = "Stonefall Ruins", Position = WorldConfig.Locations.RidgeRuins},
        {Name = "Frostpeak", Position = WorldConfig.Locations.Summit},
        {Name = "Bunker", Position = WorldConfig.Locations.BunkerApproach},
        {Name = "Old Village", Position = WorldConfig.Locations.Village},
        {Name = "Waterfall", Position = WorldConfig.Locations.Waterfall},
    }

    local nearest = nil
    local nearestDistance = math.huge
    for _, target in ipairs(targets) do
        if target.Position then
            local distance = Vector2.new(target.Position.X - root.Position.X, target.Position.Z - root.Position.Z).Magnitude
            if distance < nearestDistance and distance > 45 then
                nearestDistance = distance
                nearest = target
            end
        end
    end

    if nearest then
        toastRemote:FireClient(
            player,
            string.format("COMPASS: %s lies %s, about %d studs away.", nearest.Name, cardinal(root.Position, nearest.Position), math.floor(nearestDistance))
        )
    end
end

actionRemote.OnServerEvent:Connect(function(player, actionName, itemId)
    local definition = GameplayConfig.Items[itemId]
    if not definition then
        return
    end

    if actionName == "Attack" and itemId ~= "Machete" and definition.Damage then
        if not equippedTool(player, itemId) then
            return
        end
        local now = os.clock()
        local cooldown = itemId == "HunterSpear" and 0.68 or itemId == "IcePick" and 0.58 or 0.72
        if now - (attackTimes[player] or 0) < cooldown then
            return
        end
        attackTimes[player] = now

        local character = player.Character
        local root = character and character:FindFirstChild("HumanoidRootPart")
        if not root then
            return
        end

        local enemy = nearestEnemy(root.Position, definition.AttackRange or 12)
        if enemy then
            local humanoid = enemy:FindFirstChildOfClass("Humanoid")
            enemy:SetAttribute("LastHitUserId", player.UserId)
            if humanoid then
                humanoid:TakeDamage(definition.Damage)
            end
        end
    elseif actionName == "Use" and definition.Heal and itemId ~= "Medkit" then
        local tool = equippedTool(player, itemId)
        local character = player.Character
        local humanoid = character and character:FindFirstChildOfClass("Humanoid")
        if tool and humanoid and humanoid.Health > 0 and humanoid.Health < humanoid.MaxHealth then
            humanoid.Health = math.min(humanoid.MaxHealth, humanoid.Health + definition.Heal)
            tool:Destroy()
            toastRemote:FireClient(player, (definition.DisplayName or itemId) .. " used.")
        end
    elseif actionName == "Use" and itemId == "AncientCompass" then
        if equippedTool(player, itemId) then
            compassMessage(player)
        end
    end
end)
