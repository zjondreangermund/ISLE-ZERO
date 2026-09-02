local ReplicatedStorage = game:GetService("ReplicatedStorage")

local MAX_TREEHOUSE_EXTENT = 78
local MIN_TREEHOUSE_EXTENT = 10
local TREEHOUSE_KEY = "AUTHORED_TreeHouse_"

local function startsWith(value, prefix)
    return string.sub(value, 1, #prefix) == prefix
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
        local ok = pcall(function()
            instance:ScaleTo(instance:GetScale() * factor)
        end)
        return ok
    elseif instance:IsA("BasePart") then
        instance.Size *= factor
        return true
    end
    return false
end

local function findTreeHousePlaceholder()
    local root = workspace:FindFirstChild("ISLE_ZERO_WORLD")
    if not root then
        return nil
    end
    return root:FindFirstChild("JungleTreeHouse", true)
end

local function realignToPlaceholder(instance)
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

    local _, targetSize = boundsOf(placeholder)
    local visualCf, visualSize = boundsOf(instance)
    if not targetSize or not visualCf or not visualSize then
        return
    end

    -- Keep the authored model standing on the same floor as the generated shelter.
    local targetBottom = select(1, placeholder:GetBoundingBox()).Position.Y - targetSize.Y / 2
    local visualBottom = visualCf.Position.Y - visualSize.Y / 2
    local deltaY = targetBottom - visualBottom

    if instance:IsA("Model") then
        instance:PivotTo(instance:GetPivot() + Vector3.new(0, deltaY, 0))
    else
        instance.CFrame += Vector3.new(0, deltaY, 0)
    end
end

local function validateTreeHouse(instance)
    if not (instance:IsA("Model") or instance:IsA("BasePart")) then
        return
    end
    if not startsWith(instance.Name, TREEHOUSE_KEY) then
        return
    end
    if instance:GetAttribute("ISLEZeroStructureValidated") then
        return
    end

    instance:SetAttribute("ISLEZeroStructureValidated", true)

    local _, size = boundsOf(instance)
    if not size then
        return
    end

    local largest = math.max(size.X, size.Y, size.Z)
    if largest <= 0 then
        return
    end

    if largest > MAX_TREEHOUSE_EXTENT then
        local factor = MAX_TREEHOUSE_EXTENT / largest
        if scaleVisual(instance, factor) then
            warn(string.format(
                "[ISLE//ZERO][ASSET SAFETY] Tree House asset was %.1f studs across; auto-scaled by %.3f to prevent an oversized world obstruction.",
                largest,
                factor
            ))
        end
    elseif largest < MIN_TREEHOUSE_EXTENT then
        local factor = MIN_TREEHOUSE_EXTENT / largest
        if scaleVisual(instance, factor) then
            warn(string.format(
                "[ISLE//ZERO][ASSET SAFETY] Tree House asset was unusually small; scaled by %.3f for world use.",
                factor
            ))
        end
    end

    realignToPlaceholder(instance)
end

workspace.DescendantAdded:Connect(function(instance)
    if startsWith(instance.Name, TREEHOUSE_KEY) then
        task.delay(0.1, validateTreeHouse, instance)
    end
end)

local function scan()
    for _, instance in ipairs(workspace:GetDescendants()) do
        if startsWith(instance.Name, TREEHOUSE_KEY) then
            validateTreeHouse(instance)
        end
    end
end

workspace:GetAttributeChangedSignal("ISLEZeroGenerated"):Connect(function()
    if workspace:GetAttribute("ISLEZeroGenerated") == true then
        task.delay(0.5, scan)
    end
end)

if workspace:GetAttribute("ISLEZeroGenerated") == true then
    task.delay(0.5, scan)
end
