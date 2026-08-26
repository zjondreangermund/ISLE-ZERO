local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameplayConfig = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("GameplayConfig"))

local remotes = ReplicatedStorage:FindFirstChild("ISLEZeroSurvival")
if not remotes then
    remotes = Instance.new("Folder")
    remotes.Name = "ISLEZeroSurvival"
    remotes.Parent = ReplicatedStorage
end

local function ensureRemoteEvent(name)
    local remote = remotes:FindFirstChild(name)
    if remote and remote:IsA("RemoteEvent") then
        return remote
    end
    if remote then
        remote:Destroy()
    end
    remote = Instance.new("RemoteEvent")
    remote.Name = name
    remote.Parent = remotes
    return remote
end

local function ensureRemoteFunction(name)
    local remote = remotes:FindFirstChild(name)
    if remote and remote:IsA("RemoteFunction") then
        return remote
    end
    if remote then
        remote:Destroy()
    end
    remote = Instance.new("RemoteFunction")
    remote.Name = name
    remote.Parent = remotes
    return remote
end

local actionRemote = ensureRemoteEvent("Action")
local stateRemote = ensureRemoteEvent("State")
local toastRemote = ensureRemoteEvent("Toast")
local getStateRemote = ensureRemoteFunction("GetState")

local states = {}
local attackTimes = {}

local function newState()
    return {
        inventory = {},
        openedChests = {},
        treasureValue = 0,
        cavesCleared = 0,
        lastCamp = nil,
        safeCamp = nil,
    }
end

local function stateFor(player)
    local state = states[player]
    if not state then
        state = newState()
        states[player] = state
    end
    return state
end

local function inventoryCopy(inventory)
    local result = {}
    for key, value in pairs(inventory) do
        result[key] = value
    end
    return result
end

local function makeStatePacket(player)
    local state = stateFor(player)
    return {
        Inventory = inventoryCopy(state.inventory),
        TreasureValue = state.treasureValue,
        CavesCleared = state.cavesCleared,
        SafeCamp = state.safeCamp,
        Recipe = GameplayConfig.CampRecipe,
    }
end

local function sendState(player)
    stateRemote:FireClient(player, makeStatePacket(player))
end

local function toast(player, message)
    toastRemote:FireClient(player, message)
end

local function toastAll(message)
    toastRemote:FireAllClients(message)
end

local function ensureLeaderstats(player)
    local leaderstats = player:FindFirstChild("leaderstats")
    if not leaderstats then
        leaderstats = Instance.new("Folder")
        leaderstats.Name = "leaderstats"
        leaderstats.Parent = player
    end

    local treasure = leaderstats:FindFirstChild("Treasure")
    if not treasure then
        treasure = Instance.new("IntValue")
        treasure.Name = "Treasure"
        treasure.Parent = leaderstats
    end

    local caves = leaderstats:FindFirstChild("Caves")
    if not caves then
        caves = Instance.new("IntValue")
        caves.Name = "Caves"
        caves.Parent = leaderstats
    end
end

local function updateLeaderstats(player)
    ensureLeaderstats(player)
    local state = stateFor(player)
    local leaderstats = player:FindFirstChild("leaderstats")
    if not leaderstats then
        return
    end
    local treasure = leaderstats:FindFirstChild("Treasure")
    local caves = leaderstats:FindFirstChild("Caves")
    if treasure and treasure:IsA("IntValue") then
        treasure.Value = state.treasureValue
    end
    if caves and caves:IsA("IntValue") then
        caves.Value = state.cavesCleared
    end
end

local function hasTool(player, itemId)
    for _, container in ipairs({player:FindFirstChildOfClass("Backpack"), player.Character}) do
        if container then
            for _, child in ipairs(container:GetChildren()) do
                if child:IsA("Tool") and child:GetAttribute("ItemId") == itemId then
                    return true
                end
            end
        end
    end
    return false
end

