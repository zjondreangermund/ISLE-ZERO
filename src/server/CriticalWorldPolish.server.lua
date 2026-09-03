local CollectionService = game:GetService("CollectionService")
local TweenService = game:GetService("TweenService")

local BROKEN_MESH_IDS = {
    ["4701218333"] = true,
    ["4694750324"] = true,
}

local NATURE_PREFIXES = {
    "AUTHORED_JungleTree_",
    "AUTHORED_EmergentTree_",
    "AUTHORED_Palm_",
    "AUTHORED_Mangrove_",
}

local REJECTED_AUTHORED_PREFIXES = {
    "AUTHORED_TreeHouse_",
    "AUTHORED_CaveChest_",
    "AUTHORED_WorldChest_",
    "AUTHORED_BlackJaguar",
    "AUTHORED_JungleStalker",
}

local chestBound = setmetatable({}, {__mode = "k"})
local guardianBound = setmetatable({}, {__mode = "k"})

local function startsWith(value, prefix)
    return string.sub(value, 1, #prefix) == prefix
end

local function horizontalDistance(a, b)
    return Vector2.new(a.X - b.X, a.Z - b.Z).Magnitude
end

local function isNatureVisual(instance)
    for _, prefix in ipairs(NATURE_PREFIXES) do
        if startsWith(instance.Name, prefix) then
            return true
        end
    end
    return false
end

local function rejectedAuthored(instance)
    for _, prefix in ipairs(REJECTED_AUTHORED_PREFIXES) do
        if startsWith(instance.Name, prefix) then
            return true
        end
    end
    return false
end

local function containsBrokenMesh(instance)
    local objects
    if instance:IsA("Model") then
        objects = instance:GetDescendants()
    else
        objects = {instance}
    end

    for _, descendant in ipairs(objects) do
        local meshId = nil
        if descendant:IsA("MeshPart") then
            meshId = descendant.MeshId
        elseif descendant:IsA("SpecialMesh") then
            meshId = descendant.MeshId
        end

        if meshId and meshId ~= "" then
            for assetId in pairs(BROKEN_MESH_IDS) do
                if string.find(meshId, assetId, 1, true) then
                    return true, assetId
                end
            end
        end
    end

    return false, nil
end

local function restoreCreatureFallback(model)
    if not model or not model:IsA("Model") then
        return
    end

    for _, descendant in ipairs(model:GetDescendants()) do
        if descendant:IsA("BasePart") then
            if descendant.Name == "Body"
                or descendant.Name == "Head"
                or descendant.Name == "Leg"
                or descendant.Name == "Tail"
            then
                descendant.Transparency = 0
                descendant.CanTouch = false
                descendant.CanQuery = false
            elseif descendant.Name == "HumanoidRootPart" then
                descendant.Transparency = 1
            end
        end
    end
end

local function restoreTreeHouseFallback()
    local root = workspace:FindFirstChild("ISLE_ZERO_WORLD")
    local treeHouse = root and root:FindFirstChild("JungleTreeHouse", true)
    if not treeHouse or not treeHouse:IsA("Model") then
        return
    end

    for _, descendant in ipairs(treeHouse:GetDescendants()) do
        if descendant:IsA("BasePart") then
            local hiddenMarker = descendant.Name == "TreeHouseClimbPoint"
                or descendant.Name == "TreeHouseDescendPoint"
                or descendant.Name == "TreeHouseRestPoint"
                or descendant.Name == "TreeHouseSafeZone"

            if hiddenMarker then
                descendant.Transparency = 1
            else
                descendant.Transparency = 0
                for _, child in ipairs(descendant:GetChildren()) do
                    if child:IsA("Decal") or child:IsA("Texture") then
                        child.Transparency = 0
                    end
                end
            end
        end
    end

    treeHouse:SetAttribute("UsingGeneratedFallback", true)
end

local function restoreChestFallback(model)
    if not model or not model:IsA("Model") then
        return
    end

    for _, descendant in ipairs(model:GetDescendants()) do
        if descendant:IsA("BasePart") and (
            descendant.Name == "ChestBody"
            or descendant.Name == "ChestLid"
            or descendant.Name == "MetalBand"
        ) then
            descendant.Transparency = 0
        end
    end
    model:SetAttribute("UsingGeneratedFallback", true)
end

local function restoreNearestPlaceholder(authored)
    local parent = authored.Parent
    if not parent then
        return
    end

    if startsWith(authored.Name, "AUTHORED_TreeHouse_") then
        restoreTreeHouseFallback()
        return
    end

    if startsWith(authored.Name, "AUTHORED_BlackJaguar") or startsWith(authored.Name, "AUTHORED_JungleStalker") then
        if parent:IsA("Model") then
            restoreCreatureFallback(parent)
        end
        return
    end

    local authoredPosition = authored:GetPivot().Position
    local nearest = nil
    local nearestDistance = math.huge

    for _, sibling in ipairs(parent:GetChildren()) do
        if sibling:IsA("Model") then
            local matchesChest = startsWith(authored.Name, "AUTHORED_CaveChest_") and startsWith(sibling.Name, "Chest_")
            local matchesWorldChest = startsWith(authored.Name, "AUTHORED_WorldChest_") and startsWith(sibling.Name, "WorldChest_")
            local matchesNature = isNatureVisual(authored)
                and (sibling.Name == "JungleTree" or sibling.Name == "EmergentTree" or sibling.Name == "Palm" or sibling.Name == "Mangrove")

            if matchesChest or matchesWorldChest or matchesNature then
                local distance = (sibling:GetPivot().Position - authoredPosition).Magnitude
                if distance < nearestDistance then
                    nearestDistance = distance
                    nearest = sibling
                end
            end
        end
    end

    if nearest then
        if startsWith(nearest.Name, "Chest_") or startsWith(nearest.Name, "WorldChest_") then
            restoreChestFallback(nearest)
        else
            for _, descendant in ipairs(nearest:GetDescendants()) do
                if descendant:IsA("BasePart") then
                    descendant.Transparency = 0
                end
            end
        end
    end
end

local function rejectAuthored(instance, reason)
    if not instance.Parent then
        return
    end
    restoreNearestPlaceholder(instance)
    warn(string.format("[ISLE//ZERO][POLISH] Rejected authored visual %s: %s", instance.Name, reason))
    instance:Destroy()
end

local function groundPointAt(position)
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Include
    params.FilterDescendantsInstances = {workspace.Terrain}
    params.IgnoreWater = true

    local result = workspace:Raycast(
        Vector3.new(position.X, 700, position.Z),
        Vector3.new(0, -1400, 0),
        params
    )

    return result and result.Position or nil
end

local function groundNatureVisual(instance)
    if not instance.Parent or not isNatureVisual(instance) then
        return
    end

    local pivot = instance:GetPivot()
    local ground = groundPointAt(pivot.Position)
    if not ground then
        return
    end

    if instance:IsA("Model") then
        local ok, boxCFrame, boxSize = pcall(function()
            local cf, size = instance:GetBoundingBox()
            return cf, size
        end)
        if not ok then
            return
        end

        local bottomY = boxCFrame.Position.Y - boxSize.Y / 2
        local deltaY = ground.Y - bottomY
        if math.abs(deltaY) > 0.05 then
            instance:PivotTo(instance:GetPivot() + Vector3.new(0, deltaY, 0))
        end
    elseif instance:IsA("BasePart") then
        local bottomY = instance.Position.Y - instance.Size.Y / 2
        instance.CFrame += Vector3.new(0, ground.Y - bottomY, 0)
    end

    instance:SetAttribute("TerrainGrounded", true)
    instance:SetAttribute("TerrainGroundY", ground.Y)
end

local function chestColors(tier)
    if tier == "Relic" then
        return Color3.fromRGB(66, 42, 91), Color3.fromRGB(104, 66, 145), Color3.fromRGB(181, 158, 201), Color3.fromRGB(164, 94, 255)
    elseif tier == "Deep" then
        return Color3.fromRGB(28, 39, 51), Color3.fromRGB(37, 62, 82), Color3.fromRGB(196, 157, 73), Color3.fromRGB(92, 166, 225)
    end
    return Color3.fromRGB(91, 63, 37), Color3.fromRGB(112, 77, 43), Color3.fromRGB(75, 77, 73), Color3.fromRGB(225, 164, 88)
end

local function findCave(caveId)
    local root = workspace:FindFirstChild("ISLE_ZERO_WORLD")
    local caves = root and root:FindFirstChild("Caves")
    return caves and caveId and caves:FindFirstChild(caveId)
end

local function animateChestOpen(model, lid)
    if model:GetAttribute("PolishOpenAnimated") then
        return
    end
    model:SetAttribute("PolishOpenAnimated", true)

    local closed = lid:GetAttribute("PolishClosedCFrame")
    if typeof(closed) ~= "CFrame" then
        closed = lid.CFrame
    end

    lid.CFrame = closed
    local goal = closed * CFrame.new(0, 1.15, -1.15) * CFrame.Angles(math.rad(-58), 0, 0)
    local tween = TweenService:Create(
        lid,
        TweenInfo.new(0.62, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
        {CFrame = goal}
    )
    tween:Play()
end

local function bindChest(base)
    if chestBound[base] or not base:IsA("BasePart") or not base.Parent then
        return
    end
    chestBound[base] = true

    local model = base.Parent
    if not model:IsA("Model") then
        return
    end

    restoreChestFallback(model)

    local tier = base:GetAttribute("LootTier") or "Supplies"
    local bodyColor, lidColor, bandColor, glowColor = chestColors(tier)
    local lid = model:FindFirstChild("ChestLid")

    base.Color = bodyColor
    base.Material = Enum.Material.WoodPlanks

    if lid and lid:IsA("BasePart") then
        lid.Color = lidColor
        lid.Material = Enum.Material.WoodPlanks
        lid:SetAttribute("PolishClosedCFrame", lid.CFrame)

        local oldGlow = lid:FindFirstChild("ChestGlow")
        if oldGlow then
            oldGlow:Destroy()
        end
        if tier == "Relic" or tier == "Deep" then
            local glow = Instance.new("PointLight")
            glow.Name = "ChestGlow"
            glow.Color = glowColor
            glow.Brightness = 0.75
            glow.Range = 10
            glow.Shadows = false
            glow.Parent = lid
        end
    end

    for _, band in ipairs(model:GetChildren()) do
        if band:IsA("BasePart") and band.Name == "MetalBand" then
            band.Color = bandColor
            band.Material = Enum.Material.Metal
            band.Transparency = 0
        end
    end

    local prompt = base:FindFirstChildOfClass("ProximityPrompt")
    if not prompt then
        prompt = Instance.new("ProximityPrompt")
        prompt.Name = "OpenChestPrompt"
        prompt.Parent = base
    end
    prompt.Enabled = true
    prompt.ActionText = "Open"
    prompt.ObjectText = tier == "Relic" and "Purple relic cache" or (tier == "Deep" and "Deep treasure cache" or "Supply cache")
    prompt.HoldDuration = 0.35
    prompt.MaxActivationDistance = 11
    prompt.RequiresLineOfSight = false

    prompt.Triggered:Connect(function()
        task.delay(0.06, function()
            if not model.Parent or not lid or not lid.Parent then
                return
            end
            if model:GetAttribute("OpenedVisual") == true then
                animateChestOpen(model, lid)
            end
        end)
    end)
end

local function ensureJaguarDetails(model)
    if model:GetAttribute("JaguarFallbackPolished") then
        return
    end

    local guardianType = model:GetAttribute("GuardianType")
    if guardianType ~= "BlackJaguar" and guardianType ~= "JungleStalker" then
        return
    end

    restoreCreatureFallback(model)
    model:SetAttribute("JaguarFallbackPolished", true)
    model:SetAttribute("UsingGeneratedFallback", true)

    local head = model:FindFirstChild("Head")
    if not head or not head:IsA("BasePart") then
        return
    end

    local body = model:FindFirstChild("Body")
    if body and body:IsA("BasePart") then
        body.Material = Enum.Material.SmoothPlastic
        body.Color = guardianType == "BlackJaguar" and Color3.fromRGB(27, 29, 27) or Color3.fromRGB(39, 47, 35)
    end
    head.Material = Enum.Material.SmoothPlastic
    head.Color = guardianType == "BlackJaguar" and Color3.fromRGB(39, 42, 38) or Color3.fromRGB(57, 68, 48)

    for _, side in ipairs({-1, 1}) do
        local ear = Instance.new("WedgePart")
        ear.Name = "JaguarEar"
        ear.Size = Vector3.new(0.55, 0.7, 0.55)
        ear.Color = head.Color
        ear.Material = Enum.Material.SmoothPlastic
        ear.Anchored = false
        ear.CanCollide = false
        ear.CanTouch = false
        ear.CanQuery = false
        ear.Massless = true
        ear.CFrame = head.CFrame * CFrame.new(side * head.Size.X * 0.28, head.Size.Y * 0.48, -head.Size.Z * 0.22)
        ear.Parent = model

        local earWeld = Instance.new("WeldConstraint")
        earWeld.Part0 = head
        earWeld.Part1 = ear
        earWeld.Parent = ear

        local eye = Instance.new("Part")
        eye.Name = "JaguarEye"
        eye.Shape = Enum.PartType.Ball
        eye.Size = Vector3.new(0.13, 0.13, 0.13)
        eye.Color = Color3.fromRGB(211, 185, 69)
        eye.Material = Enum.Material.Neon
        eye.Anchored = false
        eye.CanCollide = false
        eye.CanTouch = false
        eye.CanQuery = false
        eye.Massless = true
        eye.CFrame = head.CFrame * CFrame.new(side * head.Size.X * 0.21, head.Size.Y * 0.13, -head.Size.Z * 0.5 - 0.03)
        eye.Parent = model

        local eyeWeld = Instance.new("WeldConstraint")
        eyeWeld.Part0 = head
        eyeWeld.Part1 = eye
        eyeWeld.Parent = eye
    end
end

local function caveForGuardian(guardian)
    local caveId = guardian:GetAttribute("CaveId")
    return caveId and findCave(caveId) or nil
end

local function caveFloorParts(cave)
    local parts = {}
    for _, descendant in ipairs(cave:GetDescendants()) do
        if descendant:IsA("BasePart") and (
            descendant.Name == "CavePath"
            or descendant.Name == "ChamberFloor"
            or descendant.Name == "GuardianArena"
        ) then
            table.insert(parts, descendant)
        end
    end
    return parts
end

local function floorRay(parts, position)
    if #parts == 0 then
        return nil
    end

    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Include
    params.FilterDescendantsInstances = parts
    params.IgnoreWater = true

    return workspace:Raycast(
        position + Vector3.new(0, 35, 0),
        Vector3.new(0, -90, 0),
        params
    )
end

local function nearestFloorHit(parts, position)
    local direct = floorRay(parts, position)
    if direct then
        return direct
    end

    local nearestPart = nil
    local nearestDistance = math.huge
    for _, part in ipairs(parts) do
        local distance = horizontalDistance(position, part.Position)
        if distance < nearestDistance then
            nearestDistance = distance
            nearestPart = part
        end
    end

    if nearestPart then
        return floorRay(parts, nearestPart.Position)
    end
    return nil
end

local function snapGuardianToHit(guardian, root, humanoid, hit)
    if not hit then
        return false
    end

    local lift = root.Size.Y / 2 + math.max(0.55, humanoid.HipHeight * 0.42)
    local target = hit.Position + Vector3.new(0, lift, 0)
    local look = root.CFrame.LookVector
    local flatLook = Vector3.new(look.X, 0, look.Z)
    if flatLook.Magnitude < 0.1 then
        flatLook = Vector3.new(0, 0, -1)
    else
        flatLook = flatLook.Unit
    end

    guardian:PivotTo(CFrame.lookAt(target, target + flatLook))
    root.AssemblyLinearVelocity = Vector3.zero
    root.AssemblyAngularVelocity = Vector3.zero
    return true
end

local function bindGuardianLeash(guardian)
    if guardianBound[guardian] or not guardian:IsA("Model") then
        return
    end
    if not guardian:GetAttribute("CaveId") then
        return
    end

    local root = guardian:FindFirstChild("HumanoidRootPart")
    local humanoid = guardian:FindFirstChildOfClass("Humanoid")
    local cave = caveForGuardian(guardian)
    if not root or not root:IsA("BasePart") or not humanoid or not cave then
        return
    end

    guardianBound[guardian] = true
    humanoid:SetStateEnabled(Enum.HumanoidStateType.Climbing, false)
    humanoid.AutoJumpEnabled = false

    task.spawn(function()
        task.wait(0.7)
        if not guardian.Parent or humanoid.Health <= 0 then
            return
        end

        local parts = caveFloorParts(cave)
        local homeHit = nearestFloorHit(parts, root.Position)
        if homeHit then
            snapGuardianToHit(guardian, root, humanoid, homeHit)
        end
        local home = root.Position
        guardian:SetAttribute("ArenaHome", home)

        while guardian.Parent and humanoid.Health > 0 do
            task.wait(0.32)
            parts = caveFloorParts(cave)
            local currentHit = floorRay(parts, root.Position)
            local tooFar = horizontalDistance(root.Position, home) > 38
            local offFloor = not currentHit
            local tooHigh = currentHit and root.Position.Y - currentHit.Position.Y > 7

            if tooFar or offFloor or tooHigh then
                local targetHit
                if tooFar then
                    targetHit = nearestFloorHit(parts, home)
                else
                    targetHit = nearestFloorHit(parts, root.Position)
                end

                if targetHit and snapGuardianToHit(guardian, root, humanoid, targetHit) then
                    guardian:SetAttribute("ArenaCorrectionCount", (guardian:GetAttribute("ArenaCorrectionCount") or 0) + 1)
                end
            end
        end
    end)
end

local function handleAuthored(instance)
    if not (instance:IsA("Model") or instance:IsA("BasePart")) then
        return
    end
    if not startsWith(instance.Name, "AUTHORED_") then
        return
    end

    if rejectedAuthored(instance) then
        task.defer(rejectAuthored, instance, "generated fallback is more reliable and interactive")
        return
    end

    local broken, assetId = containsBrokenMesh(instance)
    if broken then
        task.defer(rejectAuthored, instance, "Roblox could not fetch mesh asset " .. tostring(assetId))
        return
    end

    if isNatureVisual(instance) then
        task.delay(0.05, groundNatureVisual, instance)
    end
end

local function scanAuthored()
    for _, descendant in ipairs(workspace:GetDescendants()) do
        if (descendant:IsA("Model") or descendant:IsA("BasePart")) and startsWith(descendant.Name, "AUTHORED_") then
            handleAuthored(descendant)
        end
    end
    restoreTreeHouseFallback()
end

local function scanChests()
    for _, chest in ipairs(CollectionService:GetTagged("LootChest")) do
        if chest:IsDescendantOf(workspace) and chest:IsA("BasePart") then
            bindChest(chest)
        end
    end
end

local function scanGuardians()
    for _, guardian in ipairs(CollectionService:GetTagged("CaveGuardian")) do
        if guardian:IsA("Model") and guardian:IsDescendantOf(workspace) then
            ensureJaguarDetails(guardian)
            bindGuardianLeash(guardian)
        end
    end
end

workspace.DescendantAdded:Connect(function(instance)
    if (instance:IsA("Model") or instance:IsA("BasePart")) and startsWith(instance.Name, "AUTHORED_") then
        task.delay(0.08, handleAuthored, instance)
    end
end)

CollectionService:GetInstanceAddedSignal("LootChest"):Connect(function(chest)
    if chest:IsA("BasePart") then
        task.delay(0.3, bindChest, chest)
    end
end)

CollectionService:GetInstanceAddedSignal("CaveGuardian"):Connect(function(guardian)
    if guardian:IsA("Model") then
        task.delay(0.35, ensureJaguarDetails, guardian)
        task.delay(0.55, bindGuardianLeash, guardian)
    end
end)

workspace:GetAttributeChangedSignal("ISLEZeroGenerated"):Connect(function()
    if workspace:GetAttribute("ISLEZeroGenerated") == true then
        task.delay(0.35, scanAuthored)
        task.delay(0.55, scanChests)
        task.delay(0.75, scanGuardians)
        task.delay(2.0, scanAuthored)
        task.delay(2.2, scanChests)
    end
end)

if workspace:GetAttribute("ISLEZeroGenerated") == true then
    task.delay(0.35, scanAuthored)
    task.delay(0.55, scanChests)
    task.delay(0.75, scanGuardians)
end
