local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("WorldConfig"))

local lastRoot = nil
local cleanupRunning = false

local function horizontalPosition(position)
    return Vector2.new(position.X, position.Z)
end

local function pointSegmentDistanceXZ(position, a, b)
    local p = horizontalPosition(position)
    local av = horizontalPosition(a)
    local bv = horizontalPosition(b)
    local ab = bv - av
    local lengthSquared = ab:Dot(ab)

    if lengthSquared <= 0.001 then
        return (p - av).Magnitude
    end

    local t = math.clamp((p - av):Dot(ab) / lengthSquared, 0, 1)
    local closest = av + ab * t
    return (p - closest).Magnitude
end

local function distanceToMainRiver(position)
    local waterways = config.Waterways
    local points = waterways and waterways.MainRiver
    if not points or #points < 2 then
        return math.huge
    end

    local nearest = math.huge
    for index = 1, #points - 1 do
        nearest = math.min(nearest, pointSegmentDistanceXZ(position, points[index], points[index + 1]))
    end
    return nearest
end

local function vegetationPosition(instance)
    if instance:IsA("BasePart") then
        return instance.Position
    elseif instance:IsA("Model") then
        return instance:GetPivot().Position
    end
    return nil
end

local function shouldRemove(instance, position)
    local waterways = config.Waterways
    if not waterways then
        return false
    end

    local kind = tostring(instance:GetAttribute("VegetationType") or "")
    local riverHalfWidth = (waterways.RiverWidth or 26) * 0.5

    -- Keep mangroves on wet banks, but never let their trunks sit in the flowing channel.
    local riverMargin = kind == "Mangrove" and 3 or 13
    if distanceToMainRiver(position) <= riverHalfWidth + riverMargin then
        return true
    end

    local poolCenter = waterways.PoolCenter
    local poolRadius = waterways.PoolRadius or 0
    if poolCenter and poolRadius > 0 then
        local poolMargin = kind == "Mangrove" and 4 or 12
        local distance = (horizontalPosition(position) - horizontalPosition(poolCenter)).Magnitude
        if distance <= poolRadius + poolMargin then
            return true
        end
    end

    return false
end

local function cleanup(root)
    if cleanupRunning or not root or not root.Parent then
        return
    end
    cleanupRunning = true

    local removed = 0
    local byKind = {}

    for _, vegetation in ipairs(CollectionService:GetTagged("WorldVegetation")) do
        if vegetation:IsDescendantOf(root) and vegetation.Parent then
            local position = vegetationPosition(vegetation)
            if position and shouldRemove(vegetation, position) then
                local kind = tostring(vegetation:GetAttribute("VegetationType") or vegetation.Name)
                byKind[kind] = (byKind[kind] or 0) + 1
                removed += 1
                vegetation:Destroy()
            end
        end
    end

    root:SetAttribute("WaterwayVegetationRemoved", removed)
    cleanupRunning = false

    local details = {}
    for kind, count in pairs(byKind) do
        table.insert(details, string.format("%s=%d", kind, count))
    end
    table.sort(details)

    print(string.format(
        "[ISLE//ZERO][WATERWAY VEGETATION] Removed %d river/pool vegetation%s",
        removed,
        #details > 0 and (" (" .. table.concat(details, ", ") .. ")") or ""
    ))
end

local function watchRoot(root)
    if not root or root == lastRoot then
        return
    end
    lastRoot = root

    task.spawn(function()
        local vegetation = root:WaitForChild("Vegetation", 180)
        if not vegetation then
            return
        end

        if vegetation:GetAttribute("TotalTrees") ~= nil then
            cleanup(root)
            return
        end

        local connection
        connection = vegetation:GetAttributeChangedSignal("TotalTrees"):Connect(function()
            if vegetation:GetAttribute("TotalTrees") ~= nil then
                if connection then
                    connection:Disconnect()
                end
                task.defer(cleanup, root)
            end
        end)
    end)
end

local existing = workspace:FindFirstChild("ISLE_ZERO_WORLD")
if existing then
    watchRoot(existing)
end

workspace.ChildAdded:Connect(function(child)
    if child.Name == "ISLE_ZERO_WORLD" then
        watchRoot(child)
    end
end)

workspace:GetAttributeChangedSignal("ISLEZeroGenerated"):Connect(function()
    if workspace:GetAttribute("ISLEZeroGenerated") == true then
        local root = workspace:FindFirstChild("ISLE_ZERO_WORLD")
        if root then
            cleanup(root)
        end
    end
end)