local function createTool(player, itemId)
    local definition = GameplayConfig.Items[itemId]
    if not definition then
        return
    end
    if definition.Kind == "Tool" and hasTool(player, itemId) then
        return
    end

    local tool = Instance.new("Tool")
    tool.Name = definition.DisplayName or itemId
    tool.CanBeDropped = false
    tool.RequiresHandle = true
    tool:SetAttribute("ItemId", itemId)

    local handle = Instance.new("Part")
    handle.Name = "Handle"
    handle.Anchored = false
    handle.CanCollide = false
    handle.CanTouch = false
    handle.Massless = true
    handle.Color = definition.Color or Color3.fromRGB(120, 120, 120)
    handle.Material = itemId == "Machete" and Enum.Material.Metal or Enum.Material.SmoothPlastic
    handle.TopSurface = Enum.SurfaceType.Smooth
    handle.BottomSurface = Enum.SurfaceType.Smooth

    if itemId == "Machete" then
        handle.Size = Vector3.new(0.55, 4.2, 0.45)
        tool.Grip = CFrame.new(0, -1.15, 0) * CFrame.Angles(0, 0, math.rad(-8))
    elseif itemId == "Torch" then
        handle.Size = Vector3.new(0.7, 3.6, 0.7)
        handle.Material = Enum.Material.Wood
        local flame = Instance.new("PointLight")
        flame.Name = "TorchLight"
        flame.Brightness = 2.2
        flame.Range = 28
        flame.Color = Color3.fromRGB(255, 190, 112)
        flame.Shadows = true
        flame.Parent = handle
    elseif itemId == "Medkit" then
        handle.Size = Vector3.new(2.4, 1.5, 2.4)
        handle.Color = Color3.fromRGB(205, 210, 203)
    else
        handle.Size = Vector3.new(1, 3, 1)
    end

    handle.Parent = tool
    tool.Parent = player:WaitForChild("Backpack")
end

local function addItem(player, itemId, amount)
    amount = amount or 1
    local definition = GameplayConfig.Items[itemId]
    if not definition then
        return
    end

    if definition.Kind == "Tool" then
        createTool(player, itemId)
    elseif definition.Kind == "ConsumableTool" then
        for _ = 1, amount do
            createTool(player, itemId)
        end
    else
        local state = stateFor(player)
        state.inventory[itemId] = (state.inventory[itemId] or 0) + amount
        if definition.Kind == "Valuable" then
            state.treasureValue += (definition.Value or 0) * amount
        end
    end

    updateLeaderstats(player)
    sendState(player)
end

local function canAfford(player, recipe)
    local inventory = stateFor(player).inventory
    for itemId, amount in pairs(recipe) do
        if (inventory[itemId] or 0) < amount then
            return false, itemId, amount - (inventory[itemId] or 0)
        end
    end
    return true
end

local function consumeRecipe(player, recipe)
    local inventory = stateFor(player).inventory
    for itemId, amount in pairs(recipe) do
        inventory[itemId] = math.max(0, (inventory[itemId] or 0) - amount)
    end
    sendState(player)
end

local function findCave(caveId)
    local root = workspace:FindFirstChild("ISLE_ZERO_WORLD")
    local caves = root and root:FindFirstChild("Caves")
    return caves and caves:FindFirstChild(caveId)
end

local function findGround(position, root)
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = root and {root} or {}
    params.IgnoreWater = false
    local result = workspace:Raycast(
        Vector3.new(position.X, 600, position.Z),
        Vector3.new(0, -900, 0),
        params
    )
    if result then
        return result.Position
    end
    return Vector3.new(position.X, position.Y, position.Z)
end

local function pickupSize(itemId)
    if itemId == "Machete" then
        return Vector3.new(0.8, 4.5, 0.6)
    elseif itemId == "Torch" then
        return Vector3.new(0.8, 3.6, 0.8)
    elseif itemId == "Medkit" then
        return Vector3.new(2.5, 1.7, 2.5)
    elseif itemId == "Rope" then
        return Vector3.new(2.2, 1.2, 2.2)
    end
    return Vector3.new(2.4, 2.4, 2.4)
end

