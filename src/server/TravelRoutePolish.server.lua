local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local WorldConfig = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("WorldConfig"))

local ROUTE_CLEARANCE = 13.5
local LANDMARK_CLEARANCE = 11

local function horizontalPosition(position)
    return Vector2.new(position.X, position.Z)
end

local function pointSegmentDistance(point, a, b)
    local p = horizontalPosition(point)
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

local function distanceToConfiguredPaths(position)
    local nearest = math.huge
    for _, path in pairs(WorldConfig.Paths or {}) do
        for index = 1, #path - 1 do
            nearest = math.min(nearest, pointSegmentDistance(position, path[index], path[index + 1]))
        end
    end
    return nearest
end

local function instancePosition(instance)
    if instance:IsA("Model") then
        return instance:GetPivot().Position
    elseif instance:IsA("BasePart") then
        return instance.Position
    end
    return nil
end

local function authoredVisualNear(instance, position)
    local parent = instance.Parent
    if not parent then
        return nil
    end

    for _, sibling in ipairs(parent:GetChildren()) do
        if sibling ~= instance and string.sub(sibling.Name, 1, 9) == "AUTHORED_" then
            local siblingPosition = instancePosition(sibling)
            if siblingPosition and (siblingPosition - position).Magnitude < 7 then
                return sibling
            end
        end
    end
    return nil
end

local function collectFurnitureClearances()
    local clearances = {}

    for _, tagged in ipairs(CollectionService:GetTagged("SafeCampZone")) do
        if tagged:IsA("BasePart") and tagged:IsDescendantOf(workspace) then
            table.insert(clearances, {
                Position = tagged.Position,
                Radius = (tagged:GetAttribute("SafeRadius") or 29) + 5,
            })
        end
    end

    for _, descendant in ipairs(workspace:GetDescendants()) do
        if descendant:IsA("BasePart") and (
            string.find(descendant.Name, "Sign", 1, true)
            or string.find(descendant.Name, "Direction", 1, true)
            or string.find(descendant.Name, "MapBoard", 1, true)
        ) then
            table.insert(clearances, {
                Position = descendant.Position,
                Radius = LANDMARK_CLEARANCE,
            })
        end
    end

    return clearances
end

local function isNearFurniture(position, clearances)
    local point = horizontalPosition(position)
    for _, clearance in ipairs(clearances) do
        if (point - horizontalPosition(clearance.Position)).Magnitude <= clearance.Radius then
            return true
        end
    end
    return false
end

local function polish()
    local removed = 0
    local authoredRemoved = 0
    local clearances = collectFurnitureClearances()
    local candidates = CollectionService:GetTagged("WorldVegetation")

    for _, vegetation in ipairs(candidates) do
        if vegetation:IsDescendantOf(workspace) then
            local position = instancePosition(vegetation)
            local remove = position
                and (distanceToConfiguredPaths(position) <= ROUTE_CLEARANCE or isNearFurniture(position, clearances))

            if remove and position then
                local authored = authoredVisualNear(vegetation, position)
                if authored then
                    authored:Destroy()
                    authoredRemoved += 1
                end
                vegetation:Destroy()
                removed += 1
            end
        end
    end

    print(string.format(
        "[ISLE//ZERO][ROUTE POLISH] Cleared %d intrusive vegetation objects and %d authored visuals from travel corridors",
        removed,
        authoredRemoved
    ))
end

workspace:GetAttributeChangedSignal("ISLEZeroGenerated"):Connect(function()
    if workspace:GetAttribute("ISLEZeroGenerated") == true then
        task.delay(0.2, polish)
        task.delay(1.4, polish)
    end
end)

if workspace:GetAttribute("ISLEZeroGenerated") == true then
    task.delay(0.2, polish)
end
