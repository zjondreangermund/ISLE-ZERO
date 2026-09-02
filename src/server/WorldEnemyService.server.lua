local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameplayConfig = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("GameplayConfig"))

local activeByMarker = setmetatable({}, {__mode = "k"})

local function toast(player, message)
    local remotes = ReplicatedStorage:FindFirstChild("ISLEZeroSurvival")
    local remote = remotes and remotes:FindFirstChild("Toast")
    if remote and remote:IsA("RemoteEvent") then
        remote:FireClient(player, message)
    end
end

local function animalPart(model, name, size, cframe, color)
    local object = Instance.new("Part")
    object.Name = name
    object.Size = size
    object.CFrame = cframe
    object.Color = color
    object.Material = Enum.Material.SmoothPlastic
    object.Anchored = false
    object.CanCollide = false
    object.CanTouch = false
    object.Massless = true
    object.TopSurface = Enum.SurfaceType.Smooth
    object.BottomSurface = Enum.SurfaceType.Smooth
    object.Parent = model
    return object
end

local function weld(root, object)
    local constraint = Instance.new("WeldConstraint")
    constraint.Part0 = root
    constraint.Part1 = object
    constraint.Parent = root
end

local function healthBillboard(root, humanoid, displayName)
    local gui = Instance.new("BillboardGui")
    gui.Name = "WildlifeHealth"
    gui.Size = UDim2.fromOffset(150, 36)
    gui.StudsOffset = Vector3.new(0, 4.5, 0)
    gui.AlwaysOnTop = true
    gui.MaxDistance = 62
    gui.Parent = root

    local label = Instance.new("TextLabel")
    label.BackgroundColor3 = Color3.fromRGB(24, 27, 24)
    label.BackgroundTransparency = 0.24
    label.Size = UDim2.fromScale(1, 1)
    label.TextColor3 = Color3.fromRGB(230, 226, 206)
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

local function nearestTarget(origin, range)
    local nearestPlayer = nil
    local nearestRoot = nil
    local nearestHumanoid = nil
    local nearestDistance = range

    for _, player in ipairs(Players:GetPlayers()) do
        local character = player.Character
        local root = character and character:FindFirstChild("HumanoidRootPart")
        local humanoid = character and character:FindFirstChildOfClass("Humanoid")
        if root and humanoid and humanoid.Health > 0 then
            local distance = (root.Position - origin).Magnitude
            if distance < nearestDistance then
                nearestDistance = distance
                nearestPlayer = player
                nearestRoot = root
                nearestHumanoid = humanoid
            end
        end
    end

    return nearestPlayer, nearestRoot, nearestHumanoid, nearestDistance
end

local function spawnEnemy(marker)
    if not marker.Parent or activeByMarker[marker] then
        return
    end

    local guardianType = marker:GetAttribute("GuardianType") or "WildBoar"
    local definition = GameplayConfig.Guardians[guardianType]
    if not definition then
        warn("[ISLE//ZERO][WILDLIFE] Missing Guardian definition: " .. guardianType)
        return
    end

    local scale = definition.Scale or 0.85
    local model = Instance.new("Model")
    model.Name = "Wild_" .. guardianType
    model:SetAttribute("EncounterId", marker:GetAttribute("EncounterId"))
    model:SetAttribute("GuardianType", guardianType)
    model:SetAttribute("WorldEnemy", true)
    model.Parent = marker.Parent
    CollectionService:AddTag(model, "CaveGuardian")
    CollectionService:AddTag(model, "WorldEnemy")

    local spawnPosition = marker.Position + Vector3.new(0, 2.5, 0)
    local root = Instance.new("Part")
    root.Name = "HumanoidRootPart"
    root.Size = Vector3.new(3 * scale, 2.2 * scale, 5 * scale)
    root.CFrame = CFrame.new(spawnPosition)
    root.Transparency = 1
    root.Anchored = false
    root.CanCollide = true
    root.CanTouch = false
    root.Parent = model

    local body = animalPart(model, "Body", Vector3.new(4.3 * scale, 2.8 * scale, 6.4 * scale), root.CFrame * CFrame.new(0, 1 * scale, 0), definition.BodyColor)
    weld(root, body)
    local head = animalPart(model, "Head", Vector3.new(2.8 * scale, 2.5 * scale, 2.9 * scale), root.CFrame * CFrame.new(0, 1.35 * scale, -3.7 * scale), definition.AccentColor)
    weld(root, head)

    for _, offset in ipairs({
        Vector3.new(-1.4, -1.15, -1.9),
        Vector3.new(1.4, -1.15, -1.9),
        Vector3.new(-1.4, -1.15, 1.9),
        Vector3.new(1.4, -1.15, 1.9),
    }) do
        local leg = animalPart(model, "Leg", Vector3.new(0.9 * scale, 3 * scale, 0.9 * scale), root.CFrame * CFrame.new(offset * scale), definition.BodyColor)
        weld(root, leg)
    end

    local humanoid = Instance.new("Humanoid")
    humanoid.MaxHealth = definition.Health
    humanoid.Health = definition.Health
    humanoid.WalkSpeed = definition.WalkSpeed
    humanoid.HipHeight = 1.1 * scale
    humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
    humanoid.Parent = model
    model.PrimaryPart = root
    healthBillboard(root, humanoid, definition.DisplayName)

    pcall(function()
        root:SetNetworkOwner(nil)
    end)

    activeByMarker[marker] = model
    local home = marker.Position
    local lastAttack = 0

    task.spawn(function()
        while model.Parent and humanoid.Health > 0 do
            task.wait(0.32)
            local player, targetRoot, targetHumanoid, distance = nearestTarget(root.Position, definition.AggroRange or 50)
            local homeDistance = (root.Position - home).Magnitude

            if player and targetRoot and targetHumanoid and homeDistance < 115 then
                humanoid:MoveTo(targetRoot.Position)
                if distance <= (definition.AttackRange or 5) and os.clock() - lastAttack >= 1.35 then
                    lastAttack = os.clock()
                    targetHumanoid:TakeDamage(definition.Damage or 8)
                    toast(player, definition.DisplayName .. " attacked you!")
                end
            elseif homeDistance > 8 then
                humanoid:MoveTo(home)
            end
        end
    end)

    humanoid.Died:Connect(function()
        local killerId = model:GetAttribute("LastHitUserId")
        local killer = killerId and Players:GetPlayerByUserId(killerId)
        if killer then
            killer:SetAttribute("WorldEnemiesDefeated", (killer:GetAttribute("WorldEnemiesDefeated") or 0) + 1)
            toast(killer, string.format("%s defeated. Search the area for hidden caches.", definition.DisplayName))
        end

        activeByMarker[marker] = nil
        task.delay(4, function()
            if model.Parent then
                model:Destroy()
            end
        end)
        task.delay(55, function()
            if marker.Parent and workspace:GetAttribute("ISLEZeroGenerated") == true then
                spawnEnemy(marker)
            end
        end)
    end)
end

local function bindWorld()
    local count = 0
    for _, marker in ipairs(CollectionService:GetTagged("WorldEnemySpawn")) do
        if marker:IsDescendantOf(workspace) then
            spawnEnemy(marker)
            count += 1
        end
    end
    print(string.format("[ISLE//ZERO][WILDLIFE] %d roaming encounters activated", count))
end

workspace:GetAttributeChangedSignal("ISLEZeroGenerated"):Connect(function()
    if workspace:GetAttribute("ISLEZeroGenerated") == true then
        task.defer(bindWorld)
    end
end)

if workspace:GetAttribute("ISLEZeroGenerated") == true then
    task.defer(bindWorld)
end