local function createSurfacePickup(parent, entry, ground)
    local definition = GameplayConfig.Items[entry.ItemId]
    if not definition then
        return nil
    end

    local part = Instance.new("Part")
    part.Name = "Pickup_" .. entry.Id
    part.Anchored = true
    part.CanCollide = false
    part.CanTouch = false
    part.Material = entry.ItemId == "Machete" and Enum.Material.Metal or Enum.Material.SmoothPlastic
    part.Color = definition.Color or Color3.fromRGB(125, 125, 120)
    part.Size = pickupSize(entry.ItemId)
    part.CFrame = CFrame.new(ground + Vector3.new(0, part.Size.Y / 2 + 0.35, 0)) * CFrame.Angles(0, math.rad(18), entry.ItemId == "Machete" and math.rad(70) or 0)
    part:SetAttribute("ItemId", entry.ItemId)
    part:SetAttribute("Amount", entry.Amount or 1)
    part:SetAttribute("PickupId", entry.Id)
    part.Parent = parent
    CollectionService:AddTag(part, "WorldPickup")

    if entry.ItemId == "Torch" then
        local light = Instance.new("PointLight")
        light.Brightness = 1.2
        light.Range = 15
        light.Color = Color3.fromRGB(255, 190, 112)
        light.Parent = part
    end

    local prompt = Instance.new("ProximityPrompt")
    prompt.Name = "PickupPrompt"
    prompt.ActionText = "Pick up"
    prompt.ObjectText = definition.DisplayName or entry.ItemId
    prompt.HoldDuration = 0.15
    prompt.MaxActivationDistance = 10
    prompt.RequiresLineOfSight = false
    prompt.Parent = part
    return part
end

local function seedStarterPickups(root)
    local folder = root:FindFirstChild("GameplayItems")
    if folder then
        folder:Destroy()
    end
    folder = Instance.new("Folder")
    folder.Name = "GameplayItems"
    folder.Parent = root

    for _, entry in ipairs(GameplayConfig.StarterPickups) do
        local ground = findGround(entry.Position, root)
        createSurfacePickup(folder, entry, ground)
    end
end

local function bindPickup(part)
    if part:GetAttribute("SurvivalBound") then
        return
    end
    part:SetAttribute("SurvivalBound", true)

    local prompt = part:FindFirstChildOfClass("ProximityPrompt")
    if not prompt then
        prompt = Instance.new("ProximityPrompt")
        prompt.ActionText = "Pick up"
        prompt.MaxActivationDistance = 10
        prompt.RequiresLineOfSight = false
        prompt.Parent = part
    end

    local itemId = part:GetAttribute("ItemId")
    local definition = itemId and GameplayConfig.Items[itemId]
    if definition then
        prompt.ObjectText = definition.DisplayName or itemId
    end

    prompt.Triggered:Connect(function(player)
        if not part.Parent then
            return
        end
        local id = part:GetAttribute("ItemId")
        local amount = part:GetAttribute("Amount") or 1
        local item = id and GameplayConfig.Items[id]
        if not item then
            return
        end
        addItem(player, id, amount)
        toast(player, string.format("Picked up %s%s", item.DisplayName or id, amount > 1 and (" x" .. tostring(amount)) or ""))
        part:Destroy()
    end)
end

local function rollChest(player, tier)
    local random = Random.new()
    if tier == "Supplies" then
        local wood = random:NextInteger(4, 8)
        local cloth = random:NextInteger(2, 4)
        local rope = random:NextInteger(1, 3)
        addItem(player, "Wood", wood)
        addItem(player, "Cloth", cloth)
        addItem(player, "Rope", rope)
        addItem(player, "Stone", random:NextInteger(2, 5))
        if random:NextNumber() < 0.55 then
            addItem(player, "Medkit", 1)
        end
        return string.format("Supplies: wood %d, cloth %d, rope %d", wood, cloth, rope)
    elseif tier == "Relic" then
        local coins = random:NextInteger(3, 7)
        addItem(player, "AncientCoin", coins)
        addItem(player, "RelicShard", random:NextInteger(1, 2))
        if random:NextNumber() < 0.45 then
            addItem(player, "Ruby", 1)
            return string.format("Relics: %d coins, shard and a ruby!", coins)
        end
        return string.format("Relics: %d ancient coins and relic shards", coins)
    else
        local coins = random:NextInteger(5, 10)
        addItem(player, "AncientCoin", coins)
        addItem(player, "GoldBar", 1)
        if random:NextNumber() < 0.7 then
            addItem(player, "Ruby", random:NextInteger(1, 2))
        end
        addItem(player, "RelicShard", 1)
        return string.format("Deep cache: gold bar, %d coins and valuables", coins)
    end
end

