local AUTHORED_PREFIX = "AUTHORED_"
local TREEHOUSE_KEY = "AUTHORED_TreeHouse_"

local LIMITS = {
    TreeHouse = 64,
    SafeTent = 28,
    JungleTree = 86,
    EmergentTree = 105,
    Palm = 78,
    Mangrove = 62,
    WorldChest = 18,
    CaveChest = 18,
}

local DEFAULT_LIMIT = 72
local PART_LIMIT_MULTIPLIER = 1.2
local OUTLIER_DISTANCE_MULTIPLIER = 1.35

local processed = setmetatable({}, {__mode = "k"})

local function startsWith(value, prefix)
    return string.sub(value, 1, #prefix) == prefix
end

local function authoredKey(name)
    if not startsWith(name, AUTHORED_PREFIX) then
        return nil
    end

    local rest = string.sub(name, #AUTHORED_PREFIX + 1)
    local separator = string.find(rest, "_", 1, true)
    if separator then
        return string.sub(rest, 1, separator - 1)
    end
    return rest
end

local function boundsOf(instance)
    if instance:IsA("Model") then
        local ok, cf, size = pcall(function()
            local boxCFrame, boxSize = instance:GetBoundingBox()
            return boxCFrame, boxSize
        end)
        if ok then
            return cf, size
        end
    elseif instance:IsA("BasePart") then
        return instance.CFrame, instance.Size
    end
    return nil, nil
end

local function scaleVisual(instance, factor)
    if factor >= 0.999 and factor <= 1.001 then
        return true
    end

    if instance:IsA("Model") then
        return pcall(function()
            instance:ScaleTo(instance:GetScale() * factor)
        end)
    elseif instance:IsA("BasePart") then
        instance.Size *= factor
        return true
    end
    return false
end

local function visualPivot(instance)
    if instance:IsA("Model") or instance:IsA("BasePart") then
        return instance:GetPivot().Position
    end
    return Vector3.zero
end

local function removeUnsupportedContent(instance)
    for _, descendant in ipairs(instance:GetDescendants()) do
        if descendant:IsA("Sound") then
            descendant:Destroy()
        elseif descendant:IsA("BasePart") then
            descendant.CanCollide = false
            descendant.CanTouch = false
            descendant.CanQuery = false
        end
    end
end

local function sanitizeOutlierParts(instance, limit)
    local center = visualPivot(instance)
    local removed = 0
    local maxPartExtent = limit * PART_LIMIT_MULTIPLIER
    local maxDistance = limit * OUTLIER_DISTANCE_MULTIPLIER

    local descendants = instance:IsA("Model") and instance:GetDescendants() or {instance}
    for _, descendant in ipairs(descendants) do
        if descendant:IsA("BasePart") then
            local size = descendant.Size
            local largest = math.max(size.X, size.Y, size.Z)
            local distance = (descendant.Position - center).Magnitude

            if largest > maxPartExtent or distance > maxDistance then
                warn(string.format(
                    "[ISLE//ZERO][ASSET SAFETY] Quarantined oversized/outlier part %s (extent %.1f, distance %.1f).",
                    descendant:GetFullName(),
                    largest,
                    distance
                ))
                descendant:Destroy()
                removed += 1
            end
        end
    end
    return removed
end

local function findTreeHousePlaceholder()
    local root = workspace:FindFirstChild("ISLE_ZERO_WORLD")
    if not root then
        return nil
    end
    return root:FindFirstChild("JungleTreeHouse", true)
end

local function realignTreeHouse(instance)
    local placeholder = findTreeHousePlaceholder()
    if not placeholder or not placeholder:IsA("Model") then
        return
    end

    local targetPivot = placeholder:GetPivot()
    if instance:IsA("Model") then
        instance:PivotTo(targetPivot)
    elseif instance:IsA("BasePart") then
        instance.CFrame = targetPivot
    end

    local placeholderCf, placeholderSize = boundsOf(placeholder)
    local visualCf, visualSize = boundsOf(instance)
    if not placeholderCf or not placeholderSize or not visualCf or not visualSize then
        return
    end

    local targetBottom = placeholderCf.Position.Y - placeholderSize.Y / 2
    local visualBottom = visualCf.Position.Y - visualSize.Y / 2
    local deltaY = targetBottom - visualBottom

    if instance:IsA("Model") then
        instance:PivotTo(instance:GetPivot() + Vector3.new(0, deltaY, 0))
    else
        instance.CFrame += Vector3.new(0, deltaY, 0)
    end
end

local function validateAuthoredVisual(instance)
    if processed[instance] or not (instance:IsA("Model") or instance:IsA("BasePart")) then
        return
    end
    if not startsWith(instance.Name, AUTHORED_PREFIX) then
        return
    end

    processed[instance] = true
    removeUnsupportedContent(instance)

    local key = authoredKey(instance.Name) or "Unknown"
    local limit = LIMITS[key] or DEFAULT_LIMIT
    local _, size = boundsOf(instance)
    if not size then
        return
    end

    local largest = math.max(size.X, size.Y, size.Z)
    if largest > limit then
        local factor = limit / largest
        if scaleVisual(instance, factor) then
            warn(string.format(
                "[ISLE//ZERO][ASSET SAFETY] %s authored visual was %.1f studs across; auto-scaled to %.1f studs.",
                key,
                largest,
                limit
            ))
        end
    end

    local removed = sanitizeOutlierParts(instance, limit)
    if key == "TreeHouse" or startsWith(instance.Name, TREEHOUSE_KEY) then
        realignTreeHouse(instance)
    end

    local _, finalSize = boundsOf(instance)
    if finalSize then
        local finalLargest = math.max(finalSize.X, finalSize.Y, finalSize.Z)
        if finalLargest > limit * 1.45 then
            warn(string.format(
                "[ISLE//ZERO][ASSET SAFETY] %s remains oversized after cleanup (%.1f studs). Hiding remaining authored geometry for this run.",
                instance.Name,
                finalLargest
            ))
            for _, descendant in ipairs(instance:GetDescendants()) do
                if descendant:IsA("BasePart") then
                    descendant.Transparency = 1
                    descendant.CanCollide = false
                end
            end
            if instance:IsA("BasePart") then
                instance.Transparency = 1
                instance.CanCollide = false
            end
        elseif removed > 0 then
            print(string.format("[ISLE//ZERO][ASSET SAFETY] %s cleaned; %d invalid parts removed", instance.Name, removed))
        end
    end
end

workspace.DescendantAdded:Connect(function(instance)
    if (instance:IsA("Model") or instance:IsA("BasePart")) and startsWith(instance.Name, AUTHORED_PREFIX) then
        task.delay(0.12, validateAuthoredVisual, instance)
    end
end)

local function scan()
    for _, instance in ipairs(workspace:GetDescendants()) do
        if (instance:IsA("Model") or instance:IsA("BasePart")) and startsWith(instance.Name, AUTHORED_PREFIX) then
            validateAuthoredVisual(instance)
        end
    end
end

workspace:GetAttributeChangedSignal("ISLEZeroGenerated"):Connect(function()
    if workspace:GetAttribute("ISLEZeroGenerated") == true then
        task.delay(0.5, scan)
        task.delay(2, scan)
    end
end)

if workspace:GetAttribute("ISLEZeroGenerated") == true then
    task.delay(0.5, scan)
end
