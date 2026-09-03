local CollectionService = game:GetService("CollectionService")

local bound = setmetatable({}, {__mode = "k"})

local function horizontalDistance(a, b)
    return Vector2.new(a.X - b.X, a.Z - b.Z).Magnitude
end

local function findCave(caveId)
    local root = workspace:FindFirstChild("ISLE_ZERO_WORLD")
    local caves = root and root:FindFirstChild("Caves")
    return caves and caveId and caves:FindFirstChild(caveId) or nil
end

local function floorParts(cave)
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

local function rayToFloor(parts, position)
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
    local direct = rayToFloor(parts, position)
    if direct then
        return direct
    end

    local nearest = nil
    local best = math.huge
    for _, part in ipairs(parts) do
        local distance = horizontalDistance(position, part.Position)
        if distance < best then
            best = distance
            nearest = part
        end
    end

    return nearest and rayToFloor(parts, nearest.Position) or nil
end

local function snapToHit(model, root, humanoid, hit)
    if not hit then
        return false
    end

    local lift = root.Size.Y / 2 + math.max(0.55, humanoid.HipHeight * 0.42)
    local target = hit.Position + Vector3.new(0, lift, 0)
    local look = root.CFrame.LookVector
    local flat = Vector3.new(look.X, 0, look.Z)
    if flat.Magnitude < 0.1 then
        flat = Vector3.new(0, 0, -1)
    else
        flat = flat.Unit
    end

    model:PivotTo(CFrame.lookAt(target, target + flat))
    root.AssemblyLinearVelocity = Vector3.zero
    root.AssemblyAngularVelocity = Vector3.zero
    return true
end

local function restoreJaguar(model)
    local guardianType = model:GetAttribute("GuardianType")
    if guardianType ~= "BlackJaguar" and guardianType ~= "JungleStalker" then
        return
    end

    for _, child in ipairs(model:GetChildren()) do
        if (child:IsA("Model") or child:IsA("BasePart")) and (
            string.sub(child.Name, 1, 21) == "AUTHORED_BlackJaguar"
            or string.sub(child.Name, 1, 22) == "AUTHORED_JungleStalker"
        ) then
            child:Destroy()
        end
    end

    for _, descendant in ipairs(model:GetDescendants()) do
        if descendant:IsA("BasePart") then
            if descendant.Name == "Body" or descendant.Name == "Head" or descendant.Name == "Leg" or descendant.Name == "Tail" then
                descendant.Transparency = 0
            elseif descendant.Name == "HumanoidRootPart" then
                descendant.Transparency = 1
            end
        end
    end

    if model:GetAttribute("JaguarFallbackPolished") then
        return
    end
    model:SetAttribute("JaguarFallbackPolished", true)
    model:SetAttribute("UsingGeneratedFallback", true)

    local head = model:FindFirstChild("Head")
    local body = model:FindFirstChild("Body")
    if body and body:IsA("BasePart") then
        body.Color = guardianType == "BlackJaguar" and Color3.fromRGB(27, 29, 27) or Color3.fromRGB(39, 47, 35)
        body.Material = Enum.Material.SmoothPlastic
    end
    if not head or not head:IsA("BasePart") then
        return
    end

    head.Color = guardianType == "BlackJaguar" and Color3.fromRGB(39, 42, 38) or Color3.fromRGB(57, 68, 48)
    head.Material = Enum.Material.SmoothPlastic

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

local function bindGuardian(model)
    if bound[model] or not model:IsA("Model") then
        return
    end

    restoreJaguar(model)

    local caveId = model:GetAttribute("CaveId")
    if not caveId then
        return
    end

    local cave = findCave(caveId)
    local root = model:FindFirstChild("HumanoidRootPart")
    local humanoid = model:FindFirstChildOfClass("Humanoid")
    if not cave or not root or not root:IsA("BasePart") or not humanoid then
        return
    end

    bound[model] = true
    humanoid:SetStateEnabled(Enum.HumanoidStateType.Climbing, false)
    humanoid.AutoJumpEnabled = false

    task.spawn(function()
        task.wait(0.7)
        if not model.Parent or humanoid.Health <= 0 then
            return
        end

        local parts = floorParts(cave)
        local homeHit = nearestFloorHit(parts, root.Position)
        if homeHit then
            snapToHit(model, root, humanoid, homeHit)
        end
        local home = root.Position
        model:SetAttribute("ArenaHome", home)

        while model.Parent and humanoid.Health > 0 do
            task.wait(0.32)
            parts = floorParts(cave)
            local currentHit = rayToFloor(parts, root.Position)
            local tooFar = horizontalDistance(root.Position, home) > 38
            local offFloor = currentHit == nil
            local tooHigh = currentHit and root.Position.Y - currentHit.Position.Y > 7

            if tooFar or offFloor or tooHigh then
                local targetHit = tooFar and nearestFloorHit(parts, home) or nearestFloorHit(parts, root.Position)
                if targetHit and snapToHit(model, root, humanoid, targetHit) then
                    model:SetAttribute("ArenaCorrectionCount", (model:GetAttribute("ArenaCorrectionCount") or 0) + 1)
                end
            end
        end
    end)
end

local function scan()
    for _, guardian in ipairs(CollectionService:GetTagged("CaveGuardian")) do
        if guardian:IsA("Model") and guardian:IsDescendantOf(workspace) then
            bindGuardian(guardian)
        end
    end
end

CollectionService:GetInstanceAddedSignal("CaveGuardian"):Connect(function(guardian)
    if guardian:IsA("Model") then
        task.delay(0.45, bindGuardian, guardian)
    end
end)

workspace:GetAttributeChangedSignal("ISLEZeroGenerated"):Connect(function()
    if workspace:GetAttribute("ISLEZeroGenerated") == true then
        task.delay(0.75, scan)
        task.delay(1.8, scan)
    end
end)

if workspace:GetAttribute("ISLEZeroGenerated") == true then
    task.delay(0.75, scan)
end