local function bindChest(base)
    if base:GetAttribute("SurvivalBound") then
        return
    end
    base:SetAttribute("SurvivalBound", true)
    local prompt = base:FindFirstChildOfClass("ProximityPrompt")
    if not prompt then
        return
    end

    prompt.Triggered:Connect(function(player)
        local caveId = base:GetAttribute("CaveId")
        local chestId = base:GetAttribute("ChestId")
        local cave = caveId and findCave(caveId)
        if not cave or cave:GetAttribute("GuardianDefeated") ~= true then
            toast(player, "The guardian still controls this cave.")
            return
        end

        local state = stateFor(player)
        if state.openedChests[chestId] then
            toast(player, "You already searched this chest.")
            return
        end
        state.openedChests[chestId] = true

        local message = rollChest(player, base:GetAttribute("LootTier") or "Supplies")
        toast(player, message)

        local model = base.Parent
        local lid = model and model:FindFirstChild("ChestLid")
        if lid and lid:IsA("BasePart") and not model:GetAttribute("OpenedVisual") then
            model:SetAttribute("OpenedVisual", true)
            lid.CFrame = lid.CFrame * CFrame.new(0, 1.2, -1.2) * CFrame.Angles(math.rad(-35), 0, 0)
        end
    end)
end

local function tentPart(parent, name, size, cframe, material, color)
    local part = Instance.new("Part")
    part.Name = name
    part.Anchored = true
    part.CanTouch = false
    part.Size = size
    part.CFrame = cframe
    part.Material = material
    part.Color = color
    part.TopSurface = Enum.SurfaceType.Smooth
    part.BottomSurface = Enum.SurfaceType.Smooth
    part.Parent = parent
    return part
end

local function setCamp(player, caveId, cframe)
    local state = stateFor(player)
    state.lastCamp = cframe
    state.safeCamp = caveId
    player:SetAttribute("SafeCamp", caveId)
    local character = player.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    if humanoid then
        humanoid.Health = humanoid.MaxHealth
    end
    sendState(player)
    toast(player, "Safe camp set. You are healed and will return here after defeat.")
end

local function createTent(marker, caveId, player)
    local cave = findCave(caveId)
    if not cave then
        return
    end

    local existing = cave:FindFirstChild("SafeTent")
    if existing then
        return
    end

    local model = Instance.new("Model")
    model.Name = "SafeTent"
    model:SetAttribute("CaveId", caveId)
    model:SetAttribute("BuiltBy", player.UserId)
    model.Parent = cave

    local base = marker.CFrame * CFrame.new(0, 0.7, 0)
    local wood = Color3.fromRGB(84, 60, 38)
    local canvas = Color3.fromRGB(70, 86, 66)

    tentPart(model, "Groundsheet", Vector3.new(13, 0.5, 10), base, Enum.Material.Fabric, Color3.fromRGB(61, 70, 58))
    for _, x in ipairs({-5.4, 5.4}) do
        tentPart(model, "TentPole", Vector3.new(0.8, 7.5, 0.8), base * CFrame.new(x, 3.6, 0), Enum.Material.Wood, wood)
    end
    tentPart(model, "CanvasA", Vector3.new(12.5, 0.45, 8), base * CFrame.new(0, 4.5, -2.6) * CFrame.Angles(math.rad(-31), 0, 0), Enum.Material.Fabric, canvas).CanCollide = false
    tentPart(model, "CanvasB", Vector3.new(12.5, 0.45, 8), base * CFrame.new(0, 4.5, 2.6) * CFrame.Angles(math.rad(31), 0, 0), Enum.Material.Fabric, canvas).CanCollide = false
    tentPart(model, "Bedroll", Vector3.new(4.2, 0.7, 7), base * CFrame.new(1.8, 0.7, 0), Enum.Material.Fabric, Color3.fromRGB(92, 91, 72))

    for index = 1, 8 do
        local angle = index / 8 * math.pi * 2
        tentPart(model, "FireStone", Vector3.new(1.5, 0.9, 1.3), base * CFrame.new(9 + math.cos(angle) * 2.5, 0.6, math.sin(angle) * 2.5), Enum.Material.Rock, Color3.fromRGB(87, 86, 80)).CanCollide = false
    end
    local fire = tentPart(model, "Campfire", Vector3.new(1.4, 1.8, 1.4), base * CFrame.new(9, 1.5, 0), Enum.Material.Neon, Color3.fromRGB(238, 132, 62))
    fire.CanCollide = false
    local light = Instance.new("PointLight")
    light.Brightness = 2
    light.Range = 24
    light.Color = Color3.fromRGB(255, 174, 94)
    light.Shadows = true
    light.Parent = fire
end

