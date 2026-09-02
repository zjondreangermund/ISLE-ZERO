local CollectionService = game:GetService("CollectionService")

local function caveForGuardian(guardian)
    local caveId = guardian:GetAttribute("CaveId")
    if not caveId then
        return nil
    end
    local root = workspace:FindFirstChild("ISLE_ZERO_WORLD")
    local caves = root and root:FindFirstChild("Caves")
    return caves and caves:FindFirstChild(caveId)
end

local function walkableParts(cave)
    local parts = {}
    for _, object in ipairs(cave:GetDescendants()) do
        if object:IsA("BasePart") and (
            object.Name == "CavePath"
            or object.Name == "ChamberFloor"
            or object.Name == "GuardianArena"
        ) then
            table.insert(parts, object)
        end
    end
    return parts
end

local function snapGuardian(guardian)
    if not guardian:IsA("Model") then
        return
    end

    task.wait(0.15)
    if not guardian.Parent then
        return
    end

    local rootPart = guardian:FindFirstChild("HumanoidRootPart")
    local cave = caveForGuardian(guardian)
    if not rootPart or not cave then
        return
    end

    local candidates = walkableParts(cave)
    if #candidates == 0 then
        warn("[ISLE//ZERO][GUARDIAN] No walkable cave parts found for " .. guardian.Name)
        return
    end

    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Include
    params.FilterDescendantsInstances = candidates
    params.IgnoreWater = true

    local origin = rootPart.Position + Vector3.new(0, 45, 0)
    local result = workspace:Raycast(origin, Vector3.new(0, -100, 0), params)
    if not result then
        warn("[ISLE//ZERO][GUARDIAN] Could not find cave floor under " .. guardian.Name)
        return
    end

    local lift = rootPart.Size.Y / 2 + 1.2
    local targetPosition = result.Position + Vector3.new(0, lift, 0)
    local look = rootPart.CFrame.LookVector
    guardian:PivotTo(CFrame.lookAt(targetPosition, targetPosition + Vector3.new(look.X, 0, look.Z)))
    rootPart.AssemblyLinearVelocity = Vector3.zero
    rootPart.AssemblyAngularVelocity = Vector3.zero

    guardian:SetAttribute("FloorSnapped", true)
    guardian:SetAttribute("FloorY", result.Position.Y)
    print(string.format("[ISLE//ZERO][GUARDIAN] %s snapped to cave floor Y %.1f", guardian.Name, result.Position.Y))
end

CollectionService:GetInstanceAddedSignal("CaveGuardian"):Connect(snapGuardian)

for _, guardian in ipairs(CollectionService:GetTagged("CaveGuardian")) do
    task.defer(snapGuardian, guardian)
end