local function bindCampSpot(marker)
    if marker:GetAttribute("SurvivalBound") then
        return
    end
    marker:SetAttribute("SurvivalBound", true)
    local prompt = marker:FindFirstChildOfClass("ProximityPrompt")
    if not prompt then
        return
    end

    prompt.Triggered:Connect(function(player)
        local caveId = marker:GetAttribute("CaveId")
        local cave = caveId and findCave(caveId)
        if not cave then
            return
        end

        if cave:GetAttribute("GuardianDefeated") ~= true then
            toast(player, "Defeat the cave guardian before camping here.")
            return
        end

        if cave:GetAttribute("CampBuilt") == true then
            setCamp(player, caveId, marker.CFrame + Vector3.new(0, 4, 0))
            return
        end

        local affordable, missingItem, missingAmount = canAfford(player, GameplayConfig.CampRecipe)
        if not affordable then
            local item = GameplayConfig.Items[missingItem]
            toast(player, string.format("Need %d more %s to build the tent.", missingAmount, item and item.DisplayName or missingItem))
            return
        end

        consumeRecipe(player, GameplayConfig.CampRecipe)
        createTent(marker, caveId, player)
        cave:SetAttribute("CampBuilt", true)
        cave:SetAttribute("CampOwnerUserId", player.UserId)
        prompt.ActionText = "Rest / checkpoint"
        prompt.ObjectText = "Safe cave camp"
        setCamp(player, caveId, marker.CFrame + Vector3.new(0, 4, 0))
    end)
end

local function animalPart(model, name, size, cframe, color, material)
    local part = Instance.new("Part")
    part.Name = name
    part.Size = size
    part.CFrame = cframe
    part.Color = color
    part.Material = material or Enum.Material.SmoothPlastic
    part.Anchored = false
    part.CanCollide = false
    part.CanTouch = false
    part.Massless = true
    part.TopSurface = Enum.SurfaceType.Smooth
    part.BottomSurface = Enum.SurfaceType.Smooth
    part.Parent = model
    return part
end

local function weld(root, part)
    local constraint = Instance.new("WeldConstraint")
    constraint.Part0 = root
    constraint.Part1 = part
    constraint.Parent = root
end

local function guardianBillboard(root, humanoid, displayName)
    local gui = Instance.new("BillboardGui")
    gui.Name = "GuardianHealth"
    gui.Size = UDim2.fromOffset(180, 44)
    gui.StudsOffset = Vector3.new(0, 5, 0)
    gui.AlwaysOnTop = true
    gui.MaxDistance = 75
    gui.Parent = root

    local label = Instance.new("TextLabel")
    label.BackgroundColor3 = Color3.fromRGB(24, 27, 24)
    label.BackgroundTransparency = 0.2
    label.Size = UDim2.fromScale(1, 1)
    label.TextColor3 = Color3.fromRGB(236, 231, 214)
    label.TextStrokeTransparency = 0.65
    label.Font = Enum.Font.GothamBold
    label.TextScaled = true
    label.Parent = gui

    local function refresh()
        label.Text = string.format("%s  %d/%d", displayName, math.max(0, math.ceil(humanoid.Health)), math.ceil(humanoid.MaxHealth))
    end
    refresh()
    humanoid.HealthChanged:Connect(refresh)
end

local function createGuardian(marker)
    local caveId = marker:GetAttribute("CaveId")
    local guardianType = marker:GetAttribute("GuardianType") or "CaveBoar"
    local definition = GameplayConfig.Guardians[guardianType] or GameplayConfig.Guardians.CaveBoar
    local scale = definition.Scale or 1

    local model = Instance.new("Model")
    model.Name = guardianType
    model:SetAttribute("CaveId", caveId)
    model:SetAttribute("GuardianType", guardianType)
    model.Parent = marker.Parent
    CollectionService:AddTag(model, "CaveGuardian")

    local root = Instance.new("Part")
    root.Name = "HumanoidRootPart"
    root.Size = Vector3.new(3.2 * scale, 2.4 * scale, 5.5 * scale)
    root.CFrame = marker.CFrame + Vector3.new(0, 4, 0)
    root.Transparency = 1
    root.Anchored = false
    root.CanCollide = true
    root.CanTouch = false
    root.Parent = model

    local body = animalPart(model, "Body", Vector3.new(4.8 * scale, 3 * scale, 7.2 * scale), root.CFrame * CFrame.new(0, 1.1 * scale, 0), definition.BodyColor)
    weld(root, body)
    local head = animalPart(model, "Head", Vector3.new(3.1 * scale, 2.7 * scale, 3.2 * scale), root.CFrame * CFrame.new(0, 1.5 * scale, -4.2 * scale), definition.AccentColor)
    weld(root, head)

    for _, offset in ipairs({
        Vector3.new(-1.6, -1.2, -2.2),
        Vector3.new(1.6, -1.2, -2.2),
        Vector3.new(-1.6, -1.2, 2.2),
        Vector3.new(1.6, -1.2, 2.2),
    }) do
        local leg = animalPart(model, "Leg", Vector3.new(1 * scale, 3.3 * scale, 1 * scale), root.CFrame * CFrame.new(offset * scale), definition.BodyColor)
        weld(root, leg)
    end

    local tail = animalPart(model, "Tail", Vector3.new(0.8 * scale, 0.8 * scale, 4 * scale), root.CFrame * CFrame.new(0, 1.1 * scale, 5 * scale) * CFrame.Angles(math.rad(-12), 0, 0), definition.BodyColor)
    weld(root, tail)

    local humanoid = Instance.new("Humanoid")
    humanoid.Name = "Humanoid"
    humanoid.MaxHealth = definition.Health
    humanoid.Health = definition.Health
    humanoid.WalkSpeed = definition.WalkSpeed
    humanoid.HipHeight = 1.25 * scale
    humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
    humanoid.Parent = model
    model.PrimaryPart = root
    guardianBillboard(root, humanoid, definition.DisplayName)

    pcall(function()
        root:SetNetworkOwner(nil)
    end)

    local lastAttack = 0
    task.spawn(function()
        while model.Parent and humanoid.Health > 0 do
            task.wait(0.3)
            local nearestPlayer = nil
            local nearestRoot = nil
            local nearestHumanoid = nil
            local nearestDistance = math.huge

            for _, player in ipairs(Players:GetPlayers()) do
                local character = player.Character
                local targetRoot = character and character:FindFirstChild("HumanoidRootPart")
                local targetHumanoid = character and character:FindFirstChildOfClass("Humanoid")
                if targetRoot and targetHumanoid and targetHumanoid.Health > 0 then
                    local distance = (targetRoot.Position - root.Position).Magnitude
                    if distance < nearestDistance then
                        nearestDistance = distance
                        nearestPlayer = player
                        nearestRoot = targetRoot
                        nearestHumanoid = targetHumanoid
                    end
                end
            end

            if nearestPlayer and nearestRoot and nearestHumanoid and nearestDistance <= definition.AggroRange then
                humanoid:MoveTo(nearestRoot.Position)
                if nearestDistance <= definition.AttackRange and os.clock() - lastAttack >= 1.25 then
                    lastAttack = os.clock()
                    nearestHumanoid:TakeDamage(definition.Damage)
                    toast(nearestPlayer, definition.DisplayName .. " hit you!")
                end
            end
        end
    end)

    humanoid.Died:Connect(function()
        local cave = caveId and findCave(caveId)
        if cave then
            cave:SetAttribute("GuardianDefeated", true)
        end

        for _, chest in ipairs(CollectionService:GetTagged("LootChest")) do
            if chest:GetAttribute("CaveId") == caveId then
                local prompt = chest:FindFirstChildOfClass("ProximityPrompt")
                if prompt then
                    prompt.Enabled = true
                    prompt.ObjectText = "Unlocked cave cache"
                end
            end
        end
        for _, camp in ipairs(CollectionService:GetTagged("CampBuildSpot")) do
            if camp:GetAttribute("CaveId") == caveId then
                local prompt = camp:FindFirstChildOfClass("ProximityPrompt")
                if prompt then
                    prompt.Enabled = true
                    prompt.ObjectText = "Safe campsite"
                end
            end
        end

        local killerId = model:GetAttribute("LastHitUserId")
        local killer = killerId and Players:GetPlayerByUserId(killerId)
        if killer then
            local state = stateFor(killer)
            state.cavesCleared += 1
            addItem(killer, "AncientCoin", 2)
            updateLeaderstats(killer)
            sendState(killer)
        end
        toastAll(string.format("%s defeated — %s is now safe to explore!", definition.DisplayName, cave and cave:GetAttribute("DiscoveryName") or tostring(caveId)))
        task.delay(4, function()
            if model.Parent then
                model:Destroy()
            end
        end)
    end)

    return model
end

local function bindWorld()
    local root = workspace:FindFirstChild("ISLE_ZERO_WORLD")
    if not root or root:GetAttribute("BuildComplete") ~= true then
        return
    end

    seedStarterPickups(root)

    for _, pickup in ipairs(CollectionService:GetTagged("WorldPickup")) do
        if pickup:IsDescendantOf(root) then
            bindPickup(pickup)
        end
    end
    for _, chest in ipairs(CollectionService:GetTagged("LootChest")) do
        if chest:IsDescendantOf(root) then
            bindChest(chest)
        end
    end
    for _, camp in ipairs(CollectionService:GetTagged("CampBuildSpot")) do
        if camp:IsDescendantOf(root) then
            bindCampSpot(camp)
        end
    end
    for _, marker in ipairs(CollectionService:GetTagged("CaveGuardianSpawn")) do
        if marker:IsDescendantOf(root) then
            createGuardian(marker)
        end
    end

    print("[ISLE//ZERO][SURVIVAL] Pickups, cave guardians, loot chests and safe camps are live")
end

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

actionRemote.OnServerEvent:Connect(function(player, actionName, itemId)
    if actionName == "Attack" and itemId == "Machete" then
        if not equippedTool(player, "Machete") then
            return
        end
        local now = os.clock()
        if now - (attackTimes[player] or 0) < 0.52 then
            return
        end
        attackTimes[player] = now

        local character = player.Character
        local playerRoot = character and character:FindFirstChild("HumanoidRootPart")
        if not playerRoot then
            return
        end

        local nearestModel = nil
        local nearestDistance = 12.5
        for _, guardian in ipairs(CollectionService:GetTagged("CaveGuardian")) do
            if guardian:IsA("Model") then
                local guardianRoot = guardian:FindFirstChild("HumanoidRootPart")
                local humanoid = guardian:FindFirstChildOfClass("Humanoid")
                if guardianRoot and humanoid and humanoid.Health > 0 then
                    local distance = (guardianRoot.Position - playerRoot.Position).Magnitude
                    if distance <= nearestDistance then
                        nearestDistance = distance
                        nearestModel = guardian
                    end
                end
            end
        end

        if nearestModel then
            local humanoid = nearestModel:FindFirstChildOfClass("Humanoid")
            nearestModel:SetAttribute("LastHitUserId", player.UserId)
            if humanoid then
                humanoid:TakeDamage(GameplayConfig.Items.Machete.Damage or 28)
            end
        end
    elseif actionName == "Use" and itemId == "Medkit" then
        local tool = equippedTool(player, "Medkit")
        local character = player.Character
        local humanoid = character and character:FindFirstChildOfClass("Humanoid")
        if tool and humanoid and humanoid.Health > 0 and humanoid.Health < humanoid.MaxHealth then
            humanoid.Health = math.min(humanoid.MaxHealth, humanoid.Health + (GameplayConfig.Items.Medkit.Heal or 45))
            tool:Destroy()
            toast(player, "Medkit used.")
        end
    end
end)

getStateRemote.OnServerInvoke = function(player)
    return makeStatePacket(player)
end

local function playerAdded(player)
    stateFor(player)
    ensureLeaderstats(player)
    updateLeaderstats(player)

    player.CharacterAdded:Connect(function(character)
        local state = stateFor(player)
        if state.lastCamp then
            task.wait(0.35)
            if character.Parent and character.PrimaryPart then
                character:PivotTo(state.lastCamp)
            else
                local root = character:FindFirstChild("HumanoidRootPart")
                if root then
                    root.CFrame = state.lastCamp
                end
            end
        end
    end)
end

Players.PlayerAdded:Connect(playerAdded)
Players.PlayerRemoving:Connect(function(player)
    states[player] = nil
    attackTimes[player] = nil
end)
for _, player in ipairs(Players:GetPlayers()) do
    playerAdded(player)
end

workspace:GetAttributeChangedSignal("ISLEZeroGenerated"):Connect(function()
    if workspace:GetAttribute("ISLEZeroGenerated") == true then
        task.defer(bindWorld)
    end
end)

if workspace:GetAttribute("ISLEZeroGenerated") == true then
    task.defer(bindWorld)
end
